#include "TelesupervisionManager.h"
#include "TelesupSettingsDAO.h"
#include "Persistence.h"
#include "SettingsExcepts.h"
#include "ordcltn.h"
#include "UserManager.h"
#include "Audit.h"
#include "system/util/all.h"
#include "TelesupDefs.h"

static id singleInstance = NULL;

@implementation TelesupervisionManager


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
	int i;
	TELESUP_SETTINGS telesup;

	myTelesups = [[[Persistence getInstance] getTelesupSettingsDAO] loadAll];

	myConnections = [[[Persistence getInstance] getConnectionSettingsDAO] loadAll];

	for (i = 0; i < [myTelesups size]; ++i)
	{
		telesup	= [myTelesups at: i];
		if ( [telesup getConnectionId1] != 0 ) {
			[telesup setConnection1: [self getConnection: [telesup getConnectionId1]] ];
		}


		// Si el telcoType es igual a cero, entonces lo pongo en SARII_TSUP_ID (por compatibilidad hacia atras)
		// Nunca deberia venir en 0, excepto si se actualizo desde la version 0.4
		if ( [telesup getTelcoType] == 0 ) {
			[telesup setTelcoType: SARII_TSUP_ID];
			TRY
				[telesup applyChanges];
			CATCH
				ex_printfmt();
			//	doLog(0,"Fallo el intento de guardar la supervision al SAR II\n");
			END_TRY
		}

	}

	[self loadDNSSettings];

	// inicializa de nuevo los archivos de telesupervision
	[self initGprsFiles];

	return self;
}


/*******************************************************************************************
*																			TELESUP SETTINGS
*
*******************************************************************************************/


/**/
- (TELESUP_SETTINGS) getTelesup: (int) aTelesupId
{
	int i = 0;
	
	for (i=0; i<[myTelesups size]; ++i) 
		if ([ [myTelesups at: i] getTelesupId] == aTelesupId) return [myTelesups at: i];
	
	THROW(REFERENCE_NOT_FOUND_EX);	
	return NULL;
}

/**/
- (TELESUP_SETTINGS) getTelesupByTelcoType: (TelcoType) aTelcoType
{
	int i = 0;

	assert(myTelesups);
    printf("aTelcoType = %d\n", aTelcoType);
	for (i=0; i<[myTelesups size]; ++i) {

		if ([ [myTelesups at: i] getTelcoType] == aTelcoType) return [myTelesups at: i];
	}

	return NULL;
}

/**/
- (void) setTelSystemId: (int) aTelesupId value: (char*) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setSystemId: aValue];
}

/**/
- (void) setTelRemoteSystemId: (int) aTelesupId value: (char*) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setRemoteSystemId: aValue];
}

/**/
- (void) setTelDescription: (int) aTelesupId value: (char*) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setTelesupDescription: aValue];
}

/**/
- (void) setTelUserName: (int) aTelesupId value: (char*) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setTelesupUserName: aValue];
}

/**/
- (void) setTelPassword: (int) aTelesupId value: (char*) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setTelesupPassword: aValue];
}

/**/
- (void) setTelRemoteUserName: (int) aTelesupId value: (char*) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setRemoteUserName: aValue];
}
/**/
- (void) setTelRemotePassword: (int) aTelesupId value: (char*) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setRemotePassword: aValue];
}

/**/
- (void) setTelTelcoType: (int) aTelesupId value: (int) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setTelcoType: aValue];
}

/**/
- (void) setTelFrequency: (int) aTelesupId value: (int) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setTelesupFrequency: aValue];
}

/**/
- (void) setTelStartMoment: (int) aTelesupId value: (int) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setStartMoment: aValue];
}

/**/
- (void) setTelAttemptsQty: (int) aTelesupId value: (int) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setAttemptsQty: aValue];
}

/**/
- (void) setTelTimeBetweenAttempts: (int) aTelesupId value: (int) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setTimeBetweenAttempts: aValue];
}

/**/
- (void) setTelMaxTimeWithoutTelAllowed: (int) aTelesupId value: (int) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setMaxTimeWithoutTelAllowed: aValue];
}

/**/
- (void) setTelConnectionId1: (int) aTelesupId value: (int) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	CONNECTION_SETTINGS connection = NULL;

	if (aValue > 0) connection = [self getConnection: aValue];
	
	[obj setConnectionId1: aValue];
	[obj setConnection1: connection];
}

/**/
- (void) setTelConnectionId2: (int) aTelesupId value: (int) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	CONNECTION_SETTINGS connection = NULL;

	if (aValue > 0) connection = [self getConnection: aValue];
	
	[obj setConnectionId2: aValue];
	[obj setConnection2: connection];
}

/**/
- (void) setTelNextTelesupDateTime: (int) aTelesupId value: (datetime_t) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setNextTelesupDateTime: aValue];
}

/**/
- (void) setTelLastSuceedTelesupDateTime: (int) aTelesupId value: (datetime_t) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setLastSuceedTelesupDateTime: aValue];
}

/**/
- (void) setTelLastTelesupCallId: (int) aTelesupId value: (long) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setLastTelesupCallId: aValue];
}

/**/
- (void) setTelLastTelesupTicketId: (int) aTelesupId value: (long) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setLastTelesupTicketId: aValue];
}

/**/
- (void) setTelLastTelesupAuditId: (int) aTelesupId value: (long) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setLastTelesupAuditId: aValue];
}

/**/
- (void) setTelLastTelesupMessageId: (int) aTelesupId value: (long) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setLastTelesupMessageId: aValue];
}

/**/
- (void) setTelLastTelesupAdditionalTicketId: (int) aTelesupId value: (long) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setLastTelesupAdditionalTicketId: aValue];
}

/**/
- (void) setTelLastTelesupCollectorId: (int) aTelesupId value: (long) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setLastTelesupCollectorId: aValue];
}

/**/
- (void) setTelLastTelesupCashRegisterId: (int) aTelesupId value: (long) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	
	[obj setLastTelesupCashRegisterId: aValue];
}

