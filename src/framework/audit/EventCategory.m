#include "EventCategory.h"
#include "Persistence.h"
#include "util.h"
#include "MessageHandler.h"

@implementation EventCategory

/**/
- (void) setEventCategoryId: (int) aValue { myEventCategoryId = aValue; }
- (void) setCatEventDescription: (char*) aValue { strncpy2(myDescription, aValue, sizeof(myDescription)-1); }
- (void) setLogEventCategory: (BOOL) aValue { myLogCategory = aValue; }  
- (void) setDeleted: (BOOL) aValue { myDeleted = aValue; }
- (void) setResource: (char*) aValue { strcpy(myResource, aValue); }

/**/
- (int) getEventCategoryId { return myEventCategoryId; }
- (char*) getCatEventDescription { return myDescription; }
- (BOOL) logEventCategory { return myLogCategory; }
- (BOOL) isDeleted { return myDeleted; }
- (char*) getResource { return myResource; }

/**/
- (void) applyChanges
{
	id catEventDAO;
	catEventDAO = [[Persistence getInstance] getEventCategoryDAO];		

	[catEventDAO store: self];
}

/**/
- (void) restore
{
	EVENT_CATEGORY obj;

	//Recupera el objeto de la persistencia
	obj =	[[[Persistence getInstance] getEventCategoryDAO] loadById: [self getEventCategoryId]];		

	assert(obj != nil);
	//Setea los valores a la instancia en memoria
  [self setLogEventCategory: [obj logEventCategory]];

	[obj free];	
}

/**/
- (STR) str
{
  if (strcmp(myResource,"0") == 0)
	  return myDescription;
	else
	  return getResourceString(atoi(myResource));	  	  
}

@end

