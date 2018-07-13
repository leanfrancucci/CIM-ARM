#include "ExtractionWorkflow.h"
#include "ExtractionManager.h"
#include "ExtractionDetail.h"
#include "ReportXMLConstructor.h"
#include "PrinterSpooler.h"
#include "CimExcepts.h"
#include "Profile.h"
#include "SafeBoxHAL.h"
#include "Buzzer.h"
#include "CimManager.h"
#include "Audit.h"
#include "UserManager.h"
#include "AmountSettings.h"
#include "Currency.h"
#include "ResourceStringDefs.h"
#include "CimGeneralSettings.h"
#include "dynamicPin.h"

//#define LOG(args...) doLog(0,args)

#define LOCK_DOOR_WARNING_TIME			10

@implementation ExtractionWorkflow

// Eventos de la maquina de estados ///////////////////////////////////////////////

/** Un usuario se autentico en el sistema (y eligio abrir puerta) */
#define USER_LOGIN_EVT			1

/** Se abrio la puerta */
#define OPEN_DOOR_EVT				2

/** Se cerro la puerta */
#define CLOSE_DOOR_EVT    	3

/** Expiro el timer */
#define TIMER_EXPIRED_EVT  	4

/** Cancelo el Time Delay */
#define CANCEL_TIME_DELAY_EVT	5

/** Evento de error */
#define UNLOCK_ERROR_EVT		6

/** Evento de error */
#define LOCK_DOOR_EVT				7

/** Evento de error */
#define UNLOCK_DOOR_EVT			8

/** Giro la llave para habilitar la puerta */
#define UNLOCK_ENABLE_EVT		9

/** Se abrio la puerta externa */
#define OUTER_DOOR_OPEN_EVT	10

/** Comenzo el proceso de apertura de la puerta externa */
#define OUTER_DOOR_START_EVT	11

/** Se cancelo el proceso de apertura de la puerta externa */
#define OUTER_DOOR_CANCEL_EVT	12

/** Se loguearon existosamente los usuarios */
#define USERS_LOGIN_EVT			13


// forward ////////////////////////////////////////////////////////////////////////
- (void) idleEntry;
- (void) idleExit;
- (BOOL) hasTimeDelay;
- (void) lockDoor;
- (void) unLockDoor;
- (void) timeDelayEntry;
- (void) timeDelayExit;
- (void) accessTimeEntry;
- (void) accessTimeExit;
- (void) waitOpenDoorEntry;
- (void) waitOpenDoorExit;
- (void) waitUnlockDoorEntry;
- (void) waitUnlockDoorExit;
- (void) waitCloseDoorEntry;
- (void) waitCloseDoorExit;
- (void) waitCloseDoorWarningEntry;
- (void) waitCloseDoorWarningExit;
- (void) openDoorViolationEntry;
- (void) openDoorViolationExit;
- (void) waitCloseDoorErrorEntry;
- (void) waitCloseDoorErrorExit;
- (void) auditAccessTimeExpired;
- (BOOL) isLoginComplete;
- (void) doorLockAndOpenEntry;
- (void) doorLockAndOpenExit;
- (void) waitLockDoorEntry;
- (void) waitLockDoorExit;
- (void) waitLockDoorErrorEntry;
- (void) waitLockDoorErrorExit;
- (BOOL) isDoorLock;
- (BOOL) isDoorOpen;
- (void) buzzerStart;
- (void) activateAlarm;
- (void) doorViolationAction;

// Implementacion en C de las funciones de la maquina de estado ///////////////////
void idleEntry(StateMachine *sm)  { [smGetCurrentContext(sm) idleEntry]; }
void idleExit(StateMachine *sm)  { [smGetCurrentContext(sm) idleExit]; }
BOOL hasTimeDelay(StateMachine *sm) { return [smGetCurrentContext(sm) hasTimeDelay];}
void lockDoor(StateMachine *sm) { [smGetCurrentContext(sm) lockDoor]; }
void unLockDoor(StateMachine *sm) { [smGetCurrentContext(sm) unLockDoor]; }

void timeDelayEntry(StateMachine *sm)  { [smGetCurrentContext(sm) timeDelayEntry]; }
void timeDelayExit(StateMachine *sm)  { [smGetCurrentContext(sm) timeDelayExit]; }

void accessTimeEntry(StateMachine *sm)  { [smGetCurrentContext(sm) accessTimeEntry]; }
void accessTimeExit(StateMachine *sm)  { [smGetCurrentContext(sm) accessTimeExit]; }

void waitCloseDoorEntry(StateMachine *sm)  { [smGetCurrentContext(sm) waitCloseDoorEntry]; }
void waitCloseDoorExit(StateMachine *sm)  { [smGetCurrentContext(sm) waitCloseDoorExit]; }

void waitCloseDoorWarningEntry(StateMachine *sm)  { [smGetCurrentContext(sm) waitCloseDoorWarningEntry]; }
void waitCloseDoorWarningExit(StateMachine *sm)  { [smGetCurrentContext(sm) waitCloseDoorWarningExit]; }

void waitOpenDoorEntry(StateMachine *sm)  { [smGetCurrentContext(sm) waitOpenDoorEntry]; }
void waitOpenDoorExit(StateMachine *sm)  { [smGetCurrentContext(sm) waitOpenDoorExit]; }

void waitUnlockDoorEntry(StateMachine *sm)  { [smGetCurrentContext(sm) waitUnlockDoorEntry]; }
void waitUnlockDoorExit(StateMachine *sm)  { [smGetCurrentContext(sm) waitUnlockDoorExit]; }

void openDoorViolationEntry(StateMachine *sm)  { [smGetCurrentContext(sm) openDoorViolationEntry]; }
void openDoorViolationExit(StateMachine *sm)  { [smGetCurrentContext(sm) openDoorViolationExit]; }

void doorLockAndOpenEntry(StateMachine *sm)  { [smGetCurrentContext(sm) doorLockAndOpenEntry]; }
void doorLockAndOpenExit(StateMachine *sm)  { [smGetCurrentContext(sm) doorLockAndOpenExit]; }

void waitLockDoorEntry(StateMachine *sm)  { [smGetCurrentContext(sm) waitLockDoorEntry]; }
void waitLockDoorExit(StateMachine *sm)  { [smGetCurrentContext(sm) waitLockDoorExit]; }

void waitLockDoorErrorEntry(StateMachine *sm)  { [smGetCurrentContext(sm) waitLockDoorErrorEntry]; }
void waitLockDoorErrorExit(StateMachine *sm)  { [smGetCurrentContext(sm) waitLockDoorErrorExit]; }

void waitCloseDoorErrorEntry(StateMachine *sm)  { [smGetCurrentContext(sm) waitCloseDoorErrorEntry]; }
void waitCloseDoorErrorExit(StateMachine *sm)  { [smGetCurrentContext(sm) waitCloseDoorErrorExit]; }
void auditAccessTimeExpired(StateMachine *sm)  { [smGetCurrentContext(sm) auditAccessTimeExpired]; }
void buzzerStart(StateMachine *sm)  { [smGetCurrentContext(sm) buzzerStart]; }
void activateAlarm(StateMachine *sm)  { [smGetCurrentContext(sm) activateAlarm]; }

BOOL isLoginComplete(StateMachine *sm)  { return [smGetCurrentContext(sm) isLoginComplete]; }
BOOL isLoginIncomplete(StateMachine *sm)  { return ![smGetCurrentContext(sm) isLoginComplete]; }
BOOL isDoorLock(StateMachine *sm)  { return [smGetCurrentContext(sm) isDoorLock]; }
BOOL isDoorOpen(StateMachine *sm)  { return [smGetCurrentContext(sm) isDoorOpen]; }

