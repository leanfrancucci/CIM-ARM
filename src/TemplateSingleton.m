#include "Template.h"

@implementation Template

static TEMPLATE singleInstance = NULL; 

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}
 
/**/
- initialize
{
	return self;
}

/**/
+ getInstance
{
  return [self new];
}


@end
