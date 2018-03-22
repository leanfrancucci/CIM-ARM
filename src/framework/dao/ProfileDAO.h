#ifndef PROFILE_DAO_H
#define PROFILE_DAO_H

#define PROFILE_DAO id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"
#include "DualAccess.h"

/**
 *	Implementacion de la persistencia de la configuracion de los perfiles.
 *	Provee metodos para recuperar la configuracion de los perfiles.
 *
 *	<<singleton>>
 */
@interface ProfileDAO : DataObject
{
	ABSTRACT_RECORDSET myProfileRS;
}

+ getInstance;
+ (COLLECTION) loadAll;
- (void) storeDualAccess: (int) aProfile1Id profile2Id: (int) aProfile2Id;
- (void) removeDualAccess: (int) aProfile1Id profile2Id: (int) aProfile2Id;
- (BOOL) existsProfile: (int) aProfileId;
- (COLLECTION) loadAllDualAccess;
- (DUAL_ACCESS) loadDualAccess: (int) aProfile1Id profile2Id: (int) aProfile2Id;

@end

#endif