// Forward de los estados //////////////////////////////////////////////////////////////
#if 0
extern State IdleState;
extern State TimeDelayState;
extern State AccessTimeState;
extern State WaitOuterDoorOpenState;
extern State WaitOpenDoorState;
extern State WaitCloseDoorState;
extern State WaitCloseDoorWarningState;
extern State WaitCloseDoorErrorState;
extern State OpenDoorViolationState;
extern State WaitUnlockEnabledState;
extern State WaitUnlockDoorState;
extern State DoorLockAndOpenState;
extern State WaitLockDoorState;
extern State WaitLockDoorWarningState;
extern State WaitLockDoorErrorState;
extern State WaitUnlockDoorWithOpenDoorState;
#else
 static State IdleState;
 static State TimeDelayState;
 static State AccessTimeState;
 State WaitOuterDoorOpenState;
 static State WaitOpenDoorState;
 static State WaitCloseDoorState;
 static State WaitCloseDoorWarningState;
 static State WaitCloseDoorErrorState;
 static State OpenDoorViolationState;
 static State WaitUnlockEnabledState;
 static State WaitUnlockDoorState;
 static State DoorLockAndOpenState;
 static State WaitLockDoorState;
 static State WaitLockDoorWarningState;
 static State WaitLockDoorErrorState;
 static State WaitUnlockDoorWithOpenDoorState;
#endif

// Estados ///////////////////////////////////////////////////////////////////////////

/**
 *  Estado Idle. 
 *	No hace nada y unicamente pasa al estado siguiente cuando se loguea el usuario.
 *	Si se abre la puerta en este estado, paso al estado de Door Violation
 */
static Transition IdleStateTransitions[] =
{
	 {USER_LOGIN_EVT, isLoginIncomplete, NULL, &IdleState}
	,{USER_LOGIN_EVT, hasTimeDelay, NULL, &TimeDelayState}
	,{USER_LOGIN_EVT, NULL, NULL, &WaitUnlockDoorState}
	,{UNLOCK_ERROR_EVT, NULL, NULL, &IdleState}
	,{OPEN_DOOR_EVT,  isDoorLock, NULL, &DoorLockAndOpenState}
  ,{OPEN_DOOR_EVT,  NULL, NULL, &OpenDoorViolationState}
  ,{UNLOCK_DOOR_EVT,  NULL, NULL, &WaitLockDoorState}
	,{OUTER_DOOR_START_EVT, NULL, NULL, &WaitOuterDoorOpenState}
	,{OUTER_DOOR_OPEN_EVT, NULL, NULL, &WaitUnlockDoorState}
	,{SM_ANY, NULL, NULL, &IdleState}
};
static State IdleState = 
{
  idleEntry,					 // entry
  idleExit,                // exit
	IdleStateTransitions
};

/**
 *  Estado WaitOpenDoorState. 
 *	Estado para una puerta interna unicamente, debe esperar que se abra la puerta externa
 *	en primer lugar para luego continuar.
 */
 Transition WaitOuterDoorOpenStateTransitions[] =
{
	 {UNLOCK_ERROR_EVT, NULL, NULL, &IdleState}
	,{CANCEL_TIME_DELAY_EVT, NULL, NULL, &IdleState}
	,{OPEN_DOOR_EVT,  isDoorLock, NULL, &DoorLockAndOpenState}
  ,{OPEN_DOOR_EVT,  NULL, NULL, &OpenDoorViolationState}
	,{OUTER_DOOR_OPEN_EVT, NULL, NULL, &WaitUnlockDoorState}
	,{OUTER_DOOR_CANCEL_EVT, NULL, NULL, &IdleState}
	,{SM_ANY, NULL, NULL, &WaitOuterDoorOpenState}
};
 State WaitOuterDoorOpenState = 
{
  NULL,								 // entry
  NULL,                // exit
	WaitOuterDoorOpenStateTransitions
};

/**
 *  Estado TimeDelay
 *	Esta esperando que expire el timer de TimeDelay para continuar.
 *	Si el usuario de vuelve a loguear se cancela la operacion.
 */
static Transition TimeDelayStateTransitions[] =
{
	 {TIMER_EXPIRED_EVT, NULL, NULL, &AccessTimeState}
	,{USER_LOGIN_EVT, NULL, NULL, &IdleState}
	,{OPEN_DOOR_EVT,  isDoorLock, NULL, &DoorLockAndOpenState}
  ,{OPEN_DOOR_EVT,  NULL, NULL, &OpenDoorViolationState}
	,{CANCEL_TIME_DELAY_EVT, NULL, NULL, &IdleState}
  ,{UNLOCK_DOOR_EVT,  NULL, NULL, &OpenDoorViolationState}
	,{SM_ANY, NULL, NULL, &TimeDelayState}
};
static State TimeDelayState = 
{
  timeDelayEntry,			 // entry
  timeDelayExit,       // exit
	TimeDelayStateTransitions
};

/**
 *  Estado AccessTime
 *	Espera que el usuario se loguea nuevamente para continuar.
 *	Si expira el tiempo, vuelve al estado Idle.
 */
static Transition AccessTimeStateTransitions[] =
{
	 {TIMER_EXPIRED_EVT, NULL, auditAccessTimeExpired, &IdleState}	
	,{USER_LOGIN_EVT, isLoginComplete, NULL, &WaitUnlockDoorState}
	,{USER_LOGIN_EVT, NULL, NULL, &AccessTimeState}
	,{UNLOCK_ERROR_EVT, NULL, NULL, &IdleState}
	,{OPEN_DOOR_EVT,  isDoorLock, NULL, &DoorLockAndOpenState}
  ,{OPEN_DOOR_EVT,  NULL, NULL, &OpenDoorViolationState}
	,{SM_ANY, NULL, NULL, &AccessTimeState}
};
static State AccessTimeState = 
{
  accessTimeEntry,		 // entry
  accessTimeExit,      // exit
	AccessTimeStateTransitions
};

/**
 *  Estado WaitUnlockDoor
 *	Espera a que se desbloquee la cerradura.
 *	Si no la abre en cierto tiempo, se cancela el proceso.
 */
static Transition WaitUnlockDoorStateTransitions[] =
{
	 {TIMER_EXPIRED_EVT, NULL, lockDoor, &IdleState}	

// Esto dependera de la seguridad que se le quiera dar a la implementacion.
// La mas seguro es esperar que venga primero un unlock y luego el open door  
//  ,{OPEN_DOOR_EVT,  NULL, NULL, &DoorLockAndOpenState}
	,{OPEN_DOOR_EVT,  NULL, NULL, &WaitCloseDoorState}
	,{UNLOCK_ERROR_EVT, NULL, NULL, &IdleState}
	,{UNLOCK_DOOR_EVT, NULL, NULL, &WaitOpenDoorState}
	,{SM_ANY, NULL, NULL, &WaitUnlockDoorState}
};
static State WaitUnlockDoorState = 
{
  waitUnlockDoorEntry,	 // entry
  waitUnlockDoorExit,    // exit
	WaitUnlockDoorStateTransitions
};

/**
 *  Estado WaitOpenDoor
 *	Espera a que el usuario abra la puerta para generar la extraccion.
 *	Si no la abre en cierto tiempo, la cierra automaticamente y se cancela el proceso.
 */
static Transition WaitOpenDoorStateTransitions[] =
{
	 {TIMER_EXPIRED_EVT, NULL, NULL, &WaitLockDoorState}	
  ,{OPEN_DOOR_EVT,  NULL, NULL, &WaitCloseDoorState}
	,{UNLOCK_ERROR_EVT, NULL, NULL, &IdleState}
	,{LOCK_DOOR_EVT, NULL, NULL, &IdleState}
	,{SM_ANY, NULL, NULL, &WaitOpenDoorState}
};
static State WaitOpenDoorState = 
{
  waitOpenDoorEntry,	 // entry
  waitOpenDoorExit,    // exit
	WaitOpenDoorStateTransitions
};

/**
 *  Estado WaitCloseDoor
 *	El usuario debe cerrar la puerta, sino la cierra en un tiempo x, debe pasar
 *	al estado warning, si la cierra correctamente vuelve a pasar al estado Idle.
 */
static Transition WaitCloseDoorStateTransitions[] =
{
	 {USER_LOGIN_EVT, isLoginIncomplete, NULL, &WaitCloseDoorState}
	,{USER_LOGIN_EVT, NULL, NULL, &WaitUnlockDoorWithOpenDoorState}
	,{TIMER_EXPIRED_EVT, NULL, NULL, &WaitCloseDoorWarningState}	
  ,{CLOSE_DOOR_EVT,  NULL, lockDoor, &WaitLockDoorState}
	,{LOCK_DOOR_EVT,  NULL, NULL, &DoorLockAndOpenState}
	,{SM_ANY, NULL, NULL, &WaitCloseDoorState}
};
static State WaitCloseDoorState = 
{
  waitCloseDoorEntry,  							 // entry
  waitCloseDoorExit,                 // exit
	WaitCloseDoorStateTransitions
};

