#include "Profile.h"
#include "Persistence.h"
#include "util.h"
#include "OperationDAO.h"
#include "UserManager.h"
#include "objpak.h"
#include "integer.h"
#include "MessageHandler.h"
#include "Collection.h"

@implementation Profile

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myProfileId = 0;
	myDeleted = FALSE;
  //myOperations = [Collection new];
  strcpy(myResource,"0");
  myKeyRequired = FALSE;
  myTimeDelayOverride = FALSE;
  memset(myOperationsList, 0, 14);
  mySecurityLevel = SecurityLevel_1;
	myUseDuressPassword = FALSE;
	return self;
}

/**/
- (void) setProfileId: (int) aValue { myProfileId = aValue; }
- (void) setProfileName: (char*) aValue { strncpy2(myName, aValue, sizeof(myName)-1); }
- (void) setFatherId: (int) aValue { myFatherId = aValue; }
- (void) setResource: (char*) aValue { strcpy(myResource, aValue); }
- (void) setKeyRequired: (BOOL) aValue { myKeyRequired = aValue; }
- (void) setDeleted: (BOOL) aValue { myDeleted = aValue; }
- (void) setTimeDelayOverride: (BOOL) aValue { myTimeDelayOverride = aValue; }
- (void) setOperationsList: (unsigned char*) aValue { memcpy(myOperationsList, aValue, 14); }
- (void) setUseDuressPassword: (BOOL) aValue { myUseDuressPassword = aValue; }
- (void) setSecurityLevel: (SecurityLevel) aValue 
{
  // Esto es porque antiguamente tenia el valor "0" en la tabla el valor security level el cual es invalido
  //if (aValue == SecurityLevel_UNDEFINED) mySecurityLevel = SecurityLevel_1;
  //else mySecurityLevel = aValue;

	if (myProfileId == 1) // Al admin siempre le cableo el nivel 1
  	mySecurityLevel = SecurityLevel_1;
  else mySecurityLevel = aValue;
}

/**/

- (int) getProfileId { return myProfileId; }
- (char*) getProfileName { return myName; }
- (int) getFatherId { return myFatherId; }
- (char*) getResource { return myResource; }
- (BOOL) getKeyRequired { return myKeyRequired; }
- (BOOL) isDeleted { return myDeleted; }
- (BOOL) getTimeDelayOverride { return myTimeDelayOverride; }
- (unsigned char*) getOperationsList { return myOperationsList; }
- (SecurityLevel) getSecurityLevel { return mySecurityLevel; }
- (BOOL) getUseDuressPassword { return myUseDuressPassword; }

/**/
- (void) applyChanges
{
	id profileDAO;
	profileDAO = [[Persistence getInstance] getProfileDAO];		

	[profileDAO store: self];
}

/**/
- (void) restore
{
	PROFILE obj;

	//Recupera el objeto de la persistencia
	obj =	[[[Persistence getInstance] getProfileDAO] loadById: [self getProfileId]];

	assert(obj != nil);
	//Setea los valores a la instancia en memoria
	[self setProfileName: [obj getProfileName]];
	[self setFatherId: [obj getFatherId]];
	[self setResource: [obj getResource]];
	[self setKeyRequired: [obj getKeyRequired]];
	[self setTimeDelayOverride: [obj getTimeDelayOverride]];
	[self setOperationsList: [obj getOperationsList]];
	[self setUseDuressPassword: [obj getUseDuressPassword]];

	[obj free];	
}

/**/
- (STR) str
{
  //if (strcmp(myResource,"0") == 0)
	return myName;
	//else
	//  return getResourceString(atoi(myResource));
}

/**/
- (BOOL) hasPermission: (int) anOperationId
{
  if ( getbit(myOperationsList, anOperationId) == 0 ) return FALSE;
  
  return TRUE;
}

@end

