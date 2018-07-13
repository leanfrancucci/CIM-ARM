#include "TelesupFacade.h"
#include "Persistence.h"
#include "SettingsExcepts.h"
#include "TelesupervisionManager.h"

static id singleInstance = NULL;


@implementation TelesupFacade

/**/
+ new
{
	if (!singleInstance) singleInstance = [[super new] initialize];
	return singleInstance;
}

+ getInstance
{
	return [self new];
}

- initialize
{
	[super initialize];
	return self;
}

/*******************************************************************************************
*																			TELESUP SETTINGS
*
*******************************************************************************************/

/**
* SET
*/

/**/
- (void) setTelesupParamAsString: (char*) aParam value: (char *) aValue telesupRol: (int) aTelesupRol
{
	if (strcasecmp(aParam, "Description") == 0 ) {
		[[TelesupervisionManager getInstance] setTelDescription: aTelesupRol value: aValue];
    return;
	}

	if (strcasecmp(aParam, "UserName") == 0 ) {
		[[TelesupervisionManager getInstance] setTelUserName: aTelesupRol value: aValue];
    return;
	}

	if (strcasecmp(aParam, "Password") == 0 ) {
		[[TelesupervisionManager getInstance] setTelPassword: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "RemoteUserName") == 0 ) {
		[[TelesupervisionManager getInstance] setTelRemoteUserName: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "RemotePassword") == 0 ) {
		[[TelesupervisionManager getInstance] setTelRemotePassword: aTelesupRol value: aValue];
		return;
	}
	
	if (strcasecmp(aParam, "SystemId") == 0 ) {
		[[TelesupervisionManager getInstance] setTelSystemId: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "RemoteSystemId") == 0 ) {
		[[TelesupervisionManager getInstance] setTelRemoteSystemId: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "Extension") == 0 ) {
		[[TelesupervisionManager getInstance] setTelExtension: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "Acronym") == 0 ) {
		[[TelesupervisionManager getInstance] setTelAcronym: aTelesupRol value: aValue];
		return;
	}
		
	[[TelesupervisionManager getInstance] restoreTelesup: aTelesupRol];
	THROW_MSG(INVALID_PARAM_EX, aParam);
}

/**/
- (void) setTelesupParamAsInteger: (char*) aParam value: (int) aValue telesupRol: (int) aTelesupRol
{
	if (strcasecmp(aParam, "TelcoType") == 0 ) {
		[[TelesupervisionManager getInstance] setTelTelcoType: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "Frequency") == 0 ) {
		[[TelesupervisionManager getInstance] setTelFrequency: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "StartMoment") == 0 ) {
		[[TelesupervisionManager getInstance] setTelStartMoment: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "AttemptsQty") == 0 ) {
		[[TelesupervisionManager getInstance] setTelAttemptsQty: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "TimeBetweenAttempts") == 0 ) {
		[[TelesupervisionManager getInstance] setTelTimeBetweenAttempts: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "MaxTimeWithoutTelAllowed") == 0 ) {
		[[TelesupervisionManager getInstance] setTelMaxTimeWithoutTelAllowed: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "ConnectionId1") == 0 ) {
		[[TelesupervisionManager getInstance] setTelConnectionId1: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "ConnectionId2") == 0 ) {
		[[TelesupervisionManager getInstance] setTelConnectionId2: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "FromHour") == 0 ) {
		[[TelesupervisionManager getInstance] setTelFromHour: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "ToHour") == 0 ) {
		[[TelesupervisionManager getInstance] setTelToHour: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "Scheduled") == 0 ) {
		[[TelesupervisionManager getInstance] setTelScheduled: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "SendTraffic") == 0 ) {
		[[TelesupervisionManager getInstance] setSendTraffic: aTelesupRol value: aValue];
    return;
	}
	
	if (strcasecmp(aParam, "SendAudits") == 0 ) {
		[[TelesupervisionManager getInstance] setSendAudits: aTelesupRol value: aValue];
    return;
	}

	if (strcasecmp(aParam, "Frame") == 0 ) {
		[[TelesupervisionManager getInstance] setTelFrame: aTelesupRol value: aValue];
    return;
	}
	
	if (strcasecmp(aParam, "CabinIdleWaitTime") == 0 ) {
		[[TelesupervisionManager getInstance] setTelCabinIdleWaitTime: aTelesupRol value: aValue];
    return;
	}

	[[TelesupervisionManager getInstance] restoreTelesup: aTelesupRol];
	THROW_MSG(INVALID_PARAM_EX, aParam);
}

