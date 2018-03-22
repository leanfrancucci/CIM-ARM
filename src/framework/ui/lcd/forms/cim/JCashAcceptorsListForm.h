#ifndef  JCASH_ACCEPTORS_LIST_FORM_H
#define  JCASH_ACCEPTORS_LIST_FORM_H

#define  JCASH_ACCEPTORS_LIST_FORM id

#include "JListForm.h"
#include "JCheckBoxList.h"
#include "JCheckBox.h"
#include "JEditForm.h"


typedef enum {
	CashAcceptorsListFormState_SAVE,
	CashAcceptorsListFormState_CONTINUE,		
	CashAcceptorsListFormState_CANCEL		  
} CashAcceptorsListFormState;


/**
 *
 */
@interface  JCashAcceptorsListForm: JCustomForm
{
	JGRID	myObjectsList;

	JLABEL myLabelDevices;
  JCHECK_BOX_LIST myCheckBoxList;
  COLLECTION myDevicesCheckBoxCollection;  

	COLLECTION myCollection;
	int myDoorId;
	int myState;
	COLLECTION mySelectedAcceptors;

	BOOL myCloseOnCancel;

	JEditFormMode myFormMode;
}

/**/
- (void) setCollection: (COLLECTION) aCollection;

/**/
- (void) setDoorId: (int) aDoorId;

/**/
- (int) getFormState;

/**/
- (COLLECTION) getSelectedAcceptorsCollection;

/**/
- (void) setSelectedAcceptors: (COLLECTION) aCollection;

/**/
- (void) setFormMode: (JEditFormMode) aFormMode;
- (JEditFormMode) getFormMode;

/**/
- (void) setCloseOnCancel: (BOOL) aValue;

@end

#endif

