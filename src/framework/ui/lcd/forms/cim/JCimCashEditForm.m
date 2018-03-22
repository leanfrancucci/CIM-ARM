#include "JCimCashEditForm.h"
#include "CimCash.h"
#include "MessageHandler.h"
#include "JMessageDialog.h"
#include "CimManager.h"
#include "JCashAcceptorsListForm.h"
#include "Event.h"
#include "Audit.h"
#include "JExceptionForm.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation  JCimCashEditForm

static char mySaveMsg[] = "Save ?";

/**/
- (void) depositType_onSelect;

- (void) printAcceptorsName: (COLLECTION) aCollection collectionName: (char*) aCollectionName;

/**/
+ free
{
	[mySelectedAcceptors free];
	[acceptorsList free];

	return [super free];
 }

/**/
- (void) onCreateForm
{
	[super onCreateForm];

	[self setCloseOnAccept: TRUE];
	[self setCloseOnCancel: TRUE];

	acceptorsList = [Collection new];
	mySelectedAcceptors = [Collection new];

	myLabelCashType = [self addLabelFromResource: RESID_CASH_TYPE default: "Tipo cash:"];
	myComboCashType = [JCombo new];
	[myComboCashType setWidth: 17];
	[myComboCashType setHeight: 1];
	[myComboCashType addString: getResourceStringDef(RESID_VALIDATED, "Validado")];
	[myComboCashType addString: getResourceStringDef(RESID_MANUAL, "Manual")];
	[myComboCashType addString: getResourceStringDef(RESID_NO_DEVICES, "S/Dispositivos")];
	[myComboCashType setSelectedIndex: 0];
	[myComboCashType setOnSelectAction: self 	action: "depositType_onSelect"];

	[self addFormComponent: myComboCashType];

	[self addFormNewPage];

	myLabelCashName = [self addLabelFromResource: RESID_CASH_NAME default: "Nombre Cash:"];
	myTextCashName = [JText new];
	[myTextCashName setWidth: 16];
	[self addFormComponent: myTextCashName];

	[self addFormNewPage];

	myLabelCashDoor = [self addLabelFromResource: RESID_SELECT_LOCK default: "Seleccione Puerta:"];
	myComboCashDoor = [JCombo new];
	[myComboCashDoor setWidth: 17];
	[myComboCashDoor setHeight: 1];
	[myComboCashDoor addString: getResourceStringDef(RESID_UNDEFINE, "Indefinido")];
	[myComboCashDoor setSelectedIndex: 0];
	[self addFormComponent: myComboCashDoor];

	[self setConfirmAcceptOperation: TRUE];

}

/**/
- (void) onModelToView: (id) anInstance
{
	[myComboCashType setSelectedIndex: [anInstance getDepositType] - 1];

	[myTextCashName setText: [anInstance getName]];

	[self depositType_onSelect];

	if ([anInstance getDoor])	
		[myComboCashDoor setSelectedItem: [anInstance getDoor]];

}

/**/
- (void) onViewToModel: (id) anInstance
{
	[anInstance setDepositType: [myComboCashType getSelectedIndex] + 1];

	[anInstance setName: [myTextCashName getText]];
	
	if ([myComboCashDoor getSelectedIndex] != 0)
		[anInstance setDoorId: [[myComboCashDoor getSelectedItem] getDoorId]];

}

/**/
- (void) onAcceptForm: (id) anInstance
{
	int i;
	JFORM processForm = NULL;

  TRY
    processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];
    
  	[anInstance applyChanges];
  
  	[anInstance removeAllAcceptorsByCash];
  	
  	for (i=0; i<[mySelectedAcceptors size]; ++i) {
  		[anInstance addAcceptorSettingsByCash: [mySelectedAcceptors at: i]];
  	}
  	
    [processForm closeProcessForm];
    [processForm free];
      	
  	[self closeForm];
  	
  CATCH
  
    [processForm closeProcessForm];
    [processForm free];
    RETHROW();
        
  END_TRY
}

/**/
- (void) setDepositTypeReadOnly
{
	[myComboCashType setReadOnly: TRUE];
	[myComboCashType setEnabled: FALSE];
}

