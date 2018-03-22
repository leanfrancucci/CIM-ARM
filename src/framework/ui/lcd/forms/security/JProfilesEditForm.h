#ifndef  JPROFILES_EDIT_FORM_H
#define  JPROFILES_EDIT_FORM_H

#define  JPROFILES_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JCombo.h"
#include "JCheckBoxList.h"

#include "User.h"

/**
 *
 */
@interface  JProfilesEditForm: JEditForm
{
	int myProfileId;
  unsigned char mySelectedOperations[15];
  
	JLABEL myLabelName;
	JTEXT	myTextName;

  JLABEL myLabelSecurityLevel;
  JCOMBO myComboSecurityLevel;

  JCHECK_BOX_LIST myTimeDelayCheckBoxList;
  COLLECTION myTimeDelayCheckBoxCollection;

  JCHECK_BOX_LIST myUseDuressCheckBoxList;
  COLLECTION myUseDuressCheckBoxCollection;

	JLABEL myLabelProfile;
	JCOMBO myComboProfile;
}

/**/
- (void) onCreateForm;

/**/
- (void) setSelectedOperations: (unsigned char *) aValue;
- (unsigned char *) getSelectedOperations;

@end

#endif

