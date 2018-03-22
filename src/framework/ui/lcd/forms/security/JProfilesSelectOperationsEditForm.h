#ifndef  JSELECT_OPERATIONS_EDIT_FORM_H
#define  JSELECT_OPERATIONS_EDIT_FORM_H

#define  JSELECT_OPERATIONS_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JCombo.h"
#include "JCheckBoxList.h"
#include "Profile.h"

/**
 *
 */
@interface  JProfilesSelectOperationsEditForm: JEditForm
{
  char myProfileName[30];
  int myFatherProfileId;
	int mySecurityLevel;
  BOOL myTimeDelayOverride;
	BOOL myUseDuressPassword;
  unsigned char mySelectedOperations[15];
	int myProfileId;

  JCHECK_BOX_LIST myCheckBoxList;
  COLLECTION myOperationsCheckBoxCollection;
  COLLECTION mySelectAllCheckBoxCollection;
}

- (void) setProfileName: (char*) aValue;
- (void) setFatherProfileId: (int) aValue;
- (void) setSelectedOperations: (unsigned char *) aValue;
- (unsigned char *) getSelectedOperations;
- (void) setTimeDelayOverride: (BOOL) aValue;
- (void) setUseDuressPassword: (BOOL) aValue;
- (void) setSecurityLevel: (int) aValue;
- (int) getProfileId;

/**/
- (void) onCreateForm;

@end

#endif

