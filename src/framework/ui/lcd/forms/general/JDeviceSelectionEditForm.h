#ifndef  JSELECT_DEVICE_EDIT_FORM_H
#define  JSELECT_DEVICE_EDIT_FORM_H

#define  JSELECT_DEVICE_EDIT_FORM id

#include "JEditForm.h"
#include "JLabel.h"
#include "JText.h"
#include "JCombo.h"
#include "JCheckBoxList.h"

/**
 *
 */
@interface  JDeviceSelectionEditForm: JEditForm
{
  JCHECK_BOX_LIST myCheckBoxList;
  COLLECTION myDeviceCheckBoxCollection;  
}

/**/
- (void) onCreateForm;

@end

#endif

