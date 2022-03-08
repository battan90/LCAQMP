#include <Arduino.h>   // required before wiring_private.h
#include "wiring_private.h"
#include <SDS011_Uart.h>
#include <SPI.h>
#include <SD.h>
#include "Adafruit_BME680.h"                
#include <bme680_defs.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_CCS811.h>
#include <Adafruit_GPS.h>

#include <stdio.h>
#include <string.h>





float cardVoltage = 3.3; 
float PT1000temp;

int i = 0; //Använda för att skriva till SD-kortet var tionde gång man läser data
uint32_t t0 = 0;


//For NO2 and OZON:
float NO2;       
float O3;        
float SN1_WE_u;
float SN1_AE_u;
float SN2_WE_u;
float SN2_AE_u;
int WE1Pin = A2; //OP1
int AE1Pin = A5; //OP2
int WE2Pin = A1; //OP3
int AE2Pin = A0; //OP4
int PTPin = A7; //Pt1000+

String sdsRead;
String bmeRead;
String ccsRead;
String cozRead;
String gpsRead;

String parsedValues = "";

#define SEALEVELPRESSURE_HPA (1013.25)
// Set the pins used
#define cardSelect 4

#define GREEN_LED_PIN 8
#define RED_LED_PIN 13
#define timeZoneHourShift 2

#define GPSSerial Serial1
#define GPSECHO true
Adafruit_GPS GPS(&GPSSerial);
bool gpsLatestReadResult;

#define CozIrSerial Serial3
bool CozIrLatestReadResult;
String CozIrCo2Value;
String CozIrCo2_filteredValue;

//we are using feather0, for sensor sds011 we need another uard, here we activate one more
//from ada https://learn.adafruit.com/using-atsamd21-sercom-to-add-more-spi-i2c-serial-ports/creating-a-new-serial


struct StructSDS011 {
  float pm25;
  float pm10;
  int sds011error;
};

StructSDS011 StructSDS011;

bool bme680LatestReadResult;
bool ccs811LatestReadResult;


Uart Serial2 (&sercom1, 11, 10, SERCOM_RX_PAD_0, UART_TX_PAD_2);
void SERCOM1_Handler()
{
  Serial2.IrqHandler();
}

Uart Serial1 (&sercom0, A4, A3, SERCOM_RX_PAD_1, UART_TX_PAD_0);
void SERCOM0_Handler(){
  Serial1.IrqHandler();
}

Uart Serial3 (&sercom2, 0, 1, SERCOM_RX_PAD_3, UART_TX_PAD_2);
void SERCOM2_Handler(){
  Serial3.IrqHandler();
}


#define NAMEFILE "name.txt" //name of file that contains noting but a short name that will be appeded to the readings file
#define FILETYPE ".CSV" //the filetype that we export to.
File logfile;
bool sdCardConnected;
String apendingName;
int unitNumber;
SDS011 sds011Sensor(&Serial2);
Adafruit_BME680 bme; // temp & RH & Preasure & VOC

Adafruit_CCS811 ccs; // C02 & TVOC

uint32_t timer = millis();
String errorString;
bool errorLed;

void setup() {

  //start computer uart
  Serial.begin(115200);
  Serial.println("host port open");
 //while(!Serial) delay(10); //WAIT FOR PORT TO OPEN!

  //starting our secound uart
  Serial2.begin(9600);
  Serial.println("slave port open");
  Serial.println(sizeof(StructSDS011));
  Serial3.begin(9600);
  Serial1.begin(9600);
  
  delay(1);
  
  if(Serial3) Serial.println("slaveport serial 3 open");
  //we have to assingn uart functionality to pin 11 and 10 since we have defined them as it above
  pinPeripheral(A3, PIO_SERCOM_ALT);
  pinPeripheral(A4, PIO_SERCOM_ALT);
  
  //serial2
  pinPeripheral(10, PIO_SERCOM);
  pinPeripheral(11, PIO_SERCOM);

  //serial3
  pinPeripheral(0, PIO_SERCOM_ALT);
  pinPeripheral(1, PIO_SERCOM_ALT);

  pinMode(GREEN_LED_PIN, OUTPUT); //Green led, close to SD card
  pinMode(RED_LED_PIN, OUTPUT);
  digitalWrite(RED_LED_PIN, LOW); //on the feather the red led is for some reason started as high

  initiateSD();
  initiateBME();
  initiateCCS();
  initiateGPS();

  analogReadResolution(12);
  
  printSDAndSerial("Starting!");
  delay(500);
}


