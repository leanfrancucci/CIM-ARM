#include "ZCloseDAO.h"
#include "system/db/all.h"
#include "UserManager.h"
#include "CimBackup.h"
#include "FilteredRecordSet.h"
#include "CimManager.h"

//#define LOG(args...) doLog(0,args)
//#define LOG(args...)

@implementation ZCloseDAO

static ZCLOSE_DAO singleInstance = NULL;

/**/
- (ABSTRACT_RECORDSET) getNewZCloseRecordSet
{
	ABSTRACT_RECORDSET recordSet;

	recordSet = [[DBConnection getInstance] createRecordSet: "zclose"];
	[recordSet setDateField: "CLOSE_TIME"];
	[recordSet setIdField: "NUMBER"];

	return recordSet;
}

/**/
- initialize
{
	[super initialize];

	myZCloseRS = [self getNewZCloseRecordSet];
	[myZCloseRS open];

	return self;
}

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
- free
{
	[myZCloseRS free];
	return [super free];
}

/**/
- (void) store: (id) anObject
{
	//doLog(0,"DepositDAO -> Grabando ZClose...\n");

	[myZCloseRS add];

	[myZCloseRS setLongValue: "NUMBER" value: [anObject getNumber]];
	[myZCloseRS setLongValue: "FROM_DEPOSIT_NUMBER" value: [anObject getFromDepositNumber]];
	[myZCloseRS setLongValue: "TO_DEPOSIT_NUMBER" value: [anObject getToDepositNumber]];
	[myZCloseRS setDateTimeValue: "OPEN_TIME" value: [anObject getOpenTime]];
	[myZCloseRS setDateTimeValue: "CLOSE_TIME" value: [anObject getCloseTime]];
	[myZCloseRS setShortValue: "REJECTED_QTY" value: [anObject getRejectedQty]];
	if ([anObject getUser])
		[myZCloseRS setLongValue: "USER_ID" value: [[anObject getUser] getUserId]];

	[myZCloseRS setCharValue: "CLOSE_TYPE" value: [anObject getCloseType]];
	[myZCloseRS setLongValue: "FROM_CLOSE_NUMBER" value: [anObject getFromCloseNumber]];
	[myZCloseRS setLongValue: "TO_CLOSE_NUMBER" value: [anObject getToCloseNumber]];
	if ([anObject getCimCash])
		[myZCloseRS setShortValue: "CIM_CASH_ID" value: [[anObject getCimCash] getCimCashId]];

	[myZCloseRS save];

	//[[CimBackup getInstance] syncBackupFile: "zclose"];
	[[CimBackup getInstance] syncRecord: "zclose" buffer: [myZCloseRS getRecordBuffer]];

	//doLog(0,"DepositDAO -> termino de ZClose...\n");

}

/**/
- (id) getZCloseFromRecordSet: (ABSTRACT_RECORDSET) aZCloseRS 
{
	ZCLOSE zClose;

	// Creo el deposito con los datos
	zClose = [ZClose new];
	[zClose setNumber: [aZCloseRS getLongValue: "NUMBER"]];
	[zClose setFromDepositNumber: [aZCloseRS getLongValue: "FROM_DEPOSIT_NUMBER"]];
	[zClose setToDepositNumber: [aZCloseRS getLongValue: "TO_DEPOSIT_NUMBER"]];
	[zClose setOpenTime: [aZCloseRS getDateTimeValue: "OPEN_TIME"]];
	[zClose setCloseTime: [aZCloseRS getDateTimeValue: "CLOSE_TIME"]];
	[zClose setRejectedQty: [aZCloseRS getShortValue: "REJECTED_QTY"]];
	if ([aZCloseRS getLongValue: "USER_ID"] > 0)
		[zClose setUser: [[UserManager getInstance] getUserFromCompleteList: [aZCloseRS getLongValue: "USER_ID"]]];

	[zClose setCloseType: [aZCloseRS getCharValue: "CLOSE_TYPE"]];
	[zClose setFromCloseNumber: [aZCloseRS getLongValue: "FROM_CLOSE_NUMBER"]];
	[zClose setToCloseNumber: [aZCloseRS getLongValue: "TO_CLOSE_NUMBER"]];
	if ([aZCloseRS getShortValue: "CIM_CASH_ID"] > 0)
		[zClose setCimCash: [[CimManager getInstance] getCimCashById: [aZCloseRS getShortValue: "CIM_CASH_ID"]]];

	return zClose;	
}

