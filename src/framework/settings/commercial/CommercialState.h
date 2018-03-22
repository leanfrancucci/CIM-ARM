#ifndef COMMERCIAL_STATE_H
#define COMMERCIAL_STATE_H

#define COMMERCIAL_STATE id

#include "Object.h"
#include "ctapp.h"
#include "openssl/dsa.h"

/**
 *	Define los estados comerciales del sistema.
 */


typedef enum {
	SYSTEM_NOT_DEFINED,  					//0
	SYSTEM_FACTORY_BLOCKED,				//1
	SYSTEM_TEST_PIMS,							//2
	SYSTEM_PRODUCTION_PIMS,				//3
	SYSTEM_BLOCKED_USE,						//4
	SYSTEM_TEST_STAND_ALONE,			//5
	SYSTEM_PRODUCTION_STAND_ALONE,//6
	SYSTEM_BLOCKED_COMERCIAL			//7
} CommercialStateType;

typedef enum {
	CommercialMode_NOT_DEFINED, 	//0
	CommercialMode_STAND_ALONE, 	//1
	CommercialMode_PIMS						//2
} CommercialMode;

typedef enum {
	RESULT_OK = 1,
	DUPLICATED_MAC,
	WRONG_USER_NAME,
	WRONG_PIMS_SIGNATURE,
	WRONG_CIM_SIGNATURE,
	WRONG_NEW_STATE,
	WRONG_CURRENT_STATE,
	WRONG_TRANSITION,
	UNKNOWN_EQ,
	WRONG_PIMS_ID,
	FORBIDDEN_STATE,
	RENEWAL_REJECTED,
	WRONG_AUTHORIZATION_ID,
	TOO_MANY_TEST_STATES_REQUESTED,
	INTERNAL_SERVER_ERROR,
	AUTHORIZATION_ALREADY_CONFIRMED,
	AUTHORIZATIONS_NOT_FOUND,
	CIM_PUBLIC_KEY_ERROR,
	CIM_PRIVATE_KEY_ERROR,
	REMOTE_PUBLIC_KEY_ERROR,
	MODULE_NOT_AUTHORIZED,
	MODULE_ONLINE_MODE_NOT_AUTHORIZED,
	SIGN_GENERATION_ERROR = 30,
	ERROR_IN_SIGN_VERIFICATION,
	CONFIRMATION_SIGN_GENERATION_ERROR,
	REMOTE_CONFIRMATION_OK,
	REMOTE_CONFIRMATION_ERROR,
	NEW_RENEWAL_GENERATED
} CommercialStateChangeResult;
/*
#define RESULT_OK 1;
#define WRONG_PIMS_SIGNATURE 4
#define WRONG_CIM_SIGNATURE 5
#define WRONG_NEW_STATE 6
#define WRONG_CURRENT_STATE 7
#define WRONG_TRANSITION 8
#define UNKNOWN_EQ 9
#define WRONG_PIMS_ID 10
#define FORBIDDEN_STATE 11
#define RENEWAL_REJECTED 12
#define WRONG_AUTHORIZATION_ID 13
#define TOO_MANY_TEST_STATES_REQUESTED 14
#define INTERNAL_SERVER_ERROR 15
#define AUTHORIZATION_ALREADY_CONFIRMED 16

#define SIGN_GENERATION_ERROR 30
#define ERROR_IN_SIGN_VERIFICATION 31
#define CONFIRMATION_SIGN_GENERATION_ERROR 32
*/
/**
 * Clase  
 */