/**/
- (void) setTelExtension: (int) aTelesupId value: (char*) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setExtension: aValue];
}

/**/
- (void) setTelAcronym: (int) aTelesupId value: (char*) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setAcronym: aValue];
}

/**/
- (void) setTelFromHour: (int) aTelesupId value: (int) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setFromHour: aValue];
}

/**/
- (void) setSendAudits:(int) aTelesupId value:(BOOL) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setSendAudits: aValue];
}

/**/
- (void) setSendTraffic:(int) aTelesupId value:(BOOL) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setSendTraffic: aValue];
}

/**/
- (void) setTelToHour: (int) aTelesupId value: (int) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setToHour: aValue];
}

/**/
- (void) setTelScheduled: (int) aTelesupId value: (BOOL) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setActive: aValue];
}

/**/
- (void) setTelNextSecondaryDate: (int) aTelesupId value: (datetime_t) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setNextSecondaryTelesupDateTime: aValue];
}

/**/
- (void) setTelFrame: (int) aTelesupId value: (int) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setTelesupFrame: aValue];
}

/**/
- (void) setTelCabinIdleWaitTime: (int) aTelesupId value: (int) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setCabinIdleWaitTime: aValue];
}

/**/
- (void) setTelLastTelesupDepositNumber: (int) aTelesupId value: (unsigned long) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setLastTelesupDepositNumber: aValue];
}

/**/
- (void) setTelLastTelesupZCloseNumber: (int) aTelesupId value: (unsigned long) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setLastTelesupZCloseNumber: aValue];
}

/**/
- (void) setTelLastTelesupXCloseNumber: (int) aTelesupId value: (unsigned long) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setLastTelesupXCloseNumber: aValue];
}

/**/
- (void) setTelLastTelesupExtractionNumber: (int) aTelesupId value: (unsigned long) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setLastTelesupExtractionNumber: aValue];
}

/**/
- (void) setTelLastTelesupAlarmId: (int) aTelesupId value: (unsigned long) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setLastTelesupAlarmId: aValue];
}

/**/
- (void) setTelInformDepositsByTransaction: (int) aTelesupId value: (BOOL) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setInformDepositsByTransaction: aValue];
}

/**/
- (void) setTelInformExtractionsByTransaction: (int) aTelesupId value: (BOOL) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setInformExtractionsByTransaction: aValue];
}

/**/
- (void) setTelInformAlarmsByTransaction: (int) aTelesupId value: (BOOL) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setInformAlarmsByTransaction: aValue];
}

/**/
- (void) setTelInformZCloseByTransaction: (int) aTelesupId value: (BOOL) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setInformZCloseByTransaction: aValue];
}


/*****
 * GET
 *****/
/**/
- (char*) getTelSystemId: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getSystemId];
}

/**/
- (BOOL) getSendAudits:(int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getSendAudits];
}

/**/
- (BOOL) getSendTraffic:(int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getSendTraffic];	
}

/**/
- (char*) getTelRemoteSystemId: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getRemoteSystemId];
}

/**/
- (char*) getTelDescription: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getTelesupDescription];
}
 
/**/
- (char*) getTelUserName: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getTelesupUserName];
}

/**/
- (char*) getTelPassword: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getTelesupPassword];
}

/**/
- (char*) getTelRemoteUserName: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getRemoteUserName];
}

/**/
- (char*) getTelRemotePassword: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getRemotePassword];
}

/**/
- (int) getTelTelcoType: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getTelcoType];
}

/**/
- (int) getTelFrequency: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getTelesupFrequency];
}

/**/
- (int) getTelStartMoment: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getStartMoment];
}

/**/
- (int) getTelAttemptsQty: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getAttemptsQty];
}

/**/
- (int) getTelTimeBetweenAttempts: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getTimeBetweenAttempts];
}

/**/
- (int) getTelMaxTimeWithoutTelAllowed: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getMaxTimeWithoutTelAllowed];
}

/**/
- (int) getTelConnectionId1: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getConnectionId1];
}

/**/
- (int) getTelConnectionId2: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getConnectionId2];
}

/**/
- (datetime_t) getTelNextTelesupDateTime: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getNextTelesupDateTime];
}

/**/
- (datetime_t) getTelLastSuceedTelesupDateTime: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getLastSuceedTelesupDateTime];
}

/**/
- (long) getTelLastTelesupCallId: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getLastTelesupCallId];
}

/**/
- (long) getTelLastTelesupTicketId: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getLastTelesupTicketId];
}

/**/
- (long) getTelLastTelesupAuditId: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getLastTelesupAuditId];
}

/**/
- (long) getTelLastTelesupMessageId: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getLastTelesupMessageId];
}

/**/
- (long) getTelLastTelesupAdditionalTicketId: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getLastTelesupAdditionalTicketId];
}

/**/
- (long) getTelLastTelesupCollectorId: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getLastTelesupCollectorId];
}

/**/
- (long) getTelLastTelesupCashRegisterId: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	return [obj getLastTelesupCashRegisterId];
}
/**/
- (char*) getTelExtension: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	return [obj getExtension];
}

/**/
- (char*) getTelAcronym: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	return [obj getAcronym];
}

/**/
- (int) getTelFromHour: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	return [obj getFromHour];
}

/**/
- (int) getTelToHour: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	return [obj getToHour];
}

/**/
- (BOOL) getTelScheduled: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	return [obj isActive];
}

/**/
- (datetime_t) getTelNextSecondaryDate: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	return [obj getNextSecondaryTelesupDateTime];
}

/**/
- (int) getTelFrame: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	return [obj getTelesupFrame];
}

/**/
- (int) getTelCabinIdleWaitTime: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	return [obj getCabinIdleWaitTime];
}

