#include "ROPPersistence.h"
#include "util.h"
#include "ROPAudit.h"

static ROP_PERSISTENCE singleInstance = NULL;

@implementation ROPPersistence

/**/
+ new
{
	if (!singleInstance) {
		singleInstance = [super new];
		[Persistence setInstance: singleInstance];
	}
	return singleInstance;
}

/**/
+ getInstance
{
	return [self new];
}


/**/
- (DATA_OBJECT) getAuditDAO
{
  return [ROPAudit new];
}

@end
