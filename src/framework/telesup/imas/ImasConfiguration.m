#include "ImasConfiguration.h"

@implementation ImasConfiguration

/**/
- (void) setTelesupId: (int) aTelesupId
{
	myTelesupId = aTelesupId;
}

/**/
-(int) applyConfiguration:(char *) filename destination:(char*) dest
{
	return 1;
}

@end
