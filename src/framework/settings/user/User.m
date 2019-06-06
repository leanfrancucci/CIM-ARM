#include "User.h"
#include "Persistence.h"
#include "util.h"
#include "UserManager.h"    
#include "SettingsExcepts.h"
#include "OperationDAO.h"
#include "Collection.h"
#include "system/util/all.h"
#include "CimManager.h"
#include "RegionalSettings.h"
#include "UserDAO.h"

@implementation User

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myUserId = 0;
	myDeleted = FALSE;
	myLoginMethod = LoginMethod_PERSONALIDNUMBER;
	myActive = TRUE;
	myLastLoginDateTime = [SystemTime getLocalTime];
	myEnrollDateTime = [SystemTime getLocalTime];
	myIsTemporaryPassword = TRUE;
	strcpy(myKey,"");
	myDoors = [Collection new];
	*myRealPassword = '\0';
	myLanguage = [[RegionalSettings getInstance] getLanguage];
	myIsSpecialUser = FALSE;
	usesDynamicPin = FALSE;
	*closingCode = '\0';
	*previousPin = '\0';
	return self;
}

/**/
- (void) setUserId: (int) aValue { myUserId = aValue; }
- (void) setUName: (char*) aValue { stringcpy(myName, aValue); }
- (void) setUSurname: (char*) aValue { stringcpy(mySurname, aValue); }
- (void) setLoginName: (char*) aValue { stringcpy(myLoginName, aValue); }
- (void) setPassword: (char*) aValue { stringcpy(myPassword, aValue); }
- (void) setDuressPassword: (char*) aValue { stringcpy(myDuressPassword, aValue); }
- (void) setUProfileId: (int) aValue { myProfileId = aValue; }
- (void) setDeleted: (BOOL) aValue { myDeleted = aValue; }
- (void) setActive: (BOOL) aValue { myActive = aValue; }
- (void) setIsTemporaryPassword: (BOOL) aValue { myIsTemporaryPassword = aValue; }
- (void) setLastLoginDateTime: (datetime_t) aValue { myLastLoginDateTime = aValue; }
- (void) setLastChangePasswordDateTime: (datetime_t) aValue { myLastChangePasswordDateTime = aValue; }
- (void) setBankAccountNumber: (char*) aValue { stringcpy(myBankAccountNumber, aValue); }
- (void) setLoginMethod: (int) aValue { myLoginMethod = aValue; }
- (void) setEnrollDateTime: (datetime_t) aValue { myEnrollDateTime = aValue; }
- (void) setClosingCode: (char*) aValue { stringcpy(closingCode, aValue); }
- (void) setPreviousPin: (char*) aValue { stringcpy(previousPin, aValue); }
- (void) setUsesDynamicPin: (BOOL) aValue { usesDynamicPin = aValue; }

- (void) setKey: (char*) aValue 
{ 
  // Esto es por antiguamente el DallasKey salia con un valor "0" (lo cual es invalido)
  if (strcmp(aValue, "0") == 0) strcpy(myKey, "");
  else stringcpy(myKey, aValue); 
}
- (void) setRealPassword: (char *) aRealPassword { 
	stringcpy(myRealPassword, aRealPassword); 
}
- (void) setLanguage: (LanguageType) aLanguage { myLanguage = aLanguage; }
- (void) setIsSpecialUser: (BOOL) aValue { myIsSpecialUser = aValue; }

/**/
- (int) getUserId { return myUserId; } 
- (char*) getUName { return myName; }
- (char*) getUSurname { return mySurname; }
- (char*) getLoginName { return myLoginName; }
- (char*) getPassword { return myPassword; }
- (char*) getDuressPassword { return myDuressPassword; }
- (int) getUProfileId { return myProfileId; }
- (BOOL) isDeleted { return myDeleted; }
- (BOOL) isActive { return myActive; }
- (BOOL) isTemporaryPassword { return myIsTemporaryPassword; }
- (datetime_t) getLastLoginDateTime { return myLastLoginDateTime; }
- (datetime_t) getLastChangePasswordDateTime { return myLastChangePasswordDateTime; }
- (char*) getBankAccountNumber { return myBankAccountNumber; }
- (int) getLoginMethod { return myLoginMethod; }
- (datetime_t) getEnrollDateTime { return myEnrollDateTime; }
- (char*) getKey { return myKey; }
- (char*) getRealPassword { return myRealPassword; }
- (LanguageType) getLanguage { return myLanguage; }
- (BOOL) isSpecialUser { return myIsSpecialUser; }
- (char *) getClosingCode { return closingCode; }
- (char *) getPreviousPin { return previousPin;}
- (BOOL) getUsesDynamicPin { return usesDynamicPin;}


