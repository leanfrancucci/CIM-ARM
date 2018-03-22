#include "ProfileDAO.h"
#include "Profile.h"
#include "SettingsExcepts.h"
#include "Collection.h"
#include "system/db/all.h"
#include "DataSearcher.h"
#include "util.h"
#include "DualAccess.h"
#include "Audit.h"
#include "ResourceStringDefs.h"
#include "UserManager.h"

static id singleInstance = NULL;

@implementation ProfileDAO

- (void) auditOperation: (unsigned char*) anOperationList audit: (id) anAudit;
- (id) newProfileFromRecordSet: (id) aRecordSet; 

- (id) newDualAccessFromRecordSet: (id) aRecordSet;

/**/
+ new
{
	if (!singleInstance) singleInstance = [super new];
	return singleInstance;
}

/**/
- initialize
{
	[super initialize];
	return self;
}

/**/
- free
{
	return [super free];
}

/**/
+ getInstance
{
	return [self new];
}


/*
 *	Devuelve la configuracion de los perfiles en base a la informacion del registro actual del recordset.
 */

- (id) newProfileFromRecordSet: (id) aRecordSet
{
	PROFILE obj;
	char buffer[200];

	obj = [Profile new];

	[obj setProfileId: [aRecordSet getShortValue: "PROFILE_ID"]];
	[obj setProfileName: [aRecordSet getStringValue: "NAME" buffer: buffer]];
	[obj setFatherId: [aRecordSet getShortValue: "FATHER_ID"]];
  [obj setResource: [aRecordSet getStringValue: "RESOURCE" buffer: buffer]];
  [obj setKeyRequired: 0];
  [obj setSecurityLevel: [aRecordSet getCharValue: "SECURITY_LEVEL"]];
  [obj setTimeDelayOverride: [aRecordSet getCharValue: "TIME_DELAY_OVERRIDE"]];
	[obj setDeleted: [aRecordSet getCharValue: "DELETED"]];
	[obj setOperationsList: [aRecordSet getCharArrayValue: "OPERATION_LIST" buffer: buffer]];
	[obj setUseDuressPassword: [aRecordSet getCharValue: "USE_DURESS_PASSWORD"]];

	return obj;
}

/**/
- (COLLECTION) loadAll
{
	COLLECTION collection = [Collection new];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "profiles" filter: "" orderFields: "PROFILE_ID"];
	PROFILE obj;

	[myRecordSet open];

	while ( [myRecordSet moveNext] ) {
		// agrego el perfil a la coleccion solo si se encuentra activa
		obj = [self newProfileFromRecordSet: myRecordSet];
		if (!( [obj isDeleted])) [collection add: obj];
		else [obj free];
	}

	[myRecordSet free];

	return collection;
}

/**/

- (id) loadById: (unsigned long) anId
{
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "profiles" filter: "" orderFields: "PROFILE_ID"];
	
	id obj = NULL;

	[myRecordSet open];

	if ([myRecordSet findById: "PROFILE_ID" value: anId]) {
		obj = [self newProfileFromRecordSet: myRecordSet];
		//Verifica que la el perfil no este borrado
		if (![obj isDeleted])	return obj;
	} 
	[myRecordSet free];
	THROW(REFERENCE_NOT_FOUND_EX);
	return NULL;
}

