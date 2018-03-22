#include "CimCash.h"
#include "CimExcepts.h"
#include "CimManager.h"
#include "Persistence.h"	

@implementation CimCash

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myAcceptorSettingsList = [Collection new];
	myDoor = NULL;
	*myName = '\0';
	myCimCashId = 0;
	myDepositType = DepositType_AUTO;
	return self;
}

/**/
- (void) setDepositType: (DepositType) aDepositType { myDepositType = aDepositType; }
- (DepositType) getDepositType { return myDepositType; }

/**/
- (void) setCimCashId: (int) aValue { myCimCashId = aValue; }
- (int) getCimCashId { return myCimCashId; }

/**/
- (void) setDoor: (DOOR) aDoor { myDoor = aDoor; }
- (DOOR) getDoor { return myDoor; }

/**/
- (void) setName: (char *) aName { stringcpy(myName, trim(aName)); }
- (char *) getName { return myName; }

/**/
- (void) addAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings 
{
	if ([anAcceptorSettings getDoor] != myDoor) 
		THROW(CIM_CIM_CASH_INVALID_DOOR_EX);

 	[myAcceptorSettingsList add: anAcceptorSettings];
}

/**/
- (void) addAcceptorSettingsByCash: (ACCEPTOR_SETTINGS) anAcceptorSettings
{
	id dao = [[Persistence getInstance] getCimCashDAO];

	[dao addAcceptorByCash: myCimCashId acceptorId: [anAcceptorSettings getAcceptorId]];
	[self addAcceptorSettings: anAcceptorSettings];
}

/**/
- (void) removeAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings
{
	id dao = [[Persistence getInstance] getCimCashDAO];

	[dao removeAcceptorByCash: myCimCashId acceptorId: [anAcceptorSettings getAcceptorId]];	

	[myAcceptorSettingsList remove: anAcceptorSettings];
}

/**/
- (void) removeAllAcceptorSettings
{
	int i;
	int count;
	id dao = [[Persistence getInstance] getCimCashDAO];

	count = [myAcceptorSettingsList size];
	for (i = 0; i < count; ++i) {
		[dao removeAcceptorByCash: myCimCashId acceptorId: [[myAcceptorSettingsList at: 0] getAcceptorId]];
		[myAcceptorSettingsList removeAt: 0];
	}
}

/**/
- (BOOL) hasAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings
{
	int i;

	for (i = 0; i < [myAcceptorSettingsList size]; ++i) {
		if ([myAcceptorSettingsList at: i] == anAcceptorSettings) return TRUE;
	}

	return FALSE;
}

/**/
- (COLLECTION) getAcceptorSettingsList
{
 return myAcceptorSettingsList;
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
- (void) setDoorId: (int) aDoorId
{
	if ((![self getDoor]) || ([[self getDoor] getDoorId] != aDoorId)) 
		[self setDoor: [[CimManager getInstance] getDoorById: aDoorId]];
	
}

/**/
- (void) applyChanges
{
	id dao = [[Persistence getInstance] getCimCashDAO];		

	[dao store: self];
}

/**/
- (void) restore
{
	CIM_CASH obj;

	//Recupera el objeto de la persistencia
	obj =	[[[Persistence getInstance] getCimCashDAO] loadById: [self getCimCashId]];		

	assert(obj != nil);

	[self setDoor: [obj getDoor]];
	[self setName: [obj getName]];
	[self setDepositType: [obj getDepositType]];
	[self setDeleted: [obj isDeleted]];

	[obj free];	
}

/**/
- (void) removeAllAcceptorsByCash
{
	int i;
	int count = [myAcceptorSettingsList size];

	for (i=0; i<count; ++i) 
		[self removeAcceptorSettings: [myAcceptorSettingsList at: 0]];

}


@end