/**/
- (char*) getFullName
{
	strcpy(myFullName, [self getUSurname]);
	if (strlen([self getUSurname]) != 0 &&
		  strlen([self getUName]) != 0) strcat(myFullName, ", ");
	strcat(myFullName, [self getUName]);
	return myFullName;
}

/**/
- (void) applyChanges
{
	id userDAO;
	userDAO = [[Persistence getInstance] getUserDAO];

	// antes de grabar verifico si debo setear un duress password ficticio dependiendo
	// de si el perfil del usuario use o no la duress password.
	if (![[self getProfile] getUseDuressPassword]) {
		[self setDuressPassword: BLANK_DURESS_PASSWORD];
	}

	[userDAO store: self];
}

/**/
- (void) applyPinChanges: (char *) anOldPassword
{
	id userDAO;
	userDAO = [[Persistence getInstance] getUserDAO];
    
    printf("applyPinChanges oldPassword = %s , newPassword = %s \n", anOldPassword, myPassword);

	// antes de grabar verifico si debo setear un duress password ficticio dependiendo
	// de si el perfil del usuario use o no la duress password.
	if (![[self getProfile] getUseDuressPassword]) {
		[self setDuressPassword: BLANK_DURESS_PASSWORD];
	}

	[userDAO storePin: self oldPassword: anOldPassword];
}

/**/
- (void) restore
{
	USER obj;

	//Recupera el objeto de la persistencia
	obj =	[[[Persistence getInstance] getUserDAO] loadById: [self getUserId]];		

	assert(obj != nil);
	//Setea los valores a la instancia en memoria
	[self setUName: [obj getUName]];
	[self setUSurname: [obj getUSurname]];
	[self setLoginName: [obj getLoginName]];
	[self setPassword: [obj getPassword]];
	[self setUProfileId: [obj getUProfileId]];
	[self setDuressPassword: [obj getDuressPassword]];	
	[self setActive: [obj isActive]];
	[self setIsTemporaryPassword: [obj isTemporaryPassword]];
	[self setLastLoginDateTime: [obj getLastLoginDateTime]];
	[self setLastChangePasswordDateTime: [obj getLastChangePasswordDateTime]];
	[self setBankAccountNumber: [obj getBankAccountNumber]];
	[self setLoginMethod: [obj getLoginMethod]];
	[self setEnrollDateTime: [obj getEnrollDateTime]];
	[self setKey: [obj getKey]];
	[self setClosingCode: [obj getClosingCode]];
	[self setPreviousPin: [obj getPreviousPin]];
	[self setUsesDynamicPin: [obj getUsesDynamicPin]];
	

	[obj free];	
}

/**/
- (void) setLoggedIn: (BOOL) aValue
{
    printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> user setLoggedIn = %d  value = %d \n", myUserId, aValue);
	myLoggedIn = aValue;
}

/**/
- (BOOL) isLoggedIn
{
	return myLoggedIn;
}

/**/
- (STR) str
{
	return [self getFullName];
}

/**/
- (BOOL) hasPermission: (int) anOperationId
{
	unsigned char operationsL[15];
	
	// al id de la operacion le resto 1 porque la cadena lo almacena desde la posicion 0.
	// osea que la posicion 0 es el id de operacion 1, ..., posicion 41 es el id de operacion 42 
  	return (getbit(operationsL, (anOperationId - 1)) == 1);
}

