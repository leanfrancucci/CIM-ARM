#include "EventCategoryDAO.h"
#include "EventCategory.h"
#include "SettingsExcepts.h"
#include "ordcltn.h"
#include "Event.h"

static id singleInstance = NULL;

@implementation EventCategoryDAO

- (id) newEventCategoryFromRecordSet: (id) aRecordSet; 

/**/
+ new
{
	if (!singleInstance) singleInstance = [super new];
	return singleInstance;
}

/**/
- initialize
{
	[super initialize];
	return self;
}

/**/
- free
{
	return [super free];
}

/**/
+ getInstance
{
	return [self new];
}

/*******************************************************************************************
*																			EVENT CATEGORY
*
*******************************************************************************************/

/*
 *	Devuelve las categorias de eventos en base a la informacion del registro actual del recordset.
 */

- (id) newEventCategoryFromRecordSet: (id) aRecordSet
{
	EVENT_CATEGORY obj;
	char buffer[31];

	obj = [EventCategory new];

	[obj setEventCategoryId: [aRecordSet getShortValue: "EVENT_CATEGORY_ID"]];
	[obj setCatEventDescription: [aRecordSet getStringValue: "DESCRIPTION" buffer: buffer]];
	[obj setLogEventCategory: [aRecordSet getCharValue: "LOG_CATEGORY"]];
	[obj setDeleted: [aRecordSet getCharValue: "DELETED"]];
	[obj setResource: [aRecordSet getStringValue: "RESOURCE" buffer: buffer]];

	return obj;
}

/**/
- (id) loadById: (unsigned long) anId
{
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "events_category"];
	id obj = NULL;

	[myRecordSet open];
	[myRecordSet moveFirst];


	if ([myRecordSet findById: "CATEGORY_EVENT_ID" value: anId]) {
		obj = [self newEventCategoryFromRecordSet: myRecordSet];
		if (![obj isDeleted]) {
			[myRecordSet free];
			return obj;
		}
	}

	[myRecordSet free];
	THROW(REFERENCE_NOT_FOUND_EX);
	return NULL;
}

/**/
- (COLLECTION) loadAll
{
	COLLECTION collection = [OrdCltn new];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "events_category"];
	EVENT_CATEGORY obj;

	[myRecordSet open];

	while ( [myRecordSet moveNext] ) {
		obj = [self newEventCategoryFromRecordSet: myRecordSet];
		// agrego la categoria de eventos a la coleccion solo si no se encuentra borrado logicamente
		if (![obj isDeleted]) [collection add: obj];
	}

	[myRecordSet free];

	return collection;
}

/**/
- (void) store: (id) anObject
{
//	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "events_category"];

	return;

/*	TRY

		[myRecordSet open];
	
		if (![myRecordSet findById: "EVENT_CATEGORY_ID" value: [anObject getEventCategoryId]]) THROW(INVALID_REFERENCE_EX);
	
		[myRecordSet setStringValue: "DESCRIPTION" value: [anObject getCatEventDescription]];
		[myRecordSet setCharValue: "LOG_CATEGORY" value: [anObject logEventCategory]];
		[myRecordSet setCharValue: "DELETED" value: [anObject isDeleted]];
		[myRecordSet setStringValue: "RESOURCE" value: [anObject getResource]];
		
	
	FINALLY

		[myRecordSet free];

	END_TRY;
*/
}


/*******************************************************************************************
*																			EVENT
*
*******************************************************************************************/

/*
 *	Devuelve los eventos en base a la informacion del registro actual del recordset.
 */

- (id) newEventFromRecordSet: (id) aRecordSet
{
	EVENT obj;
	char buffer[31];

	obj = [Event new];

	[obj setEventId: [aRecordSet getShortValue: "EVENT_ID"]];
	[obj setEventCategoryId: [aRecordSet getShortValue: "EVENT_TYPE"]];
	[obj setEventName: [aRecordSet getStringValue: "NAME" buffer: buffer]];
	[obj setHasAdditional: [aRecordSet getCharValue: "HAS_ADDITIONAL"]];
	[obj setCritical: [aRecordSet getCharValue: "CRITICAL"]];
	[obj setResource: [aRecordSet getStringValue: "RESOURCE" buffer: buffer]];
		
	return obj;
}

/**/
- (id) loadEventById: (unsigned long) anId
{
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "events"];
	id obj = NULL;

	[myRecordSet open];
	[myRecordSet moveFirst];


	if ([myRecordSet findById: "EVENT_ID" value: anId]) {
		obj = [self newEventFromRecordSet: myRecordSet];
		[myRecordSet free];
		return obj;
	}

	[myRecordSet free];
	THROW(REFERENCE_NOT_FOUND_EX);
	return NULL;
}

/**/
- (COLLECTION) loadAllEvents
{  
	COLLECTION collection = [OrdCltn new];	
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "events"];	
  EVENT obj;

	[myRecordSet open];

	while ( [myRecordSet moveNext] ) {
		obj = [self newEventFromRecordSet: myRecordSet];
		// agrego el evento a la coleccion
		[collection add: obj];
	}

	[myRecordSet free];

	return collection;
}

/**/
- (void) storeEvent: (id) anObject
{
//	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "events"];

	return;
}


@end
