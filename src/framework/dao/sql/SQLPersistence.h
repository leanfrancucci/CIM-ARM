#ifndef SQL_PERSISTENCE_H
#define SQL_PERSISTENCE_H

#define SQL_PERSISTENCE id

#include <Object.h>
#include "ctapp.h"
#include "Persistence.h"

/**
 *	Implementacion particular de factory de persistencia para el mecanismo de almacenamiento SQL.
 *	
 *	<<singleton>>
 */
@interface SQLPersistence : Persistence
{

}

+ new;
+ getInstance;


@end

#endif
