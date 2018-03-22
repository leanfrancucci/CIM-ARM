#include "TelesupSettings.h"
#include "Persistence.h"
#include "TelesupSettingsDAO.h"
#include "util.h"
#include <objpak.h>
#include "Module.h"

@implementation TelesupSettings

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myTelesupId = 0;
	myDeleted = FALSE;
	myFromHour = 0;
	myToHour   = 24;
	myAttemptsQty = 3;
 	myFrequency = 1;
	myTimeBetweenAttempts = 10;
	myLastTelesupAdditionalTicketId = 0;
	myActive = TRUE;
	mySendTraffic = TRUE;
	mySendAudits = TRUE;
  myMaxTimeWithoutTelesupAllowed = 0;
	strcpy(myExtension, "");
	strcpy(myAcronym, "");
	strcpy(myRemoteSystemId, "");
	myNextTelDate = 1;
	myNextSecondaryTelDate = 1;
	myFrame = 1;
	myCabinIdleWaitTime = 0;
  myLastTariffTableHistoryId = 0;
	myLastTelesupDepositNumber = 0;
	myLastTelesupExtractionNumber = 0;
	myInformDepositsByTransaction = FALSE;
	myInformExtractionsByTransaction = FALSE;
	myInformAlarmsByTransaction = FALSE;
	myLastTelesupAlarmId = 0;
	myLastTelesupZCloseNumber = 0;
	myLastTelesupXCloseNumber = 0;
	myInformZCloseByTransaction = FALSE;
	return self;
}

/**/
- (void) setTelesupId: (int) aValue { myTelesupId = aValue; }
- (void) setSystemId: (char*) aValue { strncpy2(mySystemId, aValue, sizeof(mySystemId) - 1);}
- (void) setRemoteSystemId: (char*) aValue { stringcpy(myRemoteSystemId, aValue);}
- (void) setTelesupDescription: (char*) aValue { strncpy2(myDescription , aValue, sizeof(myDescription) - 1);} 
- (void) setTelesupUserName: (char*) aValue { strncpy2(myUserName , aValue, sizeof(myUserName) - 1);} 
- (void) setTelesupPassword: (char*) aValue { strncpy2(myPassword , aValue, sizeof(myPassword) - 1);} 
- (void) setRemoteUserName: (char*) aValue { strncpy2(myRemoteUserName , aValue, sizeof(myRemoteUserName) - 1);} 
- (void) setRemotePassword: (char*) aValue { strncpy2(myRemotePassword , aValue, sizeof(myRemotePassword) - 1);} 
- (void) setTelcoType: (TelcoType) aValue { myTelcoType = aValue; } 
- (void) setTelesupFrequency: (int) aValue { myFrequency = aValue; } 
- (void) setStartMoment: (StartMomentType) aValue { myStartMoment = aValue; } 
- (void) setAttemptsQty: (int) aValue { myAttemptsQty = aValue; } 
- (void) setTimeBetweenAttempts: (int) aValue { myTimeBetweenAttempts = aValue; } 
- (void) setMaxTimeWithoutTelAllowed: (int) aValue { myMaxTimeWithoutTelesupAllowed = aValue; } 
- (void) setConnectionId1: (int) aValue { myConnectionId1 = aValue; } 
- (void) setConnectionId2: (int) aValue { myConnectionId2 = aValue; } 
- (void) setNextTelesupDateTime: (datetime_t) aValue { myNextTelDate = aValue; } 
- (void) setLastSuceedTelesupDateTime: (datetime_t) aValue { myLastSuceedTelesupDate = aValue; } 
- (void) setConnection1: (CONNECTION_SETTINGS) aConnection  { myConnection1 = aConnection; }
- (void) setConnection2: (CONNECTION_SETTINGS) aConnection { myConnection2 = aConnection; }
- (void) setLastTelesupCallId: (long) aValue { myLastTelesupCallId = aValue; }
- (void) setLastTelesupTicketId: (long) aValue { myLastTelesupTicketId = aValue; }
- (void) setLastTelesupAuditId: (long) aValue { myLastTelesupAuditId = aValue; }
- (void) setLastTelesupCollectorId: (long) aValue { myLastTelesupCollectorId = aValue; }
- (void) setLastTelesupCashRegisterId: (long) aValue { myLastTelesupCashRegisterId = aValue; }
- (void) setLastTelesupMessageId: (long) aValue { myLastTelesupMessageId = aValue; }
- (void) setLastTelesupAdditionalTicketId: (long) aValue { myLastTelesupAdditionalTicketId = aValue; }
- (void) setDeleted: (BOOL) aValue { myDeleted = aValue; } 
- (void) setLastAttemptDateTime: (datetime_t) aValue { myLastAttemptDateTime = aValue; }
- (void) setFromHour: (int) aValue { myFromHour = aValue; }
- (void) setToHour: (int) aValue { myToHour = aValue; }
- (void) setAcronym: (char*) aValue { strncpy2(myAcronym, aValue, sizeof(myAcronym) - 1); }
- (void) setExtension: (char*) aValue { strncpy2(myExtension, aValue, sizeof(myExtension) - 1); }
- (void) setActive: (BOOL) aValue { myActive = aValue; }
- (void) setSendAudits:(BOOL) aValue{ mySendAudits = aValue; }
- (void) setSendTraffic:(BOOL) aValue{ mySendTraffic = aValue; }
- (void) setNextSecondaryTelesupDateTime: (datetime_t) aValue { myNextSecondaryTelDate = aValue; }
- (void) setTelesupFrame: (int) aValue { myFrame = aValue; }
- (void) setCabinIdleWaitTime: (int) aValue { myCabinIdleWaitTime = aValue; } 

