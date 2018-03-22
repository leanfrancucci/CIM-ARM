#include "FilterWriter.h"

@implementation FilterWriter

- initWithWriter: (WRITER) aWriter
{
	myWriter = aWriter;
	return self;
}

- (int) write: (char *)aBuf qty: (int) aQty
{
	return [myWriter write:aBuf qty: aQty];
}

- (void) seek: (int)aQty from: (int) aFrom
{
	return [myWriter seek:aQty from: aFrom];
}

- (void) close
{
	[myWriter close];
}

@end

