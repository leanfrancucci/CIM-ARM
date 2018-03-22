#ifndef  JAUTOMATIC_DEPOSIT_FORM_H
#define  JAUTOMATIC_DEPOSIT_FORM_H

#define  JAUTOMATIC_DEPOSIT_FORM  id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JDate.h"
#include "JTime.h"
#include "User.h"
#include "JGrid.h"
#include "Deposit.h"
#include "CimCash.h"
#include "User.h"
#include "CashReference.h"

typedef enum {
	AutomaticDepositView_AMOUNT
 ,AutomaticDepositView_QTY
} AutomaticDepositView;

/**
 *	Pantalla de ingreso de deposito automatico (por validador)
 */
@interface  JAutomaticDepositForm: JCustomForm
{
	JLABEL myLabelTitle;
	JGRID  myGrid;
	DEPOSIT myDeposit;
	JFORM myNeedMoreTimeForm;
	OTIMER myCloseTimer;
	CIM_CASH myCimCash;
	CASH_REFERENCE myCashReference;
	USER myUser;
	AutomaticDepositView myCurrentView;
	char myEnvelopeNumber[50];
	char myApplyTo[50];
	int myTotalDecimals;
	BOOL myIsDepositOK;
	JFormModalResult myModalRes;
	BOOL myIsClosingDeposit;
	BOOL myIsViewMode;
}

/**/
- (BOOL) isDepositOk;

/**/
- (void) setCimCash: (CIM_CASH) anCimCash;

/**/
- (void) setUser: (USER) aUser;

/**/
- (void) setCashReference: (CASH_REFERENCE) aCashReference;

/**/
- (void) setEnvelopeNumber: (char *) anEnvelopeNumber;

/**/
- (void) setApplyTo: (char *) anApplyTo;


@end

#endif

