#ifndef  JACTIVATE_DEACTIVATE_USER_EDIT_FORM_H
#define  JACTIVATE_DEACTIVATE_USER_EDIT_FORM_H

#define  JACTIVATE_DEACTIVATE_USER_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JCombo.h"
#include "JCheckBoxList.h"

/**
 *
 */
@interface  JActivateDeactivateUserEditForm: JEditForm
{
  JCHECK_BOX_LIST myCheckBoxList;
  COLLECTION myUsersCheckBoxCollection;
  
  BOOL myViewActiveUsers;
}

/**/
- (void) onCreateForm;

- (void) setViewActiveUsers: (BOOL) aValue;
- (BOOL) getViewActiveUsers;

@end

#endif

