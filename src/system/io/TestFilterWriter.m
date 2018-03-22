#include "TestFilterWriter.h"

@implementation TestFilterWriter


- (int) write: (char *)aBuf qty: (int) aQty
{
	int i;
		
	for (i = 0; i < aQty; ++i) 
		aBuf[i] = aBuf[i] - 1;
  
	return [super write:aBuf qty: aQty];	
}


@end

