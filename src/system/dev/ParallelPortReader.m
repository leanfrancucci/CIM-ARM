#include "ParallelPortReader.h"

@implementation ParallelPortReader

/**/
- initWithParallelPort: (PARALLEL_PORT) aParallelPort 
{
	myParallelPort = aParallelPort;
	return self;
}

/**/
- (int) read: (char*)aBuf qty: (int)aQty
{
	return [myParallelPort read: aBuf qty: aQty];
}


@end