/**/
- (void) setTelesupParamAsDateTime: (char*) aParam value: (datetime_t) aValue telesupRol: (int) aTelesupRol
{
	if (strcasecmp(aParam, "NextTelesupDateTime") == 0 ) {
		[[TelesupervisionManager getInstance] setTelNextTelesupDateTime: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "LastSuceedTelesupDateTime") == 0 ) {
		[[TelesupervisionManager getInstance] setTelLastSuceedTelesupDateTime: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "NextSecondaryTelesupDateTime") == 0 ) {
		[[TelesupervisionManager getInstance] setTelNextSecondaryDate: aTelesupRol value: aValue];
		return;
	}
	
	[[TelesupervisionManager getInstance] restoreTelesup: aTelesupRol];
	THROW_MSG(INVALID_PARAM_EX, aParam);
}

 /**/
- (void) setTelesupParamAsLong: (char*) aParam value: (long) aValue telesupRol: (int) aTelesupRol
{
	if (strcasecmp(aParam, "LastTelesupCallId") == 0 ) {
		[[TelesupervisionManager getInstance] setTelLastTelesupCallId: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "LastTelesupTicketId") == 0 ) {
		[[TelesupervisionManager getInstance] setTelLastTelesupTicketId: aTelesupRol value: aValue];
		return;
	}
	
	if (strcasecmp(aParam, "LastTelesupAuditId") == 0 ) {		
		[[TelesupervisionManager getInstance] setTelLastTelesupAuditId: aTelesupRol value: aValue];
		return;
	}

	if (strcasecmp(aParam, "LastTelesupMessageId") == 0 ) {		
		 [[TelesupervisionManager getInstance] setTelLastTelesupMessageId: aTelesupRol value: aValue];
		return;
	}
  
	if (strcasecmp(aParam, "LastTelesupAdditionalTicketId") == 0 ) {		
		 [[TelesupervisionManager getInstance] setTelLastTelesupAdditionalTicketId: aTelesupRol value: aValue];
		return;
	}
	if (strcasecmp(aParam, "LastTelesupCollectorId") == 0 ){
    [[TelesupervisionManager getInstance] setTelLastTelesupCollectorId: aTelesupRol value: aValue];
    return;
  } 

	if (strcasecmp(aParam, "LastTelesupCashRegisterId") == 0 ){
    [[TelesupervisionManager getInstance] setTelLastTelesupCashRegisterId: aTelesupRol value: aValue];
    return;
  }   
	
  if (strcasecmp(aParam, "LastTariffTableHistoryId") == 0 ) {		
		[[TelesupervisionManager getInstance] setTelLastTariffTableHistoryId: aTelesupRol value: aValue];
		return;
	}

  if (strcasecmp(aParam, "LastTelesupDepositNumber") == 0 ) {		
		[[TelesupervisionManager getInstance] setTelLastTelesupDepositNumber: aTelesupRol value: aValue];
		return;
	}

  if (strcasecmp(aParam, "LastTelesupExtractionNumber") == 0 ) {		
		[[TelesupervisionManager getInstance] setTelLastTelesupExtractionNumber: aTelesupRol value: aValue];
		return;
	}

  if (strcasecmp(aParam, "LastTelesupAlarmId") == 0 ) {		
		[[TelesupervisionManager getInstance] setTelLastTelesupAlarmId: aTelesupRol value: aValue];
		return;
	}

  if (strcasecmp(aParam, "LastTelesupZCloseNumber") == 0 ) {		
		[[TelesupervisionManager getInstance] setTelLastTelesupZCloseNumber: aTelesupRol value: aValue];
		return;
	}

  if (strcasecmp(aParam, "LastTelesupXCloseNumber") == 0 ) {		
		[[TelesupervisionManager getInstance] setTelLastTelesupXCloseNumber: aTelesupRol value: aValue];
		return;
	}

	[[TelesupervisionManager getInstance] restoreTelesup: aTelesupRol];
	THROW_MSG(INVALID_PARAM_EX, aParam);
}

