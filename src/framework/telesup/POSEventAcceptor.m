#include "POSEventAcceptor.h"
#include "POSAcceptor.h"
#include "LCDTelesupViewer.h"
#include "TelesupervisionManager.h"
#include "system/net/all.h"
#include "Configuration.h"
#include "ResourceStringDefs.h"
#include "MessageHandler.h"
#include "Audit.h"
#include "UserManager.h"
#include "ExtractionManager.h"
#include "CashReferenceManager.h"
#include "CimGeneralSettings.h"
#include "InstaDropManager.h"
#include "Persistence.h"
#include "DepositManager.h"
#include "AmountSettings.h"
#include "ZCloseManager.h"
#include "RegionalSettings.h"
#include "ReportXMLConstructor.h"
#include "PrinterSpooler.h"
#include "DepositDetailReport.h"
#include "CurrencyManager.h"

#define XML_MESSAGE_HEADER							"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\012\012"
#define XML_MESSAGE_TAG									"message"
#define XML_MESSAGE_NAME								"messageName"

#define XML_MESSAGE_EVENT_BILLSTACKED		"billStacked"
#define XML_MESSAGE_EVENT_BILLREJECTED	"billRejected"
#define XML_MESSAGE_EVENT_INFORMEVENT		"informEvent"

static void convertTime(datetime_t *dt, struct tm *bt)
{
	localtime_r(dt, bt);
}

static char *formatBrokenDateTime(char *dest, struct tm *brokenTime)
{
	strftime(dest, 50, [[RegionalSettings getInstance] getDateTimeFormatString], brokenTime);
	return dest;
}

@implementation POSEventAcceptor

static POS_ACCEPTOR singleInstance = NULL;

- (TELESUP_SETTINGS) getDefaultTelesup;

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [[super new] initialize];
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
	mySyncQueue = [SyncQueue new];
	port = 5556;
	ssocketEvents = [SSLServerSocket new];
	telesupRunning = FALSE;
	myEventWriter = NULL;
	myCurrentMsg = malloc(TELESUP_MSG_SIZE + 1);
	myAuxMessage = malloc(TELESUP_MSG_SIZE + 1);

	return self;
}

/**/
- (void) setPort: (int) aPort
{
	port = aPort;
}

/**/
- (TELESUP_SETTINGS) getDefaultTelesup
{
	COLLECTION telesups;
	int i;

	telesups = [[TelesupervisionManager getInstance] getTelesups];

	for (i = 0; i < [telesups size]; ++i) {
		if ([[telesups at: i] getTelcoType] == POS_TSUP_ID) return [telesups at:i];
	}

	return NULL;
}

/**/
- (void) run
{
	XMLEvent *event = NULL;
	char eventMessage[5000];

	// Lo vinculo con la direccion IP local y el puerto
	myTelesup = [self getDefaultTelesup];
	port = [[myTelesup getConnection1] getConnectionTCPPortDestination];
	[ssocketEvents bind: "127.0.0.1" port: port+1];

	while (TRUE) {

		TRY

			//doLog(0,"Esperando conexion entrante del POS (eventos) al puerto %d\n", port+1);
			csocketEvents = [ssocketEvents accept];
			if (csocketEvents == NULL) THROW(SOCKET_EX);
		//	doLog(0,"Conexion entrante al puerto %d\n", port+1);

			myEventWriter = [csocketEvents getWriter];

		//	doLog(0,"Comenzando supervision POS de Eventos...\n");

			telesupRunning = TRUE;

			eventMessage[0] = '\0';
			while ([[POSAcceptor getInstance] isTelesupRunning]) {
				// levanto el evento
				if ([mySyncQueue getCount] > 0) {
					event = [mySyncQueue popElement];
					stringcpy(eventMessage, event->text);
	
					// envio el evento
					[self sendEventMessage: &eventMessage];
	
					free(event->text);
					free(event);
				}

				msleep(1000);
			}

			[self closeConnection];

		CATCH

			ex_printfmt();
		///	doLog(0,"Ha ocurrido una excepcion grave en el hilo de la supervision POS de Eventos\n");
		//	doLog(0,"Se reiniciara la supervision POS de Eventos\n");

			[self closeConnection];
		
		END_TRY
	}

}

