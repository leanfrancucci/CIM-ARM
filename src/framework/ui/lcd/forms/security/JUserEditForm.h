#ifndef  JUSER_EDIT_FORM_H
#define  JUSER_EDIT_FORM_H

#define  JUSER_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JCombo.h"

#include "User.h"

/**
 *
 */
@interface  JUserEditForm: JEditForm
{
	JTEXT myTextUserId;
	JTEXT	myTextName;
	JTEXT	myTextSurname;
	JTEXT	myTextUserName;
	JTEXT	myTextPassword;
	JTEXT	myTextConfirmPassword;
	JLABEL myLabelDuressPassword;
	JTEXT	myTextDuressPassword;
	JLABEL myLabelConfirmDuressPassword;
	JTEXT	myTextConfirmDuressPassword;
	JTEXT	myTextBankAccountNumber;
	JCOMBO myComboProfile;
	JCOMBO myComboLoginMethod;
	JCOMBO myComboStatus;
	JCOMBO myComboDynamicPin;
	JCOMBO myComboLanguage;
  
  JLABEL myLabelDallasKey;
  JTEXT  myTextDallasKey;

	LanguageType myOriginalLanguage;
}

/**/
- (void) onCreateForm;

@end

#endif

