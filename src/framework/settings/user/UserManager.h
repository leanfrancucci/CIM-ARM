#ifndef USER_MANAGER_H
#define USER_MANAGER_H

#define USER_MANAGER id

#include "Object.h"
#include "ctapp.h"
#include "Profile.h"
#include "User.h"
#include "Operation.h"

/**
 * Clase  
 */
 

 
#define SET_CASH_OP								(1) // Cash Config
#define SET_REFERENCE_OP					(2) // Reference Config
#define OPEN_DOOR_OP							(3) // Door Access
#define OVERRIDE_DOOR_OP					(4) // Door Override
#define DEVICE_CONFIG_OP					(5) // Device Config
#define DOORS_BY_USER_OP					(6) // Doors by User
#define EXTENDED_DROP_CONFIG_OP		(7) // Extend Drop Conf
#define INSERT_BOOKMARK_OP				(8) // Insert Bookmark
#define INSTADROP_CONFIG_OP		    (9) // InstaDrop Config
#define MANUAL_DROP_OP						(10)// Manual Drop
#define VALIDATED_DROP_OP					(11)// Validated Drop
#define GENERAL_PRINT_SETTINGS_OP	(12)// Printing Config
#define AUDIT_REPORT_OP						(13)// Audit Report
#define CASH_REPORT_OP						(14)// Cash Report
#define GRAND_Z_REPORT_OP					(15)// End Day Report
#define ENROLLED_USER_REPORT_OP		(16)// Enrolled User Report
#define GRAND_X_REPORT_OP					(17)// Grand X
#define OPERATOR_REPORT_OP				(18)// Operator Report
#define OPERATORS_REPORT_OP				(19)// Operators Report
#define REFERENCE_REPORT_OP				(20)// Reference Report
#define REPRINT_DEPOSIT_OP				(21)// Reprint Deposit
#define REPRINT_DROP_OP						(22)// Reprint Drop
#define REPRINT_END_DAY_OP				(23)// Reprint End Day
#define SYSTEM_INFO_REPORT_OP			(24)// System Report
#define TELESUP_REPORT_OP					(25)// Telesup Report
#define CMP_TELESUP_OP						(26)// CMP Telesup
#define SUPERVISION_SETTINGS_OP		(27)// Telesup Config
#define SUPERVISION_OP						(28)// Telesupervision
#define BACKUP_OP									(29)// BackUp
#define NETWORK_SETTINGS_OP				(30)// Network Config
#define REBOOT_OP									(31)// Reboot
#define RESTORE_OP								(32)// Restore
#define REGIONAL_SETTINGS_OP			(33)// Regional Config
#define SHUTDOWN_OP								(34)// Shutdown
#define DELETE_USER_OP						(35)// Delete User
#define USER_STATE_OP							(36)// User State
#define USERS_ADMINISTRATION_OP		(37)// Enroll/Updat Usr
#define FORCE_PIN_CHANGE_OP				(38)// Force Pin Change
#define PROFILES_ADMINISTRATION_OP (39)// Profile Config
#define DUAL_ACCESS_OP						(40)// Dual Access
#define GENERAL_SETTINGS_OP				(41)// General Settings
#define SEND_UPGRADES_OP					(42)// Send Upgrades
#define WORK_ORDER_OP							(43)// Work Order
#define REPAIR_ORDER_OP						(44)// Repair Order
#define RECEIVE_LOGS_OP						(45)// Receive Logs
#define DUMP_SETTINGS_OP					(46)// Dump settings
#define RUN_HARDWARE_TEST_OP			(47)// Run hardware test
#define SIM_CARD_CONFIG_OP				(48)// Run hardware test
#define INSTA_DROP_OP							(49)// Insta drop 
#define STATE_CHANGE_OP						(50)// Cambio de estado
#define DEVICE_COMMUNICATION_OP		(51)// Habilitar y deshabilitar comunicacion con validadores
#define SET_DOORS_OP							(52) // Door Config
/*
#define PRINT_CLOSE_CODE_OP					(51)// Impresion de Codigo de Cierre
#define RESET_DYNAMIC_PIN_OP					(52)// Reseteo de PIN Dinamico
*/


#define OPERATION_COUNT 	(52) // Indica la cantidad total de operaciones.