/**/
- (char *) getMainTelesupSystemId
{
	TELESUP_SETTINGS telesup;

	telesup = [self getTelesupByTelcoType: PIMS_TSUP_ID];
	if (telesup) return [telesup getSystemId];

	telesup = [self getTelesupByTelcoType: SARII_PTSD_TSUP_ID];
	if (telesup) return [telesup getSystemId];

	telesup = [self getTelesupByTelcoType: G2_TSUP_ID];
	if (telesup) return [telesup getSystemId];

	telesup = [self getTelesupByTelcoType: SARII_TSUP_ID];
	if (telesup) return [telesup getSystemId];

	telesup = [self getTelesupByTelcoType: IMAS_TSUP_ID];
	if (telesup) return [telesup getSystemId];

	telesup = [self getTelesupByTelcoType: HOYTS_BRIDGE_TSUP_ID];
	if (telesup) return [telesup getSystemId];

	telesup = [self getTelesupByTelcoType: BRIDGE_TSUP_ID];
	if (telesup) return [telesup getSystemId];


	return NULL;
}

/**/
- (void) setTelLastTariffTableHistoryId: (int) aTelesupId value: (int) aValue
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj setLastTariffTableHistoryId: aValue];
}

/**/
- (long) getTelLastTariffTableHistoryId: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	return [obj getLastTariffTableHistoryId];
}

/**/
- (unsigned long) getTelLastTelesupDepositNumber: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	return [obj getLastTelesupDepositNumber];
}

/**/
- (unsigned long) getTelLastTelesupZCloseNumber: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	return [obj getLastTelesupZCloseNumber];
}

/**/
- (unsigned long) getTelLastTelesupXCloseNumber: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	return [obj getLastTelesupXCloseNumber];
}

/**/
- (unsigned long) getTelLastTelesupExtractionNumber: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	return [obj getLastTelesupExtractionNumber];
}

/**/
- (unsigned long) getTelLastTelesupAlarmId: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	return [obj getLastTelesupAlarmId];
}

/**/
- (BOOL) getTelInformDepositsByTransaction: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	return [obj getInformDepositsByTransaction];
}

/**/
- (BOOL) getTelInformExtractionsByTransaction: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	return [obj getInformExtractionsByTransaction];
}

/**/
- (BOOL) getTelInformAlarmsByTransaction: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	return [obj getInformAlarmsByTransaction];
}

/**/
- (BOOL) getTelInformZCloseByTransaction: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	return [obj getInformZCloseByTransaction];
}

/**/
- (void) telesupApplyChanges: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
  
	[obj applyChanges];
	[obj restore];
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
	volatile int error;
  TELESUP_SETTINGS newTelesup = [TelesupSettings new];

	// Solo puede haber una supervision por tipo
	if ([self getTelesupByTelcoType: aTelcoType])
		THROW(ONLY_ONE_TELESUP_ALLOWED_EX);

	[newTelesup setSystemId: aSystemId];
	[newTelesup setTelesupDescription: aDescription];
	[newTelesup setTelesupUserName: aUserName];
	[newTelesup setTelesupPassword: aPassword];
	[newTelesup setRemoteUserName: aRemoteUserName];
	[newTelesup setRemotePassword: aRemotePassword];
	[newTelesup setRemoteSystemId: aRemoteSystemId];
	[newTelesup setTelcoType: aTelcoType];
	[newTelesup setTelesupFrequency: aFrecuency];
	[newTelesup setStartMoment: aStartMoment];
	[newTelesup setAttemptsQty: aAttemptsQty];
	[newTelesup setTimeBetweenAttempts: aTimeBetweenAttempts];
	[newTelesup setMaxTimeWithoutTelAllowed: aMaxTimeWithoutTelAllowed];
	[newTelesup setConnectionId1: aConnectionId1];
	[newTelesup setConnection1: [self getConnection: aConnectionId1]];
	[newTelesup setConnectionId2: aConnectionId2];
	[newTelesup setNextTelesupDateTime: aNextTelesupDateTime];
	[newTelesup setFromHour: aFromHour];
	[newTelesup setToHour: aToHour];
	[newTelesup setAcronym: anAcronym];
	[newTelesup setExtension: anExtension];
	[newTelesup setActive: aScheduled];
	[newTelesup setNextSecondaryTelesupDateTime: aNextSecondaryTelesupDateTime];
	[newTelesup setTelesupFrame: aFrame];
	[newTelesup setCabinIdleWaitTime: aCabinIdleWaitTime];
	[newTelesup setInformDepositsByTransaction: anInformDepositsByTransaction];
	[newTelesup setInformExtractionsByTransaction: anInformExtractionsByTransaction];
	[newTelesup setInformAlarmsByTransaction: anInformAlarmsByTransaction];
	[newTelesup setInformZCloseByTransaction: anInformZCloseByTransaction];

    
    [newTelesup applyChanges];
    [self addTelesupToCollection: newTelesup];

	TRY
		if (![[TelesupervisionManager getInstance] writeTelesupsToFile])
			error = 1;

		[[TelesupervisionManager getInstance] updateGprsConnections: [newTelesup getConnection1]];

	CATCH
		error = 1;
	END_TRY

	/*if (error)
	{
		doLog(0,"ERROR writing supervision config to file\n");
	}*/

	
  return [newTelesup getTelesupId];
}

/**/
- (void) removeTelesup: (int) aTelesupId
{
	int i;
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];

	if (obj && (([obj getTelcoType] == CMP_TSUP_ID) || ([obj getTelcoType] == SARI_TSUP_ID) || ([obj getTelcoType] == CMP_OUT_TSUP_ID))) THROW(CANNOT_REMOVE_DEFAULT_TELESUP_EX);

	for (i=0; i<[myTelesups size]; ++i) 
		if ([ [myTelesups at: i] getTelesupId] == aTelesupId) {
    	[[myTelesups at: i] setDeleted: TRUE];
	    [[myTelesups at: i] applyChanges];
			[myTelesups removeAt: i];

			return;
		}
    
	THROW(REFERENCE_NOT_FOUND_EX);	  
}


/**/
- (void) restoreTelesup: (int) aTelesupId
{
	TELESUP_SETTINGS obj = [self getTelesup: aTelesupId];
	[obj restore];
}

