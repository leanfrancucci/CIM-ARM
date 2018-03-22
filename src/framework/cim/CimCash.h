#ifndef CIM_CASH_H
#define CIM_CASH_H

#define CIM_CASH id

#include <Object.h>
#include "system/util/all.h"
#include "Door.h"
#include "AcceptorSettings.h"

#define CIM_CASH_NAME_SIZE 20

/**
 *	Encapsulo un grupo de aceptadores asociados a una puerta.
 *	Restricciones:
 */
@interface CimCash : Object
{
	COLLECTION myAcceptorSettingsList;
	DOOR myDoor;
	char myName[CIM_CASH_NAME_SIZE + 1];
	int myCimCashId;
	DepositType myDepositType;
	BOOL myDeleted;
}

/**/
- (void) addAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings;
- (void) addAcceptorSettingsByCash: (ACCEPTOR_SETTINGS) anAcceptorSettings;
- (void) removeAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings;
- (void) removeAllAcceptorSettings;
- (COLLECTION) getAcceptorSettingsList;
- (BOOL) hasAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings;

/**/
- (void) setCimCashId: (int) aValue;
- (int) getCimCashId;

/**/
- (void) setDoor: (DOOR) aDoor;
- (DOOR) getDoor;

/**/
- (void) setName: (char *) aName;
- (char *) getName;

/**/
- (void) setDepositType: (DepositType) aDepositType;
- (DepositType) getDepositType;

/**/
- (void) setDeleted: (BOOL) aValue;
- (BOOL) isDeleted;

/**/
- (void) setDoorId: (int) aDoorId;
- (void) applyChanges;

/**/
- (void) removeAllAcceptorsByCash;

@end

#endif
