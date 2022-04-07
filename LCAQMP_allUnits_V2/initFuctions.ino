/* Functions are called dureing void setup, used for initializing
 *  
 */


// Init for BME-sensor
void initiateBME() {
  //run me in init
  if (!bme.begin()) {
    Serial.println("Could not find a valid BME680 sensor, check wiring!");
  }
  // Set up oversampling and filter initialization
  bme.setTemperatureOversampling(BME680_OS_8X);
  bme.setHumidityOversampling(BME680_OS_2X);
  bme.setPressureOversampling(BME680_OS_4X);
  bme.setIIRFilterSize(BME680_FILTER_SIZE_3);
  bme.setGasHeater(320, 150); // 320*C for 150 ms

  Serial.println("the BME680 is initiated");
}

// Init for GPS
void initiateGPS() {
  //GPS.begin(9600);
  GPS.sendCommand(PMTK_SET_NMEA_OUTPUT_RMCGGA); //Set GPS-output to recommended ammount of data, which is also in line with what's desirable   (RMC = recommended minimum , GGA (fix data) including altitude)

  GPS.sendCommand(PMTK_SET_NMEA_UPDATE_1HZ); // Sets GPS update rate to 1 Hz 
  GPS.sendCommand(PGCMD_ANTENNA); //  // Request updates on antenna status, comment out to keep quiet
  delay(1000);

  GPSSerial.println(PMTK_Q_RELEASE); // Ask for firmware version
  GPS.wakeup(); // Wake up the GPS from standby mode.
  Serial.println("The GPS is initiated");
}

void initiateCCS() {
  //run me in init
  if (!ccs.begin()) {
    Serial.println("Could not find a valid CCS811 sensor, check wiring!");
  }
  delay(20);
  // Wait for the sensor to be ready
  if(!ccs.available()){
    Serial.println("the CCS811 is initiated but had no data");
  }else{
    Serial.println("the CCS811 is initiated");
  }
}

void initiateSD() {
  //SD setup, called in void setup() and is used when LCAQMP is initialized
  
  /* see if the card is present and can be initialized
   *  SD.begin(cardSelect) returns boolean, True if SD-card is connected and False if not. 
   *  If there is no card detected, prints to serial, sets boolean to false and runs error-code.
   */ 
  
  if (!SD.begin(cardSelect)) {
    // Runs if there is no card, returns errors.        
    Serial.println("Card init. failed!");
    sdCardConnected = false;
    error(2);
  }else{
    sdCardConnected = true;

  }

  //see if we can get a name to apend to the fileName
  String filename;
  if(getSDName()){
    filename = apendingName + "_";
  }else{
    Serial.println("cound not find append name");
    filename = "LCAQMP";
  }

  //File name used is created here 
  String FullFileName;
  for (uint8_t i = 0; i < 100; i++) {
    String number;
    number =  String(i / 10);
    number += String(i % 10);
   
    
    // create if does not exist, do not open existing, write, sync after write
 
    FullFileName = filename + number + FILETYPE;
    
    if (!SD.exists(FullFileName)) {
      break;
    }
    //  Can't create filenames longer then 8 characters, eg. "Unit10_00.CSV" is to long. 
    if (FullFileName.length() > 8){ 
      FullFileName = "UnX.CSV";
  }
  }
  // CSV-file is created here, 
  logfile = SD.open(FullFileName, FILE_WRITE);  
  if (!logfile) {
    // If there is no instance of open file
    Serial.print("Couldnt create ");
    Serial.println(FullFileName);
    error(3);
  }
  // Prints header to CSV file. 
  Serial.print("Writing to ");
  Serial.println(FullFileName);
  Serial.println("Ready!");;
  printSDAndSerial(getMillisStringHeader() + "," + getSDS011StringHeader() + "," + getBME680StringHeader() + "," + getCCS811StringHeader() + "," + getGPSStringHeader() + "," + getCozIrStringHeader() + "," + getAFEStringHeader()+ "," + getErrorHeader());
}



bool getSDName(){
 /* This function reads opens and reads namefile from SD-card connected to ADA-feather
  * Function is boolean which enables function to be called in a logic statment (if-,while statement etc..)
  * If Unit name is collected from the file, returns True otherwise False.
  * 4 logic statements are used to make sure main code runs succesfull. 
  */

  if(sdCardConnected){  //sdCardConnected is defined in function initiateSD(). If sdCardConnected == false getSDName() returns false
    Serial.println("SD is connected!"); 
    if(SD.exists(NAMEFILE)){ // Logic statement to check if textfile exists
      Serial.println("the name file exists");
      File nameFile = SD.open(NAMEFILE); // Defines the instance of opening the namefile. 
      if(nameFile){ // Logic statement to check if instance of open file is created
        Serial.println("successfully opened the file");
        Serial.println("now reading from file");
        if(nameFile.available()){ // Logic statment checking content of instance
          String rawInput;
          while(nameFile.available()){ // Extracting each character from the file in a loop
            rawInput+= (char) nameFile.read();
          }
          //clean the namestring from any unwanted shit
          rawInput.replace("\n","");
          rawInput.replace( "\r","");
          apendingName = rawInput; // Used for creating namefile
          // Using previously used rawinput to get unit number as int. 
          rawInput.replace("Un",""); 
          unitNumber = rawInput.toInt();
          
        
          Serial.println("apend text found, will apend " + apendingName + " To the file name");
          delay(10);
          nameFile.close(); // Closes instance
          return true;
        }
        
      }else{
        Serial.println("Failed open the namefile");
      }
      nameFile.close();
    }else{
      Serial.println("no namme file exists");
    }
  }
  return false;
}