/**/
- (COLLECTION) getTelesups
{
	return myTelesups;
}

/**/
- (COLLECTION) getTelConnections: (int) aTelesupId
{
	TELESUP_SETTINGS newTelesup = [TelesupSettings new];
	return [newTelesup getConnections];
}

/**/
- (void) addTelesupToCollection: (TELESUP_SETTINGS) aTelesup
{
	[myTelesups add: aTelesup];
}

/**/
- (int) getTelesupIdByRemoteSystemId: (char *) aSystemId
{
	int i;
	TELESUP_SETTINGS telesup;

	for (i = 0; i < [myTelesups size]; ++i) {

		telesup = [myTelesups at: i];
		if (strcmp([telesup getRemoteSystemId], aSystemId) == 0) return [telesup getTelesupId];

	}

	return 0;

}

/*******************************************************************************************
*																			CONNECTIONS
*
*******************************************************************************************/

/**/
- (void) setConDescription: (int) aConnectionId value: (char*) aValue
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	[obj setConnectionDescription: aValue];
}

/**/
- (void) setConModemPhoneNumber: (int) aConnectionId value: (char*) aValue
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	[obj setModemPhoneNumber: aValue];
}

/**/
- (void) setConDomain: (int) aConnectionId value: (char*) aValue
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	[obj setDomain: aValue];
}

/**/
- (void) setConIP: (int) aConnectionId value: (char*) aValue
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	[obj setConnectionIP: aValue];
}

/**/
- (void) setConISPPhoneNumber: (int) aConnectionId value: (char*) aValue
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	[obj setISPPhoneNumber: aValue];
}

/**/
- (void) setConUserName: (int) aConnectionId value: (char*) aValue
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	[obj setConnectionUserName: aValue];
}

/**/
- (void) setConPassword: (int) aConnectionId value: (char*) aValue
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	[obj setConnectionPassword: aValue];
}

/**/
- (void) setConType: (int) aConnectionId value: (int) aValue
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	[obj setConnectionType: aValue];
}

/**/
- (void) setConPortType: (int) aConnectionId value: (int) aValue
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	[obj setPortType: aValue];
}

/**/
- (void) setConPortId: (int) aConnectionId value: (int) aValue
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	[obj setPortId: aValue];
}

/**/
- (void) setConRingsQty: (int) aConnectionId value: (int) aValue
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	[obj setRingsQty: aValue];
}

/**/
- (void) setConTCPPortSource: (int) aConnectionId value: (int) aValue
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	[obj setTCPPortSource: aValue];
}

/**/
- (void) setConTCPPortDestination: (int) aConnectionId value: (int) aValue
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	[obj setTCPPortDestination: aValue];
}

/**/
- (void) setConPPPConnectionId: (int) aConnectionId value: (int) aValue
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	[obj setPPPConnectionId: aValue];
}

/**/
- (void) setConAttemptsQty: (int) aConnectionId value: (int) aValue
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	[obj setConnectionAttemptsQty: aValue];
}

/**/
- (void) setConTimeBetweenAttempts: (int) aConnectionId value: (int) aValue
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	[obj setConnectionTimeBetweenAttempts: aValue];
}

/**/
- (void) setConSpeed: (int) aConnectionId value: (int) aValue
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	[obj setConnectionSpeed: aValue];
}

/**/
- (void) setConConnectBy: (int) aConnectionId value: (int) aValue
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	[obj setConnectBy: aValue];
}

/**/
- (void) setConDomainSup: (int) aConnectionId value: (char*) aValue
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	[obj setDomainSup: aValue];
}


/**/
- (char*) getConDescription: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	
	return [obj getConnectionDescription];
}	

/**/
- (char*) getConModemPhoneNumber: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];

	return [obj getModemPhoneNumber];
}

/**/
- (char*) getConDomain: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];

	return [obj getDomain];
}

/**/
- (char*) getConIP: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];

	return [obj getIP];
}

/**/
- (char*) getConISPPhoneNumber: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];

	return [obj getISPPhoneNumber];
}

/**/
- (char*) getConUserName: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];

	return [obj getConnectionUserName];
}

/**/
- (char*) getConPassword: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];

	return [obj getConnectionPassword];
}

/**/
- (int) getConType: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];

	return [obj getConnectionType];
}

/**/
- (int) getConPortType: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];

	return [obj getConnectionPortType];
}

/**/
- (int) getConPortId: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];

	return [obj getConnectionPortId];
}

/**/
- (int) getConRingsQty: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];

	return [obj getRingsQty];
}

/**/
- (int) getConTCPPortSource: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];

	return [obj getTCPPortSource];
}

/**/
- (int) getConTCPPortDestination: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];

	return [obj getConnectionTCPPortDestination];
}

/**/
- (int) getConPPPConnectionId: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];

	return [obj getPPPConnectionId];
}

/**/
- (int) getConAttemptsQty: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];

	return [obj getConnectionAttemptsQty];
}

/**/
- (int) getConTimeBetweenAttempts: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];

	return [obj getConnectionTimeBetweenAttempts];
}

/**/
- (int) getConSpeed: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];

	return [obj getConnectionSpeed];
}

/**/
- (int) getConConnectBy: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];

	return [obj getConnectBy];
}

/**/
- (char*) getConDomainSup: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];

	return [obj getDomainSup];
}


/**/
- (void) applyConnectionChanges: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
  
	[obj applyChanges];
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
	CONNECTION_SETTINGS newConnection = [ConnectionSettings new];

	[newConnection setConnectionType: aConnectionType];
  [newConnection setConnectionDescription: aDescription];
	[newConnection setPortType: aPortType];
	[newConnection setPortId: aPortId];
	[newConnection setModemPhoneNumber: aModemPhoneNumber];
	[newConnection setRingsQty: aRingsQty];
	[newConnection setDomain: aDomain];
	[newConnection setTCPPortSource: aTCPPortSource];
	[newConnection setTCPPortDestination: aTCPPortDestination];
	[newConnection setPPPConnectionId: aPPPConnectionId];
	[newConnection setISPPhoneNumber: aISPPhoneNumber];
	[newConnection setConnectionUserName: aUserName];
	[newConnection setConnectionPassword: aPassword];
	[newConnection setConnectionSpeed: aSpeed];
	[newConnection setConnectionIP: anIP];
	[newConnection setConnectBy: aConnectBy];
	[newConnection setDomainSup: aDomainSup];
	
	[newConnection applyChanges];
	[self addConnectionToCollection: newConnection];
	//doLog(0,"Agrego la conexion %d a la lista\n", [newConnection getConnectionId]);
	return [newConnection getConnectionId];
}

