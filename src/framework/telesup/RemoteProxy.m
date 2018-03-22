#include "system/util/all.h"
#include "RemoteProxy.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation RemoteProxy

+ new
{
	return [[super new] initialize];
}

- initialize
{
	myTelesupViewer = NULL;
	//myTelesupParser = NULL;	
	myReader = NULL;
	myWriter = NULL;
	myTelesupRol = 0;
	mySystemId[0] = '\0';
	
	return self;
}

/**/
- (void) setTelesupViewer: aTelesupViewer { myTelesupViewer = aTelesupViewer; }
- (TELESUP_VIEWER) getTelesupViewer { return myTelesupViewer; }

/**/
- (void) setTelesupRol: (int) aTelesupRol { myTelesupRol = aTelesupRol; }
- (int)  getTelesupRol { return myTelesupRol; }	
	
/**/
- (void) setSystemId: (char *) aSystemId { stringcpy(mySystemId, aSystemId); }
- (char *) getSystemId { return mySystemId; };

/**/
/*
- (void) setTelesupParser: (TELESUP_PARSER) aTelesupParser
{
	myTelesupParser = aTelesupParser;
}
*/

/**/
- (void) setReader: (READER) aReader { 	myReader = aReader; }
- (READER) getReader { return myReader; }

/**/
- (void) setWriter: (WRITER) aWriter { 	myWriter = aWriter; };
- (WRITER) getWriter { return myWriter; }


/**/
- (int) decodeTelesupMessage: (char *) aTargetBuffer from: (char *) aSourceBuffer size: (int) aSize
{
	memcpy((void *)aTargetBuffer, (void *)aSourceBuffer, aSize);
	return aSize;
}

/**/
- (int) encodeTelesupMessage: (char *) aTargetBuffer from: (char *) aSourceBuffer size: (int) aSize
{
	memcpy((void *)aTargetBuffer, (void *)aSourceBuffer, aSize);
	return aSize;
}

/**/
- (void) configureFileTransfer: (FILE_TRANSFER) aFileTransfer
{
	assert(aFileTransfer);
	assert(myTelesupViewer);
	
	[aFileTransfer clear];
	
	[aFileTransfer setTelesupViewer: myTelesupViewer];
	[aFileTransfer setReader: myReader];
	[aFileTransfer setWriter: myWriter];
}
	
/**/
- (int) readTelesupMessage: (char *) aBuffer qty: (int) aQty
{	
	aBuffer = aBuffer;
	aQty = aQty;
	THROW( ABSTRACT_METHOD_EX ); 
	return 0;
}


/**/
- (BOOL) isRequestComplete: (char *)aBuffer
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}	

/**/
- (BOOL) isLogoutTelesupMessage: (char *) aMessage
{	
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}

/**/
- (BOOL) isLoginTelesupMessage: (char *) aMessage
{	
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}

/**/
- (BOOL) isOkMessage: (char *) aMessage
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}

/**/
- (void) newMessage: (const char *) aMessageName
{	
	THROW( ABSTRACT_METHOD_EX ); 
};

/**/
- (void) newResponseMessage
{	
	THROW( ABSTRACT_METHOD_EX ); 
};

/**/
- (void) newResponseMessageWithoutDateTime
{
	THROW( ABSTRACT_METHOD_EX );
}

/**/
- (void) setMessageName: (const char *) aMessageName 
{	
	THROW( ABSTRACT_METHOD_EX ); 
};

/**/
- (void) sendMessage
{
	THROW( ABSTRACT_METHOD_EX );
};


/**/
- (void) sendAckMessage
{
	THROW( ABSTRACT_METHOD_EX );
};

/**/
- (void) sendAckDataFileMessage
{
	THROW( ABSTRACT_METHOD_EX );
};

/**/
- (void) sendErrorRequestMessage: (int) aCode description: (char *) aDescription
{
	THROW( ABSTRACT_METHOD_EX );
};

/**/
- (void) addLine: (char *) aLine
{
	THROW( ABSTRACT_METHOD_EX );
}

/**/
- (void) addParamAsDateTime: (char *) aParamName value: (datetime_t) aValue
{
	THROW( ABSTRACT_METHOD_EX );
};
- (datetime_t) getParamAsDateTime: (char *) aParamName
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
};

/**/
- (void) addParamAsString: (char *) aParamName value: (char *) aValue
{
	THROW( ABSTRACT_METHOD_EX );
};
- (char *) getParamAsString: (char *) aParamName
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
};
- (char *) getParamAsTrimString: (char *) aParamName
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
};


/**/
- (void) addParamAsInteger: (char *) aParamName value: (int) aValue
{
	THROW( ABSTRACT_METHOD_EX );
};
- (int) getParamAsInteger: (char *) aParamName
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
};


/**/
- (void) addParamAsLong: (char *) aParamName value: (long) aValue
{
	THROW( ABSTRACT_METHOD_EX );
};
- (long) getParamAsLong: (char *) aParamName
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
};

/**/
- (void) addParamAsCurrency: (char *) aParamName value: (money_t) aValue decimals: (int) aDecimals
{
	THROW( ABSTRACT_METHOD_EX );
}

/**/
- (void) addParamAsCurrency: (char *) aParamName value: (money_t) aValue
{
	THROW( ABSTRACT_METHOD_EX );
};
- (money_t) getParamAsCurrency: (char *) aParamName
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
};

/**/
- (void) addParamAsFloat: (char *) aParamName value: (float) aValue
{
	THROW( ABSTRACT_METHOD_EX );
};
- (float) getParamAsFloat: (char *) aParamName
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
};

/**/
- (void) addParamAsBoolean: (char *) aParamName value: (BOOL) aValue
{
	THROW( ABSTRACT_METHOD_EX );
};
- (BOOL) getParamAsBoolean: (char *) aParamName
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
};


/* Transferecnia  de informacion */

- (void) sendFile: (char *)aSourceFileName targetFileName: (char *) aTargetFileName
				 appendMode: (BOOL) anAppendMode
{
	THROW( ABSTRACT_METHOD_EX );
}

/**/
- (char *) receiveFile: (char *)aSourceFileName targetFileName: (char *) aTargetFileName
{
	THROW( ABSTRACT_METHOD_EX );
	return NULL;
}


/**/
- (void) sendCallTrafficFrom: (READER) aReader
{
	THROW( ABSTRACT_METHOD_EX );
};

/**/
- (void) sendAuditEventsFrom: (READER) aReader
{
	THROW( ABSTRACT_METHOD_EX );
};

/**/
- (void) sendTextMessagesFrom: (READER) aReader
{
	THROW( ABSTRACT_METHOD_EX );
};

/**/
- (void) sendHardwareInfoFrom: (READER) aReader
{
	THROW( ABSTRACT_METHOD_EX );
};

/**/
- (void) sendSoftwareInfoFrom: (READER) aReader
{
	THROW( ABSTRACT_METHOD_EX );
};

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
