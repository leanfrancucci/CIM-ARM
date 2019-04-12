#include "UserManager.h"
#include "Profile.h"
#include "User.h"
#include "Operation.h"
#include "Persistence.h"
#include "SettingsExcepts.h"
#include "ProfileDAO.h"
#include "MessageHandler.h"
#include "Audit.h"
#include "util.h"
#include <stdlib.h> 
#include "UserDAO.h"
#include "CtSystem.h" 
#include "CimGeneralSettings.h"
#include "system/util/all.h"
#include "Event.h"
#include "CimManager.h"
#include "UserDAO.h"
#include "DualAccess.h"
#include "SafeBoxHAL.h"
#include "Acceptor.h"
#include "PrinterSpooler.h"
#include "CimExcepts.h"
#include "InputKeyboardManager.h"
#include "TelesupervisionManager.h"
#include "TelesupScheduler.h"


//#define printd(args...) doLog(0,args)
//#define printd(args...)


static id singleInstance = NULL;


@implementation UserManager


/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
  [singleInstance initialize];
	return singleInstance;
 
}

/**/
+ getInstance
{
	return [self new];	
}


/**/
- initialize
{
	id dao;
	int i;

	// La carga de operaciones debe encontrarse antes que la carga de perfiles, debido a que 
	// la carga de estos ultimos utiliza la coleccion de operaciones.
	myOperations = [[[Persistence getInstance] getOperationDAO] loadAll];
	myProfiles = [[[Persistence getInstance] getProfileDAO] loadAll];
	myDualAccessList = [[[Persistence getInstance] getProfileDAO] loadAllDualAccess];

	myUserPims = NULL;
	myUserOverride = NULL;

	dao = [[Persistence getInstance] getUserDAO];
	[dao loadCompleteList];
 

	myUsersCompleteList = [dao getCompleteList];
	myUsers = [dao getActiveList];

	
	myExistUserPims = [dao existUserPims];
	myExistUserOverride = [dao existUserOverride];

	if(myExistUserPims) printf("EXISTE EL PIMS\n");


//	for (i=0; i<[myUsers size]; ++i)
		//printf("login = %s\n", [[myUsers at: i] getLoginName]);
		


	// cargo una lista de usuarios sin incluir al superusuario
	[self setVisibleUsers];
	
	// cargo una lista de perfiles sin incluir al ADMIN
	[self setVisibleProfiles];
		
	// verifico si debo crear a los usuarios especiales PIMS y Override
		
	[self verifiedSpecialUsers];

	myLoginInProcess = FALSE;

	myUserToLogin[0] = '\0';
	myPasswordToLogin[0] = '\0';
	myUserToLoginResponse = FALSE; // TRUE es correcto FALSE es error
	myUserToLoginName[0] = '\0';
	myUserToLoginSurname[0] = '\0';

    myHoytsUser = NULL;

  return self;
}

/*******************************************************************************************
*																			PROFILE SETTINGS
*
*******************************************************************************************/

/**/
- (PROFILE) getProfile: (int) aProfileId
{
	int i = 0;
	
	for (i=0; i<[myProfiles size];++i) 
		if ([ [myProfiles at: i] getProfileId] == aProfileId) return [myProfiles at: i];
	
	THROW(REFERENCE_NOT_FOUND_EX);
	return NULL;
}

/**/
- (PROFILE) getProfileByName: (char*) aProfileName
{
	int i = 0;


	for (i=0; i<[myProfiles size];++i) {
		if ( strcasecmp(aProfileName, [[myProfiles at: i] getProfileName]) == 0 ) 
			return [myProfiles at: i];
	}
	
	THROW(REFERENCE_NOT_FOUND_EX);	
	return NULL;
}

/**/
- (void) setProfileName: (int) aProfileId value: (char*) aValue
{
	PROFILE obj = [self getProfile: aProfileId];
	[obj setProfileName: aValue];
}

/**/
- (void) setFatherId: (int) aProfileId value: (int) aValue
{
	PROFILE obj = [self getProfile: aProfileId];
	[obj setFatherId: aValue];
}

/**/
- (void) setResource: (int) aProfileId value: (char*) aValue
{
	PROFILE obj = [self getProfile: aProfileId];
	[obj setResource: aValue];
}

/**/
- (void) setKeyRequired: (int) aProfileId value: (BOOL) aValue
{
	PROFILE obj = [self getProfile: aProfileId];
	[obj setKeyRequired: aValue];
}


- (void) setSecurityLevel: (int) aProfileId value: (SecurityLevel) aValue
{
	PROFILE obj = [self getProfile: aProfileId];
	[obj setSecurityLevel: aValue];
}

- (void) setTimeDelayOverride: (int) aProfileId value: (BOOL) aValue
{
	PROFILE obj = [self getProfile: aProfileId];
	[obj setTimeDelayOverride: aValue];
}

- (void) setUseDuressPassword: (int) aProfileId value: (BOOL) aValue
{
	PROFILE obj = [self getProfile: aProfileId];
	[obj setUseDuressPassword: aValue];
}

- (void) setOperationsList: (int) aProfileId value: (unsigned char*) aValue
{
	PROFILE obj = [self getProfile: aProfileId];
	[obj setOperationsList: aValue];
}

/**/
- (char*) getProfileName: (int) aProfileId
{
	PROFILE obj = [self getProfile: aProfileId];
	return [obj getProfileName];
}

/**/
- (int) getFatherId: (int) aProfileId
{
	PROFILE obj = [self getProfile: aProfileId];
	return [obj getFatherId];
}

/**/
- (char*) getResource: (int) aProfileId
{
	PROFILE obj = [self getProfile: aProfileId];
	return [obj getResource];
}

/**/
- (BOOL) getKeyRequired: (int) aProfileId
{
	PROFILE obj = [self getProfile: aProfileId];
	return [obj getKeyRequired];
}

/**/
- (SecurityLevel) getSecurityLevel: (int) aProfileId
{
	PROFILE obj = [self getProfile: aProfileId];
	return [obj getSecurityLevel];
}

/**/
- (BOOL) getTimeDelayOverride: (int) aProfileId
{
	PROFILE obj = [self getProfile: aProfileId];
	return [obj getTimeDelayOverride];
}

/**/
- (BOOL) getUseDuressPassword: (int) aProfileId
{
	PROFILE obj = [self getProfile: aProfileId];
	return [obj getUseDuressPassword];
}

- (unsigned char*) getOperationsList: (int) aProfileId
{
	PROFILE obj = [self getProfile: aProfileId];
	return [obj getOperationsList];
}

/**/
- (void) applyProfileChanges: (int) aProfileId
{
	PROFILE obj = [self getProfile: aProfileId];
  
	[obj applyChanges];
}

/**/
- (int) addProfile:(char*) aName resource: (char*) aResource keyRequired: (BOOL) aKeyRequired fatherId: (int) aFatherId timeDelayOverride: (BOOL) aTimeDelayOverride operationsList: (unsigned char*) anOperationsList securityLevel: (SecurityLevel) aSecurityLevel useDuressPassword: (BOOL) anUseDuressPassword
{
  char buffer[4];
  PROFILE	newProfile = [Profile new];
	
	[newProfile setProfileName: aName];
	[newProfile setFatherId: aFatherId];
	[newProfile setResource: aResource];
	[newProfile setKeyRequired: aKeyRequired];
	[newProfile setTimeDelayOverride: aTimeDelayOverride];
	[newProfile setOperationsList: anOperationsList];
	[newProfile setSecurityLevel: aSecurityLevel];
	[newProfile setUseDuressPassword: anUseDuressPassword];

	[newProfile applyChanges];
		
	[self addProfileToCollection: newProfile];
  
  // Audita la insercion de un nuevo perfil
  snprintf(buffer, sizeof(buffer) - 1, "%s", [newProfile getProfileName]);

	return [newProfile getProfileId];
}

- (BOOL) canRemoveProfile: (int) aProfileId
{
  COLLECTION myC;
  int i;
  BOOL res;

  res = TRUE;
  
  // antes de eliminar hago el control para ver si es posible eliminarlo
  // 1) Si es perfil = 1 no permito eliminarlo porque es el perfil ADMIN.
  if (aProfileId == 1) res = FALSE;
  
  // 2) verifico que no tenga usuarios asociados
  if (res) {
    if ([self hasAssociatedUsers: aProfileId]) res = FALSE;
  }
  
  // 3) verifico que sus hijos tampoco los tengan
  if (res) {
    myC = [Collection new];
    [self getChildProfiles: aProfileId childs: myC];
    for (i=0; i<[myC size]; ++i) {
  	  if (res)
        if ([self hasAssociatedUsers: [[myC at: i] getProfileId]]) res = FALSE;
    }
		[myC free];
  }
  
  return res;
}

- (void) removeProfile: (int) aProfileId
{
  PROFILE aProfile = [self getProfile: aProfileId];
  COLLECTION myC;
  int i;

	// verifico si el perfil existe
	if (!aProfile) THROW(REFERENCE_NOT_FOUND_EX);

  // antes de eliminar hago el control para ver si es posible eliminarlo
  // 1) Si es perfil = 1 no permito eliminarlo porque es el perfil ADMIN.
  if (aProfileId == 1) THROW(NOT_DELETE_PROFILE_ADMIN_EX);
  
  // 2) verifico que no tenga usuarios asociados
  if ([self hasAssociatedUsers: aProfileId]) THROW(USER_ASSOCIATED_PROFILE_EX);
  
  // 3) verifico que sus hijos tampoco los tengan
  myC = [Collection new];
  [self getChildProfiles: aProfileId childs: myC];
  for (i=0; i<[myC size]; ++i) {
	  if ([self hasAssociatedUsers: [[myC at: i] getProfileId]]) {
			[myC free];
			THROW(USER_ASSOCIATED_CHILD_PROFILE_EX);
		}
  }

  // 4) si 1, 2 y 3 se cumplen hago el borrado del perfil (si tiene hijos hacer borrado en cascada)
  // borro el padre
  [self deleteProfile: aProfile];
  // borro a los hijos (si los tiene)
  for (i=0; i<[myC size]; ++i) {
	  [self deleteProfile: [myC at: i]];
  }

	[myC free];
}

/**
 * Remueve un prefil y sus hijos (si los tiene)
 */

