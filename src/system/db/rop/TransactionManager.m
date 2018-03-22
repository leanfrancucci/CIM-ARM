#include "TransactionManager.h"
#include "DBExcepts.h"
#include "DB.h"
#include "log.h"

//#define printd(args...) doLog(args)
#define printd(args...) 

static TRANSACTION_MANAGER singleInstance = NULL;

@implementation TransactionManager

/**/
- (void) recover;

/**/
- (void) deleteLog;


/**/
+ new
{
	if (!singleInstance) singleInstance = [[super new] initialize];
	return singleInstance;
}

/**/
- initialize
{
	mutex = [OMutex new];
	nextTransactionId = 1;
	transactionRecordSet = [[RecordSet new] initWithTableName: "transactions"];
	
	[transactionRecordSet open];
	[self recover];
	[transactionRecordSet close];
	
	[self deleteLog];
	
	[transactionRecordSet open];
	
	return self;
}

/**/
- (void) stop
{
	[transactionRecordSet close];
}

/**/
- free
{
	[mutex unLock];
	[mutex free];
	return [super free];
}

/**/
+ getInstance
{
	return [self new];
}

/**/
- (unsigned long) getNextTransactionId
{
	unsigned long tid;
	
	[mutex lock];
	
	tid = nextTransactionId;
	nextTransactionId++;
	
	[mutex unLock];
	
	return tid;
}

/**/
- (void) saveOperation: (unsigned long) aTransactionId operation: (int) anOperation
				 entityId : (int) anEntityId entityPart: (int) anEntityPart 
				 recNo: (unsigned long) aRecNo
{

	printd("TransactionManager -> TransactionId %ld, Operation %d, EntityId %d, EntityPart %d, RecordNumber %ld\n",
					aTransactionId, anOperation, anEntityId, anEntityPart, aRecNo);
	
	[transactionRecordSet add];						
	[transactionRecordSet setLongValue: "TRANSACTION_ID" value: aTransactionId];
	[transactionRecordSet setCharValue: "OPERATION" value: anOperation];
	[transactionRecordSet setShortValue: "ENTITY_ID" value: anEntityId];
	[transactionRecordSet setShortValue: "ENTITY_PART" value: anEntityPart];
	[transactionRecordSet setLongValue: "REC_NO" value: aRecNo];
	[transactionRecordSet save];
		
}

/**/
- (void) startTransaction: (TRANSACTION) aTransaction
{
	[mutex lock];
}

/**/
- (void) commitTransaction: (TRANSACTION) aTransaction
{
	[self saveOperation: [aTransaction getTransactionId] operation: OP_COMMIT 
	      entityId: 0 entityPart: 0 recNo: 0];
  [mutex unLock];				
}

/**/
- (void) abortTransaction: (TRANSACTION) aTransaction
{
	[self recover];
	[self saveOperation: [aTransaction getTransactionId] operation: OP_ABORT 
	      entityId: 0 entityPart: 0 recNo: 0];
	[mutex unLock];
}

/**/
- (void) appendRecord: (TRANSACTION) aTransaction recordSet: (RECORD_SET) aRecordSet entityId: (int) anEntityId 
           entityPart: (int) anEntityPart recNo: (unsigned long) aRecNo
{
	[self saveOperation: [aTransaction getTransactionId] operation: OP_APPEND 
	      entityId: anEntityId entityPart: anEntityPart recNo: aRecNo];	
}

/**/
- (void) deleteRecord: (TRANSACTION) aTransaction recordSet: (RECORD_SET) aRecordSet entityId: (int) anEntityId 
           entityPart: (int) anEntityPart recNo: (unsigned long) aRecNo
{
	[self saveOperation: [aTransaction getTransactionId] operation: OP_DELETE 
	      entityId: anEntityId entityPart: anEntityPart recNo: aRecNo];	
}

/**/
- (void) updateRecord: (TRANSACTION) aTransaction recordSet: (RECORD_SET) aRecordSet entityId: (int) anEntityId 
           entityPart: (int) anEntityPart recNo: (unsigned long) aRecNo
{
	[self saveOperation: [aTransaction getTransactionId] operation: OP_UPDATE 
	      entityId: anEntityId entityPart: anEntityPart recNo: aRecNo];	
}   

/**/
- (void) undoAdd: (int) anEntityId entityPart: (int) anEntityPart recNo: (unsigned long) aRecNo 
{
	char name[100];
	DATABASE db = [DB getInstance];
	TABLE t = [db getTableById: anEntityId];
	ABSTRACT_RECORDSET rs;
	
	//doLog(0,"TransactionManager --> undoAdd\n");
	//doLog(0,"Undoing add for table %d, part %d, recno %ld\n", anEntityId, anEntityPart, aRecNo);
	//doLog(0,"TransactionManager --> table %s\n", [t getName]);
	
	if (anEntityPart > 0) {
		sprintf(name, "%s_%d", [t getName], anEntityPart - 1);
		[db createTableWithSchema: name schema: (char*)[t getName]];
	} else if (anEntityPart == -1) {
		sprintf(name, "%s_index", [t getName]);
		[db createTableWithSchema: name schema: name];
	} else {
		strcpy(name, [t getName]);
	}
	
	//doLog(0,"TransactionManager --> deleting record %ld from file %s\n", aRecNo, name);
	
	rs = [[RecordSet new] initWithTableName: name];
	[rs open];

	if (aRecNo >= [rs getRecordCount]) {
		//doLog(0,"TransactionManager -> no borro el registro %d porque no se grabo, recordCount = %d\n", aRecNo, [rs getRecordCount]);
	} else {
		[rs seek: SEEK_SET offset: aRecNo];
		[rs delete];
	}

	[rs close];

	[[rs getTable] loadAutoIncValue];

	[rs free];
}

/**/
- (void) deleteLog
{
	char file[100];
	int result;
		
	strcpy(file, [[DB getInstance] getDataBasePath]);
	strcat(file, "transactions.dat");
	printd("TransactionManager --> removing file %s\n", file);
	result = remove(file);
	
	if (result == -1 && geterrno() != ENOENT) THROW(CANNOT_REMOVE_TRANSACTION_LOG_EX);
	
}

/**/
- (void) recover
{
	long tid = -1;
	int entityId, entityPart;
	int operation;
	unsigned long recNo;
	
	printd("TransactionManager --> recover\n");
	
	// no hay ninguna transaccion en el archivo
	if ([transactionRecordSet getRecordCount] == 0) return;
	
	[transactionRecordSet moveLast];
	
	// la ultima transaccion fue un commit o un abort, asi que esta todo bien
	operation = [transactionRecordSet getCharValue:"OPERATION"];
	if (operation == OP_COMMIT || operation == OP_ABORT) return;
	
  // obtengo el ultimo id de transaccion y recorro la lista hacia atras, deshaciendo las
	// operaciones
	tid = [transactionRecordSet getLongValue: "TRANSACTION_ID"];
	
	while ( ![transactionRecordSet bof] ) {
		
		if ([transactionRecordSet getLongValue: "TRANSACTION_ID"] != tid) break;

		entityId = [transactionRecordSet getShortValue: "ENTITY_ID"];
		entityPart = [transactionRecordSet getShortValue: "ENTITY_PART"];
		operation = [transactionRecordSet getCharValue: "OPERATION"];
		recNo = [transactionRecordSet getLongValue: "REC_NO"];
		
		if (operation == OP_APPEND) [self undoAdd: entityId entityPart: entityPart recNo: recNo];
		
		[transactionRecordSet movePrev];
		
	}
	
}

@end