/**/
- (void) removeConnection: (int) aConnectionId
{
	int i;

	// Controla si esta asociada a alguna supervision, en caso afirmativo, no se puede eliminar
	for (i=0; i<[myTelesups size]; ++i) {
		if ([[myTelesups at: i] getConnectionId1] == aConnectionId ||
				[[myTelesups at: i] getConnectionId2] == aConnectionId) THROW(REFERENTIAL_INTEGRITY_EX);
	}

	for (i=0; i<[myConnections size]; ++i) 
		if ([ [myConnections at: i] getConnectionId] == aConnectionId) {
    	[[myConnections at: i] setDeleted: TRUE];
	    [[myConnections at: i]  applyChanges];
			[myConnections removeAt: i];
     
			return;
		}
    
	THROW(REFERENCE_NOT_FOUND_EX);	
}

- (void) restoreConnection: (int) aConnectionId
{
	CONNECTION_SETTINGS obj = [self getConnection: aConnectionId];
	[obj restore];
}

/**/
- (CONNECTION_SETTINGS) getConnection: (int) aConnectionId
{
	int i = 0;
	
	for (i=0; i<[myConnections size]; ++i) 
		if ([ [myConnections at: i] getConnectionId] == aConnectionId) return [myConnections at: i];
	
	THROW(REFERENCE_NOT_FOUND_EX);	
	return NULL;
}

/**/
- (int) getLastConnectionId
{	
	if ([myConnections size] == 0)
	  return 0;
	
	return [[myConnections at: ([myConnections size]-1)] getConnectionId];
}

/**/
- (CONNECTION_SETTINGS) getConnectionByDescription: (char *) aValue
{
	int i = 0;
	
	for (i=0; i<[myConnections size]; ++i) 
		if (strcasecmp([[myConnections at: i] getConnectionDescription], aValue) == 0) 
      return [myConnections at: i];
	
	THROW(REFERENCE_NOT_FOUND_EX);	
	return NULL;
}

/**/
- (void) addConnectionToCollection: (CONNECTION_SETTINGS) aConnection
{
	[myConnections add: aConnection];
}

/**/
- (COLLECTION) getConnections
{
  return myConnections; 
}

/**/
- (BOOL) clearTelesupFiles: (char *) aTelesupFileName connectionFileName: (char*) aConnectionFileName
								deviceFileName: (char*) aDeviceFileName
{
	FILE *telesupFile;
	FILE *connectionFile;
	FILE *deviceFile;
	
	// Creo el archivo de telesup
	telesupFile = fopen(aTelesupFileName, "w+");
	if (!telesupFile) {
	//	doLog(0,"ERROR opening file %s\n", aTelesupFileName);
		return FALSE;
	}

	// Creo el archivo de conexion
	connectionFile = fopen(aConnectionFileName, "w+");
	if (!connectionFile) {
	//	doLog(0,"ERROR opening file %s\n", aConnectionFileName);
		fclose(telesupFile);
		return FALSE;
	}

	// Creo el archivo de device
	deviceFile = fopen(aDeviceFileName, "w+");
	if (!deviceFile) {
	//	doLog(0,"ERROR opening file %s\n", aDeviceFileName);
		fclose(telesupFile);
		fclose(connectionFile);
		return FALSE;
	}
	
	// Genero el archivo de supervision
	fprintf(telesupFile, "servidor: %s\n", "");
	fprintf(telesupFile, "idequipo: %s\n", "");
	fprintf(telesupFile, "usuario: %s\n", "");
	fprintf(telesupFile, "password: %s\n", "");
	fprintf(telesupFile, "frecuencia: %d\n", 0);
	fprintf(telesupFile, "root: %s\n", BASE_APP_PATH "");
	fprintf(telesupFile, "bymodem: %s\n", "yes");
	fprintf(telesupFile, "active: %d\n", 0);

	// Genero el archivo de conexion
	fprintf(connectionFile, "waitlogin: %s\n", "no");
	fprintf(connectionFile, "phone: %s\n", "");
	fprintf(connectionFile, "user: %s\n", "");
	fprintf(connectionFile, "password: %s\n", "");
	fprintf(connectionFile, "speed: %d\n", 0);
	fprintf(connectionFile, "attempts: %d\n", 0);
	fprintf(connectionFile, "time_between_attempts: %d\n", 0);

	// Por default es COM4
	fprintf(deviceFile, "/dev/ttyS3");

	fclose(deviceFile);
	fclose(telesupFile);
	fclose(connectionFile);

	return TRUE;
}

#define TSP_CONNECTION_FILE "account.conf"
#define TSP_TELESUP_FILE    "telesup.conf"
#define TSP_DEVICE_FILE			"device"
#define TSP_CALL_SCRIPT_FILE "llamar.script"
#define TSP_HANGUP_SCRIPT_FILE "colgar.script"

- (void) processScript: (char*) aScript file: (FILE *) aFile;
- (char*) getLine: (char*) aText line: (char*) aLine;
- (void) generateConnectScript: (char*) aTagName
				 buffer: (char*) aBuffer
				 destinationFileName: (char*) aDestinationFileName;
				 
/**/
- (char*) getLine: (char*) aText line: (char*) aLine
{
	char *index;

	index = strchr(aText, 13);
	if (!index) index = strchr(aText, 10);
	if (!index) index = strchr(aText, 0);
	if (!index) return NULL;
	
	strncpy(aLine, aText, index - aText);
	aLine[index-aText] = 0;

	index++;
	if (*index == 10) index++;

	return index;
}
				 
