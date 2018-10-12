#include "UICimUtils.h"
#include "JSimpleSelectionForm.h"
#include "MessageHandler.h"
#include "CimManager.h"
#include "JAutomaticDepositForm.h"
#include "JMessageDialog.h"
#include "JSecondaryUserLoginForm.h"
#include "JUserLoginForm.h"
#include "ZCloseManager.h"
#include "CimDefs.h"
#include "CashReferenceManager.h"
#include "JExceptionForm.h"
#include "EventManager.h"
#include "Event.h"
#include "JSystem.h"
#include "AlarmThread.h"
#include "JDoorDelaysForm.h"
#include "JSimpleTextForm.h"
#include "JDoorOverrideForm.h"
#include "Profile.h"
#include "CimGeneralSettings.h"
#include "Option.h"
#include "Audit.h"
#include "AuditDAO.h"
#include "Persistence.h"
#include "Buzzer.h"
#include "CimExcepts.h"
#include "CommercialStateMgr.h"
#include "doorover.h"
#include "AsyncMsgThread.h"

@implementation UICimUtils

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	return self;
}

+ (id) selectFromCollection: (JWINDOW) aParent 
	collection: (COLLECTION) aCollection 
	title: (char *) aTitle
	showItemNumber: (BOOL) aShowItemNumber
	selectedItem: (id) aSelectedItem
{
	id obj = NULL;
	JSIMPLE_SELECTION_FORM form;
	JFormModalResult modalResult;

	form = [JSimpleSelectionForm createForm: aParent];
	[form setTitle: aTitle];
	[form setCollection: aCollection];
	[form setShowItemNumber: aShowItemNumber];
	[form setInitialSelectedItem: aSelectedItem];
	modalResult = [form showModalForm];
	if (modalResult == JFormModalResult_OK) {
		obj = [form getSelectedItem];
	}

	[form free];

	return obj;
}

/**/
+ (id) selectFromCollection: (JWINDOW) aParent 
	collection: (COLLECTION) aCollection 
	title: (char *) aTitle
	showItemNumber: (BOOL) aShowItemNumber
{
	return [self selectFromCollection: aParent 
		collection: aCollection 
		title: aTitle 
		showItemNumber: aShowItemNumber
		selectedItem: NULL];
}

/**/
+ (CIM_CASH) selectCimCash: (JWINDOW) aParent
{
	printf("cantidad de cashes = %d\n", [[[[CimManager getInstance] getCim] getCimCashs] size]);

	return [UICimUtils selectFromCollection: aParent 
		collection: [[[CimManager getInstance] getCim] getCimCashs] 
		title: getResourceStringDef(RESID_SELECT_CASH, "Seleccione Cash:")
		showItemNumber: TRUE];
}

/**/
+ (EVENT_CATEGORY) selectEventCategory: (JWINDOW) aParent
{
	return [UICimUtils selectFromCollection: aParent 
		collection: [[EventManager getInstance] getEventsCategory]
		title: getResourceStringDef(RESID_SELECT_EVENT_CATEG, "Selecc Categ Evento:")
		showItemNumber: TRUE];
}


/**/
+ (DOOR) selectCollectorDoor: (JWINDOW) aParent
{
	COLLECTION list = [Collection new];
	COLLECTION doors;
	id door = NULL;
	int i;

	doors = [[[CimManager getInstance] getCim] getCollectorDoors];
	for (i = 0; i < [doors size]; ++i) {
		// solo la agrego si no esta deshabilitada
		if ((![[doors at: i] isDeleted]) && ([[[doors at: i] getAcceptorSettingsList] size] > 0))
			[list add: [doors at: i]];
	}

	door = [UICimUtils selectFromCollection: aParent 
		collection: list
		title: getResourceStringDef(RESID_SELECT_DOOR, "Seleccione Puerta:")
		showItemNumber: TRUE];

	[list free];
	return door;

}

/**/
+ (int) selectCollectorSelection: (JWINDOW) aParent title: (char *) aTitle
{
  COLLECTION selection;
  id strAll;
  id strSelect;
  id resultStr;
  int result;

  strAll = [String str: getResourceStringDef(RESID_ALL_LABEL, "All")];
  strSelect = [String str: getResourceStringDef(RESID_SELECT_LABEL, "Select")];
        
  selection = [Collection new];
  
  [selection add: strAll];
  [selection add: strSelect];

	resultStr = [UICimUtils selectFromCollection: aParent 
		collection: selection
		title: aTitle
		showItemNumber: TRUE];
  	
	if (resultStr == strAll) result = 1;
	else if (resultStr == strSelect) result = 2;
	else result = 0;
		
	[strAll free];
	[strSelect free];
	[selection free];

	return result;
}

/**/
+ (int) selectCurrentUserSelection: (JWINDOW) aParent title: (char *) aTitle
{
  COLLECTION selection;
  id strCurrentUser;
  id strOtherUser;
  id resultStr;
  int result;

  strCurrentUser = [String str: getResourceStringDef(RESID_CURRENT_USER, "Current User")];
  strOtherUser = [String str: getResourceStringDef(RESID_OTHER_USER, "Other User")];
        
  selection = [Collection new];
  
  [selection add: strCurrentUser];
  [selection add: strOtherUser];

	resultStr = [UICimUtils selectFromCollection: aParent 
		collection: selection
		title: aTitle
		showItemNumber: TRUE];
  	
	if (resultStr == strCurrentUser) result = 1;
	else if (resultStr == strOtherUser) result = 2;
	else result = 0;
		
	[strCurrentUser free];
	[strOtherUser free];
	[selection free];

	return result;
}