@interface UserManager:  Object
{
	COLLECTION myProfiles;
	COLLECTION myUsers;
	COLLECTION myOperations;
	COLLECTION myVisibleUsersList;
	COLLECTION myVisibleProfilesList;
	COLLECTION myDualAccessList;
	COLLECTION myVUsers;
	COLLECTION myVProfiles;
	COLLECTION myUsersCompleteList;
	int myCantLoginFails;
	BOOL myExistUserPims;
	BOOL myExistUserOverride;
	USER myUserPims;
	USER myUserOverride;
	BOOL myLoginInProcess;

	char myUserToLogin[11]; // este campo seria el PersonalIdNumber (solo numerico de 9 digitos)
	char myPasswordToLogin[9];
	char myUserToLoginName[22];
	char myUserToLoginSurname[22];
	BOOL myUserToLoginResponse;
	char myUserToLoginProfileName[30];

	id myHoytsUser;
}

/**
 * 
 */

+ new;
+ getInstance;
- initialize;

/*******************************************************************************************
*																			PROFILE SETTINGS
*
*******************************************************************************************/

/**
 * Setea los valores correspondientes a la configuracion de los perfiles
 */

- (void) setProfileName: (int) aProfileId value: (char*) aValue;
- (void) setFatherId: (int) aProfileId value: (int) aValue;
- (void) setResource: (int) aProfileId value: (char*) aValue;
- (void) setKeyRequired: (int) aProfileId value: (BOOL) aValue;
- (void) setTimeDelayOverride: (int) aProfileId value: (BOOL) aValue;
- (void) setOperationsList: (int) aProfileId value: (unsigned char*) aValue;
- (void) setSecurityLevel: (int) aProfileId value: (SecurityLevel) aValue;
- (void) setUseDuressPassword: (int) aProfileId value: (BOOL) aValue;

/**
 * Devuelve los valores correspondientes a la configuracion de los perfiles
 */

- (char*) getProfileName: (int) aProfileId;
- (int) getFatherId: (int) aProfileId;
- (char*) getResource: (int) aProfileId;
- (BOOL) getKeyRequired: (int) aProfileId;
- (BOOL) getTimeDelayOverride: (int) aProfileId;
- (unsigned char*) getOperationsList: (int) aProfileId;
- (SecurityLevel) getSecurityLevel: (int) aProfileId; 
- (BOOL) getUseDuressPassword: (int) aProfileId;

/**
 * Aplica los cambios en la persistencia realizados al perfil pasado como parametro
 */

- (void) applyProfileChanges: (int) aProfileId;

/**
 * Agrega un perfil
 */

- (int) addProfile:(char*) aName resource: (char*) aResource keyRequired: (BOOL) aKeyRequired fatherId: (int) aFatherId timeDelayOverride: (BOOL) aTimeDelayOverride operationsList: (unsigned char*) anOperationsList securityLevel: (SecurityLevel) aSecurityLevel useDuressPassword: (BOOL) anUseDuressPassword;

/**
 * Verifica si se puede eliminar un perfil (return BOOL)
 */
- (BOOL) canRemoveProfile: (int) aProfileId;

/**
 * Verifica si se puede eliminar un perfil
 */
- (void) removeProfile: (int) aProfileId;

/**
 * Remueve un prefil y sus hijos (si los tiene)
 */
- (void) deleteProfile: (PROFILE) aProfile;

/**
 * Agrega un perfil a la lista de perfiles
 */

- (void) addProfileToCollection: (PROFILE) aProfile;

/**
 * Remueve un perfil a la lista de perfiles
 */

- (void) removeProfileFromCollection: (int) aProfileId;
- (void) removeProfileFromVisibleCollection: (int) aProfileId;

/**
 * Restaura los valores de la configuracion del perfil
 */

- (void) restoreProfile: (int) aProfileId;

/**
 * Obtiene un perfil de la lista
 */

- (PROFILE) getProfile: (int) aProfileId;

/**
 * Obtiene un perfil de la lista por el nombre
 */

- (PROFILE) getProfileByName: (char*) aProfileName;

/**
 * Devuelve una coleccion con todos los perfiles activos
 */
- (COLLECTION) getProfiles;

/**
 * 
 */
- (COLLECTION) getProfileIdList;

/**
 * Devuelve una coleccion con todos los perfiles hijos de un prefil pasado por parametro
 */
- (void) getChildProfiles: (int) aProfileId childs: (COLLECTION) aChild;

/**
 * Devuelve si un perfile tiene asociado uno o mas usuarios
 */
