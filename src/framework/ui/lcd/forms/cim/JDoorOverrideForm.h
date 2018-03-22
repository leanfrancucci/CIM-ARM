#ifndef  JDOOR_OVERRIDE_FORM_H
#define  JDOOR_OVERRIDE_FORM_H

#define  JDOOR_OVERRIDE_FORM  id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JText.h"
#include "Door.h"

/**
 *	
 */
@interface  JDoorOverrideForm: JCustomForm
{
	JLABEL myLabelUserCode;
	JLABEL myLabel;
	JLABEL myLabelAccessCode;
	JTEXT  myTextAccessCode;
	char myVerificationCode[50];
	datetime_t myDateTime;
	DOOR myDoor;
	BOOL mySecondaryHardwareMode;
}

/**/
- (void) setDoor: (DOOR) aDoor;

/**/
- (void) setVerificationCode: (char *) aVerificationCode;

/**/
- (void) setDateTime: (datetime_t) aDateTime;

/**/
- (void) setSecondaryHardwareMode: (BOOL) aValue;

@end

#endif

