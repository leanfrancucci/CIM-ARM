#include "JCommercialStateChangeForm.h"
#include "util.h"
#include "MessageHandler.h"
#include "system/util/all.h"
#include "JMessageDialog.h"
#include "CommercialState.h"
#include "CommercialStateMgr.h"
#include "SystemTime.h"
#include "UICimUtils.h"
#include "JCommercialStCodeForm.h"
#include "JSimpleTextForm.h"
#include "TelesupDefs.h"
#include "TelesupervisionManager.h"
#include "JIncomingTelTimerForm.h"
#include "Acceptor.h"
#include "JSimpleDateForm.h"
#include "TelesupScheduler.h"
#include "TelesupervisionManager.h"
#include "TelesupDefs.h"
#include "JExceptionForm.h"
#include "Audit.h"
#include "UserManager.h"
#include "CimManager.h"
#include "JDoorStateForm.h"

#define printd(args...)// doLog(0,args)
//#define printd(args...)


@implementation  JCommercialStateChangeForm

- (BOOL) openDoor;
- (BOOL) systemHasPendingExtractions;

/**/
static int getStateTypeByIndex(int stateIndex)
{
	id currentState = [[CommercialStateMgr getInstance] getCurrentCommercialState];
 
	if ([currentState getCommState] == SYSTEM_TEST_PIMS) {
		switch (stateIndex) {
		  case 0: return SYSTEM_FACTORY_BLOCKED; break;
		  case 1: return SYSTEM_PRODUCTION_PIMS; break;
		  case 2: return SYSTEM_TEST_STAND_ALONE; break;
		}
	}

	if ([currentState getCommState] == SYSTEM_PRODUCTION_PIMS) {
		switch (stateIndex) {
	  	case 0: return SYSTEM_FACTORY_BLOCKED; break;
			case 1: return SYSTEM_PRODUCTION_STAND_ALONE; break;
		}
	}

	if ([currentState getCommState] == SYSTEM_TEST_STAND_ALONE) {
		switch (stateIndex) {
		  case 0: return SYSTEM_FACTORY_BLOCKED; break;
		  case 1: return SYSTEM_PRODUCTION_STAND_ALONE; break;
			case 2: return SYSTEM_TEST_PIMS; break;
			case 3: return SYSTEM_PRODUCTION_PIMS; break;
		}
	}

	if ([currentState getCommState] == SYSTEM_PRODUCTION_STAND_ALONE) {
		switch (stateIndex) {
		  case 0: return SYSTEM_FACTORY_BLOCKED; break;
			case 1: return SYSTEM_PRODUCTION_PIMS; break;
		}
	}

	return SYSTEM_NOT_DEFINED;
}


