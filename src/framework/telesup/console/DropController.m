#include <stdio.h>
#include <stdlib.h>
#include "ExtractionController.h"
#include "log.h"
#include "UICimUtils.h"
#include "MessageHandler.h"
#include "AlarmThread.h"
#include "Audit.h"
#include "CimManager.h"
#include "CimExcepts.h"
#include "CimGeneralSettings.h"
#include "UserManager.h"
#include "AsyncMsgThread.h"


@implementation ExtractionController

static EXTRACTION_CONTROLLER singleInstance = NULL;


+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}

+ getInstance
{
    return [self new];
}

/**/
- initialize
{
	[super initialize];
	myExtractionWorkflow = NULL;
	myInnerExtractionWorkflow = NULL;
    myObserver = NULL;
/*	myUser1 = NULL;
	myUser2 = NULL;
	myDoorLastState = OpenDoorStateType_UNDEFINED;
	myOuterDoorLastState = OpenDoorStateType_UNDEFINED;
    */
	return self;
    
    
}   

- (void) setObserver: (id) anObserver
{
    myObserver = anObserver;
}    

/**/
- (void) initExtraction: (int) aDoorId
{
    id door = [[CimManager getInstance] getDoorById: aDoorId];       
    
    printf("00\n");
    if (door == NULL) THROW(CIM_CIM_CASH_INVALID_DOOR_EX);  

 
    printf("0\n");
	[[CimManager getInstance] setDoorTimes];
    printf("1\n");
	if (![door getOuterDoor]) {
		myExtractionWorkflow = [[CimManager getInstance] getExtractionWorkflowForDoor: door];
		[myExtractionWorkflow setInnerDoorWorkflow: NULL];
		[myExtractionWorkflow setGeneratedOuterDoorExtr: FALSE];
		[myExtractionWorkflow setHasOpened: FALSE];
	} else {
		myExtractionWorkflow = [[CimManager getInstance] getExtractionWorkflowForDoor: [door getOuterDoor]];
		myInnerExtractionWorkflow = [[CimManager getInstance] getExtractionWorkflowForDoor: door];
		[myInnerExtractionWorkflow setHasOpened: FALSE];
        [myExtractionWorkflow setInnerDoorWorkflow: myInnerExtractionWorkflow];
		[myExtractionWorkflow setGeneratedOuterDoorExtr: FALSE];
		[myExtractionWorkflow setHasOpened: FALSE];
	}
    printf("2\n");
	//doorAcceptors = [door getAcceptorSettingsList];

	//doLog(0, "doorAcceptors size = %d\n", [doorAcceptors size]);
    printf("3\n");
	// Controlo si puede abrir la puerta dado el Time Lock correspondiente
	if ([myExtractionWorkflow getCurrentState] == OpenDoorStateType_IDLE) {

		// Error: no puede abrir la puerta en este momento
		if (![door canOpenDoor]) {
            
            THROW(RESID_DOOR_TIME_LOCK_ACTIVE);  

		}
	}
	printf("4\n");
}

/**/
- (OpenDoorStateType) getDoorState: (int) aDoorId
{
    return [myExtractionWorkflow getCurrentState];
}


/**/
- (void) setRemoveCash: (BOOL) aRemoveCash
{
    if ([myExtractionWorkflow getInnerDoorWorkflow]) {

        // solo mando generar la extraccion de la puerta externa segun el seteo
        if ([[CimGeneralSettings getInstance] removeCashOuterDoor])
            [myExtractionWorkflow setGenerateExtraction: TRUE];
        else
            [myExtractionWorkflow setGenerateExtraction: FALSE];

        [[myExtractionWorkflow getInnerDoorWorkflow] setGenerateExtraction: aRemoveCash];
    } else {
        [myExtractionWorkflow setGenerateExtraction: aRemoveCash];
    }
    
    
}

