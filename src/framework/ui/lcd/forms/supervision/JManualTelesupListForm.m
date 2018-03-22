#include "JManualTelesupListForm.h"
#include "TelesupervisionManager.h"
#include "JTelesupTypesListForm.h"
#include "ConnectionSettings.h"
#include "TelesupScheduler.h"
#include "CtSystem.h"
#include "JMessageDialog.h"
#include "TelesupDefs.h"
#include "system/printer/all.h"
#include "MessageHandler.h"
#include "JIncomingTelTimerForm.h"
#include "Acceptor.h"
#include "UserManager.h"
#include "JSimpleTimerLockForm.h"
#include "Audit.h"
#include "CimGeneralSettings.h"
#include "CommercialStateMgr.h"

#define printd(args...)// doLog(0,args)
//#define printd(args...)

static char *_caption2 = "superv";

@implementation  JManualTelesupListForm

/**/
- (void) onConfigureForm
{
  COLLECTION allTelesups;
  COLLECTION telesups;
  id telesup;
  id user;
  id profile;
  int i;

	/**/
	[self setAllowNewInstances: FALSE];
	[self setAllowDeleteInstances: FALSE];

  // tarigo el usuario logueado para ver los permisos que tiene
  user = [[UserManager getInstance] getUserLoggedIn];
  profile = [[UserManager getInstance] getProfile: [user getUProfileId]];

  // tarigo todas las telesup
  allTelesups = [[TelesupervisionManager getInstance] getTelesups];
  
  // cargo solo las telesups que puede ver de acuerdo a los permisos que posea
  telesups = [Collection new];

  for (i=0; i < [allTelesups size]; ++i) {
    
    telesup = [allTelesups at: i];
    
    // si es CMP telesup me fijo si tiene el permiso para supervisar a CMP
    if (([telesup getTelcoType] == CMP_TSUP_ID) || ([telesup getTelcoType] == CMP_OUT_TSUP_ID)) {
      if ([profile hasPermission: CMP_TELESUP_OP])
        [telesups add: telesup];
    } else {
      if ([profile hasPermission: SUPERVISION_OP])
        [telesups add: telesup];
    }

  }

	[self addItemsFromCollection: telesups];	

	// libera la coleccion
	[telesups free];
}

/**/
- (char*) getCaption2
{
	return getResourceStringDef(RESID_SUPERV, _caption2);
}

/**/
- (void) onSelectInstance: (id) anInstance
{
	id form;
	int modalResult;

	int jobCount = [[PrinterSpooler getInstance] getJobCount];

	//
	if ([anInstance getTelcoType] == CMP_TSUP_ID) {

		if ([JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_ENABLED_INCOMING_SUP_QUESTION, "Habilitar supervision entrante?")]  == JDialogResult_YES)  {
	
			[[Acceptor getInstance] acceptIncomingSupervision: TRUE];	 
		
			form = [JIncomingTelTimerForm createForm: self];
			[form setTimeout: [[Configuration getDefaultInstance] getParamAsInteger: "INCOMING_SUPERVISION_TIMEOUT"]];

			[form setTitle: getResourceStringDef(RESID_WAITING_INCOMING_SUPERV_MSG, "Esperando supervision entrante...")];

			[form setCanCancel: TRUE];
			[form setShowTimer: TRUE];
			[[Acceptor getInstance] setFormObserver: form];
			modalResult = [form showModalForm];
			[form free];
		
			//if (modalResult == JFormModalResult_YES) break;
			if (modalResult == JFormModalResult_CANCEL) 
				[[Acceptor getInstance] acceptIncomingSupervision: FALSE];	 		

			// si el intento de logueo es = 3 bloqueo el equipo
			if ([[Acceptor getInstance] getCantLoginFails] == 3){
        // llamo a la pantalla de bloqueo del equipo si supero los tres intentos de login
        [self lockSystem: [[CimGeneralSettings getInstance] getLockLoginTime]];      
      }
      // inicializo el contador en 0
      [[Acceptor getInstance] initCantLoginFails];
	
			return;

		}

		return;

	}

	// Si no tengo permiso porque esta mal la autorizacion, me voy
	if (([anInstance getTelcoType] == PIMS_TSUP_ID) && (![[CommercialStateMgr getInstance] canExecutePimsSupervision])) {		
   	[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_NO_AUT_FOR_TELESUP, "No posee autorizacion para realizar la supervision.")];
		return;
	}

	if ([[TelesupScheduler getInstance] inTelesup]) {		
   	[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_SUPERVITION_RUNNING, "Ya existe una supervision en curso.")];
		return;
	}

  if ([JMessageDialog askYesNoMessageFrom: self
	 			withMessage: getResourceStringDef(RESID_CONFIRM_SUPERVITION, "Confirma realizar la telesupervision?")]  == JDialogResult_NO)
    return;

	if (jobCount > 0) {
   	[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_PENDIND_PRINT_SUP, "Impresiones en curso. No se puede supervisar.")];
		return;
	}

	if ( [anInstance getTelcoType] == 1 ) {		// SAR II

		// Como todas las cabinas se encuentran inhabilitadas, es posible telesupervisar
	  [[CtSystem getInstance] shutdownSystem];
		exit(24);
	
	} else { // PIMS o CMP OUT

		[[TelesupScheduler getInstance] isManual: TRUE];
		[[TelesupScheduler getInstance] startTelesup: anInstance];

	}

	[self closeForm];

}

- (void) lockSystem: (int) aSeconds {
   JFORM form;
	 JFormModalResult modalResult;
	 
	 [Audit auditEvent: Event_WRONG_PIN_BLOCK additional: "" station: 0 logRemoteSystem: FALSE];
	 
   form = [JSimpleTimerLockForm createForm: self];
	 [form setTimeout: aSeconds];
	 [form setTitle: getResourceStringDef(RESID_LOCK_LOGIN_MSG, "Equipo Bloqueado!")];
	 [form setShowTimer: TRUE];
	 modalResult = [form showModalForm];
	 [form free];
}

/**/
- (char *) getDeleteInstanceMessage: (char *) aMessage toSave: (id) anInstance
{
	snprintf(aMessage, JCustomForm_MAX_MESSAGE_SIZE, getResourceStringDef(RESID_DELETE_MSSG, "Eliminar %s"), [anInstance str]);
	return aMessage;
}

@end

