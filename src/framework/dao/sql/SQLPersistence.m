#include "SQLPersistence.h"
#include "util.h"
#include "SQLAudit.h"

static SQL_PERSISTENCE singleInstance = NULL;

@implementation SQLPersistence

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
  return [SQLAudit new];
}

@end