/**
 *	Genera el script de conexion adicional que debe ejecutar PPP para conectarse.
 */
- (void) generateConnectScript: (char*) aTagName
				 buffer: (char*) aBuffer
				 destinationFileName: (char*) aDestinationFileName
{
	char *script = NULL;
	FILE *f;

	f = fopen(aDestinationFileName, "w+");
	if (!f) return;

	// Busco la cadena [aTagName]
	if (aBuffer) script = strstr(aBuffer, aTagName);
	if (script) [self processScript: script + strlen(aTagName) + 1 file: f];

	fclose(f);
}		

/**/
- (void) processScript: (char*) aScript file: (FILE *) aFile
{
	char *p = aScript;
	char line[255];
	char command[100];
	char expect[100];
	char *fromIndex, *toIndex;
	int  timeout;
	
	while (*p != 0) {

		p = [self getLine: p line: line];
		if (*line == 0) continue;
		if (*line == '[') return;			// Termina este tipo de script y comienza otro
		if (*line == '#') continue;		// Es un comentario
		
		fromIndex = strstr(line, "\"");
		if (!fromIndex) continue;
		fromIndex++;
		toIndex = strstr(fromIndex, "\"");
		if (!toIndex) continue;
		strncpy(command, fromIndex, toIndex - fromIndex);
		command[toIndex - fromIndex] = 0;
		
		toIndex++;
		fromIndex = strstr(toIndex, "\"");
		if (!fromIndex) continue;		
		fromIndex++;
		toIndex = strstr(fromIndex, "\"");
		if (!toIndex) continue;
		strncpy(expect, fromIndex, toIndex - fromIndex);
		expect[toIndex - fromIndex] = 0;

		// Debo enviar un comando, a no ser que sea un sleep con lo cual espero cierta cantidad de tiempo
		if (strcasecmp(command, "SLEEP") == 0) {
			timeout = atoi(expect);
			// para que no me redondee para abajo
			if (timeout % 1000 != 0) timeout = timeout + 1000;
			fprintf(aFile, "TIMEOUT %d\n",  timeout / 1000);
		}
		else {
			fprintf(aFile, "\"\" \"%s\" \"%s\" \"\"\n", command, expect);
		}
				
	}

}

/**/
- (BOOL) writeTelesupToPath: (TELESUP_SETTINGS) aTelesup path: (char*) aPath
{
	CONNECTION_SETTINGS connection;
	FILE *telesupFile;
	FILE *connectionFile;
	FILE *deviceFile;
	char telesupFileName[255];
	char connectionFileName[255];
	char deviceFileName[255];
	int  comPort;
	char host[100];

	sprintf(telesupFileName, "%s/%s", aPath, TSP_TELESUP_FILE);
	sprintf(connectionFileName, "%s/%s", aPath, TSP_CONNECTION_FILE);
	sprintf(deviceFileName, "%s/%s", aPath, TSP_DEVICE_FILE);
									 	
	if (!aTelesup)
		return [self clearTelesupFiles: telesupFileName connectionFileName: connectionFileName
								 deviceFileName: deviceFileName];
		
	[File makeDir: aPath];

	connection = [self getConnection: [aTelesup getConnectionId1]];
	THROW_NULL(connection);

	// Creo el archivo de telesup
	telesupFile = fopen(telesupFileName, "w+");
	if (!telesupFile) {
	//	doLog(0,"ERROR opening file %s\n", telesupFileName);
		return FALSE;
	}

	// Creo el archivo de conexion
	connectionFile = fopen(connectionFileName, "w+");
	if (!connectionFile) {
	//	doLog(0,"ERROR opening file %s\n", connectionFileName);
		fclose(telesupFile);
		return FALSE;
	}

	// Creo el archivo de telesup
	deviceFile = fopen(deviceFileName, "w+");
	if (!deviceFile) {
		//doLog(0,"ERROR opening file %s\n", deviceFileName);
		fclose(telesupFile);
		fclose(connectionFile);
		return FALSE;
	}
	
	// Genero el archivo de supervision

	if ([connection getConnectBy] == ConnectionByType_IP)
		stringcpy(host, [connection getIP]);
	
	if ([connection getConnectBy] == ConnectionByType_DOMAIN)
		stringcpy(host, [connection getDomainSup]);

	fprintf(telesupFile, "servidor: %s\n", host);
	fprintf(telesupFile, "idequipo: %s\n", [aTelesup getSystemId]);
	fprintf(telesupFile, "usuario: %s\n", [aTelesup getTelesupUserName]);
	fprintf(telesupFile, "password: %s\n", [aTelesup getTelesupPassword]);
	fprintf(telesupFile, "frecuencia: %d\n", [aTelesup getTelesupFrequency]);
	fprintf(telesupFile, "root: %s\n", BASE_APP_PATH "");
	fprintf(telesupFile, "bymodem: %s\n", ([connection getConnectionType] == ConnectionType_LAN) ?
																				"no": "yes");
	fprintf(telesupFile, "active: %d\n", [aTelesup isActive]);

	// Genero el archivo de conexion
	fprintf(connectionFile, "waitlogin: %s\n", "no");
	fprintf(connectionFile, "phone: %s\n", [connection getISPPhoneNumber]);
	fprintf(connectionFile, "user: %s\n", [connection getConnectionUserName]);
	fprintf(connectionFile, "password: %s\n", [connection getConnectionPassword]);
	fprintf(connectionFile, "speed: %d\n", [connection getConnectionSpeed]);
	fprintf(connectionFile, "attempts: %d\n", [aTelesup getAttemptsQty]);
	fprintf(connectionFile, "time_between_attempts: %d\n", [aTelesup getTimeBetweenAttempts]);

	// Genero el archivo de dispositivo
	// Por default es /dev/ttyS3
	comPort = [connection getConnectionPortId];
	if (comPort == 0) comPort = 4;
	fprintf(deviceFile, "/dev/ttyS%d", comPort-1);

	fclose(deviceFile);
	fclose(telesupFile);
	fclose(connectionFile);

	return TRUE;	
}

