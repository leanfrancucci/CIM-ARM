#ifndef USER_H
#define USER_H

#define USER id

#include "Object.h"
#include "ctapp.h"
#include "Operation.h"
#include "Door.h"
#include "Profile.h"

#define FICTICIOUS_PASSWORD						"12344321"
#define FICTICIOUS_DURESS_PASSWORD		"12344322"
#define BLANK_DURESS_PASSWORD    			"0DURESS0"

#define PIMS_USER_NAME								"00PIMS00"
#define PIMS_PASSWORD									"52311325"
#define PIMS_DURESS_PASSWORD					"52311326"
#define OVERRIDE_USER_NAME						"00OVER00"
#define OVERRIDE_PASSWORD							"52311325"
#define OVERRIDE_DURESS_PASSWORD			"52311326"

/**
 *	Especifica el tipo de dispositivo "aceptador".
 */
typedef enum {
	LoginMethod_UNDEFINED,
	LoginMethod_PERSONALIDNUMBER,		/** numero de identificacion personal */
	LoginMethod_DALLASKEY,		      /** llave Dallas */
	LoginMethod_SWIPE_CARD_READER,	/** tarjeta magnetica */
	LoginMethod_FINGERPRINT		      /** detector de huella */
} LoginMethod;

/**
 *	Representa un usuario.
 * 	
 */
@interface User :  Object
{
	int myUserId;
	char myName[22];
	char mySurname[22];
	char myLoginName[11]; // este campo seria el PersonalIdNumber (solo numerico de 9 digitos)
	char myPassword[9];
	char myDuressPassword[9]; // password para utilizar en caso de robo
	char myRealPassword[9];
	int myProfileId;
	BOOL myLoggedIn;
	BOOL myDeleted;
	BOOL myActive; // indica si el usuario esta o no activo. 1 = ACTIVO / 0 = INACTIVO
	BOOL myIsTemporaryPassword; // indica si la clave actual es temporaria, en cuyo caso debe solicitar cambio de clave.
	datetime_t myLastLoginDateTime; // indica la ultima fecha en la que se logueo el usuario
	datetime_t myLastChangePasswordDateTime; // indica la fecha en la que cambio el password
	char myBankAccountNumber[22]; // numero de cuenta bancaria
	int myLoginMethod; // tipo de logueo.
	datetime_t myEnrollDateTime; // indica la fecha de creacion del usuario
	char myKey[21];
	COLLECTION myDoors;
	LanguageType myLanguage;
	char myDallasKeyLoginName[30];
	BOOL myIsSpecialUser; // indica si el usuario es especial. Admin, PIMS y Override. Este dato solo se mantiene en memoria (NO se almacena en el data)
  char closingCode[9];
	char previousPin[9];
	BOOL usesDynamicPin;
	BOOL pinJustGenerated;
	char myFullName[50];
}

+ new;
- initialize;

/**
 * Setea los valores correspondientes a los usuarios
 */

- (void) setUserId: (int) aValue;
- (void) setUName: (char*) aValue;
- (void) setUSurname: (char*) aValue;
- (void) setLoginName: (char*) aValue;
- (void) setPassword: (char*) aValue;
- (void) setUProfileId: (int) aValue;
- (void) setDeleted: (BOOL) aValue;
- (void) setDuressPassword: (char*) aValue;
- (void) setActive: (BOOL) aValue;
- (void) setIsTemporaryPassword: (BOOL) aValue;
- (void) setLastLoginDateTime: (datetime_t) aValue;
- (void) setLastChangePasswordDateTime: (datetime_t) aValue;
- (void) setBankAccountNumber: (char*) aValue;
- (void) setLoginMethod: (int) aValue;
- (void) setEnrollDateTime: (datetime_t) aValue;
- (void) setKey: (char*) aValue;
- (void) setLanguage: (LanguageType) aLanguage;
- (void) setIsSpecialUser: (BOOL) aValue;
- (void) setClosingCode: (char*) aValue;
- (void) setPreviousPin: (char*) aValue;
- (void) setUsesDynamicPin: (BOOL) aValue;
- (void) setWasPinGenerated: (BOOL) pinGenerated;

/**
 * Devuelve los valores correspondientes a los usuarios
 */

- (int) getUserId;
- (char*) getUName;
- (char*) getUSurname;
- (char*) getLoginName;
- (char*) getPassword;
- (char*) getFullName;
- (int) getUProfileId;
- (BOOL) isDeleted;
- (char*) getDuressPassword;
- (BOOL) isActive;
- (BOOL) isTemporaryPassword;
- (datetime_t) getLastLoginDateTime;
- (datetime_t) getLastChangePasswordDateTime;
- (char*) getBankAccountNumber;
- (int) getLoginMethod;
- (datetime_t) getEnrollDateTime;
- (char*) getKey;
- (LanguageType) getLanguage;
- (BOOL) isSpecialUser;
- (char *) getClosingCode;
- (char *) getPreviousPin;
- (BOOL) getUsesDynamicPin;
- (BOOL) getWasPinGenerated;
	
/**
 * Aplica los cambios realizados al usuario en la persistencia.
 */
- (void) applyChanges;
- (void) applyPinChanges: (char *) anOldPassword;

/**
 * Restaura los valores de la persistencia
 */
- (void) restore;

/**
 *
 */
- (void) setLoggedIn: (BOOL) aValue;

/**
 * Retorna si el usuario se encuentra logueado.
 */

- (BOOL) isLoggedIn;

/**
 * Devuelve TRUE en el caso que posea permiso para realizar la operacion pasada como parametro.
 */
- (BOOL) hasPermission: (int) anOperationId;

/**
 * Retorna la lista de puertas a las cuales tiene acceso
 */
- (COLLECTION) getDoors;

/**
 * carga en memoria las puertas del usuario
 */
- (void) initializeDoorsByUser;

/**
 * devuelve la puerte del usuario solicitada
 */
- (DOOR) getUserDoor: (int) aDoorId;

/**
 * Agrega en memoria la puerta asignada al usuario
 */
- (void) addDoorByUserToCollection: (int) aDoorId;

/**
 * Quita de memoria la puerta asignada al usuario
 */
- (void) removeDoorByUserToCollection: (int) aDoorId;

/**
 *	Devuelve TRUE si el usuario tiene acceso permitido a la puerta.
 */
- (BOOL) hasAccessToDoor: (DOOR) aDoor;

/**/
- (void) setRealPassword: (char *) aRealPassword;
- (char*) getRealPassword;

/**/
- (PROFILE) getProfile;

/**/
- (BOOL) isDallasKeyRequired;
- (BOOL) isPinRequired;

/**/
- (char *) getDallasKeyLoginName;

/**/
- (unsigned short) getDevListMask;

@end

#endif