/**/
- (void) setTelesupParamAsBoolean: (char*) aParam value: (BOOL) aValue telesupRol: (int) aTelesupRol
{
  if (strcasecmp(aParam, "InformDepositsByTransaction") == 0 ) {
		[[TelesupervisionManager getInstance] setTelInformDepositsByTransaction: aTelesupRol value: aValue];
		return;
	}

  if (strcasecmp(aParam, "InformExtractionsByTransaction") == 0 ) {
		[[TelesupervisionManager getInstance] setTelInformExtractionsByTransaction: aTelesupRol value: aValue];
		return;
	}

  if (strcasecmp(aParam, "InformAlarmsByTransaction") == 0 ) {
		[[TelesupervisionManager getInstance] setTelInformAlarmsByTransaction: aTelesupRol value: aValue];
		return;
	}

    if (strcasecmp(aParam, "InformZCloseByTransaction") == 0 ) {
		[[TelesupervisionManager getInstance] setTelInformZCloseByTransaction: aTelesupRol value: aValue];
		return;
	}

	[[TelesupervisionManager getInstance] restoreTelesup: aTelesupRol];
	THROW_MSG(INVALID_PARAM_EX, aParam);
}

/**
* GET
*/

/**/
- (char*) getTelesupParamAsString: (char*) aParam telesupRol: (int) aTelesupRol
{
	if (strcasecmp(aParam, "Description") == 0 ) return [[TelesupervisionManager getInstance] getTelDescription: aTelesupRol];
	if (strcasecmp(aParam, "UserName") == 0 ) return [[TelesupervisionManager getInstance] getTelUserName: aTelesupRol];
	if (strcasecmp(aParam, "Password") == 0 ) return [[TelesupervisionManager getInstance] getTelPassword: aTelesupRol];
	if (strcasecmp(aParam, "RemoteUserName") == 0 ) return [[TelesupervisionManager getInstance] getTelRemoteUserName: aTelesupRol];
	if (strcasecmp(aParam, "RemotePassword") == 0 ) return [[TelesupervisionManager getInstance] getTelRemotePassword: aTelesupRol];
	if (strcasecmp(aParam, "SystemId") == 0 ) return [[TelesupervisionManager getInstance]
	getTelSystemId: aTelesupRol];
	if (strcasecmp(aParam, "RemoteSystemId") == 0 ) return [[TelesupervisionManager getInstance]
	getTelRemoteSystemId: aTelesupRol];
	if (strcasecmp(aParam, "Extension") == 0 ) return [[TelesupervisionManager getInstance]
	getTelExtension: aTelesupRol];
	if (strcasecmp(aParam, "Acronym") == 0 ) return [[TelesupervisionManager getInstance]
	getTelAcronym: aTelesupRol];
			
	
	[[TelesupervisionManager getInstance] restoreTelesup: aTelesupRol];

	THROW_MSG(INVALID_PARAM_EX, aParam);
	return NULL;
}

