#include <stdlib.h>
#include "Event.h"
#include "ctapp.h"
#include "MessageHandler.h"


@implementation Event

/**/
- (void) setEventId: (int) aValue { myEventId = aValue; }
- (void) setEventCategoryId: (int) aValue { myEventCategoryId = aValue; }
- (void) setEventName: (char *) aName { strcpy(myEventName,aName); }
- (void) setHasAdditional: (int) aValue { myHasAdditional = aValue; }
- (void) setCritical: (BOOL) aValue { myCritical = aValue; }
- (void) setResource: (char *) aValue { strcpy(myResource,aValue); }

/**/
- (int) getEventId { return myEventId; }
- (int) getEventCategoryId { return myEventCategoryId; }
- (char *) getEventName { return myEventName; }
- (int) getHasAdditional { return myHasAdditional; }
- (BOOL) isCritical { return myCritical; }
- (char *) getResource { return myResource; }

/**/
- (STR) str
{
  if (strcmp(myResource,"0") == 0)
	  return myEventName;
	else
	  return getResourceString(atoi(myResource));	  	  
}

@end
