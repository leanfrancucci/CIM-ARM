#include "JDeviceSelectionEditForm.h"
#include "UserManager.h"
#include "util.h"
#include "Door.h"
#include "MessageHandler.h"
#include "system/util/all.h"
#include "JExceptionForm.h"
#include "CimManager.h"
#include "JMessageDialog.h"
#include "CtSystem.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation  JDeviceSelectionEditForm
static char myCaptionX[] = "marcar";

/**/
- (void) onCreateForm
{
  int i;
  id checkBox;
	COLLECTION list = NULL;
	id acceptorSetting;  
  myDeviceCheckBoxCollection = [Collection new];
  
	[super onCreateForm];
	printd("JDeviceSelectionEditForm:onCreateForm\n");

  myCheckBoxList = [JCheckBoxList new];
  [myCheckBoxList setHeight: 3];


	list = [[[CimManager getInstance] getCim] getAcceptorSettings];
	for (i=0; i<[list size]; ++i) {
	acceptorSetting = [list at: i];
  if ([acceptorSetting getAcceptorType] == AcceptorType_VALIDATOR && 
			![acceptorSetting isDeleted] && 
			([acceptorSetting getAcceptorProtocol] != ProtocolType_CDM3000) ){
    checkBox = [JCheckBox new];
    [checkBox setCaption: [acceptorSetting getAcceptorName ]];
    [checkBox setCheckItem: acceptorSetting];        
    [myDeviceCheckBoxCollection add: checkBox];
		}
	}
   
  [myCheckBoxList addCheckBoxFromCollection: myDeviceCheckBoxCollection];
  [self addFormComponent: myCheckBoxList];
	[self setConfirmAcceptOperation: TRUE];

}

/**/
- (void) onModelToView: (id) anInstance
{
	int i;
  BOOL checked;
  
  printd("JDeviceSelectionEditForm:onModelToView\n");

  for (i = 0; i < [myDeviceCheckBoxCollection size]; ++i) {
    checked = TRUE;

    if ([[[myDeviceCheckBoxCollection at: i] getCheckItem] isDisabled])
      checked = FALSE;
       
    [[myDeviceCheckBoxCollection at: i] setChecked: checked];
  }   	
}



- (void) onAcceptForm: (id) anInstance
{
  int i;
	COLLECTION oldDevices;
	COLLECTION newDevices;
  id acceptorSettings;
	JFORM processForm;
  ABSTRACT_ACCEPTOR acceptor;

  printd("JDeviceSelectionEditForm:onAcceptForm\n");
	assert(anInstance != NULL);

  processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];

	newDevices = [Collection new];
  
  for (i = 0; i < [myDeviceCheckBoxCollection size]; ++i) {
		if ([[myDeviceCheckBoxCollection at: i] isChecked])
			[newDevices add: [[myDeviceCheckBoxCollection at: i] getCheckItem]];
	}

	oldDevices = [[[[CimManager getInstance] getCim] getAcceptorSettings] clone];
	// Debo comparar la lista anterior y la nueva para ver cuales debo
	// eliminar y cuales debo agregar
	// La politica es: 
	// 		- Si esta en la lista anterior pero no en la nueva lo debo eliminar.
	//		- Si esta en la lista nueva pero no en la anterior lo debo agregar

	for (i = 0; i < [oldDevices size]; ++i) {

		acceptorSettings = [oldDevices at: i];

		if ([acceptorSettings isDeleted]) continue;
		if ([acceptorSettings getAcceptorType] != AcceptorType_VALIDATOR) continue;
		if ([acceptorSettings getAcceptorProtocol] == ProtocolType_CDM3000) continue;

		acceptor = [[[CimManager getInstance] getCim] getAcceptorById: [acceptorSettings getAcceptorId]];

		if ([acceptorSettings isDisabled]) {
			if ([newDevices contains: acceptorSettings]) {
				[acceptorSettings setDisabled:FALSE];
				[acceptorSettings applyChanges];

				if (acceptor) [acceptor enableCommunication];
			}

		} else {
				if (![newDevices contains: acceptorSettings]) {
				[acceptorSettings setDisabled:TRUE];
				[acceptorSettings applyChanges];

				if (acceptor) [acceptor disableCommunication];
			}
		}
	}

	[oldDevices free];
	[newDevices free];
	
	[processForm closeProcessForm];
  [processForm free];

}


- (char *) getConfirmAcceptMessage: (char *) aMessage toSave: (id) anInstance
{
	snprintf(aMessage, JCustomForm_MAX_MESSAGE_SIZE, 
	getResourceStringDef(RESID_SAVE_DEVICE_QUESTION, "Esta seguro que desea grabar la configuracion?"));
	return aMessage;
}

- (char *) getCaptionX
{
  if ([self getFormMode] == JEditFormMode_EDIT)
    return getResourceStringDef(RESID_CHECK, myCaptionX);
    
  return NULL;    
}

@end

