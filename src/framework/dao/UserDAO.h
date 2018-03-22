#ifndef USER_DAO_H
#define USER_DAO_H

#define USER_DAO id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"

/**
 *	Implementacion de la persistencia de la configuracion de los usuarios.
 *	Provee metodos para recuperar la configuracion de los usuarios.
 *
 *	<<singleton>>
 */
@interface UserDAO : DataObject
{
	COLLECTION myCompleteList;
	COLLECTION myActiveList;
	ABSTRACT_RECORDSET myUserRS;
	ABSTRACT_RECORDSET myDoorsByUserRS;
	BOOL myExistUserPims;
	BOOL myExistUserOverride;
}

+ getInstance;

/**/
- (void) loadCompleteList;
- (COLLECTION) getCompleteList;
- (COLLECTION) getActiveList;
- (COLLECTION) getDoorsByUser: (int) anUserId;
- (void) storeDoorByUser: (int) aDoorId userId: (int) anUserId;
- (void) removeDoorByUser: (int) aDoorId userId: (int) anUserId;
- (BOOL) existsDoor: (int) aDoorId;
- (void) storePin: (id) anObject oldPassword: (char *) anOldPassword;

/**/
- (BOOL) existUserPims;
- (BOOL) existUserOverride;

@end

#endif
