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

void initiateGPS() {
  //GPS.begin(9600);
  GPS.sendCommand(PMTK_SET_NMEA_OUTPUT_RMCGGA); //(RMC = recommended minimum)
  //Denna typ av data innehåller infon vi behöver
  //Säger åt GPSen att ge oss denna typ av data 
  GPS.sendCommand(PMTK_SET_NMEA_UPDATE_1HZ); // 1 Hz update rate
  GPS.sendCommand(PGCMD_ANTENNA);
  delay(1000);
  // Ask for firmware version
  GPSSerial.println(PMTK_Q_RELEASE);
  GPS.wakeup();
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
  //SD setup
  
  // see if the card is present and can be initialized:
  if (!SD.begin(cardSelect)) {
    Serial.println("Card init. failed!");
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
  }

  logfile = SD.open(FullFileName, FILE_WRITE);
  if (!logfile) {
    Serial.print("Couldnt create ");
    Serial.println(FullFileName);
    error(3);
  }
  Serial.print("Writing to ");
  Serial.println(FullFileName);
  Serial.println("Ready!");;
  printSDAndSerial(getMillisStringHeader() + ", " + getSDS011StringHeader() + ", " + getBME680StringHeader() + "," + getCCS811StringHeader() + "," + getGPSStringHeader() + "," + getCozIrStringHeader());
}

bool getSDName(){
  if(sdCardConnected){
    Serial.println("SD is connected!");
    if(SD.exists(NAMEFILE)){
      Serial.println("the name file exists");
      File nameFile = SD.open(NAMEFILE);
      if(nameFile){
        Serial.println("successfully opened the file");
        Serial.println("now reading from file");
        if(nameFile.available()){
          String rawInput;
          while(nameFile.available()){
            rawInput+= (char) nameFile.read();
          }
          //clean the namestring from any unwanted shit
          rawInput.replace("\n","");
          rawInput.replace( "\r","");
          apendingName = rawInput;
          Serial.println("apend text found, will apend " + apendingName + " To the file name");
          delay(10);
          nameFile.close();
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
