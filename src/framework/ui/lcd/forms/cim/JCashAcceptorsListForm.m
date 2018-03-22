#include "JCashAcceptorsListForm.h"
#include "MessageHandler.h"
#include "system/util/all.h"
#include "JMessageDialog.h"
#include "UICimUtils.h"
#include "Collection.h"

#define printd(args...) //doLog(0,args)
//#define printd(args...)

@implementation  JCashAcceptorsListForm

/**/
+ free
{
	[myDevicesCheckBoxCollection free];
	return [super free];
}

/**/
- (void) buildSelectedAcceptorsCollection;

/**/
- (void) initComponent
{
	[super initComponent];
}

/**/
- (void) doCreateForm
{
	[super doCreateForm];	

	myDoorId = 0;
	myCloseOnCancel = FALSE;

}	

/**/
- (void) setCollection: (COLLECTION) aCollection
{
	//aceptadores que se visualizaran
	myCollection = aCollection;
}

/**/
- (void) checkSelectedAcceptor: (int) anAcceptorId
{
	int i;

  for (i=0; i<[myDevicesCheckBoxCollection size]; ++i) {
    if ([[[myDevicesCheckBoxCollection at: i] getCheckItem] getAcceptorId] == anAcceptorId) {
			[[myDevicesCheckBoxCollection at: i] doKeyPressed: JCheckBox_KEY_CLICK isKeyPressed: TRUE];
		}
  }   	

}

/**/
- (void) doOpenForm
{
	int i;
	id checkBox;

  myDevicesCheckBoxCollection = [Collection new];

	myLabelDevices = [self addLabelFromResource: RESID_DEVICES default: "Dispositivos:"];
	
  myCheckBoxList = [JCheckBoxList new];
  [myCheckBoxList setHeight: 2];

	if (myDoorId == 0) return;

  for (i=0; i<[myCollection size]; ++i) {
//		if ([[[myCollection at: i] getDoor] getDoorId] == myDoorId) {
    	checkBox = [JCheckBox new];
    	[checkBox setCaption: [[myCollection at: i] str]];
    	[checkBox setCheckItem: [myCollection at: i]];
        
    	[myDevicesCheckBoxCollection add: checkBox];
//		}
  }    

  [myCheckBoxList addCheckBoxFromCollection: myDevicesCheckBoxCollection];
  [self addFormComponent: myCheckBoxList];


	assert(mySelectedAcceptors);

	for (i=0; i<[mySelectedAcceptors size]; ++i) {
		[self checkSelectedAcceptor: [[mySelectedAcceptors at: i] getAcceptorId]];
	}

	//Pone todo readOnly
	if (myFormMode == JEditFormMode_VIEW)	{
		[myCheckBoxList setReadOnly: TRUE];
		[myCheckBoxList setEnabled: FALSE];
	}

}

/**/
- (char *) getCaption1
{
	if (myFormMode == JEditFormMode_VIEW) return getResourceStringDef(RESID_BACK_KEY, "atras");

	return getResourceStringDef(RESID_CANCEL_KEY, "cancel");
}

/**/
- (char*) getCaptionX
{
	if ((myDevicesCheckBoxCollection) && ([myDevicesCheckBoxCollection size] > 0) && (myFormMode == JEditFormMode_EDIT) ) {
			
		if ([[myCheckBoxList getSelectedCheckBoxItem] isChecked])
			return getResourceStringDef(RESID_UNCHECK_OPTION, "desmarc");
		else
			return getResourceStringDef(RESID_CHECK_OPTION, "marcar");

	}

	return NULL;
}

/**/
- (char*) getCaption2
{
	if (myFormMode == JEditFormMode_VIEW) return getResourceStringDef(RESID_UPDATE_KEY, "modif.");
	
	return getResourceStringDef(RESID_SAVE_KEY, "grabar");

}

/**/
- (void) onMenu1ButtonClick
{	
	int i;

	if (myCloseOnCancel) {
		myState = CashAcceptorsListFormState_CANCEL;
		[self closeForm];
	}

	if (myFormMode == JEditFormMode_EDIT)	{
		myFormMode = JEditFormMode_VIEW;
		[myCheckBoxList setReadOnly: TRUE];
		[myCheckBoxList setEnabled: FALSE];

		for (i=0; i<[myDevicesCheckBoxCollection size]; ++i) {
			if ([[myDevicesCheckBoxCollection at: i] isChecked]) [[myDevicesCheckBoxCollection at: i] doKeyPressed: JCheckBox_KEY_CLICK isKeyPressed: TRUE];
		}

		for (i=0; i<[mySelectedAcceptors size]; ++i) {
			[self checkSelectedAcceptor: [[mySelectedAcceptors at: i] getAcceptorId]];
		}

		[self paintComponent];
		[self doChangeStatusBarCaptions];	
		return;
	}



	myState = CashAcceptorsListFormState_CANCEL;
	[self closeForm];

}

/**/
- (void) onMenu2ButtonClick
{

	if (myFormMode == JEditFormMode_VIEW)	{
		myFormMode = JEditFormMode_EDIT;
		[myCheckBoxList setReadOnly: FALSE];
		[myCheckBoxList setEnabled: TRUE];
		[self sendPaintMessage];
		[self doChangeStatusBarCaptions];	
		return;
	}

	myState = CashAcceptorsListFormState_SAVE;
	[self buildSelectedAcceptorsCollection];
	[self closeForm];

}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) anIsPressed
{
	if (!anIsPressed)
			return FALSE;

	switch (aKey) {

		case UserInterfaceDefs_KEY_UP:

			if ([myCheckBoxList getSelectedCheckBoxIndex] > 0) break;

			myState = CashAcceptorsListFormState_CONTINUE;
			[self buildSelectedAcceptorsCollection];
			[self closeForm];
			return TRUE;

	}
		
	[super doKeyPressed: aKey isKeyPressed: anIsPressed];
	
	return FALSE;
}

/**/
- (int) getFormState
{
	return myState;
}

/**/
- (void) setDoorId: (int) aDoorId
{
	myDoorId = aDoorId;
}

/**/
- (void) buildSelectedAcceptorsCollection
{

	int i;

	[mySelectedAcceptors removeAll];

	for (i = 0; i < [myDevicesCheckBoxCollection size]; ++i) {

    if ([[myDevicesCheckBoxCollection at: i] isChecked]) {
				[mySelectedAcceptors add: [[myDevicesCheckBoxCollection at: i] getCheckItem]];
		}
	}

}

/**/
- (COLLECTION) getSelectedAcceptorsCollection
{
	return mySelectedAcceptors;
}

/**/
- (void) setSelectedAcceptors: (COLLECTION) aCollection
{
	mySelectedAcceptors = aCollection;
}

/**/
- (void) setFormMode: (JEditFormMode) aFormMode
{
	myFormMode = aFormMode;
}

/**/
- (JEditFormMode) getFormMode
{
	return myFormMode;
}

/**/
- (void) setCloseOnCancel: (BOOL) aValue
{
	myCloseOnCancel = aValue;
}

@end

