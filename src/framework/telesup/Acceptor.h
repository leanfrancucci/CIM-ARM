#ifndef ACCEPTOR_H
#define ACCEPTOR_H

#define ACCEPTOR id

#include <Object.h>
#include "ctapp.h"
#include "system/net/all.h"
#include "system/os/all.h"
#include "TelesupDefs.h"

/**
 *	Espera una conexion entrante y larga una supervision una vez que se conecta.
 *	
 */
@interface Acceptor : OThread
{
	SERVER_SOCKET ssocket;
	int port;

	BOOL myAcceptIncomingSupervision;
	OTIMER myTimer;

	BOOL telesupRunning;

	id myFormObserver;
	id myRemoteCurrentUser;
	
	int myCantLoginFails; 
	CommunicationIntention myCommunicationIntention;

	BOOL myShutdownApp;
}

+ getInstance;

/**
 *	Configura el puerto pasado por parametro.
 */
- (void) setPort: (int) aPort;

/**/
- (void) acceptIncomingSupervision: (BOOL) aValue;
- (void) timerExpired;
- (BOOL) isTelesupRunning;

/**/
- (void) setFormObserver: (id) aForm;

/**/
- (void) setRemoteCurrentUser: (id) aUser;
- (id) getRemoteCurrentUser;

/**/
- (void) incCantLoginFails;
- (void) initCantLoginFails;
- (int) getCantLoginFails;

/**/
- (void) setCommunicationIntention: (CommunicationIntention) aCommunicationIntention;
- (CommunicationIntention) getCommunicationIntention;

/**/
- (void) setShutdownApp: (BOOL) aValue;
- (BOOL) getShutdownApp;
- (void) shutdownApp;

@end

#endif