/**/
- (BOOL) acceptorInCash: (id) anAcceptor
{
	int i;
	COLLECTION cashes = [[[CimManager getInstance] getCim] getCimCashs];

	for (i=0; i<[cashes size]; ++i) {
		if ([[cashes at: i] hasAcceptorSettings: anAcceptor]) return TRUE;
	}
	
	return FALSE;
}

/**/
- (BOOL) doorNotInList: (COLLECTION) aDoors doorId: (int) aDoorId
{
	int i;

	for (i=0; i<[aDoors size]; ++i) {
		if ([[aDoors at: i] getDoorId] == aDoorId) return TRUE;
	}
	
	return FALSE;
}

/**/
- (BOOL) acceptorInList: (COLLECTION) aCollection acceptor: (id) anAcceptor
{
	int i;

	for (i=0; i<[aCollection size]; ++i) {
		if ([aCollection at: i] == anAcceptor) return TRUE;
	}
	
	return FALSE;
}

/**/
- (void) getDefaultAcceptorsCollection
{

	int i;
	COLLECTION currentAcceptors = NULL;

	[mySelectedAcceptors removeAll];

	currentAcceptors =	[[self getFormInstance] getAcceptorSettingsList];

	for (i=0; i<[currentAcceptors size]; ++i) {
		if (![self acceptorInList: acceptorsList acceptor: [currentAcceptors at: i]])
			[acceptorsList add: [currentAcceptors at: i]];
		[mySelectedAcceptors add: [currentAcceptors at: i]];
	}

}

/**/
- (void) depositType_onSelect
{
	int i;
	COLLECTION acceptorsCompleteList = [[[CimManager getInstance] getCim] getActiveAcceptorSettings];
	COLLECTION doors = [Collection new];
	COLLECTION doorsList;

	/*
	acceptorsList: lista de aceptadores totales del tipo y puerta seleccionados que no se encuentran en otro cash. 
	*/

	[myComboCashDoor clearItems];
	[doors removeAll];
	[acceptorsList removeAll];

	[myComboCashDoor addString: getResourceStringDef(RESID_UNDEFINE, "Indefinido")];

	printf("selectedIndex = %d\n", 	[myComboCashType getSelectedIndex]);

	if (([myComboCashType getSelectedIndex] + 1)  == DepositType_WITHOUT_DEVICES) {
	
			doorsList	= [[[CimManager getInstance] getCim] getDoors];

		for (i=0; i<[doorsList size]; ++i) {
			if ([[[doorsList at: i] getAcceptorSettingsList] size] == 0)
				[doors add: [doorsList at: i]];
		}


	} else {

		// recorro los aceptadores para tener la lista de los que no se encuentran en otro cash
		for (i=0; i<[acceptorsCompleteList size]; ++i)	{
	
			if ((![self acceptorInCash: [acceptorsCompleteList at: i]]) && ([[acceptorsCompleteList at: i] getAcceptorType] == [myComboCashType getSelectedIndex] + 1)) {
				[acceptorsList add: [acceptorsCompleteList at: i]];
			}
		}
	
		[self getDefaultAcceptorsCollection];
	
		// recorro los aceptadores resultantes para tener la lista de puertas disponibles
		for (i=0; i<[acceptorsList size]; ++i) {
			if (![self doorNotInList: doors doorId: [[[acceptorsList at: i] getDoor] getDoorId]]) {
				[doors add: [[acceptorsList at: i] getDoor]];
			}
		}

	}

	// asignar las puertas a la lista
	[myComboCashDoor addItemsFromCollection: doors];


	// libera las colleciones
	[doors free];
	[acceptorsCompleteList free];
	
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) anIsPressed
{
	JFORM form;

	if (!anIsPressed) return FALSE;
	
		switch (aKey) {

			case UserInterfaceDefs_KEY_DOWN:

				if ([self getFormFocusedComponent] == myComboCashDoor && [myComboCashType getSelectedIndex] + 1 != DepositType_WITHOUT_DEVICES) {

					form = [JCashAcceptorsListForm createForm: self];

					// Setea todos los aceptadores que se visualizaran
					[form setCollection: acceptorsList];
					// Setea los aceptadores que tiene seleccionado el cash
					[form setSelectedAcceptors: mySelectedAcceptors];

					//[self printAcceptorsName: acceptorsList collectionName: "doKeyPressed -> AcceptorsList "];
					//[self printAcceptorsName: mySelectedAcceptors collectionName: "doKeyPressed -> mySelectedAcceptors "];

					//Setea la puerta seleccionada
					if ([myComboCashDoor getSelectedIndex] != 0)
						[form setDoorId: [[myComboCashDoor getSelectedItem] getDoorId]];

					// Setea el modo del formulario al mismo de este
					[form setFormMode: myFormMode];
					[form setCloseOnCancel: myCloseOnCancel];

					[form showModalForm];		

					mySelectedAcceptors = [form getSelectedAcceptorsCollection];
					myCashAcceptorsFormState = [form getFormState];

					switch ([form getFormState]) {

						// Cancela
						case CashAcceptorsListFormState_CANCEL:
							[self onMenu1ButtonClick];
							break;

						// Guarda
						case CashAcceptorsListFormState_SAVE:
							
								myFormMode = [form getFormMode];
								myCashAcceptorsFormState = CashAcceptorsListFormState_SAVE;

							if ([myComboCashDoor getSelectedIndex] == 0)
								[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_SELECT_DOOR_MSG, "Seleccione una puerta.")];
							else 
								if ([mySelectedAcceptors size] == 0) {
									[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_SELECT_A_DEVICE, "Seleccione un dispositivo.")];

								if (myFormMode == JEditFormMode_VIEW) 
									[self onMenu2ButtonClick];
									
								[self doKeyPressed: UserInterfaceDefs_KEY_DOWN isKeyPressed: TRUE];	
								break;
							}

							[self onMenu2ButtonClick];

							[self doKeyPressed: UserInterfaceDefs_KEY_DOWN isKeyPressed: TRUE];	
							return TRUE;

						case CashAcceptorsListFormState_CONTINUE:

							if (([form getFormMode] == JEditFormMode_EDIT) && (myFormMode == JEditFormMode_VIEW)) 
								[self onMenu2ButtonClick];

							if (([form getFormMode] == JEditFormMode_VIEW) && (myFormMode == JEditFormMode_EDIT)) 
								[self onMenu1ButtonClick];

							break;

					}

					[form free];
					return TRUE;
				}
		}

	[super doKeyPressed: aKey isKeyPressed: anIsPressed];
	return FALSE;
}