- (void) deleteProfile: (PROFILE) aProfile
{
  char buffer[4];
  int aProfileId = 0;
  
  // elimino el perfil
  aProfileId = [aProfile getProfileId];
	[aProfile setDeleted: TRUE];
	[aProfile applyChanges];
	[self removeProfileFromCollection: aProfileId];
	[self removeProfileFromVisibleCollection: aProfileId];
  
  // Audita la eliminacion de un perfil
  snprintf(buffer, sizeof(buffer) - 1, "%d", aProfileId);  

}

/**/
- (void) addProfileToCollection: (PROFILE) aProfile
{
	[myProfiles add: aProfile];
	[myVisibleProfilesList add: aProfile];
}

/**/
- (void) removeProfileFromCollection: (int) aProfileId
{
	int i = 0;
	
	for (i=0; i<=[myProfiles size]-1; ++i) 
		if ([ [myProfiles at: i] getProfileId] == aProfileId) {
			[myProfiles removeAt: i];
			return;
		}
}

/**/
- (void) removeProfileFromVisibleCollection: (int) aProfileId
{
	int i = 0;
	
	for (i=0; i<=[myVisibleProfilesList size]-1; ++i)
		if ([ [myVisibleProfilesList at: i] getProfileId] == aProfileId) {
			[myVisibleProfilesList removeAt: i];
			return;
		}
}

/**/
- (void) restoreProfile: (int) aProfileId
{
	PROFILE obj = [self getProfile: aProfileId];

	[obj restore];
}

/**/
- (COLLECTION) getProfiles
{
	return myProfiles;
}

/**/
- (COLLECTION) getProfileIdList
{
	COLLECTION list = [Collection new];
	COLLECTION profiles = [self getProfiles];
	int i;

	for (i = 0; i < [profiles size]; ++i)
	{
		[list add: [BigInt int: [[profiles at: i] getProfileId]]];
	}
	
	return list;
}

/**/
- (void) getChildProfiles: (int) aProfileId childs: (COLLECTION) aChild
{
	int i,j;
	BOOL exists;
	
	for (i=0; i<[myProfiles size]; ++i){
	  if ((![[myProfiles at: i] isDeleted]) && ([ [myProfiles at: i] getFatherId] == aProfileId)) {
      	    exists = FALSE;
	    j = 0;
     	    while ((j<[aChild size]) && (!exists)){
              if ([aChild at: j] == [myProfiles at: i])
          	exists = TRUE;
          
              j++;
      	    }
      
      	    // si no existe la inserto en la lista
      	    if (!exists)
              [aChild add: [myProfiles at: i]];
        
            // llamo a si mismo para ver si tiene hijos dicho nodo
            [self getChildProfiles: [[myProfiles at: i] getProfileId] childs: aChild];
	  }
	}
}

/**/
- (COLLECTION) getVisibleProfiles
{
  id user = NULL;
  id profile;
  
  user = [self getUserLoggedIn];
  if (user != NULL){
    profile = [self getProfile: [user getUProfileId]];
    
    [myVProfiles removeAll];
    
    //agrego el perfil logueado
    if ([profile getProfileId] != 1)
      [myVProfiles add: profile];
      
    // agrego los hijos
    [self getChildProfiles: [profile getProfileId] childs: myVProfiles];
      
    return myVProfiles;
  }else  
	  return myVisibleProfilesList;
}

/**/
- (COLLECTION) getProfilesWithChildren: (int) aProfileId
{
  id profile;
  COLLECTION myP; 
  
  myP = [Collection new];
  profile = [self getProfile: aProfileId];
  
  //agrego el perfil pasado por parametro
  [myP add: profile];
  // agrego los hijos
  [self getChildProfiles: aProfileId childs: myP];
    
  return myP;

}

/**/
- (void) setVisibleProfiles
{
	int i = 0;
  PROFILE profile;

  myVisibleProfilesList = [Collection new];
  myVProfiles = [Collection new];
  for (i=0; i<[myProfiles size];++i) 
		if ([ [myProfiles at: i] getProfileId] != 1){
      profile = [myProfiles at: i]; 
      [myVisibleProfilesList add: profile];
    }
}

- (BOOL) hasAssociatedUsers: (int) aProfileId
{
	int i = 0;
		
  for (i=0; i<[myUsers size];++i) 
		if ([ [myUsers at: i] getUProfileId] == aProfileId) return TRUE;
	
	return FALSE;
}

/**/
- (void) deactivateOpByChildrenProfile: (int) aProfileId operationsList: (unsigned char*) anOperationsList
{
	COLLECTION myC;
	int i,j;
	id profile;
	unsigned char opL[15];
	BOOL wasEditedList;
  
  // si tiene hijos elimino las operacion del perfil de estos tambien
  myC = [Collection new];
  [self getChildProfiles: aProfileId childs: myC];
  for (i=0; i<[myC size]; ++i) {

    profile = [myC at: i];
    memset(opL, 0, 14);
    memcpy(opL, [profile getOperationsList], 14);
		wasEditedList = FALSE;

    for (j=1; j<= OPERATION_COUNT; ++j) {
      if (getbit(anOperationsList, j) == 0) {
				if (getbit(opL, j) == 1) {
        	setbit(opL, j, 0);
					wasEditedList = TRUE;
				}
			}
    }

		// actualizo la lista solo si se ha quitado una operacion
		if (wasEditedList) {
			[profile setOperationsList: opL];
			[profile applyChanges];
		}
  }
	[myC free];

}

/*******************************************************************************************
*																			USER SETTINGS
*
*******************************************************************************************/

/**/

- (USER) getUser: (int) aUserId
{
	int i = 0;
		
  for (i=0; i<[myUsers size];++i) 
		if ([ [myUsers at: i] getUserId] == aUserId) return [myUsers at: i];
	
	return NULL;
}


/**/
- (USER) getUserFromCompleteList: (int) aUserId
{
	int i = 0;

	assert(myUsersCompleteList);

	for (i = 0; i < [myUsersCompleteList size];++i) 
		if ([ [myUsersCompleteList at: i] getUserId] == aUserId) return [myUsersCompleteList at: i];

	return NULL;
}

/*SET*/

/**/
- (void) setUserName: (int) aUserId value: (char*) aValue
{
	USER obj = [self getUser: aUserId];
	[obj setUName: aValue];
}

/**/
- (void) setUserSurname: (int) aUserId value: (char*) aValue
{
	USER obj = [self getUser: aUserId];
	[obj setUSurname: aValue];
}

/**/
- (void) setUserLoginName: (int) aUserId value: (char*) aValue
{
	USER obj = [self getUser: aUserId];
	[obj setLoginName: aValue];
}

/**/
- (void) setUserPassword: (int) aUserId value: (char*) aValue
{
	USER obj = [self getUser: aUserId];
	[obj setPassword: aValue];
}

/**/
- (void) setUserProfileName: (int) aUserId value: (char*) aValue
{
	USER user = [self getUser: aUserId];
	PROFILE profile = [self getProfileByName: aValue];
	[user setProfileId: [profile getProfileId]];
}

/**/
- (void) setUserProfileId: (int) aUserId value: (int) aValue
{
	USER obj = [self getUser: aUserId];
	[obj setUProfileId: aValue];
}

/**/
- (void) setUserDuressPassword: (int) aUserId value: (char*) aValue
{
	USER obj = [self getUser: aUserId];
	[obj setDuressPassword: aValue];
}

/**/
- (void) setUserActive: (int) aUserId value: (BOOL) aValue
{
	USER obj = [self getUser: aUserId];
	[obj setActive: aValue];
}

- (void) setUserUsesDynamicPin: (int) aUserId value: (BOOL) aValue
{
	USER obj = [self getUser: aUserId];
	[obj setUsesDynamicPin: aValue];
}

- (BOOL) getUserUsesDynamicPin: (int) aUserId
{
	USER obj = [self getUser: aUserId];
	return [obj getUsesDynamicPin];
}

/**/
- (void) setUserIsTemporaryPassword: (int) aUserId value: (BOOL) aValue
{
	USER obj = [self getUser: aUserId];
	[obj setIsTemporaryPassword: aValue];
}

/**/
- (void) setUserLastLoginDateTime: (int) aUserId value: (datetime_t) aValue
{
	USER obj = [self getUser: aUserId];
	[obj setLastLoginDateTime: aValue];
}

/**/
- (void) setUserLastChangePasswordDateTime: (int) aUserId value: (datetime_t) aValue
{
	USER obj = [self getUser: aUserId];
	[obj setLastChangePasswordDateTime: aValue];
}

/**/
- (void) setUserBankAccountNumber: (int) aUserId value: (char*) aValue
{
	USER obj = [self getUser: aUserId];
	[obj setBankAccountNumber: aValue];
}

/**/
- (void) setUserLoginMethod: (int) aUserId value: (int) aValue
{
	USER obj = [self getUser: aUserId];
	[obj setLoginMethod: aValue];
}

/**/
- (void) setUserEnrollDateTime: (int) aUserId value: (datetime_t) aValue
{
	USER obj = [self getUser: aUserId];
	[obj setEnrollDateTime: aValue];
}

/**/
- (void) setUserKey: (int) aUserId value: (char*) aValue
{
	USER obj = [self getUser: aUserId];
	[obj setKey: aValue];
}

/**/
- (void) setUserLanguage: (int) aUserId value: (LanguageType) aLanguage
{
	USER obj = [self getUser: aUserId];
	[obj setLanguage: aLanguage];
}

/*GET*/

/**/
- (char*) getUserName: (int) aUserId
{
	USER obj = [self getUserFromCompleteList: aUserId];
	if (obj == NULL) THROW(REFERENCE_NOT_FOUND_EX);	
	return [obj getUName];
}


/**/
- (char*) getUserSurname: (int) aUserId
{
	USER obj = [self getUserFromCompleteList: aUserId];
	if (obj == NULL) THROW(REFERENCE_NOT_FOUND_EX);	
	return [obj getUSurname];
}

/**/
- (char*) getUserLoginName: (int) aUserId
{
	USER obj = [self getUserFromCompleteList: aUserId];
	if (obj == NULL) THROW(REFERENCE_NOT_FOUND_EX);	
	return [obj getLoginName];
}

