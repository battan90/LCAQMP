void updateValues(){
  //run the code to fetch new sensor data, if there is an error fetching the data, print it in this function
  StructSDS011.sds011error = sds011Sensor.read(&StructSDS011.pm25, &StructSDS011.pm10);
  if(StructSDS011.sds011error){
    errorString += " SDS011";
  }
  
  bme680LatestReadResult = bme.performReading();
  if(!bme680LatestReadResult) {
    errorString += " BME680";
  } 
  
  ccs811LatestReadResult = !ccs.readData();
  if(!ccs811LatestReadResult) {
    errorString += " CCS811";
  }
  
  if(GPS.available()){
    while(GPS.available()){
      delay(1);
      GPS.read();
    }
  }
  if (GPS.newNMEAreceived()) {
    // a tricky thing here is if we print the NMEA sentence, or data
    // we end up not listening and catching other sentences!
    // so be very wary if using OUTPUT_ALLDATA and trying to print out data
    //Serial.println(GPS.lastNMEA()); // this also sets the newNMEAreceived() flag to false
    
    if(GPS.parse(GPS.lastNMEA())){
      gpsLatestReadResult = true;
    }else{
      gpsLatestReadResult = false;
      errorString += " GPS";
    }
  }
  CozIrLatestReadResult = false;
  if(CozIrSerial.available()){
    Serial.println("Bytes available before read : " + String(CozIrSerial.available()));
    String message;
    while(CozIrSerial.available()){
      delay(20);
      char latestchar = CozIrSerial.read();
      message += latestchar;
      if(latestchar == '\n'){
        while(CozIrSerial.available()){
          CozIrSerial.read();
        }
        break; //transmission break found
      }
    }

    if(message.length() == 18){
      CozIrLatestReadResult = true;
      CozIrCo2Value = message.substring(3,8);
      CozIrCo2_filteredValue = message.substring(11,16);
    }else{
      
    }
    Serial.println("Bytes available after read: " + String(CozIrSerial.available()));
  }
  if(!CozIrLatestReadResult){ //we have not recived a new update
    errorString += " CozIR";
  }
  readNO2andO3(); //get all data for NO2 and O3
  getTemp();      //calculate temperature using to PT1000 sensor on the AFE
}