/**/
- (void) closeConnection
{
	telesupRunning = FALSE;

	// limpio la lista de eventos por si quedo alguno
	while ([mySyncQueue getCount] > 0)
		[mySyncQueue removeAt: 0];

	if (csocketEvents) {
	//	doLog(0,"cerrando csocketEvents ... "); fflush(stdout);
		[csocketEvents close];
		csocketEvents = NULL;
		msleep(10000);
	//	doLog(0,"[OK]\n");
	}
}

/**/
- (BOOL) isTelesupRunning
{
	return telesupRunning;
}


//********************* EVENTOS ******************************

/**/
- (void) sendEventMessage: (char *) anEventMessage
{
	int size;

	// reseteo el timer
	if ([[POSAcceptor getInstance] isTelesupRunning])
		[[POSAcceptor getInstance] resetTimer];

	size = strlen(anEventMessage);
	if (size > TELESUP_MSG_SIZE) THROW( TSUP_MSG_TOO_LARGE_EX );

	//doLog(0,"Sending event msg...\n");
	[myEventWriter write: anEventMessage qty: size];
	/*doLog(0,"POSAcceptor:Event Message Sended (%d) --------------------------\n"
			"%s\n "
			"---------------------------------------------------------------\n", strlen(anEventMessage), anEventMessage); fflush(stdout);*/
}

/**/
- (void) billAcceptedEvent: (int) anAcceptorId amount: (money_t) anAmount currencyId: (int) aCurrencyId
{
	XMLEvent *event;
	char buf[50];
	char line[200];
	CURRENCY currency;
	char eventMessage[5000];
	int totalDecimals = [[AmountSettings getInstance] getTotalRoundDecimalQty];

	// armo el mensaje de respuesta del evento ************
	eventMessage[0] = '\0';

	strcpy(eventMessage,XML_MESSAGE_HEADER);

	sprintf(line,"<%s>\012", XML_MESSAGE_TAG);
	strcat(eventMessage,line);
	sprintf(line,"   <%s>%s</%s>\012", XML_MESSAGE_NAME, XML_MESSAGE_EVENT_BILLSTACKED, XML_MESSAGE_NAME);
	strcat(eventMessage,line);
	// id del validador
	sprintf(line,"   <acceptorId>%d</acceptorId>\012", anAcceptorId);
	strcat(eventMessage,line);

	// codigo de la moneda
	currency = [[CurrencyManager getInstance] getCurrencyById: aCurrencyId];
	if (currency)
		sprintf(line,"   <currencyCode>%s</currencyCode>\012", [currency getCurrencyCode]);
	else sprintf(line,"   <currencyCode>?</currencyCode>\012");
	strcat(eventMessage,line);

	// denominacion
	formatMoney(buf, "", anAmount, totalDecimals, 20);
	sprintf(line,"   <denomination>%s</denomination>\012", buf);
	strcat(eventMessage,line);
	sprintf(line,"</%s>\012", XML_MESSAGE_TAG);
	strcat(eventMessage,line);

	// agrego el evento a la lista
	event = malloc(sizeof(XMLEvent));
	event->text = strdup(eventMessage);
	[mySyncQueue pushElement: event];

}

/**/
- (void) billRejectedEvent: (int) anAcceptorId
{
	XMLEvent *event;
	char line[200];
	char eventMessage[5000];

	// armo el mensaje de respuesta del evento ************
	eventMessage[0] = '\0';

	strcpy(eventMessage,XML_MESSAGE_HEADER);

	sprintf(line,"<%s>\012", XML_MESSAGE_TAG);
	strcat(eventMessage,line);
	sprintf(line,"   <%s>%s</%s>\012", XML_MESSAGE_NAME, XML_MESSAGE_EVENT_BILLREJECTED, XML_MESSAGE_NAME);
	strcat(eventMessage,line);
	// id del validador
	sprintf(line,"   <acceptorId>%d</acceptorId>\012", anAcceptorId);
	strcat(eventMessage,line);
	sprintf(line,"</%s>\012", XML_MESSAGE_TAG);
	strcat(eventMessage,line);

	// agrego el evento a la lista
	event = malloc(sizeof(XMLEvent));
	event->text = strdup(eventMessage);
	[mySyncQueue pushElement: event];

}

/**/
- (void) doorOpenEvent: (int) aDoorId doorName: (char *) aDoorName
{
	[self doorEvent: aDoorId doorName: aDoorName event: "doorOpen"];
}

