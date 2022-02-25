// Följande paket behöver finnas tillgängliga för att koden ska gå att köra
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

float cardVoltage = 3.3; 

// Skapar stringar med namnen på varje sensor 
String sdsRead;
String bmeRead;
String ccsRead;
String cozRead;
String gpsRead;

String parsedValues = ""; // string där de värdena som ska analyseras är inlagda 

// #define skapar konstanta värden innan programmet kompileras 
// #define constantName value 
#define SEALEVELPRESSURE_HPA (1013.25)

// Set the pins used
#define cardSelect 4
#define GREEN_LED_PIN 8
#define RED_LED_PIN 13
#define timeZoneHourShift 2

#define GPSSerial Serial1 // vad är serial 1?
#define GPSECHO true

Adafruit_GPS GPS(&GPSSerial); //mkt oklar rad. 

// Bools som är true om det går att läsa av värden från respektive sensor/GPS:en
bool gpsLatestReadResult; 
bool bme680LatestReadResult;
bool ccs811LatestReadResult;


// Definitioner gällande CosIR, vilket är koldioxid-sensorn
#define CozIrSerial Serial3
bool CozIrLatestReadResult; // true om det går att läsa av resultatet
String CozIrCo2Value; // värdet på mängden CO2
String CozIrCo2_filteredValue; //värdena filtreras på något sätt?

int i = 0; // borde flyttas!?

//we are using feather0, for sensor sds011 we need another uard (t?), here we activate one more
//from ada https://learn.adafruit.com/using-atsamd21-sercom-to-add-more-spi-i2c-serial-ports/creating-a-new-serial

// struct = lagrar olika data och gör dem till samma typ (typ?)
struct StructSDS011 {
  float pm25;
  float pm10;
  int sds011error;
};

StructSDS011 StructSDS011; // Vad menas? 

// KOLLA UPP SAKER OM UART!! 
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
bool sdCardConnected; // true om SD-kortet sitter i 
String apendingName; // namnet som ska läggas till i (??) 

SDS011 sds011Sensor(&Serial2); // föstår ej 
Adafruit_BME680 bme; // temp & RH & Preasure & VOC (JA OCH VAD MENAR NI MED DET?) 
Adafruit_CCS811 ccs; // C02 & VOC

uint32_t timer = millis(); // Sätter timerns enhet till millisekunder 
uint32_t t0 = 0; // säger att tiden ska börja på 0

String errorString; // string som säger om något är fel   
bool errorLed; // LED-lapma som lyser om något är fel (dock oklart vad) 

// Funktion som körs en gång vid start används för att initiera värden
void setup() {

  //start computer uart
  Serial.begin(115200);
  Serial.println("host port open");
 //while(!Serial) delay(10); //WAIT FOR PORT TO OPEN! (Frågan är varför detta är bortkommenterat? 

  //starting our secound uart
  Serial2.begin(9600);
  Serial.println("slave port open");
  Serial.println(sizeof(StructSDS011));
  Serial3.begin(9600);
  Serial1.begin(9600);
  
  delay(1); // väntar 1 ms
  
  if(Serial3) Serial.println("slaveport serial 3 open"); // om serial3 är true -> printa det som står
  //we have to assingn uart functionality to pin 11 and 10 since we have defined them as it above
  pinPeripheral(A3, PIO_SERCOM_ALT); // Oklart vad pinPeripheral är för något, gissar att det är en funktion som gör något, men den är inte definerad någonstans eller 
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

// Följande funtioner finns i initFunctions.ino
  initiateSD(); 
  initiateBME();
  initiateCCS();
  initiateGPS();

  analogReadResolution(12); // sätter storleken i bitar från det retunerade värder i analogRead(), frågan är dock var den finns någonstnas
  
  printSDAndSerial("Starting!"); 
  delay(500);
}


void loop() {
  errorLed = false;
  errorString = "";
  updateValues(); // definerad i updateSensorValues.ino
  printValues(); // definerad nedan 
  if(errorString.length()) errorLed = true; // om stringen har en längd är ska error-lampan lysa 
  digitalWrite(RED_LED_PIN, errorLed); //the led is red, thus, when the red light is on, there is an error
  //delay(1000);
  // digitalWrite(pin, value), säger om den pinnen som är kallad på om den ska vara HIGH eller LOW dvs på eller av. 
}


