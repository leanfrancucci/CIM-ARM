#ifndef POS_ACCEPTOR_H
#define POS_ACCEPTOR_H

#define POS_ACCEPTOR id

#include <Object.h>
#include "ctapp.h"
#include "system/net/all.h"
#include "system/os/all.h"
#include "TelesupDefs.h"
#include "TelesupSettings.h"
#include "parser.h"
#include "TelesupViewer.h"
#include "CimManager.h"
#include "POSEventAcceptor.h"

/**
 *	Espera una conexion entrante y larga una supervision una vez que se conecta.
 *	
 */
@interface POSAcceptor : OThread
{
	SSL_SERVER_SOCKET ssocket;
	SSL_CLIENT_SOCKET csocket;
	int port;
	OTIMER myTimer;
	BOOL telesupRunning;
	TELESUP_VIEWER myTelesupViewer;
	TELESUP_SETTINGS myTelesup;
	READER myReader;
	WRITER myWriter;
	char* myMessage;
	char* myCurrentMsg;
	char* myAuxMessage;
	DEPOSIT myDrop;
	DEPOSIT myExtendedDrop;
	BOOL mySendError;
	BOOL myConnectionStarted;
	POS_EVENT_ACCEPTOR POSEvAcceptor;
	scew_parser* myParser;
	scew_tree* myTree;
}

+ getInstance;

/**
 *	Configura el puerto pasado por parametro.
 */
- (void) setPort: (int) aPort;

/**/
- (void) timerExpired;
- (BOOL) isTelesupRunning;

/**/
- (void) setTelesupViewer: (TELESUP_VIEWER) aTelesupViewer;

/**/
- (void) resetDrop;

/**/
- (void) resetTimer;

@end

#endif
