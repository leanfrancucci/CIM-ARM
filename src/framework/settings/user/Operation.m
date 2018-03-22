#include <stdlib.h>
#include "Operation.h"
#include "util.h"
#include "MessageHandler.h"

@implementation Operation

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myOperationId = 0;
	myDeleted = FALSE;
	strcpy(myResource,"0");
	return self;
}

/**/
- (void) setOperationId: (int) aValue { myOperationId = aValue; }
- (void) setOpName: (char*) aValue { strncpy2(myName, aValue, sizeof(myName)-1); }
- (void) setOpResource: (char*) aValue { strcpy(myResource, aValue); }
- (void) setDeleted: (BOOL) aValue { myDeleted = aValue; }


/**/
- (int) getOperationId { return myOperationId; } 
- (char*) getOpName { return myName; }
- (char*) getOpResource { return myResource; }
- (BOOL) isDeleted { return myDeleted; }

/**/
- (STR) str
{
  if (strcmp(myResource,"0") == 0)
	  return myName;
	else
	  return getResourceString(atoi(myResource));
}

@end

