#include "ComPortReader.h"

@implementation ComPortReader

- initWithComPort: (COM_PORT) aComPort 
{
	myComPort = aComPort;
	return self;
}

- (int) read: (char*)aBuf qty: (int)aQty
{
	return [myComPort read: aBuf qty: aQty];
}

- (void) flush
{
	[myComPort flush];
}

@end
