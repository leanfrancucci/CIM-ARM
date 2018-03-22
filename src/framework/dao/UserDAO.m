#include "User.h"
#include "UserDAO.h"
#include "UserManager.h"
#include "SettingsExcepts.h"
#include "ordcltn.h"
#include "system/db/all.h"
#include "DataSearcher.h"
#include "util.h"
#include "Audit.h"
#include "MessageHandler.h"
#include "system/util/all.h"
#include "CimGeneralSettings.h"
#include "Event.h"
#include "CimManager.h"
#include "SafeBoxHAL.h"
#include "TemplateParser.h"
#include "CimExcepts.h"
#include "User.h"
#include "TelesupScheduler.h"

static id singleInstance = NULL;

@implementation UserDAO

- (id) newUserFromRecordSet: (id) aRecordSet; 
- (BOOL) existsUser: (int) anUserId;

/**/
+ new
{
	if (!singleInstance) singleInstance = [super new];
	return singleInstance;
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

/**/
- initialize
{
	[super initialize];

	myCompleteList = [Collection new];
	myActiveList = [Collection new];
	myExistUserPims = FALSE;
	myExistUserOverride = FALSE;

	return self;
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

/*
 *	Devuelve la configuracion de los usuarios en base a la informacion del registro actual del recordset.
 */

- (id) newUserFromRecordSet: (id) aRecordSet
{
	USER obj;
	char buffer[201];

	obj = [User new];

	[obj setUserId: [aRecordSet getShortValue: "USER_ID"]];
	[obj setUName: [aRecordSet getStringValue: "NAME" buffer: buffer]];
	[obj setUSurname: [aRecordSet getStringValue: "SURNAME" buffer: buffer]];
	[obj setLoginName: [aRecordSet getStringValue: "LOGIN_NAME" buffer: buffer]];
	// seteo password y duress ficticios para que en la pantalla de ABM de usuarios se muestre algo.
  [obj setPassword: FICTICIOUS_PASSWORD];
	[obj setDuressPassword: FICTICIOUS_DURESS_PASSWORD];
  [obj setUProfileId: [aRecordSet getShortValue: "PROFILE_ID"]];
	[obj setDeleted: [aRecordSet getCharValue: "DELETED"]];
	[obj setActive: [aRecordSet getCharValue: "ACTIVE"]];
	[obj setIsTemporaryPassword: [aRecordSet getCharValue: "TEMPORARY_PASSWORD"]];
	[obj setLastLoginDateTime: [aRecordSet getDateTimeValue: "LAST_LOGIN_DATE"]];
	[obj setLastChangePasswordDateTime: [aRecordSet getDateTimeValue: "LAST_CHANGE_PASSWORD_DATE"]];
	[obj setBankAccountNumber: [aRecordSet getStringValue: "BANK_ACCOUNT_NUMBER" buffer: buffer]];
	[obj setLoginMethod: [aRecordSet getCharValue: "LOGIN_METHOD"]];
	[obj setEnrollDateTime: [aRecordSet getDateTimeValue: "ENROLLED_DATE"]];
	[obj setKey: [aRecordSet getStringValue: "KEY" buffer: buffer]];  
	[obj setLanguage: [aRecordSet getShortValue: "LANGUAGE"]];
	/* Comento lo de pines dinamicos para liberarlo mas adelante
	[obj setClosingCode: [aRecordSet getStringValue: "CLOSING_CODE" buffer: buffer]];  
	[obj setPreviousPin: [aRecordSet getStringValue: "PREVIOUS_PIN" buffer: buffer]];  
	[obj setUsesDynamicPin: [aRecordSet getCharValue: "USES_DYNAMIC_PIN"]];  
*/
	[obj setClosingCode: ""];  
	[obj setPreviousPin: ""];  
	[obj setUsesDynamicPin: 0];

	// indico si el usuario es un usuario especial o no: Admin, PIMS y Override
	// admin
	if ([obj getUserId] == 1) {
		[obj setIsSpecialUser: TRUE];
	}
	// pims
	if (strcmp([obj getLoginName],PIMS_USER_NAME) == 0) {
		[obj setIsSpecialUser: TRUE];
		myExistUserPims = TRUE;
	}
	// override
	if (strcmp([obj getLoginName],OVERRIDE_USER_NAME) == 0) {
		[obj setIsSpecialUser: TRUE];
		myExistUserOverride = TRUE;
	}

	return obj;
}

/**/
- (void) loadCompleteList
{
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "users" filter: "" orderFields: "USER_ID"];
	USER obj;

	[myRecordSet open];
	while ( [myRecordSet moveNext] ) {

		obj = [self newUserFromRecordSet: myRecordSet];

		[myCompleteList add: obj];

		if (!( [obj isDeleted])) [myActiveList add: obj];
	}

	[myRecordSet free];

}

/**/
- (id) loadById: (unsigned long) anId
{
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "users" filter: "" orderFields: "USER_ID"];
	
	id obj = NULL;

	[myRecordSet open];

	if ([myRecordSet findById: "USER_ID" value: anId]) {
		obj = [self newUserFromRecordSet: myRecordSet];
		//Verifica que la el usuario no este borrado
		if (![obj isDeleted])	return obj;
	} 
  
	[myRecordSet free];
  
	THROW(REFERENCE_NOT_FOUND_EX);
	return NULL;
}

/**/
- (void) storeLastLoginDateTime: (id) anObject
{
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSetWithFilter: "users" filter: "" orderFields: "USER_ID"];
	ABSTRACT_RECORDSET myRecordSetBck;

	[myRecordSet open];

	if ([myRecordSet findById: "USER_ID" value: [anObject getUserId]]) {
		[myRecordSet setDateTimeValue: "LAST_LOGIN_DATE" value: [anObject getLastLoginDateTime]];
		[myRecordSet save];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "users_bck"]) {
			myRecordSetBck = [dbConnection createRecordSetWithFilter: "users_bck" filter: "" orderFields: "USER_ID"];
	
			[self doUpdateBackupUserById: "USER_ID" value: [anObject getUserId] backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "users_bck"];
		}
	}

	[myRecordSet free];
}