/**
 *  Estado WaitCloseDoorWarning
 *	Comienza a emitir el warning de cierre la puerta, si no la cierra en el tiempo
 *	correcto, pasa a estado Error
 */
static Transition WaitCloseDoorWarningStateTransitions[] =
{
	 {USER_LOGIN_EVT, isLoginIncomplete, NULL, &WaitCloseDoorWarningState}
	,{USER_LOGIN_EVT, NULL, NULL, &WaitUnlockDoorWithOpenDoorState}
	,{TIMER_EXPIRED_EVT, NULL, NULL, &WaitCloseDoorErrorState}	
  ,{CLOSE_DOOR_EVT,  NULL, lockDoor, &WaitLockDoorState}
	,{LOCK_DOOR_EVT,  NULL, NULL, &DoorLockAndOpenState}
	,{SM_ANY, NULL, NULL, &WaitCloseDoorWarningState}
};
static State WaitCloseDoorWarningState = 
{
  waitCloseDoorWarningEntry,				 // entry
  waitCloseDoorWarningExit,          // exit
	WaitCloseDoorWarningStateTransitions
};

/**
 *  Estado WaitCloseDoorError
 *	Error: el usuario no cerro la puerta.
 */
static Transition WaitCloseDoorErrorStateTransitions[] =
{
	 {USER_LOGIN_EVT, isLoginIncomplete, NULL, &WaitCloseDoorErrorState}
	,{USER_LOGIN_EVT, NULL, NULL, &WaitUnlockDoorWithOpenDoorState}
  ,{CLOSE_DOOR_EVT,  NULL, lockDoor, &WaitLockDoorState}
	,{LOCK_DOOR_EVT,  NULL, NULL, &DoorLockAndOpenState}
	,{SM_ANY, NULL, NULL, &WaitCloseDoorErrorState}
};
static State WaitCloseDoorErrorState = 
{
  waitCloseDoorErrorEntry,  				// entry
  waitCloseDoorErrorExit,						// exit
	WaitCloseDoorErrorStateTransitions
};

/**
 *  Estado WaitLockDoor
 *	El usuario debe trabar la cerradura, si no la cierra en un tiempo X debe comenzar
 *	a sonar el buzzer.
 */
static Transition WaitLockDoorStateTransitions[] =
{
	 {TIMER_EXPIRED_EVT, NULL, NULL, &WaitLockDoorErrorState}	
	,{LOCK_DOOR_EVT,  NULL, NULL, &IdleState}
	,{OPEN_DOOR_EVT,  NULL, NULL, &WaitCloseDoorWarningState}
	,{SM_ANY, NULL, NULL, &WaitLockDoorState}
};
static State WaitLockDoorState = 
{
  waitLockDoorEntry,  							// entry
  waitLockDoorExit,                 // exit
	WaitLockDoorStateTransitions
};

/**
 *  Estado WaitLockDoorError
 *	El usuario no trabo la cerradura pasado el tiempo, debe comenzar a sonar un buzzer y 
 *	cuando expira el tiempo activar la alarma
 */
static Transition WaitLockDoorErrorStateTransitions[] =
{
	 {TIMER_EXPIRED_EVT, NULL, activateAlarm, &WaitLockDoorErrorState}	
	,{LOCK_DOOR_EVT,  NULL, NULL, &IdleState}
	,{OPEN_DOOR_EVT,  NULL, NULL, &WaitCloseDoorWarningState}
	,{SM_ANY, NULL, NULL, &WaitLockDoorErrorState}
};
static State WaitLockDoorErrorState = 
{
  waitLockDoorErrorEntry,  							// entry
  waitLockDoorErrorExit,                 // exit
	WaitLockDoorErrorStateTransitions
};

/**
 *  Estado OpenDoorViolationState
 */
static Transition OpenDoorViolationStateTransitions[] =
{
	 {USER_LOGIN_EVT, isLoginIncomplete, NULL, &OpenDoorViolationState}
	,{USER_LOGIN_EVT, NULL, NULL, &WaitUnlockDoorWithOpenDoorState}
  ,{CLOSE_DOOR_EVT,  NULL, lockDoor, &IdleState}
	,{LOCK_DOOR_EVT,  NULL, NULL, &DoorLockAndOpenState}
	,{SM_ANY, NULL, NULL, &OpenDoorViolationState}
};
static State OpenDoorViolationState = 
{
  openDoorViolationEntry, 	 // entry
  openDoorViolationExit, 	   // exit
	OpenDoorViolationStateTransitions
};

/**
 *  Estado DoorLockAndOpenState
 */
static Transition DoorLockAndOpenStateTransitions[] =
{
   {CLOSE_DOOR_EVT,  NULL, NULL, &IdleState}
	,{USER_LOGIN_EVT, isLoginIncomplete, NULL, &DoorLockAndOpenState}
	,{USER_LOGIN_EVT, NULL, NULL, &WaitUnlockDoorWithOpenDoorState}
	,{UNLOCK_ERROR_EVT, NULL, NULL, &DoorLockAndOpenState}
	,{UNLOCK_DOOR_EVT,  NULL, NULL, &WaitCloseDoorState}
	,{SM_ANY, NULL, NULL, &DoorLockAndOpenState}
};
static State DoorLockAndOpenState = 
{
  doorLockAndOpenEntry, 	 // entry
  doorLockAndOpenExit, 	   // exit
	DoorLockAndOpenStateTransitions
};


/**
 *  Estado WaitUnlockDoor
 *	Espera a que se desbloquee la cerradura.
 *	Si no la abre en cierto tiempo, se cancela el proceso.
 */
static Transition WaitUnlockDoorWithOpenDoorStateTransitions[] =
{
	 {TIMER_EXPIRED_EVT, NULL, lockDoor, &DoorLockAndOpenState}	
	,{UNLOCK_ERROR_EVT, NULL, NULL, &DoorLockAndOpenState}
	,{UNLOCK_DOOR_EVT, NULL, NULL, &WaitCloseDoorState}
	,{SM_ANY, NULL, NULL, &WaitUnlockDoorWithOpenDoorState}
};
static State WaitUnlockDoorWithOpenDoorState = 
{
  waitUnlockDoorEntry,	 // entry
  waitUnlockDoorExit,    // exit
	WaitUnlockDoorWithOpenDoorStateTransitions
};

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myStateMachine = newStateMachine(&IdleState, self);
	myTimer = [OTimer new];
	myGenerateExtraction = FALSE;
	myHasUnlocked = FALSE;
	myForceTimeDelayOverride = FALSE;
	myDelayUser1 = NULL;
	myDelayUser2 = NULL;
	myLastExtractionNumber = 0;
	myHasOpened = FALSE;
	myBagTrackingMode = BagTrackingMode_NONE;
	myInnerDoorWorkflow = NULL;
	myIsGeneratedOuterDoorExtr = FALSE;
    
    myObserver = NULL;

	return self;
}

