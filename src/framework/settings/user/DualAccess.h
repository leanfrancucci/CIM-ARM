#ifndef DUAL_ACCESS_H
#define DUAL_ACCESS_H

#define DUAL_ACCESS id

#include "Object.h"
#include "ctapp.h"

/**
 *	Representa un acceso dual o dupla.
 * 	
 */
@interface DualAccess :  Object
{
	int myProfile1Id;
	int myProfile2Id;
	BOOL myDeleted;
	char myDescription[100];
}

+ new;
- initialize;

/**
 * Setea los valores correspondientes a los perfiles
 */

- (void) setProfile1Id: (int) aValue;
- (void) setProfile2Id: (int) aValue;
- (void) setDeleted: (BOOL) aValue;

/**
 * Devuelve los valores correspondientes a los perfiles
 */

- (int) getProfile1Id;
- (int) getProfile2Id;
- (BOOL) isDeleted;
	
/**
 * Aplica los cambios realizados al perfil en la persistencia.
 */

- (void) applyChanges;

/**
 * Restaura los valores de la persistencia
 */

- (void) restore;
 
@end

#endif