/**/
- (void) doorCloseEvent: (int) aDoorId doorName: (char *) aDoorName
{
	[self doorEvent: aDoorId doorName: aDoorName event: "doorClose"];
}

/**/
- (void) doorViolationEvent: (int) aDoorId doorName: (char *) aDoorName
{
	[self doorEvent: aDoorId doorName: aDoorName event: "doorViolation"];
}

/**/
- (void) doorEvent: (int) aDoorId doorName: (char *) aDoorName event: (char *) anEvent
{
	XMLEvent *event;
	char line[200];
	char eventMessage[5000];

	// armo el mensaje de respuesta del evento ************
	eventMessage[0] = '\0';

	strcpy(eventMessage,XML_MESSAGE_HEADER);

	sprintf(line,"<%s>\012", XML_MESSAGE_TAG);
	strcat(eventMessage,line);
	sprintf(line,"   <%s>%s</%s>\012", XML_MESSAGE_NAME, XML_MESSAGE_EVENT_INFORMEVENT, XML_MESSAGE_NAME);
	strcat(eventMessage,line);
	// evento
	sprintf(line,"   <event>%s</event>\012", anEvent);
	strcat(eventMessage,line);
	// id de la puerta
	sprintf(line,"   <doorId>%d</doorId>\012", aDoorId);
	strcat(eventMessage,line);
	// nombre de la puerta
	sprintf(line,"   <doorName>%s</doorName>\012", aDoorName);
	strcat(eventMessage,line);
	sprintf(line,"</%s>\012", XML_MESSAGE_TAG);
	strcat(eventMessage,line);

	// agrego el evento a la lista
	event = malloc(sizeof(XMLEvent));
	event->text = strdup(eventMessage);
	[mySyncQueue pushElement: event];

}

/**/
- (void) cassetteFullEvent: (int) anAcceptorId acceptorName: (char *) anAcceptorName
{
	[self cassetteEvent: anAcceptorId acceptorName: anAcceptorName event: "cassetteFull"];
}

/**/
- (void) cassetteAlmostFullEvent: (int) anAcceptorId acceptorName: (char *) anAcceptorName
{
	[self cassetteEvent: anAcceptorId acceptorName: anAcceptorName event: "cassetteAlmostFull"];
}

/**/
- (void) cassetteRemovedEvent: (int) anAcceptorId acceptorName: (char *) anAcceptorName
{
	[self cassetteEvent: anAcceptorId acceptorName: anAcceptorName event: "cassetteRemoved"];
}

/**/
- (void) cassetteInstalledEvent: (int) anAcceptorId acceptorName: (char *) anAcceptorName
{
	[self cassetteEvent: anAcceptorId acceptorName: anAcceptorName event: "cassetteInstalled"];
}

/**/
- (void) validatorStatusEvent: (int) anAcceptorId acceptorName: (char *) anAcceptorName statusName: (char *) aStatusName
{
	[self cassetteEvent: anAcceptorId acceptorName: anAcceptorName event: aStatusName];
}

/**/
- (void) cassetteEvent: (int) anAcceptorId acceptorName: (char *) anAcceptorName event: (char *) anEvent
{
	XMLEvent *event;
	char line[200];
	char eventMessage[5000];

	// armo el mensaje de respuesta del evento ************
	eventMessage[0] = '\0';

	strcpy(eventMessage,XML_MESSAGE_HEADER);

	sprintf(line,"<%s>\012", XML_MESSAGE_TAG);
	strcat(eventMessage,line);
	sprintf(line,"   <%s>%s</%s>\012", XML_MESSAGE_NAME, XML_MESSAGE_EVENT_INFORMEVENT, XML_MESSAGE_NAME);
	strcat(eventMessage,line);
	// evento
	sprintf(line,"   <event>%s</event>\012", anEvent);
	strcat(eventMessage,line);
	// id del acceptor
	sprintf(line,"   <acceptorId>%d</acceptorId>\012", anAcceptorId);
	strcat(eventMessage,line);
	// nombre del acceptor
	sprintf(line,"   <acceptorName>%s</acceptorName>\012", anAcceptorName);
	strcat(eventMessage,line);
	sprintf(line,"</%s>\012", XML_MESSAGE_TAG);
	strcat(eventMessage,line);

	// agrego el evento a la lista
	event = malloc(sizeof(XMLEvent));
	event->text = strdup(eventMessage);
	[mySyncQueue pushElement: event];

}

@end