/**/
- (COLLECTION) getDoors
{
	if ([myDoors size] == 0) [self initializeDoorsByUser];
  return myDoors;
}

/**/
- (void) initializeDoorsByUser
{
	COLLECTION myDoorsList;
	int i;
  id obj;
	id door;

	// si la lista ya tiene datos salgo
	if ([myDoors size] > 0) return;

    obj = [[Persistence getInstance] getUserDAO];
	myDoorsList =	[obj getDoorsByUser: myUserId];
	
  for (i=0;i<[myDoorsList size];++i) {

		door = [[CimManager getInstance] getDoorById: [[myDoorsList at: i] intValue]];

		// agrego la puerta a la lista de puertas del usuario
    [myDoors add: door];

		// agrego al usuario a la lista de usuarios de la puerta
		[door addUserToDoor: self];
  }
  
	[myDoorsList freeContents];
	[myDoorsList free];
}

/**/
- (void) removeDoorByUserToCollection: (int) aDoorId
{
	int i = 0;
	id door = NULL;

	if ([myDoors size] == 0) [self initializeDoorsByUser];

	for (i=0; i<[myDoors size]; ++i) {
		door = [myDoors at: i];
		if ([door getDoorId] == aDoorId) {
			// quito la asociacion en la usuario
			[myDoors removeAt: i];

			// quito la asociacion en la puerta
			[door removeUserFromDoor: self];

			return;
		}
	}

}

/**/
- (void) addDoorByUserToCollection: (int) aDoorId
{
	id door = NULL;

	door = [[CimManager getInstance] getDoorById: aDoorId];
	// agrego la asociacion en el usuario
  [myDoors add: door];

	// agrego la asociacion en la puerta
	[door addUserToDoor: self];
}

/**/
- (DOOR) getUserDoor: (int) aDoorId
{
	int i = 0;

	if ([myDoors size] == 0) [self initializeDoorsByUser];

  for (i=0; i<[myDoors size];++i)
		if ([ [myDoors at: i] getDoorId] == aDoorId) return [myDoors at: i];
	
	return NULL;
  
}

/**/
- (BOOL) hasAccessToDoor: (DOOR) aDoor
{
	int i = 0;

	if ([myDoors size] == 0) [self initializeDoorsByUser];

  for (i = 0; i < [myDoors size]; ++i)
		if ([[myDoors at: i] getDoorId] == [aDoor getDoorId]) return TRUE;
	
	return FALSE;
}

/**/
- (PROFILE) getProfile
{
  return [[UserManager getInstance] getProfile: myProfileId];
}

/**/
- (BOOL) isDallasKeyRequired
{
  PROFILE profile = [self getProfile];

	if ([profile getSecurityLevel] == SecurityLevel_2 || [profile getSecurityLevel] == SecurityLevel_3 || 
      [self getLoginMethod] == LoginMethod_DALLASKEY || [self getLoginMethod] == LoginMethod_SWIPE_CARD_READER) 
    return TRUE;

  return FALSE;
}

/**/
- (BOOL) isPinRequired
{
	PROFILE profile = [self getProfile];

	if ([profile getSecurityLevel] == SecurityLevel_2 || [profile getSecurityLevel] == SecurityLevel_3 || 
      [self getLoginMethod] == LoginMethod_PERSONALIDNUMBER) 
    return TRUE;

  return FALSE;	
}

/**/
- (char *) getDallasKeyLoginName
{
  sprintf(myDallasKeyLoginName, "D%s", [self getLoginName]);
  return myDallasKeyLoginName; 
}

/**/
- (unsigned short) getDevListMask
{
	int i;
	unsigned short devList = 0;
	unsigned short mask;

	if ([myDoors size] == 0) [self initializeDoorsByUser];

	for (i = 0; i < [myDoors size]; ++i) {
		mask = [[myDoors at: i] getLockHardwareId];
		devList = devList | mask;
	}

	return devList;
}

- (BOOL) getWasPinGenerated { return pinJustGenerated; }

- (void) setWasPinGenerated: (BOOL) pinGenerated { pinJustGenerated = pinGenerated; }

@end

