#ifndef BARCODE_SCANNER_H
#define BARCODE_SCANNER_H

#define BARCODE_SCANNER id

#include <Object.h>
#include "ComPort.h"
#include "system/os/all.h"

/**
 *	Scanner de codigo de barras.
 *	El proceso de "scan" se hace de forma sincronica a pedido del usuario.
 */
@interface BarcodeScanner : OThread
{
	COM_PORT myComPort;
	int myTimeout;
	int myComPortNumber;
	BaudRateType myBaudRate;
	int myReadTimeout;
	id myObserver;
	BOOL myIsEnable;
}

/**
 *  Devuelve la unica instancia posible de esta clase
 */
+ getInstance;

/**/
- (void) setObserver: (id) anObserver;
- (void) removeObserver;

/**/
- (void) setComPortNumber: (int) aValue;

/**/
- (void) setBaudRate: (BaudRateType) aValue;

/**/
- (void) setReadTimeout: (int) aValue;

/**/
- (void) open;

/**/
- (void) close;

/** Lee el codigo de barras del dispositivo.
    @return la cantidad de datos leidos
*/
- (int) readBarcode: (char *) aBuffer;

/**/
- (void) enable;
- (void) disable;

@end

#endif
