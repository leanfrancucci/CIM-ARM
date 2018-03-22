#ifndef PROFILE_H
#define PROFILE_H

#define PROFILE id

#include "Object.h"
#include "ctapp.h"
#include "Operation.h"

typedef enum {
	ProfileId_UNDEFINED
 ,ProfileId_ADMINISTRATOR
 ,ProfileId_SUPERVISOR
 ,ProfileId_MANAGER
 ,ProfileId_ASSISTANT_MANAGER
 ,ProfileId_LEAD_OPERATOR
 ,ProfileId_OPERATOR
 ,ProfileId_REGIONAL
 ,ProfileId_ARMOR_CAR
 ,ProfileId_SUPPORT
} ProfileId;

typedef enum {
	SecurityLevel_0 //SecurityLevel_UNDEFINED. Se reemplazo el undefined por el nuvel 0
 ,SecurityLevel_1
 ,SecurityLevel_2
 ,SecurityLevel_3
} SecurityLevel;

/**
 *	Representa un perfil.
 * 	
 */
@interface Profile :  Object
{
	int myProfileId;
	char myName[30];
	int myFatherId;
	char myResource[10];
	BOOL myKeyRequired;
	BOOL myDeleted;
	BOOL myTimeDelayOverride;
  unsigned char myOperationsList[15];
  SecurityLevel mySecurityLevel;
	BOOL myUseDuressPassword;
}

+ new;
- initialize;

/**
 * Setea los valores correspondientes a los perfiles
 */

- (void) setProfileId: (int) aValue;
- (void) setProfileName: (char*) aValue;
- (void) setFatherId: (int) aValue;
- (void) setResource: (char*) aValue;
- (void) setKeyRequired: (BOOL) aValue;
- (void) setDeleted: (BOOL) aValue;
- (void) setTimeDelayOverride: (BOOL) aValue;
- (void) setOperationsList: (unsigned char*) aValue;
- (void) setSecurityLevel: (SecurityLevel) aValue;
- (void) setUseDuressPassword: (BOOL) aValue;

/**
 * Devuelve los valores correspondientes a los perfiles
 */

- (int) getProfileId;
- (char*) getProfileName;
- (int) getFatherId;
- (char*) getResource;
- (BOOL) getKeyRequired;
- (BOOL) isDeleted;
- (BOOL) getTimeDelayOverride;
- (unsigned char*) getOperationsList;
- (SecurityLevel) getSecurityLevel;
- (BOOL) getUseDuressPassword;

/**
 * Aplica los cambios realizados al perfil en la persistencia.
 */

- (void) applyChanges;

/**
 * Restaura los valores de la persistencia
 */

- (void) restore;

/**
 * Devuelve TRUE en el caso que posea permiso para realizar la operacion pasada como parametro.
 */
- (BOOL) hasPermission: (int) anOperationId;
 
@end

#endif

