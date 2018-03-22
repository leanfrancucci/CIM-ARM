#include "ComPortWriter.h"

@implementation ComPortWriter 

- initWithComPort: (COM_PORT) aComPort
{
	myComPort = aComPort;
	return self;
}

- (int) write: (char*)aBuf qty: (int)aQty
{
	return [myComPort write: aBuf qty: aQty];
}

- (void) flush
{
	[myComPort flush];
}


@end
