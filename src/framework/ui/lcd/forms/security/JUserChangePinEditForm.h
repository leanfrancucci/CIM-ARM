#ifndef  JUSER_CHANGE_PIN_EDIT_FORM_H
#define  JUSER_CHANGE_PIN_EDIT_FORM_H

#define  JUSER_CHANGE_PIN_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JCombo.h"

#include "User.h"

/**
 *
 */
@interface  JUserChangePinEditForm: JEditForm
{
	JTEXT	myTextActualPassword;
	JTEXT	myTextPassword;
	JTEXT	myTextConfirmPassword;
	JLABEL myLabelDuressPassword;
	JTEXT	myTextDuressPassword;
	JLABEL myLabelConfirmDuressPassword;
	JTEXT	myTextConfirmDuressPassword;

	BOOL myShowCancel;
	BOOL myWasCanceledLogin;

	char myOldPassword[9];
	char myOldDuressPassword[9];
}

/**/
- (void) onCreateForm;

- (void) setShowCancel: (BOOL) aValue;

- (BOOL) wasCanceledLogin;

@end

#endif