/**/
- (void) setInnerDoorWorkflow: (EXTRACTION_WORKFLOW) aValue
{
	int unlockEnable1 = 0;
	int unlockEnable2 = 0;
	int unlockEnable3 = 0;
	int unlockEnable4 = 0;
	int timeLock1 = 0;
	int timeLock2 = 0;
	int timeLock3 = 0;
	int timeLock4 = 0;

	myInnerDoorWorkflow = aValue;

	// para el caso de querer abrir una puerta interna debo ver si hay que resetear
	// los tiempos de key switch para ponerles los nuevos valores.
	if (myInnerDoorWorkflow) {
		if ([myDoor getTUnlockEnable] == 0) {
			unlockEnable1 = [[myInnerDoorWorkflow getDoor] getTUnlockEnable];
			unlockEnable2 = [[myInnerDoorWorkflow getDoor] getTUnlockEnable];
			unlockEnable3 = [[myInnerDoorWorkflow getDoor] getTUnlockEnable];
			unlockEnable4 = [[myInnerDoorWorkflow getDoor] getTUnlockEnable];
			[SafeBoxHAL setUnlockEnableTime: unlockEnable1 unlockEnable2: unlockEnable2 unlockEnable3: unlockEnable3 unlockEnable4: unlockEnable4];
		} else {
			if ([[myInnerDoorWorkflow getDoor] getTUnlockEnable] != 0) {
				unlockEnable1 = [[myInnerDoorWorkflow getDoor] getTUnlockEnable];
				unlockEnable2 = [[myInnerDoorWorkflow getDoor] getTUnlockEnable];
				unlockEnable3 = [[myInnerDoorWorkflow getDoor] getTUnlockEnable];
				unlockEnable4 = [[myInnerDoorWorkflow getDoor] getTUnlockEnable];
				[SafeBoxHAL setUnlockEnableTime: unlockEnable1 unlockEnable2: unlockEnable2 unlockEnable3: unlockEnable3 unlockEnable4: unlockEnable4];
			}
		}
	
		// Time locks
		timeLock1 = [[myInnerDoorWorkflow getDoor] getAutomaticLockTime];
		timeLock2 = [[myInnerDoorWorkflow getDoor] getAutomaticLockTime];
		timeLock3 = [[myInnerDoorWorkflow getDoor] getAutomaticLockTime];
		timeLock4 = [[myInnerDoorWorkflow getDoor] getAutomaticLockTime];
		[SafeBoxHAL setAutomaticLockTime: timeLock1 timeLock2: timeLock2 timeLock3: timeLock3 timeLock4: timeLock4];		

	}

}

/**/
- (EXTRACTION_WORKFLOW) getInnerDoorWorkflow
{
	return myInnerDoorWorkflow;
}

/**/
- (int) getDelayOpenTime
{
	if (myInnerDoorWorkflow != NULL) return [myInnerDoorWorkflow getDelayOpenTime];
	return [myDoor getDelayOpenTime];
}

/**/
- (int) getAccessTime
{
	if (myInnerDoorWorkflow  != NULL) return [myInnerDoorWorkflow getAccessTime];
	return [myDoor getAccessTime];
}

/**/
- (int) getAutomaticLockTime
{
	if (myInnerDoorWorkflow  != NULL) return [myInnerDoorWorkflow getAutomaticLockTime];
	return [myDoor getAutomaticLockTime];
}

/**/
- (int) getTUnlockEnable
{
	if (myInnerDoorWorkflow  != NULL) { // tiene puerta interna
		if ([myDoor getTUnlockEnable] == 0) 
			return [myInnerDoorWorkflow getTUnlockEnable];  // lo piso
		else
			if ([[myInnerDoorWorkflow getDoor] getTUnlockEnable] == 0) {
				return [myDoor getTUnlockEnable];
			} else {
				return [myInnerDoorWorkflow getTUnlockEnable]; // lo piso
			}
	} else { // No tiene puerta interna
		return [myDoor getTUnlockEnable];
	}
}

/**/
- (int) getMaxOpenTime
{
	if (myInnerDoorWorkflow  != NULL) return [myInnerDoorWorkflow getMaxOpenTime];
	return [myDoor getMaxOpenTime];
}

/**/
- (int) getFireAlarmTime
{
	if (myInnerDoorWorkflow  != NULL) return [myInnerDoorWorkflow getFireAlarmTime];
	return [myDoor getFireAlarmTime];
}

/**/
- (unsigned long) getTimeLeft
{
	return [myTimer getTimeLeft];
}

/**/
- (unsigned long) getTimePassed
{
	return [myTimer getTimePassed];
}

/**/
- (unsigned long) getPeriod
{
    printf("ExtractionWorkflow getPeriod\n");
        return [myTimer getTimeLeft];
}


/**/
- (void) setExtractionManager: (EXTRACTION_MANAGER) anExtractionManager { myExtractionManager = anExtractionManager; }

/**/
- (void) setGenerateExtraction: (BOOL) aValue 
{
	myGenerateExtraction = aValue; 
}

- (BOOL) getGenerateExtraction { return myGenerateExtraction; }

/**/
- (void) setDoor: (DOOR) aDoor { myDoor = aDoor; }
- (DOOR) getDoor { return myDoor; }


/**/
- (OpenDoorStateType) getCurrentState
{

	if (smGetCurrentState(myStateMachine) == &IdleState) return OpenDoorStateType_IDLE;
	if (smGetCurrentState(myStateMachine) == &TimeDelayState) return OpenDoorStateType_TIME_DELAY;
	if (smGetCurrentState(myStateMachine) == &AccessTimeState) return OpenDoorStateType_ACCESS_TIME;
	if (smGetCurrentState(myStateMachine) == &WaitOpenDoorState) return OpenDoorStateType_WAIT_OPEN_DOOR;
	if (smGetCurrentState(myStateMachine) == &WaitUnlockDoorState) return OpenDoorStateType_WAIT_OPEN_DOOR;
	if (smGetCurrentState(myStateMachine) == &WaitCloseDoorState) return OpenDoorStateType_WAIT_CLOSE_DOOR;
	if (smGetCurrentState(myStateMachine) == &WaitLockDoorState) return OpenDoorStateType_WAIT_LOCK_DOOR;
	if (smGetCurrentState(myStateMachine) == &WaitLockDoorErrorState) return OpenDoorStateType_WAIT_LOCK_DOOR_ERROR;
	if (smGetCurrentState(myStateMachine) == &WaitCloseDoorWarningState) return OpenDoorStateType_WAIT_CLOSE_DOOR_WARNING;
	if (smGetCurrentState(myStateMachine) == &WaitCloseDoorErrorState) return OpenDoorStateType_WAIT_CLOSE_DOOR_ERROR;
	if (smGetCurrentState(myStateMachine) == &OpenDoorViolationState) return OpenDoorStateType_OPEN_DOOR_VIOLATION;
	if (smGetCurrentState(myStateMachine) == &DoorLockAndOpenState) return OpenDoorStateType_LOCK_AND_OPEN_DOOR;
	if (smGetCurrentState(myStateMachine) == &WaitUnlockDoorWithOpenDoorState) return OpenDoorStateType_WAIT_UNLOCK_WITH_OPEN_DOOR;
	if (smGetCurrentState(myStateMachine) == &WaitOuterDoorOpenState) return OpenDoorStateType_WAIT_OUTER_DOOR_OPEN;
	
			    //************************* logcoment
	//doLog(0,"Error: estado indefinido\n");
    printf("Error: estado indefinido\n");
	return OpenDoorStateType_UNDEFINED;
}

/**/
- (void) startTimer: (unsigned long) aTime
{
    printf("ExtractionWorkflow -> startTimer, on %ld ms\n", aTime);
    [myTimer initTimer: ONE_SHOT period: aTime object: self callback: "timerExpired"];
	[myTimer start];
			    //************************* logcoment
	//doLog(0, "ExtractionWorkflow -> startTimer, on %ld ms\n", aTime);
}

/**/
- (void) stopTimer
{
	[myTimer stop];
			    //************************* logcoment
	//doLog(0,"ExtractionWorkflow -> stopTimer\n");
    printf("ExtractionWorkflow -> stopTimer\n");
}

