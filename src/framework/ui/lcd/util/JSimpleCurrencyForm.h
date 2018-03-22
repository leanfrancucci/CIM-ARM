#ifndef  JSIMPLE_CURRENCY_FORM_H
#define  JSIMPLE_CURRENCY_FORM_H

#define  JSIMPLE_CURRENCY_FORM id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JNumericText.h"

/**
 *
 */
@interface  JSimpleCurrencyForm: JCustomForm
{
	JLABEL myLabelTitle;
	JLABEL myLabelDescription;
	JLABEL myLabelCurrencyCode;
	JNUMERIC_TEXT myNumericText;

	money_t myValue;
	char myTitle[41];
	char myCurrencyCode[21];
	char myDescription[41];
}

/**/
- (void) setTitle: (char *) aTitle;
- (void) setDescription: (char *) aDescription;
- (void) setCurrencyCode: (char *) aCurrencyCode;

/**/
- (void) setMoneyValue: (money_t) aValue;
- (money_t) getMoneyValue;

@end

#endif