/**/
+ (int) selectValidationMode: (JWINDOW) aParent title: (char *) aTitle viewPIMSM: (BOOL) aViewPIMSMode
{
  COLLECTION selection;
  id strManual;
  id strCMP;
  id strPIMS;
  id resultStr;
  int result;

  strManual = [String str: getResourceStringDef(RESID_MANUAL_MODE, "Manual")];
  strCMP = [String str: getResourceStringDef(RESID_CMP_MODE, "CMP")];
	strPIMS = [String str: getResourceStringDef(RESID_PIMS_MODE, "PIMS")];
        
  selection = [Collection new];
  
  [selection add: strManual];
  [selection add: strCMP];
	// solo lo agrego a la lista cuando la variable me lo indica
	if (aViewPIMSMode)
    [selection add: strPIMS];

	resultStr = [UICimUtils selectFromCollection: aParent 
		collection: selection
		title: aTitle
		showItemNumber: TRUE];
  	
	if (resultStr == strManual) result = 1;
	else if (resultStr == strCMP) result = 2;
	     else if (resultStr == strPIMS) result = 3;
						else result = 0;
		
	[strManual free];
	[strCMP free];
	[strPIMS free];
	[selection free];

	return result;
}

/**/
+ (int) selectPrintType: (JWINDOW) aParent title: (char *) aTitle
{
  COLLECTION selection;
  id strSummary;
  id strDetailed;
  id resultStr;
  int result;

  strSummary = [String str: getResourceStringDef(RESID_SUMMARY_LABEL, "Resumido")];
  strDetailed = [String str: getResourceStringDef(RESID_DETAILED_LABEL, "Detallado")];
        
  selection = [Collection new];
  
  [selection add: strSummary];
  [selection add: strDetailed];

	resultStr = [UICimUtils selectFromCollection: aParent 
		collection: selection
		title: aTitle
		showItemNumber: TRUE];
  	
	if (resultStr == strSummary) result = 1;
	else if (resultStr == strDetailed) result = 2;
	else result = 0;
		
	[strSummary free];
	[strDetailed free];
	[selection free];

	return result;
}

/**/
+ (int) selectReprintSelection: (JWINDOW) aParent
{
  COLLECTION selection;
  id strLast;
  id strByRange;
  id resultStr;
  int result;

  strLast = [String str: getResourceStringDef(RESID_LAST_LABEL, "Ultimo")];
  strByRange = [String str: getResourceStringDef(RESID_BY_RANGE_LABEL, "Por rango")];
        
  selection = [Collection new];
  
  [selection add: strLast];
  [selection add: strByRange];

	resultStr = [UICimUtils selectFromCollection: aParent 
		collection: selection
		title: getResourceStringDef(RESID_REPRINT_LABEL, "Reimprimir:")
		showItemNumber: TRUE];
  	
	if (resultStr == strLast) result = 1;
	else if (resultStr == strByRange) result = 2;
	     else result = 0;
		
	[strLast free];
	[strByRange free];
	[selection free];

	return result;
}

/**/
+ (int) selectCollectorUserStatus: (JWINDOW) aParent
{
  COLLECTION userStatus;
  id strAll;
  id strActives;
  id strInactives;
  id resultStr;
  int result;

  strAll = [String str: getResourceStringDef(RESID_ALL_LABEL, "All")];
  strActives = [String str: getResourceStringDef(RESID_ACTIVE_LABEL, "Actives")];
  strInactives = [String str: getResourceStringDef(RESID_INACTIVE_LABEL, "Inactives")];
        
  userStatus = [Collection new];
  
  [userStatus add: strAll];
  [userStatus add: strActives];
  [userStatus add: strInactives];

	resultStr = [UICimUtils selectFromCollection: aParent 
		collection: userStatus
		title: getResourceStringDef(RESID_SELECT_STATUS, "Seleccione Estado:")
		showItemNumber: TRUE];
  	
	if (resultStr == strAll) result = 1;
	else if (resultStr == strActives) result = 2;
	else if (resultStr == strInactives) result = 3;
	else result = 0;
		
	[strAll free];
	[strActives free];
	[strInactives free];
	[userStatus free];
	
	return result;
}

/**/
+ (int) selectCollectorWorkOrder: (JWINDOW) aParent
{
  COLLECTION operations;
  id strNew;
  id strInsert;
  id resultStr;
  int result;

  strNew = [String str: getResourceStringDef(RESID_NEW_WORK_ORDER_LABEL, "Nueva Orden Trab")];
  strInsert = [String str: getResourceStringDef(RESID_INSERT_WORK_ORDER_LABEL, "Indicar Ord Trab")];
        
  operations = [Collection new];
  
  [operations add: strNew];
  [operations add: strInsert];

	resultStr = [UICimUtils selectFromCollection: aParent 
		collection: operations
		title: getResourceStringDef(RESID_WORK_ORDER_LABEL, "Orden de Trabajo:")
		showItemNumber: TRUE];
  	
	if (resultStr == strNew) result = 1;
	else if (resultStr == strInsert) result = 2;
	     else result = 0;
		
	[strNew free];
	[strInsert free];
	[operations free];
	
	return result;
}

