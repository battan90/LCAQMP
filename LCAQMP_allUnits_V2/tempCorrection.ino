float temp;
float correctionFactorNO2(){
  float n;
  temp = bme.temperature;
  if(temp < -20.0){
    n = 0.8;
  }
  else if((temp >= -20.0) && (temp < -10.0)){
    n = 0.8 + ((1-0.8)/10)*(temp - (-20.0));
  }
  else if((temp >= -10.0) && (temp < 0.0)){
    n = 1 + ((1.2-1)/10)*(temp - (-10.0));
  }
  else if((temp >= 0.0) && (temp < 10.0)){
    n = 1.2 + ((1.6-1.2)/10)*temp;
  }
  else if((temp >= 10.0) && (temp < 20.0)){
    n = 1.6 + ((1.8-1.6)/10)*(temp - 10.0);
  }
  else if((temp >= 20.0) && (temp < 30.0)){
    n = 1.8 + ((1.9-1.8)/10)*(temp - 20.0);
  }
  else if((temp >= 30) && (temp < 40.0)){
    n = 1.9 + ((2.5-1.9)/10)*(temp - 30.0);
  }
  else if(temp >= 40){
    n = 2.5 + ((3.6-2.5)/10)*(temp - 40.0);
  }
  else{
    n = 1.8; //20 Celsius
    //This shouldn't be able to happen,
    //but I added it as a failsafe
  }
  return n;
}

float correctionFactorOX(){
  float k;
  temp = bme.temperature;
  if(temp < -20.0){
    k = 0.1;
  }
  else if((temp >= -20.0) && (temp < -10.0)){
    k = 0.1 + ((0.2-0.1)/10)*(temp - (-20.0));
  }
  else if((temp >= -10.0) && (temp < 0.0)){
    k = 0.2 + ((0.3-0.2)/10)*(temp - (-10.0));
  }
  else if((temp >= 0.0) && (temp < 10.0)){
    k = 0.3 + ((0.7-0.3)/10)*temp;
  }
  else if((temp >= 10.0) && (temp < 20.0)){
    k = 0.7 + ((1.0-0.7)/10)*(temp - 10.0);
  }
  else if((temp >= 20.0) && (temp < 30.0)){
    k = 1.0 + ((1.7-1.0)/10)*(temp - 20.0);
  }
  else if((temp >= 30) && (temp < 40.0)){
    k = 1.7 + ((3.0-1.7)/10)*(temp - 30.0);
  }
  else if(temp >= 40){
    k = 3.0 + ((4.0-3.0)/10)*(temp - 40.0);
  }
  else{
    k = 1.0; //20 Celsius
    //This shouldn't be able to happen,
    //but I added it as a failsafe
  }
  return k;
}
