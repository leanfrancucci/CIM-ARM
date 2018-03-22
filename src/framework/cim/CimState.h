#ifndef CIM_STATE_H
#define CIM_STATE_H

#define CIM_STATE id

#include "Object.h"
#include "AbstractAcceptor.h"
#include "Currency.h"
#include "Door.h"
#include "Cim.h"
#include "Deposit.h"

/**
 * 	Implementa un patron "State" para poder redefinir el comportamiento
 *	de los eventos del dispositivos dependiendo de la "operacion" que
 * 	se este realizando.
 */
@interface CimState :  Object
{
	CIM myCim;
	COLLECTION myObservers;
}

/**/
- (void) setCim: (CIM) aValue;

/**/
- (void) setObservers: (COLLECTION) anObservers;

/**
 *	Metodo que se ejecuta cada vez que arranca el estado.
 */
- (void) activateState;

/**
 *	Metodo que se ejecuta cada vez que se termina el estado.
 */
- (void) deactivateState;

/**
 *
 */
- (void) onDoorOpen: (DOOR) aDoor;

/**
 *
 */
- (void) onDoorClose: (DOOR) aDoor;

/**
 *
 */
- (void) onBillAccepted: (ABSTRACT_ACCEPTOR) anAcceptor currency: (CURRENCY) aCurrency amount: (money_t) anAmount  qty: (int) aQty;

/**/
- (void) onAcceptorError: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause;

/**
 *
 */
- (void) onBillAccepting: (ABSTRACT_ACCEPTOR) anAcceptor;

/**
 *
 */
- (void) onBillRejected: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause  qty: (int) aQty;

- (void) needMoreTime;

/**/
- (DEPOSIT) getDeposit;

@end

#endif