/**/
+ (CIM_CASH) selectAutoCimCash: (JWINDOW) aParent
{
	return [UICimUtils selectFromCollection: aParent 
		collection: [[[CimManager getInstance] getCim] getAutoCimCashs]
		title: getResourceStringDef(RESID_VALIDATED_DROP_TO, "Deposito Validado a:")
		showItemNumber: TRUE];
}

/**/
+ (CIM_CASH) selectManualCimCash: (JWINDOW) aParent
{
	return [UICimUtils selectFromCollection: aParent 
		collection: [[[CimManager getInstance] getCim] getManualCimCashs]
		title: getResourceStringDef(RESID_MANUAL_DROP_TO, "Deposito Manual a:")
		showItemNumber: TRUE];
}


/**/
+ (DOOR) selectDoor: (JWINDOW) aParent
{
	COLLECTION list = [Collection new];
	COLLECTION doors;
	int i;

	doors = [[[CimManager getInstance] getCim] getDoors];
	for (i = 0; i < [doors size]; ++i) {
		// solo la agrego si no esta deshabilitada
		if (![[doors at: i] isDeleted])
			[list add: [doors at: i]];
	}

	return [UICimUtils selectFromCollection: aParent 
		collection: list
		title: getResourceStringDef(RESID_SELECT_DOOR, "Seleccione Puerta:")
		showItemNumber: TRUE];
}

/**/
+ (DOOR) selectDoorWithAllOption: (JWINDOW) aParent hasSelectAll: (BOOL *) aHasSelectAll
{
	COLLECTION list = [Collection new];
	COLLECTION doors;
	int i;
	id allStr;
	id obj;
	BOOL hasInnerDoor = FALSE;
	BOOL hasDisableDoor = FALSE;

	*aHasSelectAll = FALSE;

	doors = [[[CimManager getInstance] getCim] getDoors];

	for (i = 0; i < [doors size]; ++i) {

		// solo la agrego si no esta deshabilitada
		if (![[doors at: i] isDeleted])
			[list add: [doors at: i]];

		if ([[doors at: i] isInnerDoor]) hasInnerDoor = TRUE;
		if ([[doors at: i] isDeleted]) hasDisableDoor = TRUE;
	}
	
	if ([list size] == 1) {
		obj = [list at: 0];
		[list free];
		return obj;
	}

	allStr = [String str: getResourceStringDef(RESID_ALL_DOORS, "All")];

	// si esta habilitado el bag tracking, no hay puertas internas y no hay puertas deshabilitadas NO muestro la opcion ALL
	if (![[CimGeneralSettings getInstance] getRemoveBagVerification] && ![[CimGeneralSettings getInstance] getBagTracking] && !hasInnerDoor && !hasDisableDoor)
		[list add: allStr];
	
	obj = [UICimUtils selectFromCollection: aParent 
		collection: list
		title: getResourceStringDef(RESID_SELECT_DOOR, "Seleccione Puerta:")
		showItemNumber: TRUE];

	if (obj == allStr) {
		*aHasSelectAll = TRUE;
		obj = NULL;
	}

	[allStr free];
	[list free];

	return obj;
}

/**/
+ (JFormModalResult) startDeposit: (JWINDOW) aParent 
		user: (USER) aUser 
		cimCash: (CIM_CASH) aCimCash 
		cashReference: (CASH_REFERENCE) aCashReference
		envelopeNumber: (char *) anEnvelopeNumber
		applyTo: (char *) anApplyTo
{
	JFORM form;
	JFormModalResult modalResult;

  form = [JAutomaticDepositForm createForm: aParent];
	[form setCimCash: aCimCash];
	[form setCashReference: aCashReference];
	[form setEnvelopeNumber: anEnvelopeNumber];
	[form setApplyTo: anApplyTo];
	[form setUser: aUser];
  [form showModalForm];
	if ([form isDepositOk])
		modalResult = JFormModalResult_OK;
	else
		modalResult = JFormModalResult_CANCEL;

  [form free];

	// devuelve si cancelo o no el formulario de deposito.
	return modalResult;
}

/**/
+ (BOOL) askRemoveCash: (JWINDOW) aParent door: (DOOR) aDoor
{
	char buf[100];


	if (![[CimGeneralSettings getInstance] getAskRemoveCash]) return TRUE;

	if (aDoor != NULL) {
		formatResourceStringDef(buf, RESID_REMOVE_CASH_FROM, "Desea remover el dinero de %s?", [aDoor getDoorName]);
	} else {
		stringcpy(buf, getResourceStringDef(RESID_REMOVE_CASH_FROM_ALL, "Desea remover el dinero?"));
	}

	return [JMessageDialog askYesNoMessageFrom: aParent withMessage: buf] == JDialogResult_YES;
}

