/* Function which collects O3 and NO2 sensor data
 */



//NO2 AND OZON VARIABLES:
// Definiera variabler eller pins

//float SN1_WE_u; //raw WE input
//float SN1_AE_u; //raw AE input
float SN1_WE_c; //corrected WE input
float SN1_AE_c; //corrected AE input
//float SN2_WE_u; //same thing for the second sensor...
//float SN2_AE_u;
float SN2_WE_c;
float SN2_AE_c;
float SN2_WE_c_NO2; //(NO2 concentration from SN1)*(SN2_SENSITIVITY_NO2)
float algFirstTerm; //Equivalent to (WE_u - WE_e) in the compensation algorithms.
//Used when calculating O3 concentration, which is done in a pretty special way.
//See "ApplicationNotes.pdf"

//Correction factors:
float n_T;
float k_prim_T;

//Offset and sensitivity data:

/* Offset and sensitivity data is vectorized, vector indice represents data for specific unit 
 *  Index 0 gives sensor and offset data for unit 1, index 1 for unit 2 ... index 9 for unit 10
 *  Uses variable unitNumber-1 for indice in in calculation. unitNumber is defined in "initFunctions". 
 *  
 *  Sensitivity and offset data is gathered from data sheet 
 */

float sensor_check[] = {0,0,0,0,1,1,0,0,0, 1}; // used to specify which units has NO2 and O3 sensor, 1 repr True and 0 repr false 
float SN1_WE_e[] =  {0,0,0,0,0.296 ,0.295,0,0,0, 0.290}; //electronic offset for WE
float SN1_AE_e[] =  {0,0,0,0,0.300,0.299,0,0,0,0.302}; //electronic offset for AE
float SN1_SENSITIVITY[] = {0,0,0,0,0.188,0.204,0,0,0,0.187}; //unit: (mV/ppb); used to determine gas concentration
 

float SN2_WE_e[] = {0,0,0,0,0.409,0.415,0,0,0, 0.413}; //electronic offset for WE
float SN2_AE_e[] = {0,0,0,0,0.408,0.401,0,0,0, 0.410 }; //electronic offset for AE
float SN2_WE_o[] = {0,0,0,0,-6.000,-8.000,0,0,0,-9.000}; //sensor zero offset for WE
float SN2_AE_o[] = {0,0,0,0,-3.000,-1.000,0,0,0,-4.000}; //sensor zero offset for AE 
float SN2_SENSITIVITY[] = {0,0,0,0,0.344,0.306,0,0,0, 0.355};
float SN2_SENSITIVITY_NO2[] = {0,0,0,0, 0.313,0.255,0,0,0, 0.331};



void readNO2andO3(){
  //See "ApplicationNotes.pdf for instructions!
  //Note that the steps aren't exactly in the same order as in document
  //The weird method of calculating O3 complicates things a little


  // Step 0.5: Logic if-statement to check if LCAQMP has NO2 and O3 sensor
  // Checks if the unit has sensors using sensor_check, only proceeds with calculations for NO2/O3 if sensor_check presenets 1 for indice 
  // If bool == false ( meaning sensor_check[unitNumber-1] == 0  ) for statement, all variables for 03/NO2 return -1 to represent fault in calculation. 

  if ( sensor_check[unitNumber-1] == 1) {
   
  //Step 1: Measure the WE and AE voltages from the AFE
 
    float SN2_SENSITIVITY[] = {0,0,0,0,0.344,0.306,0,0,0, 0.355};
    SN1_WE_u = analogRead(WE1Pin)*(cardVoltage/4095.0); //read WE voltage (NO2 sensor)
    delay(10);
    SN1_AE_u = analogRead(AE1Pin)*(cardVoltage/4095.0); //read AE voltage (NO2 sensor)
    delay(10);
    SN2_WE_u = analogRead(WE2Pin)*(cardVoltage/4095.0); //read WE voltage (OX sensor)
    delay(10);
    SN2_AE_u = analogRead(AE2Pin)*(cardVoltage/4095.0); //read AE voltage (OX sensor)
    delay(10);

  
  //Step 2: Determine temperature of operation
  //and select appropriate correction factors
    n_T = correctionFactorNO2(); //correction factor for NO2
    k_prim_T = correctionFactorOX(); //correction factor for OX

   

  
  //Step 3: Apply correction algorithm 1 for NO2  
  //(Algorithm 1 is used for NO2, and algorithm 3 is used for OX!)
    SN1_WE_c = (SN1_WE_u - SN1_WE_e[unitNumber-1]) - n_T*(SN1_AE_u - SN1_AE_e[unitNumber-1]); 

   
  
  //Step 4: Determine NO2 gas concentration
    NO2 = SN1_WE_c/SN1_SENSITIVITY[unitNumber-1]; //NO2 concentration from NO2-A43F sensor (global variable)
    SN2_WE_c_NO2 = NO2*SN2_SENSITIVITY_NO2[unitNumber-1]; //Stuff used for O3 calculation
    algFirstTerm = SN2_WE_u - SN2_WE_e[unitNumber-1] - SN2_WE_c_NO2;

    
  //Step 5: Apply algorithm 3 for OX
    SN2_WE_c = algFirstTerm - (SN2_WE_o[unitNumber-1] - SN2_AE_o[unitNumber-1]) - k_prim_T*(SN2_AE_u - SN2_AE_e[unitNumber-1]);

  //Step 6: Finally, determine O3 gas concentration
    O3 = SN2_WE_c/SN2_SENSITIVITY[unitNumber-1]; //O3 concentration (global variable)
  }


  // Step 0.5
  // If previous If-statement == false, assign -1 to all measurement variables to represent fault in measurement. 
  else if (sensor_check[unitNumber-1] != 1) {
    SN1_WE_u = -1; //read WE voltage (NO2 sensor)
    delay(10);
    SN1_AE_u = -1; //read AE voltage (NO2 sensor)
    delay(10);
    SN2_WE_u = -1; //read WE voltage (OX sensor)
    delay(10);
    SN2_AE_u = -1; //read AE voltage (OX sensor)
    delay(10);
    NO2      = -1;
    delay(10);
    O3       = -1;
  }
}
