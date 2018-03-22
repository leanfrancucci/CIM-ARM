#include "JRepairOrderForm.h"
#include "util.h"
#include "MessageHandler.h"
#include "system/util/all.h"
#include "JMessageDialog.h"
#include "RepairOrderManager.h"
#include "RepairOrder.h"
#include "TelesupScheduler.h"
#include "UserManager.h"
#include "TelesupervisionManager.h"
#include "JRepairOrderReport.h"
#include "CommercialStateMgr.h"

#define printd(args...)// doLog(0,args)
//#define printd(args...)

@implementation  JRepairOrderForm


/**/
- (void) onCreateForm
{
	[super onCreateForm];

	// Tipo de reparacion
	myLabelRepair = [JLabel new];
	[myLabelRepair setCaption: getResourceStringDef(RESID_REPAIR, "Tipo reparacion:")];
	[self addFormComponent: myLabelRepair];

	myComboRepair = [JCombo new];
	[myComboRepair addItemsFromCollection: [[RepairOrderManager getInstance] getRepairOrderItems]];
//	[myComboRepair setSelectedIndex: 0];
	[self addFormComponent: myComboRepair];
	
	[self addFormNewPage];

	// Prioridad
	myLabelPriority = [JLabel new];
	[myLabelPriority setCaption: getResourceStringDef(RESID_REPAIR_ORDER_PRIORITY, "Prioridad:")];
	[self addFormComponent: myLabelPriority];
				
	myComboPriority = [JCombo new];
  [myComboPriority addString: getResourceStringDef(RESID_PRIORITY_URGENT, "Urgente")]; 
  [myComboPriority addString: getResourceStringDef(RESID_PRIORITY_NORMAL, "Normal")]; 
  [myComboPriority addString: getResourceStringDef(RESID_PRIORITY_WOUT_PRIORITY, "Sin prioridad")];
	[self addFormComponent: myComboPriority];

  [self addFormNewPage];

	// Contacto
	myLabelContactTelephoneNumber = [JLabel new];
	[myLabelContactTelephoneNumber setCaption: getResourceStringDef(RESID_CONTACT_TELEPHONE_NUMBER, "Contacto:")];
	[self addFormComponent: myLabelContactTelephoneNumber];

	myTextContactTelephoneNumber = [JText new];
	[myTextContactTelephoneNumber setWidth: 20];
	[myTextContactTelephoneNumber setNumericMode: TRUE];
	[myTextContactTelephoneNumber setHeight: 1];
	[self addFormComponent: myTextContactTelephoneNumber];
	
}

/**/
- (void) onCancelForm: (id) anInstance
{

}

/**/
- (void) onMenu1ButtonClick
{
  [self closeForm];
}

/**/
- (char*) getCaption1
{
  return getResourceStringDef(RESID_CANCEL_KEY, "cancel");
}

/**/
- (char*) getCaptionX
{
  return NULL;
}

/**/
- (char*) getCaption2
{
  return getResourceStringDef(RESID_ENTER, "entrar");
}

/**/
- (void) onMenu2ButtonClick
{
	id form;
	id repairOrder;
	id telesup;
	id telesupScheduler = [TelesupScheduler getInstance];
	
	// verifico que tenga creada una supervision a la PIMS 
  if (([telesupScheduler getMainTelesup] == NULL) || ([[telesupScheduler getMainTelesup] getTelcoType] != PIMS_TSUP_ID)){
	  [JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_CREATE_PIMS_SUPERVISION_MSG, "Primero debe crear una supervision a la PIMS!")];
	  return;
	}

	// Si no tengo permiso porque esta mal la autorizacion, me voy
	if (([[telesupScheduler getMainTelesup] getTelcoType] == PIMS_TSUP_ID) && (![[CommercialStateMgr getInstance] canExecutePimsSupervision])) {		
   	[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_NO_AUT_FOR_TELESUP, "No posee autorizacion para realizar la supervision.")];
		return;
	}


  if ([JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_CONFIRM_REPAIR_ORDER, "Generar orden de reparacion?")] != JDialogResult_YES) return;

	repairOrder = [RepairOrder new];
	[repairOrder setPriority: [myComboPriority getSelectedIndex] + 1];
	[repairOrder setTelephoneNumber: [myTextContactTelephoneNumber getText]];
	[repairOrder addRepairOrderItem: [myComboRepair getSelectedItem]];
	[repairOrder setUserId: [[[UserManager getInstance] getUserLoggedIn] getUserId]];
	[repairOrder setDateTime: [SystemTime getLocalTime]];

	if ([telesupScheduler	inTelesup]) {
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_TELESUP_IN_PROGRESS, "Supervision en curso.")];
		return;
	}

	[telesupScheduler setRepairOrder: repairOrder];
	[telesupScheduler setCommunicationIntention: CommunicationIntention_GENERATE_REPAIR_ORDER];
	telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];

	[telesupScheduler startTelesup: telesup];

	form = [JRepairOrderReport createForm: self];
	[form setRepairOrder: repairOrder];
	[form showModalForm];
	[form free];

	[repairOrder free];
	[self closeForm];
}

@end

