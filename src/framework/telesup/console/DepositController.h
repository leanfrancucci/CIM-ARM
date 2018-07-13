#ifndef DEPOSIT_CONTROLLER_H
#define DEPOSIT_CONTROLLER_H

#define DEPOSIT_CONTROLLER id

#include <Object.h>
#include "system/util/all.h"
#include "CimDefs.h"


/**
 *	Es el controller para efectuar una extraccion / apertura de puerta
 *	Maneja adicionalmente la apertura de una puerta interna.
 */
@interface DepositController : Object
{
    id tempManualDeposit;    
    id myObserver;
}

/**/

- (void) setObserver: (id) anObserver;
- (void) initManualDrop: (unsigned long) aUserId cashId: (int) aCashId referenceId: (int) aReferenceId applyTo: (char*) anApplyTo envelopeNumber: (char*) anEnvelopeNumber;
- (void) addDropDetail: (int) anAcceptorId depositValueType: (int) aDepositValueType currencyId: (int) aCurrencyId qty: (int) aQty amount: (money_t) anAmount;
- (void) printDropReceipt;
- (void) cancelDrop;
- (void) finishDrop;


@end

#endif
