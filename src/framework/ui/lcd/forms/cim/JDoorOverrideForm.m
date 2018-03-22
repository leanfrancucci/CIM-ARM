#include "JDoorOverrideForm.h"
#include "MessageHandler.h"
#include "SystemTime.h"
#include "TelesupervisionManager.h"
#include "doorover.h"
#include "Audit.h"
#include "JMessageDialog.h"
#include "CimGeneralSettings.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation  JDoorOverrideForm

/**/
- (void) setVerificationCode: (char *) aVerificationCode
{
	stringcpy(myVerificationCode, aVerificationCode);
}

/**/
- (void) setDateTime: (datetime_t) aDateTime
{
	myDateTime = aDateTime;
}

/**/
- (void) setDoor: (DOOR) aDoor
{
	myDoor = aDoor;
}

/**/
- (void) onCreateForm
{
	[super onCreateForm];

	*myVerificationCode = '\0';
	myDateTime = 0;
	myDoor = NULL;
	mySecondaryHardwareMode = FALSE;

	myLabelUserCode = [self addLabelFromResource: RESID_USER_CODE default: "Cod.Usr."];

	myLabelAccessCode = [self addLabelFromResource: RESID_ACCESS_CODE default: "Cod. Acceso:"];

	myTextAccessCode = [JText new];
	[myTextAccessCode setWidth: 10];
	[myTextAccessCode setText: ""];
	[myTextAccessCode setNumericMode: TRUE];

	[self addFormComponent: myTextAccessCode];

}

/**/
- (void) onOpenForm
{
	char buf[100];

	sprintf(buf, "%s%s", getResourceStringDef(RESID_USER_CODE, "Cod.Usr."), myVerificationCode);

	[myLabelUserCode setCaption: buf];
}

/**/
- (void) onMenu1ButtonClick
{
	myModalResult = JFormModalResult_CANCEL;
	[self closeForm];
}

/**/
- (void) onMenu2ButtonClick
{
	char mac[100];
	char *systemId;
	struct tm brokenTime;
	unsigned long internalCode;
	char additional[20];
	char secondaryHardwareCode[20];

	[SystemTime decodeTime: myDateTime brokenTime: &brokenTime];

	if (mySecondaryHardwareMode) {

		// obtengo la mac
		get_mac(mac);

		//doLog(0,"MAC ADDRESS: %s\n", mac);
		strcpy(secondaryHardwareCode, "9562431");
		internalCode = genInternalCode(mac, secondaryHardwareCode, &brokenTime);

	} else {

		[[CimGeneralSettings getInstance] getMacAddress: mac];

		systemId = [[TelesupervisionManager getInstance] getMainTelesupSystemId];
		internalCode = genInternalCode(mac, systemId, &brokenTime);
		//doLog(0,"mac = %s, systemId = %s, internalCode = %ld\n", mac, systemId, internalCode);

	}

	if ([myTextAccessCode getLongValue] == internalCode) {

		if (!mySecondaryHardwareMode) {
			[Audit auditEventCurrentUser: Event_DOOR_OVERRIDE additional: "" station: [myDoor getDoorId] logRemoteSystem: FALSE];
		}

		myModalResult = JFormModalResult_OK;
		[self closeForm];
		return;

	} else {

		if (!mySecondaryHardwareMode) {
			sprintf(additional, "%ld", [myTextAccessCode getLongValue]);
			[Audit auditEventCurrentUser: EVENT_INVALID_DOOR_OVERRIDE additional: additional station: [myDoor getDoorId] logRemoteSystem: FALSE];
		}

		[JMessageDialog askOKMessageFrom: self 
			withMessage: getResourceStringDef(RESID_INVALID_DOOR_OVERRIDE_ACCESS, "Codigo de acceso invalido para la apertura manual de puerta")];

		myModalResult = JFormModalResult_CANCEL;
		[self closeForm];
		return;

	}

}

/**/
- (char *) getCaption1
{	
	return getResourceStringDef(RESID_BACK_KEY, "atras");
}

/**/
- (char *) getCaption2
{	
	return getResourceStringDef(RESID_OK_LOWER, "ok");
}

/**/
- (void) setSecondaryHardwareMode: (BOOL) aValue
{
	mySecondaryHardwareMode = aValue;
}

@end
