#ifndef  JFOOTER_EDIT_FORM_H
#define  JFOOTER_EDIT_FORM_H

#define  JFOOTER_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"


/**
 *
 */
@interface  JFooterEditForm: JEditForm
{
	JLABEL myLabelFooter1;
	JTEXT	myTextFooter1;

	JLABEL myLabelFooter2;
	JTEXT	myTextFooter2;

	JLABEL myLabelFooter3;
	JTEXT	myTextFooter3;
}

/**/
- (void) onCreateForm;

@end

#endif