/**/
- (int) getTelesupParamAsInteger: (char*) aParam telesupRol: (int) aTelesupRol
{
	if (strcasecmp(aParam, "TelcoType") == 0 ) return [[TelesupervisionManager getInstance] getTelTelcoType: aTelesupRol];
	if (strcasecmp(aParam, "Frequency") == 0 ) return [[TelesupervisionManager getInstance] getTelFrequency: aTelesupRol];
	if (strcasecmp(aParam, "StartMoment") == 0 ) return [[TelesupervisionManager getInstance]  getTelStartMoment: aTelesupRol];
	if (strcasecmp(aParam, "AttemptsQty") == 0 ) return [[TelesupervisionManager getInstance]  getTelAttemptsQty: aTelesupRol];
	if (strcasecmp(aParam, "TimeBetweenAttempts") == 0 ) return [[TelesupervisionManager getInstance] getTelTimeBetweenAttempts: aTelesupRol];
	if (strcasecmp(aParam, "MaxTimeWithoutTelAllowed") == 0 ) return [[TelesupervisionManager getInstance] getTelMaxTimeWithoutTelAllowed: aTelesupRol];
	if (strcasecmp(aParam, "ConnectionId1") == 0 ) return [[TelesupervisionManager getInstance] getTelConnectionId1: aTelesupRol];
	if (strcasecmp(aParam, "ConnectionId2") == 0 ) return [[TelesupervisionManager getInstance] getTelConnectionId2: aTelesupRol];
	if (strcasecmp(aParam, "FromHour") == 0 ) return [[TelesupervisionManager getInstance] getTelFromHour: aTelesupRol];
	if (strcasecmp(aParam, "ToHour") == 0 ) return [[TelesupervisionManager getInstance] getTelToHour: aTelesupRol];
	if (strcasecmp(aParam, "Scheduled") == 0 ) return [[TelesupervisionManager getInstance] getTelScheduled: aTelesupRol];
	if (strcasecmp(aParam, "SendTraffic") == 0 ) return [[TelesupervisionManager getInstance] getSendTraffic: aTelesupRol];
	if (strcasecmp(aParam, "SendAudits") == 0 ) return [[TelesupervisionManager getInstance] getSendAudits: aTelesupRol];
	if (strcasecmp(aParam, "Frame") == 0 ) return [[TelesupervisionManager getInstance] getTelFrame: aTelesupRol];
  if (strcasecmp(aParam, "CabinIdleWaitTime") == 0 ) return [[TelesupervisionManager getInstance] getTelCabinIdleWaitTime: aTelesupRol];	
	
	[[TelesupervisionManager getInstance] restoreTelesup: aTelesupRol];

	THROW_MSG(INVALID_PARAM_EX, aParam);
	return 0;
}

/**/
- (datetime_t) getTelesupParamAsDateTime: (char*) aParam telesupRol: (int) aTelesupRol
{
	if (strcasecmp(aParam, "NextTelesupDateTime") == 0 ) return [[TelesupervisionManager getInstance] getTelNextTelesupDateTime: aTelesupRol];
	if (strcasecmp(aParam, "LastSuceedTelesupDateTime") == 0 ) return [[TelesupervisionManager getInstance] getTelLastSuceedTelesupDateTime: aTelesupRol];
	if (strcasecmp(aParam, "NextSecondaryTelesupDateTime") == 0 ) return [[TelesupervisionManager getInstance] getTelNextSecondaryDate: aTelesupRol];	
	
	[[TelesupervisionManager getInstance] restoreTelesup: aTelesupRol];

	THROW_MSG(INVALID_PARAM_EX, aParam);
	return 0;
}

