#include "Box.h"
#include "CimExcepts.h"
#include "CimManager.h"
#include "Persistence.h"	

@implementation Box

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myAcceptorSettingsList = [Collection new];
	myDoorsList = [Collection new];
	*myName = '\0';
	*myModel = '\0';
	myBoxId = 0;
	return self;
}

/**/
- (void) setBoxId: (int) aValue { myBoxId = aValue; }
- (int) getBoxId { return myBoxId; }

/**/
- (void) setName: (char *) aName { stringcpy(myName, trim(aName)); }
- (char *) getName { return myName; }

/**/
- (void) setBoxModel: (char*) aModel { stringcpy(myModel, aModel); }
- (char*) getBoxModel { return myModel; }

/**/
- (void) addAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings 
{
 	[myAcceptorSettingsList add: anAcceptorSettings];
}

/**/
- (void) addAcceptorSettingsByBox: (ACCEPTOR_SETTINGS) anAcceptorSettings
{
	id dao = [[Persistence getInstance] getBoxDAO];

	[dao addAcceptorByBox: myBoxId acceptorId: [anAcceptorSettings getAcceptorId]];
	[self addAcceptorSettings: anAcceptorSettings];
}

/**/
- (void) removeAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings
{
	id dao = [[Persistence getInstance] getBoxDAO];

	[dao removeAcceptorByBox: myBoxId acceptorId: [anAcceptorSettings getAcceptorId]];	

	[myAcceptorSettingsList remove: anAcceptorSettings];
}

/**/
- (void) addDoor: (DOOR) aDoor 
{
 	[myDoorsList add: aDoor];
}

/**/
- (void) addDoorByBox: (DOOR) aDoor
{
	id dao = [[Persistence getInstance] getBoxDAO];

	[dao addDoorByBox: myBoxId doorId: [aDoor getDoorId]];
	[self addDoor: aDoor];

}

/**/
- (void) removeDoor: (DOOR) aDoor
{
	id dao = [[Persistence getInstance] getBoxDAO];

	[dao removeDoorByBox: myBoxId doorId: [aDoor getDoorId]];	

	[myDoorsList remove: aDoor];
}

/**/
- (BOOL) boxHasAcceptorSettings: (int) anAcceptorSettingsId
{
	int i;

	for (i = 0; i < [myAcceptorSettingsList size]; ++i) {
		if ([[myAcceptorSettingsList at: i] getAcceptorId] == anAcceptorSettingsId) return TRUE;
	}

	return FALSE;
}


/**/
- (COLLECTION) getAcceptorSettingsList
{
 return myAcceptorSettingsList;
}

/**/
- (COLLECTION) getDoorsList
{
	return myDoorsList;
}

/**/
- (STR) str
{
	return myName;
}

/**/
- (void) setDeleted: (BOOL) aValue { myDeleted = aValue; }
- (BOOL) isDeleted { return myDeleted; }

/**/
- (void) applyChanges
{
	id dao = [[Persistence getInstance] getBoxDAO];		

	[dao store: self];
}

/**/
- (void) restore
{
	BOX obj;

	//Recupera el objeto de la persistencia
	obj =	[[[Persistence getInstance] getBoxDAO] loadById: [self getBoxId]];		

	assert(obj != nil);

	[self setName: [obj getName]];
	[self setDeleted: [obj isDeleted]];

	[obj free];	
}

/**/
- (void) removeAllAcceptorsByBox
{
	int i;
	int count = [myAcceptorSettingsList size];

	for (i=0; i<count; ++i) 
		[self removeAcceptorSettings: [myAcceptorSettingsList at: 0]];
}

/**/
- (void) removeAllDoorsByBox
{
	int i;
	int count = [myDoorsList size];

	for (i=0; i<count; ++i) 
		[self removeDoor: [myDoorsList at: 0]];
}


@end
