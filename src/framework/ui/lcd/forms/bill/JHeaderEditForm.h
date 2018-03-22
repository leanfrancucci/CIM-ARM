#ifndef  JHEADER_EDIT_FORM_H
#define  JHEADER_EDIT_FORM_H

#define  JHEADER_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"

/**
 *
 */
@interface  JHeaderEditForm: JEditForm
{
	JLABEL myLabelHeader1;
	JTEXT	myTextHeader1;

	JLABEL myLabelHeader2;
	JTEXT	myTextHeader2;

	JLABEL myLabelHeader3;
	JTEXT	myTextHeader3;

	JLABEL myLabelHeader4;
	JTEXT	myTextHeader4;

	JLABEL myLabelHeader5;
	JTEXT	myTextHeader5;

	JLABEL myLabelHeader6;
	JTEXT	myTextHeader6;
}

/**/
- (void) onCreateForm;

@end

#endif

