#ifndef PARALLEL_WRITER_H
#define PARALLEL_WRITER_H

#define PARALLEL_WRITER id 

#include <Object.h>
#include "system/io/all.h"
#include "ParallelPort.h"

/**
 *	Writer para escribir en un puerto paralelo. 
 *	Tiene internamente un atributo de tipo Parallel para realizar las escrituras.
 *
 *	No deberia crearse esta clase directamente, sino obtenerse a traves del metodo
 *	getWriter del Parallel.
 */
@interface ParallelPortWriter : Writer
{
	PARALLEL_PORT myParallelPort;
}

/**
 *	Inicializa el Writer con el puerto paralelo pasado como parametro.
 */	
- initWithParallelPort: (PARALLEL_PORT) aParallelPort;

/**
 *	Escribe los datos pasados como parametro en el puerto paralelo.
 */
- (int) write: (char*)aBuf qty: (int)aQty;

/**/
- (PARALLEL_PORT) getParallelPort;

@end

#endif
