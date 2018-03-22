#include "DataWriter.h"
#include "system/util/endian.h"
#include <string.h>
#include <limits.h>

@implementation DataWriter

/**/
- (void) setBigEndian: (BOOL) aBigEndian
{
	myBigEndian = aBigEndian;
}

/**/
- (int) writeLine: (char*) aBuf
{
	int len, n;
	
	len = strlen( aBuf );
	n = [super write: aBuf qty: n];
	return n + [super write: "\n" qty: strlen("\n")];
}

/**/
- (int) writeLine: (char*) aBuf qty: (int) aQty
{
	int len, n;
	
	len = strlen( aBuf );
	n = len > aQty ? aQty : len;	
	n = [super write: aBuf qty: n];
	return n + [super write: "\n" qty: strlen("\n")];
}

/**/
- (int) writeShort: (short) aShort
{
	if (myBigEndian) aShort = SHORT_TO_B_ENDIAN(aShort);
	else aShort = SHORT_TO_L_ENDIAN(aShort);
	return [super write: (char*)&aShort qty: sizeof(short)];
}

/**/
- (int) writeLong: (long) aLong
{
	if (myBigEndian) aLong = LONG_TO_B_ENDIAN(aLong);
	else aLong = LONG_TO_L_ENDIAN(aLong);
	return [super write: (char*)&aLong qty: sizeof(long)];
}

/**/
- (int) writeChar: (char) aChar
{
	char buf[1];
	buf[0] = aChar;
	return [super write: buf qty: sizeof(char)];
}

/**/
- (int) writeMoney2: (money_t) aValue
{
	decimal_t decimal;
	int digits = -MONEY_DECIMAL_DIGITS;
	int n;

	while (aValue > LONG_MAX) {
		digits++;
		aValue = aValue / 10;
	}

	decimal.exp = digits;
	decimal.mantise = aValue;
	n = [self writeChar: decimal.exp];
	n = n + [self writeLong: decimal.mantise];

/*
	doLog(0,"converted mvalue = %lld\n", decimalToMoney2(decimal));
	doLog(0,"mvalue = %lld\n", mvalue);
	doLog(0,"decimal.exp = %d\n", decimal.exp);
	doLog(0,"decimal.mantise = %ld\n", decimal.mantise);
	doLog(0,"money value = %f\n", 1.0 * decimal.mantise * pow(10, decimal.exp));
	doLog(0,"-----------------------------------------------\n");
*/
	return n;	
}


@end

