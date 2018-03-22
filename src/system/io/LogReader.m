#include "LogReader.h"

/**/
@implementation LogReader

/**/
- initWithLogWriter: (WRITER) aLogWriter
{
	myLogWriter = aLogWriter;
	return self;
}

- (int) read: (char *)aBuf qty: (int) aQty
{
	int size;
	
	THROW_NULL(myReader);	
	size = [myReader read: aBuf qty: aQty];
	
	if (myLogWriter) {
		snprintf(myBuffer, sizeof(myBuffer) - 1, "\"%s\" - %s", "RD", aBuf);
		[myLogWriter write: myBuffer qty: strlen(myBuffer)];
	}
	
	return size;
}

@end

