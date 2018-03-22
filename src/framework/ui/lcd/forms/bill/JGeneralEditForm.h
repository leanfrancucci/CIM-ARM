#ifndef  JGENERAL_EDIT_FORM_H
#define  JGENERAL_EDIT_FORM_H

#define  JGENERAL_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JCombo.h"
#include "JText.h"
#include "JNumericText.h"
#include "JDate.h"

/**
 *
 */
@interface  JGeneralEditForm: JEditForm
{
	JLABEL myLabelTaxDiscrimination;
	JCOMBO	myComboTaxDiscrimination;
  
	JLABEL myLabelTicketType;
	JCOMBO	myComboTicketType;
  
  JLABEL myLabelOpenCashDrawer;
  JCOMBO myComboOpenCashDrawer;

	JLABEL myLabelMinAmount;
	JNUMERIC_TEXT myNumericTextMinAmount;

	JLABEL myLabelIdentifierDescription;
	JTEXT myTextIdentifierDescription;

	JLABEL myLabelAuthorizationCode;
	JTEXT myTextAuthorizationCode;

	JLABEL myLabelVigencyDate;
	JDATE myDateVigencyDate;
}

/**/
- (void) onCreateForm;

@end

#endif

