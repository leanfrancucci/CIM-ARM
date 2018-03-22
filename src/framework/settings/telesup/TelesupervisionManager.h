#ifndef TELESUPERVISION_MANAGER_H
#define TELESUPERVISION_MANAGER_H

#define TELESUPERVISION_MANAGER id

#include "Object.h"
#include "ctapp.h"
#include "TelesupSettings.h"
#include "ConnectionSettings.h"


/**
 * Clase  
 */

@interface TelesupervisionManager:  Object
{
	COLLECTION myTelesups;
	COLLECTION myConnections;

	char myDNS1[30];
	char myDNS2[30]; 

}

/**
 * 
 */

+ new;
+ getInstance;
- initialize;

/*******************************************************************************************
*																			TELESUP SETTINGS
*
*******************************************************************************************/

/**
 * Setea los valores correspondientes a la telesupervision
 */
- (void) setTelSystemId: (int) aTelesupId value: (char*) aValue;
- (void) setTelRemoteSystemId: (int) aTelesupId value: (char*) aValue;  
- (void) setTelDescription: (int) aTelesupId value: (char*) aValue;
- (void) setTelUserName: (int) aTelesupId value: (char*) aValue;
- (void) setTelPassword: (int) aTelesupId value: (char*) aValue;
- (void) setTelRemoteUserName: (int) aTelesupId value: (char*) aValue;
- (void) setTelRemotePassword: (int) aTelesupId value: (char*) aValue;
- (void) setTelTelcoType: (int) aTelesupId value: (int) aValue;
- (void) setTelFrequency: (int) aTelesupId value: (int) aValue;
- (void) setTelStartMoment: (int) aTelesupId value: (int) aValue;
- (void) setTelAttemptsQty: (int) aTelesupId value: (int) aValue;
- (void) setTelTimeBetweenAttempts: (int) aTelesupId value: (int) aValue;
- (void) setTelMaxTimeWithoutTelAllowed: (int) aTelesupId value: (int) aValue;
- (void) setTelConnectionId1: (int) aTelesupId value: (int) aValue;
- (void) setTelConnectionId2: (int) aTelesupId value: (int) aValue;
- (void) setTelNextTelesupDateTime: (int) aTelesupId value: (datetime_t) aValue;
- (void) setTelLastSuceedTelesupDateTime: (int) aTelesupId value: (datetime_t) aValue;
- (void) setTelLastTelesupCallId: (int) aTelesupId value: (long) aValue;
- (void) setTelLastTelesupTicketId: (int) aTelesupId value: (long) aValue;
- (void) setTelLastTelesupAuditId: (int) aTelesupId value: (long) aValue;
- (void) setTelLastTelesupMessageId: (int) aTelesupId value: (long) aValue;
- (void) setTelLastTelesupAdditionalTicketId: (int) aTelesupId value: (long) aValue;
- (void) setTelLastTelesupCollectorId: (int) aTelesupId value: (long) aValue;
- (void) setTelLastTelesupCashRegisterId: (int) aTelesupId value: (long) aValue;
- (void) setTelExtension: (int) aTelesupId value: (char*) aValue;
- (void) setTelAcronym: (int) aTelesupId value: (char*) aValue;
- (void) setTelFromHour: (int) aTelesupId value: (int) aValue;
- (void) setTelToHour: (int) aTelesupId value: (int) aValue;
- (void) setTelScheduled: (int) aTelesupId value: (BOOL) aValue;
- (void) setSendAudits:(int) aTelesupId value:(BOOL) aValue ;
- (void) setSendTraffic:(int) aTelesupId value:(BOOL) aValue;
- (void) setTelNextSecondaryDate: (int) aTelesupId value: (datetime_t) aValue;
- (void) setTelFrame: (int) aTelesupId value: (int) aValue;
- (void) setTelCabinIdleWaitTime: (int) aTelesupId value: (int) aValue;
- (void) setTelLastTariffTableHistoryId: (int) aTelesupId value: (int) aValue;
- (void) setTelLastTelesupDepositNumber: (int) aTelesupId value: (unsigned long) aValue;
- (void) setTelLastTelesupExtractionNumber: (int) aTelesupId value: (unsigned long) aValue;
- (void) setTelLastTelesupAlarmId: (int) aTelesupId value: (unsigned long) aValue;
- (void) setTelInformDepositsByTransaction: (int) aTelesupId value: (BOOL) aValue;
- (void) setTelInformExtractionsByTransaction: (int) aTelesupId value: (BOOL) aValue;
- (void) setTelInformAlarmsByTransaction: (int) aTelesupId value: (BOOL) aValue;
- (void) setTelLastTelesupZCloseNumber: (int) aTelesupId value: (unsigned long) aValue;
- (void) setTelLastTelesupXCloseNumber: (int) aTelesupId value: (unsigned long) aValue;
- (void) setTelInformZCloseByTransaction: (int) aTelesupId value: (BOOL) aValue;

