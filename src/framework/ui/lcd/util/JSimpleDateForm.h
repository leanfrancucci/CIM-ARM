#ifndef  JSIMPLE_DATE_FORM_H
#define  JSIMPLE_DATE_FORM_H

#define  JSIMPLE_DATE_FORM id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JDate.h"

/**
 *
 */
@interface  JSimpleDateForm: JCustomForm
{
	JLABEL myLabelTitle;
	JLABEL myLabelDescription;
	JDATE	myDate;
	char myTitle[41];
	char myDescription[41];
	datetime_t myDateValue;
}

/**/
- (void) setTitle: (char *) aTitle;
- (void) setDescription: (char *) aDescription;

/**/
- (void) setDateVal: (datetime_t) aValue;
- (datetime_t) getDateVal;

@end

#endif