- (BOOL) hasAssociatedUsers: (int) aProfileId;

/**
 * Actualiza las operaciones de los perfiles hijos si es que al padre se le quito una operacion
 */
- (void) deactivateOpByChildrenProfile: (int) aProfileId operationsList: (unsigned char*) anOperationsList;

/*******************************************************************************************
*																			USER SETTINGS
*
*******************************************************************************************/

/**
 * Setea los valores correspondientes a la configuracion de los usuarios
 */

- (void) setUserName: (int) aUserId value: (char*) aValue;
- (void) setUserSurname: (int) aUserId value: (char*) aValue;
- (void) setUserLoginName: (int) aUserId value: (char*) aValue;
- (void) setUserPassword: (int) aUserId value: (char*) aValue;
- (void) setUserProfileName: (int) aUserId value: (char*) aValue;
- (void) setUserProfileId: (int) aUserId value: (int) aValue;
- (void) setUserDuressPassword: (int) aUserId value: (char*) aValue;
- (void) setUserActive: (int) aUserId value: (BOOL) aValue;
- (void) setUserIsTemporaryPassword: (int) aUserId value: (BOOL) aValue;
- (void) setUserLastLoginDateTime: (int) aUserId value: (datetime_t) aValue;
- (void) setUserLastChangePasswordDateTime: (int) aUserId value: (datetime_t) aValue;
- (void) setUserBankAccountNumber: (int) aUserId value: (char*) aValue;
- (void) setUserLoginMethod: (int) aUserId value: (int) aValue;
- (void) setUserEnrollDateTime: (int) aUserId value: (datetime_t) aValue;
- (void) setUserKey: (int) aUserId value: (char*) aValue;
- (void) setUserLanguage: (int) aUserId value: (LanguageType) aLanguage;
- (void) setUserUsesDynamicPin: (int) aUserId value: (BOOL) aValue;

/**
 * Devuelve los valores correspondientes a la configuracion de los usuarios
 */

- (char*) getUserName: (int) aUserId;
- (char*) getUserSurname: (int) aUserId;
- (char*) getUserLoginName: (int) aUserId;
- (char*) getUserPassword: (int) aUserId;
- (int) getUserProfileId: (int) aUserId;
- (char*) getUserDuressPassword: (int) aUserId;
- (BOOL) getUserActive: (int) aUserId;
- (BOOL) getUserTemporaryPassword: (int) aUserId;
- (datetime_t) getUserLastLoginDateTime: (int) aUserId;
- (datetime_t) getUserLastChangePasswordDateTime: (int) aUserId;
- (char*) getUserBankAccountNumber: (int) aUserId;
- (int) getUserLoginMethod: (int) aUserId;
- (datetime_t) getUserEnrollDateTime: (int) aUserId;
- (char*) getUserKey: (int) aUserId;
- (BOOL) userIsDeleted: (int) aUserId;
- (LanguageType) getUserLanguage: (int) aUserId;
- (BOOL) getUserUsesDynamicPin: (int) aUserId;

/**/
- (USER) getUserPims;
- (USER) getUserOverride;

/**/
- (USER) getUserByLoginName: (char *) aLoginName;

/**/
- (BOOL) existUserPims;
- (BOOL) existUserOverride;

/**/
- (void) verifiedSpecialUsers;
- (void) createSpecialUsers;

/**/
- (int) logInUserPIMS;
- (void) logOffUserPIMS;

/**
 * Aplica los cambios en la persistencia realizados al usuario pasado como parametro
 */

- (void) applyUserChanges: (int) aUserId;

/**
 * Agrega un usuario con el id de perfil pasado como parametro
 */

- (int) addUserByProfileId: (char*) aName 
													  surname: (char*) aSurname 
														profileId: (int) aProfileId 
														loginName: (char*) aLoginName 
														password: (char*) aPassword 
														duressPassword: (char*) aDuressPassword 
														active: (BOOL) anActive 
														temporaryPassword: (BOOL) aTemporaryPassword 
														lastLoginDateTime: (datetime_t) aLastLoginDateTime 
														lastChangePasswordDateTime: (datetime_t) aLastChangePasswordDateTime 
														bankAccountNumber: (char*) aBankAccountNumber 
														loginMethod: (int) aLoginMethod 
														enrollDateTime: (datetime_t) anEnrollDateTime 
														key: (char*) aKey
														language: (LanguageType) aLanguage
														usesDynamicPin: (BOOL) aUsesDynamicPin; 


