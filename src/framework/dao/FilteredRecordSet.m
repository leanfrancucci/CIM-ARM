#include "FilteredRecordSet.h"
 
//#define printd(args...) doLog(args)
#define printd(args...)

@implementation FilteredRecordSet

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myDataSearcher = [DataSearcher new];
	
	return self;
}


/**/
- free
{
	if (myRecordSet != NULL) {
		[myRecordSet close];
		[myRecordSet free];
	}
	
	[myDataSearcher free];
		
	return [super free];
}


/**/
- initWithRecordset: (ABSTRACT_RECORDSET) aRecordset
{
	[self setRecordset: aRecordset];
	return self;
}

/**/
- (void) setRecordset: (ABSTRACT_RECORDSET) aRecordset
{
	myRecordSet = aRecordset;	
	
	[myDataSearcher clear];
	[myDataSearcher setRecordSet: myRecordSet];
}

/**/
- initWithTableName: (char *) aTableName
{
	THROW( FEATURE_NOT_IMPLEMENTED_EX );
	return self;
}


/**/
- (void) open
{
	THROW_NULL(myRecordSet);
	[myRecordSet open];
	[myDataSearcher find];
}

/**/
- (void) close
{
	THROW_NULL(myRecordSet);
	[myRecordSet close];
/* Comentado porque en algunos lugares no conviene hacer un close del recordset porque se pierde la condicion */
/*	[myDataSearcher clear];	*/
}

/**/
- (BOOL) moveFirst
{
	THROW_NULL(myRecordSet);
	return [myDataSearcher find];
}

/**/
- (BOOL) moveBeforeFirst
{
	THROW_NULL(myRecordSet);
	[myRecordSet moveBeforeFirst];
	return 0;
}

/**/
- (BOOL) moveAfterLast
{
	THROW( FEATURE_NOT_IMPLEMENTED_EX );
	return 0;
}

/**/
- (BOOL) moveNext
{
	THROW_NULL(myRecordSet);
	return [myDataSearcher findNext];
}

/**/
- (BOOL) movePrev
{
	THROW( FEATURE_NOT_IMPLEMENTED_EX );
	return 0;
}

/**/
- (BOOL) moveLast
{
	THROW( FEATURE_NOT_IMPLEMENTED_EX );
	return 0;
}

/**/
- (void) seek: (int) aDirection offset: (int) anOffset
{
	THROW( FEATURE_NOT_IMPLEMENTED_EX );	
}

/**/
- (void) setValue: (char*)aFieldName value:(char*)aValue len:(int)aLen
{
	THROW_NULL(myRecordSet);
	[myRecordSet setValue: aFieldName value: aValue len: aLen];
}

/**/
- (void) getValue: (char*)aFieldName value:(char*)aValue
{
	THROW_NULL(myRecordSet);
	[myRecordSet getValue: aFieldName value: aValue];
}

/**/
- (void) setStringValue: (char*) aFieldName value: (char*) aValue
{
	THROW_NULL(myRecordSet);
	[myRecordSet setValue: aFieldName value:aValue len: strlen(aValue)];	
}

/**/
- (void) setCharArrayValue: (char*) aFieldName value: (char*) aValue
{
	THROW_NULL(myRecordSet);
	[myRecordSet setValue: aFieldName value:aValue len: -1];
}

/**/
- (void) setCharValue: (char*) aFieldName value: (char)aValue
{
	THROW_NULL(myRecordSet);
	[myRecordSet setValue: aFieldName value:(char*)&aValue len: 1];
}

/**/
- (void) setShortValue: (char*) aFieldName value: (short)aValue
{
	THROW_NULL(myRecordSet);

	[myRecordSet setShortValue: aFieldName value: aValue];
}

/**/
- (void) setLongValue: (char*) aFieldName value: (long)aValue
{
	THROW_NULL(myRecordSet);

	[myRecordSet setLongValue: aFieldName value: aValue];
}

/**/
- (void) setDateTimeValue: (char*) aFieldName value: (datetime_t)aValue
{
	THROW_NULL(myRecordSet);

	[myRecordSet setDateTimeValue: aFieldName value: aValue];
}

/**/
- (void) setMoneyValue: (char*) aFieldName value: (money_t)aValue
{
	[myRecordSet setMoneyValue: aFieldName value: aValue];
}

/**/
- (void) setBoolValue: (char*) aFieldName value: (BOOL) aValue
{
	THROW_NULL(myRecordSet);

	[myRecordSet setBoolValue: aFieldName value: aValue];
}