/**/
- (void) store: (id) anObject
{
	int userId;
	AUDIT audit;
	char buffer[61];
	volatile BOOL isAdd = FALSE;
	char additional[200];
	unsigned short devList;
	char oldProfileStr[40];
	char oldBuffer[61];
	char newBuffer[61];
	char aux[17];
	char dallasKeyEntry[20];
	PROFILE oldProfile;
	LoginMethod oldLoginMethod;
	volatile BOOL oldRequireDallas, oldRequirePin, newRequireDallas, newRequirePin;
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSetWithFilter: "users" filter: "" orderFields: "USER_ID"];
	ABSTRACT_RECORDSET myRecordSetBck;
	volatile BOOL addedDallasKeyUserToSafebox = FALSE;
	volatile BOOL addedPinUserToSafebox = FALSE;
	int userPimsId = 0;
	volatile BOOL updateRecord = FALSE;
	id lastProfile = NULL;
	id currentProfile = NULL;
	
	TRY

		[myRecordSet open];

		[self validateFields: anObject];
	
		// Verifico que el LOGIN_NAME no este duplicado
		[myDataSearcher setRecordSet: myRecordSet];
		[myDataSearcher addShortFilter: "USER_ID" operator: "!=" value: [anObject getUserId]];
		[myDataSearcher addStringFilter: "LOGIN_NAME" operator: "=" value: [anObject getLoginName]];
		[myDataSearcher addCharFilter: "DELETED" operator: "=" value: 0];
		if ([myDataSearcher find]) THROW(DAO_DUPLICATED_LOGIN_NAME_EX);
	
		// Verifico que la DALLAS KEY no este duplicada
		if (strlen([anObject getKey]) > 0) {
			[myDataSearcher clear];
			[myDataSearcher setRecordSet: myRecordSet];
			[myDataSearcher addShortFilter: "USER_ID" operator: "!=" value: [anObject getUserId]];
			[myDataSearcher addStringFilter: "KEY" operator: "=" value: [anObject getKey]];
			[myDataSearcher addCharFilter: "DELETED" operator: "=" value: 0];
			if ([myDataSearcher find]) THROW(DAO_DUPLICATED_DALLAS_KEY_EX);
		}

		// si no hay un usuario logueado y ademas se esta supervisando a la PIMS
		// entonces me logueo con el usuario PIMS para que quede auditado bajo dicho usuario
		if ( (![[UserManager getInstance] getUserLoggedIn]) && ([[TelesupScheduler getInstance] inTelesup]) ) {
			userPimsId = [[UserManager getInstance] logInUserPIMS];
		}

		additional[0] = '\0';
		sprintf(additional, "%s-%s", [anObject getLoginName], [anObject getFullName]);
		if ([anObject isDeleted]) {

			updateRecord = TRUE;

			// elimino al usuario de la placa
			if ([anObject isPinRequired]) {
				TRY
					[SafeBoxHAL sbDeleteUser: [anObject getLoginName]];
				CATCH
					if (ex_get_code() != CIM_USR_NOT_EXISTS_EX) RETHROW(); // La exception de que no existe la ignoro
				END_TRY
			}

			if ([anObject isDallasKeyRequired]) {
				TRY
					[SafeBoxHAL sbDeleteUser: [anObject getDallasKeyLoginName]];
				CATCH
					if (ex_get_code() != CIM_USR_NOT_EXISTS_EX) RETHROW(); // La exception de que no existe la ignoro
				END_TRY
			}

			[myRecordSet findById: "USER_ID" value: [anObject getUserId]];
			audit = [[Audit new] initAuditWithCurrentUser: Event_DELETE_USER additional: additional station: [anObject getUserId] logRemoteSystem: TRUE];

		} else if ([anObject getUserId] != 0) {

			updateRecord = TRUE;

			[myRecordSet findById: "USER_ID" value: [anObject getUserId]];

			// Todo esto es por si cambia el perfil del usuario, y antes necesita dallas o pin
			// y ahora no tengo que reflejar esos cambios en la placa
			oldProfile = [[UserManager getInstance] getProfile: [myRecordSet getShortValue: "PROFILE_ID"]];
			oldRequireDallas = oldRequirePin = newRequireDallas = newRequirePin = FALSE;
			oldLoginMethod = [myRecordSet getCharValue: "LOGIN_METHOD"];

			if ([oldProfile getSecurityLevel] == SecurityLevel_2 || [oldProfile getSecurityLevel] == SecurityLevel_3 || 
						oldLoginMethod == LoginMethod_PERSONALIDNUMBER) oldRequirePin = TRUE;

			if ([oldProfile getSecurityLevel] == SecurityLevel_2 || [oldProfile getSecurityLevel] == SecurityLevel_3 || 
						oldLoginMethod == LoginMethod_DALLASKEY || oldLoginMethod == LoginMethod_SWIPE_CARD_READER) oldRequireDallas = TRUE;

			newRequireDallas = [anObject isDallasKeyRequired];
			newRequirePin = [anObject isPinRequired];
			devList = 0;

			devList = [anObject getDevListMask];

			if (oldRequirePin && !newRequirePin) {
				TRY
					[SafeBoxHAL sbDeleteUser: [anObject getLoginName]];
				CATCH
					if (ex_get_code() != CIM_USR_NOT_EXISTS_EX) RETHROW(); // La exception de que no existe la ignoro
				END_TRY

			}

			if (oldRequireDallas && !newRequireDallas) {
				TRY
					[SafeBoxHAL sbDeleteUser: [anObject getDallasKeyLoginName]];
				CATCH
					if (ex_get_code() != CIM_USR_NOT_EXISTS_EX) RETHROW(); // La exception de que no existe la ignoro
				END_TRY

			}

			if (!oldRequirePin && newRequirePin) {
				TRY
					addedPinUserToSafebox = TRUE;
					
					[SafeBoxHAL sbAddUser: devList personalId: [anObject getLoginName] password: [anObject getPassword] duressPassword: [anObject getDuressPassword]];
				CATCH
					if (ex_get_code() != CIM_USER_EXISTS_EX) RETHROW(); // La exception de que no existe la ignoro
				END_TRY
			}

			if (!oldRequireDallas && newRequireDallas) {
				TRY
					addedDallasKeyUserToSafebox = TRUE;
					
					[SafeBoxHAL sbAddUser: devList personalId: [anObject getDallasKeyLoginName] password: [anObject getKey] duressPassword: [anObject getDuressPassword]];
				CATCH
					if (ex_get_code() != CIM_USER_EXISTS_EX) RETHROW();		// La exception de que no existe la ignoro
				END_TRY
			}

			// Seteo el cambio de password si corresponde
			if (strcmp([anObject getPassword],FICTICIOUS_PASSWORD) != 0) {

				aux[0] = '\0';
				strcpy(aux, [SafeBoxHAL getLogedUserPersonalId]);
				// si NO estoy editando al usuario logueado
				if (strcmp([anObject getLoginName], aux) != 0){

					if (!addedPinUserToSafebox) {
						// lo doy de baja y lo vuelvo a insertar en la placa
						if ([anObject isPinRequired]) {
							TRY
								[SafeBoxHAL sbDeleteUser: [anObject getLoginName]];
							CATCH
								if (ex_get_code() != CIM_USR_NOT_EXISTS_EX) RETHROW();		// La exception de que no existe la ignoro
							END_TRY
												
							[SafeBoxHAL sbAddUser: devList personalId: [anObject getLoginName] password: [anObject getPassword] duressPassword: [anObject getDuressPassword]];
						}
					}

				} else {
					// estoy editando al usuario logueado

                    printf("UserDAO oldPassword = %s newPassword = %s newDuressPassword = %s \n", [anObject getRealPassword], [anObject getPassword], [anObject getDuressPassword]);
                    
					// aplico el cambio de password en la placa
					[SafeBoxHAL sbChangePassword: [anObject getLoginName] 
							oldPassword: [anObject getRealPassword] 
							newPassword: [anObject getPassword] 
							newDuressPassword: [anObject getDuressPassword]];

					// actualizo el real password en memoria
					[anObject setRealPassword: [anObject getPassword]];

					// seteo en SafeBoxHAL la contrasenia del usuario logueado
					[SafeBoxHAL setLogedUserPassword: [anObject getPassword]];

				}
			}

			// Setea el cambio de Dallas si corresponde
			if ([anObject isDallasKeyRequired] && !addedDallasKeyUserToSafebox && 
				strcmp([anObject getKey], [myRecordSet getStringValue: "KEY" buffer: buffer]) != 0) {

//				doLog(0,"Cambio el valor de la llave Dallas\n");
						
				// aplico el cambio de password en la placa
				[SafeBoxHAL sbChangePassword: [anObject getDallasKeyLoginName] 
				oldPassword: [myRecordSet getStringValue: "KEY" buffer: buffer]
				newPassword: [anObject getKey]
				newDuressPassword: [anObject getDuressPassword]];

				// actualizo el real password en memoria
				[anObject setRealPassword: [anObject getKey]];

				// seteo en SafeBoxHAL la contrase�a del usuario logueado
				[SafeBoxHAL setLogedUserPassword: [anObject getKey]];

			}
			
			// si es un usuario especial no lo audito Salvo que sea el admin
			if ( (![anObject isSpecialUser]) || (([anObject isSpecialUser]) && ([anObject getUserId] == 1)) )
      			audit = [[Audit new] initAuditWithCurrentUser: Event_EDIT_USER additional: additional station: [anObject getUserId] logRemoteSystem: TRUE];

    } else {

			// inserto el usuario en la placa
			if ([anObject isPinRequired]) {
					

				//	doLog(0, "login = %s , password = %s, duress = %s \n", [anObject getLoginName], [anObject getPassword], [anObject getDuressPassword]);

	    		[SafeBoxHAL sbAddUser: 0 personalId: [anObject getLoginName] password: [anObject getPassword] duressPassword: [anObject getDuressPassword]];
			}

			// Inserto la clave correspondiente a la llave Dallas
			if ([anObject isDallasKeyRequired]) {
				strcpy(dallasKeyEntry, [anObject getDallasKeyLoginName]);
					
				[SafeBoxHAL sbAddUser: 0 personalId: dallasKeyEntry password: [anObject getKey] duressPassword: [anObject getDuressPassword]];
			}

			[myRecordSet add];
			isAdd = TRUE;
			// si es un usuario especial no lo audito Salvo que sea el admin
			if ( (![anObject isSpecialUser]) || (([anObject isSpecialUser]) && ([anObject getUserId] == 1)) ) {
				audit = [[Audit new] initAuditWithCurrentUser: Event_NEW_USER additional: additional station: 0 logRemoteSystem: TRUE];
				[audit setAlwaysLog: TRUE];
			}
		}

		// LOG DE CAMBIOS 
		if (![anObject isDeleted]) {

			// si es un usuario especial no lo audito Salvo que sea el admin
			if ( (![anObject isSpecialUser]) || (([anObject isSpecialUser]) && ([anObject getUserId] == 1)) ) {

				[audit logChangeAsString: RESID_User_NAME oldValue: [myRecordSet getStringValue: "NAME" buffer: buffer] newValue: [anObject getUName]];	
				[audit logChangeAsString: RESID_User_SURNAME oldValue: [myRecordSet getStringValue: "SURNAME" buffer: buffer] newValue: [anObject getUSurname]];	
				[audit logChangeAsString: RESID_User_LOGIN_NAME oldValue: [myRecordSet getStringValue: "LOGIN_NAME" buffer: buffer] newValue: [anObject getLoginName]];
				/* Comento lo de pines dinamicos
				[audit logChangeAsBoolean: RESID_User_DYNAMIC_PIN oldValue: [myRecordSet getCharValue: "USES_DYNAMIC_PIN"] newValue: [anObject getUsesDynamicPin]];
				*/
				[audit logChangeAsResourceString: FALSE 
				resourceId: RESID_User_LANGUAGE 
				resourceStringBase: RESID_RegionalSettings_LANGUAGE_NOT_DEFINED 
				oldValue: [myRecordSet getShortValue: "LANGUAGE"] 
				newValue: [anObject getLanguage] 
				oldReference: [myRecordSet getShortValue: "LANGUAGE"] 
				newReference: [anObject getLanguage]];
				
				oldProfileStr[0] = '\0';
	
				if ([myRecordSet getShortValue: "PROFILE_ID"] != 0)
					strcpy(oldProfileStr, [[[UserManager getInstance] getProfile: [myRecordSet getShortValue: "PROFILE_ID"]] getProfileName]);			
	
				[audit logChangeAsString: FALSE
				resourceId: RESID_User_PROFILE_ID 
				oldValue: oldProfileStr
				newValue: [[[UserManager getInstance] getProfile: [anObject getUProfileId]] getProfileName]  
				oldReference: [myRecordSet getShortValue: "PROFILE_ID"] 
				newReference: [anObject getUProfileId]];
	
				[audit logChangeAsBoolean: RESID_User_ACTIVE oldValue: [myRecordSet getCharValue: "ACTIVE"] newValue: [anObject isActive]];
				[audit logChangeAsString: RESID_User_BANK_ACCOUNT_NUMBER oldValue: [myRecordSet getStringValue: "BANK_ACCOUNT_NUMBER" buffer: buffer] newValue: [anObject getBankAccountNumber]];
	
				if (!isAdd)
					if ([anObject isLoggedIn])
						[audit logChangeAsDateTime: RESID_User_LAST_LOGIN_DATE oldValue: [myRecordSet getDateTimeValue: "LAST_LOGIN_DATE"] newValue: [anObject getLastLoginDateTime]];
	
				// obtengo las descripciones
				oldBuffer[0] = '\0';
				newBuffer[0] = '\0';
				switch ([myRecordSet getCharValue: "LOGIN_METHOD"])
				{
					case LoginMethod_PERSONALIDNUMBER: strcpy(oldBuffer, getResourceStringDef(RESID_PERSONAL_ID_NUMBER, "ID PERSONAL")); break;
					case LoginMethod_DALLASKEY: strcpy(oldBuffer, getResourceStringDef(RESID_DALLAS_KEY, "LLAVE DALLAS")); break;
					case LoginMethod_SWIPE_CARD_READER: strcpy(oldBuffer, getResourceStringDef(RESID_SWIPE_CARD_READER, "LECTOR TARJETA M")); break;
					case LoginMethod_FINGERPRINT: strcpy(oldBuffer, getResourceStringDef(RESID_FINGER_PRINT, "DETECTOR HUELLA")); break;
				}
	
				switch ([anObject getLoginMethod])
				{
					case LoginMethod_PERSONALIDNUMBER: strcpy(newBuffer, getResourceStringDef(RESID_PERSONAL_ID_NUMBER, "ID PERSONAL")); break;
					case LoginMethod_DALLASKEY: strcpy(newBuffer, getResourceStringDef(RESID_DALLAS_KEY, "LLAVE DALLAS")); break;
					case LoginMethod_SWIPE_CARD_READER: strcpy(newBuffer, getResourceStringDef(RESID_SWIPE_CARD_READER, "LECTOR TARJETA M")); break;
					case LoginMethod_FINGERPRINT: strcpy(newBuffer, getResourceStringDef(RESID_FINGER_PRINT, "DETECTOR HUELLA")); break;
				}
			
				[audit logChangeAsString: FALSE 
				resourceId: RESID_User_LOGIN_METHOD 
				oldValue: oldBuffer 
				newValue: newBuffer 
				oldReference: [myRecordSet getCharValue: "LOGIN_METHOD"] 
				newReference: [anObject getLoginMethod]];

			} else {
				if (isAdd) {
					// audito la creacion del usuario especial
					[Audit auditEvent: Event_CREATE_SPECIAL_USER additional: [anObject getUName] station: 0 logRemoteSystem: FALSE];
				}
			}
		}

		// obtengo el perfil que tenia antes, para saber si cambio.
		if (!isAdd)
			lastProfile = [[UserManager getInstance] getProfile: [myRecordSet getShortValue: "PROFILE_ID"]];

		[myRecordSet setStringValue: "NAME" value: [anObject getUName]];
		[myRecordSet setStringValue: "SURNAME" value: [anObject getUSurname]];
		[myRecordSet setStringValue: "LOGIN_NAME" value: [anObject getLoginName]];
		[myRecordSet setShortValue: "PROFILE_ID" value: [anObject getUProfileId]];
		[myRecordSet setCharValue: "DELETED" value: [anObject isDeleted]];
		[myRecordSet setCharValue: "ACTIVE" value: [anObject isActive]];

		// si el perfil cambio por uno que tiene diferente seteo en UseDuressPassword
		// entonces pongo la clave como temporal
		if (!isAdd) {
			currentProfile = [[UserManager getInstance] getProfile: [anObject getUProfileId]];
			if ( (lastProfile) && 
					([lastProfile getProfileId] != [currentProfile getProfileId]) && 
					(([lastProfile getUseDuressPassword]) && (![currentProfile getUseDuressPassword])) ||
					((![lastProfile getUseDuressPassword]) && ([currentProfile getUseDuressPassword])) ) {
				[anObject setIsTemporaryPassword: TRUE];
			}
		}

		[myRecordSet setCharValue: "TEMPORARY_PASSWORD" value: [anObject isTemporaryPassword]];

		if (isAdd) 
			[myRecordSet setDateTimeValue: "LAST_LOGIN_DATE" value: [SystemTime getLocalTime]];
		else
			[myRecordSet setDateTimeValue: "LAST_LOGIN_DATE" value: [anObject getLastLoginDateTime]];
	
		[myRecordSet setDateTimeValue: "LAST_CHANGE_PASSWORD_DATE" value: [anObject getLastChangePasswordDateTime]];
		[myRecordSet setStringValue: "BANK_ACCOUNT_NUMBER" value: [anObject getBankAccountNumber]];
		[myRecordSet setCharValue: "LOGIN_METHOD" value: [anObject getLoginMethod]];
		if (isAdd) [myRecordSet setDateTimeValue: "ENROLLED_DATE" value: [SystemTime getLocalTime]];
		[myRecordSet setStringValue: "KEY" value: [anObject getKey]];
		[myRecordSet setShortValue: "LANGUAGE" value: [anObject getLanguage]];
	/* Comento lo de pines dinamicos
		[myRecordSet setStringValue: "CLOSING_CODE" value: [anObject getClosingCode]];
		[myRecordSet setStringValue: "PREVIOUS_PIN" value: [anObject getPreviousPin]];
		[myRecordSet setCharValue: "USES_DYNAMIC_PIN" value: [anObject getUsesDynamicPin]];
	*/	
		userId = [myRecordSet save];
		[anObject setUserId: userId];
		// vuelvo a setear el password y duress ficticios para que en la pantalla de ABM de usuarios se muestre algo.
		[anObject setPassword: FICTICIOUS_PASSWORD];
		[anObject setDuressPassword: FICTICIOUS_DURESS_PASSWORD];
	
		// si es un usuario especial no lo audito Salvo que sea el admin
		if ( (![anObject isSpecialUser]) || (([anObject isSpecialUser]) && ([anObject getUserId] == 1)) ) {
			[audit setStation: userId];
			[audit saveAudit];
			[audit free];
		}

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "users_bck"]) {
			myRecordSetBck = [dbConnection createRecordSetWithFilter: "users_bck" filter: "" orderFields: "USER_ID"];
	
			if (updateRecord) [self doUpdateBackupUserById: "USER_ID" value: [anObject getUserId] backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "users_bck"];
			else [self doAddUserBackup: myRecordSetBck currentRecordSet: myRecordSet tableName: "users_bck" value: [anObject getUserId]];
		}

	FINALLY

		[myRecordSet free];

		// si el usuario PIMS esta logueado entonces lo deslogueo
		if (userPimsId > 0) {
			[[UserManager getInstance] logOffUserPIMS];
		}

	END_TRY
}