/**
 * Agrega un usuario con el nombre de perfil pasado como parametro
 */

- (int) addUserByProfileName: (char*) aName 
                              surname: (char*) aSurname 
                              profileName: (char*) aProfileName 
                              loginName: (char*) aLoginName 
                              password: (char*) aPassword 
                              duressPassword: (char*) aDuressPassword 
                              active: (BOOL) anActive 
                              temporaryPassword: (BOOL) aTemporaryPassword 
                              lastLoginDateTime: (datetime_t) aLastLoginDateTime 
                              lastChangePasswordDateTime: (datetime_t) aLastChangePasswordDateTime 
                              bankAccountNumber: (char*) aBankAccountNumber 
                              loginMethod: (int) aLoginMethod 
                              enrollDateTime: (datetime_t) anEnrollDateTime 
                              key: (char*) aKey
							  language: (LanguageType) aLanguage
  							  usesDynamicPin: (BOOL) aUsesDynamicPin; 


/**
 * Indica si puedo o no remover un usuario
 */
- (BOOL) canRemoveUser: (int) aUserId;


/**
 * Remueve un usuario
 */
- (void) removeUser: (int) aUserId;


/**
 * Agrega un usuario a la lista de usuarios
 */

- (void) addUserToCollection: (USER) aUser;

/**
 * Remueve un usuario a la lista de usuarios
 */

- (void) removeUserFromCollection: (int) aUserId;

- (void) removeUserFromVisibleCollection: (int) aUserId;

/**
 * Restaura los valores de la configuracion del usuario
 */

- (void) restoreUser: (int) aUserId;

/**
 * Obtiene un usuario de la lista
 */

- (USER) getUser: (int) aUserId;
- (USER) getUserFromCompleteList: (int) aUserId;
- (USER) getUserByDallasKey: (COLLECTION) aDallasKeys;

/**
 * Indica si el admin esta en estado inicial. Clave temporal && password = 5231
 */
- (BOOL) isAdminInInitialState;

/**
 * Valida si el login y password corresponde con algun usuario,
 * y en el caso que sea correcto permite la realizacion del login.
 * Retorna el idUser correspondiente en el caso de que haya sido exitoso
 * el login.
 */
- (int) logInUser: (char*) aLoginName password: (char*) aPassword dallasKeys: (COLLECTION) aDallasKeys;
- (int) loginExternalUser: (char*) aLoginName;

/**
 * Metodos que permiten indicar si estoy en proceso de login.
 */
- (void) setLoginInProgress: (BOOL) aValue;
- (BOOL) isLoginInProgress;

/** 
 * Valida que el login y el password sean correctos pero no loguea al usuario
 * Retorna el idUser correspondiente en el caso de que haya sido exitoso
 * el login.
 */
- (int) validateUser: (char*) aLoginName password: (char*) aPassword dallasKeys: (COLLECTION) aDallasKeys;

/**
 * Valida el usuario remoto. En caso de que el usuario sea correcto retorna el id de usuario.
 */
- (USER) validateRemoteUser: (char*) aLoginName password: (char*) aPassword;

/** 
 * Desloguea al usuario que posee el id pasado como parametro.
 */
- (void) logOffUser: (int) aUserId;

/**
 * Devuelve el usuario logueado
 */

- (USER) getUserLoggedIn;

/**
 * Devuelve los usuarios activos del sistema
 */
- (COLLECTION) getUsers;

/**
 * Devuelve la lista completa de usuarios.
 */
- (COLLECTION) getUsersCompleteList;

/**
 * Devuelve la lista de usuarios visibles desde la interface.
 */
- (COLLECTION) getVisibleUsers;

/**
 * Devuelve la lista de usuarios que tienen configurado PIN DINAMICO
 */
- (COLLECTION) getDynamicPinUsers;

/**
 * Devuelve la lista de usuarios visibles a partir de un usuario. 
 * (osea los que esten i gual o por debajo de su perfil)
 */
- (COLLECTION) getUsersWithChildren: (int) anUserId;

/**
 * Carga la lista de pefiles pero sin cargar al SUPER.
 */
- (void) setVisibleProfiles;

/**
 * Devuelve la lista de perfiles visibles desde la interface.
 */
- (COLLECTION) getVisibleProfiles;

/**
 * Devuelve la lista de perfiles con sus hijos.
 */
