#ifndef OPERATION_H
#define OPERATION_H

#define OPERATION id

#include "Object.h"
#include "ctapp.h"

/**
 *	Representa una operacion.
 * 	
 */
@interface Operation:  Object
{
	int myOperationId;
	char myName[100];
	char myResource[100];
	BOOL myDeleted;
}

+ new;
- initialize;

/**
 * Setea los valores correspondientes a las operaciones
 */

- (void) setOperationId: (int) aValue;
- (void) setOpName: (char*) aValue;
- (void) setOpResource: (char*) aValue;
- (void) setDeleted: (BOOL) aValue;


/**
 * Devuelve los valores correspondientes a las operaciones
 */

- (int) getOperationId;
- (char*) getOpName;
- (char*) getOpResource;
- (BOOL) isDeleted;

@end

#endif

