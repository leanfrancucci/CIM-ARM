#ifndef CIM_CASH_DAO_H
#define CIM_CASH_DAO_H

#define CIM_CASH_DAO id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"

/**
 *
 *	<<singleton>>
 */
@interface CimCashDAO : DataObject
{
}

+ getInstance;
+ (COLLECTION) loadAll;

/**/
- (void) addAcceptorByCash: (int) aCashId acceptorId: (int) anAcceptorId;
- (void) removeAcceptorByCash: (int) aCashId acceptorId: (int) anAcceptorId;


@end

#endif