/**/
- (id) loadById: (unsigned long) anId
{
	/** @todo: VER SI UTILIZO OTRO RECORDSET O ES SIEMPRE EL MISMO */
	//if (![myZCloseRS findById: "NUMBER" value: anId]) return NULL;
	if (![myZCloseRS moveLast]) return NULL;

	// Busco de atras para adelante el ultimo Z que tenga asociados depositos

	while (![myZCloseRS bof]) {

		if ([myZCloseRS getLongValue: "NUMBER"] == anId &&
				[myZCloseRS getCharValue: "CLOSE_TYPE"] == CloseType_END_OF_DAY) {
				return [self getZCloseFromRecordSet: myZCloseRS];
		}

		[myZCloseRS movePrev];

	}

	return NULL;
}

/**/
- (BOOL) findCashCloseById: (ABSTRACT_RECORDSET) aRecordSet value: (unsigned long) anId
{

	if (![aRecordSet moveLast]) return FALSE;

	// Busco de atras para adelante el ultimo Z que tenga asociados depositos
	while (![aRecordSet bof]) {
		if ([aRecordSet getCharValue: "CLOSE_TYPE"] == CloseType_CASH_CLOSE) {
			if ([aRecordSet getLongValue: "NUMBER"] == anId) return TRUE;
			if ([aRecordSet getLongValue: "NUMBER"] < anId) return FALSE;
		}
		[aRecordSet movePrev];
	}
	return FALSE;
}

/**/
- (BOOL) findZCloseById: (ABSTRACT_RECORDSET) aRecordSet value: (unsigned long) anId
{
	if (![aRecordSet moveLast]) return FALSE;

	// Busco de atras para adelante el ultimo Z que tenga asociados depositos
	while (![aRecordSet bof]) {

		if ([aRecordSet getCharValue: "CLOSE_TYPE"] == CloseType_END_OF_DAY) {

			if ([aRecordSet getLongValue: "NUMBER"] == anId) return TRUE;
			if ([aRecordSet getLongValue: "NUMBER"] < anId) return FALSE;

		}

		[aRecordSet movePrev];

	}

	return FALSE;
}

/**/
- (void) moveFirstZClose: (ABSTRACT_RECORDSET) aRecordSet
{
	[aRecordSet moveFirst];

	// Busco el primer Z
	while (![aRecordSet eof]) {

		if ([aRecordSet getCharValue: "CLOSE_TYPE"] == CloseType_END_OF_DAY) break;

		[aRecordSet moveNext];

	}

}

/**/
- (id) loadLastWithDeposits
{
	/** @todo: VER SI UTILIZO OTRO RECORDSET O ES SIEMPRE EL MISMO */
	if (![myZCloseRS moveLast]) return NULL;

	// Busco de atras para adelante el ultimo Z que tenga asociados depositos

	while (![myZCloseRS bof]) {

		if ([myZCloseRS getLongValue: "FROM_DEPOSIT_NUMBER"] > 0 &&
				[myZCloseRS getLongValue: "TO_DEPOSIT_NUMBER"] > 0 &&
				[myZCloseRS getCharValue: "CLOSE_TYPE"] == CloseType_END_OF_DAY) {
				return [self getZCloseFromRecordSet: myZCloseRS];
		}

		[myZCloseRS movePrev];

	}

	return NULL;

}

/**/
- (id) loadLast
{
	/** @todo: VER SI UTILIZO OTRO RECORDSET O ES SIEMPRE EL MISMO */
	if (![myZCloseRS moveLast]) return NULL;

	while (![myZCloseRS bof]) {

		if ([myZCloseRS getCharValue: "CLOSE_TYPE"] == CloseType_END_OF_DAY) {
				return [self getZCloseFromRecordSet: myZCloseRS];
		}

		[myZCloseRS movePrev];

	}

	return NULL;
}

/**/
- (unsigned long) getLastZCloseNumber
{
	/*if (![myZCloseRS moveLast]) 
		return [[CimBackup getInstance] getLastRowValue: "zclose" field: "NUMBER"];
*/
	if (![myZCloseRS moveLast]) return 0;
	while (![myZCloseRS bof]) {
		if ([myZCloseRS getCharValue: "CLOSE_TYPE"] == CloseType_END_OF_DAY) {
				return [myZCloseRS getLongValue: "NUMBER"];
		}
		[myZCloseRS movePrev];
	}
	return 0;
}

