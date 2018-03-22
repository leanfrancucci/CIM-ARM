#ifndef  JCOMMERCIAL_ST_CODE_FORM_H
#define  JCOMMERCIAL_ST_CODE_FORM_H

#define  JCOMMERCIAL_ST_CODE_FORM id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JText.h"

/**
 *
 */
@interface  JCommercialStCodeForm: JCustomForm
{

	JLABEL myLabelTitle;

	JLABEL myLabelBlok1;
	JTEXT myTextBlok1;
	JLABEL myLabelBlok2;
	JTEXT myTextBlok2;
	JLABEL myLabelBlok3;
	JTEXT myTextBlok3;
	JLABEL myLabelBlok4;
	JTEXT myTextBlok4;
	JLABEL myLabelBlok5;
	JTEXT myTextBlok5;
	JLABEL myLabelBlok6;
	JTEXT myTextBlok6;
	JLABEL myLabelBlok7;
	JTEXT myTextBlok7;
	JLABEL myLabelBlok8;
	JTEXT myTextBlok8;
	JLABEL myLabelBlok9;
	JTEXT myTextBlok9;
	JLABEL myLabelBlok10;
	JTEXT myTextBlok10;
	JLABEL myLabelBlok11;
	JTEXT myTextBlok11;
	JLABEL myLabelBlok12;
	JTEXT myTextBlok12;
	JLABEL myLabelBlok13;
	JTEXT myTextBlok13;

	BOOL myViewMode;
	BOOL myROnly;
	char myTitle[21];
	char myTextCode[200];
	int  myLenghtText;
	int  chrCount;
	id   myCommercialState;
	int  myCurrentPosition;
	BOOL myCanPressSpace;
	BOOL myViewBackOption;
}

/**/
- (void) setTitle: (char *) aTitle;

/**/
- (void) setViewMode: (BOOL) aValue;

/**/
- (void) setViewBackOption: (BOOL) aValue;

/**/
- (char *) getTextCode;
- (void) setTextCode: (char *) aValue;

/**/
- (void) parsingCode;

/**/
- (void) setCommercialState: (id) aValue;

@end

#endif