void printValues() {
  //Get the csv strings from the sensors.
  // Följande funtioner är definerade i sensorStringParsing.ino
  //String parsedValues = String(millis()) + ", " + getSDS011StringLastReading() + ", " + getBME680StringLastReading() + ", " + getCCS811StringLastReading() + ", " + getGPSStringLastReading() + ", " + getCozIRStringLastReading() + ", " + SN1_WE_u + ", " + SN1_AE_u + ", " + SN2_WE_u + ", " + SN2_AE_u + ", " + NO2 + ", " + O3 + ", ERRORS : " + errorString;
    sdsRead = getSDS011StringLastReading();
    bmeRead = getBME680StringLastReading();
    ccsRead = getCCS811StringLastReading();
    gpsRead = getGPSStringLastReading();
    cozRead = getCozIRStringLastReading();
    while ((millis() - t0) < 2000) {// printar värdena till parsedValues som läggs in i Excel-filen 
    parsedValues += String(millis()) + ", " + sdsRead + ", " + bmeRead + ", " + ccsRead + ", " + gpsRead + ", " + cozRead + ",,,,,,," + ", ERRORS : " + errorString;
    t0 = millis();
    //print the csv row
      i++;
      if(i<10){ // De 10 första gångerna som while-loopen (?) kör görs 9 nya rader?
        parsedValues += "\r\n";
        /* - \r = CR (Carriage Return) → Used as a new line character in Mac OS before X
           - \n = LF (Line Feed) → Used as a new line character in Unix/Mac OS X
           - \r\n = CR + LF → Used as a new line character in Windows */
      }
      else{
      printSD(parsedValues);
      i=0;
      parsedValues = "";
      }
    }
 // printSerial(getMillisStringHeader() + ", " + getSDS011StringHeader() + ", " + getBME680StringHeader() + ", " + getCCS811StringHeader() + ", " + getGPSStringHeader() + ", " + getCozIrStringHeader() + ", " + getAFEStringHeader());
 // printSerial(parsedValues);
 // Skriver över allt till Excel-filen ?
  Serial.println();
  Serial.println(getMillisStringHeader() + ": " + String(millis()));
  Serial.println(getSDS011StringHeader() + ": " + sdsRead); 
  Serial.println(getBME680StringHeader() + ": " + bmeRead);
  Serial.println(getCCS811StringHeader() + ": " + ccsRead);
  Serial.println(getGPSStringHeader() + ": " + gpsRead);
  Serial.println(getCozIrStringHeader() + ": " + cozRead);
  Serial.println("ERRORS : " + errorString);
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
    digitalWrite(GREEN_LED_PIN, HIGH); // tänder den gröna LEDen
    logfile.println(input);
    logfile.flush(); // Rensar bufferten eller vänta på att datan till serial ska överföras 
    digitalWrite(GREEN_LED_PIN, LOW); // säcker den gröna LEDen
  } else { // Om det inte går att läsa/skriva till SD-kortet kommer errorLed-lampan att lysa 
    Serial.println("Card init. failed!");
    sdCardConnected = false;
    errorLed = true;
  }


  //if error while printing, run printSerial function
}
// Printar en input, till något? Denna verkar inte användas då enda sätllet den kallas på är 184 och det är bortkommenterat
void printSerial(String input) {
  Serial.println(input);
}

// Printar inputen från SD-kortet till ??
void printSDAndSerial(String input) {
  logfile.println(input);
  Serial.println(input);
}

//SD-error code
//När kommer denna kod att köras ens?? Finns ju inga villkor? Känns som den körs varje gång den går igenom koden bara? Mkt oklart. 
void error(uint8_t errno) {
  for (int loop = 0; loop < 10; loop++) { // Den röda lampan kommer blinka med 0.1 sekunders intervall och sedan vänta 0.2 sek om det är något fel med SD-kortet.
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
