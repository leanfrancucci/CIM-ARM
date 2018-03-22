#ifndef EXTRACTION_WORKFLOW_H
#define EXTRACTION_WORKFLOW_H

#define EXTRACTION_WORKFLOW id

#include <Object.h>
#include "system/util/all.h"
#include "system/os/all.h"
#include "Door.h"
#include "User.h"
#include "ExtractionManager.h"

/** 
 	*	Define el estado en el cual se encuentre el procedimiento de apertura de puerta 
	*/
typedef enum {
	OpenDoorStateType_UNDEFINED
 ,OpenDoorStateType_IDLE
 ,OpenDoorStateType_TIME_DELAY
 ,OpenDoorStateType_ACCESS_TIME
 ,OpenDoorStateType_WAIT_OPEN_DOOR
 ,OpenDoorStateType_WAIT_CLOSE_DOOR
 ,OpenDoorStateType_WAIT_CLOSE_DOOR_WARNING
 ,OpenDoorStateType_WAIT_CLOSE_DOOR_ERROR
 ,OpenDoorStateType_WAIT_LOCK_DOOR
 ,OpenDoorStateType_WAIT_LOCK_DOOR_ERROR
 ,OpenDoorStateType_OPEN_DOOR_VIOLATION
 ,OpenDoorStateType_LOCK_AND_OPEN_DOOR
 ,OpenDoorStateType_WAIT_UNLOCK_WITH_OPEN_DOOR
 ,OpenDoorStateType_WAIT_OUTER_DOOR_OPEN
} OpenDoorStateType;

/**
 *	Contiene la logica de como es el proceso de extraccion (apertura de puerta).
 *	Controla la secuencia de pasos a seguir para abrir una puerta.
 */
@interface ExtractionWorkflow : Object
{
	StateMachine *myStateMachine;
	DOOR myDoor;
	OTIMER myTimer;
	BOOL myGenerateExtraction;
	char myBuffer[100];
	EXTRACTION_MANAGER myExtractionManager;
	USER myUser1;
	USER myUser2;
	USER myDelayUser1; // dicho usuario se utiliza para mantener en memoria al usuario que inicio el door access. De esta manera si desea cancelar el time delay puedo comparar al usuario logueado con este y no con myUser1 porque puede que dicha variable sea NULL durante el door delay.
	USER myDelayUser2; // dicho usuario se utiliza para mantener en memoria al usuario que inicio el door access. De esta manera si desea cancelar el time delay puedo comparar al usuario logueado con este y no con myUser2 porque puede que dicha variable sea NULL durante el door delay.
	BOOL myHasUnlocked;
	BOOL myForceTimeDelayOverride;
	char myBagBarCode[25];
	unsigned long myLastExtractionNumber;
	BOOL myHasOpened;
	int myBagTrackingMode;
	EXTRACTION_WORKFLOW myInnerDoorWorkflow;
	BOOL myIsGeneratedOuterDoorExtr;
	id myManualDoor;
}

/**/
- (void) setExtractionManager: (EXTRACTION_MANAGER) anExtractionManager;

/**/
- (void) setInnerDoorWorkflow: (EXTRACTION_WORKFLOW) aValue;

/**/
- (EXTRACTION_WORKFLOW) getInnerDoorWorkflow;

/**
 *	Devuelve el estado actual.
 */
- (OpenDoorStateType) getCurrentState;

/**
 *	Remueve los usuarios que se habia previamente "logueado" en la puerta.
 *	Esto puede utilizarse en caso de que cancelen la operacion.
 */
- (void) removeLoggedUsers;

/** 
 *	Devuelve el tiempo restante (en ms) para que expire el timer.
 *	Dependera del estado actual el significado de ese timer.
 */
- (unsigned long) getTimeLeft;
- (unsigned long) getTimePassed;

/**/
- (void) setGenerateExtraction: (BOOL) aValue;
- (BOOL) getGenerateExtraction;

/**/
- (void) setDoor: (DOOR) aDoor;
- (DOOR) getDoor;

/**
 *	Notifica que se cancelo la apertura de la puerta
 */
- (void) cancelTimeDelay;

/**
 *	Notifica que se valido un usuario en el sistema. 
 */
- (void) onLoginUser: (USER) aUser;

/**
 *	Notifica la apertura de una puerta.
 */
- (void) onDoorOpen: (DOOR) aDoor;

/**
 * Este metodo se utiliza para ejecutar la extraccion al detectar que se removio el 
 * stacker de la puerta externa cuando en realidad NO se debia remover. Solo es 
 * utilizado cuando se tiene configurado una puerta dentro de otra. Para el resto de los 
 * casos se comporta como siempre.
 */
- (void) generateExtraction: (DOOR) aDoor;

/**
 *
 */
- (BOOL) isGeneratedOuterDoorExtr;

/**
 *
 */
- (void) setGeneratedOuterDoorExtr: (BOOL) aValue;

/**
 *	Notifica el cierra de la puerta.
 */
- (void) onDoorClose: (DOOR) aDoor;

/**/
- (USER) getUser1;

/**/
- (USER) getUser2;

/**/
- (USER) getDelayUser1;

/**/
- (USER) getDelayUser2;

/**/
- (void) onLocked: (DOOR) aDoor;

/**/
- (void) onUnLocked: (DOOR) aDoor;

/**/
- (void) forceTimeDelayOverride: (BOOL) aValue;

/**/
- (void) setBagBarCode: (char*) aValue;

/**/
- (unsigned long) getLastExtractionNumber;

/**/
- (BOOL) hasOpened;
- (void) setHasOpened: (BOOL) aValue;

/**/
- (void) resetLastExtractionNumber;

/**/
- (void) setBagTrackingMode: (int) aMode;
- (int) getBagTrackingMode;

/**/
- (void) setManualDoor: (id) aManualDoor;

@end

#endif
