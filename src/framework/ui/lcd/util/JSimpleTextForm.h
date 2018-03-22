#ifndef  JSIMPLE_TEXT_FORM_H
#define  JSIMPLE_TEXT_FORM_H

#define  JSIMPLE_TEXT_FORM id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JText.h"

/**
 *
 */
@interface  JSimpleTextForm: JCustomForm
{
	JLABEL myLabelTitle;
	JLABEL myLabelDescription;
	JTEXT myText;
	BOOL myNumericMode;
	BOOL myPasswordMode;
	int  myTextWidth;
	unsigned long myLongValue;
	char myTitle[41];
	char myDescription[41];
	char myTextValue[100];
	BOOL myScannigModeEnable;
	char myCaption1[10];
}

/**/
- (void) setTitle: (char *) aTitle;
- (void) setDescription: (char *) aDescription;

/**/
- (void) setNumericMode: (BOOL) aValue;
- (void) setPasswordMode: (BOOL) aPasswordMode;

/**/
- (void) setWidth: (int) aWidth;

/**/
- (void) setLongValue: (long) aValue;
- (long) getLongValue;

/**/
- (char *) getTextValue;
- (void) setTextValue: (char *) aValue;

/**/
- (void) setScanningModeEnable: (BOOL) aValue;

@end

#endif

