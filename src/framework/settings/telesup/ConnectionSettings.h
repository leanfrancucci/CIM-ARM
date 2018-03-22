#ifndef CONNECTION_SETTINGS_H
#define CONNECTION_SETTINGS_H

#define CONNECTION_SETTINGS id

#include "Object.h"
#include "ctapp.h"

/**
 *	Tipo de conexion.
 */
typedef enum {
	 ConnectionType_PPP = 1
	,ConnectionType_LAN
	,ConnectionType_MODEM
	,ConnectionType_GPRS
	,ConnectionType_FTP
} ConnectionType;

/**
*  Define los tipos de puertos
*/

typedef enum {
	PORT_TYPE_NOT_DEFINED,
	RS232,
	USB,
	PARALLEL_CONNECTION
} ConnectionPortType;

typedef enum {
	ConnectionByType_IP,
	ConnectionByType_DOMAIN
} ConnectionByType;



/**
 * Clase  
 */

@interface ConnectionSettings:  Object
{
	int myConnectionId;
	char myDescription[30];
	ConnectionType myType;
	ConnectionPortType myPortType;
	int myPortId;
	char myModemPhoneNumber[32];
	int myRingsQty;
	char myDomain[60];
	char myIP[16];
	int myTcpPortSource;
	int myTcpPortDestination;
	int myPPPConnectionId;
	char myISPPhoneNumber[32];
	char myUserName[30+1];
	char myPassword[30+1];
  int myAttemptsQty;
  int myTimeBetweenAttempts;
	int myConnectionSpeed;
	TelcoType	myTelcoType;
	BOOL myDeleted;
	char myDomainSup[60];
	ConnectionByType myConnectBy;
}

/**
 *
 */
+ new;
- initialize;

/**
 * Setea los valores correspondientes a la configuracion general de las conexiones
 */
- (void) setConnectionId: (int) aValue;
- (void) setConnectionDescription: (char*) aValue;
- (void) setModemPhoneNumber: (char*) aValue;
- (void) setDomain: (char*) aValue;
- (void) setConnectionIP: (char*) aValue;
- (void) setISPPhoneNumber: (char*) aValue;
- (void) setConnectionUserName: (char*) aValue;
- (void) setConnectionPassword: (char*) aValue;
- (void) setConnectionType: (ConnectionType) aValue;
- (void) setPortType: (ConnectionPortType) aValue;
- (void) setPortId: (int) aValue;
- (void) setRingsQty: (int) aValue;
- (void) setTCPPortSource: (int) aValue;
- (void) setTCPPortDestination: (int) aValue;
- (void) setPPPConnectionId: (int) aValue;
- (void) setConnectionAttemptsQty: (int) aValue;
- (void) setConnectionTimeBetweenAttempts: (int) aValue;
- (void) setConnectionSpeed: (int) aValue;
- (void) setDeleted: (BOOL) aValue;
- (void) setTelcoType: (TelcoType) aTelcoType;
- (void) setDomainSup: (char*) aValue;
- (void) setConnectBy: (ConnectionByType) aValue;

/**
 * Devuelve los valores correspondientes a la configuracion general de las conexiones
 */

- (int) getConnectionId;
- (char*) getConnectionDescription;
- (char*) getModemPhoneNumber;
- (char*) getDomain;
- (char*) getIP;
- (char*) getISPPhoneNumber;
- (char*) getConnectionUserName;
- (char*) getConnectionPassword;
- (ConnectionType) getConnectionType;
- (ConnectionPortType) getConnectionPortType;
- (int) getConnectionPortId;
- (int) getRingsQty;
- (int) getTCPPortSource;
- (int) getConnectionTCPPortDestination;
- (int) getPPPConnectionId;
- (int) getConnectionAttemptsQty;
- (int) getConnectionTimeBetweenAttempts;
- (int) getConnectionSpeed;
- (BOOL) isDeleted;
- (TelcoType) getTelcoType;
- (char*) getDomainSup;
- (ConnectionByType) getConnectBy;


/**
 * Aplica los cambios realizados a la configuracion general de la conexion
 */	

- (void) applyChanges;

/**
 * Restaura los valores de la configuracion de la conexion
 */

- (void) restore;


@end

#endif