/**/
- (void) addStateItems
{
	char msg[100];
	id currentState = [[CommercialStateMgr getInstance] getCurrentCommercialState];

	switch ([currentState getCommState]) {
	
		case SYSTEM_TEST_PIMS:
			sprintf(msg,"%s: %s",getResourceStringDef(RESID_CURRENT_STATE, "Estado actual"), getResourceStringDef(RESID_SYSTEM_TEST_PIMS, "PRUEBA PIMS"));
			[JMessageDialog askOKMessageFrom: self withMessage: msg];

			[myComboState addString: getResourceStringDef(RESID_SYSTEM_FACTORY_BLOCKED, "BLOQUEO FABRICA")];
			[myComboState addString: getResourceStringDef(RESID_SYSTEM_PRODUCTION_PIMS, "PRODUCCION PIMS")];
			[myComboState addString: getResourceStringDef(RESID_SYSTEM_TEST_STAND_ALONE, "PRUEBA STANDALONE")];
			break;

		case SYSTEM_PRODUCTION_PIMS:
			sprintf(msg,"%s: %s",getResourceStringDef(RESID_CURRENT_STATE, "Estado actual"), getResourceStringDef(RESID_SYSTEM_PRODUCTION_PIMS, "PRODUCCION PIMS"));
			[JMessageDialog askOKMessageFrom: self withMessage: msg];

			[myComboState addString: getResourceStringDef(RESID_SYSTEM_FACTORY_BLOCKED, "BLOQUEO FABRICA")];
			[myComboState addString: getResourceStringDef(RESID_SYSTEM_PRODUCTION_STAND_ALONE, "PRODUCC ST ALONE")];
			break;

		case SYSTEM_TEST_STAND_ALONE:
			sprintf(msg,"%s: %s",getResourceStringDef(RESID_CURRENT_STATE, "Estado actual"), getResourceStringDef(RESID_SYSTEM_TEST_STAND_ALONE, "PRUEBA ST ALONE"));
			[JMessageDialog askOKMessageFrom: self withMessage: msg];

			[myComboState addString: getResourceStringDef(RESID_SYSTEM_FACTORY_BLOCKED, "BLOQUEO FABRICA")];
			[myComboState addString: getResourceStringDef(RESID_SYSTEM_PRODUCTION_STAND_ALONE, "PRODUCC ST ALONE")];
			[myComboState addString: getResourceStringDef(RESID_SYSTEM_TEST_PIMS, "PRUEBA PIMS")];
			[myComboState addString: getResourceStringDef(RESID_SYSTEM_PRODUCTION_PIMS, "PRODUCCION PIMS")];
			break;

		case SYSTEM_PRODUCTION_STAND_ALONE:
			sprintf(msg,"%s: %s",getResourceStringDef(RESID_CURRENT_STATE, "Estado actual"), getResourceStringDef(RESID_SYSTEM_PRODUCTION_STAND_ALONE, "PRODUCC ST ALONE"));
			[JMessageDialog askOKMessageFrom: self withMessage: msg];

			[myComboState addString: getResourceStringDef(RESID_SYSTEM_FACTORY_BLOCKED, "BLOQUEO FABRICA")];
			[myComboState addString: getResourceStringDef(RESID_SYSTEM_PRODUCTION_PIMS, "PRODUCCION PIMS")];
			break;

		default:
			sprintf(msg,"%s: %s",getResourceStringDef(RESID_CURRENT_STATE, "Estado actual"), getResourceStringDef(RESID_SYSTEM_NOT_DEFINED, "NO DEFINIDO"));
			[JMessageDialog askOKMessageFrom: self withMessage: msg];
			break;

	}
}

/**/
- (void) onCreateForm
{
	[super onCreateForm];
	
	myDate = [SystemTime getLocalTime];

	// creo un nuevo estado comercial
	myCommercialState = [CommercialState new];
	[myCommercialState setCommState: [[[CommercialStateMgr getInstance] getCurrentCommercialState] getCommState]];

	// Nuevo Estado comercial
	myLabelState = [JLabel new];
	[myLabelState setCaption: getResourceStringDef(RESID_SYSTEM_SELECT_COMMERCIAL_STATE, "Seleccione Estado:")];
	[self addFormComponent: myLabelState];

	myComboState = [JCombo new];
	[self addStateItems];
	[self addFormComponent: myComboState];
	
}

/**/
- (void) onMenu1ButtonClick
{
	//if (myCommercialState) [myCommercialState free];
	[self closeForm];
}

/**/
- (char*) getCaption1
{
	  return getResourceStringDef(RESID_CANCEL_KEY, "Cancelar");
}

/**/
- (char*) getCaptionX
{
   return NULL;
}

/**/
- (char*) getCaption2
{
	 return getResourceStringDef(RESID_NEXT_KEY, "sig.");
}