/**/
- (void) onLoginUser: (USER) aUser
{
	id door = NULL;
	int keyCount;

			    //************************* logcoment
	//doLog(0, "ExtractionWorkflow -> onLoginUser\n");

	// verifico permiso de apertura. Si hay puerta interna verifico permiso sobre esta
	// independientemente de que la puerta externa tenga o no permiso
	if (myInnerDoorWorkflow) {
		door = [myInnerDoorWorkflow getDoor];
		if (![aUser hasAccessToDoor: door]) {
			[Audit auditEvent: myUser1 eventId: EVENT_WITHOUT_DOOR_ACCESS additional: [door getDoorName] station: [door getDoorId] logRemoteSystem: FALSE];
			THROW(CIM_USER_INVALID_DOOR_PERMISSION_EX);
		}
	} else {
		if (![aUser hasAccessToDoor: myDoor]) {
			[Audit auditEvent: myUser1 eventId: EVENT_WITHOUT_DOOR_ACCESS additional: [myDoor getDoorName] station: [myDoor getDoorId] logRemoteSystem: FALSE];
			THROW(CIM_USER_INVALID_DOOR_PERMISSION_EX);
		}
	}

	// Es el primer usuario que se loguea en la puerta
	if (myUser1 == NULL) {
		myUser1 = aUser;			
		myDelayUser1 = aUser;
		myDelayUser2 = NULL;
		if (myInnerDoorWorkflow != NULL)
			[myInnerDoorWorkflow setUser1: aUser];

		if ([myDoor getOuterDoor] == NULL) {
			executeStateMachine(myStateMachine, USER_LOGIN_EVT);
		}
		return;
	}

	// Es el segundo login, debo controlar que sea usuarios diferentes
	// y que estan permitidas las duplas de perfiles para abrir la puerta
	
	if (myInnerDoorWorkflow)
		keyCount = [[myInnerDoorWorkflow getDoor] getKeyCount];
	else
		keyCount = [myDoor getKeyCount];

	if (keyCount == 2 && myUser1 != NULL) {

		if (myUser1 == aUser) {
			[Audit auditEvent: myUser1 eventId: EVENT_WITHOUT_DOOR_ACCESS additional: [myDoor getDoorName] station: [myDoor getDoorId] logRemoteSystem: FALSE];
			THROW(CIM_CANNOT_BE_SAME_USER_EX);
		}

		if (![[UserManager getInstance] hasDualAccess: [myUser1 getUProfileId] profile2Id: [aUser getUProfileId]]) {
			[Audit auditEvent: myUser1 eventId: EVENT_WITHOUT_DOOR_ACCESS additional: [myDoor getDoorName] station: [myDoor getDoorId] logRemoteSystem: FALSE];
			THROW(DUAL_ACCESS_FORBIDDEN_EX);
		}

		myUser2 = aUser;
		myDelayUser2 = aUser;

		if (myInnerDoorWorkflow != NULL)
			[myInnerDoorWorkflow setUser2: aUser];

		if ([myDoor getOuterDoor] == NULL) {
			executeStateMachine(myStateMachine, USER_LOGIN_EVT);
		}
	}

}

/**/
- (void) cancelTimeDelay
{
			    //************************* logcoment
	//doLog(0,"ExtractionWorkflow -> onCancelTimeDelay\n");
	if ([self getCurrentState] != OpenDoorStateType_TIME_DELAY) THROW(CIM_CANNOT_CANCEL_TIME_DELAY_EX);
	myDelayUser1 = NULL;
	myDelayUser2 = NULL;
	executeStateMachine(myStateMachine, CANCEL_TIME_DELAY_EVT);

	// Le aviso a la puerta interna que se cancelo
	if (myInnerDoorWorkflow) {
		[myInnerDoorWorkflow cancelOuterDoor];
	}
}

/**/
- (void) cancelOuterDoor
{
    //************************* logcoment
	//doLog(0,"ExtractionWorkflow -> cancelOuterDoor\n");
	executeStateMachine(myStateMachine, OUTER_DOOR_CANCEL_EVT);
}

/**/
- (void) onOuterDoorOpen: (DOOR) aDoor
{
			    //************************* logcoment
//	doLog(0,"ExtractionWorkflow -> onOuterDoorOpen %d\n", [aDoor getDoorId]);
	executeStateMachine(myStateMachine, OUTER_DOOR_OPEN_EVT);
}

- (void) verifyPinGeneration:(USER) anUser
{
	scew_tree *tree;
	char newPassword[9];
	char newClosingCode[9];
	char newDuressPass[9];

	//Si ya genero el pin no lo vuelve a hacer
			    //************************* logcoment
	//doLog(0,"verifyPinGeneration!!!\n");
	if ( anUser == NULL )
		return;

	if ([anUser getWasPinGenerated]){
			    //************************* logcoment
//		doLog(0,"Pin already Generated! %d\n", [anUser getUserId]);
		return; 
	}

			    //************************* logcoment
//	doLog(0,"verifyPinGeneration User %d\n", [anUser getUserId]);
	if ([anUser getUsesDynamicPin]) {
		[anUser setPreviousPin: [anUser getRealPassword]];
		generateNewPin( [anUser getUserId], newClosingCode, [anUser getRealPassword], newPassword, newDuressPass );
			    //************************* logcoment
//		doLog(0,"Do Generate: %s %s\n", newClosingCode, newPassword);
		[SafeBoxHAL sbChangePassword: [anUser getLoginName] oldPassword: [anUser getRealPassword]	newPassword: newPassword newDuressPassword: newDuressPass];
		[anUser setClosingCode: newClosingCode];
		[anUser applyChanges];
		//SACAR EL NEW CLOSING CODE DESPUES!
		[Audit auditEvent: anUser eventId: Event_NEW_CODE_SEAL additional: "" station: 0 logRemoteSystem: FALSE];

		tree = [[ReportXMLConstructor getInstance] buildXML: anUser entityType: CLOSING_CODE_PRT isReprint: FALSE];
		[[PrinterSpooler getInstance] addPrintingJob: CLOSING_CODE_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree];
  		[ anUser setWasPinGenerated: 1];

	}
}


/**/
- (void) onDoorOpen: (DOOR) aDoor
{
	BOOL generate = FALSE;

			    //************************* logcoment
	//doLog(0,"ExtractionWorkflow -> onDoorOpen, generateExtraction = %d\n", myGenerateExtraction);
    printf("ExtractionWorkflow -> onDoorOpen, generateExtraction = %d\n", myGenerateExtraction);

	if (myInnerDoorWorkflow) {
		[[Buzzer getInstance] buzzerStop];
	}

	if (!myHasOpened) generate = TRUE;

	myHasOpened = TRUE;

	// Audito el evento
	[Audit auditEvent: myUser1 eventId: AUDIT_CIM_DOOR_OPEN additional: [myDoor getDoorName] station: [myDoor getDoorId] logRemoteSystem: FALSE];

	executeStateMachine(myStateMachine, OPEN_DOOR_EVT);

	if (myGenerateExtraction && generate ) {

		THROW_NULL(myExtractionManager);
		myDelayUser1 = NULL;
		myDelayUser2 = NULL;

		myLastExtractionNumber = [myExtractionManager generateExtraction: myDoor user1: myUser1 user2: myUser2 bagNumber: myBagBarCode bagTrackingMode: BagTrackingMode_NONE];

	}

	if (myInnerDoorWorkflow) {
		if (![myInnerDoorWorkflow isDoorOpen]) {
			[myInnerDoorWorkflow onOuterDoorOpen: aDoor];
		}
	}

	[self verifyPinGeneration:myUser1];
	[self verifyPinGeneration:myUser2];


	if (strstr([[[[CimManager getInstance] getCim] getBoxById: 1] getBoxModel], "FLEX")) {
		[[ExtractionManager getInstance] generateExtraction: myManualDoor user1: myUser1  user2: myUser2  bagNumber: "" bagTrackingMode: BagTrackingMode_NONE];
	}
}

/**/
- (void) generateExtraction: (DOOR) aDoor
{
		THROW_NULL(myExtractionManager);
		myIsGeneratedOuterDoorExtr = TRUE;
		myDelayUser1 = NULL;
		myDelayUser2 = NULL;
		myLastExtractionNumber = [myExtractionManager generateExtraction: aDoor user1: myUser1 user2: myUser2 bagNumber: myBagBarCode bagTrackingMode: BagTrackingMode_NONE];
}

/**/
- (BOOL) isGeneratedOuterDoorExtr
{
	return myIsGeneratedOuterDoorExtr;
}

/**/
- (void) setGeneratedOuterDoorExtr: (BOOL) aValue
{
	myIsGeneratedOuterDoorExtr = aValue;
}

