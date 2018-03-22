#include "FilterReader.h"

@implementation FilterReader

- initWithReader: (READER) aReader
{
	myReader = aReader;
	return self;
}

- (int) read: (char *)aBuf qty: (int) aQty
{
	return [myReader read:aBuf qty: aQty];
}

- (void) seek: (int)aQty from: (int) aFrom
{
	return [myReader seek:aQty from: aFrom];
}

- (void) close
{
	[myReader close];
}

@end

