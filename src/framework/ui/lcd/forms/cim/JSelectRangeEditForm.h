#ifndef  JSELECT_RANGE_EDIT_FORM_H
#define  JSELECT_RANGE_EDIT_FORM_H

#define  JSELECT_RANGE_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JDate.h"

/**
 *
 */
@interface  JSelectRangeEditForm: JCustomForm
{
	JLABEL myLabelFromRange;
	JTEXT	myTextFromRange;
	
	JLABEL myLabelToRange;
	JTEXT	myTextToRange;

  unsigned long from;
  unsigned long to;
}

/**/
- (unsigned long) getFromRange;

/**/
- (unsigned long) getToRange;

/**/
- (void) setFromRange: (unsigned long) aValue;

/**/
- (void) setToRange: (unsigned long) aValue;

@end

#endif

