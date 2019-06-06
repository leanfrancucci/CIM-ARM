#include "Box.h"
#include "CimExcepts.h"
#include "CimManager.h"
#include "Persistence.h"	
#include "BoxModel.h"	

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


- (int) getValModel: (int) aValId
{
	//id box = NULL;
	id acceptorSett = NULL;
	char acceptorModel[60];

	// si aun el modelo de caja no fue seteado retorno 0
	//box = [[[CimManager getInstance] getCim] getBoxById: 1];
	if (strlen(trim([self getBoxModel])) == 0) return ValidatorModel_JCM_PUB11_BAG;

	// obtengo el modelo de validador
	acceptorSett = [[[CimManager getInstance] getCim] getAcceptorSettingsById: aValId];

	if (!acceptorSett) return -1;
	strcpy(acceptorModel,trim([acceptorSett getAcceptorModel]));
	if (strlen(acceptorModel) == 0) return -1;

	if (strstr(acceptorModel, "PUB11|BAG|")) return ValidatorModel_JCM_PUB11_BAG;
	if (strstr(acceptorModel, "WBA|SS|")) return ValidatorModel_JCM_WBA_Stacker;
	if (strstr(acceptorModel, "BNF|SS|")) return ValidatorModel_JCM_BNF_Stacker;
	if (strstr(acceptorModel, "BNF|BAG|")) return ValidatorModel_JCM_BNF_BAG;
	if (strstr(acceptorModel, "FRONTLOAD MW|V|")) return ValidatorModel_CC_CS_Stacker;
	if (strstr(acceptorModel, "CCB|BAG|")) return ValidatorModel_CC_CCB_BAG;
	if (strstr(acceptorModel, "S66 BULK|H|")) return ValidatorModel_MEI_S66_Stacker;
    if (strstr(acceptorModel, "RDM")) return ValidatorModel_RDM;
	
    // por las dudas que no haya entrado en ningun if
	return -1;

}

/**/
- (int) getModel
{
	//id box = NULL;
	char boxModel[60];

	//box = [[[CimManager getInstance] getCim] getBoxById: 1];
	//if (!box) return PhisicalModel_Box2ED2V1M;
	strcpy(boxModel, trim([self getBoxModel]));
    
    printf("boxModel = %s\n", boxModel);
    
	if (strlen(boxModel) == 0) return -1;
	
	// busco el modelo de caja
	if (strstr(boxModel, "Box2ED2V1M")) return PhisicalModel_Box2ED2V1M;
	if (strstr(boxModel, "Box2ED1V1M")) return PhisicalModel_Box2ED1V1M;
	if (strstr(boxModel, "Box2EDI2V1M")) return PhisicalModel_Box2EDI2V1M;
	if (strstr(boxModel, "Box2EDI1V1M")) return PhisicalModel_Box2EDI1V1M;
	if (strstr(boxModel, "Box1ED2V1M")) return PhisicalModel_Box1ED2V1M;
	if (strstr(boxModel, "Box1ED1V1M")) return PhisicalModel_Box1ED1V1M;
	if (strstr(boxModel, "Box1ED1M")) return PhisicalModel_Box1ED1M;
	if (strstr(boxModel, "Box1D2V1M")) return PhisicalModel_Box1D2V1M;
	if (strstr(boxModel, "Box1D1V1M")) return PhisicalModel_Box1D1V1M;
	if (strstr(boxModel, "Box1D1M")) return PhisicalModel_Box1D1M;
	if (strstr(boxModel, "FLEX")) return PhisicalModel_Flex;
	
	// por las dudas que no haya entrado en ningun if
	return -1;

}

@end