/**/
+ (char*) askBagBarCode: (JWINDOW) aParent barCode: (char*) aBarCode
{
	JFORM form;
	JFormModalResult modalResult;

	// Solicito el numero de sobre
	form = [JSimpleTextForm createForm: aParent];
	[form setWidth: 15];
	[form setTitle: getResourceStringDef(RESID_SECURITY_BAG_ID, "Id bolsa recaud.:")];

	[form setScanningModeEnable: [[CimGeneralSettings getInstance] getUseBarCodeReader]];

	[form setCaption1: getResourceStringDef(RESID_SKIP, "Ignorar")];

	modalResult = [form showModalForm];
	strcpy(aBarCode, [form getTextValue]);
	[form free];

	//if (modalResult == JFormModalResult_CANCEL) return FALSE;

	return aBarCode;

}

/**/
+ (USER) validateUser: (JWINDOW) aParent
{
	USER user = NULL;
	JFORM form;

	form = [JUserLoginForm createForm: aParent];
	[form setDoLog: FALSE];
	[form setCanGoBack: TRUE];
	if ([form showModalForm] != JFormModalResult_CANCEL) {
		user = [form getLoggedUser];
	}
	[form free];
	
	return user;
}

/**/
+ (USER) selectUser: (JWINDOW) aParent
{
	return [UICimUtils selectFromCollection: aParent 
		collection: [[UserManager getInstance] getUsers]
		title: getResourceStringDef(RESID_SELECT_USER, "Seleccione Usuario:")
		showItemNumber: TRUE];
}

/**/
+ (USER) selectVisibleUser: (JWINDOW) aParent
{
	return [UICimUtils selectFromCollection: aParent 
		collection: [[UserManager getInstance] getVisibleUsers]
		title: getResourceStringDef(RESID_SELECT_USER, "Seleccione Usuario:")
		showItemNumber: TRUE];
}

/**/
+ (USER) selectDynamicPinUser: (JWINDOW) aParent
{
	return [UICimUtils selectFromCollection: aParent 
		collection: [[UserManager getInstance] getDynamicPinUsers]
		title: getResourceStringDef(RESID_SELECT_USER, "Seleccione Usuario:")
		showItemNumber: TRUE];
}



/**/
+ (USER) selectUserWithDropPermission: (JWINDOW) aParent
{
	COLLECTION list = [Collection new];
	COLLECTION users;
	USER user;
	int i;
	PROFILE profile;

	users = [[UserManager getInstance] getVisibleUsers];

	for (i = 0; i < [users size]; ++i) {
	  profile = [[UserManager getInstance] getProfile: [[users at: i] getUProfileId]];
		if ([[users at: i] isActive] && [profile hasPermission: VALIDATED_DROP_OP]) [list add: [users at: i]];
	}

	user = [UICimUtils selectFromCollection: aParent 
		collection: list
		title: getResourceStringDef(RESID_SELECT_USER, "Seleccione Usuario:")
		showItemNumber: TRUE];

	[list free];

	return user;
}

/**/
+ (void) cancelTimeDelay: (JWINDOW) aParent extractionWorkflow: (EXTRACTION_WORKFLOW) aExtractionWorkflow
{
	USER user;
	char buf[100];

	if (aExtractionWorkflow == NULL) return;

	if ([aExtractionWorkflow getCurrentState] != OpenDoorStateType_TIME_DELAY) {
		[JMessageDialog askOKMessageFrom: aParent 
				withMessage: getResourceStringDef(RESID_NOT_TIME_DELAY_FOR_DOOR, "No existe un tiempo de apertura retrasado para esa puerta.")];
		return;
	}

	user = [UICimUtils validateUser: aParent];

	// Si el usuario es nulo cancelo la operacion
	if (user == NULL) return;

	TRY

		// Si el usuario 1 o usuario 2 coinciden entonces le permito cancelar
		// la operation (previa pregunta a si esta seguro)
		if ([aExtractionWorkflow getDelayUser1] == user ||
				[aExtractionWorkflow getDelayUser2] == user) {
			
			formatResourceStringDef(buf, RESID_CONFIRM_CANCELATION_TIME_DELAY, "Cancela tiempo de apertura retrasado %s", [[aExtractionWorkflow getDoor] getDoorName]);

			if ([JMessageDialog askYesNoMessageFrom: aParent withMessage: buf] == JDialogResult_YES) {
				[aExtractionWorkflow cancelTimeDelay];
			}
	
		} else {
	
			[JMessageDialog askOKMessageFrom: aParent 
				withMessage: getResourceStringDef(RESID_TIME_DELAY_CANCEL, "El Tiempo de apertura debe ser cancel. por el usu. que lo solicito.")];
	
		}
	
	CATCH

		[aParent showDefaultExceptionDialogWithExCode: ex_get_code()];

	END_TRY


}

/**/
+ (void) checkEndOfDay: (JWINDOW) aParent
{
	if (![[ZCloseManager getInstance] inStartDay]) return;

	[JMessageDialog askOKMessageFrom: aParent 
		withMessage: getResourceStringDef(RESID_MUST_GENERATE_END_REPORT, "Debe generar el cierre diario.")];
	
}