/**/
- (char*) getUserPassword: (int) aUserId
{
	USER obj = [self getUserFromCompleteList: aUserId];
	if (obj == NULL) THROW(REFERENCE_NOT_FOUND_EX);	
	return [obj getPassword];
}

/**/
- (int) getUserProfileId: (int) aUserId
{
	USER obj = [self getUserFromCompleteList: aUserId];
	if (obj == NULL) THROW(REFERENCE_NOT_FOUND_EX);	
	return [obj getUProfileId];
}

/**/
- (char*) getUserDuressPassword: (int) aUserId
{
	USER obj = [self getUserFromCompleteList: aUserId];
	if (obj == NULL) THROW(REFERENCE_NOT_FOUND_EX);	
	return [obj getDuressPassword];
}

/**/
- (BOOL) getUserActive: (int) aUserId
{
	USER obj = [self getUserFromCompleteList: aUserId];
	if (obj == NULL) THROW(REFERENCE_NOT_FOUND_EX);	
	return [obj isActive];
}

/**/
- (BOOL) getUserTemporaryPassword: (int) aUserId
{
	USER obj = [self getUserFromCompleteList: aUserId];
	if (obj == NULL) THROW(REFERENCE_NOT_FOUND_EX);	
	return [obj isTemporaryPassword];
}

/**/
- (datetime_t) getUserLastLoginDateTime: (int) aUserId
{
	USER obj = [self getUserFromCompleteList: aUserId];
	if (obj == NULL) THROW(REFERENCE_NOT_FOUND_EX);	
	return [obj getLastLoginDateTime];
}

/**/
- (datetime_t) getUserLastChangePasswordDateTime: (int) aUserId
{
	USER obj = [self getUserFromCompleteList: aUserId];
	if (obj == NULL) THROW(REFERENCE_NOT_FOUND_EX);	
	return [obj getLastChangePasswordDateTime];
}

/**/
- (char*) getUserBankAccountNumber: (int) aUserId
{
	USER obj = [self getUserFromCompleteList: aUserId];
	if (obj == NULL) THROW(REFERENCE_NOT_FOUND_EX);	
	return [obj getBankAccountNumber];
}

/**/
- (int) getUserLoginMethod: (int) aUserId
{
	USER obj = [self getUserFromCompleteList: aUserId];
	if (obj == NULL) THROW(REFERENCE_NOT_FOUND_EX);	
	return [obj getLoginMethod];
}

/**/
- (datetime_t) getUserEnrollDateTime: (int) aUserId
{
	USER obj = [self getUserFromCompleteList: aUserId];
	if (obj == NULL) THROW(REFERENCE_NOT_FOUND_EX);	
	return [obj getEnrollDateTime];
}

/**/
- (char*) getUserKey: (int) aUserId
{
	USER obj = [self getUserFromCompleteList: aUserId];
	if (obj == NULL) THROW(REFERENCE_NOT_FOUND_EX);	
	return [obj getKey];
}

/**/
- (LanguageType) getUserLanguage: (int) aUserId
{
	USER obj = [self getUserFromCompleteList: aUserId];
	if (obj == NULL) THROW(REFERENCE_NOT_FOUND_EX);	
	return [obj getLanguage];
}

/**/
- (BOOL) userIsDeleted: (int) aUserId
{
	USER obj = [self getUserFromCompleteList: aUserId];
	if (obj == NULL) THROW(REFERENCE_NOT_FOUND_EX);	
	return [obj isDeleted];
}

/**/
- (void) applyUserChanges: (int) aUserId
{
	USER obj = [self getUser: aUserId];
	[obj applyChanges];
}

/**/
- (int) addUserByProfileName: (char*) aName surname: (char*) aSurname profileName: (char*) aProfileName loginName: (char*) aLoginName password: (char*) aPassword duressPassword: (char*) aDuressPassword active: (BOOL) anActive temporaryPassword: (BOOL) aTemporaryPassword lastLoginDateTime: (datetime_t) aLastLoginDateTime lastChangePasswordDateTime: (datetime_t) aLastChangePasswordDateTime bankAccountNumber: (char*) aBankAccountNumber loginMethod: (int) aLoginMethod enrollDateTime: (datetime_t) anEnrollDateTime key: (char*) aKey language: (LanguageType) aLanguage usesDynamicPin: (BOOL) aUsesDynamicPin 
{
  USER	newUser = [User new];
	PROFILE obj = [self getProfileByName: aProfileName];

	[newUser setUName: aName];
	[newUser setUSurname: aSurname];
	[newUser setLoginName: aLoginName];
	[newUser setPassword: aPassword];
	[newUser setUProfileId: [obj getProfileId]];
	[newUser setDuressPassword: aDuressPassword];
	[newUser setActive: anActive];
	[newUser setIsTemporaryPassword: aTemporaryPassword];
	[newUser setLastChangePasswordDateTime: aLastChangePasswordDateTime];
	[newUser setBankAccountNumber: aBankAccountNumber];
	[newUser setLoginMethod: aLoginMethod];
	[newUser setEnrollDateTime: anEnrollDateTime];
	[newUser setKey: aKey];
	[newUser setLanguage: aLanguage];
	[newUser setLastLoginDateTime: [SystemTime getLocalTime]];
	[newUser setUsesDynamicPin: aUsesDynamicPin];

	[newUser applyChanges];
	
	[self  addUserToCollection: newUser];
  
	return [newUser getUserId];
}

/**/
- (int) addUserByProfileId: (char*) aName surname: (char*) aSurname profileId: (int) aProfileId loginName: (char*) aLoginName password: (char*) aPassword duressPassword: (char*) aDuressPassword active: (BOOL) anActive temporaryPassword: (BOOL) aTemporaryPassword lastLoginDateTime: (datetime_t) aLastLoginDateTime lastChangePasswordDateTime: (datetime_t) aLastChangePasswordDateTime bankAccountNumber: (char*) aBankAccountNumber loginMethod: (int) aLoginMethod enrollDateTime: (datetime_t) anEnrollDateTime key: (char*) aKey language: (LanguageType) aLanguage usesDynamicPin: (BOOL) aUsesDynamicPin 

{
  USER	newUser = [User new];

	[newUser setUName: aName];
	[newUser setUSurname: aSurname];
	[newUser setLoginName: aLoginName];
	[newUser setPassword: aPassword];
	[newUser setUProfileId: aProfileId];
	[newUser setDuressPassword: aDuressPassword];
	[newUser setActive: anActive];
	[newUser setIsTemporaryPassword: aTemporaryPassword];
	[newUser setLastChangePasswordDateTime: aLastChangePasswordDateTime];
	[newUser setBankAccountNumber: aBankAccountNumber];
	[newUser setLoginMethod: aLoginMethod];
	[newUser setEnrollDateTime: anEnrollDateTime];
	[newUser setKey: aKey];
	[newUser setLanguage: aLanguage];
	[newUser setLastLoginDateTime: [SystemTime getLocalTime]];
	[newUser setUsesDynamicPin: aUsesDynamicPin];

	[newUser applyChanges];

	[self  addUserToCollection: newUser];
	
  return [newUser getUserId];
}

/**/
- (void) addSpecialUser: (char*) aName surname: (char*) aSurname loginName: (char*) aLoginName password: (char*) aPassword duressPassword: (char*) aDuressPassword
{
  USER	newUser = [User new];

	[newUser setUName: aName];
	[newUser setUSurname: aSurname];
	[newUser setLoginName: aLoginName];
	[newUser setPassword: aPassword];
	[newUser setDuressPassword: aDuressPassword];
	[newUser setUProfileId: 1]; // Perfil admin
	[newUser setActive: TRUE];
	[newUser setIsTemporaryPassword: FALSE];
	[newUser setLoginMethod: LoginMethod_PERSONALIDNUMBER];
	[newUser setIsSpecialUser: TRUE];
	[newUser applyChanges];

	[self addUserToCollection: newUser];
}

/**/
- (BOOL) canRemoveUser: (int) aUserId
{
	USER aUser = [self getUser: aUserId];
	BOOL res;
	
	res = TRUE;

	// controlo que el usuario a consultar exista
	if (!aUser) res = FALSE;

  // Controlo que no se intente eliminar al usuario logueado
  if ( [self getUserLoggedIn] != NULL &&
			[[self getUserLoggedIn] getUserId] == aUserId )
			res = FALSE;

  // Controlo que no se intente eliminar al administrador
  if ( ([self getUserLoggedIn] != NULL) && (aUserId == 1) )
			res = FALSE;

	// controlo que no se intente eliminar un usuario especiales
  if ([aUser isSpecialUser])
			res = FALSE;

  if ( ([aUser getUProfileId] == 1) && (![self hasAdminUser: aUserId]) ) res = FALSE;
  
  return res;
  
}

/**/
- (void) removeUser: (int) aUserId
{
	USER aUser = [self getUser: aUserId];
	id doors = NULL;
	int i = 0;
	id door = NULL;

	// controlo que el usuario a eliminar exista
	if (!aUser) THROW(USER_NOT_EXIST_EX);

  // Controlo que no se intente eliminar al usuario logueado
  if ( [self getUserLoggedIn] != NULL &&
			[[self getUserLoggedIn] getUserId] == aUserId )
			THROW(CANNOT_REMOVE_CURRENT_USER_EX);

  // Controlo que no se intente eliminar al administrador
  if ( ([self getUserLoggedIn] != NULL) && (aUserId == 1) )
			THROW(CANNOT_REMOVE_USER_ADMIN);

  // Controlo que no se intente eliminar a un usuario especial
  if ([aUser isSpecialUser])
			THROW(CANNOT_REMOVE_USER_EX);
     
  if ( ([aUser getUProfileId] == 1) && (![self hasAdminUser: aUserId]) ) THROW(CANNOT_REMOVE_USER_EX);

	// elimino las puertas por usuario
	doors = [[[CimManager getInstance] getCim] getDoors];
	for (i=0; i<[doors size]; ++i) {
		door = [doors at: i];

		// elimino la asociacion en la db
		[self deactivateDoorByUser: [door getDoorId] userId: [aUser getUserId]];

		// quito la asociacion en la puerta de memoria
  	[aUser removeDoorByUserToCollection: [door getDoorId]];
	}

	[aUser setDeleted: TRUE];
	[aUser applyChanges];

	// elimino al usuario de las listas
	[self removeUserFromCollection: aUserId];
	[self removeUserFromVisibleCollection: aUserId];
  
}

