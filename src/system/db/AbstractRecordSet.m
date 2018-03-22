#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "AbstractRecordSet.h"
#include "util/endian.h"
#include "util.h"
 
//#define printd(args...) doLog(args)
#define printd(args...)

@implementation AbstractRecordSet

/**/
- initWithTableName: (char*) aTableName
{
	myAutoFlush = TRUE;
	return self;
}

/**/
- free
{
	return [super free];
}

/**/
- (void) open
{
	THROW(ABSTRACT_METHOD_EX);
}

/**/
- (void) close
{
	THROW(ABSTRACT_METHOD_EX);
}

/**/
- (BOOL) moveFirst
{
	THROW(ABSTRACT_METHOD_EX);
	return TRUE;
}

/**/
- (BOOL) moveBeforeFirst
{
	THROW(ABSTRACT_METHOD_EX);
	return TRUE;
}

/**/
- (BOOL) moveAfterLast
{
	THROW(ABSTRACT_METHOD_EX);
	return TRUE;
}

/**/
- (BOOL) moveNext
{
	THROW(ABSTRACT_METHOD_EX);
	return TRUE;
}

/**/
- (BOOL) movePrev
{
	THROW(ABSTRACT_METHOD_EX);
	return TRUE;
}

/**/
- (BOOL) moveLast
{
	THROW(ABSTRACT_METHOD_EX);
	return TRUE;
}

/**/
- (void) seek: (int) aDirection offset: (int) anOffset
{
	THROW(ABSTRACT_METHOD_EX);
}

/**/
- (void) setValue: (char*)aFieldName value:(char*)aValue len:(int)aLen
{
	THROW(ABSTRACT_METHOD_EX);
}

/**/
- (void) getValue: (char*)aFieldName value:(char*)aValue
{
	THROW(ABSTRACT_METHOD_EX);
}

/**/
- (void) setStringValue: (char*) aFieldName value: (char*) aValue
{
	[self setValue: aFieldName value:aValue len: strlen(aValue)];
}

/**/
- (void) setCharArrayValue: (char*) aFieldName value: (char*) aValue
{
	[self setValue: aFieldName value:aValue len: -1];
}

/**/
- (void) setCharValue: (char*) aFieldName value: (char)aValue
{
	[self setValue: aFieldName value:(char*)&aValue len: 1];
}

/**/
- (void) setShortValue: (char*) aFieldName value: (short)aValue
{
	aValue = SHORT_TO_B_ENDIAN(aValue);
	[self setValue: aFieldName value:(char*)&aValue len: sizeof(short)];
}

/**/
- (void) setLongValue: (char*) aFieldName value: (long)aValue
{
	aValue = LONG_TO_B_ENDIAN(aValue);
	[self setValue: aFieldName value:(char*)&aValue len: sizeof(long)];
}

/**/
- (void) setDateTimeValue: (char*) aFieldName value: (datetime_t)aValue
{
	aValue = LONG_TO_B_ENDIAN(aValue);
	[self setValue: aFieldName value:(char*)&aValue len: sizeof(datetime_t)];
}

/**/
- (void) setMoneyValue: (char*) aFieldName value: (money_t)aValue
{
	long	lvalue;
	unsigned char buf[5];
	decimal_t decimal;

	decimal = moneyToDecimal(aValue);

	buf[0] = decimal.exp;
	lvalue = LONG_TO_B_ENDIAN(decimal.mantise);
	memcpy(&buf[1], &lvalue, sizeof(lvalue));
	
	[self setValue: aFieldName value: buf len: 5];

}

/**/
- (void) setBoolValue: (char*) aFieldName value: (BOOL) aValue
{
	char c = aValue;
	[self setValue: aFieldName value:(char*)&c len: 1];	
}

/**/
- (void) setBcdValue: (char*) aFieldName value: (char*)aValue
{
  THROW(ABSTRACT_METHOD_EX);
}

/**/
- (char*) getBcdValue: (char*) aFieldName buffer: (char*)aBuffer
{
  THROW(ABSTRACT_METHOD_EX);
  return NULL;
}

/**/
- (char*) getStringValue: (char*) aFieldName buffer: (char*)aBuffer
{
	[self getValue: aFieldName value: aBuffer];
	printd("getStringValue (%s->%s) = %s\n", [self getName], aFieldName, aBuffer);
	return aBuffer;
} 

