#include "CimState.h"

//#define LOG(args...) doLog(0,args)

@implementation CimState


/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myObservers = NULL;
	myCim = NULL;
	return self;
}

/**/
- (void) setCim: (CIM) aValue
{
	myCim = aValue;
}

/**/
- (void) setObservers: (COLLECTION) anObservers
{
	myObservers = anObservers;
}

/**/
- (void) activateState
{
    //************************* logcoment
	//doLog(0, CimState -> activateState\n");
}

/**/
- (void) deactivateState
{
       //************************* logcoment
	//doLog(0, "CimState -> deactivateState\n");
}

/**/
- (void) onDoorOpen: (DOOR) aDoor
{
}

/**/
- (void) onDoorClose: (DOOR) aDoor
{
}

/**/
- (void) onBillAccepting: (ABSTRACT_ACCEPTOR) anAcceptor
{
}

/**/
- (void) onBillAccepted: (ABSTRACT_ACCEPTOR) anAcceptor currency: (CURRENCY) aCurrency amount: (money_t) anAmount  qty: (int) aQty
{
}

/**/
- (void) onAcceptorError: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause
{
}

/**/
- (void) onBillRejected: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause  qty: (int) aQty
{
}

/**/
- (void) needMoreTime
{
}

/**/
- (DEPOSIT) getDeposit
{
	return NULL;
}

@end

