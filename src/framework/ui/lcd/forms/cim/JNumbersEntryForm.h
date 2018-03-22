#ifndef  JNUMBERS_ENTRY_FORM_H
#define  JNUMBERS_ENTRY_FORM_H

#define  JNUMBERS_ENTRY_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JCombo.h"

#include "User.h"
#include "OMutex.h"
/**
 *
 */
@interface  JNumbersEntryForm: JCustomForm
{
	JLABEL myLabelNumbersEntry;
	JLABEL myLabelQtyRead;
	
	JTEXT myNumber;

	int myQtyRead;
	int myTotalToRead;

	COLLECTION myBagTracking;

	id myCurrentExtraction;
	unsigned long myBagTrackingParentId;

	int myBagTrackingMode;

	char myPreviousNumber[25];
	BOOL isConfirmation;
	BOOL isShowingError;

	COLLECTION myAcceptorSettingsList;

}

/**/
- (void) onCreateForm;
- (void) setTotalToRead: (int) aValue;
- (void) setCurrentExtraction: (id) anExtraction;
- (void) setBagTrackingMode: (int) aMode;
- (void) setAcceptorSettingsList: (COLLECTION) anAcceptorSettingsList;

@end

#endif