/**/
- (void) addUserToCollection: (USER) aUser
{
	[myUsers add: aUser];
	[myUsersCompleteList add: aUser];
	[myVisibleUsersList add: aUser];
}

/**/
- (void) removeUserFromCollection: (int) aUserId
{
	int i = 0;
	
	for (i=0; i<=[myUsers size]-1; ++i) 
		if ([ [myUsers at: i] getUserId] == aUserId) {
			[myUsers removeAt: i];
			return;
		}
}

/**/
- (void) removeUserFromVisibleCollection: (int) aUserId
{
	int i = 0;
	
	for (i=0; i<=[myVisibleUsersList size]-1; ++i) 
		if ([ [myVisibleUsersList at: i] getUserId] == aUserId) {
			[myVisibleUsersList removeAt: i];
			return;
		}
}

/**/
- (void) restoreUser: (int) aUserId
{
	USER obj = [self getUser: aUserId];

	[obj restore];
}

/**/
- (int) loginExternalUser: (char*) aLoginName
{
	int i = 0;
	char buffer[200];
	
	for (i=0; i<[myUsers size];++i) {

		if ( (strcmp([[myUsers at: i] getLoginName], aLoginName) == 0)) {

			[[myUsers at: i] setLoggedIn : TRUE];

			//Audita el logueo del usuario
      buffer[0] = '\0';
      sprintf(buffer, "%s-%s", [[myUsers at: i] getLoginName], [[myUsers at: i] getFullName]);
			[Audit auditEvent: [myUsers at: i] eventId: Event_LOGIN_PIN_USER additional: buffer station: 0 logRemoteSystem: FALSE];

			return [[myUsers at: i] getUserId];
		
		}
	}
	
	THROW(INEXISTENT_USER_EX);	
	return 0;
}

- (void) setLoginInProgress: (BOOL) aValue
{
	myLoginInProcess = aValue;
}

- (BOOL) isLoginInProgress
{
	return myLoginInProcess;
}

/**/
- (BOOL) isAdminInInitialState
{
	int pswResult = 1;
	id user = NULL;

	TRY

		// traigo al usuario admin para ver si su clave es temporal
		user = [self getUser: 1];

		// si el password no es temporal ya se logueo
		if (![user isTemporaryPassword]) {
			EXIT_TRY;
			return FALSE;
		}

    // valido el usuario contra la placa
    pswResult = [SafeBoxHAL sbValidateUser: "1111" password: "5231"];

		if (pswResult == 1) {
			EXIT_TRY;
			return TRUE;
		}

	CATCH

	END_TRY

	return FALSE;

}

/**/
- (USER) getUserByDallasKey: (COLLECTION) aDallasKeys
{
  id user = NULL;
  int i = 0;
	char *dallasKey;  
	
	if ([aDallasKeys size] > 0) {
		
		dallasKey = (char*)[aDallasKeys at: 0];
		for (i = 0; i < [myUsers size]; ++i) {
			if (strcmp(dallasKey, [[myUsers at: i] getKey]) == 0) {
				user = [myUsers at: i];
				break;
			}
		}
	}

	return user;

}

/**/
- (USER) getUserByLogin: (char*) aLoginName 
	password: (char*) aPassword 
	dallasKeys: (COLLECTION) aDallasKeys
	isDuressPassword: (BOOL*) aIsDuressPassword
{
  id user = NULL;
  int i = 0;
	char *dallasKey;
	SecurityLevel securityLevel;
  int pswResult;
  
	
	// Este metodo se puede llamar basicamente de varias formas:
	// - Con una llave Dallas unicamente
	// - Con una llave Dallas + Password 
	// - Con un Usuario + Password
	// - Con llave Dallas + Usuario + Password
	// En primer lugar trato de encontrar el usuario apropiado buscando por LoginName
	// o llave Dallas, una vez encontrado verifico que todo este correcto y que haya
	// presentado lo suficiente de acuerdo al nivel de seguridad del perfil

	// Si no tiene Login Name lo busco por Dallas
	if (strlen(aLoginName) == 0 && [aDallasKeys size] > 0) {
		dallasKey = (char*)[aDallasKeys at: 0];
		for (i = 0; i < [myUsers size]; ++i) {
			if (strcmp(dallasKey, [[myUsers at: i] getKey]) == 0) {
				user = [myUsers at: i];
				break;
			}
		}

	// Lo busco por Login Name
	//} else if (strlen(aLoginName) > 0 && strlen(aPassword) > 0) {
	} else if (strlen(aLoginName) > 0) { // esta condicion se cambio por el tema del nivel de seguridad 0

		for (i = 0; i < [myUsers size]; ++i) {
			if (strcmp([[myUsers at: i] getLoginName], aLoginName) == 0) {

				user = [myUsers at: i];
				break;
			}
		}
	} else THROW(INEXISTENT_USER_EX);

	
	// si el usuario NO existe me voy
	if (user == NULL) THROW(INEXISTENT_USER_EX);

	// verifico que no se logueen con el usuario PIMS ni con el Override
	if ( (strcmp([user getLoginName],PIMS_USER_NAME) == 0) || (strcmp([user getLoginName],OVERRIDE_USER_NAME) == 0) )
		THROW(INEXISTENT_USER_EX);

	// si el usuario esta inactivo me voy
	if (![user isActive]) THROW(INACTIVE_USER_EX);

	securityLevel = [[self getProfile: [user getUProfileId]] getSecurityLevel];

	// si el nivel de seguridad es == 0 y la password esta vacia retorno el user
	if (securityLevel == SecurityLevel_0) return user;

	// Si el tiene nivel de seguridad 3 tiene que haber ingresado nombre de usuario y password obligatoriamente
	if (securityLevel == SecurityLevel_3 && (strlen(aLoginName) == 0 || strlen(aPassword) == 0))
		THROW(LOGIN_NAME_AND_PIN_REQUIRED_EX);

	// Si el tiene nivel de seguridad 2 tiene que haber ingresado password obligatoriamente
	if (securityLevel == SecurityLevel_2 && strlen(aPassword) == 0)
		THROW(PIN_REQUIRED_EX);

	// Si el usuario tiene configurado que debe loguearse con LoginName + Password
	// verifico en primer lugar que haya ingresado estos datos
	if (securityLevel == SecurityLevel_1 && [user getLoginMethod] == LoginMethod_PERSONALIDNUMBER && 
		 (strlen(aLoginName) == 0 || strlen(aPassword) == 0))
		THROW(LOGIN_NAME_AND_PIN_REQUIRED_EX);

	// Si el usuario tiene nivel 1 y debe loguearse con personal id pero hay una dallas ingresada 
	// debo decirle que la llave dallas es invalida. Es decir, para que inserta una llave dallas
	// si no la necesita, como se con que se quiere loguear?
	if (securityLevel == SecurityLevel_1 && [user getLoginMethod] == LoginMethod_PERSONALIDNUMBER && 
		  [aDallasKeys size] > 0) {
		if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_DALLAS_KEY)
			THROW(INVALID_DALLAS_KEY_EX);
		if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_SWIPE_CARD_READER)
			THROW(INVALID_SWIPE_CARD_KEY_EX);
	}

	// Verifico el Password siempre para los niveles 2 y 3 de seguridad y cuando tiene Login
	if (securityLevel == SecurityLevel_2 || securityLevel == SecurityLevel_3 || strlen(aLoginName) > 0){

    // valido el usuario contra la placa

    pswResult = [SafeBoxHAL sbValidateUser: aLoginName password: aPassword];
    *aIsDuressPassword = (pswResult != 1);
  
         
	}

	// Para los niveles 2 y 3 requiero Dallas y Password o si el login method es Dallas o swipe card reader
	if (securityLevel == SecurityLevel_2 || securityLevel == SecurityLevel_3 || [user getLoginMethod] == LoginMethod_DALLASKEY  || [user getLoginMethod] == LoginMethod_SWIPE_CARD_READER) {

		if ([aDallasKeys size] == 0) {
			if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_DALLAS_KEY)
				THROW(DALLAS_KEY_REQUIRED_EX);
			if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_SWIPE_CARD_READER)
				THROW(SWIPE_CARD_KEY_REQUIRED_EX);
		}
		
		if ([aDallasKeys size] > 0)
			dallasKey = (char*)[aDallasKeys at: 0];
		else THROW(DEVICE_KEY_REQUIRED_EX);

		if (strcmp(dallasKey, [user getKey]) != 0) {
			if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_DALLAS_KEY)
				THROW(INVALID_DALLAS_KEY_EX);
			if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_SWIPE_CARD_READER)
				THROW(INVALID_SWIPE_CARD_KEY_EX);
		}

		if (securityLevel == SecurityLevel_3 && (strlen(aLoginName) == 0 || strcmp([user getLoginName], aLoginName) != 0))
			THROW(WRONG_USER_NAME_OR_PASSWORD_EX);
	}

	return user;
}