/**/
- (char*) getCharArrayValue: (char*) aFieldName buffer: (char*)aBuffer
{
	[self getValue: aFieldName value: aBuffer];
	printd("getCharArrayValue (%s->%s) = %s\n", [self getName], aFieldName, aBuffer);
	return aBuffer;
}

/**/
- (char) getCharValue: (char*) aFieldName
{
	char n;
	[self getValue: aFieldName value: (char*)&n];
	printd("getCharValue (%s->%s) = %d\n", [self getName], aFieldName, n);
	return n;
}

/**/
- (short) getShortValue: (char*) aFieldName
{
	short n;
	[self getValue: aFieldName value: (char*)&n];
	n = B_ENDIAN_TO_SHORT(n);
	printd("getShortValue (%s->%s) = %d\n", [self getName], aFieldName, n);
	return n;
}

/**/
- (long) getLongValue: (char*) aFieldName
{
	long n;
	[self getValue: aFieldName value: (char*)&n];
	n = B_ENDIAN_TO_LONG(n);
	printd("getLongValue (%s->%s) = %ld\n", [self getName],aFieldName, n);
	return n;
}

/**/
- (datetime_t) getDateTimeValue: (char*) aFieldName
{
	datetime_t n;
	[self getValue: aFieldName value: (char*)&n];
	n = B_ENDIAN_TO_LONG(n);
	printd("getDateTimeValue (%s->%s) = %ld\n", [self getName], aFieldName, n);
	return n;
}

/**/
- (money_t) getMoneyValue: (char*) aFieldName
{
	char buf[5];
	long lvalue;
	money_t m = 0;
	decimal_t decimal;

	[self getValue: aFieldName value: buf];
	memcpy(&lvalue, &buf[1], sizeof(lvalue));
		decimal.exp = buf[0];
	decimal.mantise = B_ENDIAN_TO_LONG(lvalue);
	m = decimalToMoney(decimal);

	printd("getMoneyValue (%s->%s) = %lld\n", [self getName], aFieldName, m);
	printd("EXP = %d, MANTISE = %ld\n", decimal.exp, decimal.mantise);
	return m;
}

/**/
- (BOOL) getBoolValue: (char*) aFieldName
{
	char b;
	[self getValue: aFieldName value: (char*)&b];
	printd("getBoolValue (%s->%s) = %d\n", [self getName], aFieldName, b);
	return b != 0;
}

/**/
- (void) add
{
	THROW(ABSTRACT_METHOD_EX);
}

/**/
- (void) delete
{
	THROW(ABSTRACT_METHOD_EX);
}

/**/
- (unsigned long) save
{
	THROW(ABSTRACT_METHOD_EX);
	return 0;
}

/**/
- (BOOL) eof
{
	THROW(ABSTRACT_METHOD_EX);
	return FALSE;
}

/**/
- (BOOL) bof
{
	THROW(ABSTRACT_METHOD_EX);
	return FALSE;
}

/**/
- (unsigned long) getRecordCount
{
	THROW(ABSTRACT_METHOD_EX);
	return 0;
}

/**/
- (int) getRecordSize
{
	THROW(ABSTRACT_METHOD_EX);
	return 0;
}

/**/
- (BOOL) binarySearch: (char*) aFieldName value: (unsigned long) aValue
{
	THROW(ABSTRACT_METHOD_EX);
	return FALSE;
}

/**/
- (BOOL) findById:  (char*) aFieldName value: (unsigned long) aValue
{
	THROW(ABSTRACT_METHOD_EX);
	return FALSE;
}

/**/
- (BOOL) findFirstById: (char*) aFieldName value: (unsigned long) aValue
{
	THROW(ABSTRACT_METHOD_EX);
	return FALSE;
}

/**/
- (BOOL) findFirstFromId: (char*) aFieldName value: (unsigned long) aValue
{
	THROW(ABSTRACT_METHOD_EX);
	return FALSE;
}

/**/
- (char*) getName
{
	THROW(ABSTRACT_METHOD_EX);
	return NULL;
}

/**/
- (int) getTableId
{
	THROW(ABSTRACT_METHOD_EX);
	return -1;
}


/**/
- (long) getCurrentPos
{
	THROW(ABSTRACT_METHOD_EX);
	return -1;
}

/**/
- (void) setAutoFlush: (BOOL) aValue
{
	myAutoFlush = aValue;
}

/**/
- (void) flush
{
	THROW(ABSTRACT_METHOD_EX);
}

/**/
- (void) deleteAll
{
	THROW(ABSTRACT_METHOD_EX);
}

@end
