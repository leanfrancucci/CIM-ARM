#ifndef ROP_PERSISTENCE_H
#define ROP_PERSISTENCE_H

#define ROP_PERSISTENCE id

#include <Object.h>
#include "ctapp.h"
#include "Persistence.h"

/**
 *	Implementacion particular de factory de persistencia para el mecanismo de almacenamiento ROP.
 *	
 *	<<singleton>>
 */
@interface ROPPersistence : Persistence
{

}

+ new;
+ getInstance;


@end

#endif
