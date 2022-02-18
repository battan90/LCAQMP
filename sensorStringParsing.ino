//SDS011
String getSDS011StringLastReading(){
  String sds011ParsedStringValue = "0,0"; //if sensor reading failed, this will be printed
  if(!StructSDS011.sds011error){
    sds011ParsedStringValue = String(StructSDS011.pm25) + ", " + String(StructSDS011.pm10);
  }
  return sds011ParsedStringValue;
}

String getSDS011StringHeader(){
  return "SDS011_pm25, SDS011_pm10";
}

//BME680
String getBME680StringLastReading(){
  String bme680ParsedStringValue = "0, 0, 0, 0"; //if sensor reading failed, this will be printed
  if(bme680LatestReadResult){
    bme680ParsedStringValue = String(bme.temperature) + ", " +  String(bme.pressure / 10.0) + ", " + String(bme.humidity) + ", " + String(bme.gas_resistance / 1000.0);
  }
  return bme680ParsedStringValue;
}

String getGPSStringLastReading(){
  String GPSStringLatestReading = "HEJ";
  String GPSTimeString = String(GPS.year) + ", " + String(GPS.month) + ", " + String(GPS.day) + ", " + String(GPS.hour + timeZoneHourShift) + ", " + String(GPS.minute) + ", " + String(GPS.seconds);
  String GPSPositionString = "0, 0, 0, 0";
  if(gpsLatestReadResult){
    String GPSTimeString = String(GPS.year) + ", " + String(GPS.month) + ", " + String(GPS.day) + ", " +  String(GPS.hour) + ", " + String(GPS.minute) + ", " + String(GPS.seconds);
    if(GPS.fix){
      GPSPositionString = String(GPS.longitude_fixed) + ", " + String(GPS.latitude_fixed) + ", " + String(GPS.satellites) + ", " + String(GPS.fix);
    }
  }
  GPSStringLatestReading = GPSTimeString + ", " + GPSPositionString;
  return GPSStringLatestReading;
}

String getBME680StringHeader(){
  return "BME680_temperature, BME680_pressure, BME680_humidity, BME680_gasResistance";
}

String getMillisStringHeader(){
  return "processor_millis";
}

//CCS811
String getCCS811StringLastReading(){
  String ccs811ParsedStringValue = "0,0"; //if sensor reading failed, this will be printed
  if(ccs811LatestReadResult){
    ccs811ParsedStringValue = String(ccs.geteCO2()) + ", " + String(ccs.getTVOC());
  }
  return ccs811ParsedStringValue;
}

String getCCS811StringHeader(){
  return "CCS811_C02, CCS811_TVOC";
}

String getGPSStringHeader(){
  return "GPS_year, GPS_month, GPS_day, GPS_hour, GPS_minute, GPS_seconds, GPS_longitude, GPS_latitude, GPS_noSaltilites, GPS_fix";
}

String getCozIrStringHeader(){
  return "CozIr_Co2, CozIr_Co2_filtered";
}

String getCozIRStringLastReading(){
  String CozIRParsedStringValue = "0,0";
  if(CozIrLatestReadResult){
    CozIRParsedStringValue = CozIrCo2Value + ", " + CozIrCo2_filteredValue;
  }
  return CozIRParsedStringValue;
}

//NEXT SENSOR BELOW