/**/
- (void) storePin: (id) anObject oldPassword: (char *) anOldPassword
{
	int userId;
  AUDIT audit;
	char buffer[61];
  int pinLife = 0;

	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSetWithFilter: "users" filter: "" orderFields: "USER_ID"];
	ABSTRACT_RECORDSET myRecordSetBck;
		
	[myDataSearcher setRecordSet: myRecordSet];
  [myDataSearcher addShortFilter: "USER_ID" operator: "!=" value: [anObject getUserId]];
	[myDataSearcher addStringFilter: "LOGIN_NAME" operator: "=" value: [anObject getLoginName]];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: 0];
	
	TRY

		[myRecordSet open];

    [self validateFields: anObject];

    printf("USERDAO - storePin anOldPassword = %s newPassword = %s \n", anOldPassword, [anObject getPassword]);
    
		// aplico el cambio de password en la placa
		// si me devuelve error la funcion tira una excepcion
		[SafeBoxHAL sbChangePassword: [anObject getLoginName] 
          oldPassword: anOldPassword 
	        newPassword: [anObject getPassword] 
          newDuressPassword: [anObject getDuressPassword]];

    [myRecordSet findById: "USER_ID" value: [anObject getUserId]];

    pinLife = [[CimGeneralSettings getInstance] getPinLife];
    if ((pinLife != 0) && ( ([myRecordSet getDateTimeValue: "LAST_CHANGE_PASSWORD_DATE"] != 0) && ([SystemTime getLocalTime] - [myRecordSet getDateTimeValue: "LAST_CHANGE_PASSWORD_DATE"]) >= (pinLife * 86400) ))
      strcpy(buffer, getResourceStringDef(RESID_TRIGGER_PIN_LIFE, "Caducidad de Clave"));  
    else if ([myRecordSet getCharValue: "TEMPORARY_PASSWORD"])
           strcpy(buffer, getResourceStringDef(RESID_TRIGGER_TEMPORAL_PIN, "Clave temporal"));
         else
           strcpy(buffer, getResourceStringDef(RESID_TRIGGER_MANUAL_CHANGE_PIN, "Cambio manual de clave"));
              
    audit = [[Audit new] initAuditWithCurrentUser: Event_CHANGE_PIN additional: buffer station: 0 logRemoteSystem: FALSE];
		
		[myRecordSet setCharValue: "TEMPORARY_PASSWORD" value: [anObject isTemporaryPassword]];
		[myRecordSet setDateTimeValue: "LAST_CHANGE_PASSWORD_DATE" value: [anObject getLastChangePasswordDateTime]];
				
		userId = [myRecordSet save];
		[anObject setUserId: userId];
    // actualizo el real password en memoria
    [anObject setRealPassword: [anObject getPassword]];
    // seteo en SafeBoxHAL la contrasenia del usuario logueado
    [SafeBoxHAL setLogedUserPassword: [anObject getPassword]];

		// si el usuario que acaba de cambiar su password es el admin y el archivo de
		// estado inicial del equipo existe entonces lo elimino para que no se pueda
		// aplicar ninguna plantilla
		if (userId == 1){
			if ([[TemplateParser getInstance] isInitialState])
				[[TemplateParser getInstance] deleteInitialStateFile];
		}

	  // vuelvo a setear el password y duress ficticios para que en la pantalla de ABM de usuarios se muestre algo.
    [anObject setPassword: FICTICIOUS_PASSWORD];
	  [anObject setDuressPassword: FICTICIOUS_DURESS_PASSWORD];
    
    [audit saveAudit];
    [audit free];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "users_bck"]) {
			myRecordSetBck = [dbConnection createRecordSetWithFilter: "users_bck" filter: "" orderFields: "USER_ID"];
	
			[self doUpdateBackupUserById: "USER_ID" value: [anObject getUserId] backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "users_bck"];
			
		}

	FINALLY

		[myRecordSet free];
	
	END_TRY
}