/**/
+ (CASH_REFERENCE) selectCashReference: (JWINDOW) aParent
{
	COLLECTION references;
	CASH_REFERENCE parent = NULL;
	CASH_REFERENCE newReference;
	char title[50];

	references = [Collection new];

	while (TRUE) {

		[[CashReferenceManager getInstance] getCashReferenceChilds: references cashReference: parent];

		if ([references size] == 0) {

			// Si estoy en el primer nivel quiere decir que no hay ningun
			// reference cargado con lo cual debo tirar un mensaje de error
			if (parent == NULL) {
				[JMessageDialog askOKMessageFrom: aParent 
					withMessage: getResourceStringDef(RESID_NO_REFERENCES_DEFINED, "No hay reference definidos!")];
			}


			[references free];
			return parent;
		}

		if (parent == NULL) stringcpy(title, getResourceStringDef(RESID_SELECT_REFERENCE, "Selecc reference:"));
		else stringcpy(title, [parent getName]);

		newReference = [UICimUtils selectFromCollection: aParent
			collection: references
			title: title
			showItemNumber: TRUE];

		if (newReference == NULL) {
			if (parent == NULL) {
				[references free];
				return NULL;
			}
			parent = [parent getParent];
		} else {
			parent = newReference;
		}

	}

}

/**/
+ (CASH_REFERENCE) editCashReferences: (JWINDOW) aParent
{
	COLLECTION references;
	CASH_REFERENCE parent = NULL;
	CASH_REFERENCE newReference;
	char title[50];

	references = [Collection new];

	while (TRUE) {

		[[CashReferenceManager getInstance] getCashReferenceChilds: references cashReference: parent];

		if ([references size] == 0) {

			// Si estoy en el primer nivel quiere decir que no hay ningun
			// reference cargado con lo cual debo tirar un mensaje de error
			if (parent == NULL) {
				[JMessageDialog askOKMessageFrom: aParent 
					withMessage: getResourceStringDef(RESID_NO_REFERENCES_DEFINED, "No hay reference definidos!")];
			}


			[references free];
			return parent;
		}

		if (parent == NULL) stringcpy(title, getResourceStringDef(RESID_SELECT_REFERENCE, "Selecc reference:"));
		else stringcpy(title, [parent getName]);

		newReference = [UICimUtils selectFromCollection: aParent
			collection: references
			title: title
			showItemNumber: TRUE];

		if (newReference == NULL) {
			if (parent == NULL) {
				[references free];
				return NULL;
			}
			parent = [parent getParent];
		} else {
			parent = newReference;
		}

	}

}

/**/
+ (void) showAlarm: (char *) aMessage
{
	//[[AlarmThread getInstance] addAlarm: aMessage];
    //Modificado por sole! 12/10/2018>. Despues pasar codigo a AlarmThread para hacerlo generico
    printf("UICimUtils --> addAsyncMsg\n");
    [[AsyncMsgThread getInstance] addAsyncMsg: "1000" description: aMessage isBlocking: FALSE];

}

/**/
+ (void) askYesNoQuestion: (char *) anAlarm 
	data: (void*) aData 
	object: (id) anObject
	callback: (char *) aCallback
{
	[[AlarmThread getInstance] askYesNoQuestion: anAlarm 
	data: aData
	object: anObject
	callback: aCallback];
}

+ (void) showTimeDelays: (JWINDOW) aParent
{
	JSIMPLE_SELECTION_FORM form;
	JFormModalResult modalResult;
	COLLECTION collection;

	collection = [[CimManager getInstance] getExtractionWorkflowListOnTimeDelay];
	if ([collection size] == 0) {
		[JMessageDialog askOKMessageFrom: aParent withMessage: getResourceStringDef(RESID_NO_ACTIVES_TIME_DELAYS, "No existen Time Delays activos")];
		[collection free];
		return;
	}
	
	form = [JDoorDelaysForm createForm: aParent];
	[form setAutoRefreshTime: 300];
	[form setTitle: getResourceStringDef(RESID_TIME_DELAY, "Lista de retardos:")];
	[form setCollection: collection];
	modalResult = [form showModalForm];
	[form free];
	
	[collection free];
}

/**/
+ (BOOL) askEnvelopeNumber: (JWINDOW) aParent 
		envelopeNumber: (char *) anEnvelopeNumber 
		title: (char *) aTitle
		description: (char *) aDescription
{
	JFORM form;
	JFormModalResult modalResult;

	// Solicito el numero de sobre
	form = [JSimpleTextForm createForm: aParent];
	[form setWidth: 15];
	[form setTitle: aTitle];
	[form setDescription: aDescription];

	if ([[CimGeneralSettings getInstance] getEnvelopeIdOpMode] == KeyPadOperationMode_NUMERIC)
		[form setNumericMode: TRUE];

	if ([[CimGeneralSettings getInstance] getUseBarCodeReader])
		[form setScanningModeEnable: TRUE];

	modalResult = [form showModalForm];
	strcpy(anEnvelopeNumber, [form getTextValue]);
	[form free];

	if (modalResult == JFormModalResult_CANCEL) return FALSE;

	return TRUE;
}

/**/
+ (BOOL) askApplyTo: (JWINDOW) aParent 
		applyTo: (char *) anApplyTo 
		title: (char *) aTitle
		description: (char *) aDescription
{
	JFORM form;
	JFormModalResult modalResult;

	// Solicito el apply to
	form = [JSimpleTextForm createForm: aParent];
	[form setWidth: 15];
	[form setTitle: aTitle];
	[form setDescription: aDescription];

	if ([[CimGeneralSettings getInstance] getApplyToOpMode] == KeyPadOperationMode_NUMERIC)
		[form setNumericMode: TRUE]; 

	if ([[CimGeneralSettings getInstance] getUseBarCodeReader])
		[form setScanningModeEnable: TRUE];

	modalResult = [form showModalForm];
	strcpy(anApplyTo, [form getTextValue]);
	[form free];

	if (modalResult == JFormModalResult_CANCEL) return FALSE;

	return TRUE;
}

