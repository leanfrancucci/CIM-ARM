#ifndef  JREPAIR_ORDER_FORM_H
#define  JREPAIR_ORDER_FORM_H

#define  JREPAIR_ORDER_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JCombo.h"

#include "User.h"

/**
 *
 */
@interface  JRepairOrderForm: JCustomForm
{
	JLABEL myLabelRepair;
	JCOMBO myComboRepair;
	
	JLABEL myLabelPriority;
	JTEXT	myComboPriority;

	JLABEL myLabelContactTelephoneNumber;
	JTEXT	myTextContactTelephoneNumber;
}

/**/
- (void) onCreateForm;

@end

#endif

