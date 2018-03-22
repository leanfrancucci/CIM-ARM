#ifndef  JNUMERATION_EDIT_FORM_H
#define  JNUMERATION_EDIT_FORM_H

#define  JNUMERATION_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"

/**
 *
 */
@interface  JNumerationEditForm: JEditForm
{
	JLABEL myLabelPrefix;
	JTEXT	myTextPrefix;

	JLABEL myLabelInitialNumber;
	JTEXT	myTextInitialNumber;

	JTEXT	myTextDigitsQty;

}

/**/
- (void) onCreateForm;

@end

#endif