/*CIM*/
- (void) setLastTelesupDepositNumber: (unsigned long) aValue { myLastTelesupDepositNumber = aValue; }
- (void) setLastTelesupExtractionNumber: (unsigned long) aValue { myLastTelesupExtractionNumber = aValue; }

- (void) setLastTelesupAlarmId: (unsigned long) aValue { myLastTelesupAlarmId = aValue; }
- (void) setInformDepositsByTransaction: (BOOL) aValue { myInformDepositsByTransaction = aValue; }
- (void) setInformExtractionsByTransaction: (BOOL) aValue { myInformExtractionsByTransaction = aValue; }
- (void) setInformAlarmsByTransaction: (BOOL) aValue { myInformAlarmsByTransaction = aValue; }
- (void) setLastTelesupZCloseNumber: (unsigned long) aValue { myLastTelesupZCloseNumber = aValue; }
- (void) setLastTelesupXCloseNumber: (unsigned long) aValue { myLastTelesupXCloseNumber = aValue; }
- (void) setInformZCloseByTransaction: (BOOL) aValue { myInformZCloseByTransaction = aValue; }

/**/
- (int) getTelesupId { return myTelesupId; }
- (char*) getSystemId{ return mySystemId;}
- (char*) getRemoteSystemId{ return myRemoteSystemId;}
- (char*) getTelesupDescription { return myDescription;}
- (char*) getTelesupUserName { return myUserName; }
- (char*) getTelesupPassword { return myPassword; }
- (char*) getRemoteUserName { return myRemoteUserName; }
- (char*) getRemotePassword { return myRemotePassword; }
- (TelcoType) getTelcoType { return myTelcoType; }
- (int) getTelesupFrequency { return myFrequency; }
- (StartMomentType) getStartMoment { return myStartMoment; }
- (int) getAttemptsQty { return myAttemptsQty; }
- (int) getTimeBetweenAttempts { return myTimeBetweenAttempts; }
- (int) getMaxTimeWithoutTelAllowed { return myMaxTimeWithoutTelesupAllowed; }
- (int) getConnectionId1 { return myConnectionId1; }
- (int) getConnectionId2 { return myConnectionId2; }
- (datetime_t) getNextTelesupDateTime { return myNextTelDate; }
- (datetime_t) getLastSuceedTelesupDateTime { return myLastSuceedTelesupDate; }
- (long) getLastTelesupCallId { return myLastTelesupCallId; }
- (long) getLastTelesupTicketId { return myLastTelesupTicketId; }
- (long) getLastTelesupAuditId { return myLastTelesupAuditId; }
- (long) getLastTelesupMessageId { return myLastTelesupMessageId; }
- (long) getLastTelesupAdditionalTicketId { return myLastTelesupAdditionalTicketId; }
- (long) getLastTelesupCollectorId { return myLastTelesupCollectorId; }
- (long) getLastTelesupCashRegisterId { return myLastTelesupCashRegisterId; }
- (BOOL) isDeleted { return myDeleted; }
- (datetime_t) getLastAttemptDateTime { return myLastAttemptDateTime; }
- (int) getFromHour { return myFromHour; }
- (int) getToHour { return myToHour; }
- (char*) getAcronym { return myAcronym; }
- (char*) getExtension { return myExtension; }
- (CONNECTION_SETTINGS) getConnection1 { return myConnection1; }
- (BOOL) isActive { return myActive; }
- (BOOL) getSendAudits{	return mySendAudits;}
- (BOOL) getSendTraffic{ return mySendTraffic; }
- (datetime_t) getNextSecondaryTelesupDateTime { return myNextSecondaryTelDate; }
- (int) getTelesupFrame { return myFrame; }
- (int) getCabinIdleWaitTime { return myCabinIdleWaitTime; } 

/*CIM*/
- (unsigned long) getLastTelesupDepositNumber { return myLastTelesupDepositNumber; }
- (unsigned long)  getLastTelesupExtractionNumber { return myLastTelesupExtractionNumber; }

