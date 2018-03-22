#ifndef  JBOX_MODEL_CHANGE_EDIT_FORM_H
#define  JBOX_MODEL_CHANGE_EDIT_FORM_H

#define  JBOX_MODEL_CHANGE_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JCombo.h"

/**
 *
 */
@interface  JBoxModelChangeEditForm: JCustomForm
{
  JLABEL myLabelPhisicalModel;
	JCOMBO myComboPhisicalModel;

	JLABEL myLabelValModel;
	JCOMBO myComboValModel;
	BOOL myShowVal1;

	JLABEL myLabelVal2Model;
	JCOMBO myComboVal2Model;
	BOOL myShowVal2;

	BOOL myShowCancel;
	BOOL myIsViewMode;

}

/**/
- (void) setShowCancel: (BOOL) aValue;

/**/
- (void) setIsViewMode: (BOOL) aValue;

@end

#endif