/**/
- (long) getTelesupParamAsLong: (char*) aParam telesupRol: (int) aTelesupRol
{

	if (strcasecmp(aParam, "LastTelesupCallId") == 0 ) 
		return [[TelesupervisionManager getInstance] getTelLastTelesupCallId: aTelesupRol];
		
	if (strcasecmp(aParam, "LastTelesupTicketId") == 0 ) 
		return [[TelesupervisionManager getInstance] getTelLastTelesupTicketId: aTelesupRol];
	
	if (strcasecmp(aParam, "LastTelesupAuditId") == 0 ) 
		return [[TelesupervisionManager getInstance] getTelLastTelesupAuditId: aTelesupRol];		
				
	if (strcasecmp(aParam, "LastTelesupMessageId") == 0 ) 
		return [[TelesupervisionManager getInstance] getTelLastTelesupMessageId: aTelesupRol];
		
	if (strcasecmp(aParam, "LastTelesupAdditionalTicketId") == 0 ) 
		return [[TelesupervisionManager getInstance] getTelLastTelesupAdditionalTicketId: aTelesupRol];
	
	if (strcasecmp(aParam, "LastTelesupCollectorId") == 0 ) 
		return [[TelesupervisionManager getInstance] getTelLastTelesupCollectorId: aTelesupRol];

	if (strcasecmp(aParam, "LastTelesupCashRegisterId") == 0 ) 
		return [[TelesupervisionManager getInstance] getTelLastTelesupCashRegisterId: aTelesupRol];
		
	if (strcasecmp(aParam, "LastTariffTableHistoryId") == 0 ) 
		return [[TelesupervisionManager getInstance] getTelLastTariffTableHistoryId: aTelesupRol];

	if (strcasecmp(aParam, "LastTelesupDepositNumber") == 0 ) 
		return [[TelesupervisionManager getInstance] getTelLastTelesupDepositNumber: aTelesupRol];

	if (strcasecmp(aParam, "LastTelesupExtractionNumber") == 0 ) 
		return [[TelesupervisionManager getInstance] getTelLastTelesupExtractionNumber: aTelesupRol];

	if (strcasecmp(aParam, "LastTelesupAlarmId") == 0 ) 
		return [[TelesupervisionManager getInstance] getTelLastTelesupAlarmId: aTelesupRol];

	if (strcasecmp(aParam, "LastTelesupZCloseNumber") == 0 ) 
		return [[TelesupervisionManager getInstance] getTelLastTelesupZCloseNumber: aTelesupRol];

	if (strcasecmp(aParam, "LastTelesupXCloseNumber") == 0 ) 
		return [[TelesupervisionManager getInstance] getTelLastTelesupXCloseNumber: aTelesupRol];

  [[TelesupervisionManager getInstance] restoreTelesup: aTelesupRol];

	THROW_MSG(INVALID_PARAM_EX, aParam);
	return 0;
}

/**/
- (BOOL) getTelesupParamAsBoolean: (char*) aParam telesupRol: (int) aTelesupRol
{
	if (strcasecmp(aParam, "InformDepositsByTransaction") == 0 ) 
		return [[TelesupervisionManager getInstance] getTelInformDepositsByTransaction: aTelesupRol];

	if (strcasecmp(aParam, "InformExtractionsByTransaction") == 0 ) 
		return [[TelesupervisionManager getInstance] getTelInformExtractionsByTransaction: aTelesupRol];

	if (strcasecmp(aParam, "InformAlarmsByTransaction") == 0 ) 
		return [[TelesupervisionManager getInstance] getTelInformAlarmsByTransaction: aTelesupRol];

	if (strcasecmp(aParam, "InformZCloseByTransaction") == 0 ) 
		return [[TelesupervisionManager getInstance] getTelInformZCloseByTransaction: aTelesupRol];
    
  [[TelesupervisionManager getInstance] restoreTelesup: aTelesupRol];

	THROW_MSG(INVALID_PARAM_EX, aParam);
	return 0;

}



/**/
- (int) addTelesup: (char *) aDescription
				userName: (char *) aUserName /**/ password: (char *) aPassword
				remoteUserName: (char*) aRemoteUserName /**/ remotePassword: (char *) aRemotePassword
				systemId: (char*) aSystemId /**/  remoteSystemId: (char *) aRemoteSystemId
				telcoType: (int) aTelcoType /**/ frequency: (int) aFrecuency /**/ startMoment: (int) aStartMoment
				attemptsQty: (int) aAttemptsQty /**/ timeBetweenAttempts: (int) aTimeBetweenAttempts
				maxTimeWithoutTelAllowed: (int) aMaxTimeWithoutTelAllowed /**/
				connectionId1: (int) aConnectionId1 /**/ connectionId2: (int) aConnectionId2
				nextTelesupDateTime: (datetime_t) aNextTelesupDateTime /**/
				acronym: (char *) anAcronym /**/ extension: (char *) anExtension
				fromHour: (int) aFromHour /**/ toHour: (int) aToHour /**/ scheduled: (BOOL) aScheduled
        nextSecondaryTelesupDateTime: (datetime_t) aNextSecondaryTelesupDateTime /**/
        frame: (int) aFrame /**/ cabinIdleWaitTime: (int) aCabinIdleWaitTime	
				informDepositsByTransaction: (BOOL) anInformDepositsByTransaction 
				informExtractionsByTransaction: (BOOL) anInformExtractionsByTransaction
				informAlarmsByTransaction: (BOOL) anInformAlarmsByTransaction		
				informZCloseByTransaction: (BOOL) anInformZCloseByTransaction
				
