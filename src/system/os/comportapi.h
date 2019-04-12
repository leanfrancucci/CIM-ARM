#ifndef COM_PORT_API_H
#define COM_PORT_API_H

#include "osrt.h"

/**
 *	La paridad.
 */
typedef enum {
	CT_PARITY_NONE,
	CT_PARITY_ODD,
	CT_PARITY_EVEN
} ParityType;

/**
 *	La velocidad del puerto COM (en baudios).
 */
typedef enum {
 	BR_0,
 	BR_50,
	BR_75,
  BR_110,
  BR_134,
  BR_150,
  BR_200,
  BR_300,
  BR_600,
  BR_1200,
  BR_1800,
  BR_2400,
  BR_4800,
  BR_9600,
  BR_19200,
  BR_38400,
  BR_57600,
  BR_115200,
  BR_230400
} BaudRateType;

/**
 *	La configuracion del puerto.
 */
typedef struct {
	BaudRateType baudRate;
	ParityType parity;
	int stopBits;
	int dataBits;
	int readTimeout;
	int writeTimeout;
    char ttyStr[20];
} ComPortConfig;

/**
 *
 */
OS_HANDLE com_open(int portNumber, ComPortConfig *config);

/**
 *
 */
int com_read(OS_HANDLE handle, char *buffer, int qty, int timeout);

/**
 *
 */
int com_write(OS_HANDLE handle, char *buffer, int qty);

/**
 *
 */
void com_close(OS_HANDLE handle);

/**
 *
 */
void com_flush(OS_HANDLE handle);


#endif