- (COLLECTION) getProfilesWithChildren: (int) aProfileId;

/**
 * Carga la lista de usuarios pero sin cargar al superusuario.
 */
- (void) setVisibleUsers;

/**
 * Devuelve TRUE si el permiso pasado como parametro corresponde con el perfil del
 * usuario pasado como parametro. FALSE en caso contrario.
 */
- (BOOL) hasUserPermission: (int) aUserId operation: (int) anOperationId;

/**
 * Devuelve TRUE si el permiso pasado como parametro corresponde con el perfil 
 * pasado como parametro. FALSE en caso contrario.
 */
- (BOOL) hasProfilePermission: (int) aProfileId operation: (int) anOperationId;

/**
 * Verifica que exista algun usuario que posea el perfil Administrador a parte del 
 * pasado como parametro.
 */
- (BOOL) hasAdminUser: (int) aUserId;

/**/
- (void) verifiedAutoInactivateDelete;

/*
 * Fuerza el cambio de PIN para todos los usuarios
 */
- (void) ForcePinChange;

/**
 * pone la clave como temporal para todos los usuarios que pertenecen a un perfil
 */
- (void) setTemporalUsersPinFromProfile: (int) aProfileId;

/*******************************************************************************************
*																			OPERATIONS 
*
*******************************************************************************************/

/**
 *
 */

- (OPERATION) getOperation: (int) anOperationId;

/** 
 *
 */

- (char*) getOperationName: (int) anOperationId;
- (char*) getOperationResource: (int) anOperationId;
- (COLLECTION) getAllOperations;


/*******************************************************************************************
*																			DOORS BY USER
*
*******************************************************************************************/

/**
 *
 */
- (void) activateDoorByUserId: (int) aDoorId userId: (int) anUserId;

/**
 *
 */
- (void) deactivateDoorByUser: (int) aDoorId userId: (int) anUserId;

/**
 *
 */
- (COLLECTION) getDoorsByUserList: (int) anUserId;


/**
 *
 */
- (COLLECTION) getDoorsByUserIdList: (int) anUserId;

/**
 *
 */
- (void) deactivateDoorsToUsersFromProfile: (int) aProfileId;

/*******************************************************************************************
*																			DUAL ACCESS PROFILE
*
*******************************************************************************************/

/**
 *
 */
- (BOOL) verifiedDualAccess: (int) aProfile1Id profile2Id: (int) aProfile2Id;

/**
 *
 */
- (void) activateDualAccess: (int) aProfile1Id profile2Id: (int) aProfile2Id;

/**
 *
 */
- (void) deactivateDualAccess: (int) aProfile1Id profile2Id: (int) aProfile2Id;


/**
 * Trae todos los dual access
 */
- (COLLECTION) getAllDualAccess;

/**
 * Trae los dual access a partir de un perfil determinado. En este metodo se tiene en 
 * cuenta la estructura gerarquica de los perfiles.
 */
- (COLLECTION) getVisibleDualAccess: (int) aProfileId;


/**
 *
 */
- (void) addDualAccessToCollection: (id) aDualAccess;

/**
 *
 */
- (void) removeDualAccessFromCollection: (id) aDualAccess;

/**
 *
 */
- (id) getDualAccessFromCollection: (int) aProfile1Id profile2Id: (int) aProfile2Id;

/**
 *
 */
- (id) getDualAccess: (int) aProfile1Id profile2Id: (int) aProfile2Id;

/**
 *	Devuelve TRUE si la combinacion de perfiles estan permitidos para abrir puertas.
 */
- (BOOL) hasDualAccess: (int) aProfile1Id profile2Id: (int) aProfile2Id;

/**/
- (char*) getUserToLogin;
- (char*) getPasswordToLogin;
- (void) setUserToLoginName: (char*) aValue;
- (void) setUserToLoginSurname: (char*) aValue;
- (void) setUserToLoginResponse: (BOOL) aValue;
- (USER) addHoytsUser: (char*) aName surname: (char*) aSurname loginName: (char*) aLoginName password: (char*) aPassword duressPassword: (char*) aDuressPassword profileName: (char*) aProfileName;
- (int) logInHoytsUser: (char*) aLoginName password: (char*) aPassword telesup: (id) aTelesup dallasKeys: (COLLECTION) aDallasKeys;
- (void) setUserToLoginProfileName: (char*) aProfileName;
- (id) getHoytsUser;
 
@end

#endif

