#include "TestFilterReader.h"

@implementation TestFilterReader


- (int) read: (char *)aBuf qty: (int) aQty
{
	int i;
	int n = [super read:aBuf qty: aQty];
	for (i = 0; i < n; ++i) 
		aBuf[i] = aBuf[i] + 1;
	return n;
}


@end

