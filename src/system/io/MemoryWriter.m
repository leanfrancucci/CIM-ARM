#include "MemoryWriter.h"
#include <string.h>

@implementation MemoryWriter

- initWithPointer: (char*) aPointer size: (int) aSize
{
	myStart = aPointer;
	myPos = myStart;
	mySize = aSize;
	return self;
}

- (int) write: (char *)aBuf qty:(int) aQty
{
	if (myPos + aQty > myPos + mySize) 
		aQty = myStart + mySize - myPos;
	
	memcpy(myPos, aBuf, aQty);
	myPos += aQty;
	return aQty;
}

- (void) seek: (int) aQty from: (int) aFrom
{
	switch (aFrom) {
		case SEEK_SET: myPos = myStart + aQty; break;
		case SEEK_CUR: myPos = myPos + aQty; break;
		case SEEK_END: myPos = myPos = myStart + mySize - aQty; break;
	}
}

@end

