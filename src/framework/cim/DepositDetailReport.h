#ifndef DEPOSIT_DETAIL_REPORT_H
#define DEPOSIT_DETAIL_REPORT_H

#define DEPOSIT_DETAIL_REPORT id

#include <Object.h>
#include "system/util/all.h"
#include "User.h"
#include "CimDefs.h"

typedef struct {
  DepositType depositType;
  unsigned long number;
  char envelopeNumber[16];
  int currencyId;
  int cimCashId;
  money_t amount;
  int qty;
  DepositValueType depositValueType;
} ReportDetailItem;

/**
 *	
 */
@interface DepositDetailReport : Object
{
  
}

+ getInstance;

- (COLLECTION) generateDepositDetailReport: (unsigned long) aFromDepositNumber
  toDepositNumber: (unsigned long) aToDepositNumber
  user: (USER) aUser;

- (int) getTicketsCountByDepositType: (unsigned long) aFromDepositNumber
  toDepositNumber: (unsigned long) aToDepositNumber 
	depositType: (DepositType) aDepositType;

@end

#endif
