#ifndef PARALLEL_PORT_READER_H
#define PARALLEL_PORT_READER_H

#define PARALLEL_PORT_READER id 

#include <Object.h>
#include "system/io/all.h"
#include "ParallelPort.h"

/**
 *	Reader para leer desde un ParallelPort. 
 *	Tiene internamente un atributo de tipo Parallel para realizar las lecturas.
 *
 *	No deberia crearse esta clase directamente, sino obtenerse a traves del metodo
 *	getReader del Parallel.
 */ 
@interface ParallelPortReader : Reader
{
	PARALLEL_PORT myParallelPort;
}

/**
 *	Inicializa ParallelReader con el Parallel pasado como parametro.
 */
- initWithParallelPort: (PARALLEL_PORT) aParallel;

/**
 * 	Efectua la lectura del Parallel.
 */
- (int) read: (char*)aBuf qty: (int)aQty;

@end

#endif
