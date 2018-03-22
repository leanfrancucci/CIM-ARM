#include "Transaction.h"
#include "TransactionManager.h"
#include "DBExcepts.h"

#define checkActiveTransaction() if (transactionId == -1) THROW(TRANSACTION_NOT_STARTED_EX)

@implementation Transaction

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	transactionId = -1;
	return self;
}

/**/
- (void) startTransaction
{
	transactionId = [[TransactionManager getInstance] getNextTransactionId];
	[[TransactionManager getInstance] startTransaction: self];	
}

/**/ 
- (unsigned long) getTransactionId
{
	return transactionId;
}


/**/
- (void) commitTransaction
{
	checkActiveTransaction();
	[[TransactionManager getInstance] commitTransaction: self];
}

/**/
- (void) abortTransaction
{
	checkActiveTransaction();
	[[TransactionManager getInstance] abortTransaction: self];
}

/**/
- (void) appendRecord: (RECORD_SET) aRecordSet entityId: (int) anEntityId 
           entityPart: (int) anEntityPart recNo: (unsigned long) aRecNo
{
	checkActiveTransaction();
	[[TransactionManager getInstance] appendRecord: self recordSet: aRecordSet 
	             entityId: anEntityId entityPart: anEntityPart recNo: aRecNo];	
}

/**/
- (void) deleteRecord: (RECORD_SET) aRecordSet entityId: (int) anEntityId 
           entityPart: (int) anEntityPart recNo: (unsigned long) aRecNo
{
	checkActiveTransaction();
	[[TransactionManager getInstance] deleteRecord:  self recordSet: aRecordSet 
	             entityId: anEntityId entityPart: anEntityPart recNo: aRecNo];	
}

/**/
- (void) updateRecord: (RECORD_SET) aRecordSet entityId: (int) anEntityId 
           entityPart: (int) anEntityPart recNo: (unsigned long) aRecNo
{
	checkActiveTransaction();
	[[TransactionManager getInstance] updateRecord:  self recordSet: aRecordSet 
	             entityId: anEntityId entityPart: anEntityPart recNo: aRecNo];	
}   

@end