/**/
- (int) logInUser: (char*) aLoginName password: (char*) aPassword dallasKeys: (COLLECTION) aDallasKeys
{
  USER user = NULL;
  char buffer[200];
  BOOL loginNameOK;
	int userId = 0;
	BOOL duress = FALSE;
	id telesup;

  loginNameOK = FALSE;
  
  TRY

		// Inhabilito los validadores que tienen errores de comunicacion
		// Esto lo hago para acelerar el proceso de login ya que los timeouts a cada
		// validador son bastante considerables
		
		[[CimManager getInstance] disableAcceptorsWithCommError];


    user = [self getUserByLogin: aLoginName password: aPassword dallasKeys: aDallasKeys isDuressPassword: &duress];

  	if (user) {
  	
  	printf("realpass %s\n", aPassword);
			[user setRealPassword: aPassword];
			[user setLoggedIn : TRUE];

            // seteo el SafeBoxHAL el personal id y contrasena del usuario logueado
			if ([user isPinRequired]) {
				[SafeBoxHAL setLogedUserPersonalId: aLoginName];
				[SafeBoxHAL setLogedUserPassword: aPassword];
			} else {
				[SafeBoxHAL setLogedUserPersonalId: [user getDallasKeyLoginName]];
				[SafeBoxHAL setLogedUserPassword: [user getKey]];
			}

			userId = [user getUserId];
			
			buffer[0] = '\0';
			sprintf(buffer, "%s-%s", [user getLoginName], [user getFullName]);
		
      if (!duress) {
				//Audita el logueo del usuario         			
				[Audit auditEvent: user eventId: Event_LOGIN_PIN_USER additional: buffer station: 0 logRemoteSystem: FALSE];
				[[CimManager getInstance] deactivateAlarm];
				[[CimManager getInstance] deactivateSoundAlarm];
			} else {
			
					//Si se loguea con la duress pin hay que loguear
				[[CimManager getInstance] activateAlarm];
				[Audit auditEvent: user eventId: Event_LOGIN_DURESS_PIN_USER additional: buffer station: 0 logRemoteSystem: FALSE];
			
			}

			[[MessageHandler getInstance] setCurrentLanguage: [user getLanguage]];
			[[InputKeyboardManager getInstance] setCurrentLanguage: [user getLanguage]];

			// seteo la ruta para ir a buscar los archivos de formato de los reportes segun el idioma
			[[PrinterSpooler getInstance] setReportPathByLanguage: [user getLanguage]];

			// Verifica si debe eliminar usuarios
	    [self verifiedAutoInactivateDelete];

			// Si se elimino el usuario actual por inactividad, lo deslogueo y tiro un error
			if ([user isDeleted]) {

				[user setLoggedIn: FALSE];
				THROW(INEXISTENT_USER_EX);
			} else if (![user isActive]){

				[user setLoggedIn: FALSE];
				THROW(INACTIVE_USER_EX);
			}

			// registro la fecha hora de logueo
			[user setLastLoginDateTime: [SystemTime getLocalTime]];
			[[[Persistence getInstance] getUserDAO] storeLastLoginDateTime: user];

			[[CimManager getInstance] enableAcceptorsWithCommError];

			RETURN_TRY(userId);

		}

		[[CimManager getInstance] enableAcceptorsWithCommError];

   CATCH


     if (loginNameOK){
          //Audita el ingreso de password erroneo
  	  	[Audit auditEvent: Event_WRONG_PIN additional: aLoginName station: 0 logRemoteSystem: FALSE];

      } else {
          //Audita el login erroneo
  	  	[Audit auditEvent: Event_WRONG_LOGIN additional: "" station: 0 logRemoteSystem: FALSE];
      }
    
      if (user) [user setLoggedIn : FALSE];

    [[CimManager getInstance] enableAcceptorsWithCommError];

      RETHROW();
	
   END_TRY

   return 0;
}



/**/
- (int) validateUser: (char*) aLoginName password: (char*) aPassword dallasKeys: (COLLECTION) aDallasKeys
{
  USER user = NULL;
  char buffer[200];
  BOOL loginNameOK;
	BOOL duress = FALSE;
  PROFILE profile;

  loginNameOK = FALSE;
  
  TRY

		// Inhabilito los validadores que tienen errores de comunicacion
		// Esto lo hago para acelerar el proceso de login ya que los timeouts a cada
		// validador son bastante considerables
		[[CimManager getInstance] disableAcceptorsWithCommError];

    user = [self getUserByLogin: aLoginName password: aPassword dallasKeys: aDallasKeys isDuressPassword: &duress];

 		if (user) {

			profile = [[UserManager getInstance] getProfile: [user getUProfileId]];

			//valido que el usuario que se esta logueando tenga permiso de door access
			if (![profile hasPermission: OPEN_DOOR_OP]) THROW(USER_HAS_NOT_GOT_DOOR_ACCESS_EX);

			[user setRealPassword: aPassword];
			
			// seteo el SafeBoxHAL el personal id y contrasena del usuario logueado
			if ([user isPinRequired]) {
				[SafeBoxHAL setLogedUserPersonalId: aLoginName];
				[SafeBoxHAL setLogedUserPassword: aPassword];
			} else {
				[SafeBoxHAL setLogedUserPersonalId: [user getDallasKeyLoginName]];
				[SafeBoxHAL setLogedUserPassword: [user getKey]];
			}

			buffer[0] = '\0';
			sprintf(buffer, "%s-%s", [user getLoginName], [user getFullName]);
	
			if (!duress) //Audita el logueo del usuario         			
					[Audit auditEvent: Event_LOGIN_PIN_USER additional: buffer station: 0 logRemoteSystem: FALSE];
			else {
					//Si se loguea con la duress pin hay que loguear
				[[CimManager getInstance] activateAlarm];
				[Audit auditEvent: Event_LOGIN_DURESS_PIN_USER additional: buffer station: 0 logRemoteSystem: FALSE];
			}

			// Verifica si debe eliminar usuarios
	    [self verifiedAutoInactivateDelete];
			
			// Si se elimino el usuario actual por inactividad, lo deslogueo y tiro un error
			if ([user isDeleted]) {
				[user setLoggedIn: FALSE];
				THROW(INEXISTENT_USER_EX);
			} else if (![user isActive]){
				[user setLoggedIn: FALSE];
				THROW(INACTIVE_USER_EX);
			}

			[[CimManager getInstance] enableAcceptorsWithCommError];

			RETURN_TRY([user getUserId]);

  	}

		[[CimManager getInstance] enableAcceptorsWithCommError];
  
	CATCH
	
  	if (loginNameOK)
      //Audita el ingreso de password erroneo
  	  [Audit auditEvent: Event_WRONG_PIN additional: aLoginName station: 0 logRemoteSystem: FALSE];
  	else 
      //Audita el login erroneo
  	  [Audit auditEvent: Event_WRONG_LOGIN additional: "" station: 0 logRemoteSystem: FALSE];

		[[CimManager getInstance] enableAcceptorsWithCommError];

		RETHROW();

	END_TRY

	return 0;

}

/**/
- (USER) validateRemoteUser: (char*) aLoginName password: (char*) aPassword
{
	int i = 0;
	char buffer[200];
	USER user = NULL;
  int pswResult = 1;
	SecurityLevel securityLevel;

	TRY

		// no permito loguear al usuario PIMS ni al Override
		if ( (strcmp(toupper(aLoginName),PIMS_USER_NAME) == 0) || (strcmp(toupper(aLoginName),OVERRIDE_USER_NAME) == 0) )
			THROW(INEXISTENT_USER_EX);

		for (i=0; i<[myUsers size];++i) {
	
			// Verifica el que exista el usuario
			if (strcmp([[myUsers at: i] getLoginName], aLoginName) == 0) {
				user = [myUsers at: i];
			}
		}

		if (user) {

			securityLevel = [[self getProfile: [user getUProfileId]] getSecurityLevel];

			if (securityLevel == SecurityLevel_0) {

				if (![user isActive]) THROW(INACTIVE_USER_EX);

				// inicializo el contador en 0
				[[Acceptor getInstance] initCantLoginFails];
							
				//Audita el logueo del usuario
				buffer[0] = '\0';
				sprintf(buffer, "%s-%s", [user getLoginName], [user getFullName]);
				[Audit auditEvent: Event_LOGIN_PIN_USER additional: buffer station: 0 logRemoteSystem: TRUE];

				RETURN_TRY(user);
			}

			// para el resto de los niveles de seguridad valido contra la placa
			pswResult = [SafeBoxHAL sbValidateUser: aLoginName password: aPassword];

			if (pswResult != 0) { // este if se agrego para evitar que se loguee con el duress password
				
				if (![user isActive]) THROW(INACTIVE_USER_EX);

				// inicializo el contador en 0
				[[Acceptor getInstance] initCantLoginFails];
							
				//Audita el logueo del usuario
				buffer[0] = '\0';
				sprintf(buffer, "%s-%s", [user getLoginName], [user getFullName]);
				[Audit auditEvent: Event_LOGIN_PIN_USER additional: buffer station: 0 logRemoteSystem: TRUE];
			
				RETURN_TRY(user);
			}
		}

  	// incremento la cantidad de logueos fallidos
    [[Acceptor getInstance] incCantLoginFails];  
  
		THROW(INEXISTENT_USER_EX);

	CATCH
	
  	// incremento la cantidad de logueos fallidos
    [[Acceptor getInstance] incCantLoginFails];	
	
		THROW(INEXISTENT_USER_EX);

	END_TRY

	return NULL;

}

/**/
- (void) logOffUser: (int) aUserId
{
	USER user = NULL;

    printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>logOffUser = %d\n", aUserId);
	user = [self getUser: aUserId];
	[user setLoggedIn: FALSE];

  // seteo el SafeBoxHAL el personal id y contrasena en blanco
  [SafeBoxHAL setLogedUserPersonalId: ""];
  [SafeBoxHAL setLogedUserPassword: ""];
}

/**/
- (USER) getUserLoggedIn
{
	int i = 0;
	
    printf("getUserLoggedIn-----");
	for (i=0; i<[myUsers size]; ++i)  
		if ( [[myUsers at: i] isLoggedIn] == TRUE ) {
            printf(" Id = %d\n", [[myUsers at: i] getUserId]);
			return [myUsers at: i];
        }
    printf("NO HAY\n");
	return NULL;
}

