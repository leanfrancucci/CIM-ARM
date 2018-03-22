#ifndef DEPOSIT_MANAGER_H
#define DEPOSIT_MANAGER_H

#define DEPOSIT_MANAGER id

#include <Object.h>
#include "ctapp.h"
#include "Deposit.h"
#include "User.h"

/**
 *	
 *	<<singleton>>
 */
@interface DepositManager : Object
{
	unsigned long myLastDepositNumber;
}

/**
 *  Devuelve la unica instancia posible de esta clase
 */
+ getInstance;

/**
 *	Comienza un deposito del tipo pasado como parametro.
 *	@return el deposito creado.
 */
- (DEPOSIT) getNewDeposit: (USER) aUser 
		cimCash: (CIM_CASH) aCimCash
		depositType: (DepositType) aDepositType;

/**
 *	Finaliza un deposito.
 */
- (void) endDeposit: (DEPOSIT) aDeposit;

/**
 * Retorna el ultimo numero de deposito.
 */ 
- (unsigned long) getLastDepositNumber;

@end

#endif
