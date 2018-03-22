#ifndef  JDUAL_ACCESS_EDIT_FORM_H
#define  JDUAL_ACCESS_EDIT_FORM_H

#define  JDUAL_ACCESS_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JCombo.h"

#include "DualAccess.h"

/**
 *
 */
@interface  JDualAccessEditForm: JEditForm
{
	JLABEL myLabelProfile1;
	JCOMBO myComboProfile1;
	
	JLABEL myLabelProfile2;
	JCOMBO myComboProfile2;
}

/**/
- (void) onCreateForm;

@end

#endif