/**/
- (void) userLoginForDoorAccess: (char*) aUserName userPassword: (char*) aUserPassword
{
    int userId;
    id user;
    COLLECTION dallasK = [Collection new];
    
    printf("userLoginForDoorAccess\n");
    
    [myExtractionWorkflow addObserver: myObserver];
    if ([myExtractionWorkflow getInnerDoorWorkflow]) {
        [[myExtractionWorkflow getInnerDoorWorkflow] setBagTrackingMode: BagTrackingMode_NONE];
	} else {
        [myExtractionWorkflow setBagTrackingMode: BagTrackingMode_NONE];
    }
    printf("userLoginForDoorAccess 2 \n");
    TRY
        userId = [[UserManager getInstance] validateUser: aUserName password: aUserPassword dallasKeys: dallasK];
        // analisis de expiracion de password
        user = [[UserManager getInstance] getUser: userId];
    CATCH
    
        [myExtractionWorkflow removeLoggedUsers];
        [myExtractionWorkflow setGenerateExtraction: FALSE];
        if ([myExtractionWorkflow getInnerDoorWorkflow])
            [[myExtractionWorkflow getInnerDoorWorkflow] setGenerateExtraction: FALSE];
        RETHROW();
    END_TRY

    printf("userLoginForDoorAccess 3\n");
    TRY
        //tengo que setear inicialmente que no genero Pin para que la primera puerta lo genere
        [user setWasPinGenerated: 0];
        [myExtractionWorkflow onLoginUser: user];
    CATCH
        [self showDefaultExceptionDialogWithExCode: ex_get_code()];
        [myExtractionWorkflow removeLoggedUsers];
        [myExtractionWorkflow setGenerateExtraction: FALSE];

        if ([myExtractionWorkflow getInnerDoorWorkflow])
            [[myExtractionWorkflow getInnerDoorWorkflow] setGenerateExtraction: FALSE];
        /* LANZAR ERROR*/
        RETHROW();
    END_TRY    
    
   printf("userLoginForDoorAccess 4\n"); 
}

- (void) startDoorAccess: (int) aDoorId
{
 //   [myExtractionWorkflow addObserver: self];
/*	myUpdateTimer = [OTimer new];
	[myUpdateTimer initTimer: PERIODIC period: 200 object: self callback: "updateTimerHandler"];
	[self updateTimerHandler];
	[myUpdateTimer start];*/
}    

/**/
- (void) closeExtraction: (int) aDoorId
{
    BOOL hasOpened = FALSE;
    long lastExtractionNumber = 0;
    
   // [myUpdateTimer stop];   
    
	// hago el manejo de bagTracking segun corresponda
	if (![myExtractionWorkflow getInnerDoorWorkflow]) {
		//doLog(0,"removeCash = %d    bagTrackingMode = %d    hasOpened = %d \n", removeCash, bagTrackingMode, [extractionWorkflow hasOpened]);
		hasOpened = [myExtractionWorkflow hasOpened];

		while ([[ExtractionManager getInstance] isGeneratingExtraction]) msleep(100);

		lastExtractionNumber = [myExtractionWorkflow getLastExtractionNumber];

		// resetea los valores en el extractionWorkflow
		[myExtractionWorkflow resetLastExtractionNumber];

	} else {
		//doLog(0,"removeCash = %d    bagTrackingMode = %d    hasOpened = %d \n", removeCash, bagTrackingMode, [[extractionWorkflow getInnerDoorWorkflow] hasOpened]);
		hasOpened = [[myExtractionWorkflow getInnerDoorWorkflow] hasOpened];

		while ([[ExtractionManager getInstance] isGeneratingExtraction]) msleep(100);

		lastExtractionNumber = [[myExtractionWorkflow getInnerDoorWorkflow] getLastExtractionNumber];

		// resetea los valores en el extractionWorkflow
		[[myExtractionWorkflow getInnerDoorWorkflow] resetLastExtractionNumber];
	}    
}

/**/
- (void) cancelDoorAccess
{
    
}

/**/
- (void) cancelTimeDelay: (int) aDoorId userName: (char*) aUserName userPassword: (char*) aUserPassword
{
	char buf[100];
    COLLECTION dallasK = [Collection new];
    int userId;
    id user;
/*
	if (aExtractionWorkflow == NULL) return;

	if ([aExtractionWorkflow getCurrentState] != OpenDoorStateType_TIME_DELAY) {
		[JMessageDialog askOKMessageFrom: aParent 
				withMessage: getResourceStringDef(RESID_NOT_TIME_DELAY_FOR_DOOR, "No existe un tiempo de apertura retrasado para esa puerta.")];
		return;
	}
*/
    TRY
        userId = [[UserManager getInstance] validateUser: aUserName password: aUserPassword dallasKeys: dallasK];
        // analisis de expiracion de password
        user = [[UserManager getInstance] getUser: userId];
    CATCH
    
        return;
        
    END_TRY
    

		// Si el usuario 1 o usuario 2 coinciden entonces le permito cancelar
		// la operation (previa pregunta a si esta seguro)
		if ([myExtractionWorkflow getDelayUser1] == user || [myExtractionWorkflow getDelayUser2] == user) {
				[myExtractionWorkflow cancelTimeDelay];
        } else {
            // lanza error
            printf("El Tiempo de apertura debe ser cancel. por el usu. que lo solicito.");
		}
	
}