/**/
- (BOOL) writeTelesupGprs: (CONNECTION_SETTINGS) aConnectionSettings path: (char*) aPath
{
	CONNECTION_SETTINGS connection;
	FILE *connectionFile;
	FILE *deviceFile;
	FILE *apnFile;
	char connectionFileName[255];
	char deviceFileName[255];
	char apnFileName[255];
	int  comPort;

//	doLog(0,"Escribiendo config. GPRS en %s\n", aPath);

	//sprintf(telesupFileName, "%s/%s", aPath, TSP_TELESUP_FILE);
	sprintf(connectionFileName, "%s/%s", aPath, TSP_CONNECTION_FILE);
	sprintf(deviceFileName, "%s/%s", aPath, TSP_DEVICE_FILE);
	sprintf(apnFileName, "%s/%s", aPath, TSP_CALL_SCRIPT_FILE);
						 	
	[File makeDir: aPath];

/*	doLog(0,"connectionFileName = %s \n", connectionFileName);
	doLog(0,"deviceFile = %s\n", deviceFileName);
	doLog(0,"apnFileName = %s\n", apnFileName);
*/

	connection = aConnectionSettings;
	THROW_NULL(connection);

	// Creo el archivo de conexion
	connectionFile = fopen(connectionFileName, "w+");
	if (!connectionFile) {
		//doLog(0,"ERROR opening file %s\n", connectionFileName);
		return FALSE;
	}

	// Creo el archivo de telesup
	deviceFile = fopen(deviceFileName, "w+");
	if (!deviceFile) {
	//	doLog(0,"ERROR opening file %s\n", deviceFileName);
		fclose(connectionFile);
		return FALSE;
	}

	// Creo el archivo de telesup
	apnFile = fopen(apnFileName, "w+");
	if (!apnFile) {
		//doLog(0,"ERROR opening file %s\n", apnFileName);
		fclose(connectionFile);
		fclose(deviceFile);
		return FALSE;
	}

//	doLog(0,"escribiendo en archivo gprs\n");
	//doLog(0,"phone = %s\n", [connection getISPPhoneNumber]);

	// Genero el archivo de conexion
	fprintf(connectionFile, "waitlogin: %s\n", "no");
	fprintf(connectionFile, "phone: %s\n", [connection getISPPhoneNumber]);
	fprintf(connectionFile, "user: %s\n", [connection getConnectionUserName]);
	fprintf(connectionFile, "password: %s\n", [connection getConnectionPassword]);
	fprintf(connectionFile, "speed: %d\n", [connection getConnectionSpeed]);

	// Genero el archivo de apn
	fprintf(apnFile, "'OK' 'AT+CGDCONT=1,\"IP\",\"%s\"'\n", [connection getDomain]);

	// Genero el archivo de dispositivo
	// Por default es /dev/ttyS3
	comPort = [connection getConnectionPortId];
	if (comPort == 0) comPort = 4;
	fprintf(deviceFile, "/dev/ttyS%d", comPort-1);

	fclose(deviceFile);
	fclose(connectionFile);
	fclose(apnFile);

	return TRUE;	
}

/**/
- (BOOL) writeTelesupsToFile
{
	TELESUP_SETTINGS telesupSarI = NULL;
	TELESUP_SETTINGS telesupSarII = NULL;
	int i;
	char *buffer;
	
	// Obtiene la primera de las supervisiones de delsat
	for (i = 0; i < [myTelesups size]; ++i)
	{

		if ( [[myTelesups at: i] getTelcoType] == SARII_TSUP_ID ) {
			telesupSarII = [myTelesups at: i];
		}
		
		if ( [[myTelesups at: i] getTelcoType] == CMP_TSUP_ID ) {
			telesupSarI = [myTelesups at: i];
		}

/*
		if ( ([[[myTelesups at: i] getConnection1] getConnectionType] == ConnectionType_GPRS) && ([[myTelesups at: i] getTelcoType] == PIMS_TSUP_ID )) {
			doLog(0,"Encontro una conexion GPRS configurada\n");
			telesupGprs = [myTelesups at: i];
		}
*/	
	}

	[self writeTelesupToPath: telesupSarII path: BASE_PATH "/etc/peers/default"];
	[self writeTelesupToPath: telesupSarI  path: BASE_PATH "/etc/peers/incoming"];

//if (telesupGprs) [self writeTelesupGprs: telesupGprs path: BASE_PATH "/etc/peers/gprs"];

	buffer = loadFile([[Configuration getDefaultInstance] getParamAsString: "MODEM_SCRIPT_FILE"
													 default: BASE_PATH "/etc/modem.ini"], TRUE);
	
	[self generateConnectScript: "[connect]" buffer: buffer
				 destinationFileName: BASE_PATH "/etc/peers/default/llamar.script"];
	[self generateConnectScript: "[disconnect]" buffer: buffer
				 destinationFileName: BASE_PATH "/etc/peers/default/colgar.script"];

	[self generateConnectScript: "[connect]" buffer: buffer
				 destinationFileName: BASE_PATH "/etc/peers/incoming/llamar.script"];
	[self generateConnectScript: "[disconnect]" buffer: buffer
				 destinationFileName: BASE_PATH "/etc/peers/incoming/colgar.script"];
					 				 
	if (buffer) free(buffer);
					 
	return TRUE;
}