/**/
- (void) onMenu2ButtonClick
{
  id telesup;
	id telesupScheduler;
  JFORM processForm = NULL;
	BOOL openDoorResult = FALSE;
	id commercialStateMgr = [CommercialStateMgr getInstance];
	BOOL needsAuthentication;
	BOOL telesupError = FALSE;
	BOOL viewSuccessfullyMsg = TRUE;
	char msg[35];
	char completeMsg[61];

	myNewState = getStateTypeByIndex([myComboState getSelectedIndex]);

	// seteo el nuevo estado comercial
  [myCommercialState setNextCommState: myNewState];

	// verifica si en el estado del sistema se puede cambiar el estado comercial
	sprintf(completeMsg, "%s ",getResourceStringDef(RESID_CANNOT_CHANGE_STATE_VERIFY_SYSTEM, "No puede cambiar el estado."));
	msg[0] = '\0';
	if (![commercialStateMgr canChangeState: [myCommercialState getNextCommState] msg: msg]) {
			strcat(completeMsg, msg);
   		[JMessageDialog askOKMessageFrom: self withMessage: completeMsg];
   		return;
	}

	// verifica si el cambio de estado requiere autorizacion del sistema remoto
	needsAuthentication = [commercialStateMgr needsAuthentication: [myCommercialState getNextCommState]];

	// si no necesita autenticacion del sistema remoto ...
	if (!needsAuthentication) {

  	TRY

			if ([myCommercialState getNextCommState] == SYSTEM_FACTORY_BLOCKED) {

				// indico que no se debe mostrar el mensaje de exito de cambio de estado
				viewSuccessfullyMsg = FALSE;

				if ([self systemHasPendingExtractions]) {
					[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_PENDING_EXTRACTIONS, "No es posible. Extracciones pendientes.")];
					EXIT_TRY;
					return;
				}

				if ([JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_DATA_IS_GOING_TO_BE_DELETED, "Se borraran todos los datos, desea continuar?")] == JDialogResult_NO) {
					EXIT_TRY;
					return;
				}


				telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];
	
				if (telesup) {

					if ([[TelesupScheduler getInstance] inTelesup]) {

						[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_SUPERVITION_RUNNING, "Ya existe una supervision en curso.")];
						telesupError = TRUE;

					} else {

						if ([[CommercialStateMgr getInstance] canExecutePimsSupervision]) {
			
							[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_SYSTEM_WILL_TELESUP, "Se llevara a cabo una supervision...")];
							[[TelesupScheduler getInstance] startTelesup: telesup];

							if (strlen([[TelesupScheduler getInstance] getErrorInTelesupMsg]) != 0) 
								telesupError = TRUE;

						} else telesupError = TRUE;
					}
				} else telesupError = TRUE;

				// si no pudo supervizar pregunto al usuario si desea continuar.
				if (telesupError) {
					if ([JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_SUPERVISION_ERROR_QUESTION, "Error en supervision, desea continuar?")] != JDialogResult_YES) {
						EXIT_TRY;
						return;
					}
				}

				[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_DOOR_ACCESS_PROCESS, "Comienzo proceso apertura de puerta, logueese...")];

				//abre la puerta para poder cambiar de estado	
				openDoorResult = [self openDoor];

				// si no la abre no puede hacer nada
				if (!openDoorResult) {
					[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_THE_DOOR_WAS_NOT_OPENED, "No se realizo la apertura de puerta correctamente.")];
					EXIT_TRY;
					return;
				}

			}

			if ( (([myCommercialState getCommState] == SYSTEM_TEST_STAND_ALONE) && ([myCommercialState getNextCommState] == SYSTEM_PRODUCTION_STAND_ALONE)) ||
					 (([myCommercialState getCommState] == SYSTEM_TEST_STAND_ALONE) && ([myCommercialState getNextCommState] == SYSTEM_PRODUCTION_PIMS)) ||
					 (([myCommercialState getCommState] == SYSTEM_TEST_PIMS) && ([myCommercialState getNextCommState] == SYSTEM_PRODUCTION_PIMS)) ) {
						// indico que no se debe mostrar el mensaje de exito de cambio de estado
						viewSuccessfullyMsg = FALSE;
			}

			// LA AUDITORIA DEBERIA LOGUEAR EL CAMBIO ???
			[Audit auditEventCurrentUser: Event_MANUAL_STATE_CHANGE_INTENTION additional: "" station: 0 logRemoteSystem: FALSE];

			processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];

			// aplico el cambio de estado
			[[CommercialStateMgr getInstance] doChangeCommercialState: myCommercialState];

    	[processForm closeProcessForm];
    	[processForm free];


			if (viewSuccessfullyMsg)
				[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_CHANGE_COMMERCIAL_STATE_OK, "El estado comercial fue cambiado con exito!!!")];

  //  	[myCommercialState free];
			[[CommercialStateMgr getInstance] changeSystemStatus];

  	CATCH
  
//			[Audit auditEventCurrentUser: Event_MANUAL_CHANGE_ERROR additional: "" station: 0 logRemoteSystem: FALSE]; 			
    	if (processForm) {
				[processForm closeProcessForm];
    		[processForm free];
			}

    	RETHROW();
        
  	END_TRY

	} else { // si necesita autenticacion del sistema remoto

		telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];

		if (!telesup) {
			if ([JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_UNDEFINED, "No existe una supervision configurada")]) 
				return;			
		}

		telesupScheduler = [TelesupScheduler getInstance];

		if ([telesupScheduler inTelesup]) {
   		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_TELESUP_IN_PROGRESS, "Supervision en curso.")];
   		return;
		}

		[[CommercialStateMgr getInstance] setPendingCommercialStateChange: myCommercialState];
		[telesupScheduler setCommunicationIntention: CommunicationIntention_CHANGE_STATE_REQUEST];

		// auditoria intento de supervision por pims
		[Audit auditEventCurrentUser: Event_PIMS_STATE_CHANGE_INTENTION additional: "" station: 0 logRemoteSystem: FALSE]; 			

		[telesupScheduler startTelesup: telesup];
	}


	[self closeForm];

}