/**/
- (void) validateFields: (id) anObject
{
  PROFILE profile = NULL;

	/* 
		Validacion de nulidad de campos en cuanto a sus valores que reflejan invalidez
		name = vacio
	*/
	
  if (strlen([anObject getUName]) == 0) 
    THROW(DAO_USER_NAME_NULLED_EX);
         
	if (strlen([anObject getUSurname]) == 0) 
    THROW(DAO_SURNAME_NULLED_EX);
			 
  if (strlen([anObject getLoginName]) == 0) 
    THROW(DAO_LOGIN_NAME_NULLED_EX);

	if ([anObject isPinRequired]) {

		if (strlen([anObject getPassword]) < [[CimGeneralSettings getInstance] getPinLenght])
			THROW(DAO_INVALID_PASSWORD_EX);
	
		if (strlen([anObject getDuressPassword]) < [[CimGeneralSettings getInstance] getPinLenght])
			THROW(DAO_INVALID_DURESS_PASSWORD_EX);
	}

  profile = [anObject getProfile];

	// valido que el perfil este habilitado.
	if ((profile == NULL) || ([profile isDeleted]))
		THROW(DAO_INEXISTENT_PROFILE_EX);

	// si selecciono como metodo de login: DALLAS y dicho dispositivo no esta habilitado
	// en la configuracion general no lo dejo continuar
	if ([anObject getLoginMethod] == LoginMethod_DALLASKEY && 
			[[CimGeneralSettings getInstance] getLoginDevType] != LoginDevType_DALLAS_KEY)
			THROW(DALLAS_NOT_AVAILABLE_EX);

	// Si tiene configurado como DallasKey verifico que exista
  if ([anObject getLoginMethod] == LoginMethod_DALLASKEY &&
			strlen([anObject getKey]) == 0)
    THROW(DALLAS_KEY_REQUIRED_EX);

	// si selecciono como metodo de login: SWIPE CARD READER y dicho dispositivo no esta 
	// habilitado en la configuracion general no lo dejo continuar
	if ([anObject getLoginMethod] == LoginMethod_SWIPE_CARD_READER && 
			[[CimGeneralSettings getInstance] getLoginDevType] != LoginDevType_SWIPE_CARD_READER)
			THROW(SWIPE_CARD_NOT_AVAILABLE_EX);

	// Si tiene configurado como LECTOR DE TARJETA verifico que exista
  if ([anObject getLoginMethod] == LoginMethod_SWIPE_CARD_READER &&
			strlen([anObject getKey]) == 0)
    THROW(SWIPE_CARD_KEY_REQUIRED_EX);

	// Para los security level 2 y 3 debo tener una dallas
  if (([profile getSecurityLevel] == SecurityLevel_2 ||
			 [profile getSecurityLevel] == SecurityLevel_3) && 
				strlen([anObject getKey]) == 0) {
		if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_DALLAS_KEY)
    	THROW(DALLAS_KEY_REQUIRED_EX);
		else
			if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_SWIPE_CARD_READER)
				THROW(SWIPE_CARD_KEY_REQUIRED_EX);
			else
				THROW(DALLAS_OR_SWIPE_CARD_KEY_REQUIRED_EX);
	}

	// Para el SecurityLevel_3 debo tener un password
  if ([profile getSecurityLevel] == SecurityLevel_3 &&
			strlen([anObject getPassword]) == 0)
    THROW(PIN_REQUIRED_EX);

	// Para el SecurityLevel_3 debo tener un duress password
  if ([profile getSecurityLevel] == SecurityLevel_3 &&
			strlen([anObject getDuressPassword]) == 0)
    THROW(DURESS_PIN_REQUIRED_EX);

	// Para el SecurityLevel 1 y metodo de LOGIN manual debo tener un password
  if ([profile getSecurityLevel] == SecurityLevel_1 &&
			[anObject getLoginMethod] == LoginMethod_PERSONALIDNUMBER &&
			strlen([anObject getPassword]) == 0)
    THROW(PIN_REQUIRED_EX);

	// Para el SecurityLevel 1 y metodo de LOGIN manual debo tener un duress password
  if ([profile getSecurityLevel] == SecurityLevel_1 &&
			[anObject getLoginMethod] == LoginMethod_PERSONALIDNUMBER &&
			strlen([anObject getDuressPassword]) == 0)
    THROW(DURESS_PIN_REQUIRED_EX);

}

