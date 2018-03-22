#include "TelesupDefs.h"
#include "ConsoleAcceptor.h"
#include "TelesupFactory.h"
#include "system/net/all.h"
#include "ResourceStringDefs.h"
#include "MessageHandler.h"
//#include "RemoteSystemMgr.h"
#include "TelesupervisionManager.h"
#include "G2RemoteProxy.h"
#include "CimManager.h"
#include "G2TelesupParser.h"
//#include "SystemOpTelesupParser.h"
//#include "SystemOpRequest.h"
#include "RemoteConsole.h"

#define CONSOLE_PORT	9001
#define REMOTE_SYSTEM_READ_TIMEOUT		30
#define REMOTE_SYSTEM_WRITE_TIMEOUT		10


@implementation ConsoleAcceptor

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	[super initialize];

	port = 9001;
//#ifdef _USE_SSL
//	ssocket = [SSLServerSocket new];
//#else
	ssocket = [ServerSocket new];
//#endif
    myRemoteConsole = NULL;
	return self;
}

/**/
- (id) addDefaultTelesup
{
	id	telesup = [TelesupSettings new];
	id	connection = [ConnectionSettings new];

    doLog(0,"Acceptor -> agrego con exito la supervision de tipo consola\n");
    
    

	//	doLog(0,"Agrego una supervision al CMP ya que no existe\n");
		[telesup setConnection1: connection];
		[telesup setTelcoType: CONSOLE_TSUP_ID];
		[telesup setRemoteSystemId: "CONSOLE"];
	
		// Graba la conexion
		[connection setConnectionDescription: getResourceStringDef(RESID_CMP_CONNECTION, "Conexion CONSOLE")];
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
		[telesup setTelesupDescription: "CONSOLE"];
		[telesup setConnectionId1: [connection getConnectionId]];
		[telesup setActive: FALSE];
		[telesup applyChanges];
		[[TelesupervisionManager getInstance] addTelesupToCollection: telesup];    

	return telesup;

}

/**
 *	Configura el puerto pasado por parametro.
 */
- (void) setPort: (int) aPort
{
    port = aPort;
}


/**/
- (id) getDefaultTelesup
{
	COLLECTION telesups;
	int i;

	telesups = [[TelesupervisionManager getInstance] getTelesups];

    
	for (i = 0; i < [telesups size]; ++i) {
		if ([[telesups at: i] getTelcoType] == CONSOLE_TSUP_ID) {
            return [telesups at:i]; 
        }
	}

	printf("Crea la telesupervision CONSOLE porque no existe\n");
	return [self addDefaultTelesup];

}


/**/
- (void) incommingConnection: (id) aSocket
{
	id eventsProxy = NULL;
	id telesupd = NULL;
	id parser = NULL;
	int telesupRol;
//	CONSOLE console;

    printf("comienzo incomingConnection!!!!\n");
	telesupRol = [[self getDefaultTelesup] getTelesupId];
//	console = [self getConsoleByIP: [aSocket getRemoteIPAddr]];

//	remoteSystem = [[RemoteSystemMgr getInstance] getRemoteSystemByIP: [aSocket getRemoteIPAddr] port: port];getNewTelesupDaemon

    printf("despues de telesupRol  \n");  
    

    if (myRemoteConsole == NULL) { // es primera conexion para recibir eventos
    
        myRemoteConsole = [RemoteConsole new];
        [myRemoteConsole setPort: port];                      
        printf("incommingConnection primera conexion prueba sola!!!!\n");
        telesupd = [[TelesupFactory getInstance] getNewTelesupDaemon: CONSOLE_TSUP_ID
                                                            rol: telesupRol
                                                            viewer: NULL
                                                            reader: [aSocket getReader]
                                                            writer: [aSocket getWriter]];
                                             
         printf("Exito-creado el telesupD!!!!\n");fflush(stdout);
        [myRemoteConsole setTelesupDaemon: telesupd];
		[myRemoteConsole setClientSocket: aSocket];
	

		} else if (![myRemoteConsole hasStarted]) { // es la segunda conexion para enviar eventos
            
			doLog(0,">>>>>>>>>>>>>>es la segunda conexion console para enviar eventos");	
		
			eventsProxy = [G2RemoteProxy new];
			[eventsProxy setReader: [aSocket getReader]];
			[eventsProxy setWriter: [aSocket getWriter]];
			[aSocket setReadTimeout: REMOTE_SYSTEM_READ_TIMEOUT];
			[aSocket setWriteTimeout: REMOTE_SYSTEM_WRITE_TIMEOUT];
	
			telesupd = [myRemoteConsole getTelesupDaemon];
			parser = [telesupd getTelesupParser];
			assert(parser);		
			[parser setEventsProxy: eventsProxy];
			[myRemoteConsole setParser: parser];
			[myRemoteConsole setEventsClientSocket: aSocket];
	
			printf("comienza el telesupd");		
            TRY
            
                [myRemoteConsole startRemoteConsole];
            
            CATCH

                printf("excepcion ConsoleAcceptor\n");		
                [aSocket close];
                [aSocket free];
                [myRemoteConsole free];
                myRemoteConsole = NULL;
                [telesupd free];
                [eventsProxy free];

                printf("EXCEPTIONNNNNN --incommingConnection !!!!\n");

			END_TRY
		} 


}

/**/
- (void) run
{
	id csocket = NULL;
	BOOL bind = FALSE;
	BOOL accept;

	doLog(0, "Intentando hacer el bind al puerto %d\n", port);

	while (!bind) {

		TRY
			// Lo vinculo con la direccion IP local y el puerto		
			printf("Haciendo bind en el socket\n"); fflush(stdout);
			[ssocket bind: "127.0.0.1" port: port];
			bind = TRUE;

		CATCH
	
			printf( "Ha ocurrido una excepcion en el hilo, puerto = %d\n", port);
			printf( "Reintentando en 10 segundos (puerto = %d)...\n", port);
            bind = FALSE;

		END_TRY
		
		if (!bind) msleep(10000);

	}


	printf("Bind al puerto %d realizado con exito\n", port);	

	while (TRUE) {

		accept = TRUE;
	
		TRY
	
			// Espero que llegue alguna conexion
			printf("Esperando conexion entrante al puerto %d\n", port);
			csocket = [ssocket  accept];
            printf("PASO EL ACCEPT \n");
			assert(csocket);
            printf("PASO EL ACCEPT 2 \n");   
		CATCH 

			accept = FALSE;

			printf( "Ha ocurrido una exception en el accept, puerto = %d", port);

		END_TRY

		
		
		printf("PASO EL ACCEPT 3 \n");  
		if (accept) {
	
			TRY

				printf(">>>>>>>>>>>>>>>>Conexion entrante al puerto %d\n", port);
				[self incommingConnection: csocket];
	
			CATCH
	
				//LOG_EXCEPTION( LOG_TELESUP );
				printf("Ha ocurrido una excepcion conectando al cliente, puerto = %d\n", port);
			END_TRY

		}

	}

    while(TRUE) msleep(200);
}

@end