- (unsigned long) getLastTelesupAlarmId { return myLastTelesupAlarmId; }
- (BOOL) getInformDepositsByTransaction { return myInformDepositsByTransaction; }
- (BOOL) getInformExtractionsByTransaction { return myInformExtractionsByTransaction; }
- (BOOL) getInformAlarmsByTransaction { return myInformAlarmsByTransaction; }
- (unsigned long) getLastTelesupZCloseNumber { return myLastTelesupZCloseNumber; }
- (unsigned long) getLastTelesupXCloseNumber { return myLastTelesupXCloseNumber; }
- (BOOL) getInformZCloseByTransaction { return myInformZCloseByTransaction; }

/**/
- (void) applyChanges
{
	id telesupDAO;
	telesupDAO = [[Persistence getInstance] getTelesupSettingsDAO];

	[telesupDAO store: self];

}


/**/
- (void) restore
{
	TELESUP_SETTINGS obj;

	//Recupera el objeto de la persistencia
	obj =	[[[Persistence getInstance] getTelesupSettingsDAO] loadById: [self getTelesupId]];		

	//Setea los valores a la instancia en memoria
  [self setSystemId: [obj getSystemId]];
	[self setRemoteSystemId: [obj getRemoteSystemId]];
  [self setTelesupDescription: [obj getTelesupDescription]];
	[self setTelesupUserName: [obj getTelesupUserName]];
	[self setTelesupPassword: [obj getTelesupPassword]];
	[self setRemoteUserName: [obj getRemoteUserName]];
	[self setRemotePassword: [obj getRemotePassword]];	
	[self setTelcoType: [obj getTelcoType]];
	[self setTelesupFrequency: [obj getTelesupFrequency]];
	[self setStartMoment: [obj getStartMoment]];
	[self setAttemptsQty: [obj getAttemptsQty]];
	[self setTimeBetweenAttempts: [obj getTimeBetweenAttempts]];
	[self setConnectionId1: [obj getConnectionId1]];
	[self setConnectionId2: [obj getConnectionId2]];
	[self setNextTelesupDateTime: [obj getNextTelesupDateTime]];
	[self setLastSuceedTelesupDateTime: [obj getLastSuceedTelesupDateTime]];

	[self setLastTelesupCallId: [obj getLastTelesupCallId]];
	[self setLastTelesupTicketId: [obj getLastTelesupTicketId]];
	[self setLastTelesupAuditId: [obj getLastTelesupAuditId]];
	[self setLastTelesupMessageId: [obj getLastTelesupMessageId]];
  [self setLastTelesupAdditionalTicketId: [obj getLastTelesupAdditionalTicketId]];
  [self setLastTelesupCollectorId: [obj getLastTelesupCollectorId]];
  [self setLastTelesupCashRegisterId: [obj getLastTelesupCashRegisterId]];
	[self setFromHour: [obj getFromHour]];
	[self setToHour: [obj getToHour]];
	[self setAcronym: [obj getAcronym]];
	[self setExtension: [obj getExtension]];
	[self setActive: [obj isActive]];
	[self setDeleted: [obj isDeleted]];
	[self setNextSecondaryTelesupDateTime: [obj getNextSecondaryTelesupDateTime]];
	[self setTelesupFrame: [obj getTelesupFrame]];
	[self setCabinIdleWaitTime: [obj getCabinIdleWaitTime]];

	[self setLastTelesupAlarmId: [obj getLastTelesupAlarmId]];
  [self setInformDepositsByTransaction: [obj getInformDepositsByTransaction]];
  [self setInformExtractionsByTransaction: [obj getInformExtractionsByTransaction]];
  [self setInformAlarmsByTransaction: [obj getInformAlarmsByTransaction]];
	[self setInformZCloseByTransaction: [obj getInformZCloseByTransaction]]; 


	[obj free];	
}

- (COLLECTION) getConnections
{
	COLLECTION collection = [OrdCltn new];

	if (myConnectionId1 != 0)	[collection add: myConnection1];
	if (myConnectionId2 != 0)	[collection add: myConnection2];

	return collection;
}

/**/
- (STR) str
{
  return myDescription;
}

/**/
- (void) setLastTariffTableHistoryId: (int) aValue { myLastTariffTableHistoryId = aValue; }
- (int) getLastTariffTableHistoryId { return myLastTariffTableHistoryId;}

/**/
- (BOOL) sendOnline: (int) aModuleCode
{
	BOOL result = FALSE;

	switch (aModuleCode) {

		case ModuleCode_SEND_DROPS:
			result = [self getInformDepositsByTransaction];
		break;

		case ModuleCode_SEND_EXTRACTIONS:
			result = [self getInformExtractionsByTransaction];
		break;

		case ModuleCode_SEND_ALARMS:
			result = [self getInformAlarmsByTransaction];
		break;
	
		default: break;
	}

	return result;
}

@end	