/**/
- (COLLECTION) getCompleteList
{
	assert(myCompleteList);

	return myCompleteList;
}

/**/
- (COLLECTION) getActiveList
{
	assert(myActiveList);

	return myActiveList;
}

/**/
- (COLLECTION) getDoorsByUser: (int) anUserId
{
	id obj;
	COLLECTION myDoors = [Collection new];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "doors_by_user"];

	[myRecordSet open];

	while ( [myRecordSet moveNext] ) {
    
    // Toma la puerta siempre y cuando corresponda al usuario
		if (([myRecordSet getShortValue: "USER_ID"] == anUserId) &&
			  ([myRecordSet getCharValue: "DELETED"] == 0)) 
		{
			obj = [Integer int: [myRecordSet getShortValue: "DOOR_ID"]];
			[myDoors add: obj];
		}
		
	}
	[myRecordSet free];

	return myDoors;
}

/*
NOTA: apartir de la nueva implementacion de puertas internas y externas se tuvo que
modificar la logica de almacenamiento de puertas asociadas a usuarios tanto para el data
como para la placa. Es decir que a nivel data se va a almacenar una cosa y en la placa
puede que se almacene otra dependiendo de la situacion. 
Ejemplo:

[I] = Puerta Interna
[E] = Puerta Externa

X = Deshabilitada
V = Habilitada

Datos en data    |    Datos en Placa
-----------------|----------------------
[I] X  [E] X     |    [I] X  [E] X
-----------------|----------------------
[I] X  [E] V     |    [I] X  [E] V
-----------------|----------------------
[I] V  [E] X     |    [I] V  [E] V
-----------------|----------------------
[I] V  [E] V     |    [I] V  [E] V
-----------------|----------------------
*/