void loop() {
  errorLed = false;
  errorString = "";
  updateValues();
  printValues();
  if(errorString.length()) errorLed = true;
  digitalWrite(RED_LED_PIN, errorLed); //the led is red, thus, when the red light is on, there is an error
}


void printValues() {
  //Get the csv strings from the sensors.
  //String parsedValues = String(millis()) + ", " + getSDS011StringLastReading() + ", " + getBME680StringLastReading() + ", " + getCCS811StringLastReading() + ", " + getGPSStringLastReading() + ", " + getCozIRStringLastReading() + ", " + SN1_WE_u + ", " + SN1_AE_u + ", " + SN2_WE_u + ", " + SN2_AE_u + ", " + NO2 + ", " + O3 + ", ERRORS : " + errorString;
    sdsRead = getSDS011StringLastReading();
    bmeRead = getBME680StringLastReading();
    ccsRead = getCCS811StringLastReading();
    gpsRead = getGPSStringLastReading();
    cozRead = getCozIRStringLastReading();
    while((millis() - t0) < 1998);
    parsedValues += String(millis()) + ", " + sdsRead + ", " + bmeRead + ", " + ccsRead + ", " + gpsRead + ", " + cozRead + ", " + SN1_WE_u + ", " + SN1_AE_u + ", " + SN2_WE_u + ", " + SN2_AE_u + ", " + NO2 + ", " + O3 + ", " + PT1000temp + ", ERRORS : " + errorString;
    t0 = millis();

    i++;
    if(i<10){
      parsedValues += "\r\n";
    }
    else{
      printSD(parsedValues);
      i=0;
      parsedValues = "";
    }
 // printSerial(getMillisStringHeader() + ", " + getSDS011StringHeader() + ", " + getBME680StringHeader() + ", " + getCCS811StringHeader() + ", " + getGPSStringHeader() + ", " + getCozIrStringHeader() + ", " + getAFEStringHeader());
 // printSerial(parsedValues);
  Serial.println();
  Serial.println(getMillisStringHeader() + ": " + String(millis()));
  Serial.println("SN1_WE_u " + String(SN1_WE_u));
  Serial.println("SN1_AE_u " + String(SN1_AE_u));
  Serial.println("SN2_WE_u " + String(SN2_WE_u));
  Serial.println("SN2_AE_u " + String(SN2_WE_u));
  Serial.println("NO2 " + String(NO2));
  Serial.println("O3 " + String(O3));
  Serial.println(getSDS011StringHeader() + ": " + sdsRead); 
  Serial.println(getBME680StringHeader() + ": " + bmeRead);
  Serial.println(getCCS811StringHeader() + ": " + ccsRead);
  Serial.println(getGPSStringHeader() + ": " + gpsRead);
  Serial.println(getCozIrStringHeader() + ": " + cozRead);
  Serial.println("PT1000 temperature: " + String(PT1000temp));
  Serial.println("ERRORS : " + errorString);
  Serial.println("Unit number : " + String(unitNumber));
  Serial.println();
}

void printSD(String input) {
  //Serial.println("testing the connection to the sd card");
  if (SD.begin(cardSelect)) {
    if (!sdCardConnected) {
      //the connection to the sd card have been lost but is now back! yay
      sdCardConnected = true;
      printSDAndSerial("the connection to the sd card was lost but is now reestablished!");
    }
    digitalWrite(GREEN_LED_PIN, HIGH);
    logfile.println(input);
    logfile.flush();
    digitalWrite(GREEN_LED_PIN, LOW);
  } else {
    Serial.println("Card init. failed!");
    sdCardConnected = false;
    errorLed = true;
  }


  //if error while printing, run printSerial function
}

void printSerial(String input) {
  Serial.println(input);
}

void printSDAndSerial(String input) {
  logfile.println(input);
  Serial.println(input);
}



//SD-error code
void error(uint8_t errno) {
  for (int loop = 0; loop < 10; loop++) {
    uint8_t i;
    for (i = 0; i < errno; i++) {
      digitalWrite(RED_LED_PIN, HIGH);
      delay(100);
      digitalWrite(RED_LED_PIN, LOW);
      delay(100);
    }
    for (i = errno; i < 10; i++) {
      delay(200);
    }
  }
}