/**/
- (void) onCancelForm: (id) anInstance
{
	assert(anInstance != NULL);

	if ([anInstance getCimCashId] > 0)
		[anInstance restore];
}

/**/
- (void) onMenu1ButtonClick
{
/*
	if (!myCloseOnCancel) {
		[acceptorsList removeAll];
	}
*/	
	[super onMenu1ButtonClick];

}

/**/
- (void) onMenu2ButtonClick
{							

	if ([myComboCashDoor getSelectedIndex] == 0) {
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_SELECT_DOOR_MSG, "Seleccione una puerta.")];
		return;
	}

	if (([mySelectedAcceptors size] == 0) && (myFormMode == JEditFormMode_EDIT) && 
		[myComboCashType getSelectedIndex] + 1 != DepositType_WITHOUT_DEVICES) {
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_SELECT_A_DEVICE, "Seleccione un dispositivo.")];  
		return;
	}

	[super onMenu2ButtonClick];

}
	
/**/
/*DEBUG*/
- (void) printAcceptorsName: (COLLECTION) aCollection collectionName: (char*) aCollectionName
{
/*	int i;

	assert(aCollection);

	doLog(0,"Collection name	----> %s\n", aCollectionName);

	for (i=0; i<[aCollection size]; ++i)
		doLog(0,"		AcceptorName = %s\n", [[aCollection at: i] getAcceptorName]);
*/
}

/**/
- (char *) getConfirmAcceptMessage: (char *) aMessage toSave: (id) anInstance
{
	return getResourceStringDef(RESID_SAVE_WITH_QUESTION_MARK, mySaveMsg);
}
@end

