#ifndef DEPOSIT_DAO_H
#define DEPOSIT_DAO_H

#define DEPOSIT_DAO id

#include <Object.h>
#include "ctapp.h"
#include "system/db/all.h"
#include "DataObject.h"
#include "Deposit.h"
#include "DepositDetail.h"

/** 
 *	<<singleton>>
 */
@interface DepositDAO: DataObject
{
	ABSTRACT_RECORDSET myDepositRS;
	ABSTRACT_RECORDSET myDepositDetailRS;
}

/**/
+ getInstance;

/**/
- (ABSTRACT_RECORDSET) getNewDepositRecordSet;

/**/
- (ABSTRACT_RECORDSET) getNewDepositDetailRecordSet;

/**/
- (void) saveDepositDetail: (DEPOSIT) aDeposit depositDetail: (DEPOSIT_DETAIL) aDepositDetail;

/**/
- (id) loadLast;

/**/
- (unsigned long) getLastDepositNumber;

/**/
- (id) getDepositFromRecordSetForTelesup: (ABSTRACT_RECORDSET) aDepositRS depositDetailRS: (ABSTRACT_RECORDSET) aDepositDetailRS;

/**/
- (ABSTRACT_RECORDSET) getDepositRecordSetByDate: (datetime_t) aFromDate to: (datetime_t) aToDate;

@end

#endif
