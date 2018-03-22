#include "DataReader.h"
#include "util.h"
#include "system/util/endian.h"
#include <limits.h>

@implementation DataReader

/**/
- (void) setBigEndian: (BOOL) aBigEndian
{
	myBigEndian = aBigEndian;
}

/**/
- (char*) readLine: (char*) aBuf qty: (int) aQty
{
	int c;
	char *p = aBuf;
	
	while ( aQty-- ) {
		c = [self readChar];

    // Esto controla por el caracter #10
		if (c == -1 || c == '\x0A') { 

      // Si hay un #13 en la posicion anterior lo quita tambien 
      if (p > aBuf && *(p-1) == '\x0D') p--; 
      *p = 0;
      
      return aBuf; 
    }

		*p++ = c;
	}
	
	*p = 0;
	return aBuf;
}

/**/
- (char*) readBCD: (char*) aBuf qty: (int) aQty
{
	char temp[50];
	[super read:temp qty: aQty/2];
	return bcdToAscii(aBuf, temp, aQty);
}

/**/
- (short) readShort
{
	short value;
	[super read:(char*)&value qty:sizeof(short)];
	if (myBigEndian) value = B_ENDIAN_TO_SHORT(value);
	else value = L_ENDIAN_TO_SHORT(value);
	return value;
}

/**/
- (long) readLong
{
	long value;
	[super read:(char*)&value qty:sizeof(long)];
	if (myBigEndian) value = B_ENDIAN_TO_LONG(value);
	else value = L_ENDIAN_TO_LONG(value);
	return value;
}

/**/
- (int) readChar
{
	char value[1];
	if ( [super read:value qty:sizeof(char)] == 0) return -1;
	return value[0];
}

/**/
- (money_t) readMoney2
{
	decimal_t decimal;
	int digits;
	money_t mvalue;

	decimal.exp = [self readChar];
	decimal.mantise = [self readLong];

	digits = MONEY_DECIMAL_DIGITS + decimal.exp;
	mvalue = decimal.mantise * llpow(10, digits);

	return mvalue;
}

@end

