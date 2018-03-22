#ifndef COM_PORT_H
#define COM_PORT_H

#define COM_PORT id 

#include <Object.h>
#include "system/io/all.h"
#include "system/os/all.h"

/**
 *	Encapsula el acceso a un puerto COM, independientemente del sistema operativo.
 *	Esta clase es abstracta y solo define la interfaz y algunos metodos para setear parametros.
 *	La implementacion real se delega a subclases que sepan como manejar el puerto COM para cada
 *	sistema operativo, abra una subclase para windows, otra para linux, etc.
 *
 *	El modo de funcionamiento es:
 *		1) Asginarle los parametros tales como numero de puerto, partidad, data bits, etc...
 *		2) Efectuar un open
 *		3) Realizar lecturas y escrituras
 *		...
 *		4) Realizar un close.
 */
@interface ComPort: Object
{
	int 			myReadTimeout;
	int 			myWriteTimeout;
	ParityType 		myParity;
	int 			myPortNumber;
	BaudRateType 	myBaudRate;
	int 			myStopBits;
	int 			myDataBits;
	OS_HANDLE 	myHandle;
	
	READER			myReader;
	WRITER			myWriter;

}

/**
 *
 */
- (int) getPortNumber;

/**
 *	Setea
 */
- (void) setBaudRate: (BaudRateType) aBaudRate;

/**
 *	Setea los stop bits (0..2)
 */
- (void) setStopBits: (int)aStopBits;

/**
 *	Setea los data bits (7..8)
 */
- (void) setDataBits: (int)aDataBits;

/**
 *	Setea la paridad (PARITY_NONE, PARITY_EVEN, PARITY_ODD)
 */
- (void) setParity: (ParityType) aParity;

/**
 *	Setea el numbero de puerto COM (1..n)
 */
- (void) setPortNumber: (int) aPortNumber;

/**
 *	Setea el timeout para las lecturas
 */
- (void) setReadTimeout: (int)aTimeout;

/**
 *	Setea el timeout para las escrituras
 */
- (void) setWriteTimeout: (int)aTimeout;

/**
 *	Abre el puerto COM, debe ser llamado luego de setear los parametros de configuracion.
 */
- (void) open;

/**
 *	Cierra el puerto COM.
 */
- (void) close;

/**
 *	Lee datos del puerto y los almacena en aBuf.
 */
- (int) read:(char *)aBuf qty: (int) aQty;

/**
 *	Escribe los datos contenidos en aBuf en el puerto.
 */
- (int)  write:(char *)aBuf qty: (int) aQty;

/**
 *	Devuelve el Writer para este Socket.
 */
- (WRITER) getWriter;

/**
 *	Devuelve el Reader para este Socket.
 */
- (READER) getReader;

/**
 *	Elimina los datos contenidos en el buffer del sistema operativo.
 */
- (void) flush;

/**
 *	Devuelve el handle al puerto COM.
 */
- (OS_HANDLE) getHandle;

@end

#endif
