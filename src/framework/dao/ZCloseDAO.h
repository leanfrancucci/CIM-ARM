#ifndef ZCLOSE_DAO_H
#define ZCLOSE_DAO_H

#define ZCLOSE_DAO id

#include <Object.h>
#include "ctapp.h"
#include "system/db/all.h"
#include "DataObject.h"
#include "ZClose.h"

/** 
 *	<<singleton>>
 */
@interface ZCloseDAO: DataObject
{
	ABSTRACT_RECORDSET myZCloseRS;
}

/**/
+ getInstance;

/**/
- (ABSTRACT_RECORDSET) getNewZCloseRecordSet;

/**/
- (id) loadLast;

/**/
- (id) loadLastWithDeposits;

/**/
- (unsigned long) getLastZCloseNumber;

/**/
- (datetime_t) getLastZCloseCloseTime;

/**/
- (unsigned long) getPrevZCloseNumber;

/**/
- (datetime_t) getPrevZCloseCloseTime;

/**/
- (void) moveFirstZClose: (ABSTRACT_RECORDSET) aRecordSet;

/**/
- (ABSTRACT_RECORDSET) getZCloseRecordSetByDate: (datetime_t) aFromDate to: (datetime_t) aToDate;

- (BOOL) findCashCloseById: (ABSTRACT_RECORDSET) aRecordSet value: (unsigned long) anId;
- (BOOL) findZCloseById: (ABSTRACT_RECORDSET) aRecordSet value: (unsigned long) anId;

/**/
- (id) loadLastCashClose: (int) aCimCashId;
- (id) loadCashCloseById: (unsigned long) aCashCloseId;

/**/
- (unsigned long) getLastCashCloseNumber;


@end

#endif