/**/
- (void) onDoorClose: (DOOR) aDoor
{
			    //************************* logcoment
//	doLog(0,"ExtractionWorkflow -> onDoorClose doorId %d\n", [aDoor getDoorId]);
    printf("ExtractionWorkflow -> onDoorClose doorId %d\n", [aDoor getDoorId]);

	// control para saber si se cerro la puerta externa antes que la interna
	if (myInnerDoorWorkflow) {
		if ([myInnerDoorWorkflow isDoorOpen]) {
			    //************************* logcoment
			//doLog(0,""ExtractionWorkflow -> onDoorClose doorId %d\n", [aDoor getDoorId]);
            printf("ExtractionWorkflow -> onDoorClose doorId %d\n", [aDoor getDoorId]);
			[self buzzerStart];
		}
	}else{
		//[[Buzzer getInstance] buzzerStop];
	}


	// Audito el evento (si esta en IDLE no tiene sentido ya que esta bien que llegue este evento)
	if ([self getCurrentState] != OpenDoorStateType_IDLE)
		[Audit auditEvent: myUser1 eventId: AUDIT_CIM_DOOR_CLOSE additional: [myDoor getDoorName] station: [myDoor getDoorId] logRemoteSystem: FALSE];

	executeStateMachine(myStateMachine, CLOSE_DOOR_EVT);

}

/**/
- (void) onLocked: (DOOR) aDoor
{
			    //************************* logcoment
//	doLog(0,"ExtractionWorkflow -> onLocked doorId %d\n", [aDoor getDoorId]);
	executeStateMachine(myStateMachine, LOCK_DOOR_EVT);
}

/**/
- (void) onUnLocked: (DOOR) aDoor
{
    			    //************************* logcoment
//	doLog(0,"ExtractionWorkflow -> onUnLocked doorId %d\n", [aDoor getDoorId]);
    printf("ExtractionWorkflow -> onUnLocked doorId %d\n", [aDoor getDoorId]);
	executeStateMachine(myStateMachine, UNLOCK_DOOR_EVT);
}

/**/
- (void) timerExpired
{
			    //************************* logcoment
	printf("ExtractionWorkflow -> timerExpired\n");
	executeStateMachine(myStateMachine, TIMER_EXPIRED_EVT);
}

////////////////////////////////////// METODOS DE ACCION //////////////////////////////////////////


/**/
- (BOOL) isLoginComplete
{
	id door = NULL;

	if (myInnerDoorWorkflow)
		door = [myInnerDoorWorkflow getDoor];
	else
		door = myDoor;
	
	// Por las dudas contemplo esto, si es mayor a 2 o menor a 3 nunca puedo abrir la puerta
	if ([door getKeyCount] > 2) return FALSE;
	if ([door getKeyCount] == 0) return FALSE;

	// Si no hay usuario 1 directamente no esta completo el proceso de login
	if (myUser1 == NULL) return FALSE;

	// Si no hay usuario 2 y la puerta es Dual Key entonces aun no se completo el proceso de login
	if (myUser2 == NULL && [door getKeyCount] == 2) return FALSE;
	
	return TRUE;
}

/**/
- (void) removeLoggedUsers
{
	myUser1 = NULL;
	myUser2 = NULL;
	if (myInnerDoorWorkflow != NULL) {
		[myInnerDoorWorkflow setUser1: NULL];
		[myInnerDoorWorkflow setUser2: NULL];
	}
	myForceTimeDelayOverride = FALSE;
}

/**/
- (BOOL) isDoorLock
{
				    //************************* logcoment
    //doLog(0,"[myDoor getLockState] = %d\n", [myDoor getLockState]);
	return [myDoor getLockState] == LockState_LOCK;
}

/**/
- (BOOL) isDoorOpen
{
				    //************************* logcoment
    //doLog(0,"[myDoor getDoorState] = %d\n", [myDoor getDoorState]);
	return [myDoor getDoorState] == DoorState_OPEN;
}

/**/
- (void) idleEntry
{
			    //************************* logcoment
	//doLog(0,"ExtractionWorkflow -> idleEntry\n");
    printf("ExtractionWorkflow -> idleEntry\n");

	if (myInnerDoorWorkflow) {
		[myInnerDoorWorkflow cancelOuterDoor];
	}

	myHasUnlocked = FALSE;
	myGenerateExtraction = FALSE;
	[self removeLoggedUsers];
	myBagBarCode[0] = '\0';  
	[self notifyStateChange];
}

/**/
- (void) startOuterDoorOpen
{
			    //************************* logcoment
	//doLog(0,"ExtractionWorkflow -> startOuterDoorOpen\n");
    printf("ExtractionWorkflow -> startOuterDoorOpen\n");
 	executeStateMachine(myStateMachine, OUTER_DOOR_START_EVT);
}

/**/
- (void) idleExit
{
			    //************************* logcoment
	//doLog(0,"ExtractionWorkflow -> idleExit\n");
    printf("ExtractionWorkflow -> idleExit\n");
	if (myInnerDoorWorkflow != NULL) {
		[myInnerDoorWorkflow startOuterDoorOpen];
	}
}

/**/
- (BOOL) hasTimeDelay
{
	int keyCount;
			    //************************* logcoment
//	doLog(0,"ExtractionWorkflow -> hasTimeDelay = %d\n", [self getDelayOpenTime] != 0);
	
	// si se fuerza el time delay override por un pasaje de estado
	if (myForceTimeDelayOverride) {
		myForceTimeDelayOverride = FALSE;
		return FALSE;
	}

	if (myUser1 != NULL && [[[UserManager getInstance] getProfile: [myUser1 getUProfileId]] getTimeDelayOverride])
		return FALSE;


	// control para saber si se cerro la puerta externa antes que la interna
	if (myInnerDoorWorkflow) {
		if ([myInnerDoorWorkflow isDoorOpen]) {
			    //************************* logcoment
//			LOG("ExtractionWorkflow -> hasTimeDelay: No se muestra access time por cerrar puertas en orden incorrecto.\n");
			return FALSE;
		}
	}

	// Si alguno de los dos usuarios validados es Recaudador o Soporte
	// entonces el TimeDelay no se aplica
	if (myInnerDoorWorkflow)
		keyCount = [[myInnerDoorWorkflow getDoor] getKeyCount];
	else
		keyCount = [myDoor getKeyCount];

	if (keyCount == 2 && myUser1 != NULL && myUser2 != NULL) {
		
		if ([[[UserManager getInstance] getProfile: [myUser2 getUProfileId]] getTimeDelayOverride])
			return FALSE;

	}

	return [self getDelayOpenTime] != 0;
} 

/**/
- (void) buzzerStart
{
	[[Buzzer getInstance] buzzerStart];
}

/**/
- (void) lockDoor
{
			    //************************* logcoment
	//LOG("ExtractionWorkflow -> lockDoor\n");
}

/**/
- (void) unLockDoor
{
	int result = 0;
	char additional[21];
	char loginName1[30];
	char password1[30];

			    //************************* logcoment
//	LOG("ExtractionWorkflowTT -> unLockDoor - DoorId: %d\n", [myDoor getDoorId]);
    printf("ExtractionWorkflowTT -> unLockDoor - DoorId: %d\n", [myDoor getDoorId]);

#ifdef CHOW_YANKEE
	 if ( [myDoor getDoorId] == 2 ) {
		myHasUnlocked = TRUE;
  	[[Buzzer getInstance] buzzerBeep: 200];
	 	return;
	 }
#endif

	if (myUser1 == NULL) return;
	
	TRY
	
		if (myUser2 == NULL) {
			    //************************* logcoment
//			doLog(0,"ExtractionWorkflow unLockDoor con usuario %s\n", [myUser1 getLoginName]);
	
			[Audit auditEvent: myUser1 eventId: Event_DOOR_UNLOCK additional: [myDoor getDoorName] station: [myDoor getDoorId] logRemoteSystem: FALSE];
	
			if ([myUser1 isDallasKeyRequired]) {
				strcpy(loginName1, [myUser1 getDallasKeyLoginName]);
				strcpy(password1, [myUser1 getKey]);
			} else {
				strcpy(loginName1, [myUser1 getLoginName]);
				strcpy(password1, [myUser1 getRealPassword]);          
			}
	
            printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>> SafeBoxHAL unlock\n");
			result = [SafeBoxHAL unLock: [myDoor getLockHardwareId] personalId: loginName1 password: password1];

		} else {
	
			    //************************* logcoment
//			doLog(0,"ExtractionWorkflow unLockDoor con usuario %s y usuario %s\n", [myUser1 getLoginName], [myUser2 getLoginName]);
	
			[Audit auditEvent: myUser1 eventId: Event_DOOR_UNLOCK additional: [myDoor getDoorName] station: [myDoor getDoorId] logRemoteSystem: FALSE];
			result = [SafeBoxHAL unLock: [myDoor getLockHardwareId] personalId1: [myUser1 getLoginName] password1: [myUser1 getRealPassword]
				personalId2: [myUser2 getLoginName] password2: [myUser2 getRealPassword]];
		}
	
			    //************************* logcoment
		printf("unLock result = %d\n", result);
	
	CATCH
	
		ex_printfmt();
		sprintf(additional, "%d", ex_get_code());
		
		[Audit auditEvent: myUser1 eventId: Event_DOOR_UNLOCK_ERROR additional: [myDoor getDoorName] station: [myDoor getDoorId] logRemoteSystem: FALSE];
	
		ex_printfmt();
	
		executeStateMachine(myStateMachine, UNLOCK_ERROR_EVT);
	
		RETHROW();
	
	END_TRY
	
	myHasUnlocked = TRUE;
	[[Buzzer getInstance] buzzerBeep: 200];


}

