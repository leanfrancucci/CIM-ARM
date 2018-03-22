#include "system/util/all.h"
#include "InfoFormatter.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation InfoFormatter

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{	
	myTelesupId = 0;
	return self;
}

/**/
- (void) setTelesupId: (int) aTelesupId
{
	myTelesupId = aTelesupId;
}

/**/
- (int) getLenInfo
{
	return myBuffer - myOriginalBuffer;
} 

/**/
- (void) setBuffer: (char *) aBuffer
{
	myBuffer = myOriginalBuffer = aBuffer;
}


/**/ 
- (int) writeLong: (long) aValue
{	
	long l = LONG_TO_L_ENDIAN(aValue);

	memcpy(myBuffer, (void *)&l, sizeof(long));
	myBuffer += sizeof(long);
	return sizeof(long);
}	

/**/
- (long) readLong
{	
	long l;

	memcpy((void *)&l, myBuffer, sizeof(long));
	myBuffer += sizeof(long);
	return L_ENDIAN_TO_LONG(l);
}


/**/
- (int) writeShort: (short) aValue
{
	short s = SHORT_TO_L_ENDIAN(aValue);
	
	memcpy(myBuffer, (void *)&s, sizeof(short));	
	myBuffer += sizeof(short);
	return sizeof(short);		
}

/**/
- (short) readShort
{	
	short s;

	memcpy((void *)&s, myBuffer, sizeof(short));
	myBuffer += sizeof(short);
	return L_ENDIAN_TO_SHORT(s);
}

/**/
- (int) writeByte: (int) aValue
{	
	char c = aValue;
	return [self writeChar: c];	
}

/**/
- (int) readByte
{
	int c = [self readChar];
	return c % 255;	
}

/**/
- (int) writeChar: (char) aValue
{
	*myBuffer++ = aValue;
	return 1;	
}

/**/
- (int) readChar
{
	return *myBuffer++;
}

/**/
- (int) writeByteStream: (void *)aValue qty: (int) aQty
{
	memcpy(myBuffer, (void *)aValue, aQty);	
	myBuffer += aQty;
	return aQty;
}

/**/
- (char *) readByteStream: (void *)aBuffer qty: (int) aQty
{
	memcpy((void *)aBuffer, (void *)myBuffer, aQty);	
	myBuffer += aQty;
	return aBuffer;
}

/**/
- (int) writeString: (char *)aValue qty: (int) aQty
{
	strncpy(myBuffer, aValue, aQty);	
	myBuffer += aQty;
	return aQty;
}

/**/
- (char *) readString: (char *)aBuffer qty: (int) aQty
{
	strncpy(aBuffer, (char *)myBuffer, aQty);	
	myBuffer += aQty;
	return aBuffer;
}

/**/
- (int) writeBCD: (char *)aValue qty: (int) aQty
{
	char bcdbuf[255];

	memset(bcdbuf, '\0', sizeof(bcdbuf));
	return [self writeByteStream: asciiToBcd(bcdbuf, aValue) qty: aQty / 2];
}

/**/
- (char *) readBCD: (char *) aBuffer qty: (int) aQty
{
	char bcdbuf[255];

	return bcdToAscii(aBuffer, [self readByteStream: bcdbuf qty: aQty], aQty);
}

/**/
- (int) writeBool: (BOOL) aValue
{
	char  c = (char)aValue;
	return [self writeChar: c];
}

/**/
- (BOOL) readBool
{
	char  c = [self readChar];
	return (BOOL)c;
}

/**/
- (int) writeDateTime: (datetime_t) aValue
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;	
}

/**/
- (datetime_t) readDateTime
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;	
}


/**/
- (int) writeFloat: (float) aValue
{ 
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}

/**/
- (float) readFloat
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}

/**/
- (int) writeMoney: (money_t) aValue
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}

/**/
- (money_t) readMoney
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}
/**/ 
- (int) getAuditSize
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}

/**/
- (int) formatAudit: (char *) aBuffer audits: (ABSTRACT_RECORDSET) auditsRS changeLog: (ABSTRACT_RECORDSET) changeLogRS
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}

/**/
- (int) formatDeposit: (char *) aBuffer
		includeDepositDetails: (BOOL) aIncludeDepositDetails
		deposits: (ABSTRACT_RECORDSET) aDepositRS
		depositDetails: (ABSTRACT_RECORDSET) aDepositDetailRS
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}


/**/
- (int) formatExtraction: (char *) aBuffer
		includeExtractionDetails: (BOOL) aIncludeExtractionDetails
		extractions: (ABSTRACT_RECORDSET) aExtractionRS
		extractionDetails: (ABSTRACT_RECORDSET) aExtractionDetailRS
		bagNumber: (char *) aBagNumber
		hasBagTracking: (BOOL) aHasBagTracking
		bagTrackingDetails: (ABSTRACT_RECORDSET) aBagTrackingDetailsRS
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}


/**/
- (int) formatZClose: (char *) aBuffer
		includeZCloseDetails: (BOOL) aIncludeZCloseDetails
		zclose: (ABSTRACT_RECORDSET) aZCloseRS
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}
		
/**/
- (int) formatXClose: (char *) aBuffer
		includeXCloseDetails: (BOOL) aIncludeXCloseDetails
		xclose: (ABSTRACT_RECORDSET) aXCloseRS
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}

- (int) formatUser: (char *) aBuffer
		user: (id) aUser
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}

@end
