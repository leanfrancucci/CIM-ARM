#ifndef TELESUP_SETTINGS_H
#define TELESUP_SETTINGS_H

#define TELESUP_SETTINGS id

#include "Object.h"
#include "ctapp.h"
#include "ConnectionSettings.h"

/**
 * Clase  
 */

@interface TelesupSettings:  Object
{
  char        myDescription[60 + 1];
  char        mySystemId[16 +1];
	char				myRemoteSystemId[16+1];
  int         myTelesupId;
	char				myUserName[16 + 1];
	char				myPassword[16 + 1];
	char				myRemoteUserName[16 + 1];
	char				myRemotePassword[16 + 1];
	char				myAcronym[16 + 1];
	char				myExtension[16 + 1];
	TelcoType			myTelcoType;
	int					myFrequency;
	StartMomentType		myStartMoment;
	int					myAttemptsQty;
	int					myTimeBetweenAttempts;
	int					myMaxTimeWithoutTelesupAllowed;
	int					myConnectionId1;
	int					myConnectionId2;
	CONNECTION_SETTINGS myConnection1;
	CONNECTION_SETTINGS myConnection2;
	datetime_t			myNextTelDate;
	datetime_t			myLastSuceedTelesupDate;
	datetime_t      myLastAttemptDateTime;
	long				myLastTelesupCallId;
	long				myLastTelesupTicketId;
	long				myLastTelesupAuditId;
	long				myLastTelesupMessageId;
  long        myLastTelesupAdditionalTicketId;
	
	long				myLastTelesupCollectorId;
  long        myLastTelesupCashRegisterId;
	int					myFromHour;
	int					myToHour;
	BOOL				myActive;
	BOOL				myDeleted;

	/*agregados para la telesupervision a Imas*/
	BOOL				mySendAudits;
	BOOL				mySendTraffic;
	
	datetime_t myNextSecondaryTelDate;
	int myFrame;
	int myCabinIdleWaitTime;
  int myLastTariffTableHistoryId;

	/*CIM*/
	unsigned long myLastTelesupDepositNumber;
	unsigned long myLastTelesupExtractionNumber;

	unsigned long myLastTelesupAlarmId;
	BOOL myInformDepositsByTransaction;
	BOOL myInformExtractionsByTransaction;
	BOOL myInformAlarmsByTransaction;
	unsigned long myLastTelesupZCloseNumber;
	unsigned long myLastTelesupXCloseNumber;
	BOOL myInformZCloseByTransaction;
}

/**
 *
 */
+ new;
- initialize;

/**
 * Setea los valores correspondientes a la configuracion general de las telesupervisiones
 */

- (void) setTelesupId: (int) aValue; 
- (void) setSystemId: (char*) aValue;
- (void) setRemoteSystemId: (char*) aValue;
- (void) setTelesupDescription: (char*) aValue;
- (void) setTelesupUserName: (char*) aValue;
- (void) setTelesupPassword: (char*) aValue;
- (void) setRemoteUserName: (char*) aValue;
- (void) setRemotePassword: (char*) aValue;
- (void) setTelcoType: (TelcoType) aValue;
- (void) setTelesupFrequency: (int) aValue;
- (void) setStartMoment: (StartMomentType) aValue;
- (void) setAttemptsQty: (int) aValue;
- (void) setTimeBetweenAttempts: (int) aValue;
- (void) setMaxTimeWithoutTelAllowed: (int) aValue;
- (void) setConnectionId1: (int) aValue;
- (void) setConnectionId2: (int) aValue;
- (void) setNextTelesupDateTime: (datetime_t) aValue;
- (void) setLastSuceedTelesupDateTime: (datetime_t) aValue;
- (void) setConnection1: (CONNECTION_SETTINGS) aConnection;
- (void) setConnection2: (CONNECTION_SETTINGS) aConnection;
- (void) setLastTelesupCallId: (long) aValue;
- (void) setLastTelesupTicketId: (long) aValue;
- (void) setLastTelesupAuditId: (long) aValue;
- (void) setLastTelesupCollectorId: (long) aValue;
- (void) setLastTelesupCashRegisterId: (long) aValue;
- (void) setLastTelesupMessageId: (long) aValue;	
- (void) setLastTelesupAdditionalTicketId: (long) aValue;
- (void) setDeleted: (BOOL) aValue;
- (void) setLastAttemptDateTime: (datetime_t) aValue;
- (void) setFromHour: (int) aValue;
- (void) setToHour: (int) aValue;
- (void) setAcronym: (char*) aValue;
- (void) setExtension: (char*) aValue;
- (void) setActive: (BOOL) aValue;
- (void) setSendAudits:(BOOL) aValue;
- (void) setSendTraffic:(BOOL) aValue;
- (void) setNextSecondaryTelesupDateTime: (datetime_t) aValue;
- (void) setTelesupFrame: (int) aValue;
- (void) setCabinIdleWaitTime: (int) aValue; 

