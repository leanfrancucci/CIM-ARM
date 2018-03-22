#include "CommercialState.h"
#include "Persistence.h"
#include "util.h"
#include "CimGeneralSettings.h"
#include "SystemTime.h"
#include "openssl/sha.h"
#include "openssl/objects.h"
#include "openssl/x509.h"
#include "StringTokenizer.h"
#include "math.h"
#include "TelesupervisionManager.h"
#include "MessageHandler.h"
#include "UserManager.h"
#include "TelesupDefs.h"
#include "SettingsExcepts.h"
#include "Audit.h"
#include "CommercialUtils.h"
#include "CommercialStateDAO.h"

@implementation CommercialState


/*Retorna la info del cambio de estado para armar el hash*/
- (unsigned char*) getStateChangeData: (unsigned char*) data isConfirmation: (BOOL) isConfirmation;

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myRequestDateTime = [SystemTime getGMTTime];
	myState = 0;
	myNextState = 0;
	myOldState = 0;
	myHoursQty = 0;
	myExpireDateTime = truncDateTime([SystemTime getGMTTime]);
	myStartDateTime = truncDateTime([SystemTime getLocalTime]);
	myRemoteUnitsQty = 0;
	*mySignature = 0;
	*myEncodedRemoteSignature = 0;
	memset(myRemoteSignature, 0, 50);
	myRemoteSignatureLen = 0;
	isActive = TRUE;
	myElapsedTime = 0;
	myRequestResult = 0;
  myConfirmationResult = 0;
	myRenewalRejected = FALSE;
	signatureCorrect = FALSE;
	return self;
}

/**/
- (void) setCommercialStateId: (int) aCommercialStateId { myCommercialStateId = aCommercialStateId; }
- (void) setCommState: (CommercialStateType) aState { myState = aState; }
- (void) setNextCommState: (CommercialStateType) aState { myNextState = aState; }
- (void) setOldState: (CommercialStateType) aState { myOldState = aState; }
- (void) setRemoteUnitsQty: (int) aValue { myRemoteUnitsQty = aValue; }
- (void) setHoursQty: (int) aValue { myHoursQty = aValue; }
- (void) setLastTestTimestamp: (datetime_t) aValue { myLastTestTimestamp = aValue; }
- (void) setCommercialMode: (CommercialMode) aValue { myCommercialMode = aValue; }
- (void) setExpireDateTime: (datetime_t) aValue { myExpireDateTime = aValue; }
- (void) setAuthorizationId: (unsigned long) aValue { myAuthorizationId = aValue; }
- (void) setRequestDateTime: (datetime_t) aValue { myRequestDateTime = aValue; }
- (void) setActive: (BOOL) aValue { isActive = aValue; }
- (void) setEncodedRemoteSignature: (char*) aValue { stringcpy(myEncodedRemoteSignature, aValue); };
- (void) setRemoteSignatureLen: (int) aValue { myRemoteSignatureLen = aValue; }
- (void) setRemoteSignature: (unsigned char*) aRemoteSignature remoteSignatureLen: (int) aRemoteSignatureLen 
{ 
	memcpy(myRemoteSignature, aRemoteSignature, aRemoteSignatureLen); 
}
- (void) setElapsedTime: (unsigned long) aValue { myElapsedTime = aValue; }
- (void) setRequestResult: (int) aValue { myRequestResult = aValue; }
- (void) setConfirmationResult: (int) aValue { myConfirmationResult = aValue; }
- (void) setStartDateTime: (datetime_t) aValue { myStartDateTime = aValue; }
- (void) setRenewalRejected: (BOOL) aValue { myRenewalRejected = aValue; }

/**/
- (int) getCommercialStateId { return myCommercialStateId; }
- (CommercialStateType) getCommState { return myState; }
- (CommercialStateType) getNextCommState { return myNextState; }
- (CommercialStateType) getOldState { return myOldState; }
- (int) getRemoteUnitsQty { return myRemoteUnitsQty; }
- (int) getHoursQty { return myHoursQty; }
- (int) getLastTestTimestamp { return myLastTestTimestamp; }
- (CommercialMode) getCommercialMode { return myCommercialMode; }
- (datetime_t) getExpireDateTime { return myExpireDateTime; }
- (unsigned long) getAuthorizationId { return myAuthorizationId; }
- (char*) getPimsId { return myPimsId; }
- (datetime_t) getRequestDateTime { return myRequestDateTime; }
- (int) getRemoteSignatureLen { return myRemoteSignatureLen; }
- (unsigned char*) getRemoteSignature { return myRemoteSignature; }
- (BOOL) isActive { return isActive; }
- (unsigned long) getElapsedTime { return myElapsedTime; }
- (int) getRequestResult { return myRequestResult; }
- (int) getConfirmationResult { return myConfirmationResult; }
- (datetime_t) getStartDateTime { return myStartDateTime; }
- (BOOL) isRenewalRejected { return myRenewalRejected; }


/**/
- (void) applyChanges
{
	id commercialStateDAO = [[Persistence getInstance] getCommercialStateDAO];

	[commercialStateDAO store: self];
}

/**/
- (void) applyTimeElapsed
{
	id commercialStateDAO = [[Persistence getInstance] getCommercialStateDAO];

	[commercialStateDAO storeCommercialStateElapsedTime: self];
}

/**/
- (void) generateSignature: (DSA*) dsa
{
	unsigned char data[200];

	[self getStateChangeData: data isConfirmation: FALSE];

//	doLog(0,"generateSignature\n");
//	doLog(0,"data = %s \n", data);

	[CommercialUtils	signAndEncodeData: dsa data: data signature: mySignature];
}

/**/
- (char*) getSignature: (DSA*) dsa
{
	[self generateSignature: dsa];
	return mySignature;
}

