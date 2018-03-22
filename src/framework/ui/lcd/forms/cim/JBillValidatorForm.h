#ifndef  JBILL_VALIDATOR_FORM_H
#define  JBILL_VALIDATOR_FORM_H

#define  JBILL_VALIDATOR_FORM  id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JDate.h"
#include "JTime.h"
#include "User.h"
#include "BillValidator.h"


/**
 *	Muestra una pantalla con informacion de la version del sistema
 */
@interface  JBillValidatorForm: JCustomForm
{
	JLABEL myLabelTitle;
	JLABEL myLabelTotalTitle;
	JLABEL myLabelTotal;
	JLABEL myLabelStatus;
	BILL_VALIDATOR myBillValidator;
}

@end

#endif