/**
 * Devuelve los valores correspondientes a la configuracion de las cabinas
 */

- (char*) getTelSystemId: (int) aTelesupId;
- (char*) getTelRemoteSystemId: (int) aTelesupId; 
- (char*) getTelDescription: (int) aTelesupId; 
- (char*) getTelUserName: (int) aTelesupId;
- (char*) getTelPassword: (int) aTelesupId;
- (char*) getTelRemoteUserName: (int) aTelesupId;
- (char*) getTelRemotePassword: (int) aTelesupId;
- (int) getTelTelcoType: (int) aTelesupId;
- (int) getTelFrequency: (int) aTelesupId;
- (int) getTelStartMoment: (int) aTelesupId;
- (int) getTelAttemptsQty: (int) aTelesupId;
- (int) getTelTimeBetweenAttempts: (int) aTelesupId;
- (int) getTelMaxTimeWithoutTelAllowed: (int) aTelesupId;
- (int) getTelConnectionId1: (int) aTelesupId;
- (int) getTelConnectionId2: (int) aTelesupId;
- (datetime_t) getTelNextTelesupDateTime: (int) aTelesupId;
- (datetime_t) getTelLastSuceedTelesupDateTime: (int) aTelesupId;
- (long) getTelLastTelesupCallId: (int) aTelesupId;
- (long) getTelLastTelesupTicketId: (int) aTelesupId;
- (long) getTelLastTelesupAuditId: (int) aTelesupId;
- (long) getTelLastTelesupMessageId: (int) aTelesupId;
- (long) getTelLastTelesupAdditionalTicketId: (int) aTelesupId;
- (long) getTelLastTelesupCollectorId: (int) aTelesupId;
- (long) getTelLastTelesupCashRegisterId: (int) aTelesupId;
- (char*) getTelExtension: (int) aTelesupId;
- (char*) getTelAcronym: (int) aTelesupId;
- (int) getTelFromHour: (int) aTelesupId;
- (int) getTelToHour: (int) aTelesupId;
- (BOOL) getTelScheduled: (int) aTelesupId;
- (BOOL) getSendAudits:(int) aTelesupId;
- (BOOL) getSendTraffic:(int) aTelesupId;
- (datetime_t) getTelNextSecondaryDate: (int) aTelesupId;
- (int) getTelFrame: (int) aTelesupId;
- (int) getTelCabinIdleWaitTime: (int) aTelesupId;
- (long) getTelLastTariffTableHistoryId: (int) aTelesupId;
- (unsigned long) getTelLastTelesupDepositNumber: (int) aTelesupId;
- (unsigned long) getTelLastTelesupExtractionNumber: (int) aTelesupId;
- (unsigned long) getTelLastTelesupAlarmId: (int) aTelesupId;
- (BOOL) getTelInformDepositsByTransaction: (int) aTelesupId;
- (BOOL) getTelInformExtractionsByTransaction: (int) aTelesupId;
- (BOOL) getTelInformAlarmsByTransaction: (int) aTelesupId;
- (unsigned long) getTelLastTelesupZCloseNumber: (int) aTelesupId;
- (unsigned long) getTelLastTelesupXCloseNumber: (int) aTelesupId;
- (BOOL) getTelInformZCloseByTransaction: (int) aTelesupId;

/**
 * Aplica los cambios en la persistencia realizados a la telesupervision pasada como parametro
 */

- (void) telesupApplyChanges: (int) aTelesupId;

/** 
 *
 */
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
				informZCloseByTransaction: (BOOL) anInformZCloseByTransaction;

/**
 *
 */
- (void) removeTelesup: (int) aTelesupId;
  
/**
 * Restaura los valores de la configuracion de la telesupervision
 */

- (void) restoreTelesup: (int) aTelesupId;

/**
 * Devuelve una coleccion con las telesupervisiones
 */

- (COLLECTION) getTelesups;

/**
 * Devuelve las conexiones de la telesupervision
 */

- (COLLECTION) getTelConnections: (int) aTelesupId;

/**
 *
 */

- (TELESUP_SETTINGS) getTelesup: (int) aTelesupId;
- (TELESUP_SETTINGS) getTelesupByTelcoType: (TelcoType) aTelcoType;

/**
 *
 */