{	
    
	return [[TelesupervisionManager getInstance] addTelesup: aDescription
				userName: aUserName password: aPassword
				remoteUserName: aRemoteUserName /**/ remotePassword: aRemotePassword
				systemId: aSystemId /**/  remoteSystemId: aRemoteSystemId
				telcoType: aTelcoType /**/ frequency: aFrecuency /**/ startMoment: aStartMoment
				attemptsQty: aAttemptsQty /**/ timeBetweenAttempts: aTimeBetweenAttempts
				maxTimeWithoutTelAllowed: aMaxTimeWithoutTelAllowed /**/
				connectionId1: aConnectionId1 /**/ connectionId2: aConnectionId2
				nextTelesupDateTime: aNextTelesupDateTime /**/
				acronym: anAcronym /**/ extension: anExtension
				fromHour: aFromHour /**/ toHour: aToHour /**/ scheduled: aScheduled
        nextSecondaryTelesupDateTime: aNextSecondaryTelesupDateTime /**/
        frame: aFrame /**/ cabinIdleWaitTime: aCabinIdleWaitTime
				informDepositsByTransaction: anInformDepositsByTransaction 
				informExtractionsByTransaction: anInformExtractionsByTransaction
				informAlarmsByTransaction: anInformAlarmsByTransaction
                informZCloseByTransaction: (BOOL) anInformZCloseByTransaction];
}

/**/
- (void) removeTelesup: (int) aTelesupId
{
	[[TelesupervisionManager getInstance] removeTelesup: aTelesupId];
}

/**/
- (void) telesupApplyChanges: (int) aTelesupRol
{
	TRY

		[[TelesupervisionManager getInstance] telesupApplyChanges: aTelesupRol]; 
	
	CATCH
		
		[[TelesupervisionManager getInstance] restoreTelesup: aTelesupRol];
		RETHROW();
	
	END_TRY
}

/**/
- (COLLECTION) getTelesupRolList
{
	COLLECTION list = [Collection new];
	COLLECTION telesups = [[TelesupervisionManager getInstance] getTelesups];
	int i;

	for (i = 0; i < [telesups size]; ++i)
	{
		[list add: [BigInt int: [[telesups at: i] getTelesupId]]];
	}
	
	return list;

}

/**/
- (int) getTelesupIdByRemoteSystemId: (char *) aSystemId
{
	return [[TelesupervisionManager getInstance] getTelesupIdByRemoteSystemId: aSystemId];
}

/*******************************************************************************************
*																			CONNECTIONS
*
*******************************************************************************************/

/**
* SET
*/

/**/
- (void) setConnectionParamAsString: (char*) aParam value: (char *) aValue connectionId: (int) aConnectionId
{
	if (strcasecmp(aParam, "Description") == 0 ) {
		[[TelesupervisionManager getInstance] setConDescription: aConnectionId value: aValue];
		return;
	}

	if (strcasecmp(aParam, "ModemPhoneNumber") == 0 ) {
		[[TelesupervisionManager getInstance] setConModemPhoneNumber: aConnectionId value: aValue];
		return;
	}

	if (strcasecmp(aParam, "Domain") == 0 ) {
		[[TelesupervisionManager getInstance] setConDomain: aConnectionId value: aValue];
		return;
	}

	if (strcasecmp(aParam, "IP") == 0 ) {
		[[TelesupervisionManager getInstance] setConIP: aConnectionId value: aValue];
		return;
	}

	if (strcasecmp(aParam, "ISPPhoneNumber") == 0 ) {
		[[TelesupervisionManager getInstance] setConISPPhoneNumber: aConnectionId value: aValue];
		return;
	}

	if (strcasecmp(aParam, "UserName") == 0 ) {
		[[TelesupervisionManager getInstance] setConUserName: aConnectionId value: aValue];
		return;
	}

	if (strcasecmp(aParam, "Password") == 0 ) {
		[[TelesupervisionManager getInstance] setConPassword: aConnectionId value: aValue];
		return;
	}

	if (strcasecmp(aParam, "DomainSup") == 0 ) {
		[[TelesupervisionManager getInstance] setConDomainSup: aConnectionId value: aValue];
		return;
	}

	[[TelesupervisionManager getInstance] restoreConnection: aConnectionId];
	THROW_MSG(INVALID_PARAM_EX, aParam);
}