/**/ 
- (BOOL) openDoor
{
	COLLECTION autoDoors = [[[CimManager getInstance] getCim] getAutoCimCashs];
	id door = [[autoDoors at: 0] getDoor];
	EXTRACTION_WORKFLOW extractionWorkflow = NULL;
	USER user;
	USER myLoggedUser;
	PROFILE profile;
	id form;                                                                                              

	extractionWorkflow = [[CimManager getInstance] getExtractionWorkflowForDoor: door];

	// Controlo si puede abrir la puerta dado el Time Lock correspondiente
	if ([extractionWorkflow getCurrentState] == OpenDoorStateType_IDLE) {

		myLoggedUser = [[UserManager getInstance] getUserLoggedIn];
    profile = [[UserManager getInstance] getProfile: [myLoggedUser getUProfileId]];

	}

	// Pregunta si desea remover el dinero
	if ([extractionWorkflow getCurrentState] == OpenDoorStateType_IDLE ||
			[extractionWorkflow getCurrentState] == OpenDoorStateType_ACCESS_TIME) {
		[extractionWorkflow setGenerateExtraction: FALSE];
	}

	[extractionWorkflow removeLoggedUsers];

	// Va a pedir el login de usuario tantas veces como haga falta
	// o hasta que el usuario presione el boton "back" con lo cual
	// cancela todo el proceso de login
	while ([extractionWorkflow getCurrentState] == OpenDoorStateType_IDLE ||
		[extractionWorkflow getCurrentState] == OpenDoorStateType_ACCESS_TIME ||
		[extractionWorkflow getCurrentState] == OpenDoorStateType_LOCK_AND_OPEN_DOOR ||
		[extractionWorkflow getCurrentState] == OpenDoorStateType_WAIT_CLOSE_DOOR ||
		[extractionWorkflow getCurrentState] == OpenDoorStateType_WAIT_CLOSE_DOOR_WARNING ||
		[extractionWorkflow getCurrentState] == OpenDoorStateType_WAIT_CLOSE_DOOR_ERROR ||
		[extractionWorkflow getCurrentState] == OpenDoorStateType_OPEN_DOOR_VIOLATION) {

		user = [UICimUtils validateUser: self];

		if (user == NULL) {
			[extractionWorkflow removeLoggedUsers];
			[extractionWorkflow setGenerateExtraction: FALSE];
			return FALSE;
		} 

		TRY
			[extractionWorkflow forceTimeDelayOverride: TRUE];
			[extractionWorkflow onLoginUser: user];
		CATCH
			[self showDefaultExceptionDialogWithExCode: ex_get_code()];
			[extractionWorkflow removeLoggedUsers];
			[extractionWorkflow setGenerateExtraction: FALSE];
			return FALSE;
		END_TRY

	}

	// Muestro el estado de la puerta
	form = [JDoorStateForm createForm: self];
	[form setExtractionWorkflow: extractionWorkflow];
	[form setOpenDoorForCommercialChange: TRUE];
	[form showModalForm];
	[form free];

	if ([extractionWorkflow getCurrentState] != OpenDoorStateType_WAIT_CLOSE_DOOR) {

		// TODO poner que no se realizo la apertura de puerta y no s epuede cambiar el estado 
		return FALSE;
	}

	//doLog(0,"esta la puerta abierta!\n");
	return TRUE;

}

/**/
- (BOOL) systemHasPendingExtractions
{	
	int i;
	COLLECTION doors = [[[CimManager getInstance] getCim] getDoors];
	id currentExtraction;

	for (i=0; i<[doors size]; ++i) {
		currentExtraction = [[ExtractionManager getInstance] getCurrentExtraction: [doors at: i]];

		if ([currentExtraction getTotalAmount: NULL] > 0) return TRUE;

	}

	return FALSE;	
}

@end
