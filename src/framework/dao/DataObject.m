#include "DataObject.h"
#include "util.h"
#include "SafeBoxRecordSet.h"
#include "CimBackup.h"

@implementation DataObject

+ new
{
	return [[super new] initialize];
}

- initialize
{
	return self;
}

- (id) loadById: (unsigned long) anObjectId
{
	THROW(ABSTRACT_METHOD_EX);
	return NULL;
}

- (void) store: (id) anObject
{
	THROW(ABSTRACT_METHOD_EX);
}

- (COLLECTION) loadAll
{
	THROW(ABSTRACT_METHOD_EX);
	return NULL;
}

- (void) validateFields: (id) anObject
{
	THROW(ABSTRACT_METHOD_EX);
}

- (void) loadDefaultFields: (id) anObject
{
	THROW(ABSTRACT_METHOD_EX);
}

/**/
- (void) doUpdateBackupById: (char*) aField value: (unsigned long) aValue backupRecordSet: (ABSTRACT_RECORDSET) aBackupRecordSet currentRecordSet: (ABSTRACT_RECORDSET) aCurrentRecordSet tableName: (char*) aTableName
{
	id cimBck = [CimBackup getInstance];
	TABLE table = NULL;
	
	// verifico si la tabla esta ok o corrupta
	table = [cimBck isCheckTableOk: aTableName];
	if (!table) {
		[aBackupRecordSet free];
		return;
	}

	TRY

		// marco la tabla en 1
		[cimBck checkTable: table bitValue: 1];

		[aBackupRecordSet open];

		if ([aBackupRecordSet findById: aField value: aValue]) {
			[aBackupRecordSet setRecordBuffer: [aCurrentRecordSet getRecordBuffer]];
			[aBackupRecordSet save];
			// marco la tabla en 0
			[cimBck checkTable: table bitValue: 0];
		}

		[aBackupRecordSet close];
		[aBackupRecordSet free];

	CATCH

		[aBackupRecordSet close];
		[aBackupRecordSet free];

	END_TRY
	
}

/**/
- (void) doUpdateBackup: (ABSTRACT_RECORDSET) aBackupRecordSet currentRecordSet: (ABSTRACT_RECORDSET) aCurrentRecordSet dataSearcher: (id) aDataSearcher tableName: (char*) aTableName
{
	id cimBck = [CimBackup getInstance];
	TABLE table = NULL;

	// verifico si la tabla esta ok o corrupta
	table = [cimBck isCheckTableOk: aTableName];
	if (!table) {
		[aBackupRecordSet free];
		if (aDataSearcher) [aDataSearcher free];
		return;
	}

	TRY

		// marco la tabla en 1
		[cimBck checkTable: table bitValue: 1];

		[aBackupRecordSet open];

		if ([aDataSearcher find]) {
			[aBackupRecordSet setRecordBuffer: [aCurrentRecordSet getRecordBuffer]];
			[aBackupRecordSet save];

			// marco la tabla en 0
			[cimBck checkTable: table bitValue: 0];
		}

		[aBackupRecordSet close];
		[aBackupRecordSet free];
		if (aDataSearcher) [aDataSearcher free];

	CATCH

		[aBackupRecordSet close];
		[aBackupRecordSet free];
		if (aDataSearcher) [aDataSearcher free];

	END_TRY

}

/**/
- (void) doAddBackup: (ABSTRACT_RECORDSET) aBackupRecordSet currentRecordSet: (ABSTRACT_RECORDSET) aCurrentRecordSet tableName: (char*) aTableName
{
	id cimBck = [CimBackup getInstance];
	TABLE table = NULL;

	// verifico si la tabla esta ok o corrupta
	table = [cimBck isCheckTableOk: aTableName];
	if (!table) {
		[aBackupRecordSet free];
		return;
	}

	TRY

		// marco la tabla en 1
		[cimBck checkTable: table bitValue: 1];

		[aBackupRecordSet open];
		[aBackupRecordSet add];
	
		[aBackupRecordSet setRecordBuffer: [aCurrentRecordSet getRecordBuffer]];
		[aBackupRecordSet save];

		// marco la tabla en 0
		[cimBck checkTable: table bitValue: 0];

		[aBackupRecordSet close];
		[aBackupRecordSet free];

	CATCH

		[aBackupRecordSet close];
		[aBackupRecordSet free];

	END_TRY		

}

/**/
- (void) doUpdateDenominationBck: (ABSTRACT_RECORDSET) aBackupRecordSet currentRecordSet: (ABSTRACT_RECORDSET) aCurrentRecordSet depositValueType: (int) aDepositValueType acceptorId: (int) anAcceptorId currencyId: (int) aCurrencyId denomination: (id) aDenomination tableName: (char*) aTableName
{
	BOOL found = FALSE;
	id cimBck = [CimBackup getInstance];
	TABLE table = NULL;

	// verifico si la tabla esta ok o corrupta
	table = [cimBck isCheckTableOk: aTableName];
	if (!table) {
		[aBackupRecordSet free];
		return;
	}

	TRY

		// marco la tabla en 1
		[cimBck checkTable: table bitValue: 1];

		[aBackupRecordSet open];

		[aBackupRecordSet moveFirst];
	
		while (![aBackupRecordSet eof]) {
	
			if ( ([aBackupRecordSet getCharValue: "DEPOSIT_VALUE_TYPE"] == aDepositValueType) && 
					([aBackupRecordSet getShortValue: "ACCEPTOR_ID"] == anAcceptorId) && 
					([aBackupRecordSet getShortValue: "CURRENCY_ID"] == aCurrencyId) && 
					([aBackupRecordSet getMoneyValue: "DENOMINATION"] == [aDenomination getAmount]) ) {
				found = TRUE;
				break;
			}
	
			[aBackupRecordSet moveNext];
		}

		if (found) {
			[aBackupRecordSet setRecordBuffer: [aCurrentRecordSet getRecordBuffer]];
			[aBackupRecordSet save];

			// marco la tabla en 0
			[cimBck checkTable: table bitValue: 0];
		}

		[aBackupRecordSet close];
		[aBackupRecordSet free];

	CATCH

		[aBackupRecordSet close];
		[aBackupRecordSet free];

	END_TRY

}

