#include "DBConnection.h"
#include "RecordSet.h"
#include "DB.h"
#include "Table.h"
#include "DBExcepts.h"

static DB_CONNECTION singleInstance = NULL;

@implementation DBConnection

/**/
+ new
{
	if (!singleInstance) singleInstance = [super new];
	return singleInstance;	
}

/**/
+ getInstance
{
	return [self new];
}

/**/
- (ABSTRACT_RECORDSET) createRecordSet: (char*) aTableName
{
	TABLE t = [[DB getInstance] getTable: aTableName];
	if (!t) THROW_MSG(TABLE_NOT_FOUND_EX, aTableName);
	return [t getNewRecordSet];
}

/**/
- (ABSTRACT_RECORDSET) createRecordSetFromQuery: (char*) aQuery
{
	THROW(ABSTRACT_METHOD_EX);
	return NULL;
}

/**/
- (ABSTRACT_RECORDSET) createRecordSetWithFilter: (char*) aTableName filter: (char *) aFilter
{
	THROW(ABSTRACT_METHOD_EX);
	return NULL;
}

/**/
- (ABSTRACT_RECORDSET) createRecordSetWithFilter: (char*) aTableName filter: (char *) aFilter orderFields: (char *) anOrderFields
{
  return [self createRecordSet: aTableName];
}

/**/
- (int) executeStatement: (char*) anStatement
{
	THROW(ABSTRACT_METHOD_EX);
	return 0;
}

/**/
- (int) executeStatement: (char*) anStatement transaction: (TRANSACTION) aTransaction
{
	THROW(ABSTRACT_METHOD_EX);
	return 0;
}

/**/
- (TRANSACTION) createTransaction
{
	return [Transaction new];
}

/**/
- (BOOL) tableHasBackup: (char*) aTableName
{
	TABLE t = [[DB getInstance] getTable: aTableName];
	if (!t) THROW_MSG(TABLE_NOT_FOUND_EX, aTableName);
	return [t hasBackup];
}

@end
