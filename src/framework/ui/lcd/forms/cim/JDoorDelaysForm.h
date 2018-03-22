#ifndef  JDOOR_DELAYS_FORM_H
#define  JDOOR_DELAYS_FORM_H

#define  JDOOR_DELAYS_FORM id

#include "JListForm.h"


/**
 *
 */
@interface  JDoorDelaysForm: JCustomForm
{
	JGRID	myObjectsList;
	COLLECTION myCollection;
	char myTitle[41];
	JLABEL myLabelTitle;
	int myAutoRefreshTime;
	OTIMER myUpdateTimer;
	BOOL myIsClosingForm;
}

/**/
- (void) setShowItemNumber: (BOOL) aValue;

/**/
- (void) setTitle: (char *) aTitle;

/**/
- (void) setCollection: (COLLECTION) aCollection;

/**/
- (void) setAutoRefreshTime: (unsigned long) aValue;

@end

#endif

