#ifndef EXTRACTION_CONTROLLER_H
#define EXTRACTION_CONTROLLER_H

#define EXTRACTION_CONTROLLER id

#include <Object.h>
#include "system/util/all.h"
#include "CimDefs.h"
//#include "Device.h"
#include "ExtractionWorkflow.h"

/**
 *	Es el controller para efectuar una extraccion / apertura de puerta
 *	Maneja adicionalmente la apertura de una puerta interna.
 */
@interface ExtractionController : Object
{
	EXTRACTION_WORKFLOW myExtractionWorkflow;
	EXTRACTION_WORKFLOW myInnerExtractionWorkflow;
    OTIMER myUpdateTimer;
    id myObserver;
/*	int myDoorLastState;
	int myOuterDoorLastState;
	OMUTEX myMutex;
	USER myUser1;
	USER myUser2;
 */   
}

/**/
- (void) initExtraction: (int) aDoorId; 
- (OpenDoorStateType) getDoorState: (int) aDoorId; 
- (void) setRemoveCash: (BOOL) aRemoveCash;
- (void) userLoginForDoorAccess: (char*) aUserName userPassword: (char*) aUserPassword;
- (void) startDoorAccess: (int) aDoorId;
- (void) onInformAlarm: (char*) anAlarmDsc /*timeLeft: (int) aTimeLeft isBlocking: (BOOL) anIsBlocking*/;
- (void) closeExtraction: (int) aDoorId;
- (void) cancelDoorAccess;
- (void) cancelTimeDelay: (int) aDoorId userName: (char*) aUserName userPassword: (char*) aUserPassword;
- (void) setObserver: (id) anObserver;
/*
- (void) setExtractionWorkflow: (id) anExtractionWorkflow;
- (void) setOuterDoorExtractionWorkflow: (id) anExtractionWorkflow;
- (void) onLoginUser: (USER) aUser;
- (void) validateCancelTime: (DOOR) aDoor user: (USER) aUser;
- (void) cancelTime;
- (void) removeLoggedUsers;
- (void) validateStartDoorAccess: (DOOR) aDoor;
- (EXTRACTION_WORKFLOW) getOuterDoorExtractionWorkflow;
- (BOOL) isIdle;
- (void) reset;
*/
@end

#endif
