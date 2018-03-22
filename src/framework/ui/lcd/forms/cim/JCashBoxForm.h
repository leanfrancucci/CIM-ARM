#ifndef  JCASH_BOX_FORM_H
#define  JCASH_BOX_FORM_H

#define  JCASH_BOX_FORM  id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JDate.h"
#include "JTime.h"
#include "User.h"
#include "BillValidator.h"
#include "system/db/all.h"

/**
 *	
 */
@interface  JCashBoxForm: JCustomForm
{
	JLABEL myLabelTitle;
	JLABEL myLabelTotal;
	JLABEL myLabelQty;
	BILL_VALIDATOR myBillValidator;	
	ABSTRACT_RECORDSET myCashBoxRS;
}

@end

#endif

