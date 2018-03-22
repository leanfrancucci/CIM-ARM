#include "ConnectionSettings.h"
#include "Persistence.h"
#include "ConnectionSettingsDAO.h"
#include "util.h"
#include <objpak.h>

@implementation ConnectionSettings
/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myConnectionId = 0;
	myDeleted = FALSE;
	myTimeBetweenAttempts = 10;
	myAttemptsQty = 3;
	myType = ConnectionType_LAN;
	myPortId = 4;
	myRingsQty = 6;
	myTcpPortSource = 0;
	myTcpPortDestination = 0;
	myConnectionSpeed = 115200;
	myTelcoType = 0;
	myConnectBy = ConnectionByType_IP;

	strcpy(myModemPhoneNumber, "");
	strcpy(myDomain, "");
	strcpy(myIP, "");
	strcpy(myISPPhoneNumber, "");
	strcpy(myUserName, "");
	strcpy(myPassword, "");
	strcpy(myDomainSup, "");
	
	return self;
}


- (void) setConnectionId: (int) aValue { myConnectionId = aValue; }

- (void) setConnectionDescription: (char*) aValue
{
	strncpy2(myDescription , aValue, sizeof(myDescription) - 1);
}

- (void) setModemPhoneNumber: (char*) aValue
{
	strncpy2(myModemPhoneNumber , aValue, sizeof(myModemPhoneNumber) - 1);
} 
- (void) setDomain: (char*) aValue { strncpy2(myDomain , aValue, sizeof(myDomain) -1);} 
- (void) setConnectionIP: (char*) aValue { strncpy2(myIP , aValue, sizeof(myIP)-1); } 

- (void) setISPPhoneNumber: (char*) aValue
{
	strncpy2(myISPPhoneNumber , aValue, sizeof(myISPPhoneNumber)-1);
}

- (void) setConnectionUserName: (char*) aValue { stringcpy(myUserName , aValue);} 
- (void) setConnectionPassword: (char*) aValue { stringcpy(myPassword , aValue);} 
- (void) setConnectionType: (ConnectionType) aValue { myType = aValue; }
- (void) setPortType: (ConnectionPortType) aValue { myPortType = aValue; }
- (void) setPortId: (int) aValue { myPortId = aValue; }
- (void) setRingsQty: (int) aValue { myRingsQty = aValue; }
- (void) setTCPPortSource: (int) aValue { myTcpPortSource = aValue; }
- (void) setTCPPortDestination: (int) aValue { myTcpPortDestination = aValue; }
- (void) setPPPConnectionId: (int) aValue { myPPPConnectionId = aValue; }
- (void) setConnectionAttemptsQty: (int) aValue { myAttemptsQty = aValue; }
- (void) setConnectionTimeBetweenAttempts: (int) aValue { myTimeBetweenAttempts = aValue; }
- (void) setConnectionSpeed: (int) aValue { myConnectionSpeed = aValue; }
- (void) setDeleted: (BOOL) aValue { myDeleted = aValue; }
- (void) setTelcoType: (TelcoType) aTelcoType { myTelcoType = aTelcoType; }
- (void) setDomainSup: (char*) aValue { stringcpy(myDomainSup, aValue); }
- (void) setConnectBy: (ConnectionByType) aValue { myConnectBy = aValue; 

	if (myConnectBy == ConnectionByType_IP) {
		strcpy(myDomainSup, "");
	}

	if (myConnectBy == ConnectionByType_DOMAIN) {
		strcpy(myIP, "");
	}
}

/**/
- (int) getConnectionId { return myConnectionId; } 
- (char*) getConnectionDescription { return myDescription; }
- (char*) getModemPhoneNumber { return myModemPhoneNumber; }
- (char*) getDomain { return myDomain; }
- (char*) getIP { return myIP; }
- (char*) getISPPhoneNumber { return myISPPhoneNumber; }
- (char*) getConnectionUserName { return myUserName; }
- (char*) getConnectionPassword { return myPassword; }
- (ConnectionType) getConnectionType { return myType; }
- (ConnectionPortType) getConnectionPortType { return myPortType; }
- (int) getConnectionPortId { return myPortId; }
- (int) getRingsQty { return myRingsQty; }
- (int) getTCPPortSource { return myTcpPortSource; }
- (int) getConnectionTCPPortDestination { return myTcpPortDestination; }
- (int) getPPPConnectionId { return myPPPConnectionId; }
- (int) getConnectionAttemptsQty { return myAttemptsQty; }
- (int) getConnectionTimeBetweenAttempts { return myTimeBetweenAttempts; }
- (int) getConnectionSpeed { return myConnectionSpeed; };
- (BOOL) isDeleted { return myDeleted; }
- (TelcoType) getTelcoType { return myTelcoType; }
- (char*) getDomainSup { return myDomainSup; }
- (ConnectionByType) getConnectBy { return myConnectBy; }

/**/
- (void) applyChanges
{
	id connectionDAO;
	connectionDAO = [[Persistence getInstance] getConnectionSettingsDAO];		

	[connectionDAO store: self];
}


/**/
- (void) restore
{
	CONNECTION_SETTINGS obj;

	//Recupera el objeto de la persistencia
	obj =	[[[Persistence getInstance] getConnectionSettingsDAO] loadById: [self getConnectionId]];		

	//Setea los valores a la instancia en memoria
	[self setConnectionDescription: [obj getConnectionDescription]];
	[self setModemPhoneNumber: [obj getModemPhoneNumber]];
	[self setDomain: [obj getDomain]];
	[self setConnectionIP: [obj getIP]];
	[self setISPPhoneNumber: [obj getISPPhoneNumber]];
	[self setConnectionUserName: [obj getConnectionUserName]];
	[self setConnectionPassword: [obj getConnectionPassword]];
	[self setConnectionType: [obj getConnectionType]];
	[self setPortType: [obj getConnectionPortType]];
	[self setPortId: [obj getConnectionPortId]];
	[self setRingsQty: [obj getRingsQty]];
	[self setTCPPortSource: [obj getTCPPortSource]];
	[self setTCPPortDestination: [obj getConnectionTCPPortDestination]];
	[self setPPPConnectionId: [obj getPPPConnectionId]];
  [self setConnectionAttemptsQty: [obj getConnectionAttemptsQty]];
  [self setConnectionTimeBetweenAttempts: [obj getConnectionTimeBetweenAttempts]];
	[self setConnectionSpeed: [obj getConnectionSpeed]];
	[self setDeleted: [obj isDeleted]];
	[self setDomainSup: [obj getDomainSup]];
  [self setConnectBy: [obj getConnectBy]];


	[obj free];	
}

/**/
- (STR) str
{
  return myDescription;
}

@end	
