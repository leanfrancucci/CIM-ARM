#ifndef  JAMOUNT_EDIT_FORM_H
#define  JAMOUNT_EDIT_FORM_H

#define  JAMOUNT_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JCombo.h"

/**
 *
 */
@interface  JAmountEditForm: JEditForm
{
	JLABEL myLabelRoundType;
	JCOMBO	myComboRoundType;

	JLABEL myLabelItemsRoundDecimalQty;
	JTEXT	myTextItemsRoundDecimalQty;

	JLABEL myLabelSubtotalRoundDecimalQty;
	JTEXT	myTextSubtotalRoundDecimalQty;

	JLABEL myLabelTotalRoundDecimalQty;
	JTEXT	myTextTotalRoundDecimalQty;

	JLABEL myLabelTaxRoundDecimalQty;
	JTEXT	myTextTaxRoundDecimalQty;

}

/**/
- (void) onCreateForm;

@end

#endif

