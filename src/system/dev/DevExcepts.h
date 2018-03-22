#ifndef DEV_EXCEPTS_H
#define DEV_EXCEPTS_H

#include "excepts.h"

#define DEV_EXCEPT 		5000

//#define CANNOT_OPEN_DEVICE_EX			(OS_EXCEPT)
#define DEV_EX											(DEV_EXCEPT)
#define NO_DIALTONE_EX							(DEV_EXCEPT+1)
#define NO_ANSWER_EX								(DEV_EXCEPT+2)
#define NO_CARRIER_EX								(DEV_EXCEPT+3)
#define BUSY_EX											(DEV_EXCEPT+4)
#define CONNECTION_TIMEOUT_EX				(DEV_EXCEPT+5)
#define MODEM_NOT_RESPONDING_EX			(DEV_EXCEPT+6)

#endif