/*CIM*/
- (void) setLastTelesupDepositNumber: (unsigned long) aValue;
- (void) setLastTelesupExtractionNumber: (unsigned long) aValue;

- (void) setLastTelesupAlarmId: (unsigned long) aValue;
- (void) setInformDepositsByTransaction: (BOOL) aValue;
- (void) setInformExtractionsByTransaction: (BOOL) aValue;
- (void) setInformAlarmsByTransaction: (BOOL) aValue;
- (void) setLastTelesupZCloseNumber: (unsigned long) aValue;
- (void) setLastTelesupXCloseNumber: (unsigned long) aValue;
- (void) setInformZCloseByTransaction: (BOOL) aValue;

/**
 * Devuelve los valores correspondientes a la configuracion general de las telesupervisiones
 */

- (int) getTelesupId;  
- (char*) getSystemId;
- (char*) getRemoteSystemId;
- (char*) getTelesupDescription;
- (char*) getTelesupUserName;
- (char*) getTelesupPassword;
- (char*) getRemoteUserName;
- (char*) getRemotePassword;
- (TelcoType) getTelcoType;
- (int) getTelesupFrequency;
- (StartMomentType) getStartMoment;
- (int) getAttemptsQty;
- (int) getTimeBetweenAttempts;
- (int) getMaxTimeWithoutTelAllowed;
- (int) getConnectionId1;
- (int) getConnectionId2;
- (datetime_t) getNextTelesupDateTime;
- (datetime_t) getLastSuceedTelesupDateTime;
- (long) getLastTelesupCallId;
- (long) getLastTelesupTicketId;
- (long) getLastTelesupAuditId;
- (long) getLastTelesupCollectorId;
- (long) getLastTelesupCashRegisterId;
- (long) getLastTelesupMessageId;
- (long) getLastTelesupAdditionalTicketId;
- (BOOL) isDeleted;
- (datetime_t) getLastAttemptDateTime;
- (int) getFromHour;
- (int) getToHour;
- (char*) getAcronym;
- (char*) getExtension;
- (CONNECTION_SETTINGS) getConnection1;
- (BOOL) isActive;
- (BOOL) getSendAudits;
- (BOOL) getSendTraffic;
- (datetime_t) getNextSecondaryTelesupDateTime;
- (int) getTelesupFrame;
- (int) getCabinIdleWaitTime; 

/*CIM*/
- (unsigned long) getLastTelesupDepositNumber;
- (unsigned long)  getLastTelesupExtractionNumber;

- (unsigned long) getLastTelesupAlarmId;
- (BOOL) getInformDepositsByTransaction;
- (BOOL) getInformExtractionsByTransaction;
- (BOOL) getInformAlarmsByTransaction;
- (unsigned long) getLastTelesupZCloseNumber;
- (unsigned long) getLastTelesupXCloseNumber;
- (BOOL) getInformZCloseByTransaction;


/**
 * Aplica los cambios realizados a la configuracion general de la telesupervision
 */	

- (void) applyChanges;

/**
 * Restaura los valores de la configuracion de la telesupervision
 */

- (void) restore;

/**
 *
 */

- (COLLECTION) getConnections;

/**/
- (void) setLastTariffTableHistoryId: (int) aValue;
- (int) getLastTariffTableHistoryId;

/**/
- (BOOL) sendOnline: (int) aModuleCode;

@end

#endif

