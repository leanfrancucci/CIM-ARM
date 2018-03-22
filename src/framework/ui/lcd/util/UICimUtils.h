#ifndef UI_CIM_UTILS_H
#define UI_CIM_UTILS_H

#define UI_CIM_UTILS id

#include <Object.h>
#include "ctapp.h"
#include "JWindow.h"
#include "system/util/all.h"
#include "CimCash.h"
#include "Door.h"
#include "User.h"
#include "ExtractionWorkflow.h"
#include "CashReference.h"
#include "SafeBoxHAL.h"
#include "EventCategory.h"
#include "JForm.h"
#include "AlarmThread.h"
#include "CimBackup.h"

/**
 *	Sirve como punto de entrada para disparar diferentes formulario de seleccion.
 *	Metodos de clases unicamente.
 */
@interface UICimUtils : Object
{

}
/**/
+ (id) selectFromCollection: (JWINDOW) aParent 
	collection: (COLLECTION) aCollection 
	title: (char *) aTitle
	showItemNumber: (BOOL) aShowItemNumber
	selectedItem: (id) aSelectedItem;

/**/
+ (id) selectFromCollection: (JWINDOW) aParent 
	collection: (COLLECTION) aCollection 
	title: (char *) aTitle
	showItemNumber: (BOOL) aShowItemNumber;

/**/
+ (CIM_CASH) selectCimCash: (JWINDOW) aParent;

/**/
+ (DOOR) selectCollectorDoor: (JWINDOW) aParent;

/**/
+ (CIM_CASH) selectAutoCimCash: (JWINDOW) aParent;

/**/
+ (CIM_CASH) selectManualCimCash: (JWINDOW) aParent;

/**/
+ (DOOR) selectDoor: (JWINDOW) aParent;

/**/
+ (JFormModalResult) startDeposit: (JWINDOW) aParent 
		user: (USER) aUser 
		cimCash: (CIM_CASH) aCimCash 
		cashReference: (CASH_REFERENCE) aCashReference
		envelopeNumber: (char *) anEnvelopeNumber
    applyTo: (char *) anApplyTo;

/**/
+ (BOOL) askRemoveCash: (JWINDOW) aParent door: (DOOR) aDoor;

/**/
+ (char*) askBagBarCode: (JWINDOW) aParent barCode: (char*) aBarCode;

/**/
+ (USER) validateUser: (JWINDOW) aParent;

/**/
+ (USER) selectUser: (JWINDOW) aParent;

/**/
+ (USER) selectVisibleUser: (JWINDOW) aParent;

/**/
+ (USER) selectDynamicPinUser: (JWINDOW) aParent;

/**/
+ (void) cancelTimeDelay: (JWINDOW) aParent extractionWorkflow: (EXTRACTION_WORKFLOW) aExtractionWorkflow;

/**/
+ (void) checkEndOfDay: (JWINDOW) aParent;

/**/
+ (CASH_REFERENCE) selectCashReference: (JWINDOW) aParent;

+ (void) showAlarm: (char *) aMessage;

+ (void) askYesNoQuestion: (char *) anAlarm 
	data: (void*) aData 
	object: (id) anObject
	callback: (char *) aCallback;

+ (void) showTimeDelays: (JWINDOW) aParent;

+ (BOOL) askEnvelopeNumber: (JWINDOW) aParent 
		envelopeNumber: (char *) anEnvelopeNumber 
		title: (char *) aTitle
		description: (char *) aDescription;

+ (BOOL) askApplyTo: (JWINDOW) aParent 
		applyTo: (char *) anApplyTo 
		title: (char *) aTitle
		description: (char *) aDescription;

+ (BOOL) canMakeDeposits: (JWINDOW) aParent;

+ (BOOL) canMakeDeposits;

+ (BOOL) canMakeExtractions: (JWINDOW) aParent;

+ (char *) getDepositName: (int) depositType;

/**/
+ (int) selectCollectorUserStatus: (JWINDOW) aParent;

/**/
+ (int) selectCollectorWorkOrder: (JWINDOW) aParent;

/**/
+ (int) selectCollectorSelection: (JWINDOW) aParent title: (char *) aTitle;


+ (int) selectCurrentUserSelection: (JWINDOW) aParent title: (char *) aTitle;

/**/
+ (int) selectValidationMode: (JWINDOW) aParent title: (char *) aTitle viewPIMSM: (BOOL) aViewPIMSMode;

/**/
+ (int) selectPrintType: (JWINDOW) aParent title: (char *) aTitle;

/**/
+ (int) selectReprintSelection: (JWINDOW) aParent;

/**/
+ (BOOL) overrideDoor: (JWINDOW) aParent door: (DOOR) aDoor;

/**/
+ (DOOR) selectDoorWithAllOption: (JWINDOW) aParent hasSelectAll: (BOOL *) aHasSelectAll;

/**/
+ (USER) selectUserWithDropPermission: (JWINDOW) aParent;

/**/
+ (void) hardwareFailure: (JWINDOW) aParent 
	hardwareSystemStatus: (HardwareSystemStatus) aHardwareSystemStatus
	primaryMemoryStatus: (MemoryStatus) aPrimaryMemoryStatus
	secondaryMemoryStatus: (MemoryStatus) aSecondaryMemoryStatus;

/**/
+ (int) selectExtendedDropAction: (JWINDOW) aParent title: (char *) aTitle;

/**/
+ (EVENT_CATEGORY) selectEventCategory: (JWINDOW) aParent;

/**/
+ (BOOL) askForPassword: (JWINDOW) aParent result: (char *) aBuffer title: (char *) aTitle message: (char *) aMessage;

/**/
+ (BackupType) selectBackupType: (JWINDOW) aParent title: (char *) aTitle;

/**/
+ (BackupType) selectRestoreType: (JWINDOW) aParent title: (char *) aTitle;

@end

#endif