/**/
- (void) setConnectionParamAsInteger: (char*) aParam value: (int) aValue connectionId: (int) aConnectionId
{
	if (strcasecmp(aParam, "Type") == 0 ) {
		[[TelesupervisionManager getInstance] setConType: aConnectionId value: aValue];
		return;
	}

	if (strcasecmp(aParam, "PortType") == 0 ) {
		[[TelesupervisionManager getInstance] setConPortType: aConnectionId value: aValue];
		return;
	}

	if (strcasecmp(aParam, "PortId") == 0 ) {
		[[TelesupervisionManager getInstance] setConPortId: aConnectionId value: aValue];
		return;
	}

	if (strcasecmp(aParam, "RingsQty") == 0 ) {
		[[TelesupervisionManager getInstance] setConRingsQty: aConnectionId value: aValue];
		return;
	}

	if (strcasecmp(aParam, "TCPPortSource") == 0 ) {
		[[TelesupervisionManager getInstance] setConTCPPortSource: aConnectionId value: aValue];
		return;
	}

	if (strcasecmp(aParam, "TCPPortDestination") == 0 ) {
		[[TelesupervisionManager getInstance] setConTCPPortDestination: aConnectionId value: aValue];
		return;
	}

	if (strcasecmp(aParam, "PPPConnectionId") == 0 ) {
		[[TelesupervisionManager getInstance] setConPPPConnectionId: aConnectionId value: aValue];
		return;
	}

	if (strcasecmp(aParam, "Speed") == 0 ) {
		[[TelesupervisionManager getInstance] setConSpeed: aConnectionId value: aValue];
		return;
	}

	if (strcasecmp(aParam, "ConnectBy") == 0 ) {
		[[TelesupervisionManager getInstance] setConConnectBy: aConnectionId value: aValue];
		return;
	}
	
	[[TelesupervisionManager getInstance] restoreConnection: aConnectionId];
	THROW_MSG(INVALID_PARAM_EX, aParam);
}

/**
* GET
*/

/**/
- (char *) getConnectionParamAsString: (char*) aParam connectionId: (int) aConnectionId
{
	if (strcasecmp(aParam, "Description") == 0 ) return [[TelesupervisionManager getInstance] getConDescription: aConnectionId];
	if (strcasecmp(aParam, "ModemPhoneNumber") == 0 ) return [[TelesupervisionManager getInstance] getConModemPhoneNumber: aConnectionId];
	if (strcasecmp(aParam, "Domain") == 0 ) return [[TelesupervisionManager getInstance] getConDomain: aConnectionId];
	if (strcasecmp(aParam, "IP") == 0 ) return [[TelesupervisionManager getInstance] getConIP: aConnectionId];
	if (strcasecmp(aParam, "ISPPhoneNumber") == 0 ) return [[TelesupervisionManager getInstance] getConISPPhoneNumber: aConnectionId];
	if (strcasecmp(aParam, "UserName") == 0 ) return [[TelesupervisionManager getInstance] getConUserName: aConnectionId];
	if (strcasecmp(aParam, "Password") == 0 ) return [[TelesupervisionManager getInstance] getConPassword: aConnectionId];
	if (strcasecmp(aParam, "DomainSup") == 0 ) return [[TelesupervisionManager getInstance] getConDomainSup: aConnectionId];
	
	[[TelesupervisionManager getInstance] restoreConnection: aConnectionId];

	THROW_MSG(INVALID_PARAM_EX, aParam);
	return NULL;
}