/**/
- (void) store: (id) anObject
{
	int profileId;
	AUDIT audit;
	char buffer[200];
	char oldOpList[200];
	char oldProfileStr[40];
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSetWithFilter: "profiles" filter: "" orderFields: "PROFILE_ID"];
	ABSTRACT_RECORDSET myRecordSetBck;
	volatile BOOL updateRecord = FALSE;
	BOOL lastDoOpDoorAccess;
	BOOL lastUseDuressPassword;
		
	[myDataSearcher setRecordSet: myRecordSet];
	[myDataSearcher addStringFilter: "NAME" operator: "=" value: [anObject getProfileName]];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: 0];

	TRY

		[myRecordSet open];

    [self validateFields: anObject];

		// Audito
  	if ([anObject isDeleted]) {
			updateRecord = TRUE;
    	audit = [[Audit new] initAuditWithCurrentUser: PROFILE_DELETED additional: [anObject getProfileName] station: [anObject getProfileId]  logRemoteSystem: TRUE];
			[myRecordSet findById: "PROFILE_ID" value: [anObject getProfileId]];
  	} else if ([anObject getProfileId] != 0) {
			updateRecord = TRUE;
			[myDataSearcher addShortFilter: "PROFILE_ID" operator: "!=" value: [anObject getProfileId]];
			if ([myDataSearcher find]) THROW(DAO_DUPLICATED_PROFILE_NAME_EX);
			[myRecordSet findById: "PROFILE_ID" value: [anObject getProfileId]];
    	audit = [[Audit new] initAuditWithCurrentUser: PROFILE_UPDATED additional: [anObject getProfileName] station: [anObject getProfileId] logRemoteSystem: TRUE];
		}	else {
			if ([myDataSearcher find]) THROW(DAO_DUPLICATED_PROFILE_NAME_EX);
			[myRecordSet add];
			audit = [[Audit new] initAuditWithCurrentUser: PROFILE_INSERTED additional: "" station: 0 logRemoteSystem: TRUE];	
			[audit setAlwaysLog: TRUE];
		}

    /// LOG DE CAMBIOS 
    if (![anObject isDeleted]) {
      [audit logChangeAsString: RESID_NAME oldValue: [myRecordSet getStringValue: "NAME" buffer: buffer] newValue: [anObject getProfileName]];

			oldProfileStr[0] = '\0';

			if ([myRecordSet getShortValue: "FATHER_ID"] != 0)
				strcpy(oldProfileStr, [[[UserManager getInstance] getProfile: [myRecordSet getShortValue: "FATHER_ID"]] getProfileName]);

      [audit logChangeAsString: FALSE
														resourceId: RESID_FATHER_PROFILE 
														oldValue: oldProfileStr
														newValue: [[[UserManager getInstance] getProfile: [anObject getFatherId]] getProfileName]  
														oldReference: [myRecordSet getShortValue: "FATHER_ID"] 
														newReference: [anObject getFatherId]];

			[audit logChangeAsBoolean: FALSE
																 resourceId: RESID_TIME_DELAY_OVERRIDE
																 oldValue: [myRecordSet getCharValue: "TIME_DELAY_OVERRIDE"]
																 newValue: [anObject getTimeDelayOverride]];

			[audit logChangeAsBoolean: FALSE
																 resourceId: RESID_USE_DURESS_PASSWORD
																 oldValue: [myRecordSet getCharValue: "USE_DURESS_PASSWORD"]
																 newValue: [anObject getUseDuressPassword]];

			// la auditoria del nivel de seguridad se audita diferente
			if (!updateRecord) {
				switch ([anObject getSecurityLevel]) {
					case SecurityLevel_0:
						[audit logChangeAsString: RESID_Profile_SECURITY_LEVEL oldValue: "" newValue: getResourceStringDef(RESID_Profile_SECURITY_LEVEL_0, "Nivel 0")];
						break;
					case SecurityLevel_1:
						[audit logChangeAsString: RESID_Profile_SECURITY_LEVEL oldValue: "" newValue: getResourceStringDef(RESID_Profile_SECURITY_LEVEL_1, "Nivel 1")];
						break;
					case SecurityLevel_2:
						[audit logChangeAsString: RESID_Profile_SECURITY_LEVEL oldValue: "" newValue: getResourceStringDef(RESID_Profile_SECURITY_LEVEL_2, "Nivel 2")];
						break;
					case SecurityLevel_3:
						[audit logChangeAsString: RESID_Profile_SECURITY_LEVEL oldValue: "" newValue: getResourceStringDef(RESID_Profile_SECURITY_LEVEL_3, "Nivel 3")];
						break;
				}
			}


  		// audito las operaciones que cambiaron
			[self auditOperation: [anObject getOperationsList] audit: audit];
    }

		// guardo si antes de la edisión tenia o no permiso para door access
		memcpy(oldOpList, [myRecordSet getCharArrayValue: "OPERATION_LIST" buffer: oldOpList], 14);
		lastDoOpDoorAccess = (getbit(oldOpList, OPEN_DOOR_OP) == 1);

		// guardo el valor anterior de UseDuressPassword
		lastUseDuressPassword = [myRecordSet getCharValue: "USE_DURESS_PASSWORD"];

		[myRecordSet setStringValue: "NAME" value: [anObject getProfileName]];
		[myRecordSet setShortValue: "FATHER_ID" value: [anObject getFatherId]];
		[myRecordSet setStringValue: "RESOURCE" value: [anObject getResource]];
		[myRecordSet setCharValue: "TIME_DELAY_OVERRIDE" value: [anObject getTimeDelayOverride]];
		[myRecordSet setCharValue: "DELETED" value: [anObject isDeleted]];
    [myRecordSet setCharValue: "SECURITY_LEVEL"	value: [anObject getSecurityLevel]];
    [myRecordSet setCharArrayValue: "OPERATION_LIST" value: [anObject getOperationsList]];
		[myRecordSet setCharValue: "USE_DURESS_PASSWORD" value: [anObject getUseDuressPassword]];

		profileId = [myRecordSet save];
		[anObject setProfileId: profileId];

		[audit setStation: profileId];
  	[audit saveAudit];
  	[audit free];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "profiles_bck"]) {
			myRecordSetBck = [dbConnection createRecordSetWithFilter: "profiles_bck" filter: "" orderFields: "PROFILE_ID"];
	
			if (updateRecord) [self doUpdateBackupById: "PROFILE_ID" value: [anObject getProfileId] backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "profiles_bck"];
			else [self doAddBackup: myRecordSetBck currentRecordSet: myRecordSet tableName: "profiles_bck"];
		}

		/***/
		if (updateRecord) {
			// Verifico que si al perfil se le quito el permiso DoorAccess en cuyo caso recorro
			// los usuarios con dicho perfil y les quito las puertas que tengan asignadas.
			if ( (lastDoOpDoorAccess) && (![anObject hasPermission: OPEN_DOOR_OP]) ) {
				[[UserManager getInstance] deactivateDoorsToUsersFromProfile: [anObject getProfileId]];
			}

			// si se modifica el uso de duress password entonces debo marcar como temporal las
			// claves de todos los usuarios a que tienen dicho perfil
			if ( ((!lastUseDuressPassword) && ([anObject getUseDuressPassword])) ||
					 ((lastUseDuressPassword) && (![anObject getUseDuressPassword])) ) {
				[[UserManager getInstance] setTemporalUsersPinFromProfile: [anObject getProfileId]];
			}
		}
		/***/

	FINALLY

		[myRecordSet free];
	
	END_TRY
}