/**/
- (void) updateTimerHandler
{
	char stateStr[30];
	char timeStr[30];
	char buffer[50];
	char format[20];
	unsigned long left;
	int currentState;
	BOOL errorClosingDoorOrder;
	BOOL showOpenExternalDoorMsg;


//	[myMutex lock];

	*stateStr = '\0';
/*	*timeStr = '\0';
	left = [myExtractionWorkflow getTimeLeft];

	errorClosingDoorOrder = FALSE;
	showOpenExternalDoorMsg = FALSE;
*/
	if (([myExtractionWorkflow getInnerDoorWorkflow]) && 
			([[myExtractionWorkflow getInnerDoorWorkflow] getCurrentState] != OpenDoorStateType_WAIT_OUTER_DOOR_OPEN) &&
			([[myExtractionWorkflow getInnerDoorWorkflow] getCurrentState] != OpenDoorStateType_IDLE)) {

				currentState = [[myExtractionWorkflow getInnerDoorWorkflow] getCurrentState];
			/*	if (myLastExtWorkflow != ExtWorkflowType_INNER)
					[self setCurrentDoor: [[myExtractionWorkflow getInnerDoorWorkflow] getDoor]];*/

//				myLastExtWorkflow = ExtWorkflowType_INNER;

				// control para saber si se cerro la puerta externa antes que la interna
				if ([myExtractionWorkflow getCurrentState] == OpenDoorStateType_IDLE)
					errorClosingDoorOrder = TRUE;

			/*	if ([myExtractionWorkflow getCurrentState] == OpenDoorStateType_WAIT_OPEN_DOOR) {
					showOpenExternalDoorMsg = TRUE;

					if ([self isDiferentDoor: [myExtractionWorkflow getDoor]])
						[self setCurrentDoor: [myExtractionWorkflow getDoor]];

				} else {
					if ([self isDiferentDoor: [[myExtractionWorkflow getInnerDoorWorkflow] getDoor]])
						[self setCurrentDoor: [[myExtractionWorkflow getInnerDoorWorkflow] getDoor]];
				}*/

	} else {
  			currentState = [myExtractionWorkflow getCurrentState];
				/*if (myLastExtWorkflow != ExtWorkflowType_NORMAL)
					[self setCurrentDoor: [myExtractionWorkflow getDoor]];

				myLastExtWorkflow = ExtWorkflowType_NORMAL;*/
	}

	switch (currentState) {

		case OpenDoorStateType_UNDEFINED: 
//			strcpy(stateStr, getResourceStringDef(RESID_UNDEFINED_UPPER, "INDEFINIDO"));
			break;

		case OpenDoorStateType_IDLE: 
			strcpy(stateStr, getResourceStringDef(RESID_IDLE, "Inactivo"));
            [self onInformAlarm: stateStr];
			break;

		case OpenDoorStateType_TIME_DELAY: 
			//strcpy(stateStr, getResourceStringDef(RESID_DOOR_DELAY, "Retardo de Puerta"));
			//left = [myExtractionWorkflow getTimePassed];
			//[self formatTimeLeft: left buffer: timeStr]; 
			break;

		case OpenDoorStateType_ACCESS_TIME: 
	//		strcpy(stateStr, getResourceStringDef(RESID_ACCESS_TIME, "Tiempo de Acceso")); 
	//		[self formatTimeLeft: left buffer: timeStr]; 
			break;

		case OpenDoorStateType_WAIT_OPEN_DOOR: 
            printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>ABRIR PUERTA!!!!!!!!!!!!!!!!!!!!!!! \n");
            strcpy(stateStr, getResourceStringDef(RESID_OPEN_DOOR, "Abrir Puerta"));  
            [self onInformAlarm: stateStr];
			break;

		case OpenDoorStateType_WAIT_CLOSE_DOOR: 
            /*
			if (myOpenDoorForCommercialChange) {
				strcpy(stateStr, getResourceStringDef(RESID_WAIT_PLEASE, "Espere por favor..."));
			} else {
				if ((!errorClosingDoorOrder) && (!showOpenExternalDoorMsg)) {
					strcpy(stateStr, getResourceStringDef(RESID_CLOSE_DOOR, "Cerrar Puerta"));
					[self formatTimeLeft: left buffer: buffer];
					formatResourceStringDef(timeStr, RESID_WARNING_IN, "Advertencia en %s", buffer);
				} else {
					if (!showOpenExternalDoorMsg) {
						strcpy(stateStr, getResourceStringDef(RESID_OPEN_DOOR_AGAIN, "Abrir Nuevamente"));
						strcpy(timeStr, getResourceStringDef(RESID_ERROR, "Error"));
					} else {
						strcpy(stateStr, getResourceStringDef(RESID_OPEN_DOOR, "Abrir Puerta"));  
						strcpy(timeStr, getResourceStringDef(RESID_NOW, "AHORA!"));
					}
				}
			}
            */
        break;

		case OpenDoorStateType_WAIT_CLOSE_DOOR_WARNING: 
            /*
			if (myOpenDoorForCommercialChange) {
				strcpy(stateStr, getResourceStringDef(RESID_WAIT_PLEASE, "Espere por favor..."));
			} else {
				if ((!errorClosingDoorOrder) && (!showOpenExternalDoorMsg)) {
					strcpy(stateStr, getResourceStringDef(RESID_CLOSE_DOOR, "Cerrar Puerta"));
					[self formatTimeLeft: left buffer: buffer]; 
					formatResourceStringDef(timeStr, RESID_ALARM_IN, "Alarma en %s", buffer);
				} else {
					if (!showOpenExternalDoorMsg) {
						strcpy(stateStr, getResourceStringDef(RESID_OPEN_DOOR_AGAIN, "Abrir Nuevamente"));
						strcpy(timeStr, getResourceStringDef(RESID_ERROR, "Error"));
					} else {
						strcpy(stateStr, getResourceStringDef(RESID_OPEN_DOOR, "Abrir Puerta"));  
						strcpy(timeStr, getResourceStringDef(RESID_NOW, "AHORA!"));
					}
				}
			}
            */
			break;

		case OpenDoorStateType_WAIT_CLOSE_DOOR_ERROR: 
			/*if (myOpenDoorForCommercialChange) {
				strcpy(stateStr, getResourceStringDef(RESID_WAIT_PLEASE, "Espere por favor..."));
			} else {
				if ((!errorClosingDoorOrder) && (!showOpenExternalDoorMsg)) {
					strcpy(stateStr, getResourceStringDef(RESID_CLOSE_DOOR, "Cerrar Puerta"));
					strcpy(timeStr, getResourceStringDef(RESID_ERROR, "Error"));
				} else {
					if (!showOpenExternalDoorMsg) {
						strcpy(stateStr, getResourceStringDef(RESID_OPEN_DOOR_AGAIN, "Abrir Nuevamente"));
						strcpy(timeStr, getResourceStringDef(RESID_ERROR, "Error"));
					} else {
						strcpy(stateStr, getResourceStringDef(RESID_OPEN_DOOR, "Abrir Puerta"));  
						strcpy(timeStr, getResourceStringDef(RESID_NOW, "AHORA!"));
					}
				}
			}
			*/
			break;

		case OpenDoorStateType_LOCK_AND_OPEN_DOOR: 
			//strcpy(stateStr, getResourceStringDef(RESID_DOOR_IS_OPEN, "Puerta abierta"));
			//strcpy(timeStr, getResourceStringDef(RESID_ERROR, "Error"));
			break;

		case OpenDoorStateType_WAIT_UNLOCK_WITH_OPEN_DOOR: 
			/*strcpy(stateStr, getResourceStringDef(RESID_UNLOCK_DOOR, "Destrabar Puerta"));
			strcpy(timeStr, getResourceStringDef(RESID_ERROR, "Error"));
			*/
			break;

		case OpenDoorStateType_WAIT_LOCK_DOOR: 
			/*strcpy(stateStr, getResourceStringDef(RESID_LOCK_DOOR, "Trabar Puerta"));
			if (left > 0) {
				[self formatTimeLeft: left buffer: buffer]; 
				formatResourceStringDef(timeStr, RESID_WARNING_IN, "Advertencia en %s", buffer);
			}
			*/
			break;

		case OpenDoorStateType_WAIT_LOCK_DOOR_ERROR: 
            /*
			strcpy(stateStr, getResourceStringDef(RESID_LOCK_DOOR, "Trabar Puerta"));
			if (left > 0) {
				[self formatTimeLeft: left buffer: buffer]; 
				formatResourceStringDef(timeStr, RESID_ALARM_IN, "Alarma en %s", buffer);
			}
			*/
			break;

		case OpenDoorStateType_OPEN_DOOR_VIOLATION: 
			//strcpy(stateStr, getResourceStringDef(RESID_SECURITY_VIOLATION, "Violacion de Seguridad"));
			break;

		case OpenDoorStateType_WAIT_OUTER_DOOR_OPEN: 
			//strcpy(stateStr, getResourceStringDef(RESID_WAIT_OUTER_DOOR_OPEN, "Wait Outer Door Open"));
			break;
	}

	// Texto centrado
	/*
	sprintf(format, "%%%ds", (20 - strlen(stateStr)) / 2);
	sprintf(buffer, format, " ");
	strcat(buffer, stateStr);
	[myLabelMessage setCaption: buffer];

	if (*timeStr == '\0') {
		strcpy(buffer, "                    ");
	} else {
		sprintf(format, "%%%ds", (20 - strlen(timeStr)) / 2);
		sprintf(buffer, format, " ");
		strcat(buffer, timeStr);
		// Completo el resto con " "
		if (strlen(buffer) < 20) {
			memset(&buffer[strlen(buffer)], ' ', 20 - strlen(buffer));
		}
		buffer[20] = '\0';

	}
	
	*/

	//[myMutex unLock];


	// si posee inner door y aun no se genero la extraccion 
	// hago el return porque el bag traking lo debe procesar la puerta interna
	/*if ([myExtractionWorkflow getInnerDoorWorkflow]) {
		if ([[myExtractionWorkflow getInnerDoorWorkflow] getLastExtractionNumber] == 0) return;
	}

	if ( (currentState == OpenDoorStateType_WAIT_CLOSE_DOOR && [myExtractionWorkflow getTimePassed] > 5000) ||
			 (currentState == OpenDoorStateType_WAIT_CLOSE_DOOR_WARNING) || 
			 (currentState == OpenDoorStateType_WAIT_CLOSE_DOOR_ERROR) ||
			 (currentState == OpenDoorStateType_WAIT_LOCK_DOOR) || 
			 (currentState == OpenDoorStateType_WAIT_LOCK_DOOR_ERROR) ) {
		[self exitFromForm];
		return;
	}
	*/
}

