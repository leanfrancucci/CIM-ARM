#ifndef  JDOORS_BY_USER_EDIT_FORM_H
#define  JDOORS_BY_USER_EDIT_FORM_H

#define  JDOORS_BY_USER_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JCombo.h"
#include "JCheckBoxList.h"

/**
 *
 */
@interface  JDoorsByUserEditForm: JEditForm
{
  JCHECK_BOX_LIST myCheckBoxList;
  COLLECTION myDoorsCheckBoxCollection;
}

/**/
- (void) onCreateForm;

@end

#endif