/**/
- (void) timeDelayEntry
{
			    //************************* logcoment
//	LOG("ExtractionWorkflow -> timeDelayEntry\n");
    printf("ExtractionWorkflow -> timeDelayEntry\n");

	[self startTimer: [self getDelayOpenTime] * 1000];
    [self notifyStateChange];

	[Audit auditEvent: myUser1 eventId: Event_BEGIN_TIME_DELAY additional: [myDoor getDoorName] station: [myDoor getDoorId] logRemoteSystem: FALSE];
}

/**/
- (void) timeDelayExit
{
			    //************************* logcoment
	//LOG("ExtractionWorkflow -> timeDelayExit\n");
	[self stopTimer];

	[Audit auditEvent: myUser1 eventId: Event_END_TIME_DELAY additional: [myDoor getDoorName] station: [myDoor getDoorId] logRemoteSystem: FALSE];
}

/**/
- (void) accessTimeEntry
{
			    //************************* logcoment
//	LOG("ExtractionWorkflow -> accessTimeEntry, accessTime = %d\n", [self getAccessTime]);
    printf("ExtractionWorkflow -> accessTimeEntry\n");
	[self removeLoggedUsers];
	[self startTimer: [self getAccessTime] * 1000];
	[[Buzzer getInstance] buzzerStart];
    [self notifyStateChange];
    
}

/**/
- (void) accessTimeExit
{
			    //************************* logcoment
//	LOG("ExtractionWorkflow -> accessTimeExit\n");
	[self stopTimer];
	[[Buzzer getInstance] buzzerStop];
}

/**/
- (void) auditAccessTimeExpired
{
	[Audit auditEvent: myUser1 eventId: EVENT_ACCESS_TIME_FINISHED additional: [myDoor getDoorName] station: [myDoor getDoorId] logRemoteSystem: FALSE];
}

/**/
- (void) waitUnlockDoorEntry
{
			    //************************* logcoment
//	LOG("ExtractionWorkflow -> waitUnlockDoorEntry doorId = %d\n", [myDoor getDoorId]);
    printf("ExtractionWorkflow -> waitUnlockDoorEntry doorId = %d\n", [myDoor getDoorId]);
	[self unLockDoor];
	[self startTimer: ([self getAutomaticLockTime] + ([self getTUnlockEnable] * 60) ) * 1000];
    [self notifyStateChange];
}

/**/
- (void) waitUnlockDoorExit
{
			    //************************* logcoment
//	LOG("ExtractionWorkflow -> waitUnlockDoorEntry doorId = %d\n", [myDoor getDoorId]);
    printf("ExtractionWorkflow -> waitUnlockDoorEntry doorId = %d\n", [myDoor getDoorId]);
	[self stopTimer];
}

/**/
- (void) waitOpenDoorEntry
{
			    //************************* logcoment
//	LOG("ExtractionWorkflow -> waitOpenDoorEntry doorId = %d\n", [myDoor getDoorId]);
    printf("ExtractionWorkflow -> waitOpenDoorEntry doorId = %d\n", [myDoor getDoorId]);
	[self startTimer: [self getMaxOpenTime] * 1000];
    
    [self notifyStateChange];
}

/**/
- (void) waitOpenDoorExit
{
			    //************************* logcoment
//	LOG("ExtractionWorkflow -> waitOpenDoorExit doorId = %d\n", [myDoor getDoorId]);
    printf("ExtractionWorkflow -> waitOpenDoorExit doorId = %d\n", [myDoor getDoorId]);
	[self stopTimer];
}

/**/
- (void) waitCloseDoorEntry
{
			    //************************* logcoment
//	LOG("ExtractionWorkflow -> waitCloseDoorEntry doorId = %d\n", [myDoor getDoorId]);
    printf("ExtractionWorkflow -> waitCloseDoorEntry\n");
	[self startTimer: [self getMaxOpenTime] * 1000];
    
    [self notifyStateChange];
    
}

/**/
- (void) waitCloseDoorExit
{
			    //************************* logcoment
	printf("ExtractionWorkflow -> waitCloseDoorExit doorId = %d\n", [myDoor getDoorId]);
	[self stopTimer];
}

/**/
- (void) waitCloseDoorWarningEntry
{
			    //************************* logcoment
	printf("ExtractionWorkflow -> waitCloseDoorWarningEntry doorId = %d\n", [myDoor getDoorId]);
	[self startTimer: [self getFireAlarmTime] * 1000];
    
    [self notifyStateChange];
    
	[[Buzzer getInstance] buzzerStart];
}

/**/
- (void) waitCloseDoorWarningExit
{
			    //************************* logcoment
	printf("ExtractionWorkflow -> waitCloseDoorWarningExit doorId = %d\n", [myDoor getDoorId]);
	[self stopTimer];
	[[Buzzer getInstance] buzzerStop];
}

/**/
- (void) waitLockDoorEntry
{
	[self startTimer: LOCK_DOOR_WARNING_TIME * 1000];
			    //************************* logcoment
	printf("ExtractionWorkflow -> waitLockDoorEntry doorId = %d\n", [myDoor getDoorId]);
    
    [self notifyStateChange];
}

/**/
- (void) waitLockDoorExit
{
			    //************************* logcoment
//	LOG("ExtractionWorkflow -> waitLockDoorExit doorId = %d\n", [myDoor getDoorId]);
	[self stopTimer];
}

/**/
- (void) waitLockDoorErrorEntry
{
			    //************************* logcoment
	printf("ExtractionWorkflow -> waitLockDoorErrorEntry doorId = %d\n", [myDoor getDoorId]);
	[self startTimer: [self getFireAlarmTime] * 1000];
	[[Buzzer getInstance] buzzerStart];

	if (myInnerDoorWorkflow) {
		[myInnerDoorWorkflow cancelOuterDoor];
	}
	
	[self notifyStateChange];
}

/**/
- (void) waitLockDoorErrorExit
{
			    //************************* logcoment
//	LOG("ExtractionWorkflow -> waitLockDoorErrorExit doorId = %d\n", [myDoor getDoorId]);
	[[Buzzer getInstance] buzzerStop];
	[self stopTimer];
}

/**/
- (void) doorLockAndOpenEntry
{
			    //************************* logcoment
	printf("ExtractionWorkflow -> doorLockAndOpenEntry doorId = %d\n", [myDoor getDoorId]);
	[self removeLoggedUsers];

	[[Buzzer getInstance] buzzerStart];

	// Si no desbloqueo la puerta
	if (!myHasUnlocked) {
		[self doorViolationAction];
	}
	
	[self notifyStateChange];
}

/**/
- (void) doorLockAndOpenExit
{
			    //************************* logcoment
//	LOG("ExtractionWorkflow -> doorLockAndOpenExit doorId = %d\n", [myDoor getDoorId]);
	[[Buzzer getInstance] buzzerStop];
}

