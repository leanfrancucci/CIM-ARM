#ifndef CASH_REFERENCE_DAO_H
#define CASH_REFERENCE_DAO_H

#define CASH_REFERENCE_DAO id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"

/**
 *
 *	<<singleton>>
 */
@interface CashReferenceDAO : DataObject
{
}

+ getInstance;
+ (COLLECTION) loadAll;



@end

#endif
