/* Function for collection temperature from PT1000 sensor
 *  This function is currently not in use at the moments
 */

float volt;
float tempy;
float input;
float term;
float term2;

void getTemp(){
  
  /*input = analogRead(PTPin)*1.0; //solve problem
  Serial.println(input);
  volt = input*(3.3/4095.0);
  Serial.println(volt,8);
  term = volt - 0.35;
  Serial.println(term,8);
  term2 = term*1000;
  Serial.println(term2);
  tempy = 22.0 + (volt-0.36)/1000.0;
  tempy = 22.0 + term2;
  Serial.println("PT1000 temperature " + String(tempy));*/
  //Serial.println(analogRead(PTPin)*cardVoltage/4095.0,4);
  PT1000temp = 22.0 + ((((analogRead(PTPin)/4095.0)*cardVoltage) - 2.4845) / 0.001);
  
}
