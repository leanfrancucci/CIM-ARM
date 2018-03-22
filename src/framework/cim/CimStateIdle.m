#include "CimStateIdle.h"
#include "Audit.h"

#include "InputKeyboardManager.h"

//#define LOG(args...) doLog(0,args)

@implementation CimStateIdle


/**/
- (void) onBillAccepted: (ABSTRACT_ACCEPTOR) anAcceptor currency: (CURRENCY) aCurrency amount: (money_t) anAmount  qty: (int) aQty
{
	char moneyStr[50];
	int i;

	[super onBillAccepted: anAcceptor currency: aCurrency amount: anAmount qty: aQty];
   //************************* logcoment
	//doLog(0,"CimStateIdle -> llego un billete de %s (%s)\n", [aCurrency getName], formatMoney(moneyStr, "", anAmount, 2, 40));
	if (![anAcceptor inValidatedMode]) {

    //************************* logcoment
        //doLog(0,"ERROR: nunca deberia estar habilitado el validador en este estado\n");
		formatMoney(moneyStr, [aCurrency getCurrencyCode], anAmount, 2, 40);
		[Audit auditEventCurrentUser: Event_BILL_STACKED_WITHOUT_DROP additional: moneyStr
				station: [[anAcceptor getAcceptorSettings] getAcceptorId]
				logRemoteSystem: FALSE];

	}

	// Notifico a los observadores de este evento
	if (myObservers == NULL) return;
	for (i = 0; i < [myObservers size]; ++i)
		[[myObservers at: i] onBillAccepted: anAcceptor currency: aCurrency amount: anAmount qty: aQty];

}


/**/
- (void) onBillRejected: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause  qty: (int) aQty
{
	int i;

	[super onBillRejected: anAcceptor cause: aCause qty: aQty];

    //************************* logcoment
	//doLog(0,"CimStateIdle -> se rechazo un billete, codigo = %d\n", aCause);

	// Notifico a los observadores de este evento
	if (myObservers == NULL) return;
	for (i = 0; i < [myObservers size]; ++i)
		[[myObservers at: i] onBillRejected: anAcceptor cause: aCause qty: aQty];

}

/**/
- (void) onBillAccepting: (ABSTRACT_ACCEPTOR) anAcceptor
{
	int i;

	[super onBillAccepting: anAcceptor];

	// Notifico a los observadores de este evento
	if (myObservers == NULL) return;
	for (i = 0; i < [myObservers size]; ++i)
		[[myObservers at: i] onBillAccepting: anAcceptor];

}

/**/
- (void) onAcceptorError: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause
{
}

@end

