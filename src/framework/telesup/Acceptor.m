#include "Acceptor.h"
#include "TelesupFactory.h"
#include "LCDTelesupViewer.h"
#include "TelesupViewer.h"
#include "TelesupervisionManager.h"
#include "system/net/all.h"
#include "Configuration.h"
#include "ResourceStringDefs.h"
#include "JIncomingTelTimerForm.h"
#include "MessageHandler.h"
#include "TelesupScheduler.h"
#include "CtSystem.h"
#include "Audit.h"

@implementation Acceptor

static ACCEPTOR singleInstance = NULL;

- (TELESUP_SETTINGS) addDefaultTelesup;
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
	port = 9090;
	ssocket = [SSLServerSocket new];
	myAcceptIncomingSupervision = FALSE;
	telesupRunning = FALSE;
	myRemoteCurrentUser = NULL;
	myCantLoginFails = 0;
	myShutdownApp = FALSE;
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
		if ([[telesups at: i] getTelcoType] == CMP_TSUP_ID) return [telesups at:i];
	}

	return [self addDefaultTelesup];
}

/**/
- (TELESUP_SETTINGS) addDefaultTelesup
{
	TELESUP_SETTINGS telesup = [TelesupSettings new];
	CONNECTION_SETTINGS connection = [ConnectionSettings new];

//	doLog(0,"Acceptor -> agrego una supervision al CMP ya que no existe\n");
	[telesup setConnection1: connection];
	[telesup setTelcoType: CMP_TSUP_ID];
	[telesup setRemoteSystemId: "CMP"];

	// Graba la conexion
  [connection setConnectionDescription: getResourceStringDef(RESID_CMP_CONNECTION, "Conexion CMP")];	
	[connection setConnectionType: ConnectionType_PPP];
	[connection setPortId: 4];
	/*Datos falsos para que no salte un error*/
	[connection setConnectionIP: "0.0.0.0"];
	[connection setTCPPortDestination: 1];
	[connection setISPPhoneNumber: "1"];
	[connection setConnectionUserName: "0"];
	[connection setConnectionPassword: "0"];
	/**/
	[connection setConnectionSpeed: 115200];
	[connection applyChanges];
	[[TelesupervisionManager getInstance] addConnectionToCollection: connection];

	// Graba la supervision
	[telesup setTelesupDescription: "CMP"];
	[telesup setConnectionId1: [connection getConnectionId]];
	[telesup setActive: FALSE];
	[telesup applyChanges];
	[[TelesupervisionManager getInstance] addTelesupToCollection: telesup];
	//doLog(0,"Acceptor -> agrego con exito la supervision al CMP\n");

	return telesup;

}