- (void) addTelesupToCollection: (TELESUP_SETTINGS) aTelesup;

/**/
- (int) getTelesupIdByRemoteSystemId: (char *) aSystemId;

/*******************************************************************************************
*																			CONNECTIONS
*
*******************************************************************************************/

/**
* SET
*/

/**
 * Setea los valores correspondientes a las conexiones
 */

- (void) setConDescription: (int) aConnectionId value: (char*) aValue;
- (void) setConModemPhoneNumber: (int) aConnectionId value: (char*) aValue;
- (void) setConDomain: (int) aConnectionId value: (char*) aValue;
- (void) setConIP: (int) aConnectionId value: (char*) aValue;
- (void) setConISPPhoneNumber: (int) aConnectionId value: (char*) aValue;
- (void) setConUserName: (int) aConnectionId value: (char*) aValue;
- (void) setConPassword: (int) aConnectionId value: (char*) aValue;
- (void) setConType: (int) aConnectionId value: (int) aValue;
- (void) setConPortType: (int) aConnectionId value: (int) aValue;
- (void) setConPortId: (int) aConnectionId value: (int) aValue;
- (void) setConRingsQty: (int) aConnectionId value: (int) aValue;
- (void) setConTCPPortSource: (int) aConnectionId value: (int) aValue;
- (void) setConTCPPortDestination: (int) aConnectionId value: (int) aValue;
- (void) setConPPPConnectionId: (int) aConnectionId value: (int) aValue;
- (void) setConSpeed: (int) aConnectionId value: (int) aValue;
- (void) setConAttemptsQty: (int) aConnectionId value: (int) aValue;
- (void) setConTimeBetweenAttempts: (int) aConnectionId value: (int) aValue;
- (void) setConConnectBy: (int) aConnectionId value: (int) aValue;
- (void) setConDomainSup: (int) aConnectionId value: (char*) aValue;

/**
* GET
*/

/**
 * Devuelve los valores correspondientes a las conexiones 
 */

- (char*) getConDescription: (int) aConnectionId;
- (char*) getConModemPhoneNumber: (int) aConnectionId;
- (char*) getConDomain: (int) aConnectionId;
- (char*) getConIP: (int) aConnectionId;
- (char*) getConISPPhoneNumber: (int) aConnectionId;
- (char*) getConUserName: (int) aConnectionId;
- (char*) getConPassword: (int) aConnectionId;
- (int) getConType: (int) aConnectionId;
- (int) getConPortType: (int) aConnectionId;
- (int) getConPortId: (int) aConnectionId;
- (int) getConRingsQty: (int) aConnectionId;
- (int) getConTCPPortSource: (int) aConnectionId;
- (int) getConTCPPortDestination: (int) aConnectionId;
- (int) getConPPPConnectionId: (int) aConnectionId;
- (int) getConAttemptsQty: (int) aConnectionId;
- (int) getConTimeBetweenAttempts: (int) aConnectionId;
- (int) getConSpeed: (int) aConnectionId;
- (int) getConConnectBy: (int) aConnectionId;
- (char*) getConDomainSup: (int) aConnectionId;

/**
 *
 */

- (void) applyConnectionChanges: (int) aConnectionId;

/**
 *
 */

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
											 domainSup: (char*) aDomainSup;

/**
 *
 */

- (void) removeConnection: (int) aConnectionId;

/**
 *
 */

- (void) restoreConnection: (int) aConnectionId;

/**
 *
 */

- (CONNECTION_SETTINGS) getConnection: (int) aConnectionId;

/**
 *
 */
- (CONNECTION_SETTINGS) getConnectionByDescription: (char *) aValue;

/**
 *
 */
- (int) getLastConnectionId;

/**
 *
 */

- (void) addConnectionToCollection: (CONNECTION_SETTINGS) aConnection;

/**
 *
 */
- (COLLECTION) getConnections;   

/**/
- (void) initGprsFiles;

/**/
- (void) updateGprsConnections: (CONNECTION_SETTINGS) aConnectionSettings;

/**
 * 	Configura los archivos de conexion y telesupervision.
 *
 */
- (BOOL) writeTelesupsToFile;

/**
 *  Levanta a la tabla de telesups los archivos lastTelesup.ftp y lastTelesupOk.ftp
 */
- (void) loadLastTelesupFiles;

- (char *) getMainTelesupSystemId;

/**/
- (void) loadDNSSettings;
- (void) setDNSSettingToFile: (char*) aDNS1 DNS2: (char*) aDNS2;
- (char*) getDNS1;
- (char*) getDNS2;

@end

#endif