/**/
- (char*) getStringValue: (char*) aFieldName buffer: (char*)aBuffer
{
	THROW_NULL(myRecordSet);

	return [myRecordSet getStringValue: aFieldName buffer: aBuffer];
} 

/**/
- (char*) getCharArrayValue: (char*) aFieldName buffer: (char*)aBuffer
{
	THROW_NULL(myRecordSet);

	return [myRecordSet getCharArrayValue: aFieldName buffer: aBuffer];
}

/**/
- (char) getCharValue: (char*) aFieldName
{
	THROW_NULL(myRecordSet);
	
	return [myRecordSet getCharValue: aFieldName];
}

/**/
- (short) getShortValue: (char*) aFieldName
{
	THROW_NULL(myRecordSet);
	
	return [myRecordSet getShortValue: aFieldName];
}

/**/
- (long) getLongValue: (char*) aFieldName
{
	THROW_NULL(myRecordSet);
	
	return [myRecordSet getLongValue: aFieldName];
}

/**/
- (datetime_t) getDateTimeValue: (char*) aFieldName
{
	THROW_NULL(myRecordSet);
	
	return [myRecordSet getDateTimeValue: aFieldName];
}

/**/
- (money_t) getMoneyValue: (char*) aFieldName
{
	THROW_NULL(myRecordSet);
	
	return [myRecordSet getMoneyValue: aFieldName];
}

/**/
- (BOOL) getBoolValue: (char*) aFieldName
{
	THROW_NULL(myRecordSet);
	
	return [myRecordSet getBoolValue: aFieldName];
}

/**/
- (void) add
{
	THROW_NULL(myRecordSet);
	[myRecordSet add];
}

/**/
- (void) delete
{
	THROW_NULL(myRecordSet);
	[myRecordSet delete];
}

/**/
- (unsigned long) save
{
	THROW_NULL(myRecordSet);
	return [myRecordSet save];
}

/**/
- (BOOL) eof
{
	THROW_NULL(myRecordSet);
	return [myRecordSet eof];
}

/**/
- (BOOL) bof
{
	THROW_NULL(myRecordSet);
	return [myRecordSet bof];
}

/**/
- (unsigned long) getRecordCount
{
	THROW_NULL(myRecordSet);
	return [myRecordSet getRecordCount];
}

/**/
- (int) getRecordSize
{
	THROW_NULL(myRecordSet);
	return [myRecordSet getRecordSize];
}

/**/
- (BOOL) binarySearch: (char*) aFieldName value: (unsigned long) aValue
{
	THROW_NULL(myRecordSet);	
	return [myRecordSet binarySearch: aFieldName value: aValue];
}

/**/
- (BOOL) findById:  (char*) aFieldName value: (unsigned long) aValue
{
	THROW_NULL(myRecordSet);
	return [myRecordSet findById: aFieldName value: aValue];
	
}

/**/
- (BOOL) findFirstFromId:  (char*) aFieldName value: (unsigned long) aValue
{
	THROW_NULL(myRecordSet);
	return [myRecordSet findFirstFromId: aFieldName value: aValue];
	
}

/**/
- (char*) getName
{
	THROW_NULL(myRecordSet);
	return [myRecordSet getName];
}

/**/
- (int) getTableId
{
	THROW_NULL(myRecordSet);
	return [myRecordSet getTableId];
}


/**/
- (long) getCurrentPos
{
	THROW_NULL(myRecordSet);
	return [myRecordSet getCurrentPos];
}


/**
 * Los metodos del DataSearcher
 */

/**/
- (void) clearFilters
{
	[myDataSearcher clear];
}

/**/
- (void) addCharFilter: (char*)aFieldName operator: (char*)anOperator value: (char) aValue
{
	[myDataSearcher addCharFilter: aFieldName operator: anOperator value: aValue];
}

/**/
- (void) addShortFilter: (char*)aFieldName operator: (char*)anOperator value: (short) aValue
{
	[myDataSearcher addShortFilter: aFieldName operator: anOperator value: aValue];
}

/**/
- (void) addLongFilter: (char*)aFieldName operator: (char*)anOperator value: (long) aValue
{
	[myDataSearcher addLongFilter: aFieldName operator: anOperator value: aValue];
}

/**/
- (void) addStringFilter: (char*)aFieldName operator: (char*)anOperator value: (char*) aValue
{
	[myDataSearcher addStringFilter: aFieldName operator: anOperator value: aValue];
}

/**/
- (void) addDateTimeFilter: (char*)aFieldName operator: (char*)anOperator value: (datetime_t) aValue
{
	[myDataSearcher addDateTimeFilter: aFieldName operator: anOperator value: aValue];
}


@end
