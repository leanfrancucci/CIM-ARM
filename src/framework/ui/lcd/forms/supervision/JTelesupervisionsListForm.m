#include "JTelesupervisionsListForm.h"
#include "JTelesupervisionEditForm.h"
#include "TelesupervisionManager.h"
#include "JTelesupTypesListForm.h"
#include "ConnectionSettings.h"
#include "SettingsExcepts.h"
#include "TelesupDefs.h"
#include "MessageHandler.h"
#include "JExceptionForm.h"

#define printd(args...) //doLog(0,args)
//#define printd(args...)

@implementation  JTelesupervisionsListForm

/**/
- (void) onConfigureForm
{
	/**/
	[self setAllowNewInstances: TRUE];
	[self setNewInstancesItemCaption: getResourceStringDef(RESID_NEW_TELESUP, "Nueva")];
	
	[self setAllowDeleteInstances: TRUE];
	[self setConfirmDeleteInstances: TRUE];
	
	[self addItemsFromCollection: [[TelesupervisionManager getInstance] getTelesups]];	
}


/**/
- (id) onNewInstance
{
	volatile int error = 0;
	JFORM telesupTypeForm;
	JFORM telesupForm;
	volatile TELESUP_SETTINGS telesup;
	CONNECTION_SETTINGS connection;
	int telesupType;
	
	telesup = NULL;		
	telesupTypeForm = [	JTelesupTypesListForm createForm: self];
  
	TRY
	
		telesup = [TelesupSettings new];
		connection = [ConnectionSettings new];
		[telesup setConnection1: connection];
	
		[telesupTypeForm showModalForm];
		telesupType = [telesupTypeForm getSelectedTelesupType];
		[telesupTypeForm free];
		
		if ( telesupType != 0) {

			// Solo puede haber una supervision del tipo SAR II
			if (telesupType == SARII_TSUP_ID &&
					[[TelesupervisionManager getInstance] getTelesupByTelcoType: telesupType])
				THROW(ONLY_ONE_TELESUP_ALLOWED_EX);

			// Solo puede haber una supervision del tipo PIMS
			if (telesupType == PIMS_TSUP_ID &&
					[[TelesupervisionManager getInstance] getTelesupByTelcoType: telesupType])
				THROW(ONLY_ONE_TELESUP_ALLOWED_EX);

			// Solo puede haber una supervision del tipo CMP Out
			if (telesupType == CMP_OUT_TSUP_ID &&
					[[TelesupervisionManager getInstance] getTelesupByTelcoType: telesupType])
				THROW(ONLY_ONE_TELESUP_ALLOWED_EX);

			// Solo puede haber una supervision del tipo POS
			if (telesupType == POS_TSUP_ID &&
					[[TelesupervisionManager getInstance] getTelesupByTelcoType: telesupType])
				THROW(ONLY_ONE_TELESUP_ALLOWED_EX);

			if (telesupType == FTP_SERVER_TSUP_ID &&
					[[TelesupervisionManager getInstance] getTelesupByTelcoType: telesupType])
				THROW(ONLY_ONE_TELESUP_ALLOWED_EX);

			// Solo puede haber una supervision del tipo HOYTS BRIDGE
			if (telesupType == HOYTS_BRIDGE_TSUP_ID &&
					[[TelesupervisionManager getInstance] getTelesupByTelcoType: telesupType])
				THROW(ONLY_ONE_TELESUP_ALLOWED_EX);

			// Solo puede haber una supervision del tipo BRIDGE
			if (telesupType == BRIDGE_TSUP_ID &&
					[[TelesupervisionManager getInstance] getTelesupByTelcoType: telesupType])
				THROW(ONLY_ONE_TELESUP_ALLOWED_EX);


			telesupForm = [JTelesupervisionEditForm createForm: self];
			[telesup setTelcoType: telesupType];
			
			[telesupForm showFormToEdit: telesup];
		  if ([telesupForm getModalResult] == JFormModalResult_OK) {
    
    		[[TelesupervisionManager getInstance] addTelesupToCollection: telesup];
    		[[TelesupervisionManager getInstance] addConnectionToCollection: [telesup getConnection1]];
				
				TRY
					if (![[TelesupervisionManager getInstance] writeTelesupsToFile])
						error = 1;																				

					[[TelesupervisionManager getInstance] updateGprsConnections: [telesup getConnection1]];
					
				CATCH
					error = 1;
				END_TRY
			
				/*if (error)
				{
					doLog(0,"ERROR writing supervision config to file\n");
				}*/
				
  		} else {

    		[telesup free];
				[connection free];
    		telesup = NULL;
				connection = NULL;
  		}

			[telesupForm free];
			
		} else {
	
			[telesup free];
			[connection free];
			connection = NULL;
			telesup = NULL;
		}

		
	FINALLY


	END_TRY

	return telesup;
}


/**/
- (void) onSelectInstance: (id) anInstance
{
	JFORM form;
	
	form = [JTelesupervisionEditForm createForm: self];
	TRY
		
		[form showFormToView: anInstance];
		
	FINALLY

		[form free];

	END_TRY
}


/**/
- (void) onDeleteInstance: (id) anInstance
{
	TELESUP_SETTINGS telesup;
	CONNECTION_SETTINGS connection;
	volatile JFORM processForm = NULL;
	
	telesup = anInstance;
	connection = [telesup getConnection1];

	TRY
  	processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];
	  
    // Remuevo la conexion y la supervision
	  [[TelesupervisionManager getInstance] removeTelesup: [telesup getTelesupId]];
	  [[TelesupervisionManager getInstance] removeConnection: [connection getConnectionId]];
	  
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

@end

