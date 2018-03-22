#ifndef  JCIM_CASH_EDIT_FORM_H
#define  JCIM_CASH_EDIT_FORM_H

#define  JCIM_CASH_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JCombo.h"
#include "JCheckBoxList.h"
#include "JCheckBox.h"
#include "ctapp.h"

/**
 *
 */
@interface  JCimCashEditForm: JEditForm
{
	JLABEL myLabelCashType;
	JCOMBO myComboCashType;

	JLABEL myLabelCashName;
	JTEXT	myTextCashName;

	JLABEL myLabelCashDoor;
	JCOMBO	myComboCashDoor;

	COLLECTION acceptorsList;
	COLLECTION mySelectedAcceptors;

	int myCashAcceptorsFormState;
}

/**/
- (void) setDepositTypeReadOnly;

@end

#endif

