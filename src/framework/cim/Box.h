#ifndef BOX_H
#define BOX_H

#define BOX id

#include <Object.h>
#include "system/util/all.h"
#include "Door.h"
#include "AcceptorSettings.h"

#define BOX_NAME_SIZE 20
#define BOX_MODEL_SIZE 50

/**
 */
@interface Box : Object
{
	COLLECTION myAcceptorSettingsList;
	COLLECTION myDoorsList;
	char myName[BOX_NAME_SIZE + 1];
	char myModel[BOX_MODEL_SIZE + 1];
	int myBoxId;
	BOOL myDeleted;
}

/**/
- (void) addAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings;
- (void) addAcceptorSettingsByBox: (ACCEPTOR_SETTINGS) anAcceptorSettings;
- (void) removeAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings;
- (COLLECTION) getAcceptorSettingsList;

/**/
- (void) addDoor: (DOOR) aDoor;
- (void) addDoorByBox: (DOOR) aDoor;
- (void) removeDoor: (DOOR) aDoor;
- (COLLECTION) getDoorsList;

/**/
- (BOOL) boxHasAcceptorSettings: (int) anAcceptorSettingsId;

/**/
- (void) setBoxId: (int) aValue;
- (int) getBoxId;

/**/
- (void) setName: (char *) aName;
- (char *) getName;

/**/
- (void) setBoxModel: (char*) aModel;
- (char*) getBoxModel;


/**/
- (void) setDeleted: (BOOL) aValue;
- (BOOL) isDeleted;

/**/
- (void) applyChanges;

/**/
- (void) removeAllAcceptorsByBox;
- (void) removeAllDoorsByBox;

@end

#endif
