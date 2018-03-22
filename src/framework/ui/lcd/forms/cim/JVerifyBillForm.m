#include "JVerifyBillForm.h"
#include "MessageHandler.h"
#include "AbstractAcceptor.h"
#include "CimManager.h"
#include "Buzzer.h"
#include "Audit.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)


@implementation  JVerifyBillForm


/**/
- (void) onCreateForm
{
	[super onCreateForm];

	myLabelTitle = [self addLabelFromResource: RESID_VALIDATION_MODE default: "Modo de Validacion"];

	myLabelMessage = [self addLabelFromResource: RESID_INSERT_BILL default: "Inserte el Dinero..."];
	[myLabelMessage setAutoSize: FALSE];
	[myLabelMessage setWidth: 20];

	myLabelBill = [self addLabel: ""];
	[myLabelBill setAutoSize: FALSE];
	[myLabelBill setWidth: 20];

	[[CimManager getInstance] startValidationMode];

	// audito el inicio de la validacion de billetes
	[Audit auditEventCurrentUser: Event_START_BILL_VALIDATION additional: "" station: 0 logRemoteSystem: FALSE];

	[[CimManager getInstance] addObserver: self];

}

/**/
- (char *) getCaption1
{	
 	//return NULL;
	return getResourceStringDef(RESID_BACK_KEY, "atras");
}

/**/
- (char *) getCaption2
{	
	return NULL;
}

/**/
- (void) onMenu1ButtonClick
{
	[[CimManager getInstance] removeObserver: self];
	[[CimManager getInstance] stopValidationMode];

	// audito el fin de la validacion de billetes
	[Audit auditEventCurrentUser: Event_END_BILL_VALIDATION additional: "" station: 0 logRemoteSystem: FALSE];
	[self closeForm];
}

/**/
- (void) onBillAccepting: (ABSTRACT_ACCEPTOR) anAcceptor
{
	[myLabelMessage setCaption: getResourceStringDef(RESID_VERIFYING, "Verificando...")];
	[myLabelBill setCaption: ""]; 
}

/**/
- (void) onAcceptorError: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause
{
}

/**/
- (void) onBillAccepted: (ABSTRACT_ACCEPTOR) anAcceptor currency: (CURRENCY) aCurrency amount: (money_t) anAmount  qty: (int) aQty
{
	char buf[60];
	char amountstr[50];

	[myLabelMessage setCaption: getResourceStringDef(RESID_BILL_VERIFIED, "Billete Verificado!")];

	formatMoney(amountstr, "", anAmount, 2, 20);
	formatResourceStringDef(buf, RESID_VALUES, "Valor: %-3s %9s ", [aCurrency getCurrencyCode], amountstr);
	[myLabelBill setCaption: buf];

	[self paintComponent];
}

/**/
- (void) onBillRejected: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause  qty: (int) aQty
{
	char buf[60];
	char *errorDescription;

	errorDescription = [anAcceptor getRejectedDescription: aCause];

	sprintf(buf, "Error: %d", aCause);
	[myLabelMessage setCaption: buf];

	sprintf(buf, "%-20s", errorDescription == NULL? "": errorDescription);
  [myLabelBill setCaption: buf];

	[self paintComponent];

	[[Buzzer getInstance] buzzerBeep: 800];

}

/**/
- (void) onCloseDeposit { }

/**/
- (void) onOpenDeposit { }

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) anIsPressed
{

	if (!anIsPressed)
			return FALSE;

	if ((aKey == UserInterfaceDefs_KEY_DOWN) || (aKey == UserInterfaceDefs_KEY_UP))
		 return FALSE;

	return [super doKeyPressed: aKey isKeyPressed: anIsPressed];

}

@end
