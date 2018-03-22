#ifndef  JVERIFY_BILL_FORM_H
#define  JVERIFY_BILL_FORM_H

#define  JVERIFY_BILL_FORM  id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JDate.h"
#include "JTime.h"
#include "Currency.h"

/**
 *	
 */
@interface  JVerifyBillForm: JCustomForm
{
	JLABEL myLabelTitle;
	JLABEL myLabelMessage;
	JLABEL myLabelBill;
	OTIMER myCloseTimer;
}


@end

#endif

