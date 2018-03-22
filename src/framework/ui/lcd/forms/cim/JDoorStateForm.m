#include "JDoorStateForm.h"
#include "MessageHandler.h"
#include "JMessageDialog.h"
#include "UICimUtils.h"
#include "CimManager.h"
#include "CimGeneralSettings.h"


//#define printd(args...) doLog(0,args)
#define printd(args...)


@implementation  JDoorStateForm

- (void) setCurrentDoor: (id) aDoor;
- (void) exitFromForm;

/**/
- (void) setExtractionWorkflow: (EXTRACTION_WORKFLOW) aValue
{

	myExtractionWorkflow = aValue;
	myLastExtWorkflow = ExtWorkflowType_NORMAL;
	[self setCurrentDoor: [myExtractionWorkflow getDoor]];
}

/**/
- (void) setCurrentDoor: (id) aDoor
{
	char buffer[30];
	char format[10];
	char doorName[41];

	stringcpy(doorName, [aDoor getDoorName]);
	doorName[20] = '\0';
	strcpy(myCurrentDoorStr, doorName);

	// Texto centrado
	sprintf(format, "%%%ds", (20 - strlen(doorName)) / 2);
	sprintf(buffer, format, " ");
	strcat(buffer, doorName);
	[myLabelMessage setCaption: buffer];

	[myLabelDoorName setCaption: buffer];

}

/**/
- (BOOL) isDiferentDoor: (id) aDoor
{
	char doorName[41];

	stringcpy(doorName, [aDoor getDoorName]);
	doorName[20] = '\0';

	return (strcmp(myCurrentDoorStr, doorName) != 0);

}

/**/
- (void) onCreateForm
{
	[super onCreateForm];

	myMutex = [OMutex new];

	myUpdateTimer = [OTimer new];
	[myUpdateTimer initTimer: PERIODIC period: 200 object: self callback: "updateTimerHandler"];

	myLabelMessage = [JLabel new];
	[myLabelMessage setCaption: getResourceStringDef(RESID_IDLE_UPPER, "INACTIVO")];
	[myLabelMessage setWidth: 20];
	[myLabelMessage setHeight: 1];
	[self addFormComponent: myLabelMessage];

	myLabelDoorName = [JLabel new];
	[myLabelDoorName setCaption: getResourceStringDef(RESID_DOOR_UPPER, "PUERTA")];
	[myLabelDoorName setWidth: 20];
	[myLabelDoorName setHeight: 1];
	[self addFormComponent: myLabelDoorName];

	myLabelTimeLeft = [JLabel new];
	[myLabelTimeLeft setCaption: ""];
	[myLabelTimeLeft setWidth: 20];
	[myLabelTimeLeft setHeight: 1];
	[myLabelTimeLeft setWordWrap: TRUE];
	[self addFormComponent: myLabelTimeLeft];

	myIsClosingForm = FALSE;
	myOpenDoorForCommercialChange = FALSE;

	myBagVerification = FALSE;

}