@interface CommercialState:  Object
{
	int myCommercialStateId;
	CommercialStateType myState;
	CommercialStateType myNextState;
	CommercialStateType myOldState;
	CommercialMode myCommercialMode;
	int myRemoteUnitsQty;
	int myHoursQty;
	datetime_t myLastTestTimestamp;
	char mySignature[200];
	char myEncodedRemoteSignature[200];
	unsigned char myRemoteSignature[50];
	int myRemoteSignatureLen;
	datetime_t myExpireDateTime;
  unsigned long myAuthorizationId;
	char myPimsId[20];
	datetime_t myRequestDateTime;
	BOOL isActive;
	unsigned long myElapsedTime;
	int myRequestResult;
	int myConfirmationResult;
	datetime_t myStartDateTime;
	BOOL myRenewalRejected;
	BOOL signatureCorrect;
}

/**
 * 
 */
- initialize;
				
/**
 * Setea los valores correspondientes al estado comercial del sistema
 */
- (void) setCommercialStateId: (int) aCommercialStateId;
- (void) setCommState: (CommercialStateType) aState;
- (void) setNextCommState: (CommercialStateType) aState; 
- (void) setOldState: (CommercialStateType) aState;
- (void) setRemoteUnitsQty: (int) aValue;
- (void) setHoursQty: (int) aValue;
- (void) setLastTestTimestamp: (datetime_t) aValue;
- (void) setCommercialMode: (CommercialMode) aValue;
- (void) setExpireDateTime: (datetime_t) aValue;
- (void) setAuthorizationId: (unsigned long) aValue;
- (void) setRequestDateTime: (datetime_t) aValue;
- (void) setEncodedRemoteSignature: (char*) aValue;
- (void) setRemoteSignatureLen: (int) aValue;
- (void) setRemoteSignature: (unsigned char*) aRemoteSignature remoteSignatureLen: (int) aRemoteSignatureLen;
- (void) setActive: (BOOL) aValue;
- (void) setElapsedTime: (unsigned long) aValue;
- (void) setRequestResult: (int) aValue;
- (void) setConfirmationResult: (int) aValue;
- (void) setStartDateTime: (datetime_t) aValue;
- (void) setRenewalRejected: (BOOL) aValue;


/**
 * Devuelve los valores correspondientes al estado comercial del sistema
 */

- (int) getCommercialStateId;	
- (CommercialStateType) getCommState;	
- (CommercialStateType) getNextCommState;
- (CommercialStateType) getOldState;
- (int) getRemoteUnitsQty;
- (int) getHoursQty;
- (int) getLastTestTimestamp;
- (CommercialMode) getCommercialMode;
- (datetime_t) getExpireDateTime;
- (unsigned long) getAuthorizationId;
- (char*) getPimsId;
- (datetime_t) getRequestDateTime;
- (unsigned char*) getRemoteSignature;
- (int) getRemoteSignatureLen;
- (BOOL) isActive;
- (unsigned long) getElapsedTime;
- (int) getRequestResult;
- (int) getConfirmationResult;
- (datetime_t) getStartDateTime;
- (BOOL) isRenewalRejected;

/**
 * Aplica los cambios realizados sobre la instancia correspondiente al estado comercial del 
 * sistema
 */	
- (void) applyChanges;

/**
 * Aplica los cambios realizados al tiempo transcurrido del estado.
 */
- (void) applyTimeElapsed;

/**
 * Retorna la firma en base a los datos seteados previamente.
 */
- (char*) getSignature: (DSA*) dsa;

/** 
 * Verifica que la firma sea correcta
 */
- (BOOL) verifyRemoteSignature: (DSA*) dsa;

/**
 * Devuelve la descripcion del estado dependiendo del idioma
 */
- (char*) getCommStateSTR: (CommercialStateType) aCommercialState;

/**
 * Devuelve el codigo ya generado
 */
- (char*) getSignatureCode;

/**
 * Devuelve el codigo de confirmacion ya generado
 */
- (char*) getConfirmationCode;

/**
 * Retorna TRUE en el caso en que se pueda ejectutar la supervision porque la autorizacion y los 
 * datos actuales coinciden. FALSE en caso contrario.
 */
- (BOOL) _canExecutePimsSupervision;

/**
 *
 */
- (void) setSignatureVerification: (DSA*) dsa;

@end

#endif