/**/
- (void) verifiedAutoInactivateDelete
{
  id user = NULL;
  char buffer[20];
  int i = 0;
  BOOL upd;


  while (i < [myUsers size]) {
      user = [myUsers at: i];
      upd = FALSE;
      if (![user isSpecialUser]) { // si NO es el administrador o PIMS u Override
      // si la fecha actual es menor que la fecha de ultimo logueo no verifico nada
      // para evitar que se eliminen todos los usuarios
      if ([SystemTime getLocalTime] >= [user getLastLoginDateTime]) {
        
        // verifico la auto inactivacion ********************************************
        if ([[CimGeneralSettings getInstance] getPinAutoInactivate] > 0) {
            // calculo la diferencia en segundos
            if ( ([SystemTime getLocalTime] - [user getLastLoginDateTime]) > ([[CimGeneralSettings getInstance] getPinAutoInactivate] * 2592000) ) {
              
              [user setActive : FALSE];
              upd = TRUE;
              
              //Audita la auto inactivacion del usuario
				      snprintf(buffer, sizeof(buffer) - 1, "%s", [user getLoginName]);
	    			  [Audit auditEvent: Event_AUTO_INACTIVATE additional: buffer station: 0 logRemoteSystem: FALSE];
           }
        }
        
        // verifico la auto eliminacion **********************************************
    	  if ([[CimGeneralSettings getInstance] getPinAutoDelete] > 0) {
            // calculo la diferencia en segundos
            if ( ([SystemTime getLocalTime] - [user getLastLoginDateTime]) > ([[CimGeneralSettings getInstance] getPinAutoDelete] * 2592000) ) {
              
              [user setDeleted : TRUE];
              upd = TRUE;
              
              //Audita la auto eliminacion del usuario
	      			snprintf(buffer, sizeof(buffer) - 1, "%s", [user getLoginName]);
	      			[Audit auditEvent: Event_AUTO_DELETE additional: buffer station: 0 logRemoteSystem: FALSE];
            }
        }
      }
    }
    
    // guardo los cambios
    if (upd) {
      [user applyChanges];
      if ([user isDeleted]){
        [self removeUserFromCollection: [user getUserId]];
        [self removeUserFromVisibleCollection: [user getUserId]];
      }
      else
        i++;      
    }else
      i++;
  }

}

/**/
- (COLLECTION) getUsers
{
	return myUsers;
}

/**/
- (COLLECTION) getUsersCompleteList
{
	return myUsersCompleteList;
}

/**/
- (COLLECTION) getVisibleUsers
{
  COLLECTION myC;
  id user = NULL;
  id profile;
  int i,j;
  
  user = [self getUserLoggedIn];
  if (user != NULL) {
  
      profile = [self getProfile: [user getUProfileId]];
          
      myC = [Collection new];
      
      [myVUsers removeAll];

      // agrego los usuarios del perfil logueado siempre y cuando no sea admin
      if (![user isSpecialUser]) {
        for (j=0; j<[myVisibleUsersList size]; ++j) {
          if ([profile getProfileId] == [[myVisibleUsersList at: j] getUProfileId])
             [myVUsers add: [myVisibleUsersList at: j]];
        }
      }
      
      [self getChildProfiles: [profile getProfileId] childs: myC];
      for (i=0; i<[myC size]; ++i) {
        for (j=0; j<[myVisibleUsersList size]; ++j) {
          if ([[myC at: i] getProfileId] == [[myVisibleUsersList at: j] getUProfileId]) {
            [myVUsers add: [myVisibleUsersList at: j]];
          }
        }
      }
			[myC free];
      
      return myVUsers;
  } else return myVisibleUsersList;

}

- (COLLECTION) getDynamicPinUsers
{
  	int j;
  
		
	[myVUsers removeAll];

     for (j=0; j<[myUsers size]; ++j){
        if ([[myUsers at: j] getUsesDynamicPin])
             [myVUsers add: [myUsers at: j]];
        
      }
      
      return myVUsers;
}

/**/
- (COLLECTION) getUsersWithChildren: (int) anUserId
{
  COLLECTION myC;
  COLLECTION myVU;
  id user = NULL;
  id profile;
  int i,j;
  
  myVU = [Collection new];
  
  user = [self getUser: anUserId];
  if (user != NULL) {
  
      profile = [self getProfile: [user getUProfileId]];
          
      myC = [Collection new];

      // agrego los usuarios del perfil siempre y cuando no sea admin
      if (![user isSpecialUser]) {
        for (j=0; j<[myVisibleUsersList size]; ++j) {
          if ([profile getProfileId] == [[myVisibleUsersList at: j] getUProfileId])
             [myVU add: [myVisibleUsersList at: j]];
        }
      }
      
      [self getChildProfiles: [profile getProfileId] childs: myC];
      for (i=0; i<[myC size]; ++i) {
        for (j=0; j<[myVisibleUsersList size]; ++j) {
          if ([[myC at: i] getProfileId] == [[myVisibleUsersList at: j] getUProfileId]) {
            [myVU add: [myVisibleUsersList at: j]];
          }
        }
      }
      [myC free];
  }
  
  return myVU;
  
}

/**/
- (void) setVisibleUsers
{
	int i = 0;
  USER user;

  myVisibleUsersList = [Collection new];
  myVUsers = [Collection new];
		
  for (i=0; i<[myUsers size];++i) {
		if (![[myUsers at: i] isSpecialUser]) {
      user = [myUsers at: i]; 
      [myVisibleUsersList add: user];
    }
	}

}

/**/
- (BOOL) hasUserPermission: (int) aUserId operation: (int) anOperationId
{
  USER user = NULL;
  PROFILE profile = NULL;

  user = [self getUser: aUserId];
	if (!user) return FALSE;

  profile = [self getProfile: [user getUProfileId]];

  return [profile hasPermission: anOperationId];
  
}

/**/
- (BOOL) hasProfilePermission: (int) aProfileId operation: (int) anOperationId
{
  PROFILE profile = [self getProfile: aProfileId];
  
  return [profile hasPermission: anOperationId];
}

/**/
- (BOOL) hasAdminUser: (int) aUserId
{
	int i = 0;
	
	for (i=0; i<[myUsers size];++i) 
		if ( ([[myUsers at: i] getUserId] != aUserId) && ( [[myUsers at: i] getUProfileId] == 1 ) ) return TRUE;
	
	return FALSE;
}

/**/
- (void) ForcePinChange
{
  COLLECTION users;
	USER user;
	int i;
	
	users = [self getUsers];

	for (i = 0; i < [users size]; ++i) {
		user = [users at: i];
		
		if (![user isSpecialUser] && ![user getUsesDynamicPin]) { // si NO es el administrador o PIMS u Override y no tiene PIN DInamico
			[user setIsTemporaryPassword: TRUE];
			[user applyChanges];
		}
  }
	
}

/**/
- (BOOL) existUserPims
{
	return myExistUserPims;
}

/**/
- (BOOL) existUserOverride
{
	return myExistUserOverride;
}

/**/
- (void) createSpecialUsers
{
	unsigned short devList;

	// Si NO existe creo al usuario pims
	if (![self existUserPims]) {
		TRY
			[self addSpecialUser: "PIMS" surname: "PIMS" loginName: PIMS_USER_NAME password: PIMS_PASSWORD duressPassword: PIMS_DURESS_PASSWORD];
	//		doLog(0,"Se creo el usuario PIMS **************\n");
			myExistUserPims = TRUE;
		CATCH
			myExistUserPims = TRUE;
		END_TRY
	} else {
		// intento crear la password en placa por las dudas que se haya cambiado la placa
		// por una nueva y los usuarios ya existan en el data.
		TRY
			devList = 0;
			[SafeBoxHAL sbAddUser: devList personalId: PIMS_USER_NAME password: PIMS_PASSWORD duressPassword: PIMS_DURESS_PASSWORD];
		CATCH
			if (ex_get_code() != CIM_USER_EXISTS_EX) RETHROW(); // La exception de que existe la ignoro
		END_TRY
	}

	// Si NO existe creo al usuario override
	if (![self existUserOverride]) {
		TRY
			[self addSpecialUser: "OVERRIDE" surname: "OVERRIDE" loginName: OVERRIDE_USER_NAME password: OVERRIDE_PASSWORD duressPassword: OVERRIDE_DURESS_PASSWORD];
	//		doLog(0,"Se creo el usuario Override **************\n");
			myExistUserOverride = TRUE;
		CATCH
			myExistUserOverride = TRUE;
		END_TRY
	} else {
		// intento crear la password en placa por las dudas que se haya cambiado la placa
		// por una nueva y los usuarios ya existan en el data.
		TRY
			devList = 0;
			[SafeBoxHAL sbAddUser: devList personalId: OVERRIDE_USER_NAME password: OVERRIDE_PASSWORD duressPassword: OVERRIDE_DURESS_PASSWORD];
		CATCH
			if (ex_get_code() != CIM_USER_EXISTS_EX) RETHROW(); // La exception de que existe la ignoro
		END_TRY
	}
}

/**/
- (void) verifiedSpecialUsers
{
	int userId = 0;
	COLLECTION dallasKeys = [Collection new];
    
    printf("VerifySpecialUsers\n");

	// 1) me intento loguear con el usuario admin con contrasenia por defecto
	// 2) si puedo loguearme entonces creo a los usuarios PIMS y Override. Caso contrario no hago nada.
	TRY
	
		userId = [self logInUser: "1111" password: "5231" dallasKeys: dallasKeys];

		[dallasKeys freePointers];
		
		[dallasKeys free];
	CATCH
        if (userId !=0) [self logOffUser: userId];
        userId = 0;
	END_TRY

	if (userId != 0) {
		[self createSpecialUsers];
		// deslogueo al usuario admin
		[self logOffUser: userId];
	}
}

/**/
- (int) logInUserPIMS
{
	int userId = 0;
  USER user = NULL;

	// logueo al usuario PIMS
	TRY
		if ([self existUserPims]) {
	
			user = [self getUserPims];

			if (user) {
	
				// Inhabilito los validadores que tienen errores de comunicacion
				// Esto lo hago para acelerar el proceso de login ya que los timeouts a cada
				// validador son bastante considerables
				[[CimManager getInstance] disableAcceptorsWithCommError];

				[user setRealPassword: PIMS_PASSWORD];
				[user setLoggedIn: TRUE];
				
				// seteo el SafeBoxHAL el personal id y contrasena del usuario logueado
				[SafeBoxHAL setLogedUserPersonalId: PIMS_USER_NAME];
				[SafeBoxHAL setLogedUserPassword: PIMS_PASSWORD];
	
				userId = [user getUserId];
	
				[[CimManager getInstance] enableAcceptorsWithCommError];
			}
		}

	CATCH
		[[CimManager getInstance] enableAcceptorsWithCommError];
		userId = 0;
	END_TRY

	return userId;
}

/**/
- (void) logOffUserPIMS
{
	id user = NULL;

	// deslogueo al usuario PIMS
	if ([self existUserPims]) {
		user = [self getUserPims];
		[user setLoggedIn: FALSE];
	
		// seteo el SafeBoxHAL el personal id y contrasena en blanco
		[SafeBoxHAL setLogedUserPersonalId: ""];
		[SafeBoxHAL setLogedUserPassword: ""];
	}
}

