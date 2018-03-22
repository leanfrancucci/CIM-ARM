#ifndef  JMANUAL_DEPOSIT_LIST_FORM_H
#define  JMANUAL_DEPOSIT_LIST_FORM_H

#define  JMANUAL_DEPOSIT_LIST_FORM id

#include "JListForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JList.h"
#include "CimCash.h"
#include "CashReference.h"

/**
 *
 */
@interface JManualDepositListForm: JListForm
{
	CIM_CASH myCimCash;
	CASH_REFERENCE myCashReference;
	COLLECTION myAcceptedDepositValues;
}

/**/
- (void) setCimCash: (CIM_CASH) aCimCash;
- (void) setCashReference: (CASH_REFERENCE) aCashReference;

@end

#endif