/**/
- (void) storeDoorByUser: (int) aDoorId userId: (int) anUserId
{
	char additional[60];
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	ABSTRACT_RECORDSET myRecordSet;
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSetBck;
	unsigned short devList;
	id user = NULL;
  unsigned short mask;
	unsigned short lockerId;
	id outerDoor = NULL;
	id isDoorAsignToUser = NULL;
	BOOL addOuterInHard = FALSE;
	int userPimsId = 0;

  myRecordSet = [dbConnection createRecordSet: "doors_by_user"];
	
  if (![self existsDoor: aDoorId]) THROW(REFERENCE_NOT_FOUND_EX);
  if (![self existsUser: anUserId]) THROW(REFERENCE_NOT_FOUND_EX);
  
	[myDataSearcher setRecordSet: myRecordSet];
	[myDataSearcher addShortFilter: "DOOR_ID" operator: "=" value: aDoorId];
	[myDataSearcher addShortFilter: "USER_ID" operator: "=" value: anUserId];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];

	TRY

		[myRecordSet open];
		
		if ([myDataSearcher find]) THROW(DAO_DUPLICATED_REFERENCE_EX);

		// si no hay un usuario logueado y ademas se esta supervisando a la PIMS
		// entonces me logueo con el usuario PIMS para que quede auditado bajo dicho usuario
		if ( (![[UserManager getInstance] getUserLoggedIn]) && ([[TelesupScheduler getInstance] inTelesup]) ) {
			userPimsId = [[UserManager getInstance] logInUserPIMS];
		}

    user = [[UserManager getInstance] getUser: anUserId];

		// SI ES PUERTA INTERNA
		if ([[[CimManager getInstance] getDoorById: aDoorId] isInnerDoor]) {
			// traigo la puerta externa a la que pertenece
			outerDoor = [[[CimManager getInstance] getDoorById: aDoorId] getOuterDoor];
			// verifico si la puerta externa esta o no asignada al usuario
			isDoorAsignToUser = [user getUserDoor: [outerDoor getDoorId]];
			if (!isDoorAsignToUser) addOuterInHard = TRUE;
		}

    //*************** Almacenamiento en placa *****************************
    // obtengo la lista de devices de la placa por si tiene asignado doors
    // seteo el bit correspondiente
    // el bit 1 es el loker 1 cuyo id es 2
    // el bit 2 es el loker 2 cuyo id es 4
    
    // vuelvo a setear los devices en la placa
		if ([user isPinRequired]) {
			devList = [SafeBoxHAL sbGetUserDeviceList: [user getLoginName]];
			lockerId = ([[[CimManager getInstance] getDoorById: aDoorId] getLockHardwareId]);
		
			mask = lockerId;

			if (lockerId == 11) 
				mask = 8;
			
			if (lockerId == 12)
				mask = 16;
			
			
			devList = devList | mask;
	 	  [SafeBoxHAL sbSetUserDeviceList: [user getLoginName] deviceList: devList];
    }

		if ([user isDallasKeyRequired]) {
			devList = [SafeBoxHAL sbGetUserDeviceList: [user getDallasKeyLoginName]];
			lockerId = ([[[CimManager getInstance] getDoorById: aDoorId] getLockHardwareId]);

			mask = lockerId;

			if (lockerId == 11) 
				mask = 8;
			
			if (lockerId == 12)
				mask = 16;

			devList = devList | mask;
      [SafeBoxHAL sbSetUserDeviceList: [user getDallasKeyLoginName] deviceList: devList];
    }
    //***********************************************************************

		// Audito el evento
		sprintf(additional, "%s-%s", [[[UserManager getInstance] getUser: anUserId] getLoginName], [[[[CimManager getInstance] getCim] getDoorById: aDoorId] getDoorName]);
  	[Audit auditEventCurrentUser: Event_ASSIGNE_DOOR_BY_USER additional: additional station: 0 logRemoteSystem: TRUE];

		[myRecordSet add];
		[myRecordSet setShortValue: "DOOR_ID" value: aDoorId];
		[myRecordSet setShortValue: "USER_ID" value: anUserId];
		[myRecordSet setCharValue: "DELETED" value: FALSE];
		[myRecordSet save];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "doors_by_user_bck"]) {
			myRecordSetBck = [dbConnection createRecordSet: "doors_by_user_bck"];

			[self doAddBackup: myRecordSetBck currentRecordSet: myRecordSet tableName: "doors_by_user_bck"];
		}

	FINALLY
	
		[myRecordSet free];
		[myDataSearcher free];
	
		if (addOuterInHard) {
			// vuelvo a setear los devices en la placa porque debo agregar en forma automatica
			// la puerta externa. Solo se dar� de alta en la placa (No en el data del equipo).
			if ([user isPinRequired]) {
				devList = [SafeBoxHAL sbGetUserDeviceList: [user getLoginName]];
				lockerId = ([outerDoor getLockHardwareId]);

				mask = lockerId;
	
				if (lockerId == 11) 
					mask = 8;
				
				if (lockerId == 12)
					mask = 16;

				devList = devList | mask;
				[SafeBoxHAL sbSetUserDeviceList: [user getLoginName] deviceList: devList];
			}
	
			if ([user isDallasKeyRequired]) {
				devList = [SafeBoxHAL sbGetUserDeviceList: [user getDallasKeyLoginName]];
				lockerId = ([outerDoor getLockHardwareId]);

				mask = lockerId;
				if (lockerId == 11) 
					mask = 8;
				if (lockerId == 12)
					mask = 16;

				devList = devList | mask;
				[SafeBoxHAL sbSetUserDeviceList: [user getDallasKeyLoginName] deviceList: devList];
			}
		}

		// si el usuario PIMS esta logueado entonces lo deslogueo
		if (userPimsId > 0) {
			[[UserManager getInstance] logOffUserPIMS];
		}

	END_TRY

}

