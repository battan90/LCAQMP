// SDS011 dust sensor PM2.5 and PM10
// ---------------------
//
// By R. Zschiegner (rz@madavi.de)
//modified by Gustav Lindström
// Feb 2020
//
// Documentation:
//		- The iNovaFitness SDS011 datasheet
//


#if ARDUINO >= 100
	#include "Arduino.h"
#else
	#include "WProgram.h"
#endif

#include "Uart.h"


class SDS011 {
	public:
		SDS011(Uart *serialPort);
		int read(float *p25, float *p10);
		void sleep();
		void wakeup();
	private:
 		Uart *_serialPort;
};