/**/
+ (BOOL) canMakeDeposits: (JWINDOW) aParent
{
	if ([SafeBoxHAL getHardwareSystemStatus] == HardwareSystemStatus_SECONDARY) {
		[JMessageDialog askOKMessageFrom: aParent 
			withMessage: getResourceStringDef(RESID_ERROR_PRIMARY_HARD, "Error: Falla en hardware primario!")];
		return FALSE;
	}

	if ([SafeBoxHAL getPowerStatus] == PowerStatus_BACKUP) {
		[JMessageDialog askOKMessageFrom: aParent 
			withMessage: getResourceStringDef(RESID_ERROR_POWER_DOWN, "Error: Energia baja!")];
		return FALSE;
	}

	return TRUE;
}

/**/
+ (BOOL) canMakeDeposits
{
	if ([SafeBoxHAL getHardwareSystemStatus] == HardwareSystemStatus_SECONDARY)
		return FALSE;

	if ([SafeBoxHAL getPowerStatus] == PowerStatus_BACKUP)
		return FALSE;

	return TRUE;
}

/**/
+ (BOOL) canMakeExtractions: (JWINDOW) aParent
{

	if ([SafeBoxHAL getPowerStatus] == PowerStatus_BACKUP) {
		[JMessageDialog askOKMessageFrom: aParent 
			withMessage: getResourceStringDef(RESID_ERROR_POWER_DOWN, "Error: Energia baja!")];
		return FALSE;
	}

	return TRUE;
}

+ (char *) getDepositName: (int) depositType
{
  switch (depositType)
  {
      case DepositValueType_UNDEFINED: 
          return getResourceStringDef(RESID_NOT_DEFINE_VAL, "NO DEFINIDO");
      case DepositValueType_VALIDATED_CASH: 
          return getResourceStringDef(RESID_CASH_VAL, "EFECTIVO");
      case DepositValueType_MANUAL_CASH: 
          return getResourceStringDef(RESID_CASH_VAL, "EFECTIVO");
      case DepositValueType_CHECK: 
          return getResourceStringDef(RESID_CHECK_VAL, "CHEQUES");
      case DepositValueType_BOND: 
          return getResourceStringDef(RESID_TICKET_VAL, "TICKETS");
      case DepositValueType_CREDIT_CARD: 
          return getResourceStringDef(RESID_CUPONS_VAL, "CUPONES");
      case DepositValueType_OTHER: 
          return getResourceStringDef(RESID_OTHER_VAL, "OTRO");
      case DepositValueType_BOOKMARK: 
          return getResourceStringDef(RESID_BOOKMARK_VAL, "BOOKMARK");
  }

	return NULL;
}

/**/
+ (BOOL) overrideDoor: (JWINDOW) aParent door: (DOOR) aDoor secondaryHardwareMode: (BOOL) aSecondaryHardwareMode
{
	JFORM form;
	datetime_t dateTime;
	char verificationCode[20];
	struct tm brokenTime;
	JFormModalResult modalResult;

	// Door Override
	form = [JDoorOverrideForm createForm: NULL];
	dateTime = [SystemTime getLocalTime];
	[SystemTime decodeTime: dateTime brokenTime: &brokenTime];
	genVerifCode(&brokenTime, verificationCode);
	[form setDateTime: dateTime];
	[form setVerificationCode: verificationCode];
	[form setDoor: aDoor];
	[form setSecondaryHardwareMode: aSecondaryHardwareMode];
	modalResult = [form showModalForm];
	[form free];

	if (modalResult == JFormModalResult_CANCEL) return FALSE;

	return TRUE;
}

/**/
+ (BOOL) overrideDoor: (JWINDOW) aParent door: (DOOR) aDoor
{
	return [self overrideDoor: aParent door: aDoor secondaryHardwareMode: FALSE];
}

+ (char *) getExceptionDescription: (char *) aResult 
	exceptionCode: (int) anExceptionCode 
	exceptionName: (char *) anExceptionName
{
	char myExceptionDescription[512];

	TRY
		
		[[MessageHandler getInstance] processMessage: myExceptionDescription 
																	messageNumber: anExceptionCode];
																	
		snprintf(aResult, JComponent_MAX_LEN, myExceptionDescription);
	
	CATCH
		
		snprintf(aResult, JComponent_MAX_LEN, "Exception: %d! %s", anExceptionCode, anExceptionName);
	
	END_TRY

	return aResult;
}

