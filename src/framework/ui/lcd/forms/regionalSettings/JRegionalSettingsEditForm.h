#ifndef  JREGIONAL_SETTINGS_EDIT_FORM_H
#define  JREGIONAL_SETTINGS_EDIT_FORM_H

#define  JREGIONAL_SETTINGS_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JDate.h"
#include "JTime.h"
#include "JCombo.h"
#include "ctapp.h"

/**
 *
 */
@interface  JRegionalSettingsEditForm: JEditForm
{
	JLABEL myLabelDate;
	JDATE myDateDateText;

	JLABEL myLabelTime;
	JTIME myTimeTimeText;

	JLABEL myLabelTimeZone;
	JCOMBO myComboTimeZone;

	JLABEL myLabelMoneySymbol;
	JTEXT	myTextMoneySymbol;

	JLABEL myLabelLanguage;
	JCOMBO myComboLanguage;

	JLABEL myLabelDateFormat;
 	JCOMBO myComboDateFormat;

	LanguageType myOriginalLanguage;
	
  datetime_t realTime;
  datetime_t realDate;
	BOOL wasChangedTimeZone;
}

@end

#endif

