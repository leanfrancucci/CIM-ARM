#include "JCimCashListForm.h"
#include "SettingsExcepts.h"
#include "TelesupDefs.h"
#include "MessageHandler.h"
#include "CimManager.h"
#include "Cim.h"
#include "JCimCashEditForm.h"
#include "JExceptionForm.h"

#define printd(args...) //doLog(0,args)
//#define printd(args...)

@implementation  JCimCashListForm

/**/
- (void) onConfigureForm
{
	/**/
	[self setAllowNewInstances: TRUE];
	[self setNewInstancesItemCaption: getResourceStringDef(RESID_NEW_CASH_OP, "Nueva cash")];
	
	[self setAllowDeleteInstances: TRUE];
	[self setConfirmDeleteInstances: TRUE];
	
	[self addItemsFromCollection: [[[CimManager getInstance] getCim] getCimCashs]];	
}


/**/
- (id) onNewInstance
{
	JFORM form;
	id cimCash = NULL;		

	form = [JCimCashEditForm createForm: self];

	TRY
	
		cimCash = [CimCash new];

		[form showFormToEdit: cimCash];

		if ([form getModalResult] == JFormModalResult_OK) {

		}
			//[[[CimManager getInstance] getCim] addCimCash: cimCash];
		else {
			[cimCash free];	
			cimCash = NULL;
		}
	
	FINALLY

		[form free];

	END_TRY

	return cimCash;
}


/**/
- (void) onSelectInstance: (id) anInstance
{
	JFORM form;
	
	form = [JCimCashEditForm createForm: self];
	[form setDepositTypeReadOnly];

	TRY
		
		[form showFormToView: anInstance];
		
	FINALLY

		[form free];

	END_TRY
}


/**/
- (void) onDeleteInstance: (id) anInstance
{
  JFORM processForm = NULL;

  TRY
    processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];
      
	  [[[CimManager getInstance] getCim] removeCashBox: [anInstance getCimCashId]];
    
    [processForm closeProcessForm];
    [processForm free];
    
  CATCH
  
    [processForm closeProcessForm];
    [processForm free];
    RETHROW();
        
  END_TRY
}	

/**/
- (char *) getDeleteInstanceMessage: (char *) aMessage toSave: (id) anInstance
{
	snprintf(aMessage, JCustomForm_MAX_MESSAGE_SIZE, getResourceStringDef(RESID_DELETE_MSSG, "Eliminar %s"), [anInstance str]);
	return aMessage;
}

/**/
- (char *) getCaption1
{
	return getResourceStringDef(RESID_BACK_KEY, "atras");
}

/**/
- (char *) getCaptionX
{
	if ([self canDeleteInstanceOnSelection])
		return getResourceStringDef(RESID_DELETE_KEY, "borrar");
	else
		return [super getCaptionX];
}

/**/
- (char *) getCaption2
{
	if (![self canInsertNewInstanceOnSelection])			
		return getResourceStringDef(RESID_UPDATE_KEY, "modif.");

	return [super getCaption2];
}
@end