/**/
- (void) auditOperation: (unsigned char*) anOperationList audit: (id) anAudit
{ 
	id operation = NULL;
	int i;

  // audito las operaciones que hayan cambiado
  for (i=1; i<= OPERATION_COUNT; ++i) {

		if (getbit(anOperationList, i) == 1) {
			// quiere decir que tiene la operacion asociada    

      operation = [[UserManager getInstance] getOperation: i];

      [anAudit logChangeAsString: FALSE 
				resourceId: RESID_Profile_OPERATION 
				oldValue: "" 
				newValue: [operation str] 
				oldReference: 0
				newReference: i]; 

		}

	}

}

/**/
- (void) validateFields: (id) anObject
{
	/* 
		Validacion de nulidad de campos en cuanto a sus valores que reflejan invalidez
		name = vacio
	*/

	if ( (strlen(trim([anObject getProfileName])) == 0) ) THROW(NULL_PROFILE_NAME_EX);
}

/**/
- (BOOL) verifiedDualAccess: (int) aProfile1Id profile2Id: (int) aProfile2Id
{
  volatile BOOL res;
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DATA_SEARCHER myDataSearcher2 = [DataSearcher new];
	ABSTRACT_RECORDSET myRecordSet;
  
  res = TRUE;
  
  myRecordSet = [[DBConnection getInstance] createRecordSet: "dual_access"];
	
  if (![self existsProfile: aProfile1Id]) res = FALSE;
  if (![self existsProfile: aProfile2Id]) res = FALSE;

  if (aProfile1Id == aProfile2Id) res = FALSE;

	[myDataSearcher setRecordSet: myRecordSet];
	[myDataSearcher addShortFilter: "PROFILE1_ID" operator: "=" value: aProfile1Id];
	[myDataSearcher addShortFilter: "PROFILE2_ID" operator: "=" value: aProfile2Id];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];
	
	[myDataSearcher2 setRecordSet: myRecordSet];
	[myDataSearcher2 addShortFilter: "PROFILE1_ID" operator: "=" value: aProfile2Id];
	[myDataSearcher2 addShortFilter: "PROFILE2_ID" operator: "=" value: aProfile1Id];
	[myDataSearcher2 addCharFilter: "DELETED" operator: "=" value: FALSE];
	
	TRY

		[myRecordSet open];
		
		if ([myDataSearcher find]) res = FALSE;
		if ([myDataSearcher2 find]) res = FALSE;
		
	FINALLY
	
		[myRecordSet free];
		[myDataSearcher free];
		[myDataSearcher2 free];
		
		return res;
	
	END_TRY
      	
}