/**/
- (void) onInformAlarm: (char*) anAlarmDsc /*timeLeft: (int) aTimeLeft isBlocking: (BOOL) anIsBlocking*/
{
    [[AsyncMsgThread getInstance] addAsynMsg: anAlarmDsc];
}


/*- (void) informDoorAccessNotification: (EXTRACTION_WORKFLOW) anExtractionWorkflow alarmType: (int) anAlarmType 
	notification: (char*) aNotification secondsTimerAlarm: (int) aSecondsTimerAlarm countDown: (BOOL) aCountDown;*/


/**/
/*
- (BOOL) isIdle
{
	if ([myExtractionWorkflow getCurrentState] != OpenDoorStateType_IDLE) return FALSE;

	if (myOuterDoorExtractionWorkflow != NULL && 
		[myOuterDoorExtractionWorkflow getCurrentState] != OpenDoorStateType_IDLE) return FALSE;

	return TRUE;
}
*/
/**/
/*
- (void) reset
{
	[self removeLoggedUsers];

	if (myExtractionWorkflow) {
		[myExtractionWorkflow removeObserver: self];
		[[myExtractionWorkflow getDoor] setOperationController: NULL];
	}

	if (myOuterDoorExtractionWorkflow) {
		[myOuterDoorExtractionWorkflow removeObserver: self];
		[[myOuterDoorExtractionWorkflow getDoor] setOperationController: NULL];
	}

	myDoorLastState = OpenDoorStateType_UNDEFINED;	
	myOuterDoorLastState = OpenDoorStateType_UNDEFINED;
	myExtractionWorkflow = NULL;
	myOuterDoorExtractionWorkflow = NULL;

	[self removeAllObservers];
}
*/
/**/
/*
- (void) setExtractionWorkflow: (id) anExtractionWorkflow
{
	myExtractionWorkflow = anExtractionWorkflow;
	[myExtractionWorkflow addObserver: self];
}
*/

