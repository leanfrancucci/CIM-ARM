#ifndef POS_EVENT_ACCEPTOR_H
#define POS_EVENT_ACCEPTOR_H

#define POS_EVENT_ACCEPTOR id

#include <Object.h>
#include "ctapp.h"
#include "system/net/all.h"
#include "system/os/all.h"
#include "TelesupDefs.h"
#include "TelesupSettings.h"
#include "parser.h"
#include "TelesupViewer.h"
#include "CimManager.h"

typedef struct {
	char *text;
} XMLEvent;

/**
 *	Espera una conexion entrante y larga una supervision una vez que se conecta.
 *	
 */
@interface POSEventAcceptor : OThread
{
	SSL_SERVER_SOCKET ssocketEvents;
	SSL_CLIENT_SOCKET csocketEvents;
	int port;
	BOOL telesupRunning;
	TELESUP_SETTINGS myTelesup;
	WRITER myEventWriter;
	char* myCurrentMsg;
	char* myAuxMessage;
	SYNC_QUEUE mySyncQueue;
}

+ getInstance;

/**
 *	Configura el puerto pasado por parametro.
 */
- (void) setPort: (int) aPort;

/**/
- (BOOL) isTelesupRunning;

/**
 *****************
 **** EVENTOS ****
 *****************/

/**/
- (void) billAcceptedEvent: (int) anAcceptorId amount: (money_t) anAmount currencyId: (int) aCurrencyId;

/**/
- (void) billRejectedEvent: (int) anAcceptorId;

/**/
- (void) doorOpenEvent: (int) aDoorId doorName: (char *) aDoorName;

/**/
- (void) doorCloseEvent: (int) aDoorId doorName: (char *) aDoorName;

/**/
- (void) doorViolationEvent: (int) aDoorId doorName: (char *) aDoorName;

/**/
- (void) cassetteFullEvent: (int) anAcceptorId acceptorName: (char *) anAcceptorName;

/**/
- (void) cassetteAlmostFullEvent: (int) anAcceptorId acceptorName: (char *) anAcceptorName;

/**/
- (void) cassetteRemovedEvent: (int) anAcceptorId acceptorName: (char *) anAcceptorName;

/**/
- (void) cassetteInstalledEvent: (int) anAcceptorId acceptorName: (char *) anAcceptorName;

/**/
- (void) validatorStatusEvent: (int) anAcceptorId acceptorName: (char *) anAcceptorName statusName: (char *) aStatusName;

@end

#endif