/**/
- (char *) formatTimeLeft: (unsigned long) aLeftTime buffer: (char *) aBuffer
{
	int left = aLeftTime / 1000;
	sprintf(aBuffer, "%d:%02d", left / 60, left % 60);
	return aBuffer;
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

	if (myIsClosingForm) return;

	[myMutex lock];

	*stateStr = '\0';
	*timeStr = '\0';
	left = [myExtractionWorkflow getTimeLeft];

	errorClosingDoorOrder = FALSE;
	showOpenExternalDoorMsg = FALSE;

	if (([myExtractionWorkflow getInnerDoorWorkflow]) && 
			([[myExtractionWorkflow getInnerDoorWorkflow] getCurrentState] != OpenDoorStateType_WAIT_OUTER_DOOR_OPEN) &&
			([[myExtractionWorkflow getInnerDoorWorkflow] getCurrentState] != OpenDoorStateType_IDLE)) {

				currentState = [[myExtractionWorkflow getInnerDoorWorkflow] getCurrentState];
				if (myLastExtWorkflow != ExtWorkflowType_INNER)
					[self setCurrentDoor: [[myExtractionWorkflow getInnerDoorWorkflow] getDoor]];

				myLastExtWorkflow = ExtWorkflowType_INNER;

				// control para saber si se cerro la puerta externa antes que la interna
				if ([myExtractionWorkflow getCurrentState] == OpenDoorStateType_IDLE)
					errorClosingDoorOrder = TRUE;

				if ([myExtractionWorkflow getCurrentState] == OpenDoorStateType_WAIT_OPEN_DOOR) {
					showOpenExternalDoorMsg = TRUE;

					if ([self isDiferentDoor: [myExtractionWorkflow getDoor]])
						[self setCurrentDoor: [myExtractionWorkflow getDoor]];

				} else {
					if ([self isDiferentDoor: [[myExtractionWorkflow getInnerDoorWorkflow] getDoor]])
						[self setCurrentDoor: [[myExtractionWorkflow getInnerDoorWorkflow] getDoor]];
				}

	} else {
  			currentState = [myExtractionWorkflow getCurrentState];
				if (myLastExtWorkflow != ExtWorkflowType_NORMAL)
					[self setCurrentDoor: [myExtractionWorkflow getDoor]];

				myLastExtWorkflow = ExtWorkflowType_NORMAL;
	}

	switch (currentState) {

		case OpenDoorStateType_UNDEFINED: 
			strcpy(stateStr, getResourceStringDef(RESID_UNDEFINED_UPPER, "INDEFINIDO"));
			break;

		case OpenDoorStateType_IDLE: 
			strcpy(stateStr, getResourceStringDef(RESID_IDLE, "Inactivo"));
			break;

		case OpenDoorStateType_TIME_DELAY: 
			strcpy(stateStr, getResourceStringDef(RESID_DOOR_DELAY, "Retardo de Puerta"));
			left = [myExtractionWorkflow getTimePassed];
			[self formatTimeLeft: left buffer: timeStr]; 
			break;

		case OpenDoorStateType_ACCESS_TIME: 
			strcpy(stateStr, getResourceStringDef(RESID_ACCESS_TIME, "Tiempo de Acceso")); 
			[self formatTimeLeft: left buffer: timeStr]; 
			break;

		case OpenDoorStateType_WAIT_OPEN_DOOR: 
			strcpy(stateStr, getResourceStringDef(RESID_OPEN_DOOR, "Abrir Puerta"));  
			strcpy(timeStr, getResourceStringDef(RESID_NOW, "AHORA!"));
			break;

		case OpenDoorStateType_WAIT_CLOSE_DOOR: 
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

			break;

		case OpenDoorStateType_WAIT_CLOSE_DOOR_WARNING: 
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

			break;

		case OpenDoorStateType_WAIT_CLOSE_DOOR_ERROR: 
			if (myOpenDoorForCommercialChange) {
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
			break;

		case OpenDoorStateType_LOCK_AND_OPEN_DOOR: 
			strcpy(stateStr, getResourceStringDef(RESID_DOOR_IS_OPEN, "Puerta abierta"));
			strcpy(timeStr, getResourceStringDef(RESID_ERROR, "Error"));
			break;

		case OpenDoorStateType_WAIT_UNLOCK_WITH_OPEN_DOOR: 
			strcpy(stateStr, getResourceStringDef(RESID_UNLOCK_DOOR, "Destrabar Puerta"));
			strcpy(timeStr, getResourceStringDef(RESID_ERROR, "Error"));
			break;

		case OpenDoorStateType_WAIT_LOCK_DOOR: 
			strcpy(stateStr, getResourceStringDef(RESID_LOCK_DOOR, "Trabar Puerta"));
			if (left > 0) {
				[self formatTimeLeft: left buffer: buffer]; 
				formatResourceStringDef(timeStr, RESID_WARNING_IN, "Advertencia en %s", buffer);
			}
			break;

		case OpenDoorStateType_WAIT_LOCK_DOOR_ERROR: 
			strcpy(stateStr, getResourceStringDef(RESID_LOCK_DOOR, "Trabar Puerta"));
			if (left > 0) {
				[self formatTimeLeft: left buffer: buffer]; 
				formatResourceStringDef(timeStr, RESID_ALARM_IN, "Alarma en %s", buffer);
			}
			break;

		case OpenDoorStateType_OPEN_DOOR_VIOLATION: 
			strcpy(stateStr, getResourceStringDef(RESID_SECURITY_VIOLATION, "Violacion de Seguridad"));
			break;

		case OpenDoorStateType_WAIT_OUTER_DOOR_OPEN: 
			strcpy(stateStr, getResourceStringDef(RESID_WAIT_OUTER_DOOR_OPEN, "Wait Outer Door Open"));
			break;
	}

	// Texto centrado
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

	[myLabelTimeLeft setCaption: buffer];

	[self doChangeStatusBarCaptions];

	[myMutex unLock];

	if ([myExtractionWorkflow getCurrentState] == OpenDoorStateType_WAIT_CLOSE_DOOR && myOpenDoorForCommercialChange) {
		[self exitFromForm];
		return;
	}

	if (!myBagVerification) return;

	// si posee inner door y aun no se genero la extraccion 
	// hago el return porque el bag traking lo debe procesar la puerta interna
	if ([myExtractionWorkflow getInnerDoorWorkflow]) {
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
}

/**/
- (void) onMenu1ButtonClick
{

	if (myExtractionWorkflow != NULL && [myExtractionWorkflow getCurrentState] == OpenDoorStateType_TIME_DELAY) {


		[UICimUtils cancelTimeDelay: self extractionWorkflow: myExtractionWorkflow];

		// Actualizo la pantalla
		[self updateTimerHandler];

	}

}

/**/
- (void) exitFromForm
{
	[myMutex lock];
	myModalResult = JFormModalResult_OK;
	myIsClosingForm = TRUE;
	[myUpdateTimer stop];
	[myUpdateTimer free];
	[myMutex unLock];
	[myMutex free];
	[self closeForm];
}

/**/
- (void) onMenu2ButtonClick
{
	
}

/**/
- (void) onMenuXButtonClick
{
	OpenDoorStateType currentState;

	if (myExtractionWorkflow == NULL) return;

	currentState = [myExtractionWorkflow getCurrentState];

	if (currentState == OpenDoorStateType_IDLE || 
			currentState == OpenDoorStateType_TIME_DELAY || 
			currentState == OpenDoorStateType_ACCESS_TIME ||
			currentState == OpenDoorStateType_LOCK_AND_OPEN_DOOR ||
			currentState == OpenDoorStateType_OPEN_DOOR_VIOLATION ||
			currentState == OpenDoorStateType_WAIT_LOCK_DOOR ||
			currentState == OpenDoorStateType_WAIT_LOCK_DOOR_ERROR)
	[self exitFromForm];

}

/**/
- (char *) getCaption1
{	
	if (myExtractionWorkflow != NULL && [myExtractionWorkflow getCurrentState] == OpenDoorStateType_TIME_DELAY)
		return getResourceStringDef(RESID_CANCEL_KEY, "cancel");

	return NULL;
}

/**/
- (char *) getCaption2
{	
	return NULL;
}

/**/
- (char *) getCaptionX
{	
	OpenDoorStateType currentState;

	if (myExtractionWorkflow == NULL) return NULL;

	currentState = [myExtractionWorkflow getCurrentState];

	if (currentState == OpenDoorStateType_IDLE || 
			currentState == OpenDoorStateType_TIME_DELAY || 
			currentState == OpenDoorStateType_ACCESS_TIME ||
			currentState == OpenDoorStateType_LOCK_AND_OPEN_DOOR ||
			currentState == OpenDoorStateType_OPEN_DOOR_VIOLATION ||
			currentState == OpenDoorStateType_WAIT_LOCK_DOOR ||
			currentState == OpenDoorStateType_WAIT_LOCK_DOOR_ERROR)
	return getResourceStringDef(RESID_DONE, "done");

	return NULL;
}

/**/
- (void) onActivateForm
{
	[self updateTimerHandler];
	[myUpdateTimer start];
}

/**/
- (void) setOpenDoorForCommercialChange: (BOOL) aValue
{
	myOpenDoorForCommercialChange = aValue;
}

/**/
- (void) setBagVerification: (BOOL) aValue
{
	myBagVerification = aValue;
}

@end
