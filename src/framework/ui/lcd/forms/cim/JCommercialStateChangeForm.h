#ifndef  JCOMMERCIAL_STATE_CHANGE_FORM_H
#define  JCOMMERCIAL_STATE_CHANGE_FORM_H

#define  JCOMMERCIAL_STATE_CHANGE_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JCombo.h"

#include "User.h"

/**
 *
 */
@interface  JCommercialStateChangeForm: JCustomForm
{
	JLABEL myLabelState;
	JCOMBO myComboState;

	datetime_t myDate;
	unsigned long myAuthorizationId;
	int myNewState;
	id myCommercialState;
}

/**/
- (void) onCreateForm;

@end

#endif

