#include "system/util/all.h"
#include "DummyRemoteProxy.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation DummyRemoteProxy

+ new
{
	return [[super new] initialize];
}

- initialize
{
	[super initialize];
	return self;
}

	
/**/
- (int) readTelesupMessage: (char *) aBuffer qty: (int) aQty
{
	return 0;
}


/**/
- (BOOL) isRequestComplete: (char *)aBuffer
{
	return 0;
}	

/**/
- (BOOL) isLogoutTelesupMessage: (char *) aMessage
{
	return 0;
}

/**/
- (BOOL) isLoginTelesupMessage: (char *) aMessage
{
	return 0;
}

/**/
- (BOOL) isOkMessage: (char *) aMessage
{
	return 0;
}

/**/
- (void) newMessage: (const char *) aMessageName
{
}

/**/
- (void) newResponseMessage
{
}

/**/
- (void) newResponseMessageWithoutDateTime
{
}

/**/
- (void) setMessageName: (const char *) aMessageName 
{
}

/**/
- (void) sendMessage
{
}

/**/
- (void) sendAckMessage
{
}

/**/
- (void) sendAckDataFileMessage
{
}

/**/
- (void) sendErrorRequestMessage: (int) aCode description: (char *) aDescription
{
}

/**/
- (void) addLine: (char *) aLine
{
}

/**/
- (void) addParamAsDateTime: (char *) aParamName value: (datetime_t) aValue
{
}

- (datetime_t) getParamAsDateTime: (char *) aParamName
{
	return 0;
}

/**/
- (void) addParamAsString: (char *) aParamName value: (char *) aValue
{
}

- (char *) getParamAsString: (char *) aParamName
{
	return 0;
}

- (char *) getParamAsTrimString: (char *) aParamName
{
	return 0;
}

/**/
- (void) addParamAsInteger: (char *) aParamName value: (int) aValue
{
}

- (int) getParamAsInteger: (char *) aParamName
{
	return 0;
}


/**/
- (void) addParamAsLong: (char *) aParamName value: (long) aValue
{
}

- (long) getParamAsLong: (char *) aParamName
{
	return 0;
}

/**/
- (void) addParamAsCurrency: (char *) aParamName value: (money_t) aValue decimals: (int) aDecimals
{
}

/**/
- (void) addParamAsCurrency: (char *) aParamName value: (money_t) aValue
{
}

- (money_t) getParamAsCurrency: (char *) aParamName
{
	return 0;
}

/**/
- (void) addParamAsFloat: (char *) aParamName value: (float) aValue
{
}

- (float) getParamAsFloat: (char *) aParamName
{
	return 0;
}

/**/
- (void) addParamAsBoolean: (char *) aParamName value: (BOOL) aValue
{
}

- (BOOL) getParamAsBoolean: (char *) aParamName
{
	return 0;
}


/* Transferecnia  de informacion */

- (void) sendFile: (char *)aSourceFileName targetFileName: (char *) aTargetFileName
				 appendMode: (BOOL) anAppendMode
{
}

/**/
- (char *) receiveFile: (char *)aSourceFileName targetFileName: (char *) aTargetFileName
{
	return NULL;
}


/**/
- (void) sendCallTrafficFrom: (READER) aReader
{
}

/**/
- (void) sendAuditEventsFrom: (READER) aReader
{
}

/**/
- (void) sendTextMessagesFrom: (READER) aReader
{
}

/**/
- (void) sendHardwareInfoFrom: (READER) aReader
{
}

/**/
- (void) sendSoftwareInfoFrom: (READER) aReader
{
}

/**/
- (void) appendTimestamp
{
	[self addParamAsDateTime: "DateTime" value: [SystemTime getGMTTime]];
}

/**/
- (void) sendAckWithTimestampMessage
{
}

@end