/**/
- (void) storeDualAccess: (int) aProfile1Id profile2Id: (int) aProfile2Id
{
	char additional[60];
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DATA_SEARCHER myDataSearcher2 = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet;
	ABSTRACT_RECORDSET myRecordSetBck;
  
  myRecordSet = [dbConnection createRecordSet: "dual_access"];
	
  if (![self existsProfile: aProfile1Id]) THROW(REFERENCE_NOT_FOUND_EX);
  if (![self existsProfile: aProfile2Id]) THROW(REFERENCE_NOT_FOUND_EX);

  if (aProfile1Id == aProfile2Id) THROW(DAO_EQUALS_DUAL_ACCESS_EX);

	[myDataSearcher setRecordSet: myRecordSet];
	[myDataSearcher addShortFilter: "PROFILE1_ID" operator: "=" value: aProfile1Id];
	[myDataSearcher addShortFilter: "PROFILE2_ID" operator: "=" value: aProfile2Id];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];

	[myDataSearcher2 setRecordSet: myRecordSet];
	[myDataSearcher2 addShortFilter: "PROFILE1_ID" operator: "=" value: aProfile2Id];
	[myDataSearcher2 addShortFilter: "PROFILE2_ID" operator: "=" value: aProfile1Id];
	[myDataSearcher2 addCharFilter: "DELETED" operator: "=" value: FALSE];

	TRY

		[myRecordSet open];
		
		if ([myDataSearcher find]) THROW(DAO_DUPLICATED_DUAL_ACCESS_EX);
		if ([myDataSearcher2 find]) THROW(DAO_DUPLICATED_DUAL_ACCESS_EX);

		// Audito el evento
		sprintf(additional, "%s-%s", [[[UserManager getInstance] getProfile: aProfile1Id] getProfileName], [[[UserManager getInstance] getProfile: aProfile2Id] getProfileName]);
  	[Audit auditEventCurrentUser: Event_ASSIGN_DUAL_ACCESS additional: additional station: 0 logRemoteSystem: TRUE];

		[myRecordSet add];

		[myRecordSet setShortValue: "PROFILE1_ID" value: aProfile1Id];
		[myRecordSet setShortValue: "PROFILE2_ID" value: aProfile2Id];
		[myRecordSet setCharValue: "DELETED" value: FALSE];

		[myRecordSet save];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "dual_access_bck"]) {
			myRecordSetBck = [dbConnection createRecordSet: "dual_access_bck"];

			[self doAddBackup: myRecordSetBck currentRecordSet: myRecordSet tableName: "dual_access_bck"];
		}

	FINALLY
	
		[myRecordSet free];
		[myDataSearcher free];
		[myDataSearcher2 free];
	
	END_TRY
}

