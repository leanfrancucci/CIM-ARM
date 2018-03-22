#include "EventManager.h"
#include "EventCategory.h"
#include "Persistence.h"
#include "SettingsExcepts.h"
#include "ordcltn.h"
#include "Event.h"
#include "EventCategoryDAO.h"

static id singleInstance = NULL;

@implementation EventManager


/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}

/**/
+ getInstance
{
	return [self new];	
}

/**/
- initialize
{
	myEventsCategory = [[[Persistence getInstance] getEventCategoryDAO] loadAll];
	myEvents = [[[Persistence getInstance] getEventCategoryDAO] loadAllEvents];

	return self;
}


/*******************************************************************************************
*																			EVENT CATEGORY
*
*******************************************************************************************/

/**/
- (EVENT_CATEGORY) getEventCategory: (int) aEventCategoryId
{
	int i = 0;
	
	for (i=0; i<[myEventsCategory size];++i) 
		if ([ [myEventsCategory at: i] getEventCategoryId] == aEventCategoryId) return [myEventsCategory at: i];
	
	THROW(REFERENCE_NOT_FOUND_EX);	
	return NULL;
}

/**/
- (void) setEventCategoryLog: (int) aEventCategoryId value: (BOOL) aValue
{
	EVENT_CATEGORY obj = [self getEventCategory: aEventCategoryId];
	[obj setLogEventCategory: aValue];
}

/**/
- (char*) getEventCategoryDescription: (int) aEventCategoryId
{
	EVENT_CATEGORY obj = [self getEventCategory: aEventCategoryId];
	return [obj getCatEventDescription];
}

/**/
- (BOOL) getEventCategoryLog: (int) aEventCategoryId
{
	EVENT_CATEGORY obj = [self getEventCategory: aEventCategoryId];
	return [obj logEventCategory];
}

/**/
- (char*) getEventCategoryResource: (int) aEventCategoryId
{
	EVENT_CATEGORY obj = [self getEventCategory: aEventCategoryId];
	return [obj getResource];
}

/**/
- (void) applyEventCategoryChanges: (int) aEventCategoryId
{
	EVENT_CATEGORY obj = [self getEventCategory: aEventCategoryId];
  
	[obj applyChanges];
}

/*******************************************************************************************
*																			EVENT
*
*******************************************************************************************/

/**/
- (EVENT) getEvent: (int) anEventId
{
	int i = 0;

  for (i=0; i<[myEvents size];++i)
    if ([ [myEvents at: i] getEventId] == anEventId) return [myEvents at: i];

	//THROW(REFERENCE_NOT_FOUND_EX);
	return NULL;
}

/**/
- (int) getEventCategoryId: (int) anEventId
{
	EVENT obj = [self getEvent: anEventId];
	return [obj getEventCategoryId];
}

/**/
- (char *) getEventName: (int) anEventId
{
	EVENT obj = [self getEvent: anEventId];
	return [obj getEventName];
}

/**/
- (int) getEventHasAdditional: (int) anEventId
{
	EVENT obj = [self getEvent: anEventId];
	return [obj getHasAdditional];
}

/**/
- (BOOL) getEventIsCritical: (int) anEventId
{
	EVENT obj = [self getEvent: anEventId];
	return [obj isCritical];
}

/**/
- (char *) getEventResource: (int) anEventId
{
	EVENT obj = [self getEvent: anEventId];
	return [obj getResource];
}

/**/
- (void) applyEventChanges: (int) anEventId
{
	EVENT obj = [self getEvent: anEventId];
  
	[obj applyChanges];
}

/**/
- (COLLECTION) getEvents
{
	return myEvents;
}

/**/
- (COLLECTION) getEventsCategory
{
	return myEventsCategory;
}

@end