/**/
- (USER) getUserPims
{
	int i = 0;

	// si no existe directamente hago el return
	if (![self existUserPims]) return NULL;

	// si ya esta cargado lo retorno
	if (myUserPims) return myUserPims;

	// lo busco
	for (i=0; i<[myUsers size];++i) {
		if (strcmp([[myUsers at: i] getLoginName],PIMS_USER_NAME) == 0) {
			myUserPims = [myUsers at: i];
			return myUserPims;
		}
	}
	return NULL;

}

- (USER) getUserOverride
{
	int i = 0;

	// si no existe directamente hago el return
	if (![self existUserOverride]) return NULL;

	// si ya esta cargado lo retorno
	if (myUserOverride) return myUserOverride;

	// lo busco
	for (i=0; i<[myUsers size];++i) {
		if (strcmp([[myUsers at: i] getLoginName],OVERRIDE_USER_NAME) == 0) {
			myUserOverride = [myUsers at: i];
			return myUserOverride;
		}
	}
	return NULL;

}

- (USER) getUserByLoginName: (char *) aLoginName
{
	int i = 0;

	// lo busco
	for (i=0; i<[myUsers size];++i) {
		if (strcmp([[myUsers at: i] getLoginName],aLoginName) == 0) {
			return [myUsers at: i];
		}
	}

	return NULL;

}

/*******************************************************************************************
*																			OPERATIONS 
*
*******************************************************************************************/

/**/
- (OPERATION) getOperation: (int) anOperationId
{
	int i = 0;

	for (i=0; i<[myOperations size];++i) {
		if ([[myOperations at: i] getOperationId] == anOperationId)
			return [myOperations at: i];
	}
	
	THROW(REFERENCE_NOT_FOUND_EX);	
	return NULL;
}

/**/
- (char*) getOperationName: (int) anOperationId 
{
	OPERATION obj = [self getOperation: anOperationId];

	return [obj str];
}

/**/
- (char*) getOperationResource: (int) anOperationId 
{
	OPERATION obj = [self getOperation: anOperationId];

	return [obj getOpResource];
}

/**/
- (COLLECTION) getAllOperations
{	
	return myOperations;
}


/*******************************************************************************************
*																			DOORS BY USER
*
*******************************************************************************************/

/**
 *
 */
- (void) activateDoorByUserId: (int) aDoorId userId: (int) anUserId
{
	[[[Persistence getInstance] getUserDAO] storeDoorByUser: aDoorId userId: anUserId];
}

/**
 *
 */
- (void) deactivateDoorByUser: (int) aDoorId userId: (int) anUserId
{	
  [[[Persistence getInstance] getUserDAO] removeDoorByUser: aDoorId userId: anUserId];
}

/**/
- (void) deactivateDoorsToUsersFromProfile: (int) aProfileId
{
	COLLECTION visibleUsersList;
	COLLECTION doors;
	id door;
  int i,j;

	visibleUsersList = [self getVisibleUsers];
	
	for (i=0; i<[visibleUsersList size];++i) {
		if (![[visibleUsersList at: i] isSpecialUser]) {
			if ([[visibleUsersList at: i] getUProfileId] == aProfileId) {

				doors = [[[visibleUsersList at: i] getDoors] clone];
				
				for (j = 0; j < [doors size]; ++j) {
					door = [doors at: j];
					// elimino la puerta para el usuario
					[self deactivateDoorByUser: [door getDoorId] userId: [[visibleUsersList at: i] getUserId]];
					// quito la puerta de memoria
					[[visibleUsersList at: i] removeDoorByUserToCollection: [door getDoorId]];
				}

				[doors free];
			}
		}
	}

}

/**/
- (void) setTemporalUsersPinFromProfile: (int) aProfileId
{
	COLLECTION visibleUsersList;
	id user;
  int i;

	visibleUsersList = [self getVisibleUsers];

	for (i=0; i<[visibleUsersList size];++i) {
		user = [visibleUsersList at: i];
	
		if (![user isSpecialUser] && ![user getUsesDynamicPin]) { // si NO es el administrador o PIMS u Override y no tiene PIN DInamico
			if ([user getUProfileId] == aProfileId) { // si el perfil es igual
				[user setIsTemporaryPassword: TRUE];
				[user applyChanges];
			}
		}
	}

}

/**/
- (COLLECTION) getDoorsByUserList: (int) anUserId
{
  COLLECTION doors;

  id user = [self getUser: anUserId];
  
  if (user != NULL)
    doors = [user getDoors];
  else
    doors = [Collection new];
  
  return doors;
}

/**/
- (COLLECTION) getDoorsByUserIdList: (int) anUserId
{
	COLLECTION list = [Collection new];
	int i;
	COLLECTION doors = [self getDoorsByUserList: anUserId];

	for (i = 0; i < [doors size]; ++i)
	{
		[list add: [BigInt int: [[doors at: i] getDoorId]]];
	}
	return list;
}

/*******************************************************************************************
*																			DUAL ACCESS PROFILE
*
*******************************************************************************************/

/**
 *
 */
- (BOOL) verifiedDualAccess: (int) aProfile1Id profile2Id: (int) aProfile2Id
{
	return [[[Persistence getInstance] getProfileDAO] verifiedDualAccess: aProfile1Id profile2Id: aProfile2Id];
}

/**
 *
 */
- (void) activateDualAccess: (int) aProfile1Id profile2Id: (int) aProfile2Id
{
	[[[Persistence getInstance] getProfileDAO] storeDualAccess: aProfile1Id profile2Id: aProfile2Id];
}

/**
 *
 */
- (void) deactivateDualAccess: (int) aProfile1Id profile2Id: (int) aProfile2Id
{	
  [[[Persistence getInstance] getProfileDAO] removeDualAccess: aProfile1Id profile2Id: aProfile2Id];
}

/**/
- (COLLECTION) getAllDualAccess
{	
	return myDualAccessList;
}

/**/
- (COLLECTION) getVisibleDualAccess: (int) aProfileId
{	
  COLLECTION myC;
  COLLECTION myDual;
  int i,j;
  BOOL view1, view2;
  
  myC = [Collection new];
  [self getChildProfiles: aProfileId childs: myC];
  
  [myC add: [self getProfile: aProfileId]];
    
  myDual = [Collection new];
  
  for (i=0; i<[myDualAccessList size]; ++i) {
    view1 = FALSE;
    view2 = FALSE;
    for (j=0; j<[myC size]; ++j) {
      
      if ( [[myC at: j] getProfileId] == [[myDualAccessList at: i] getProfile1Id])
        view1 = TRUE;
        
      if ( [[myC at: j] getProfileId] == [[myDualAccessList at: i] getProfile2Id])
        view2 = TRUE;        
    }

    if ((view1) && (view2))
      [myDual add: [myDualAccessList at: i]];
  }
	[myC free];

	return myDual;
}

/**/
- (void) addDualAccessToCollection: (DUAL_ACCESS) aDualAccess
{  
  [myDualAccessList add: aDualAccess];
}

/**/
- (void) removeDualAccessFromCollection: (DUAL_ACCESS) aDualAccess
{
	int i = 0;
	
	for (i=0; i<[myDualAccessList size]; ++i) 
		if ([myDualAccessList at: i] == aDualAccess) {
			[myDualAccessList removeAt: i];
			return;
		}
}

/**/
- (BOOL) hasDualAccess: (int) aProfile1Id profile2Id: (int) aProfile2Id
{
	return [self getDualAccessFromCollection: aProfile1Id profile2Id: aProfile2Id] != NULL;
}

/**/
- (id) getDualAccessFromCollection: (int) aProfile1Id profile2Id: (int) aProfile2Id
{
	int i;
	
	for (i=0; i<[myDualAccessList size]; ++i){
		if ( (([[myDualAccessList at: i] getProfile1Id] == aProfile1Id) &&
         ([[myDualAccessList at: i] getProfile2Id] == aProfile2Id)) ||
         (([[myDualAccessList at: i] getProfile1Id] == aProfile2Id) &&
         ([[myDualAccessList at: i] getProfile2Id] == aProfile1Id)) ){
			   
         return [myDualAccessList at: i];
		}
	}
	return NULL;
}

/**/
- (id) getDualAccess: (int) aProfile1Id profile2Id: (int) aProfile2Id
{
  return [[[Persistence getInstance] getProfileDAO] loadDualAccess: aProfile1Id profile2Id: aProfile2Id];
}

/**/
- (char*) getUserToLogin { return myUserToLogin; }
- (char*) getPasswordToLogin { return myPasswordToLogin; };

- (void) setUserToLoginResponse: (BOOL) aValue { myUserToLoginResponse = aValue; }

- (USER) addHoytsUser: (char*) aName surname: (char*) aSurname loginName: (char*) aLoginName password: (char*) aPassword duressPassword: (char*) aDuressPassword profileName: (char*) aProfileName
{
	int userId = 0;
	COLLECTION dallasKeys = [Collection new];
	id profile = NULL;
  USER	newUser = NULL;
	USER user = NULL;

	user = [self getUserByLoginName: aLoginName];

	// si existe el login del usuario solo le setea los campos que vienen por parametro
	if (user) {

		[user setUName: aName];
		[user setUSurname: aSurname];
		[user setPassword: aPassword];
		[user setDuressPassword: aDuressPassword];
		[user setActive: TRUE];

		myHoytsUser = user;
		return user;
	}
	

	// sino lo agrega a la base

	// busca el perfil hoyts si no lo encuentra lanza una excepcion
	TRY

		profile = [self getProfileByName: aProfileName];

	CATCH

		RETHROW();

	END_TRY
	
// 1) me intento loguear con el usuario admin con contrasenia por defecto
	// 2) si puedo loguearme entonces creo al usuario. Caso contrario debo tirar un error.

	TRY
		userId = [self logInUserPIMS];
	CATCH
		userId = 0;
	END_TRY

	if (userId != 0) {
		newUser = [User new];
		[newUser setUName: aName];
		[newUser setUSurname: aSurname];
		[newUser setLoginName: aLoginName];
		[newUser setPassword: aPassword];
		[newUser setDuressPassword: aDuressPassword];
		[newUser setUProfileId: [profile getProfileId]]; 
		[newUser setActive: TRUE];
		[newUser setIsTemporaryPassword: FALSE];
		[newUser setLoginMethod: LoginMethod_PERSONALIDNUMBER];
		[newUser setIsSpecialUser: FALSE];
		[newUser applyChanges];
		[self addUserToCollection: newUser];
		[self logOffUser: userId];

	}

	myHoytsUser = newUser;

	return newUser;
}