/**/
- (void) doUpdateDualAccessBck: (ABSTRACT_RECORDSET) aBackupRecordSet currentRecordSet: (ABSTRACT_RECORDSET) aCurrentRecordSet dataSearcher: (id) aDataSearcher dataSearcher2: (id) aDataSearcher2 tableName: (char*) aTableName
{
	BOOL found = FALSE;
	id cimBck = [CimBackup getInstance];
	TABLE table = NULL;

	// verifico si la tabla esta ok o corrupta
	table = [cimBck isCheckTableOk: aTableName];
	if (!table) {
		[aBackupRecordSet free];
		if (aDataSearcher) [aDataSearcher free];
		if (aDataSearcher2) [aDataSearcher2 free];
		return;
	}

	TRY

		// marco la tabla en 1
		[cimBck checkTable: table bitValue: 1];

		[aBackupRecordSet open];

		if ([aDataSearcher find])
			found = TRUE;
		else if ([aDataSearcher2 find]) found = TRUE;

		if (found) {
			[aBackupRecordSet setRecordBuffer: [aCurrentRecordSet getRecordBuffer]];
			[aBackupRecordSet save];

			// marco la tabla en 0
			[cimBck checkTable: table bitValue: 0];
		}

		[aBackupRecordSet close];
		[aBackupRecordSet free];
		if (aDataSearcher) [aDataSearcher free];
		if (aDataSearcher2) [aDataSearcher2 free];

	CATCH

		[aBackupRecordSet close];
		[aBackupRecordSet free];
		if (aDataSearcher) [aDataSearcher free];
		if (aDataSearcher2) [aDataSearcher2 free];

	END_TRY

}

/**/
- (void) doUpdateBackupUserById: (char*) aField value: (unsigned long) aValue backupRecordSet: (ABSTRACT_RECORDSET) aBackupRecordSet currentRecordSet: (ABSTRACT_RECORDSET) aCurrentRecordSet tableName: (char*) aTableName
{
	id cimBck = [CimBackup getInstance];
	TABLE table = NULL;
	
	// verifico si la tabla esta ok o corrupta
	table = [cimBck isCheckTableOk: aTableName];
	if (!table) {
		[aBackupRecordSet free];
		return;
	}

	TRY

		// marco la tabla en 1
		[cimBck checkTable: table bitValue: 1];

		// si aun no fue inicializada la tabla de backup escribo directamente en ella
		if ([table getGlobalData] == NULL) {
			if ([aBackupRecordSet updateRecordToFile: aValue recordBuffer: [aCurrentRecordSet getRecordBuffer] fieldName: aField]) {
				// marco la tabla en 0
				[cimBck checkTable: table bitValue: 0];
			}
			
		} else {

			[aBackupRecordSet open];
			if ([aBackupRecordSet findById: aField value: aValue]) {
				[aBackupRecordSet setRecordBuffer: [aCurrentRecordSet getRecordBuffer]];
				[aBackupRecordSet save];
				// marco la tabla en 0
				[cimBck checkTable: table bitValue: 0];
			}

		}

		[aBackupRecordSet close];
		[aBackupRecordSet free];

	CATCH

		[aBackupRecordSet close];
		[aBackupRecordSet free];

	END_TRY
	
}

- (void) doAddUserBackup: (ABSTRACT_RECORDSET) aBackupRecordSet currentRecordSet: (ABSTRACT_RECORDSET) aCurrentRecordSet tableName: (char*) aTableName value: (unsigned long) aValue
{
	id cimBck = [CimBackup getInstance];
	TABLE table = NULL;
	unsigned long lastId;

	// verifico si la tabla esta ok o corrupta
	table = [cimBck isCheckTableOk: aTableName];
	if (!table) {
		[aBackupRecordSet free];
		return;
	}

	TRY

		// marco la tabla en 1
		[cimBck checkTable: table bitValue: 1];

		// si aun no fue inicializada la tabla de backup escribo directamente en ella
		if ([table getGlobalData] == NULL) {
			if ([aBackupRecordSet addRecordToFile: aValue recordBuffer: [aCurrentRecordSet getRecordBuffer]]) {
				// marco la tabla en 0
				[cimBck checkTable: table bitValue: 0];
			}
			
		} else {

			[aBackupRecordSet open];
			[aBackupRecordSet add];
		
			[aBackupRecordSet setRecordBuffer: [aCurrentRecordSet getRecordBuffer]];
			[aBackupRecordSet save];
	
			// marco la tabla en 0
			[cimBck checkTable: table bitValue: 0];

		}

		[aBackupRecordSet close];
		[aBackupRecordSet free];

	CATCH

		[aBackupRecordSet close];
		[aBackupRecordSet free];

	END_TRY		

}

@end
