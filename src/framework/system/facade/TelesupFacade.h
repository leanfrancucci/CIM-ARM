#ifndef TELESUP_FACADE_H
#define TELESUP_FACADE_H

#include <Object.h>
#include "ctapp.h"
#include "system/util/all.h"

#define TELESUP_FACADE id

/**
 *	<<singleton>>
 */

@interface TelesupFacade : Object
{
}

+ new;
+ getInstance;
- initialize;


/*******************************************************************************************
*																			TELESUP SETTINGS
*
*******************************************************************************************/

/**
* SET
*/

/*
 * UserName
 * Password
 * RemoteUserName
 * RemotePassword
 * SystemId 
 * Acronym
 * Extension
 */

- (void) setTelesupParamAsString: (char*) aParam value: (char *) aValue telesupRol: (int) aTelesupRol;

/*
 * TelcoType
 * Frequency
 * StartMoment
 * AttemptsQty
 * TimeBetweenAttempts
 * MaxTimeWithoutTelAllowed
 * ConnectionId1
 * ConnectionId2
 * Frame
 * CabinIdleWaitTime  
 */

- (void) setTelesupParamAsInteger: (char*) aParam value: (int) aValue telesupRol: (int) aTelesupRol;

/*
 * NextTelesupDateTime
 * LastSuceedTelesupDateTime
 * NextSecondaryTelesupDateTime 
 */

- (void) setTelesupParamAsDateTime: (char*) aParam value: (datetime_t) aValue telesupRol: (int) aTelesupRol;


 /**
  * LastTelesupCallId
  * LastTelesupTicketId
  * LastTelesupAuditId
  * LastTelesupMesageId
  * LastTelesupDepositNumber
  * LastTelesupExtractionNumber
	* LastTelesupAlarmId
	* LastTelesupZCloseNumber
	* LastTelesupXCloseNumber  	
  */
- (void) setTelesupParamAsLong: (char*) aParam value: (long) aValue telesupRol: (int) aTelesupRol;

 /**
  * InformDepositsByTransaction
  * InformExtractionsByTransaction
  * InformAlarmsByTransaction
  */
- (void) setTelesupParamAsBoolean: (char*) aParam value: (BOOL) aValue telesupRol: (int) aTelesupRol;

/**
* GET
*/

/*
 * UserName
 * Password
 * RemoteUserName
 * RemotePassword
 * SystemId
 */

- (char*) getTelesupParamAsString: (char*) aParam telesupRol: (int) aTelesupRol;

/*
 * TelcoType
 * Frequency
 * StartMoment
 * AttemptsQty
 * TimeBetweenAttempts
 * MaxTimeWithoutTelAllowed
 * ConnectionId1
 * ConnectionId2
 * Frame
 * CabinIdleWaitTime  
 */

- (int) getTelesupParamAsInteger: (char*) aParam telesupRol: (int) aTelesupRol;

/*
 * NextTelesupDateTime
 * LastSuceedTelesupDateTime
 * NextSecondaryTelesupDateTime 
 */

- (datetime_t) getTelesupParamAsDateTime: (char*) aParam telesupRol: (int) aTelesupRol;

 /**
  * LastTelesupCallId
  * LastTelesupTicketId
  * LastTelesupAuditId
  * LastTelesupMesageId
  * LastTelesupDepositNumber
  * LastTelesupExtractionNumber
	* LastTelesupAlarmId
	* LastTelesupZCloseNumber
	* LastTelesupXCloseNumber  	
  */
- (long) getTelesupParamAsLong: (char*) aParam telesupRol: (int) aTelesupRol;

/**
  * InformDepositsByTransaction
	* InformExtractionsByTransaction
	* InformAlarmsByTransaction
*/
- (BOOL) getTelesupParamAsBoolean: (char*) aParam telesupRol: (int) aTelesupRol;

/*
 * Aplica los cambios correspondientes a la configuracion general de la telesupervision
 */
 
- (void) telesupApplyChanges: (int) aTelesupID;

/*
 * Agrega una telesupervision
 */

//- (void) activateTelesup: (int) aTelesupRol;

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
				informAlarmsByTransaction: (BOOL) anInformAlarmsByTransaction;


/*
 * Remueve una telesupervision
 */

//- (void) deactivateTelesup: (int) aTelesupRol;
- (void) removeTelesup: (int) aTelesupId;

/**
 *	Devuelve la lista telesupervisiones
 *	El resultado es una coleccion de objetos de tipo BigInt correspondientes al
 *	rol de cada supervision
 *	Es responsabilidad del cliente de este metodo liberar la coleccion y el contenido.
 */
- (COLLECTION) getTelesupRolList;


/**	
 *	Devuelve el id de supervision (ex Rol) a partir del Id de sistema remoto.
 */
- (int) getTelesupIdByRemoteSystemId: (char *) aSystemId;

/*******************************************************************************************
*																			CONNECTIONS
*
*******************************************************************************************/

/**
* SET
*/

	/*
 * Description
 * ModemPhoneNumber
 * Domain
 * IP
 * ISPPhoneNumber
 * UserName
 * Password
 */

- (void) setConnectionParamAsString: (char*) aParam value: (char *) aValue connectionId: (int) aConnectionId; 

/*
 * Type
 * PortType
 * PortId
 * RingsQty
 * TCPPortSource
 * TCPPortDestination
 * PPPConnectionId
 */

- (void) setConnectionParamAsInteger: (char*) aParam value: (int) aValue connectionId: (int) aConnectionId;


/**
* GET
*/

/**
 * Description
 * ModemPhoneNumber
 * Domain
 * IP
 * ISPPhoneNumber
 * UserName
 * Password
 */

- (char *) getConnectionParamAsString: (char*) aParam connectionId: (int) aConnectionId;

/*
 * Type
 * PortType
 * PortId
 * RingsQty
 * TCPPortSource
 * TCPPortDestination
 * PPPConnectionId
 */

- (int) getConnectionParamAsInteger: (char*) aParam connectionId: (int) aConnectionId;

/*
 * Aplica los cambios realizados sobre la conexion
 */
 
- (void) connectionApplyChanges: (int) aConnectionId;

/*
 * Agrega una conexion
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
                       
/*
 * Elimina una conexion
 */

- (void) removeConnection: (int) aConnectionId; 

/**
 *	Devuelve la lista conexiones
 *	El resultado es una coleccion de objetos de tipo BigInt correspondientes al
 *	al identificador de cada conexion.
 *	Es responsabilidad del cliente de este metodo liberar la coleccion y el contenido.
 */
- (COLLECTION) getConnectionIdList;

@end

#endif