/**/
- (void) removeDualAccess: (int) aProfile1Id profile2Id: (int) aProfile2Id
{
	char additional[60];
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DATA_SEARCHER myDataSearcher2 = [DataSearcher new];
	DATA_SEARCHER myDataSearcherBck = [DataSearcher new];
	DATA_SEARCHER myDataSearcherBck2 = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSet: "dual_access"];
	ABSTRACT_RECORDSET myRecordSetBck;

  if (![self existsProfile: aProfile1Id]) THROW(REFERENCE_NOT_FOUND_EX);
  if (![self existsProfile: aProfile2Id]) THROW(REFERENCE_NOT_FOUND_EX);

	[myDataSearcher setRecordSet: myRecordSet];
	[myDataSearcher addShortFilter: "PROFILE1_ID" operator: "=" value: aProfile1Id];
	[myDataSearcher addShortFilter: "PROFILE2_ID" operator: "=" value: aProfile2Id];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];

	[myDataSearcher2 setRecordSet: myRecordSet];
	[myDataSearcher2 addShortFilter: "PROFILE1_ID" operator: "=" value: aProfile2Id];
	[myDataSearcher2 addShortFilter: "PROFILE2_ID" operator: "=" value: aProfile1Id];
	[myDataSearcher2 addCharFilter: "DELETED" operator: "=" value: FALSE];	

	[myRecordSet open];
	if (([myDataSearcher find]) || ([myDataSearcher2 find])) {

		// Audito el evento
		sprintf(additional, "%s-%s", [[[UserManager getInstance] getProfile: aProfile1Id] getProfileName], [[[UserManager getInstance] getProfile: aProfile2Id] getProfileName]);
  	[Audit auditEventCurrentUser: Event_DELETE_DUAL_ACCESS additional: additional station: aProfile2Id logRemoteSystem: TRUE];

		[myRecordSet setCharValue: "DELETED" value: TRUE];
		[myRecordSet save];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "dual_access_bck"]) {
			myRecordSetBck = [dbConnection createRecordSet: "dual_access_bck"];

			[myDataSearcherBck setRecordSet: myRecordSetBck];
			[myDataSearcherBck addShortFilter: "PROFILE1_ID" operator: "=" value: aProfile1Id];
			[myDataSearcherBck addShortFilter: "PROFILE2_ID" operator: "=" value: aProfile2Id];
			[myDataSearcherBck addCharFilter: "DELETED" operator: "=" value: FALSE];

			[myDataSearcherBck2 setRecordSet: myRecordSetBck];
			[myDataSearcherBck2 addShortFilter: "PROFILE1_ID" operator: "=" value: aProfile2Id];
			[myDataSearcherBck2 addShortFilter: "PROFILE2_ID" operator: "=" value: aProfile1Id];
			[myDataSearcherBck2 addCharFilter: "DELETED" operator: "=" value: FALSE];

			[self doUpdateDualAccessBck: myRecordSetBck currentRecordSet: myRecordSet dataSearcher: myDataSearcherBck dataSearcher2: myDataSearcherBck2 tableName: "dual_access_bck"];
		}

		[myRecordSet free];
	  [myDataSearcher free];
	  [myDataSearcher2 free];
		return;
	}
	
	[myRecordSet free];
	[myDataSearcher free];
	[myDataSearcher2 free];
}

- (BOOL) existsProfile: (int) aProfileId
{
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "profiles" filter: "" orderFields: "PROFILE_ID"];

  [myDataSearcher setRecordSet: myRecordSet];
	[myDataSearcher addShortFilter: "PROFILE_ID" operator: "=" value: aProfileId];

	[myRecordSet open];
	
	if ([myDataSearcher find]) {
    [myRecordSet free];
		[myDataSearcher free];
		return TRUE;
	}
		[myRecordSet free];
		[myDataSearcher free];
		return FALSE;
}

/**/
- (COLLECTION) loadAllDualAccess
{
	COLLECTION collection = [Collection new];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "dual_access" filter: "" orderFields: "PROFILE1_ID"];
	DUAL_ACCESS obj;

	[myRecordSet open];

	while ( [myRecordSet moveNext] ) {
		// agrego el dual access a la coleccion solo si se encuentra activa
		obj = [self newDualAccessFromRecordSet: myRecordSet];
		if (!( [obj isDeleted])) [collection add: obj];
		else [obj free];
	}

	[myRecordSet free];

	return collection;
}

/**/
- (DUAL_ACCESS) loadDualAccess: (int) aProfile1Id profile2Id: (int) aProfile2Id
{
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "dual_access" filter: "" orderFields: "PROFILE1_ID"];
	DUAL_ACCESS obj;

	[myRecordSet open];

	while ( [myRecordSet moveNext] ) {
		if ( (([myRecordSet getShortValue: "PROFILE1_ID"] == aProfile1Id) &&
         ([myRecordSet getShortValue: "PROFILE2_ID"] == aProfile2Id)) ||
         (([myRecordSet getShortValue: "PROFILE1_ID"] == aProfile2Id) &&
         ([myRecordSet getShortValue: "PROFILE2_ID"] == aProfile1Id)) ){
         
    		 // creo el objeto
         obj = [self newDualAccessFromRecordSet: myRecordSet];
    		 if (!( [obj isDeleted])) 
           return obj;
    		 else 
           [obj free];
		}
	}

	[myRecordSet free];

	return NULL;
}

- (id) newDualAccessFromRecordSet: (id) aRecordSet
{
	DUAL_ACCESS obj;
	
	obj = [DualAccess new];

	[obj setProfile1Id: [aRecordSet getShortValue: "PROFILE1_ID"]];
	[obj setProfile2Id: [aRecordSet getShortValue: "PROFILE2_ID"]];
	[obj setDeleted: [aRecordSet getCharValue: "DELETED"]];

	return obj;
}

@end