/**/
- (void) doorViolationAction
{	
  EXTRACTION extraction;
  COLLECTION cimCashs, detailsByCimCash, acceptorSettingsList, detailsByAcceptor;
  COLLECTION detailsByCurrency, currecies;
  CIM_CASH cimCash;
  int iCash, iAcceptor, iCurrency, iDetail;
  ACCEPTOR_SETTINGS acceptorSettings;
  char buf[50];
  char buf2[50];
  EXTRACTION_DETAIL extractionDetail;
  int totalDecimals = [[AmountSettings getInstance] getTotalRoundDecimalQty];
  CURRENCY currency;
  AUDIT audit;
  int resId = RESID_NOT_DEFINE_VAL;

			    //************************* logcoment
    printf("ExtractionWorkflow -> doorViolationAction\n");


			    //************************* logcoment
	printf("******************* ACTIVA LA ALARMA ************************\n");

	[[CimManager getInstance] activateSoundAlarm];

	audit = [[Audit new] initAuditWithCurrentUser: Event_DOOR_ACCESS_VIOLATION additional: [myDoor getDoorName] station: [myDoor getDoorId] logRemoteSystem: FALSE];
	
	// traigo el detalle a mostrar en la auditoria ***********************
	extraction = [[ExtractionManager getInstance] getCurrentExtraction: myDoor];
	// Obtengo la lista de cashs
	cimCashs = [extraction getCimCashs: NULL];	
	
  // Recorro la lista de cashs
	for (iCash = 0; iCash < [cimCashs size]; ++iCash) {
		
    cimCash = [cimCashs at: iCash];
		
		// Obtengo los depositos para el cash actual
		detailsByCimCash = [extraction getDetailsByCimCash: NULL cimCash: cimCash];
		// Obtengo la lista de Acceptors
		acceptorSettingsList = [extraction getAcceptorSettingsList: detailsByCimCash];

		// Recorro la lista de Acceptors
		for (iAcceptor = 0; iAcceptor < [acceptorSettingsList size]; ++iAcceptor) {
	    
      acceptorSettings = [acceptorSettingsList at: iAcceptor];
			// Obtengo la lista de detalles para el Acceptor en curso
			detailsByAcceptor = [extraction getDetailsByAcceptorSettings: detailsByCimCash acceptorSettings: acceptorSettings];
			// Obtengo la lista de monedas
			currecies = [extraction getCurrencies: detailsByAcceptor];

			// Recorro la lista de monedas
			for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {

				currency = [currecies at: iCurrency];
				detailsByCurrency = [extraction getDetailsByCurrency: detailsByAcceptor currency: currency];

        // validado  Event_DOOR_ACCESS_VIOLATION
        if ([cimCash getDepositType] == 1) {
          formatMoney(buf, "", [extraction getTotalAmount: detailsByCurrency], totalDecimals, 20);
          sprintf(buf2, "%s %s", [currency getCurrencyCode], buf);
          [audit logChangeAsString: RESID_CASH_VAL oldValue: "" newValue: buf2];
        } else {
		      // manual
  				for (iDetail = 0; iDetail < [detailsByCurrency size]; ++iDetail) {
  			
  					extractionDetail = [detailsByCurrency at: iDetail];
            switch ([extractionDetail getDepositValueType])
            {
                case DepositValueType_UNDEFINED: resId = RESID_NOT_DEFINE_VAL; break;
                case DepositValueType_VALIDATED_CASH: resId = RESID_CASH_VAL; break;
                case DepositValueType_MANUAL_CASH: resId = RESID_CASH_VAL; break;
                case DepositValueType_CHECK: resId = RESID_CHECK_VAL; break;
                case DepositValueType_BOND: resId = RESID_TICKET_VAL; break;
                case DepositValueType_CREDIT_CARD: resId = RESID_CUPONS_VAL; break;
                case DepositValueType_OTHER: resId = RESID_OTHER_VAL; break;
                case DepositValueType_BOOKMARK: resId = RESID_BOOKMARK_VAL; break;
            }  			  	
  			  	
            formatMoney(buf, "", [extractionDetail getTotalAmount], totalDecimals, 20);
            sprintf(buf2, "%s %s", [currency getCurrencyCode], buf);
            [audit logChangeAsString: resId oldValue: "" newValue: buf2];
  				}
        }
				[detailsByCurrency free];
			}
			[currecies free];
			[detailsByAcceptor free];
		}
		[acceptorSettingsList free];
		[detailsByCimCash free];
  }
  
	[cimCashs free];

  [audit saveAudit];
  [audit free];
}

/**/
- (void) openDoorViolationEntry
{
			    //************************* logcoment
    printf("ExtractionWorkflow -> openDoorViolationEntry doorId = %d\n", [myDoor getDoorId]);
	[[Buzzer getInstance] buzzerStart];
	[self doorViolationAction];

	if (myInnerDoorWorkflow) {
		[myInnerDoorWorkflow cancelOuterDoor];
	}
	
	[self notifyStateChange];
}

/**/
- (void) openDoorViolationExit
{
    //************************* logcoment

	printf("ExtractionWorkflow -> openDoorViolationExit doorId = %d\n", [myDoor getDoorId]);
	[[Buzzer getInstance] buzzerStop];
}

/**/
- (void) waitCloseDoorErrorEntry
{
			    //************************* logcoment
    printf("ExtractionWorkflow -> waitCloseDoorErrorEntry doorId = %d\n", [myDoor getDoorId]);
	[[Buzzer getInstance] buzzerStart];
	[self activateAlarm];

	if (myInnerDoorWorkflow) {
		[myInnerDoorWorkflow cancelOuterDoor];
	}
	
	[self notifyStateChange];
}

/**/
- (void) waitCloseDoorErrorExit
{
			    //************************* logcoment
//	LOG("ExtractionWorkflow -> waitCloseDoorErrorExit doorId = %d\n", [myDoor getDoorId]);
	[[Buzzer getInstance] buzzerStop];
}

/**/
- (STR) str
{
	int left = 0;
	char doorName[50];

	if ([self getCurrentState] == OpenDoorStateType_TIME_DELAY)
		left = [self getTimePassed] / 1000;

	strcpy(doorName, [myDoor str]);
	doorName[9] = 0;
  sprintf(myBuffer, "%-9s %3d:%02d", doorName, left / 60, left % 60);

	return myBuffer;
}

/**/
- (void) activateAlarm
{
	[[CimManager getInstance] activateAlarm];	
}

/**/
- (USER) getUser1
{
	return myUser1;
}

/**/
- (USER) getUser2
{
	return myUser2;
}

/**/
- (void) setUser1: (USER) aUser { myUser1 = aUser; }

/**/
- (void) setUser2: (USER) aUser { myUser2 = aUser; }

/**/
- (USER) getDelayUser1
{
	return myDelayUser1;
}

/**/
- (USER) getDelayUser2
{
	return myDelayUser2;
}

/**/
- (void) forceTimeDelayOverride: (BOOL) aValue 
{
	myForceTimeDelayOverride = aValue;
}

/**/
- (void) setBagBarCode: (char*) aValue
{
	stringcpy(myBagBarCode, aValue);
}

/**/
- (unsigned long) getLastExtractionNumber
{
	return myLastExtractionNumber;
}

/**/
- (BOOL) hasOpened { return myHasOpened; }
- (void) setHasOpened: (BOOL) aValue { myHasOpened = aValue; }

/**/
- (void) resetLastExtractionNumber
{
	myLastExtractionNumber = 0;
}

/**/
- (void) setBagTrackingMode: (int) aMode 
{
			    //************************* logcoment
//	doLog(0,"BagTrackingMode  0 Ninguno 1 Auto 2 Manual = %d\n", aMode); 
	myBagTrackingMode = aMode; 
}

/**/
- (int) getBagTrackingMode { return myBagTrackingMode; }


/**/
- (void) setManualDoor: (id) aManualDoor
{
	myManualDoor = aManualDoor;
}

/**/
- (void) addObserver: (id) anObserver
{
    myObserver = anObserver;
}

/**/
- (void) removeObserver
{
    myObserver = NULL;
}

/**/
- (void) notifyStateChange
{
	int i;

	printf("notifica un cambio de estado \n");
    
    if (myObserver) [myObserver onExtractionWorkflowStateChange: self];
	
}


@end