/**/
- (void) updateGprsConnections: (CONNECTION_SETTINGS) aConnectionSettings
{
	int i;
	id connection;

	for (i=0; i<[myTelesups size]; ++i) {

		connection = [[myTelesups at: i] getConnection1];

		if (([connection getConnectionType] == ConnectionType_GPRS) && ([connection getConnectionId] != [aConnectionSettings getConnectionId])) {

			[connection setISPPhoneNumber: [aConnectionSettings getISPPhoneNumber]];
			[connection setConnectionUserName: [aConnectionSettings getConnectionUserName]];
			[connection setConnectionPassword: [aConnectionSettings getConnectionPassword]];
			[connection setDomain: [aConnectionSettings getDomain]];
			[connection setConnectionSpeed: [aConnectionSettings getConnectionSpeed]];
			[connection applyChanges];
		}	

	}

	if ([connection getConnectionType] == ConnectionType_GPRS)
		[self writeTelesupGprs: connection path: BASE_PATH "/etc/peers/gprs"];

} 

/**/
- (void) initGprsFiles
{
	int i;

	for (i=0; i<[myTelesups size]; ++i) 
		if ([[[myTelesups at: i] getConnection1] getConnectionType] == ConnectionType_GPRS) {
			[self writeTelesupGprs: [[myTelesups at: i] getConnection1] path: BASE_PATH "/etc/peers/gprs"];
			return;
		}

}


#define LAST_OK_TELEUSUP_FILE BASE_APP_PATH "/telesup/lastTelesupOk.ftp"
#define LAST_TELEUSUP_FILE 	  BASE_APP_PATH "/telesup/lastTelesup.ftp"

/**/
- (void) loadLastTelesupFiles
{
	FILE *f;
	char buf[50];
	TELESUP_SETTINGS telesup = NULL;
	int i;
	datetime_t lastOk = 0;
	datetime_t lastTelesup = 0;
	
	// Obtiene la primera de las supervisiones de delsat
	for (i = 0; i < [myTelesups size]; ++i)
	{

		if ( [[myTelesups at: i] getTelcoType] == SARII_TSUP_ID ) {
			telesup = [myTelesups at: i];
			break;
		}
	}

  // Si no hay ninguna de delsat, me voy
	if (!telesup) return;

	f = fopen( LAST_OK_TELEUSUP_FILE, "r" );

	if (f) {
		fgets(buf, 40, f);
		lastOk = atoi(buf) - [SystemTime getTimeZone];
		fclose(f);
	}

	f = fopen( LAST_TELEUSUP_FILE, "r" );

	if (f) {
		fgets(buf, 40, f);
		lastTelesup = atoi(buf) - [SystemTime getTimeZone];
		fclose(f);
	}

  [telesup setLastAttemptDateTime: lastTelesup];
  [telesup setLastSuceedTelesupDateTime: lastOk];

  // Grabo la fecha/hora de la ultima supervision exitosa
	[[TelesupSettingsDAO getInstance] updateTelesupDate: telesup];


//  [telesup applyChanges];

}

#define DNS_PATH "/etc"
#define DNS_FILE_NAME "/etc/resolv.conf"
#define DNS_TEMP_FILE_NAME "/rw/etc/config/resolv.conf"

/**/
- (void) loadDNSSettings
{
	STRING_TOKENIZER tokenizer = [StringTokenizer new];
	FILE *dnsFile;
	char buffer[255];
	int count;
	char token[30];
	char *index;

	myDNS1[0] = '\0';
	myDNS2[0] = '\0';
		
	dnsFile = fopen(DNS_TEMP_FILE_NAME, "r");

	[tokenizer setDelimiter: " "];
	[tokenizer setTrimMode: TRIM_ALL];


	if (!dnsFile) {
	//	doLog(0, "No existe el archivo de dns\n");
		return;
	}
	
	if (feof(dnsFile)) return;

	if (!fgets(buffer, 255, dnsFile)) return;

	printf("buffer = %s\n", buffer);	

	[tokenizer restart];
	[tokenizer setText: buffer];
	
	[tokenizer getNextToken: token];
	[tokenizer getNextToken: myDNS1];

	index = strchr(myDNS1, 13);
	if (index) *index = 0;
	index = strchr(myDNS1, 10);
	if (index) *index = 0;
	
	printf("myDNS1 = %s\n", myDNS1);
			
	if (feof(dnsFile)) return;

	if (!fgets(buffer, 255, dnsFile)) return;

	printf("buffer = %s\n", buffer);

	[tokenizer restart];
	[tokenizer setText: buffer];
	
	[tokenizer getNextToken: token];
	[tokenizer getNextToken: myDNS2];

	index = strchr(myDNS2, 13);
	if (index) *index = 0;
	index = strchr(myDNS2, 10);
	if (index) *index = 0;

	printf("myDNS2 = %s\n", myDNS2);

	[tokenizer free];

	fclose(dnsFile);	

	sprintf(buffer, "rm -f %s", DNS_FILE_NAME);
	system(buffer);
	sprintf(buffer, "cp %s %s", DNS_TEMP_FILE_NAME, DNS_PATH);
	system(buffer);
	
}

/**/
- (void) setDNSSettingToFile: (char*) aDNS1 DNS2: (char*) aDNS2
{
	FILE *dnsFile;
	char buffer[255];

	dnsFile = fopen(DNS_TEMP_FILE_NAME, "w+");

	if (!dnsFile) {
		printf("ERROR opening file %s\n", DNS_TEMP_FILE_NAME);
		return;
	}
	
	if (strlen(aDNS1) > 0) fprintf(dnsFile, "nameserver %s\n", aDNS1);
	if (strlen(aDNS2) > 0) fprintf(dnsFile, "nameserver %s\n", aDNS2);

	fclose(dnsFile);

	sprintf(buffer, "rm -f %s", DNS_FILE_NAME);
	system(buffer);
	sprintf(buffer, "cp %s %s", DNS_TEMP_FILE_NAME, DNS_PATH);
	system(buffer);


	[self setDNSSettings: aDNS1 DNS2: aDNS2];

}

/**/
- (char*) getDNS1
{
	return myDNS1;
}

/**/
- (char*) getDNS2
{
	return myDNS2;
}

/**/
- (void) setDNSSettings: (char*) aDNS1 DNS2: (char*) aDNS2
{
	stringcpy(myDNS1, aDNS1);
	stringcpy(myDNS2, aDNS2);
}


@end