/**/
- (unsigned long) getLastCashCloseNumber
{
/*	if (![myZCloseRS moveLast]) 
		return [[CimBackup getInstance] getLastRowValue: "zclose" field: "NUMBER"];
*/
	if (![myZCloseRS moveLast]) return 0;
	while (![myZCloseRS bof]) {
		if ([myZCloseRS getCharValue: "CLOSE_TYPE"] == CloseType_CASH_CLOSE) {
				return [myZCloseRS getLongValue: "NUMBER"];
		}
		[myZCloseRS movePrev];
	}
	return 0;
}

/**/
- (unsigned long) getPrevZCloseNumber
{
/*	if (![myZCloseRS moveLast]) return 0;
	if (![myZCloseRS movePrev]) return 0;*/

	if (![myZCloseRS moveLast]) return 0;
	while (![myZCloseRS bof]) {
		if ([myZCloseRS getCharValue: "CLOSE_TYPE"] == CloseType_END_OF_DAY) {
				break;
		}
		[myZCloseRS movePrev];
	}
	while (![myZCloseRS bof]) {
		if ([myZCloseRS getCharValue: "CLOSE_TYPE"] == CloseType_END_OF_DAY) {
			return [myZCloseRS getLongValue: "NUMBER"];
		}
		[myZCloseRS movePrev];
	}
	return 0;
}

/**/
- (datetime_t) getPrevZCloseCloseTime
{
	/*if (![myZCloseRS moveLast]) return 0;
	if (![myZCloseRS movePrev]) return 0;
*/
	/** @todo: VER SI UTILIZO OTRO RECORDSET O ES SIEMPRE EL MISMO */

	if (![myZCloseRS moveLast]) return 0;
	while (![myZCloseRS bof]) {
		if ([myZCloseRS getCharValue: "CLOSE_TYPE"] == CloseType_END_OF_DAY) {
				break;
		}
		[myZCloseRS movePrev];
	}
	while (![myZCloseRS bof]) {
		if ([myZCloseRS getCharValue: "CLOSE_TYPE"] == CloseType_END_OF_DAY) {
			return [myZCloseRS getDateTimeValue: "CLOSE_TIME"];
		}
		[myZCloseRS movePrev];
	}
	return 0;
	
}

/**/
- (datetime_t) getLastZCloseCloseTime
{
	/** @todo: VER SI UTILIZO OTRO RECORDSET O ES SIEMPRE EL MISMO */
	if (![myZCloseRS moveLast]) return 0;
	while (![myZCloseRS bof]) {
		if ([myZCloseRS getCharValue: "CLOSE_TYPE"] == CloseType_END_OF_DAY) {
				return [myZCloseRS getDateTimeValue: "CLOSE_TIME"];
		}
		[myZCloseRS movePrev];
	}
	return 0;
}

/**/
- (void) deleteAll
{
	[myZCloseRS deleteAll];
}

/**/
- (ABSTRACT_RECORDSET) getZCloseRecordSetByDate: (datetime_t) aFromDate to: (datetime_t) aToDate
{
	FILTERED_RECORDSET recordSet; 
	
	recordSet = [[FilteredRecordSet new] initWithRecordset: [self getNewZCloseRecordSet]];
	
	if (aFromDate > 0)
		[recordSet addLongFilter: "CLOSE_TIME" operator: ">=" value: aFromDate];
		
	if (aToDate > 0)
		[recordSet addLongFilter: "CLOSE_TIME" operator: "<=" value: aToDate];
								
	return recordSet;		

}

/**/
- (id) loadCashCloseById: (unsigned long) aCashCloseId
{
	/** @todo: VER SI UTILIZO OTRO RECORDSET O ES SIEMPRE EL MISMO */
	if (![myZCloseRS moveLast]) return NULL;

	if ([self findCashCloseById: myZCloseRS value: aCashCloseId]) {
				return [self getZCloseFromRecordSet: myZCloseRS];
	}


	return NULL;
}

/**/
- (id) loadLastCashClose: (int) aCimCashId
{
	/** @todo: VER SI UTILIZO OTRO RECORDSET O ES SIEMPRE EL MISMO */
	if (![myZCloseRS moveLast]) return NULL;

	// Busco de atras para adelante el ultimo Z que tenga asociados depositos

	while (![myZCloseRS bof]) {

		if ([myZCloseRS getShortValue: "CIM_CASH_ID"] == aCimCashId &&
				[myZCloseRS getCharValue: "CLOSE_TYPE"] == CloseType_CASH_CLOSE) {
				return [self getZCloseFromRecordSet: myZCloseRS];
		}

		[myZCloseRS movePrev];

	}

	return NULL;
}

@end
