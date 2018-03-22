#include "DataSearcher.h"
#include "util.h"

enum {
	DT_CHAR,
	DT_SHORT,
	DT_LONG,
	DT_STRING,
	DT_DATE_TIME
};

enum {
	DS_EQUAL,
	DS_NOT_EQUAL,
	DS_LESS,
	DS_GREAT,
	DS_GREAT_EQUAL,
	DS_LESS_EQUAL
};

@implementation DataSearcher

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	[self clear];
	myRecordSet = NULL;
	myObserver = NULL;
	return self;
}

/**/
- (void) setRecordSet: (ABSTRACT_RECORDSET) aRecordSet
{
	myRecordSet = aRecordSet;
}

/**/
- (void) clear
{
	myCurrentFilter = 0;
	firstCall = TRUE;
}

/**/
- (void) addFilter: (char*)aFieldName operator: (char*)anOperator 
						 value: (long long) aValue dataType: (int) aDataType
{
	if (myCurrentFilter >= DS_MAX_FILTERS) THROW(ARRAY_OVERFLOW_EX);
	if (strlen(aFieldName) > DS_MAX_FIELD_SIZE) THROW_MSG(BUFFER_OVERFLOW_EX, aFieldName);

	if (strcmp(anOperator, "=") == 0 ) myFilters[myCurrentFilter].operator = DS_EQUAL;
	else if (strcmp(anOperator, "!=") == 0) myFilters[myCurrentFilter].operator = DS_NOT_EQUAL;
	else if (strcmp(anOperator, ">=")  == 0) myFilters[myCurrentFilter].operator = DS_GREAT_EQUAL;
	else if (strcmp(anOperator, "<=")  == 0) myFilters[myCurrentFilter].operator = DS_LESS_EQUAL;
	else if (strcmp(anOperator, "<")  == 0) myFilters[myCurrentFilter].operator = DS_LESS;
	else if (strcmp(anOperator, ">")  == 0) myFilters[myCurrentFilter].operator = DS_GREAT;
	else THROW_MSG(INVALID_PARAMETER_EX, anOperator);
		
	strcpy(myFilters[myCurrentFilter].name, aFieldName);
	myFilters[myCurrentFilter].dataType = aDataType;
	myFilters[myCurrentFilter].value = aValue;
	
	myCurrentFilter++;
}

/**/
- (void) addCharFilter: (char*)aFieldName operator: (char*)anOperator value: (char) aValue
{
	[self addFilter: aFieldName operator: anOperator value: aValue dataType: DT_CHAR];
}

/**/
- (void) addShortFilter: (char*)aFieldName operator: (char*)anOperator value: (short) aValue
{
	[self addFilter: aFieldName operator: anOperator value: aValue dataType: DT_SHORT];	
}

/**/
- (void) addLongFilter: (char*)aFieldName operator: (char*)anOperator value: (long) aValue
{
	[self addFilter: aFieldName operator: anOperator value: aValue dataType: DT_LONG];
}

/**/
- (void) addStringFilter: (char*)aFieldName operator: (char*)anOperator value: (char*) aValue
{
	[self addFilter: aFieldName operator: anOperator value: (long)aValue dataType: DT_STRING];
}

/**/
- (void) addDateTimeFilter: (char*)aFieldName operator: (char*)anOperator value: (datetime_t) aValue
{
	[self addFilter: aFieldName operator: anOperator value: aValue dataType: DT_DATE_TIME];
}


- (BOOL) compareNumeric: (long long) aValue toValue:(long long) aToValue type: (int) aType
{
	
	switch (aType) {
		case DS_EQUAL: return aValue == aToValue; break;
		case DS_NOT_EQUAL: return aValue != aToValue; break;
		case DS_LESS: return aValue < aToValue; break;
		case DS_GREAT: return aValue > aToValue; break;
		case DS_GREAT_EQUAL: return aValue >= aToValue; break;
		case DS_LESS_EQUAL: return aValue <= aToValue; break;
	}
	
	return FALSE;	
}

/**/
- (BOOL) checkCondition
{
	int i;
	char buffer[100];
	BOOL result = FALSE;
	FilterRec *current;
	long long value;
	
	for (i = 0; i < myCurrentFilter; ++i) {
		
		current = &myFilters[i];
		
		switch ( current->dataType ) {
			
			case DT_CHAR:
				value = [myRecordSet getCharValue: current->name];
				result = [self compareNumeric: value toValue: current->value type: current->operator];
				break;

			case DT_SHORT: 
				value = [myRecordSet getShortValue: current->name]; 
				result = [self compareNumeric: value toValue: current->value type: current->operator];
				break;
			
			case DT_LONG: 
				value = [myRecordSet getLongValue: current->name]; 
				result = [self compareNumeric: value toValue: current->value type: current->operator];
				break;
				
			case DT_DATE_TIME: 
				value = [myRecordSet getDateTimeValue: current->name];
				result = [self compareNumeric: value toValue: current->value type: current->operator];
				break;
			
			case DT_STRING:
				if (current->operator == DS_EQUAL)
					result = strcasecmp((char*)(long)current->value, [myRecordSet getStringValue: current->name buffer:buffer]) == 0 ;
				else if (current->operator != DS_EQUAL)
					result = strcasecmp((char*)(long)current->value, [myRecordSet getStringValue: current->name buffer:buffer]) != 0 ;
				else
					THROW(INVALID_PARAMETER_EX);
				break;
			
		}
		
		if (!result) return FALSE;		
		
	}
	
	return TRUE;
	
}


/**/
- (BOOL) find
{
	if (myRecordSet == NULL) THROW(INVALID_POINTER_EX);
	
	firstCall = TRUE;
	return [self findNext];	
}


/**/
- (BOOL) findNext
{
	int i = 0;
	if (myRecordSet == NULL) THROW(INVALID_POINTER_EX);

	if (firstCall) {
		[myRecordSet moveBeforeFirst];
		firstCall = FALSE;
	}

	if (![myRecordSet moveNext]) return FALSE;

	// recorro todo el recordset
	while ( ![myRecordSet eof] ) {

		// chequea los filtros contra el registro actual del recordset
		if ( [self checkCondition] ) return TRUE;

		[myRecordSet moveNext];

		i++;
//		sched_yield();
		if (myObserver && i % 500 == 0) [myObserver advance];
		if (i % 10 == 0) msleep(1);

	}
	
	return FALSE;
}

/**/
- (void) setObserver: (id) anObserver
{
	myObserver = anObserver;
}

@end
