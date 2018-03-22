#ifndef OPERATION_DAO_H
#define OPERATION_DAO_H

#define OPERATION_DAO id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"

/**
 *	Provee metodos para recuperar la configuracion de las operaciones.
 *
 *	<<singleton>>
 */
@interface OperationDAO : DataObject
{
}

+ getInstance;
+ (COLLECTION) loadAll;

@end

#endif
