#ifndef CIM_STATE_DEPOSIT_H
#define CIM_STATE_DEPOSIT_H

#define CIM_STATE_DEPOSIT id

#include "CimState.h"
#include "Deposit.h"
#include "system/os/all.h"
#include "CimCash.h"

/**
 * 	Estado cuando se esta realizando un deposito.
 *
 */
@interface CimStateDeposit :  CimState
{
	DEPOSIT myDeposit;
	OTIMER myInactivityTimer;
	OTIMER myCloseTimer;
	OMUTEX myMutex;
}

/**/
- (void) setDeposit: (DEPOSIT) aDeposit;

@end

#endif