/**/
- (unsigned char*) getStateChangeData: (unsigned char*) data isConfirmation: (BOOL) isConfirmation
{
	char mac[50];
	char buf[] = "0000:00:00T00:00:00+00:00\0\0";
	char buf2[] = "0000:00:00T00:00:00+00:00\0\0";		
  char GMTDateTime[40];
	char expireDateTime[40];
	id telesup;
	char state[10];
	char nextState[10];

	sprintf(GMTDateTime, "%s", datetimeToISO8106(buf, myRequestDateTime));
	sprintf(expireDateTime, "%s", datetimeToISO8106(buf2, myExpireDateTime));

	telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];
	
	if (!telesup) stringcpy(myPimsId, "0");
	else stringcpy(myPimsId, [telesup getRemoteSystemId]);

	if (isConfirmation) {
		sprintf(state, "%d", myOldState);
		sprintf(nextState, "%d", myState);
	} else {
		sprintf(state, "%d", myState);
		sprintf(nextState, "%d", myNextState);
	}

//	doLog(0,"pimsId = %s\n", myPimsId);
	//doLog(0,"gmttime = %s\n", GMTDateTime);
//	doLog(0,"myState = %s\n", state);
///	doLog(0,"myNextState = %s\n", nextState);

	// IdPims
  // MacAddress
  // Fecha solicitud
  // Estado actual
  // Nuevo estado 

	sprintf(data, "%s%s%s%s%s", myPimsId, [[CimGeneralSettings getInstance] getMacAddress: mac], GMTDateTime, state, nextState);

/*
	for (i=0; i<strlen(data); ++i) 
		doLog(0,"%x ", data[i]);
*/
	return data;

}

/**/
- (BOOL) verifyRemoteSignature: (DSA*) dsa
{
	unsigned char data[200];
	char autIdStr[15];
	int result;

	[self getStateChangeData: data isConfirmation: FALSE];
	sprintf(autIdStr, "%ld", myAuthorizationId);
	strcat(data, autIdStr);
	strcat(data, "1");

//	doLog(0,"verifyRemoteSignature\n");
//	doLog(0,"data = %s\n", data);

	myRemoteSignatureLen = [CommercialUtils decodeSignature: myEncodedRemoteSignature signature: myRemoteSignature];

	result = [CommercialUtils verifySignature: dsa data: data signature: myRemoteSignature signatureLen: myRemoteSignatureLen];

	if (result == 0) { // error
		// auditoria error en verificacion de firma remota
		[Audit auditEventCurrentUser: Event_SIGNATURE_VERIFICATION_ERROR additional: "" station: 0 logRemoteSystem: FALSE]; 			
		myRequestResult = ERROR_IN_SIGN_VERIFICATION;
 		return FALSE;
	}

	return TRUE;	
}


/**/
- (char*) getCommStateSTR: (CommercialStateType) aCommercialState
{
	switch (aCommercialState) {
	
		case SYSTEM_FACTORY_BLOCKED:
			return getResourceStringDef(RESID_SYSTEM_FACTORY_BLOCKED, "BLOQUEO FABRICA");
			break;

		case SYSTEM_TEST_PIMS:
			return getResourceStringDef(RESID_SYSTEM_TEST_PIMS, "PRUEBA PIMS");
			break;

		case SYSTEM_PRODUCTION_PIMS:
			return getResourceStringDef(RESID_SYSTEM_PRODUCTION_PIMS, "PRODUCCION PIMS");
			break;

		case SYSTEM_BLOCKED_USE:
			return getResourceStringDef(RESID_SYSTEM_BLOCKED_USE, "BLOQUEO DE USO");
			break;

		case SYSTEM_TEST_STAND_ALONE:
			return getResourceStringDef(RESID_SYSTEM_TEST_STAND_ALONE, "PRUEBA ST ALONE");
			break;

		case SYSTEM_PRODUCTION_STAND_ALONE:
			return getResourceStringDef(RESID_SYSTEM_PRODUCTION_STAND_ALONE, "PRODUCC ST ALONE");
			break;

		case SYSTEM_BLOCKED_COMERCIAL:
			return getResourceStringDef(RESID_SYSTEM_BLOCKED_COMMERCIAL, "BLOQUEO COMERCIAL");
			break;

		default:
			return getResourceStringDef(RESID_SYSTEM_NOT_DEFINED, "NO DEFINIDO");
			break;
	}

}

/**/
- (char*) getSignatureCode
{
  return mySignature;
}

/**/
- (BOOL) _canExecutePimsSupervision
{
//	doLog(0,"\n---canExecutePimsSupervision---\n");

	return TRUE;

	if (myState == SYSTEM_BLOCKED_USE) return FALSE;
	if (myState == SYSTEM_TEST_STAND_ALONE) return FALSE;
	if (myState == SYSTEM_PRODUCTION_STAND_ALONE) return FALSE;

	return signatureCorrect;

}

/**/
- (void) setSignatureVerification: (DSA*) dsa
{
	unsigned char data[200];
	char autIdStr[15];
	int result;


	[self getStateChangeData: data isConfirmation: TRUE];
	sprintf(autIdStr, "%ld", myAuthorizationId);
	strcat(data, autIdStr);
	strcat(data, "1");

	result = [CommercialUtils verifySignature: dsa data: data signature: myRemoteSignature signatureLen: myRemoteSignatureLen];

	if (result == 0) { // error
		// auditoria no puede supervisar porque la firma no concuerda
		[Audit auditEvent: Event_CANNOT_SUPERVISE_SIGN_ERROR additional: "" station: 0 logRemoteSystem: FALSE];	
		signatureCorrect = FALSE;	
	}

	signatureCorrect = TRUE;
	
}

@end