/**/
- (void) removeDoorByUser: (int) aDoorId userId: (int) anUserId
{
	char additional[60];
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DATA_SEARCHER myDataSearcherBck = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSet: "doors_by_user"];
	ABSTRACT_RECORDSET myRecordSetBck;
	unsigned short devList;
	id user;
	unsigned short mask;
	unsigned short lockerId;
	id innerDoor = NULL;
	id outerDoor = NULL;
	id isDoorAsignToUser = NULL;
	BOOL deleteInHard = TRUE;
	BOOL deleteOuterToHard = FALSE;
	int userPimsId = 0;

	if (![self existsDoor: aDoorId]) THROW(REFERENCE_NOT_FOUND_EX);
	if (![self existsUser: anUserId]) THROW(REFERENCE_NOT_FOUND_EX);

	[myDataSearcher setRecordSet: myRecordSet];
	[myDataSearcher addShortFilter: "DOOR_ID" operator: "=" value: aDoorId];
	[myDataSearcher addShortFilter: "USER_ID" operator: "=" value: anUserId];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];

	[myRecordSet open];
	if ([myDataSearcher find]) {

		// si no hay un usuario logueado y ademas se esta supervisando a la PIMS
		// entonces me logueo con el usuario PIMS para que quede auditado bajo dicho usuario
		if ( (![[UserManager getInstance] getUserLoggedIn]) && ([[TelesupScheduler getInstance] inTelesup]) ) {
			userPimsId = [[UserManager getInstance] logInUserPIMS];
		}

    user = [[UserManager getInstance] getUser: anUserId];

		// SI ES PUERTA EXTERNA
		if (![[[CimManager getInstance] getDoorById: aDoorId] isInnerDoor]) {
			// traigo la puerta interna
			innerDoor = [[CimManager getInstance] getInnerDoor: aDoorId];
			// verifico si hay puerta interna
			if (innerDoor) {
				// verifico si la puerta interna esta o no asignada al usuario
				isDoorAsignToUser = [user getUserDoor: [innerDoor getDoorId]];
				if (isDoorAsignToUser) deleteInHard = FALSE;
			}
		} else { //SI ES PUERTA INTERNA
			// traigo la puerta externa a la que pertenece
			outerDoor = [[[CimManager getInstance] getDoorById: aDoorId] getOuterDoor];
			// verifico si la puerta externa esta o no asignada al usuario
			isDoorAsignToUser = [user getUserDoor: [outerDoor getDoorId]];
			if (!isDoorAsignToUser) deleteOuterToHard = TRUE;
		}

    //*************** Almacenamiento en placa solo si corresponde ************
		if (deleteInHard) {
			// obtengo la lista de devices de la placa por si tiene asignado doors			
			// seteo el bit correspondiente
			// el bit 1 es el loker 1 cuyo id es 2
			// el bit 2 es el loker 2 cuyo id es 4
			devList = [SafeBoxHAL sbGetUserDeviceList: [user getLoginName]];
			lockerId = ~([[[CimManager getInstance] getDoorById: aDoorId] getLockHardwareId]);

			mask = lockerId;
			if (lockerId == 11) 
				mask = ~(8);
			if (lockerId == 12)
				mask = ~(16);


			devList = devList & mask;
			
			// vuelvo a setear los devices en la placa
			if ([user isPinRequired]) {
				[SafeBoxHAL sbSetUserDeviceList: [user getLoginName] deviceList: devList];
			}
	
			if ([user isDallasKeyRequired]) {
				[SafeBoxHAL sbSetUserDeviceList: [user getDallasKeyLoginName] deviceList: devList];
			}
		}
		//**************************************************************************

		// Audito el evento
		sprintf(additional, "%s-%s", [[[UserManager getInstance] getUser: anUserId] getLoginName], [[[[CimManager getInstance] getCim] getDoorById: aDoorId] getDoorName]);

  	[Audit auditEventCurrentUser: Event_DELETE_DOOR_BY_USER additional: additional station: 0 logRemoteSystem: TRUE];

		[myRecordSet setCharValue: "DELETED" value: TRUE];
		[myRecordSet save];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "doors_by_user_bck"]) {
			myRecordSetBck = [dbConnection createRecordSet: "doors_by_user_bck"];

			[myDataSearcherBck setRecordSet: myRecordSetBck];
			[myDataSearcherBck addShortFilter: "DOOR_ID" operator: "=" value: aDoorId];
			[myDataSearcherBck addShortFilter: "USER_ID" operator: "=" value: anUserId];
			[myDataSearcherBck addCharFilter: "DELETED" operator: "=" value: FALSE];

			[self doUpdateBackup: myRecordSetBck currentRecordSet: myRecordSet dataSearcher: myDataSearcherBck tableName: "doors_by_user_bck"];
		}

		[myRecordSet free];

		// Elimino la puerta externa solo de la placa segun corresponda.
		if (deleteOuterToHard) {
			devList = [SafeBoxHAL sbGetUserDeviceList: [user getLoginName]];

			lockerId = ~([outerDoor getLockHardwareId]);

			mask = lockerId;
			if (lockerId == 11) 
				mask = ~(8);
			if (lockerId == 12)
				mask = ~(16);

			devList = devList & mask;
			
			// vuelvo a setear los devices en la placa
			if ([user isPinRequired]) {
				[SafeBoxHAL sbSetUserDeviceList: [user getLoginName] deviceList: devList];
			}
	
			if ([user isDallasKeyRequired]) {
				[SafeBoxHAL sbSetUserDeviceList: [user getDallasKeyLoginName] deviceList: devList];
			}
		}

		// si el usuario PIMS esta logueado entonces lo deslogueo
		if (userPimsId > 0) {
			[[UserManager getInstance] logOffUserPIMS];
		}

		return;
	}
	
	[myRecordSet free];
}

- (BOOL) existsDoor: (int) aDoorId
{
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "doors" filter: "" orderFields: "DOOR_ID"];

  [myDataSearcher setRecordSet: myRecordSet];
	[myDataSearcher addShortFilter: "DOOR_ID" operator: "=" value: aDoorId];

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

- (BOOL) existsUser: (int) anUserId
{
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "users" filter: "" orderFields: "USER_ID"];

  [myDataSearcher setRecordSet: myRecordSet];
	[myDataSearcher addShortFilter: "USER_ID" operator: "=" value: anUserId];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: 0];

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

@end