/**/
/*
- (EXTRACTION_WORKFLOW ) getOuterDoorExtractionWorkflow { return myOuterDoorExtractionWorkflow; }*/

/**/
/*
- (void) setOuterDoorExtractionWorkflow: (id) anExtractionWorkflow
{
	myOuterDoorExtractionWorkflow = anExtractionWorkflow;
	[myOuterDoorExtractionWorkflow addObserver: self];
}*/

/**/
/*
- (void) start
{
	LOG_DEBUG( LOG_TELESUP, "ExtractionController -> start");
	myMutex = [OMutex new];
	if (myOuterDoorExtractionWorkflow != NULL) {
		[myOuterDoorExtractionWorkflow setInnerDoorWorkflow: myExtractionWorkflow];
	}
}
*/
/**/
/*
- (void) finish
{
	LOG_DEBUG( LOG_TELESUP, "ExtractionController -> finish");
	[myMutex free];
	[myExtractionWorkflow removeObserver: self];
	if (myOuterDoorExtractionWorkflow) [myOuterDoorExtractionWorkflow removeObserver: self];
	[self removeAllObservers];
}
*/
/**/
/*
- (void) onLoginUser: (USER) aUser
{
	DOOR door;

	door = [myExtractionWorkflow getDoor];

	// Verifica si el usuario / usuarios estan habilitados para el acceso a la puerta

	TRY

		if (myUser1 == NULL) {
			[door checkDoorAccess: aUser];
			myUser1 = aUser;
		} else {
			[door checkDoorAccess: myUser1 user2: aUser];
			myUser2 = aUser;
		}

	CATCH

		[Audit auditEvent: aUser eventId: EVENT_WITHOUT_DOOR_ACCESS additional: [door getDoorName] 
			station: [door getDoorId] logRemoteSystem: FALSE];

		RETHROW();

	END_TRY

	// Esperar al segundo usuario
	if ([door getKeyCount] == 2 && myUser2 == NULL) return;

	// Notifica a los Workflows que ya se loguearon los usuarios
	if (myOuterDoorExtractionWorkflow != NULL) {

		[myOuterDoorExtractionWorkflow setUser1: myUser1];
		[myOuterDoorExtractionWorkflow setUser2: myUser2];
		[myExtractionWorkflow setUser1: myUser1];
		[myExtractionWorkflow setUser2: myUser2];

		[myOuterDoorExtractionWorkflow finishUsersLogin];

	} else {

		[myExtractionWorkflow setUser1: myUser1];
		[myExtractionWorkflow setUser2: myUser2];
		[myExtractionWorkflow finishUsersLogin];
	
	}
}
*/
/**/
/*
- (char *) formatTimeLeft: (unsigned long) aLeftTime buffer: (char *) aBuffer
{
	int left = aLeftTime / 1000;
	sprintf(aBuffer, "%d:%02d", left / 60, left % 60);
	return aBuffer;
}
*/
/**/
/*
- (void) onExtractionWorkflowStateChange: (EXTRACTION_WORKFLOW) anExtractionWorkflow
{
	char timeStr[30];
	unsigned long left ;
	volatile int entityType = Alarm_DOOR_UNDEFINED_STATE;
	char notificationDsc[100];
	int secondsCount = 0;
	volatile BOOL cDown = TRUE;

	[myMutex lock];

	TRY


		*notificationDsc = '\0';
		*timeStr = '\0';
		left = [anExtractionWorkflow getTimeLeft];
		secondsCount = [anExtractionWorkflow getPeriod];

		LOG_DEBUG(LOG_DEVICES, "Cambio el estado de la puerta %s", [[anExtractionWorkflow getDoor] getDoorName]);

		switch ([anExtractionWorkflow getCurrentState]) {
	
			case OpenDoorStateType_UNDEFINED: 
				strcpy(notificationDsc, getResourceStringDef(RESID_UNDEFINED_UPPER, "INDEFINIDO"));
				entityType = Alarm_DOOR_UNDEFINED_STATE;
				secondsCount = 0;
				break;
	
			case OpenDoorStateType_IDLE: 
				if ([anExtractionWorkflow isLoadOperation] && [anExtractionWorkflow hasOpenedDoor] && [[anExtractionWorkflow getDoor] hasDeviceType: DeviceType_VEND]) {			

					PASO_POR_ACA();
					strcpy(notificationDsc, getResourceStringDef(RESID_IDLE_WAITING_FOR_LOAD_INFO, "Inactivo. Esperando informacion de datos de carga."));
				}
				else 
					strcpy(notificationDsc, getResourceStringDef(RESID_IDLE, "Inactivo"));

				entityType = Alarm_DOOR_IDLE;
				secondsCount = 0;
*/
				/** @todo1: ver si conviene hacer eso asi !!!! Es retrucho ya que no se libera nada pero de alguna manera tengo 
						que desasociar el controller con la correspondiente puerta
						Ojo que el controller este puede ser utilizado por mas de una puerta en caso de puertas interna */
