#include "ParallelPortWriter.h"

@implementation ParallelPortWriter 

/**/
- (PARALLEL_PORT) getParallelPort
{
  return myParallelPort;
}

/**/
- initWithParallelPort: (PARALLEL_PORT) aParallelPort
{
	myParallelPort = aParallelPort;
	return self;
}

/**/
- (int) write: (char*)aBuf qty: (int)aQty
{
	return [myParallelPort write: aBuf qty: aQty];
}

@end