- (void) setUserToLoginProfileName: (char*) aProfileName
{
	strcpy(myUserToLoginProfileName, aProfileName);
}


/**/
- (int) logInHoytsUser: (char*) aLoginName password: (char*) aPassword telesup: (id) aTelesup dallasKeys: (COLLECTION) aDallasKeys
{
  USER user = NULL;
  char buffer[200];
  BOOL loginNameOK;
	int userId = 0;
	BOOL duress = FALSE;
	BOOL error = FALSE;

	myHoytsUser = NULL;
  loginNameOK = FALSE;
  
	// Inhabilito los validadores que tienen errores de comunicacion
	// Esto lo hago para acelerar el proceso de login ya que los timeouts a cada
	// validador son bastante considerables
	[[CimManager getInstance] disableAcceptorsWithCommError];

	// supervisa al HB para verificar la existencia y si esta activo el usuario.
	strcpy(myUserToLogin, aLoginName);
	strcpy(myPasswordToLogin, aPassword); 


	TRY
		// verifico que este en el equipo
		user = [self getUserByLogin: aLoginName password: aPassword dallasKeys: aDallasKeys isDuressPassword: &duress];
	
		// si no existe el usuario supervisa al hoyts 
		if (!user) THROW(INEXISTENT_USER_EX);

		// si el nombre del perfil del usuario es HOYTS supervisa al hoyts para validar que se encuentre activo
		if (strcasecmp([[user getProfile] getProfileName], "HOYTS") == 0)THROW(INEXISTENT_USER_EX); 


	CATCH
	
		error = TRUE;
	
	END_TRY

	user = [self getUserByLoginName: aLoginName];

	if (error && user && (strcasecmp([[user getProfile] getProfileName], "HOYTS") != 0)) 
		THROW(INEXISTENT_USER_EX);

	if (error) { 

		user = NULL;

		TRY
		//como no esta en el equipo lo busco en el HOYTS BRIDGE
		[[TelesupScheduler getInstance] setCommunicationIntention: CommunicationIntention_LOGIN];
		[[TelesupScheduler getInstance] startTelesup: aTelesup getCurrentSettings: FALSE];

		CATCH
	
			RETHROW();

		END_TRY

		// si no esta o no lo encuentra en el HB lanza una excepcion
		if (myUserToLoginResponse == FALSE) THROW(INEXISTENT_USER_EX);

			// si no lo encuentra lo ingreso
		user = myHoytsUser;

		//    if (loginNameOK){
			//      //Audita el ingreso de password erroneo
				//	[Audit auditEvent: Event_WRONG_PIN additional: aLoginName station: 0 logRemoteSystem: FALSE];
				//} else {
						//Audita el login erroneo
				//	[Audit auditEvent: Event_WRONG_LOGIN additional: "" station: 0 logRemoteSystem: FALSE];
			// }
		[[CimManager getInstance] enableAcceptorsWithCommError];

	}

	// si lo pudo insertar configuro el usuario logueado
	if (user) {

		[user setRealPassword: aPassword];
		[user setLoggedIn : TRUE];

		// seteo el SafeBoxHAL el personal id y contrasena del usuario logueado
		if ([user isPinRequired]) {
			[SafeBoxHAL setLogedUserPersonalId: aLoginName];
			[SafeBoxHAL setLogedUserPassword: aPassword];
		} else {
			[SafeBoxHAL setLogedUserPersonalId: [user getDallasKeyLoginName]];
			[SafeBoxHAL setLogedUserPassword: [user getKey]];
		}
		userId = [user getUserId];
		buffer[0] = '\0';
		sprintf(buffer, "%s-%s", [user getLoginName], [user getFullName]);

		if (!duress) {
			//Audita el logueo del usuario         			
			[Audit auditEvent: user eventId: Event_LOGIN_PIN_USER additional: buffer station: 0 logRemoteSystem: FALSE];
			[[CimManager getInstance] deactivateAlarm];
			[[CimManager getInstance] deactivateSoundAlarm];
		} else {
				//Si se loguea con la duress pin hay que loguear
			[[CimManager getInstance] activateAlarm];
			[Audit auditEvent: user eventId: Event_LOGIN_DURESS_PIN_USER additional: buffer station: 0 logRemoteSystem: FALSE];
		}

		[[MessageHandler getInstance] setCurrentLanguage: [user getLanguage]];
		[[InputKeyboardManager getInstance] setCurrentLanguage: [user getLanguage]];

		// seteo la ruta para ir a buscar los archivos de formato de los reportes segun el idioma
		[[PrinterSpooler getInstance] setReportPathByLanguage: [user getLanguage]];

		// Verifica si debe eliminar usuarios
		[self verifiedAutoInactivateDelete];

		// registro la fecha hora de logueo
		[user setLastLoginDateTime: [SystemTime getLocalTime]];
		[[[Persistence getInstance] getUserDAO] storeLastLoginDateTime: user];

		[[CimManager getInstance] enableAcceptorsWithCommError];

		return userId;

	} else {

		[[CimManager getInstance] enableAcceptorsWithCommError];
		THROW(INEXISTENT_USER_EX); 
	}

	return 0;
}


/**/
/*
- (int) logInHoytsUser: (char*) aLoginName password: (char*) aPassword telesup: (id) aTelesup dallasKeys: (COLLECTION) aDallasKeys
{
  USER user = NULL;
  char buffer[200];
  BOOL loginNameOK;
	int userId = 0;
	BOOL duress = FALSE;
	id telesup;

  loginNameOK = FALSE;
  
  TRY

		// Inhabilito los validadores que tienen errores de comunicacion
		// Esto lo hago para acelerar el proceso de login ya que los timeouts a cada
		// validador son bastante considerables
		[[CimManager getInstance] disableAcceptorsWithCommError];

    user = [self getUserByLogin: aLoginName password: aPassword dallasKeys: aDallasKeys isDuressPassword: &duress];

  CATCH

	 // Como no encuentra el usuario entonces lo consulta al sistema de ellos.

		if (!loginNameOK) {

			strcpy(myUserToLogin, aLoginName);
			strcpy(myPasswordToLogin, aPassword); 
	
			[[TelesupScheduler getInstance] setCommunicationIntention: CommunicationIntention_LOGIN];
			[[TelesupScheduler getInstance] startTelesup: aTelesup getCurrentSettings: FALSE];
	
			if (!myUserToLogin) RETHROW();
			else {
				user = [self addHoytsUser: myUserToLoginName surname: myUserToLoginSurname loginName: myUserToLogin password: myPasswordToLogin duressPassword: "0000" profileName: myUserToLoginProfileName];
			}
		}
				
	//    if (loginNameOK){
    //      //Audita el ingreso de password erroneo
  	  //	[Audit auditEvent: Event_WRONG_PIN additional: aLoginName station: 0 logRemoteSystem: FALSE];
      //} else {
          //Audita el login erroneo
  	  //	[Audit auditEvent: Event_WRONG_LOGIN additional: "" station: 0 logRemoteSystem: FALSE];
     // }

			[[CimManager getInstance] enableAcceptorsWithCommError];

   END_TRY


	if (user) {

		[user setRealPassword: aPassword];
		[user setLoggedIn : TRUE];
		
		// seteo el SafeBoxHAL el personal id y contrasena del usuario logueado
		if ([user isPinRequired]) {
			[SafeBoxHAL setLogedUserPersonalId: aLoginName];
			[SafeBoxHAL setLogedUserPassword: aPassword];
		} else {
			[SafeBoxHAL setLogedUserPersonalId: [user getDallasKeyLoginName]];
			[SafeBoxHAL setLogedUserPassword: [user getKey]];
		}

		userId = [user getUserId];
		
		buffer[0] = '\0';
		sprintf(buffer, "%s-%s", [user getLoginName], [user getFullName]);
	
		if (!duress) {
			//Audita el logueo del usuario         			
			[Audit auditEvent: user eventId: Event_LOGIN_PIN_USER additional: buffer station: 0 logRemoteSystem: FALSE];
			[[CimManager getInstance] deactivateAlarm];
			[[CimManager getInstance] deactivateSoundAlarm];
		} else {
				//Si se loguea con la duress pin hay que loguear
			[[CimManager getInstance] activateAlarm];
			[Audit auditEvent: user eventId: Event_LOGIN_DURESS_PIN_USER additional: buffer station: 0 logRemoteSystem: FALSE];
		}

		[[MessageHandler getInstance] setCurrentLanguage: [user getLanguage]];
		[[InputKeyboardManager getInstance] setCurrentLanguage: [user getLanguage]];

		// seteo la ruta para ir a buscar los archivos de formato de los reportes segun el idioma
		[[PrinterSpooler getInstance] setReportPathByLanguage: [user getLanguage]];

		// Verifica si debe eliminar usuarios
		[self verifiedAutoInactivateDelete];

		// Si se elimino el usuario actual por inactividad, lo deslogueo y tiro un error
		if ([user isDeleted]) {
			[user setLoggedIn: FALSE];
			THROW(INEXISTENT_USER_EX);
		} else if (![user isActive]){
			[user setLoggedIn: FALSE];
			THROW(INACTIVE_USER_EX);
		}

		// registro la fecha hora de logueo
		[user setLastLoginDateTime: [SystemTime getLocalTime]];
		[[[Persistence getInstance] getUserDAO] storeLastLoginDateTime: user];

		[[CimManager getInstance] enableAcceptorsWithCommError];

		RETURN_TRY(userId);

	}

	[[CimManager getInstance] enableAcceptorsWithCommError];

	return 0;
}

*/

- (void) setUserToLoginName: (char*) aValue { strcpy(myUserToLoginName, aValue); }
- (void) setUserToLoginSurname: (char*) aValue { strcpy(myUserToLoginSurname, aValue); }
- (id) getHoytsUser { return myHoytsUser; }

@end
