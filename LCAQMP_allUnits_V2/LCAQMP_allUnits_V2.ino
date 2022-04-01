/* Main program for LCAQMP, calls all other functions from here
 */
#include <Arduino.h>   // required before wiring_private.h
#include "wiring_private.h"
#include <SDS011_Uart.h>
#include <SPI.h> // Library used for SD-card and saving data
#include <SD.h> // Library used for SD-card and saving data
#include "Adafruit_BME680.h"                
#include <bme680_defs.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_CCS811.h>
#include <Adafruit_GPS.h>

#include <stdio.h>
#include <string.h>





float cardVoltage = 3.3; // Adafeathers kortspänning
float PT1000temp;     

int i = 0; //Använda för att skriva till SD-kortet var tionde gång man läser data
uint32_t t0 = 0;


//Predefine variables for NO2 and OZONe:
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

//Predefine variables for sensor values
String sdsRead;
String bmeRead;
String ccsRead;
String cozRead;
String gpsRead;

//Predefine sensor data string
String parsedValues = "";

// atmospheric pressure
#define SEALEVELPRESSURE_HPA (1013.25)

// Set the pins used
#define cardSelect 4 // Used for SD-card
#define GREEN_LED_PIN 8 // Used for successfull operation
#define RED_LED_PIN 13 // Used for error-led
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


#define NAMEFILE "name.txt" //name of file that contains Unit name that will be appeded to the readings file.
#define FILETYPE ".CSV" //the filetype that we export to.
File logfile; // Naming the instance of the opened file "logfile"
bool sdCardConnected; // Boolean used for identifying if SD-card is connected or not
String apendingName; // Used to create name for new file on SD-card, containting the unit name eg. "Unit6"
int unitNumber; // integer describing unit number, = 6 if apendingName = "Unit6"
SDS011 sds011Sensor(&Serial2);
Adafruit_BME680 bme; // temp & RH & Preasure & VOC

Adafruit_CCS811 ccs; // C02 & TVOC

uint32_t timer = millis();
String errorString; 
bool errorLed; // Bool , True if error

void setup(){ 

 //start computer uart
  Serial.begin(115200);
  //delay(10000);
  Serial.println("host port open");
 //while(!Serial) delay(10); //WAIT FOR PORT TO OPEN!

  //starting our secound uart used for SDS01
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

  // initFunctions for sensors
  initiateGPS();
  initiateSD();
  initiateBME();
  initiateCCS();
  


  // sets analog pin resolution to 12 bits
  analogReadResolution(12);

  
  // Print to serial
  printSDAndSerial("Starting!");
  delay(500);

  
  updateValues();
  // Makes sure the LCAQMP starts updating at start of a new minute
  t0 = millis();
 
  while(String(GPS.seconds) != "0")  
  {
   updateValues();
   delay(10);
   //Serial.println(GPS.seconds);
   //Serial.println("Nu väntar vi :)");
   if (millis() - t0 > 61000) { 
      break;  // 
    }
  }

  

  
}


void loop() { 
  /* Main loop of program, starts after setup. 
   * Loops functions until shut off. 
   */


  errorLed = false; // false at start
  errorString = ""; // no error at start
  updateValues(); // get sensor values 
  printValues(); // Print to SD-card
  if(errorString.length()) errorLed = true;
  digitalWrite(RED_LED_PIN, errorLed); //the led is red, thus, when the red light is on, there is an error
}


void printValues() {
  /*This function is used to get the csv strings from the sensors.
   * Reformat sensor data strings to one string
   * This occurs 10 times, depending on how you define the loop.
   * Runs function printSD() after, used for saving data to SD-card
   */

    // Get all sensor data as strings
    sdsRead = getSDS011StringLastReading();
    bmeRead = getBME680StringLastReading();
    ccsRead = getCCS811StringLastReading();
    gpsRead = getGPSStringLastReading();
    cozRead = getCozIRStringLastReading();

    // every 2 seconds, depending on set time in loop (eg. 1998)
    while((millis() - t0) < 1900);
    // Printing at 2000 ms intervals 
    while(millis()%2000 != 0);
    // format values into on string
    parsedValues += String(millis()) + "," + sdsRead + "," + bmeRead + "," + ccsRead + "," + gpsRead + "," + cozRead + "," + SN1_WE_u + "," + SN1_AE_u + "," + SN2_WE_u + "," + SN2_AE_u + "," + NO2 + "," + O3 + "," + PT1000temp + ","+  errorString;
    t0 = millis();
    

    // Saves 10 sensor datapoints to string then prints to SD
    i++;
    if(i<10){
      parsedValues += "\r\n";
    }
    else{
      printSD(parsedValues);
      i=0;
      parsedValues = "";
    }

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
  
  // Returns True if card is available, procceds to print to card
  if (SD.begin(cardSelect)) {

    // Logic statement changing sdCardConnected bool
    if (!sdCardConnected) {
      //the connection to the sd card have been lost but is now back! yay
      sdCardConnected = true;
      printSDAndSerial("the connection to the sd card was lost but is now reestablished!");
    }

    // Prints parsed sensor values to instance of open file, logfile
    logfile.println(input);
    // Ensures that any bytes written to the file are physically saved to the SD card. 
    logfile.flush();

    // Short green led blink signaling succesfull export of data to SD-card
    digitalWrite(GREEN_LED_PIN, HIGH);
    delay(100);
    digitalWrite(GREEN_LED_PIN, LOW);
  } else {
    
    // If no card is found at pin 4.
    Serial.println("Card init. failed!");
    sdCardConnected = false;
    errorLed = true;
  }


  //if error while printing, run printSerial function
}
// Prints parsed string to serial monitor
void printSerial(String input) {
  Serial.println(input);
}
// prints to SD and serial monitor
void printSDAndSerial(String input) {
  logfile.println(input);
  Serial.println(input);
}



//SD-error function, takes 8-bit integer as input which determines ammount to flashes of Red led.
void error(uint8_t errno) {

  // loops 10 times
  for (int loop = 0; loop < 10; loop++) {
    uint8_t i;

    // flashes red led "errno" ammount of times
    for (i = 0; i < errno; i++) {
      digitalWrite(RED_LED_PIN, HIGH);
      delay(500);
      digitalWrite(RED_LED_PIN, LOW);
      delay(500);
    }
    for (i = errno; i < 10; i++) {
      delay(200);
    }
  }
}
