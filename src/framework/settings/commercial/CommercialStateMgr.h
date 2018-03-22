#ifndef COMMERCIAL_STATE_MGR_H
#define COMMERCIAL_STATE_MGR_H

#define COMMERCIAL_STATE_MGR id

#include "Object.h"
#include "ctapp.h"
#include "CommercialState.h"
#include "openssl/dsa.h"
#include "openssl/objects.h"
#include "openssl/x509.h"
#include "system/util/all.h"
#include "SettingsExcepts.h"
#include "Module.h"

/**
 * Clase  
 */
 
@interface CommercialStateMgr:  Object
{
	id myCurrentCommercialState;

	id myPendingCommercialStateChange;

	DSA* myLocaldsa;
	DSA* myLSdsa;

  COLLECTION myModules;

	BOOL myChangingState;
}

/**
 * 
 */

+ new;
+ getInstance;
- initialize;

/**
 * Retorna el estado comercial actual. 
 */
- (id) getCurrentCommercialState;

/** 
 * Realiza el cambio de estado, en el caso correspondiente verifica la firma remota retornando un error
 * si la misma no coincide con las claves del servidor de licencias almacenado.
 */
- (void) doChangeCommercialState: (id) aCommercialState;

/** 
 * Retorna TRUE si la combinacion de cambios de estado requiere autorizacion del servidor de licencias.
 */
- (BOOL) needsAuthentication: (CommercialStateType) aNextCommState;

/**
 *  Setea un commercial state pendiente de verificar con la PIMS o el CMP.
 */
- (void) setPendingCommercialStateChange: (id) aPendingCommercialStateChange;
- (id) getPendingCommercialStateChange;

/**
 * Remueve el commercial state pendiente.
 */
- (void) removePendingCommercialStateChange;

/**
 * Retorna la firma del estado pasado como parametro.
 */
- (char*) getCommercialStateSignature: (id) aCommercialState;

/**
 * Retorna si puede ejecutar la supervision a la PiMS.
 */
- (BOOL) canExecutePimsSupervision;

/**
 *
 */
- (void) generateReport: (id) aCommercialState;

/**
 *
 */
- (void) changeSystemStatus;

/**
 *
 */
- (BOOL) isChangingState;

/**
 *
 */
- (BOOL) canChangeState: (int) aNewState msg: (char*) aMsg;


/***** MODULES *****/

/**/
- (COLLECTION) getModules;

/**/
- (MODULE) getModuleByCode: (int) aModuleCode;

/**/
- (BOOL) verifyModuleSignature: (int) aModuleCode 
                              baseDateTime: (datetime_t) aBaseDateTime
                              expireDateTime: (datetime_t) anExpireDateTime
                              hoursQty: (int) anHoursQty
															online: (BOOL) isOnline
															enable: (BOOL) isEnable
															authorizationId: (int) anAuthorizationId
                              encodeRemoteSignature: (char*) anEncodeRemoteSignature;


/**/
- (void) applyModuleLicence: (int) aModuleCode 
                              baseDateTime: (datetime_t) aBaseDateTime
                              expireDateTime: (datetime_t) anExpireDateTime
                              hoursQty: (int) anHoursQty
															online: (BOOL) isOnline
															enable: (BOOL) isEnable
															authorizationId: (int) anAuthorizationId
                              encodeRemoteSignature: (char*) anEncodeRemoteSignature; 

/**/
- (char*) getModuleApplySignature: (int) aModuleCode 
                              baseDateTime: (datetime_t) aBaseDateTime
                              expireDateTime: (datetime_t) anExpireDateTime
                              hoursQty: (int) anHoursQty
															online: (BOOL) isOnline
															enable: (BOOL) isEnable
															authorizationId: (int) anAuthorizationId
                              signatureBuffer: (char*) aSignatureBuffer; 


/**/
- (void) disableModule: (int) aModuleCode;

/**/
- (void) forceDisable: (int) aModuleCode expireDateTime: (datetime_t) anExpireDateTime;

/**/
- (BOOL) hasExpiredModules;

/**/
- (COLLECTION) getExpiredModules;

/**/
- (char*) getExpiredModulesStr: (char*) anExpireModulesStr;

/**/
- (BOOL) canExecuteModule: (int) aModuleCode;
- (BOOL) canExecuteModule: (int) aModuleCode executionMode: (int) anExecutionMode;

/**/
- (void) updateModulesTimeElapsed: (unsigned long) anElapsedTime;

/**/
- (void) updateModulesState: (int) anOldState currentState: (int) aCurrentState;

@end

#endif