/*			
				[anExtractionWorkflow removeObserver: self];
				[[anExtractionWorkflow getDoor] setOperationController: NULL];
				
				break;
	
			case OpenDoorStateType_TIME_DELAY: 
				strcpy(notificationDsc, getResourceStringDef(RESID_DOOR_DELAY, "Retardo de Puerta"));
				cDown = FALSE;
				entityType = Alarm_DOOR_TIME_DELAY;
				break;
	
			case OpenDoorStateType_ACCESS_TIME: 
				strcpy(notificationDsc, getResourceStringDef(RESID_ACCESS_TIME, "Tiempo de Acceso")); 
				entityType = Alarm_DOOR_ACCESS_TIME;
                */
				/** @todo: esta bien que sea haga esto aca ??? */
				/*[self removeLoggedUsers];		
				break;
	
			case OpenDoorStateType_WAIT_OPEN_DOOR: 
				sprintf(notificationDsc, "%s %s ", getResourceStringDef(RESID_OPEN_DOOR, "Abrir Puerta"), getResourceStringDef(RESID_NOW, "AHORA!")); 
				entityType = Alarm_DOOR_WAIT_OPEN;
				break;
	
			case OpenDoorStateType_WAIT_CLOSE_DOOR: 
				if ([anExtractionWorkflow isLoadOperation] && [[anExtractionWorkflow getDoor] hasDeviceType: DeviceType_VEND]) // se abre la puerta para cargar las monedas
					sprintf(notificationDsc, "%s %s ", getResourceStringDef(RESID_CLOSE_DOOR_AND_LOAD, "Cargar dispenser y cerrar Puerta"), getResourceStringDef(RESID_WARNING_IN, "Advertencia en: "));
				else
					sprintf(notificationDsc, "%s %s ", getResourceStringDef(RESID_CLOSE_DOOR, "Cerrar Puerta."), getResourceStringDef(RESID_WARNING_IN, "Advertencia en: "));
				entityType = Alarm_DOOR_WAIT_CLOSE_DOOR;

				break;

			case OpenDoorStateType_WAIT_CLOSE_DOOR_WARNING: 
				if ([[anExtractionWorkflow getDoor] getFireAlarmTime] == 0) secondsCount = 0;

				sprintf(notificationDsc, "%s %s ", getResourceStringDef(RESID_CLOSE_DOOR, "Cerrar Puerta"), getResourceStringDef(RESID_ALARM_IN, "Alarma en: "));
				entityType = Alarm_DOOR_WAIT_CLOSE_DOOR_WARNING;

				break;
	
			case OpenDoorStateType_WAIT_CLOSE_DOOR_ERROR: 
				sprintf(notificationDsc, "%s %s", getResourceStringDef(RESID_CLOSE_DOOR, "Cerrar Puerta"), getResourceStringDef(RESID_ERROR, "Error"));
				entityType = Alarm_DOOR_WAIT_CLOSE_DOOR_ERROR;

				break;
	
			case OpenDoorStateType_LOCK_AND_OPEN_DOOR: 
				sprintf(notificationDsc, "%s %s", getResourceStringDef(RESID_DOOR_IS_OPEN, "Puerta abierta"), getResourceStringDef(RESID_ERROR, "Error"));
				entityType = Alarm_DOOR_LOCK_AND_OPEN_DOOR;
				break;
	
			case OpenDoorStateType_WAIT_UNLOCK_WITH_OPEN_DOOR: 
				sprintf(notificationDsc, "%s %s", getResourceStringDef(RESID_UNLOCK_DOOR, "Destrabar Puerta"), getResourceStringDef(RESID_ERROR, "Error"));
				entityType = Alarm_DOOR_WAIT_UNLOCK_WITH_OPEN_DOOR;
				secondsCount = 0;
				break;
	
			case OpenDoorStateType_WAIT_UNLOCK_ENABLE:
				strcpy(notificationDsc, getResourceStringDef(RESID_SWITCH_KEY, "Girar llave"));
				cDown = FALSE;
				entityType = Alarm_DOOR_WAIT_UNLOCK_ENABLE;
				break;
	
			case OpenDoorStateType_WAIT_LOCK_DOOR: 
	
				sprintf(notificationDsc, "%s %s", getResourceStringDef(RESID_LOCK_DOOR, "Trabar Puerta"), getResourceStringDef(RESID_WARNING_IN, "Advertencia en: "));
				entityType = Alarm_DOOR_WAIT_LOCK_DOOR;

				break;
	
			case OpenDoorStateType_WAIT_LOCK_DOOR_WARNING: 
				if ([[anExtractionWorkflow getDoor] getFireAlarmTime] == 0) secondsCount = 0;
				sprintf(notificationDsc, "%s %s", getResourceStringDef(RESID_LOCK_DOOR, "Trabar Puerta"), getResourceStringDef(RESID_ALARM_IN, "Alarma en: "));
	
				entityType = Alarm_DOOR_WAIT_LOCK_DOOR_WARNING;				
				break;

			case OpenDoorStateType_WAIT_LOCK_DOOR_ERROR: 
				sprintf(notificationDsc, "%s %s", getResourceStringDef(RESID_LOCK_DOOR, "Trabar puerta"), getResourceStringDef(RESID_ERROR, "Error"));
				entityType = Alarm_DOOR_WAIT_LOCK_DOOR_ERROR;
				secondsCount = 0;
				break;

	
			case OpenDoorStateType_OPEN_DOOR_VIOLATION: 
				strcpy(notificationDsc, getResourceStringDef(RESID_SECURITY_VIOLATION, "Violacion de Seguridad"));

				entityType = Alarm_DOOR_VIOLATION;
				secondsCount = 0;
				break;

			case OpenDoorStateType_WAIT_OUTER_DOOR_OPEN: 
				strcpy(notificationDsc, getResourceStringDef(RESID_WAIT_OUTER_DOOR_OPEN, "Wait Outer Door Open"));
				entityType = Alarm_WAIT_OUTER_DOOR_OPEN;
				secondsCount = 0;
				break;

	
		}
	
//		LOG_DEBUG(LOG_TELESUP, "Door State: %s, %s, %d", notificationDsc, timeStr, [anExtractionWorkflow getCurrentState]);
	
		[self informDoorAccessNotification: anExtractionWorkflow alarmType: entityType	
		notification: notificationDsc secondsTimerAlarm: secondsCount countDown: cDown];

	FINALLY

		[myMutex unLock];

	END_TRY

}
*/
/**/
/*
- (void) informDoorAccessNotification: (EXTRACTION_WORKFLOW) anExtractionWorkflow alarmType: (int) anAlarmType 
	notification: (char*) aNotification secondsTimerAlarm: (int) aSecondsTimerAlarm countDown: (BOOL) aCountDown
{
	char add[30];

	LOG_DEBUG(LOG_TELESUP, "Door %s State: %s", [[anExtractionWorkflow getDoor] getDoorName], aNotification);

	// Verifica el estado anterior de la puerta externa	 
	if (anExtractionWorkflow == myOuterDoorExtractionWorkflow) {

		if (myOuterDoorLastState == anAlarmType) return;
		myOuterDoorLastState = anAlarmType;

	// Verifica el estado anterior de la puerta interna o normal
	} else {

		if (myDoorLastState == anAlarmType) return;
		myDoorLastState = anAlarmType;
	}

	if ([anExtractionWorkflow isLoadOperation] && [anExtractionWorkflow hasOpenedDoor] && [[anExtractionWorkflow getDoor] hasDeviceType: DeviceType_VEND]) sprintf(add, "%s", "True");
	else sprintf(add, "%s", "False");

	[[AlarmThread getInstance] addAlarm: [[anExtractionWorkflow getDoor] getDoorId] entityType: AlarmEntityType_NOT_DEFINED alarmType: anAlarmType alarmDsc: aNotification secondsTimerAlarm: aSecondsTimerAlarm countDown: aCountDown additional: add];
}
*/
/**/
/*
- (void) validateCancelTime: (DOOR) aDoor user: (USER) aUser
{

	// Si tiene puerta externa valido contra esa ya que es la que
	// tiene corriendo el TimeDelay
  if (myOuterDoorExtractionWorkflow != NULL) {

    if (([myOuterDoorExtractionWorkflow getCurrentState] != OpenDoorStateType_TIME_DELAY) && 
			([myOuterDoorExtractionWorkflow getCurrentState] != OpenDoorStateType_WAIT_UNLOCK_ENABLE) )
		THROW(INCORRECT_STATE_TO_CANCEL_TIME_EX);

    // Si el usuario 1 o usuario 2 coinciden entonces le permito cancelar
    // la operation (previa pregunta a si esta seguro)
    if ([myOuterDoorExtractionWorkflow getUser1] != aUser &&
        [myOuterDoorExtractionWorkflow getUser2] != aUser) 
      THROW(INCORRECT_USER_FOR_TIME_CANCEL_EX);	

	} else {

    if ( ([myExtractionWorkflow getCurrentState] != OpenDoorStateType_TIME_DELAY) && 
        ([myExtractionWorkflow getCurrentState] != OpenDoorStateType_WAIT_UNLOCK_ENABLE) )
      THROW(INCORRECT_STATE_TO_CANCEL_TIME_EX);
  
    // Si el usuario 1 o usuario 2 coinciden entonces le permito cancelar
    // la operation (previa pregunta a si esta seguro)
    if ([myExtractionWorkflow getUser1] != aUser &&
        [myExtractionWorkflow getUser2] != aUser) 
      THROW(INCORRECT_USER_FOR_TIME_CANCEL_EX);	

  }
		
}
*/
/**/
/*
- (void) cancelTime
{
	// Si tiene una puerta externa, cancelo esta unicamente (internamente la externa
	// cancela la interna tambien)
	if (myOuterDoorExtractionWorkflow != NULL) {
		[myOuterDoorExtractionWorkflow cancelTime];
	} else {
		[myExtractionWorkflow cancelTime];
	}

	[self removeLoggedUsers];
}
*/
/**/
/*
- (void) removeLoggedUsers
{
	myUser1 = NULL;
	myUser2 = NULL;
}
*/

/**/
/*
- (void) validateStartDoorAccess: (DOOR) aDoor
{
	if (myOuterDoorExtractionWorkflow != NULL) {

		// Rechazo la puerta si esta en access time y es externa y en realidad esta efectuando
		// la apertura de una interna	
		if ([myOuterDoorExtractionWorkflow getCurrentState] == OpenDoorStateType_ACCESS_TIME &&
				[myExtractionWorkflow getDoor] != aDoor)
			THROW(OPEN_DOOR_STATE_ERROR_EX);

	}

}
*/
@end
