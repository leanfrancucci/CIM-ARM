#include "LogWriter.h"

/**/
@implementation LogWriter


/**/
- initWithLogWriter: (WRITER) aLogWriter
{
	myLogWriter = aLogWriter;
	
	return self;
}

/**/
- (int) write: (char *)aBuf qty: (int) aQty
{
	int size;
	
	THROW_NULL(myWriter);	
	size = [myWriter write: aBuf qty: aQty];
		
	/**/
	if (myLogWriter) {
		snprintf(myBuffer, sizeof(myBuffer) - 1, "\"%s\" - %s", "WR", aBuf);
		[myLogWriter write: myBuffer qty: strlen(myBuffer)];
	}
	
	return size;
}

@end

