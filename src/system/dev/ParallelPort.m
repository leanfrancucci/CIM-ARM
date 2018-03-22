#include "ParallelPort.h"
#include "ParallelPortReader.h"
#include "ParallelPortWriter.h"

@implementation ParallelPort 

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myHandle = -1;
	myReader = [[ParallelPortReader new] initWithParallelPort: self];				 
	myWriter = [[ParallelPortWriter new] initWithParallelPort: self];
	
	return self ;
}

/**/
- free 
{
	[myReader free];
	[myWriter free];
	return self;
}

/**/
- (void) open
{
	myHandle = lpt_open();
	
	if (myHandle == -1) THROW(CANNOT_OPEN_DEVICE_EX);
}

/**/
- (void) close
{
	lpt_close(myHandle);
}

/**/
- (int)  read:(char *)aBuf qty: (int) aQty
{
	return lpt_read(myHandle, aBuf, aQty);
}

/**/
- (int)  write:(char *)aBuf qty: (int) aQty
{
	return lpt_write(myHandle, aBuf, aQty);
}

/**/
- (WRITER) getWriter
{
	return myWriter;
};

/**/
- (READER) getReader
{
	return myReader;
};

/**/
- (OS_HANDLE) getHandle
{
	return myHandle;
}

@end