/**/
- (void) run
{
	SSL_CLIENT_SOCKET csocket = NULL;
	TELESUPD telesupd;
	TELESUP_VIEWER tsviewer = [TelesupViewer new];
	TELESUP_SETTINGS telesup;
	int telesupRol;
	char telcoTypeSt[20];

	TRY

		telesup = [self getDefaultTelesup];
		if (!telesup) {
			printf("Acceptor -> no existe la supervision al CMP, error, no se puede realizar el telemantenimiento\n");
			EXIT_TRY;
			return;
		}

		// Esto es porque el telesupRol es en realidad el telesupId
		telesupRol = [telesup getTelesupId];

		// Lo vinculo con la direccion IP local y el puerto		
		[ssocket bind: "127.0.0.1" port: port];
	
		while (TRUE)
		{
			printf("Esperando conexion entrante al puerto %d\n", port);
			// Espero que llegue alguna conexion
			
			csocket = [ssocket  accept];

			assert(csocket);

		/*	if (myAcceptIncomingSupervision) doLog(0,"Acepta supervision entrante\n"); 
			else doLog(0,"NO Acepta supervision entrante\n"); 

			if (telesupRunning) doLog(0,"Supervision en curso\n"); 
			else doLog(0,"NO hay supervision en curso\n"); */

			// Verifica s esta habilitado aceptar conexiones entrantes
			if ((!myAcceptIncomingSupervision) || (telesupRunning) || ([[TelesupScheduler getInstance] inTelesup])) {
			//	doLog(0,"No puede comenzar la supervision\n");
				myCommunicationIntention = CommunicationIntention_TELESUP;
				continue;
			}

			// Si no esta habilitada la opcion continua

			printf("Conexion entrante al puerto %d\n", port);
			printf("Comenzando supervision...\n");
			
			if (!myFormObserver) continue;

			telesupRunning = TRUE;

			[myFormObserver startIncomingTelesup];
			
			// Creo la supervision y la ejecuto
			telesupd = [[TelesupFactory getInstance] getNewTelesupDaemon: CMP_TSUP_ID
															rol: telesupRol
															viewer: tsviewer
															reader: [csocket getReader]
															writer: [csocket getWriter]];


			[telesupd setIsActiveLogger: FALSE];

			// Audito el comienzo de supervision
  		stringcpy(telcoTypeSt, getResourceString(RESID_TelesupSettings_TELCO_TYPE_Desc + [telesup getTelcoType]));
			strcat(telcoTypeSt, " - ");
			strcat(telcoTypeSt, getResourceStringDef(RESID_TELESUP_TYPE_MANUAL, "Manual"));
			[Audit auditEventCurrentUser: TELESUP_START additional: telcoTypeSt station: 0 logRemoteSystem: FALSE];

			[telesupd start];

			[telesupd waitFor: telesupd];

			telesupRunning = FALSE;
			[myFormObserver finishIncomingTelesup];
			myCommunicationIntention = CommunicationIntention_TELESUP;
			myFormObserver = NULL;
			myAcceptIncomingSupervision = FALSE;
			[csocket close];

			// si se recibe un update de applicacion (mediante supervision) se manda a
			// reiniciar la aplicacion luego de finalizar la supervision
			if (myShutdownApp){
				[self shutdownApp];
			}

		}

	CATCH

		ex_printfmt();
	//	doLog(0,"Ha ocurrido una excepcion en el hilo de la supervision entrante\n");
	//	doLog(0,"No se aceptaran mas conexiones\n");
		/** @todo: debo generar una auditoria */
	
	END_TRY
	
}

- (void) incCantLoginFails
{
  myCantLoginFails++;
}

/**/
- (void) acceptIncomingSupervision: (BOOL) aValue
{
//	if (myAcceptIncomingSupervision) return;

/*

	myTimer = [OTimer new];
	[myTimer initTimer: ONE_SHOT period: [[Configuration getDefaultInstance] getParamAsInteger: "INCOMING_SUPERVISION_TIMEOUT"] * 1000 object: self callback: "timerExpired"];
	[myTimer start];
*/
	
	myAcceptIncomingSupervision = aValue;
}

/**/
- (void) timerExpired
{
	//doLog(0,"Expiro el tiempo de conexion de SAR I\n");

	[myTimer stop];
	[myTimer free];

	myAcceptIncomingSupervision = FALSE;
}

/**/
- (BOOL) isTelesupRunning
{
	return telesupRunning;
}

/**/
- (void) setFormObserver: (id) aForm
{
	myFormObserver = aForm;
}

- (void) setRemoteCurrentUser: (id) aUser { myRemoteCurrentUser = aUser; }
- (id) getRemoteCurrentUser { return myRemoteCurrentUser; }

- (int) getCantLoginFails { return myCantLoginFails; }
- (void) initCantLoginFails { myCantLoginFails = 0; }

/**/
- (void) setCommunicationIntention: (CommunicationIntention) aCommunicationIntention
{
	myCommunicationIntention  = aCommunicationIntention;
}

/**/
- (CommunicationIntention) getCommunicationIntention
{
	return myCommunicationIntention;
}

- (void) setShutdownApp: (BOOL) aValue
{
	myShutdownApp = aValue;
}

- (BOOL) getShutdownApp
{
	return myShutdownApp;
}

- (void) shutdownApp
{					
	[[CtSystem getInstance] shutdownSystem];

	// reinicio el sistema operativo
	system("reboot");
}

@end
