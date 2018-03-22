#ifndef PARALLEL_PORT_H
#define PARALLEL_PORT_H

#define PARALLEL_PORT id 

#include <Object.h>
#include "system/io/all.h"
#include "system/os/all.h"

/**
 *	Encapsula el acceso a un puerto paralelo, independientemente del sistema operativo.
 *	Esta clase es abstracta y solo define la interfaz de acceso.
 *	La implementacion real se delega a subclases que sepan como manejar el puerto paralelo para cada
 *	sistema operativo, abra una subclase para windows, otra para linux, etc.
 */
 
@interface ParallelPort: Object
{
	OS_HANDLE 	myHandle;
	
	READER			myReader;
	WRITER			myWriter;

}

/**
 *	Abre el puerto paralelo.
 */
- (void) open;

/**
 *	Cierra el puerto paralelo.
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
 *	Devuelve el handle al puerto paralelo.
 */
- (OS_HANDLE) getHandle;

@end

#endif