/**/
+ (void) hardwareFailure: (JWINDOW) aParent 
	hardwareSystemStatus: (HardwareSystemStatus) aHardwareSystemStatus
	primaryMemoryStatus: (MemoryStatus) aPrimaryMemoryStatus
	secondaryMemoryStatus: (MemoryStatus) aSecondaryMemoryStatus
{
	char exdesc[JComponent_MAX_LEN+1];
	JSECONDARY_USER_LOGIN_FORM loginForm;
	char personalId[50];
	char password[50];
	char mac[100];
	char buf[100];
	JFORM processForm;

	[[Buzzer getInstance] buzzerBeep: 3000];

	[MessageHandler newWithDefaultLanguage: ENGLISH];

	// La auditoria la genero de esta manera para evitar que cargue las supervisiones
	if ([Persistence getInstance]) {
		[[[Persistence getInstance] getAuditDAO] storeAudit: Event_PRIMARY_HARDWARE_FAILURE userId: 0
			date: [SystemTime getLocalTime] station: 0 additional: "" systemType: SystemType_CIM];
	}

	// Agrego el dispositivo LOCKER0 para poder manejarlo
	[SafeBoxHAL addDevice: LOCKER0 deviceType: DeviceType_LOCKER object: NULL];

	// Muestro el mensaje de hardware secundario
	if (aPrimaryMemoryStatus == MemoryStatus_FAILURE) {
		[JMessageDialog askOKMessageFrom: NULL 
			withMessage: getResourceStringDef(RESID_PRIMARY_MEMORY_FAILURE, "Primary memory failure!")];
	}

	// Muestro el mensaje de hardware secundario
	if (aSecondaryMemoryStatus == MemoryStatus_FAILURE) {
		[JMessageDialog askOKMessageFrom: NULL 
			withMessage: getResourceStringDef(RESID_SECONDARY_MEMORY_FAILURE, "Secondary memory failure!")];
	}

	if (aHardwareSystemStatus == HardwareSystemStatus_SECONDARY) {
		// Muestro el mensaje de hardware secundario
		[JMessageDialog askOKMessageFrom: NULL 
				withMessage: getResourceStringDef(RESID_CURRENTLY_USING_SECONDARY_HARDWARE, "Currently using secondary hardware!")];
	}

	// Si estoy en primario y la memoria primaria me fallo
	if (aHardwareSystemStatus == HardwareSystemStatus_PRIMARY && 
			 aPrimaryMemoryStatus == MemoryStatus_FAILURE &&
			 aSecondaryMemoryStatus == MemoryStatus_OK) {
		// Muestro el mensaje de hardware secundario
		[JMessageDialog askOKMessageFrom: NULL 
				withMessage: "Connect to secondary hardware to Open Door!"];
	}

	// Si estoy en primario y la memoria primaria me fallo
	if (aPrimaryMemoryStatus == MemoryStatus_FAILURE &&
			aSecondaryMemoryStatus == MemoryStatus_FAILURE) {
		// Muestro el mensaje de hardware secundario
		[JMessageDialog askOKMessageFrom: NULL 
				withMessage: getResourceStringDef(RESID_SEVERY_HARDWARE_DAMAGE, "Severe hardware damage! Contact support!")];
	}

	if (aHardwareSystemStatus == HardwareSystemStatus_PRIMARY) {

		[JMessageDialog askOKMessageFrom: NULL 
				withMessage: "Press OK to reset the SafeBox!"];

	  processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];

		// Audita el apagado del equipo
		// La auditoria la genero de esta manera para evitar que cargue las supervisiones
		if ([Persistence getInstance]) {
			[[[Persistence getInstance] getAuditDAO] storeAudit: Event_SYSTEM_SHUTDOWN userId: 0
				date: [SystemTime getLocalTime] station: 0 additional: "" systemType: SystemType_CIM];
		}

		[[PowerFailManager getInstance] stop];

		// Se queda clavado aca esperando hasta que se apague
		while (TRUE) {

			[SafeBoxHAL shutdown];
			msleep(10000);
		
		}

	}

	// obtengo la mac
	get_mac(mac);

	// Espera hasta que ingrese un codigo de override correcto
	while (TRUE) {
		sprintf(buf, "MAC Address: %s", mac);
		[JMessageDialog askOKMessageFrom: NULL withMessage: buf];
		if ([UICimUtils overrideDoor: self door: NULL secondaryHardwareMode: TRUE]) break;
	}

	while (TRUE) {

	//	doLog(0,"User Login...\n");

		// Selecciona el usuario (pero no lo valida ni nada)
		loginForm = [JSecondaryUserLoginForm createForm: NULL];
		[loginForm setCanGoBack: FALSE];
		[loginForm setValidateLogin: FALSE];
		[loginForm showModalForm];
		stringcpy(personalId, [loginForm getPersonalId]);
		stringcpy(password, [loginForm getPassword]);
		[loginForm free];

		//doLog(0,"User with ID = %s\n", personalId);
		
		TRY

			if ([Persistence getInstance]) {
				[[[Persistence getInstance] getAuditDAO] storeAudit: Event_DOOR_UNLOCK userId: 0
					date: [SystemTime getLocalTime] station: LOCKER0 additional: personalId systemType: SystemType_CIM];
			}

			// UnLock de la puerta
			[SafeBoxHAL unLock: LOCKER0 personalId: personalId password: password];

			[JMessageDialog askOKMessageFrom: NULL withMessage: getResourceStringDef(RESID_OPEN_DOOR_NOW, "Abrir puerta ahora!")];

		CATCH

			if ([Persistence getInstance]) {
				[[[Persistence getInstance] getAuditDAO] storeAudit: Event_DOOR_UNLOCK_ERROR userId: 0
					date: [SystemTime getLocalTime] station: LOCKER0 additional: personalId systemType: SystemType_CIM];
			}

			// Error de Unlock en la puerta
			if (ex_get_code() == CIM_USR_NOT_EXISTS_EX ||
					ex_get_code() == CIM_USR_BAD_PASSWORD_EX ||
					ex_get_code() == CIM_USER_DEVID_NOT_ALLOWED_EX) {
				[JMessageDialog askOKMessageFrom: NULL 
						withMessage: getResourceStringDef(RESID_PASSWORD_INCORRECT, "USUARIO O CLAVE INCORRECTO")];
			} else {
				[UICimUtils getExceptionDescription: exdesc exceptionCode: ex_get_code() exceptionName: ex_get_name()];
				[JMessageDialog askOKMessageFrom: NULL withMessage: exdesc];
			}

		END_TRY

	}

}