/**/
- (int) getConnectionParamAsInteger: (char*) aParam connectionId: (int) aConnectionId
{
	if (strcasecmp(aParam, "Type") == 0 ) return [[TelesupervisionManager getInstance] getConType: aConnectionId];
	if (strcasecmp(aParam, "PortType") == 0 ) return [[TelesupervisionManager getInstance] getConPortType: aConnectionId];
	if (strcasecmp(aParam, "PortId") == 0 ) return [[TelesupervisionManager getInstance] getConPortId: aConnectionId];
	if (strcasecmp(aParam, "RingsQty") == 0 ) return [[TelesupervisionManager getInstance] getConRingsQty: aConnectionId];
	if (strcasecmp(aParam, "TCPPortSource") == 0 ) return [[TelesupervisionManager getInstance] getConTCPPortSource: aConnectionId];
	if (strcasecmp(aParam, "TCPPortDestination") == 0 ) return [[TelesupervisionManager getInstance] getConTCPPortDestination: aConnectionId];
	if (strcasecmp(aParam, "PPPConnectionId") == 0 ) return [[TelesupervisionManager getInstance] getConPPPConnectionId: aConnectionId];

	if (strcasecmp(aParam, "Speed") == 0 ) return [[TelesupervisionManager getInstance] getConSpeed: aConnectionId];
	if (strcasecmp(aParam, "ConnectBy") == 0 ) return [[TelesupervisionManager getInstance] getConConnectBy: aConnectionId];

	
	[[TelesupervisionManager getInstance] restoreConnection: aConnectionId];

	THROW_MSG(INVALID_PARAM_EX, aParam);
	return 0;
}

/**/
- (void) connectionApplyChanges: (int) aConnectionId
{
	TRY

		[[TelesupervisionManager getInstance] applyConnectionChanges: aConnectionId]; 
	
	CATCH
		
			[[TelesupervisionManager getInstance] restoreConnection: aConnectionId];
			RETHROW();
	
	END_TRY
}

/**/
- (int) addConnection: (int) aConnectionType
                       description: (char*) aDescription 
                       portType: (int) aPortType
                       portId: (int) aPortId
                       modemPhoneNumber: (char*) aModemPhoneNumber
                       ringsQty: (int) aRingsQty
                       domain: (char*) aDomain
                       tcpPortSource: (int) aTCPPortSource
                       tcpPortDestination: (int) aTCPPortDestination
                       pppConnectionId: (int) aPPPConnectionId
                       ispPhoneNumber: (char*) aISPPhoneNumber
                       userName: (char*) aUserName
                       password: (char*) aPassword
                       speed: (int) aSpeed
                       IP: (char*) anIP
											 connectBy: (int) aConnectBy
											 domainSup: (char*) aDomainSup

{
	return [[TelesupervisionManager getInstance] addConnection: aConnectionType
                                                              description: aDescription
                                                              portType: aPortType
                                                              portId: aPortId
                                                              modemPhoneNumber: aModemPhoneNumber
                                                              ringsQty: aRingsQty
                                                              domain: aDomain
                                                              tcpPortSource: aTCPPortSource
                                                              tcpPortDestination: aTCPPortDestination
                                                              pppConnectionId: aPPPConnectionId
                                                              ispPhoneNumber: aISPPhoneNumber
                                                              userName: aUserName
                                                              password: aPassword
                                                              speed: aSpeed
                                                              IP: anIP
																															connectBy: aConnectBy
																															domainSup: aDomainSup];
}

/**/
- (void) removeConnection: (int) aConnectionId
{
	[[TelesupervisionManager getInstance] removeConnection: aConnectionId]; 
}

/**/
- (COLLECTION) getConnectionIdList
{
	COLLECTION list = [Collection new];
	COLLECTION connections = [[TelesupervisionManager getInstance] getConnections];
	int i;

	for (i = 0; i < [connections size]; ++i)
	{
		[list add: [BigInt int: [[connections at: i] getConnectionId]]];
	}
	
	return list;
}


@end