/**/
+ (int) selectExtendedDropAction: (JWINDOW) aParent title: (char *) aTitle
{
  COLLECTION selection;
  id strViewDetail;
  id strFinish;
  id resultStr;
  int result;

  strViewDetail = [String str: getResourceStringDef(RESID_VIEW_DETAIL_LABEL, "Ver detalle")];
  strFinish = [String str: getResourceStringDef(RESID_FINISH_LABEL, "Elimin")];

  selection = [Collection new];
  
  [selection add: strViewDetail];
  [selection add: strFinish];

	resultStr = [UICimUtils selectFromCollection: aParent 
		collection: selection
		title: aTitle
		showItemNumber: TRUE];
  	
	if (resultStr == strViewDetail) result = 1;
	else if (resultStr == strFinish) result = 2;
	else result = 0;
		
	[strViewDetail free];
	[strFinish free];
	[selection free];

	return result;
}

/**/
+ (BOOL) askForPassword: (JWINDOW) aParent result: (char *) aBuffer title: (char *) aTitle message: (char *) aMessage
{
	JFormModalResult modalResult;
	JFORM form;

	form = [JSimpleTextForm createForm: aParent];
	[form setNumericMode: TRUE];
	[form setWidth: 8];
	[form setPasswordMode: TRUE];
	[form setTitle: aTitle];
	[form setDescription: aMessage];
	[form setTextValue: ""];
	modalResult = [form showModalForm];
	strcpy(aBuffer, [form getTextValue]);
	[form free];

	return modalResult == JFormModalResult_OK;
}

/**/
+ (BackupType) selectBackupType: (JWINDOW) aParent title: (char *) aTitle
{
  COLLECTION selection;
  id strAll;
  id strTransactions;
	id strSettings;
	id strUsers;
  id resultStr;
  int result;

  strAll = [String str: getResourceStringDef(RESID_ALL_BACKUP_LABEL, "All")];
  strTransactions = [String str: getResourceStringDef(RESID_TRANSACTIONS_BACKUP_LABEL, "Transactions")];
	strSettings = [String str: getResourceStringDef(RESID_SETTINGS_BACKUP_LABEL, "Settings")];
	strUsers = [String str: getResourceStringDef(RESID_USERS_BACKUP_LABEL, "Users")];
        
  selection = [Collection new];
  
  [selection add: strAll];
  [selection add: strTransactions];
	[selection add: strSettings];
	[selection add: strUsers];

	resultStr = [UICimUtils selectFromCollection: aParent 
		collection: selection
		title: aTitle
		showItemNumber: TRUE];
  	
	if (resultStr == strAll) result = BackupType_ALL;
	else if (resultStr == strTransactions) result = BackupType_TRANSACTIONS;
	else if (resultStr == strSettings) result = BackupType_SETTINGS;
	else if (resultStr == strUsers) result = BackupType_USERS;
	else result = BackupType_UNDEFINED;
		
	[strAll free];
	[strTransactions free];
	[strSettings free];
	[strUsers free];
	[selection free];

	return result;
}

/**/
+ (BackupType) selectRestoreType: (JWINDOW) aParent title: (char *) aTitle
{
  COLLECTION selection;
  id strAll;
  id strTransactions;
	id strSettings;
	id strUsers;
  id resultStr;
  int result;

  strAll = [String str: getResourceStringDef(RESID_ALL_BACKUP_LABEL, "All")];
	strTransactions = [String str: getResourceStringDef(RESID_TRANSACTIONS_BACKUP_LABEL, "Transactions")];
	strSettings = [String str: getResourceStringDef(RESID_SETTINGS_BACKUP_LABEL, "Settings")];
	strUsers = [String str: getResourceStringDef(RESID_USERS_BACKUP_LABEL, "Users")];
  selection = [Collection new];
  
  [selection add: strAll];

	// si viene de un restore fallido solo le muestro la opcion all
	if (![[CimBackup getInstance] isRestoreFailure]) {
		[selection add: strTransactions];
		[selection add: strSettings];
		[selection add: strUsers];
	}

	resultStr = [UICimUtils selectFromCollection: aParent 
		collection: selection
		title: aTitle
		showItemNumber: TRUE];
  	
	if (resultStr == strAll) result = RestoreType_ALL;
	else if (resultStr == strTransactions) result = RestoreType_TRANSACTIONS;
	else if (resultStr == strSettings) result = RestoreType_SETTINGS;
	else if (resultStr == strUsers) result = RestoreType_USERS;
	else result = RestoreType_UNDEFINED;
		
	[strAll free];
	[strTransactions free];
	[strSettings free];
	[strUsers free];
	[selection free];

	return result;
}

@end
