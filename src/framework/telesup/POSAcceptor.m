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

#define TIME_EXPIRE											300000

#define XML_RESPONSE_FILE								BASE_VAR_PATH "/response.xml"

#define XML_MESSAGE_TAG									"message"
#define XML_MESSAGE_NAME								"messageName"

#define XML_OPENVALIDATEDCASH_ERROR			"OpenValidatedCashFail"
#define XML_OPENVALIDATEDCASH_SUCCESS		"OpenValidatedCashSuccess"
#define XML_CLOSEVALIDATEDCASH_ERROR		"CloseValidatedCashFail"
#define XML_CLOSEVALIDATEDCASH_SUCCESS	"CloseValidatedCashSuccess"
#define XML_OPENMANUALCASH_ERROR				"OpenManualCashFail"
#define XML_OPENMANUALCASH_SUCCESS			"OpenManualCashSuccess"
#define XML_ENDOFDAY_ERROR							"EndOfDayFail"

#define XML_MESSAGE_STARTCONNECTION			"startConnection"
#define XML_MESSAGE_ENDCONNECTION				"endConnection"
#define XML_MESSAGE_LOGIN								"userLogin"
#define XML_MESSAGE_LOGOFF							"userLogoff"
#define XML_MESSAGE_GETSTATUS						"getStatus"
#define XML_MESSAGE_GETDROPINFO					"getDropInfo"
#define XML_MESSAGE_OPENVALIDATEDCASH		"openValidatedCash"
#define XML_MESSAGE_CLOSEVALIDATEDCASH	"closeValidatedCash"
#define XML_MESSAGE_OPENMANUALCASH			"openManualCash"
#define XML_MESSAGE_ENDOFDAY						"endOfDay"
#define XML_MESSAGE_DROPSREPORT					"dropsReport"
#define XML_MESSAGE_DEPOSITSREPORT			"depositsReport"
#define XML_MESSAGE_ENDDAYREPORT				"endDayReport"

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

@implementation POSAcceptor

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
	port = 5555;
	ssocket = [SSLServerSocket new];
	telesupRunning = FALSE;
	myReader = NULL;
	myWriter = NULL;
	myMessage = malloc(TELESUP_MSG_SIZE + 1);
	myCurrentMsg = malloc(TELESUP_MSG_SIZE + 1);
	myAuxMessage = malloc(TELESUP_MSG_SIZE + 1);
	myDrop = NULL;
	myExtendedDrop = NULL;
	POSEvAcceptor = [POSEventAcceptor new];

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
- (void) timerExpired
{
//	doLog(0,"Expiro el tiempo de conexion del POS por inactividad\n");

	if (myDrop) {
		[myTimer stop];
		[myTimer start];
	//	doLog(0,"Reinicio el timer de inactividad porque estoy en medio de un deposito.\n");
		return;
	}

	[myTimer stop];

	telesupRunning = FALSE;

	// mato al cliente
	if (csocket) {
	//	doLog(0,"cerrando csocket por inactividad ... "); fflush(stdout);
		[csocket close];
		csocket = NULL;
		msleep(10000);
	//	doLog(0,"[OK]\n");
	}

}

/**/
- (void) run
{
	int size;
	char msgName[50];
	char exceptionDescription[512];
	BOOL sendTelesupError, telesupHaltError;
	char msgError[200];
	BOOL isEventsStarted = FALSE;
	BOOL bind = FALSE;

	myParser = NULL;
	myTree = NULL;

	myTelesup = [self getDefaultTelesup];
	if (!myTelesup) {
	//	doLog(0,"POSAcceptor -> no existe la supervision al POS, error, no se puede realizar la conexion.\n");
		return;
	}

	while (!bind) {
		TRY
			// Lo vinculo con la direccion IP local y el puerto		
			port = [[myTelesup getConnection1] getConnectionTCPPortDestination];
			[ssocket bind: "127.0.0.1" port: port];
			bind = TRUE;
	
		CATCH
	
	//		doLog(0, "Ha ocurrido una excepcion en el hilo, puerto = %d", port);
	//		doLog(0, "Reintentando en 10 segundos (puerto = %d)...", port);
			msleep(10000);
	
		END_TRY
	}
	
	// creo el timer
	myTimer = [OTimer new];
	[myTimer initTimer: ONE_SHOT period: TIME_EXPIRE object: self callback: "timerExpired"];

	while (TRUE) {
		
		TRY

			// Espero que llegue alguna conexion
		//	doLog(0,"Esperando conexion entrante del POS al puerto %d\n", port);
			csocket = [ssocket accept];
			if (csocket == NULL) THROW(SOCKET_EX);
		//	doLog(0,"Conexion entrante al puerto %d\n", port);

			myReader = [csocket getReader];
			myWriter = [csocket getWriter];

			// CHEQUEO ERRORES:
			// 1) si no existe el telesupViewer me voy
			// 2) si ya hay un usuario logueado en el sistema me voy
			if ([self checkErrors]) {
				EXIT_TRY;
				continue;
			}

		//	doLog(0,"Comenzando supervision POS...\n");
			telesupRunning = TRUE;
			myConnectionStarted = FALSE;

			// arranco la pantalla de supervision
			[self startTelesupViewer];

			// inicio supervision de eventos
			if (!isEventsStarted) {
				[POSEvAcceptor start];
				isEventsStarted = TRUE;
			}

			// inicio timer de desconeccion por inactividad
			[myTimer start];

			while (telesupRunning) {

				TRY

					// Lee el mensaje
					size = [self readMessage: myCurrentMsg qty: TELESUP_MSG_SIZE - 1];

					// luego de leer un comando reseteo el timer
					[self resetTimer];

					// cargo el XML en memoria
					if (myTree) scew_tree_free(myTree);
					if (myParser) scew_parser_free(myParser);

					myParser = scew_parser_create();
					scew_parser_ignore_whitespaces(myParser, 0);
					scew_parser_load_buffer(myParser, myCurrentMsg, size);
					myTree = scew_parser_tree(myParser);

					// obtengo el nombre del mensaje
					msgName[0] = '\0';
					strcpy(msgName, [self parseRequestName: myTree name: msgName]);

					// Si aun no se realizo el startConnection verifico si es dicho mensaje.
					// Si no lo es no lo dejo conectarse
					if (!myConnectionStarted) {
						if (strcasecmp(msgName, XML_MESSAGE_STARTCONNECTION) != 0) {
							strcpy(msgError, getResourceStringDef(RESID_MUST_START_CONNECTION, "Debe iniciar la conexion."));
							[self sendErrorMessage: msgName msgError: msgError];
							EXIT_TRY;
							continue;
						}
					} else {
						// Si aun no se logueo un usuario verifico si es un mensaje de login.
						// Si no lo es no lo dejo pasar a no ser que se quiera desconectar
						if (strcasecmp(msgName, XML_MESSAGE_ENDCONNECTION) != 0) {
							if (![[UserManager getInstance] getUserLoggedIn]) {
								if (strcasecmp(msgName, XML_MESSAGE_LOGIN) != 0) {
									strcpy(msgError, getResourceStringDef(RESID_MUST_LOGIN_USER, "Debe realizar el login de usuario."));
									[self sendErrorMessage: msgName msgError: msgError];
									EXIT_TRY;
									continue;
								}
							} else {
								// si ya hay alguien logueado y se intenta loguear otro no lo dejo
								if (strcasecmp(msgName, XML_MESSAGE_LOGIN) == 0) {
									strcpy(msgError, getResourceStringDef(RESID_EXIST_USER_LOGGEDIN, "Ya existe un usuario logueado."));
									[self sendErrorMessage: msgName msgError: msgError];
									EXIT_TRY;
									continue;
								}
							}
						}
					}

					// Procesa el request
					if ([self processMessageRequest: myTree msgName: msgName]) {
						[self sendMessage];
					} else {
					//	doLog(0,"Mensaje [%s] desconocido.\n", msgName);
						strcpy(msgError, getResourceStringDef(RESID_UNKNOWN_COMMAND, "Comando desconocido."));
						[self sendErrorMessage: msgName msgError: msgError];
						EXIT_TRY;
						continue;
					}

					// Controla que sea o no un mensaje de fin conexion
					if (strcasecmp(msgName, XML_MESSAGE_ENDCONNECTION) == 0) {
						if (myTimer) [myTimer stop];
						BREAK_TRY;
					}

				CATCH

					// Imprime la excepcion
					ex_printfmt();

					EXCEPTION				( FT_FILE_TRANSFER_ERROR )	telesupHaltError = FALSE;			
					else EXCEPTION_GROUP	( IO_EXCEPT ) 				telesupHaltError = TRUE;
					else EXCEPTION_GROUP	( NET_EXCEPT ) 				telesupHaltError = TRUE;
					else EXCEPTION			( TSUP_GENERAL_EX ) 		telesupHaltError = TRUE;

		//			doLog(0,"POSAcceptor: Ha ocurrido una excepcion en el hilo de la supervision al POS (halt=%d)\n", telesupHaltError);

					break;
						
				END_TRY
			} // while (telesupRunning)

			// finalizo la conexion
			[self closeConnection];

		CATCH

			ex_printfmt();
	//		doLog(0,"Ha ocurrido una excepcion grave en el hilo de la supervision POS\n");
	//		doLog(0,"Se reiniciara la supervision POS\n");

			telesupRunning = FALSE;
			myConnectionStarted = FALSE;

		END_TRY
	}

}

/**/
- (void) resetTimer {
	if (myTimer) {
		[myTimer stop];
		[myTimer start];
	}
}

/**/
- (void) startTelesupViewer {
	// arranco pantalla de suypervison
	[myTelesupViewer start];
	[myTelesupViewer updateTitle: [myTelesup str]];
	[myTelesupViewer updateText: getResourceStringDef(RESID_STARTING_TELESUP, "Iniciando....")];
	[myTelesupViewer setTelesupId: [myTelesup getTelesupId]];
}

/**/
- (BOOL) checkErrors
{
	// si no existe el telesupViewer me voy
	if (!myTelesupViewer) {
	//	doLog(0,"ERROR: no existe telesupViewer...\n");				
		if (csocket) {
		//	doLog(0,"cerrando csocket ... "); fflush(stdout);
			[csocket close];
			csocket = NULL;
			msleep(10000);
		//	doLog(0,"[OK]\n");
		}
		return TRUE;
	}

	// si ya hay un usuario logueado en el sistema me voy
	if ([[UserManager getInstance] getUserLoggedIn]) {
	//	doLog(0, "Ya hay un usuario logueado. Se cerrara la conexion.\n");
		if (csocket) {
	//		doLog(0,"cerrando csocket ... "); fflush(stdout);
			[csocket close];
			csocket = NULL;
			msleep(10000);
		//	doLog(0,"[OK]\n");
		}
		return TRUE;
	}

	return FALSE;
}

/**/
- (void) closeConnection
{
	int userId = 0;

	//doLog(0,"***** closeConnection *****\n");

	telesupRunning = FALSE;
	myConnectionStarted = FALSE;

	// free del tree
	if (myTree) scew_tree_free(myTree);
	myTree = NULL;
	if (myParser) scew_parser_free(myParser);
	myParser = NULL;

	// si hay algun deposito validado iniciado lo cierro
	if (myDrop) {
		[[CimManager getInstance] endDeposit];
		[self resetDrop];
	}

	// si hay un usuario logueado lo deslogueo
	if ([[UserManager getInstance] getUserLoggedIn]) {
		userId = [[[UserManager getInstance] getUserLoggedIn] getUserId];
		[[UserManager getInstance] logOffUser: userId];
	}

	if (myTimer) [myTimer stop];

	if (csocket) {
	//	doLog(0,"cerrando csocket ... "); fflush(stdout);
		[csocket close];
		csocket = NULL;
		msleep(10000);
//		doLog(0,"[OK]\n");
	}

	if (myTelesupViewer) {
	//	doLog(0,"myTelesupViewer finish...");
		[myTelesupViewer finish];
	//	doLog(0,"[OK]\n");
	}
}

/**/
- (BOOL) isTelesupRunning
{
	return telesupRunning;
}

/**/
- (void) setTelesupViewer: (TELESUP_VIEWER) aTelesupViewer
{
	myTelesupViewer = aTelesupViewer;
}

/**/
- (void) resetDrop
{
	myDrop = NULL;
}

/**/
- (int) readMessage: (char *) aBuffer qty: (int) aQty
{	
	int size;
	char *p = myAuxMessage;
	datetime_t date;
  struct tm brokenTime;
	char dateStr[50];
	
	assert(aBuffer);
	assert(myReader);
	
	memset(myAuxMessage, '\0', aQty);
		
	while (1) {
		size = [myReader read: p qty: aQty - (p - myAuxMessage)];

		if (size <= 0) 
			THROW( TSUP_GENERAL_EX );

		p += size;
		
		/* Si recibe un mensaje demasiado largo lanza una excepcion.
			No deberia pasar esta situacion.*/
		if (p - myAuxMessage > aQty) THROW( TSUP_MSG_TOO_LARGE_EX );

		*p = '\0';

		// Debe haber un "\n</message>\n" para definir un mensaje. Si no llega vuelve a leer mas.
		if ([self isRequestComplete: myAuxMessage])
			break;
	}

	// copia el texto recibido
	strcpy(aBuffer, myAuxMessage);

	date = [SystemTime getLocalTime];
	convertTime(&date, &brokenTime);
	formatBrokenDateTime(dateStr, &brokenTime);
	/*doLog(0,"POSAcceptor:Message Receive (%d) -----------------------\n"
			"%s\n "
			"%s\n "
			"--------------------------------------------------------\n", size, dateStr, myAuxMessage); fflush(stdout);*/

	return size;
}

/**/
- (void) getTreeBuffer: (char *) fileName
{
	FILE *f;
	int size;

	f = fopen(fileName, "r");

	if (f) {
		fseek(f, 0, SEEK_END);
		size = ftell(f);
		fseek(f, 0, SEEK_SET);
		fread(myMessage, size, 1, f);
		fclose(f);
		myMessage[size] = '\0';
		unlink(fileName);
  }
}

/**/
- (void) sendMessage
{
	int size;
	char msgName[50];

	size = strlen(myMessage);
	if (size > TELESUP_MSG_SIZE) THROW( TSUP_MSG_TOO_LARGE_EX );

//	doLog(0,"Sending msg...\n"); fflush(stdout);

	[myWriter write: myMessage qty: size];

	/*doLog(0,"POSAcceptor:Message Sended (%d) --------------------------\n"
			"%s\n "
			"-----------------------------------------------------------\n", strlen(myMessage), myMessage); fflush(stdout);*/

}

/**/
- (BOOL) processMessageRequest: (scew_tree*) aTree msgName: (char *) aMsgName
{

	TRY

		[myTelesupViewer updateText: getResourceStringDef(RESID_PROCESSING, "Procesando...")];

		// derivo cada mensaje al metodo que lo procesara.
		if (strcasecmp(aMsgName, XML_MESSAGE_STARTCONNECTION) == 0) [self startConnection: aTree];
		if (strcasecmp(aMsgName, XML_MESSAGE_ENDCONNECTION) == 0) [self endConnection: aTree];
		if (strcasecmp(aMsgName, XML_MESSAGE_LOGIN) == 0) [self userLogin: aTree];
		if (strcasecmp(aMsgName, XML_MESSAGE_LOGOFF) == 0) [self userLogoff: aTree];
		if (strcasecmp(aMsgName, XML_MESSAGE_GETSTATUS) == 0) [self getStatus: aTree];
		if (strcasecmp(aMsgName, XML_MESSAGE_GETDROPINFO) == 0) [self getDropInfo: aTree];
		if (strcasecmp(aMsgName, XML_MESSAGE_OPENVALIDATEDCASH) == 0) [self openCash: aTree];
		if (strcasecmp(aMsgName, XML_MESSAGE_CLOSEVALIDATEDCASH) == 0) [self closeCash: aTree];
		if (strcasecmp(aMsgName, XML_MESSAGE_OPENMANUALCASH) == 0) [self openManualCash: aTree];
		if (strcasecmp(aMsgName, XML_MESSAGE_ENDOFDAY) == 0) [self endOfDay: aTree];
		if (strcasecmp(aMsgName, XML_MESSAGE_DROPSREPORT) == 0) [self dropsReport: aTree];
		if (strcasecmp(aMsgName, XML_MESSAGE_DEPOSITSREPORT) == 0) [self depositsReport: aTree];
		if (strcasecmp(aMsgName, XML_MESSAGE_ENDDAYREPORT) == 0) [self endDayReport: aTree];


		[myTelesupViewer updateText: getResourceStringDef(RESID_WAITING, "Esperando...")];

	CATCH

		return FALSE;

	END_TRY
	
	return TRUE;
}

/**/
- (BOOL) isRequestComplete: (char *)aBuffer
{	
	int i = strlen(aBuffer);
	char *p = aBuffer + strlen(aBuffer) - 1;

	// se posiciona en el ultimo caracter que no sea ' ' o '\n'
	while (--i) {
		if (*p != '\012' && *p != ' ')
			break;
		p--;
	}

	// Por lo menos debe haber 12 "...\n</message>\n"
	if (i < 12) return FALSE;

	// Se fija si hay un "\n</message>\n"
	if (*(p + 1) == '\012' && *(p + 0) == '>' && 
		tolower(*(p - 1)) == 'e' && tolower(*(p - 2)) == 'g' &&
		tolower(*(p - 3)) == 'a' && tolower(*(p - 4)) == 's' && 
		tolower(*(p - 5)) == 's' && tolower(*(p - 6)) == 'e' && 
		tolower(*(p - 7)) == 'm' && tolower(*(p - 8)) == '/' && 
		tolower(*(p - 9)) == '<' && *(p - 10) == '\012') {
		return TRUE;
	}

	return FALSE;
}

/**/
- (char *) parseRequestName: (scew_tree*) aTree name: (char *) aName
{
  scew_element * root;
  scew_element * element;

	root = scew_tree_root(aTree);

  if (!root) return "";

	element =  scew_element_by_name(root, XML_MESSAGE_NAME);
  sprintf(aName, "%s", scew_element_contents(element));

	return aName;
}


//*******************************************************************
//******************* PROCESAMIENTO DE MENSAJES *********************
//*******************************************************************

/**/
- (void) sendErrorMessage: (char *) aMsgName msgError: (char *) aMsgError
{
	scew_tree* tree = NULL;

	scew_element* root = NULL;
	scew_element* element = NULL;

	myMessage[0] = '\0';

	// armo el mensaje de respuesta **********
	tree = scew_tree_create();
	root = scew_tree_add_root(tree, XML_MESSAGE_TAG);
	element = scew_element_add(root, XML_MESSAGE_NAME);
	scew_element_set_contents(element, aMsgName);

	element = scew_element_add(root, "response");
	scew_element_set_contents(element, "Error");

	element = scew_element_add(root, "description");
	scew_element_set_contents(element, aMsgError);

	// creo el xml con el tree
	scew_writer_tree_file(tree, XML_RESPONSE_FILE);
	scew_tree_free(tree);

	// obtengo el contenido del xml y lo guardo en myMessage
	[self getTreeBuffer: XML_RESPONSE_FILE];

	[self sendMessage];

}

/**/
- (void) startConnection: (scew_tree*) aTree
{
	scew_tree* tree = NULL;
	scew_element* root = NULL;
	scew_element* element = NULL;
	char user[10];
	char password[10];

	user[0] = '\0';
	password[0] = '\0';

	// analizo los parametros recibidos ********
  root = scew_element_by_name(scew_tree_root(aTree), "params");
  if (root) {
		element =  scew_element_by_name(root, "user");
  	sprintf(user, "%s", scew_element_contents(element));

		element =  scew_element_by_name(root, "password");
  	sprintf(password, "%s", scew_element_contents(element));
	}

	// armo el mensaje de respuesta ************
	myMessage[0] = '\0';

	tree = scew_tree_create();
	root = scew_tree_add_root(tree, XML_MESSAGE_TAG);
	element = scew_element_add(root, XML_MESSAGE_NAME);
	scew_element_set_contents(element, XML_MESSAGE_STARTCONNECTION);

	if ( (strcmp([myTelesup getTelesupUserName], user) == 0) && (strcmp([myTelesup getTelesupPassword],password) == 0) ) {
		myConnectionStarted = TRUE;
		element = scew_element_add(root, "response");
		scew_element_set_contents(element, "ConnexionSuccess");
	} else {
		element = scew_element_add(root, "response");
		scew_element_set_contents(element, "Error");

		element = scew_element_add(root, "description");
		scew_element_set_contents(element, getResourceStringDef(RESID_WRONG_CONNECTION_DATA, "Datos de conexion erroneos."));
	}

	// creo el xml con el tree
	scew_writer_tree_file(tree, XML_RESPONSE_FILE);
	scew_tree_free(tree);

	// obtengo el contenido del xml y lo guardo en myMessage
	[self getTreeBuffer: XML_RESPONSE_FILE];

}

/**/
- (void) endConnection: (scew_tree*) aTree
{
	scew_tree* tree = NULL;
	scew_element* root = NULL;
	scew_element* element = NULL;

	// marco el fin de la conexion *************
	myConnectionStarted = FALSE;

	// armo el mensaje de respuesta ************
	myMessage[0] = '\0';

	tree = scew_tree_create();
	root = scew_tree_add_root(tree, XML_MESSAGE_TAG);
	element = scew_element_add(root, XML_MESSAGE_NAME);
	scew_element_set_contents(element, XML_MESSAGE_ENDCONNECTION);

	element = scew_element_add(root, "response");
	scew_element_set_contents(element, "ConnectionEnded");

	// creo el xml con el tree
	scew_writer_tree_file(tree, XML_RESPONSE_FILE);
	scew_tree_free(tree);

	// obtengo el contenido del xml y lo guardo en myMessage
	[self getTreeBuffer: XML_RESPONSE_FILE];

}

/**/
- (void) userLogin: (scew_tree*) aTree
{
	scew_tree* tree = NULL;
	scew_element* root = NULL;
	scew_element* element = NULL;
	char user[10];
	char password[10];
	int userId = 0;
  COLLECTION dallasKeys = [Collection new];
	char msgError[100];

	user[0] = '\0';
	password[0] = '\0';

	// analizo los parametros recibidos ********
  root = scew_element_by_name(scew_tree_root(aTree), "params");
  if (root) {
		element =  scew_element_by_name(root, "userId");
  	sprintf(user, "%s", scew_element_contents(element));

		element =  scew_element_by_name(root, "password");
  	sprintf(password, "%s", scew_element_contents(element));
	}

	// armo el mensaje de respuesta ************
	myMessage[0] = '\0';

	tree = scew_tree_create();
	root = scew_tree_add_root(tree, XML_MESSAGE_TAG);
	element = scew_element_add(root, XML_MESSAGE_NAME);
	scew_element_set_contents(element, XML_MESSAGE_LOGIN);

	// intento loguear al usuario
	TRY
		userId = [[UserManager getInstance] logInUser: user password: password dallasKeys: dallasKeys];
		[dallasKeys freePointers];
		[dallasKeys free];
	CATCH
		userId = 0;

		if (ex_get_code() == INACTIVE_USER_EX)
			strcpy(msgError, getResourceStringDef(RESID_NOT_ACTIVE_USER, "Usted no es un usuario activo."));
		else
			strcpy(msgError, getResourceStringDef(WRONG_USER_NAME_OR_PASSWORD_EX, "Nombre de usuario o clave incorrecto."));

	END_TRY

	if (userId != 0) {
		element = scew_element_add(root, "response");
		scew_element_set_contents(element, "LoginSuccess");
	} else {
		element = scew_element_add(root, "response");
		scew_element_set_contents(element, "LoginFail");

		element = scew_element_add(root, "description");
		scew_element_set_contents(element, msgError);
	}

	// creo el xml con el tree
	scew_writer_tree_file(tree, XML_RESPONSE_FILE);
	scew_tree_free(tree);

	// obtengo el contenido del xml y lo guardo en myMessage
	[self getTreeBuffer: XML_RESPONSE_FILE];

}

/**/
- (void) userLogoff: (scew_tree*) aTree
{
	scew_tree* tree = NULL;
	scew_element* root = NULL;
	scew_element* element = NULL;
	int userId = 0;

	// antes de realizar el logoff verifico si hay un deposito abierto. Si hay uno lo cierro
	if (myDrop) {
		[[CimManager getInstance] endDeposit];
		[self resetDrop];
	}

	// deslogueo al usuario logueado ***********
	userId = [[[UserManager getInstance] getUserLoggedIn] getUserId];
	[[UserManager getInstance] logOffUser: userId];

	// armo el mensaje de respuesta ************
	myMessage[0] = '\0';

	tree = scew_tree_create();
	root = scew_tree_add_root(tree, XML_MESSAGE_TAG);
	element = scew_element_add(root, XML_MESSAGE_NAME);
	scew_element_set_contents(element, XML_MESSAGE_LOGOFF);

	element = scew_element_add(root, "response");
	scew_element_set_contents(element, "LogoffSuccess");

	// creo el xml con el tree
	scew_writer_tree_file(tree, XML_RESPONSE_FILE);
	scew_tree_free(tree);

	// obtengo el contenido del xml y lo guardo en myMessage
	[self getTreeBuffer: XML_RESPONSE_FILE];

}

/**/
- (void) getStatus: (scew_tree*) aTree
{
	scew_tree* tree = NULL;
	scew_element* root = NULL;
	scew_element* element = NULL;
	scew_element* elementList = NULL;
	scew_element* elementAcceptor = NULL;
	scew_element* elementDoor = NULL;
	COLLECTION acceptorsList;
	COLLECTION doorList;
	int iAcceptor, iDoor, qtyUse;
	id acceptorSettings, door;
	char buf[50];
	float usePercent;

	// armo el mensaje de respuesta ************
	myMessage[0] = '\0';

	tree = scew_tree_create();
	root = scew_tree_add_root(tree, XML_MESSAGE_TAG);
	element = scew_element_add(root, XML_MESSAGE_NAME);
	scew_element_set_contents(element, XML_MESSAGE_GETSTATUS);

	element = scew_element_add(root, "response");
	scew_element_set_contents(element, "Ok");

	// Obtengo la lista de validadores
	acceptorsList = [[[CimManager getInstance] getCim] getAcceptors];
	elementList = scew_element_add(root, "acceptors");
		
	// Recorro la lista de validadores
	for (iAcceptor = 0; iAcceptor < [acceptorsList size]; ++iAcceptor) {
		acceptorSettings = [[acceptorsList at: iAcceptor] getAcceptorSettings];
		
		if ([acceptorSettings getAcceptorType] == AcceptorType_VALIDATOR) {
		
				elementAcceptor = scew_element_add(elementList, "acceptor");

				// Id del aceptador
				element = scew_element_add(elementAcceptor, "acceptorId");
				sprintf(buf,"%d",[acceptorSettings getAcceptorId]);
				scew_element_set_contents(element, buf);

				// Nombre del aceptador
				element = scew_element_add(elementAcceptor, "acceptorName");
				scew_element_set_contents(element, [acceptorSettings getAcceptorName]);

				// Staker Use
				element = scew_element_add(elementAcceptor, "cassetteUse");
				qtyUse = [[[ExtractionManager getInstance] getCurrentExtraction: [acceptorSettings getDoor]] getQtyByAcceptor: acceptorSettings];

				if ([acceptorSettings getStackerSize] != 0)
						usePercent = ((float)qtyUse / (float)[acceptorSettings getStackerSize]) * 100.0;
				else usePercent = 0;

				sprintf(buf,"%4.0f %%",usePercent);
				scew_element_set_contents(element, trim(buf));
		}
	}

	// Obtengo la lista de puertas
	doorList = [[[CimManager getInstance] getCim] getDoors];
	elementList = scew_element_add(root, "doors");

	// Recorro la lista de puertas
	for (iDoor = 0; iDoor < [doorList size]; ++iDoor) {

		door = [doorList at: iDoor];

		elementDoor = scew_element_add(elementList, "door");

		// Id de la puerta
		element = scew_element_add(elementDoor, "doorId");
		sprintf(buf,"%d",[door getDoorId]);
		scew_element_set_contents(element, buf);

		// Nombre de la puerta
		element = scew_element_add(elementDoor, "doorName");
		scew_element_set_contents(element, [door getDoorName]);

		// Sensor type
		element = scew_element_add(elementDoor, "sensorType");
		switch ([door getSensorType]) {
			case SensorType_NONE:
					scew_element_set_contents(element, getResourceStringDef(RESID_Door_SENSOR_TYPE_NONE, "Ninguno"));
				break;
			case SensorType_LOCKER:
					scew_element_set_contents(element, getResourceStringDef(RESID_Door_SENSOR_TYPE_LOCKER, "Plunger"));
				break;
			case SensorType_PLUNGER:
					scew_element_set_contents(element, getResourceStringDef(RESID_Door_SENSOR_TYPE_PLUNGER, "Locker"));
				break;
			case SensorType_BOTH:
					scew_element_set_contents(element, getResourceStringDef(RESID_Door_SENSOR_TYPE_BOTH, "Ambos"));
					break;
			case SensorType_PLUNGER_EXT:
					scew_element_set_contents(element, getResourceStringDef(RESID_Door_SENSOR_TYPE_PLUNGER_EXT, "Plunger-Ext"));
					break;
		}

		// Locker state
		element = scew_element_add(elementDoor, "locker");
		switch ([door getLockState]) {
			case LockState_UNDEFINED:
					scew_element_set_contents(element, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
				break;
			case LockState_UNLOCK:
					scew_element_set_contents(element, getResourceStringDef(RESID_OPENED_LOCKER, "Abierta"));
				break;
			case LockState_LOCK:
					scew_element_set_contents(element, getResourceStringDef(RESID_CLOSED_LOCKER, "Cerrada"));
				break;
		}

		// Plunger state
		element = scew_element_add(elementDoor, "plunger");
		switch ([door getDoorState]) {
			case DoorState_UNDEFINED:
					scew_element_set_contents(element, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
				break;
			case DoorState_OPEN:
					scew_element_set_contents(element, getResourceStringDef(RESID_OPENED_PLUNGER, "Abierto"));
				break;
			case DoorState_CLOSE:
					scew_element_set_contents(element, getResourceStringDef(RESID_CLOSED_PLUNGER, "Cerrado"));
				break;
		}
	}

	// creo el xml con el tree
	scew_writer_tree_file(tree, XML_RESPONSE_FILE);
	scew_tree_free(tree);

	// obtengo el contenido del xml y lo guardo en myMessage
	[self getTreeBuffer: XML_RESPONSE_FILE];

}

/**/
- (void) getDropInfo: (scew_tree*) aTree
{
	scew_tree* tree = NULL;
	scew_element* root = NULL;
	scew_element* element = NULL;
	scew_element* elementList = NULL;
	scew_element* elementCash = NULL;
	scew_element* elementRef = NULL;
	scew_element* elementAcceptor = NULL;
	scew_element* valueList = NULL;
	scew_element* elementValue = NULL;
	scew_element* currencyList = NULL;
	scew_element* elementAccCurrency = NULL;
	COLLECTION cimCashs, references, acceptorsList, acceptedValues, acceptedCurrenies;
	int iCash, iRef, iAcceptor, iValues, iAccCurrency;
	id cimCash, reference, acceptedDepositValue, acceptedCurrency, currency, acceptorSettings;
	char buf[50];

	// armo el mensaje de respuesta ************
	myMessage[0] = '\0';

	tree = scew_tree_create();
	root = scew_tree_add_root(tree, XML_MESSAGE_TAG);
	element = scew_element_add(root, XML_MESSAGE_NAME);
	scew_element_set_contents(element, XML_MESSAGE_GETDROPINFO);

	// Obtengo la lista de cashes
	cimCashs = [[[CimManager getInstance] getCim] getCimCashs];
	elementList = scew_element_add(root, "cashList");
		
	// Recorro la lista de cashes
	for (iCash = 0; iCash < [cimCashs size]; ++iCash) {

			cimCash = [cimCashs at: iCash];

			elementCash = scew_element_add(elementList, "cash");

			// Id del cash
			element = scew_element_add(elementCash, "cashId");
			sprintf(buf,"%d",[cimCash getCimCashId]);
			scew_element_set_contents(element, buf);

			// Nombre del cash
			element = scew_element_add(elementCash, "cashName");
			scew_element_set_contents(element, [cimCash getName]);

			// Tipo de cash
			element = scew_element_add(elementCash, "cashType");
			sprintf(buf,"%d",[cimCash getDepositType]);
			scew_element_set_contents(element, buf);
	}

	// Obtengo la lista de references
	references = [[CashReferenceManager getInstance] getCashReferences];

	if ([references size] > 0)
		elementList = scew_element_add(root, "referenceList");

	// Recorro la lista de puertas
	for (iRef = 0; iRef < [references size]; ++iRef) {

		reference = [references at: iRef];
		elementRef = scew_element_add(elementList, "reference");

		// Id del reference
		element = scew_element_add(elementRef, "referenceId");
		sprintf(buf,"%d",[reference getCashReferenceId]);
		scew_element_set_contents(element, buf);

		// Nombre del reference
		element = scew_element_add(elementRef, "referenceName");
		scew_element_set_contents(element, [reference getName]);

		// Reference padre
		element = scew_element_add(elementRef, "parentId");
		if ([reference getParent])
			sprintf(buf,"%d",[[reference getParent] getCashReferenceId]);
		else sprintf(buf,"%d",0);
		scew_element_set_contents(element, buf);
	}

	// Obtengo la lista de validadores / buzon
	acceptorsList = [[[CimManager getInstance] getCim] getAcceptors];

	if ([acceptorsList size] > 0)
		elementList = scew_element_add(root, "acceptorList");
		
	// Recorro la lista de validadores
	for (iAcceptor = 0; iAcceptor < [acceptorsList size]; ++iAcceptor) {

		acceptorSettings = [[acceptorsList at: iAcceptor] getAcceptorSettings];
		elementAcceptor = scew_element_add(elementList, "acceptor");

		// Id del aceptador
		element = scew_element_add(elementAcceptor, "acceptorId");
		sprintf(buf,"%d",[acceptorSettings getAcceptorId]);
		scew_element_set_contents(element, buf);

		// Nombre del aceptador
		element = scew_element_add(elementAcceptor, "acceptorName");
		scew_element_set_contents(element, [acceptorSettings getAcceptorName]);

		// tipo de aceptador 1 = validador / 2 = buzon
		element = scew_element_add(elementAcceptor, "acceptorType");
		sprintf(buf,"%d",[acceptorSettings getAcceptorType]);
		scew_element_set_contents(element, buf);

		// lista de valores
		acceptedValues = [acceptorSettings getAcceptedDepositValues];
		valueList = scew_element_add(elementAcceptor, "valueList");

		// Solo agrego los valores que tienen monedas asociadas
		// de lo contrario podria elegir el valor pero luego no
		// la moneda
		for (iValues = 0; iValues < [acceptedValues size]; ++iValues) {

			acceptedDepositValue = [acceptedValues at: iValues];

			if ([[acceptedDepositValue getAcceptedCurrencies] size] > 0) {
				elementValue = scew_element_add(valueList, "value");

				// Id del valor
				element = scew_element_add(elementValue, "valueId");
				sprintf(buf,"%d",[acceptedDepositValue getDepositValueType]);
				scew_element_set_contents(element, buf);
	
				// Nombre del valor
				element = scew_element_add(elementValue, "valueName");
				scew_element_set_contents(element, [acceptedDepositValue str]);
	
				// listado de monedas del valor
				acceptedCurrenies = [acceptedDepositValue getAcceptedCurrencies];
				currencyList = scew_element_add(elementValue, "currencyList");

				for (iAccCurrency = 0; iAccCurrency < [acceptedCurrenies size]; ++iAccCurrency) {

					acceptedCurrency = [acceptedCurrenies at: iAccCurrency];
					elementAccCurrency = scew_element_add(currencyList, "currency");

					currency = [acceptedCurrency getCurrency];

					// Id de la moneda
					element = scew_element_add(elementAccCurrency, "currencyId");
					sprintf(buf,"%d",[currency getCurrencyId]);
					scew_element_set_contents(element, buf);
		
					// Codigo de la moneda
					element = scew_element_add(elementAccCurrency, "currencyCode");
					scew_element_set_contents(element, [currency getCurrencyCode]);
				}
			}
		}

	}


	// Usa ApplyTo
	element = scew_element_add(root, "useApplyTo");
	if ([[CimGeneralSettings getInstance] getAskApplyTo])
		scew_element_set_contents(element, "TRUE");
	else
		scew_element_set_contents(element, "FALSE");

	// Usa Numero de Sobre
	element = scew_element_add(root, "useEnvelopeNumber");
	if ([[CimGeneralSettings getInstance] getAskEnvelopeNumber])
		scew_element_set_contents(element, "TRUE");
	else
		scew_element_set_contents(element, "FALSE");

	// creo el xml con el tree
	scew_writer_tree_file(tree, XML_RESPONSE_FILE);
	scew_tree_free(tree);

	// obtengo el contenido del xml y lo guardo en myMessage
	[self getTreeBuffer: XML_RESPONSE_FILE];

}

/**/
- (void) openCash: (scew_tree*) aTree
{
	scew_tree* tree = NULL;
	scew_element* root = NULL;
	scew_element* element = NULL;
	char buf[50];
	CIM_CASH cimCash = NULL;
	CASH_REFERENCE reference = NULL;
	USER user = NULL;
	USER extendedUser = NULL;
	COLLECTION acceptors = NULL;
	id instaDrop;
	int cashId = 0;
	BOOL extended = FALSE;
	int extendedUserId = 0;
	int referenceId = 0;
	char applyTo[50];
	int	excode;
	char exceptionDescription[512];
	char envelopeNumber[50];
	int stackerQty;
	int count, iAcceptor;
	PROFILE profile = NULL;

	envelopeNumber[0] = '\0';
	applyTo[0] = '\0';

	// analizo los parametros recibidos ********
  root = scew_element_by_name(scew_tree_root(aTree), "params");
  if (root) {
		// cashId
		element =  scew_element_by_name(root, "cashId");
		if ( scew_element_contents(element) != NULL ) {
  		sprintf(buf, "%s", scew_element_contents(element));
			cashId = atoi(trim(buf));
			cimCash = [[[CimManager getInstance] getCim] getCimCashById: cashId];
		}

		// es extendido ?
		element =  scew_element_by_name(root, "extended");
		if ( scew_element_contents(element) != NULL ) {
  		sprintf(buf, "%s", scew_element_contents(element));
			extended = (strcmp(trim(buf), "TRUE") == 0);
		}

		// extendedUserId
		element =  scew_element_by_name(root, "extendedUserId");
		if ( scew_element_contents(element) != NULL ) {
  		sprintf(buf, "%s", scew_element_contents(element));
			extendedUser = [[UserManager getInstance] getUserByLoginName: buf];
			if (extendedUser)
				extendedUserId = [extendedUser getUserId];
		}

		// obtengo el usuario que va a realizar el deposito
		if ( (!extended) || (extendedUserId == 0) )
			user = [[UserManager getInstance] getUserLoggedIn];
		else user = [[UserManager getInstance] getUser: extendedUserId];

		// referenceId
		element =  scew_element_by_name(root, "referenceId");
		if ( scew_element_contents(element) != NULL ) {
  		sprintf(buf, "%s", scew_element_contents(element));
			referenceId = atoi(trim(buf));
		}

		// applyTo
		element =  scew_element_by_name(root, "applyTo");
		if ( scew_element_contents(element) != NULL )
  		sprintf(applyTo, "%s", scew_element_contents(element));
	}


	// armo el mensaje de respuesta ************
	myMessage[0] = '\0';

	tree = scew_tree_create();
	root = scew_tree_add_root(tree, XML_MESSAGE_TAG);
	element = scew_element_add(root, XML_MESSAGE_NAME);
	scew_element_set_contents(element, XML_MESSAGE_OPENVALIDATEDCASH);

	// controlo todo tipo de errores antes de iniciar deposito ******
	mySendError = FALSE;

	// verifico si el usuario que va a realizar el deposito tiene permiso de VALIDATED_DROP_OP
	if (user) {
		profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
		if (![profile hasPermission: VALIDATED_DROP_OP])
			[self concatError: root error: getResourceStringDef(RESID_USER_NOT_HAVE_PERMISSION, "El usuario no tiene permiso!") responseMsg: XML_OPENVALIDATEDCASH_ERROR];
	}

	// controlo que se haya seleccionado un cash validado
	if (!mySendError) {
		if (!cimCash)
			[self concatError: root error: getResourceStringDef(RESID_MUST_SELECT_CASH, "Debe seleccionar un cash.") responseMsg: XML_OPENVALIDATEDCASH_ERROR];
		else if ([cimCash getDepositType] != DepositType_AUTO)
					[self concatError: root error: getResourceStringDef(RESID_MUST_SELECT_VALIDATED_CASH, "Debe seleccionar un cash validado.") responseMsg: XML_OPENVALIDATEDCASH_ERROR];
	}

	// controlo que no haya un deposito validado en curso
	if ( (!mySendError) && (!extended) && (myDrop) ) {
		[self concatError: root error: getResourceStringDef(RESID_DROP_ALREADY_EXISTS, "Ya existe un deposito en curso.") responseMsg: XML_OPENVALIDATEDCASH_ERROR];
	}

	// Verifico si el cash esta en uso
	if (!mySendError) {
		if ([[CimManager getInstance] getExtendedDrop: cimCash] != NULL) {
			if (!extended)
				[self concatError: root error: getResourceStringDef(RESID_CASH_ALREADY_USE_EXTENDED, "El Cash ya se encuentra en uso por un Deposito Extendido.") responseMsg: XML_OPENVALIDATEDCASH_ERROR];
			else [self concatError: root error: getResourceStringDef(RESID_EXTENDED_DROP_IN_USE_MSG, "El deposito extendido ya se encuentra activo.") responseMsg: XML_OPENVALIDATEDCASH_ERROR];
	
		} else {
			if (extended) {
				// Verifico si ya esta asignado a un Insta Drop el cash seleccionado
				instaDrop = [[InstaDropManager getInstance] getInstaDropForCash: cimCash];
				if (instaDrop)
					[self concatError: root error: getResourceStringDef(RESID_CASH_ALREADY_USE_INSTA, "El Cash ya se encuentra en uso por un Deposito Instantaneo.") responseMsg: XML_OPENVALIDATEDCASH_ERROR];
			}
		}
	}

	// controlo que la puerta este habilitada
	if ( (!mySendError) && ([[cimCash getDoor] isDeleted]) )
		[self concatError: root error: getResourceStringDef(RESID_DISABLE_DOOR, "La puerta se encuentra deshabilitada!") responseMsg: XML_OPENVALIDATEDCASH_ERROR];

	// controlo que la puerta este cerrada
	if ( (!mySendError) && ([[cimCash getDoor] getDoorState] == DoorState_OPEN) )
		[self concatError: root error: getResourceStringDef(RESID_YOU_MUST_CLOSE_VALIDATED_DOOR, "Primero debe cerrar la puerta validada!") responseMsg: XML_OPENVALIDATEDCASH_ERROR];

	// recorro los validadores para saber si ambos estan en stacker full en cuyo caso no lo dejo hacer depositos
	if (!mySendError) {
		acceptors = [cimCash getAcceptorSettingsList];
		count = 0; // contador para saber cuantos validadores no se pueden usar
		for (iAcceptor = 0; iAcceptor < [acceptors size]; ++iAcceptor) {
			// si es stacker full incremento el contador
			stackerQty = [[[ExtractionManager getInstance] getCurrentExtraction: [[acceptors at: iAcceptor] getDoor]] getQtyByAcceptor: [acceptors at: iAcceptor]];
			if (([[acceptors at: iAcceptor] getStackerSize] != 0) && ([[acceptors at: iAcceptor] getStackerSize] <= stackerQty)) {
				count++;
			}
		}
		if ([acceptors size] == count)
			[self concatError: root error: getResourceStringDef(RESID_ACCEPTORS_DISABLED, "Validadores deshabilitados. Stackers llenos.") responseMsg: XML_OPENVALIDATEDCASH_ERROR];
	}
	

	// controlo si utiliza el reference
	if ( (!mySendError) && ([[CimGeneralSettings getInstance] getUseCashReference]) ) {
		reference = [[CashReferenceManager getInstance] getCashReferenceById: referenceId];
		if (reference == NULL) [self concatError: root error: getResourceStringDef(RESID_MUST_SELECT_REFERENCE, "Debe seleccionar un reference.") responseMsg: XML_OPENVALIDATEDCASH_ERROR];
	}

	if (!mySendError) {
		TRY
			// chequeo el estado
			[[CimManager getInstance] checkCimCashState: cimCash];
	
			// inicio el deposito
			if (!extended) {
				myDrop = [[CimManager getInstance] startDeposit: user cimCash: cimCash depositType: DepositType_AUTO];
		
				// audito el inicio del deposito validado
				[Audit auditEvent: [myDrop getUser] eventId: Event_START_VALIDATED_DROP additional: "" station: 0 logRemoteSystem: FALSE];
			
				[myDrop setCashReference: reference];
				[myDrop setEnvelopeNumber: envelopeNumber];
				[myDrop setApplyTo: applyTo];
	
			} else {
				myExtendedDrop = [[CimManager getInstance] startExtendedDrop: user cimCash: cimCash cashReference: reference envelopeNumber: envelopeNumber applyTo: applyTo];
			}

			element = scew_element_add(root, "response");
			scew_element_set_contents(element, XML_OPENVALIDATEDCASH_SUCCESS);
	
		CATCH
	
			ex_printfmt();
			excode = ex_get_code();
			// Traduzco el codigo de error a mensaje
			TRY
				[[MessageHandler getInstance] processMessage: exceptionDescription messageNumber: excode];
			CATCH
				strcpy(exceptionDescription, "");
			END_TRY
	
			[self concatError: root error: exceptionDescription responseMsg: XML_OPENVALIDATEDCASH_ERROR];
	
		END_TRY
	}

	// creo el xml con el tree
	scew_writer_tree_file(tree, XML_RESPONSE_FILE);
	scew_tree_free(tree);

	// obtengo el contenido del xml y lo guardo en myMessage
	[self getTreeBuffer: XML_RESPONSE_FILE];
}

/**/
- (void) concatError: (scew_element*) aRoot error: (char *) anError responseMsg: (char *) aResponseMsg
{
	scew_element* element = NULL;

	mySendError = TRUE;

	element = scew_element_add(aRoot, "response");
	scew_element_set_contents(element, aResponseMsg);
	element = scew_element_add(aRoot, "description");
	scew_element_set_contents(element, anError);
}

/**/
- (void) closeCash: (scew_tree*) aTree
{
	scew_tree* tree = NULL;
	scew_element* root = NULL;
	scew_element* element = NULL;
	char buf[50];
	CIM_CASH cimCash = NULL;
	int cashId = 0;
	int	excode;
	char exceptionDescription[512];
	unsigned long lastDepositNumber = 0;

	// analizo los parametros recibidos ********
  root = scew_element_by_name(scew_tree_root(aTree), "params");
  if (root) {
		// cashId
		element =  scew_element_by_name(root, "cashId");
		if ( scew_element_contents(element) != NULL ) {
  		sprintf(buf, "%s", scew_element_contents(element));
			cashId = atoi(trim(buf));
			cimCash = [[[CimManager getInstance] getCim] getCimCashById: cashId];
		}
	}

	// armo el mensaje de respuesta ************
	myMessage[0] = '\0';

	tree = scew_tree_create();
	root = scew_tree_add_root(tree, XML_MESSAGE_TAG);
	element = scew_element_add(root, XML_MESSAGE_NAME);
	scew_element_set_contents(element, XML_MESSAGE_CLOSEVALIDATEDCASH);

	// controlo todo tipo de errores antes de cerrar deposito ******
	mySendError = FALSE;

	// controlo que se haya seleccionado un cash validado
	if (!cimCash)
		[self concatError: root error: getResourceStringDef(RESID_MUST_SELECT_CASH, "Debe seleccionar un cash.") responseMsg: XML_CLOSEVALIDATEDCASH_ERROR];
	else if ([cimCash getDepositType] != DepositType_AUTO)
				 [self concatError: root error: getResourceStringDef(RESID_MUST_SELECT_VALIDATED_CASH, "Debe seleccionar un cash validado.") responseMsg: XML_CLOSEVALIDATEDCASH_ERROR];

	// verifico si existe un deposito abierto
	if (!mySendError)
		if ( (!myDrop) && (!myExtendedDrop) )
			[self concatError: root error: getResourceStringDef(RESID_NO_CASH_DROP_ASSOCIATED, "No hay depositos para cerrar.") responseMsg: XML_CLOSEVALIDATEDCASH_ERROR];

	// si es deposito extendido debo ver si existe en la lista (No deberia ocurrir nunca pero por las dudas lo controlo)
	if (!mySendError)
		if (myExtendedDrop)
			if ([[CimManager getInstance] getExtendedDrop: cimCash] == NULL)
				[self concatError: root error: "Error" responseMsg: XML_CLOSEVALIDATEDCASH_ERROR];

	// cierro el deposito correspondiente
	if (!mySendError) {
		TRY

			lastDepositNumber = [[DepositManager getInstance] getLastDepositNumber];

			// es extendido
			if (myExtendedDrop) {
				[[CimManager getInstance] endExtendedDrop: cimCash];
				myExtendedDrop = NULL;
			} else { // es validado
				[[CimManager getInstance] endDeposit];
				[self resetDrop];
			}

			element = scew_element_add(root, "response");
			scew_element_set_contents(element, XML_CLOSEVALIDATEDCASH_SUCCESS);

			// si se almaceno el deposito entonces concateno la info del mismo
			if (lastDepositNumber != [[DepositManager getInstance] getLastDepositNumber]) {
				// obtengo el ultimo deposito
				myDrop = [[[Persistence getInstance] getDepositDAO] loadLast];
				[self concatDropInfo: root drop: myDrop];
				[myDrop free];
				[self resetDrop];
			}

		CATCH
	
			ex_printfmt();
			excode = ex_get_code();
			// Traduzco el codigo de error a mensaje
			TRY
				[[MessageHandler getInstance] processMessage: exceptionDescription messageNumber: excode];
			CATCH
				strcpy(exceptionDescription, "");
			END_TRY
	
			[self concatError: root error: exceptionDescription responseMsg: XML_CLOSEVALIDATEDCASH_ERROR];
	
		END_TRY
	}

	// creo el xml con el tree
	scew_writer_tree_file(tree, XML_RESPONSE_FILE);
	scew_tree_free(tree);

	// obtengo el contenido del xml y lo guardo en myMessage
	[self getTreeBuffer: XML_RESPONSE_FILE];

}

/**/
- (void) concatDropInfo: (scew_element*) aRoot drop: (DEPOSIT) aDrop
{
	scew_element* dropDetail = NULL;
	scew_element* element = NULL;
	scew_element *elementDepositDetails;
	scew_element *elementDepositDetail;
	scew_element *elementAcceptors;
	scew_element *elementAcceptor;
	scew_element *elementCurrencyList;
	scew_element *elementCurrency;
	ACCEPTOR_SETTINGS acceptorSettings;
	COLLECTION acceptors;
	COLLECTION currencies;
	COLLECTION detailsByAcceptor;
	COLLECTION detailsByCurrency;
	CURRENCY currency;
	DEPOSIT_DETAIL depositDetail;
	int iAcceptor, iCurrency, iDetail, qtyUse;
	char buf[50];
	float usePercent;
	int totalDecimals = [[AmountSettings getInstance] getTotalRoundDecimalQty];

	dropDetail = scew_element_add(aRoot, "dropDetail");

	// numero de deposito
	element = scew_element_add(dropDetail, "dropNumber");
	sprintf(buf, "%08ld", [aDrop getNumber]);
	scew_element_set_contents(element, buf);

	// tipo de deposito
	element = scew_element_add(dropDetail, "dropType");
	sprintf(buf, "%d", [aDrop getDepositType]);
	scew_element_set_contents(element, buf);

	// id de usuario
	element = scew_element_add(dropDetail, "operatorId");
	sprintf(buf, "%05d", [[aDrop getUser] getUserId]);
	scew_element_set_contents(element, buf);

	// nombre de usuario
	element = scew_element_add(dropDetail, "operatorName");
	strcpy(buf, [aDrop getUser] != NULL ? [[aDrop getUser] str] : getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
	scew_element_set_contents(element, buf);

	// cashId
	element = scew_element_add(dropDetail, "cashId");
	sprintf(buf, "%d", [[aDrop getCimCash] getCimCashId]);
	scew_element_set_contents(element, buf);

  // Nombre del cash
  element = scew_element_add(dropDetail, "cashName");
  scew_element_set_contents(element, [[aDrop getCimCash] getName]);

	// lista de acceptadores
	acceptors = [aDrop getAcceptorSettingsList: NULL];
	elementAcceptors = scew_element_add(dropDetail, "acceptorList");

	// Recorro la lista de aceptadores
	for (iAcceptor = 0; iAcceptor < [acceptors size]; ++iAcceptor) {

		acceptorSettings = [acceptors at: iAcceptor];
		elementAcceptor = scew_element_add(elementAcceptors, "acceptor");

		// Id del aceptador
		element = scew_element_add(elementAcceptor, "acceptorId");
		sprintf(buf,"%d",[acceptorSettings getAcceptorId]);
		scew_element_set_contents(element, buf);

		// Nombre del aceptador
		element = scew_element_add(elementAcceptor, "acceptorName");
		scew_element_set_contents(element, [acceptorSettings getAcceptorName]);

		// Staker Use
		element = scew_element_add(elementAcceptor, "cassetteUse");
		qtyUse = [[[ExtractionManager getInstance] getCurrentExtraction: [acceptorSettings getDoor]] getQtyByAcceptor: acceptorSettings];

		if ([acceptorSettings getStackerSize] != 0)
				usePercent = ((float)qtyUse / (float)[acceptorSettings getStackerSize]) * 100.0;
		else usePercent = 0;

		sprintf(buf,"%4.0f %%",usePercent);
		scew_element_set_contents(element, trim(buf));

		// Obtengo la lista de detalles para el aceptador
		detailsByAcceptor = [aDrop getDetailsByAcceptor: NULL acceptorSettings: acceptorSettings];

		// Obtengo la lista de monedas utilizadas en este aceptador
		currencies = [aDrop getCurrencies: detailsByAcceptor];
		elementCurrencyList = scew_element_add(elementAcceptor, "currencyList");

		// Recorro las monedas
		for (iCurrency = 0; iCurrency < [currencies size]; ++iCurrency) {

			currency = [currencies at: iCurrency];

			// Creo el elemento moneda con los datos de la moneda y la info totalizada
			elementCurrency = scew_element_add(elementCurrencyList, "currency");
			detailsByCurrency = [aDrop getDetailsByCurrency: detailsByAcceptor currency: currency];

			element = scew_element_add(elementCurrency, "currencyCode");
			scew_element_set_contents(element, [currency getCurrencyCode]);

			element = scew_element_add(elementCurrency, "qty");
			sprintf(buf, "%d", [aDrop getQty: detailsByCurrency]);
			scew_element_set_contents(element, buf);
	
			element = scew_element_add(elementCurrency, "total");
			formatMoney(buf, "", [aDrop getAmount: detailsByCurrency], totalDecimals, 20);
			scew_element_set_contents(element, buf);
	
			elementDepositDetails = scew_element_add(elementCurrency, "denominationDetails");

			// Recorro el detalle de los depositos		
			for (iDetail = 0; iDetail < [detailsByCurrency size]; ++iDetail) {
		
				depositDetail = [detailsByCurrency at: iDetail];
				elementDepositDetail = scew_element_add(elementDepositDetails, "detail");
		
				// Cantidad
				element = scew_element_add(elementDepositDetail, "qty");
				sprintf(buf, "%d", [depositDetail getQty]);
				scew_element_set_contents(element, buf);
		
				// Importe
				element = scew_element_add(elementDepositDetail, "denomination");
				if ([depositDetail isUnknownBill]) stringcpy(buf, getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
				else formatMoney(buf, "", [depositDetail getAmount], totalDecimals, 20);
				scew_element_set_contents(element, buf);
		
				// Total
				element = scew_element_add(elementDepositDetail, "totalDenomination");
				if ([depositDetail isUnknownBill]) stringcpy(buf, getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
				else formatMoney(buf, "", [depositDetail getTotalAmount], totalDecimals, 20);
				scew_element_set_contents(element, buf);

				// Nombre del tipo de valor
				element = scew_element_add(elementDepositDetail, "dropValueName");
				scew_element_set_contents(element, [depositDetail getDepositValueName]);

			}
			[detailsByCurrency free];
		}
		[detailsByAcceptor free];
		[currencies free];
	}
	[acceptors free];

}

/**/
- (void) endOfDay: (scew_tree*) aTree
{
	scew_tree* tree = NULL;
	scew_element* root = NULL;
	scew_element* element = NULL;
	char buf[50];
	int	excode;
	char exceptionDescription[512];
	BOOL printOperatorReport = FALSE;
	ZCLOSE zclose = NULL;
	USER user = NULL;
	PROFILE profile = NULL;

	// analizo los parametros recibidos (solo si corresponde) ********
	
	// Imprime los reportes de operador ?
	if ([[CimGeneralSettings getInstance] getPrintOperatorReport] == PrintOperatorReport_ALWAYS)
		printOperatorReport = TRUE;
	else 
		if ([[CimGeneralSettings getInstance] getPrintOperatorReport] == PrintOperatorReport_ASK) {
			root = scew_element_by_name(scew_tree_root(aTree), "params");
			if (root) {
				// printOperatorReport
				element = scew_element_by_name(root, "printOperatorReport");
				if ( scew_element_contents(element) != NULL ) {
					sprintf(buf, "%s", scew_element_contents(element));
					printOperatorReport = (strcmp(trim(buf), "TRUE") == 0);
				} else printOperatorReport = TRUE;
			} else printOperatorReport = TRUE;
		}

	// armo el mensaje de respuesta ************
	myMessage[0] = '\0';

	tree = scew_tree_create();
	root = scew_tree_add_root(tree, XML_MESSAGE_TAG);
	element = scew_element_add(root, XML_MESSAGE_NAME);
	scew_element_set_contents(element, XML_MESSAGE_ENDOFDAY);

	// controlo todo tipo de errores antes de generar el cierre ******
	mySendError = FALSE;

	// verifico si el usuario tiene el permiso de GRAND_Z_REPORT_OP
	user = [[UserManager getInstance] getUserLoggedIn];
	if (user) {
		profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
		if (![profile hasPermission: GRAND_Z_REPORT_OP])
			[self concatError: root error: getResourceStringDef(RESID_USER_NOT_HAVE_PERMISSION, "El usuario no tiene permiso!") responseMsg: XML_OPENVALIDATEDCASH_ERROR];
	}

	// controlo que este habilitado el uso de end day
	if ( (!mySendError) && (![[CimGeneralSettings getInstance] getUseEndDay]) )
		[self concatError: root error: getResourceStringDef(RESID_USE_END_DAY_DISABLE, "Debe habilitar el parametro Use End Day") responseMsg: XML_ENDOFDAY_ERROR];

	// genero el cierre correspondiente
	if (!mySendError) {
		TRY

			[[ZCloseManager getInstance] generateZClose: printOperatorReport];

			element = scew_element_add(root, "response");
			scew_element_set_contents(element, "EndOfDaySuccess");

			// concateno la info del cierre diario
			// obtengo el ultimo cierre generado
			zclose = [[ZCloseManager getInstance] loadLastZClose];
			if (zclose!= NULL) {
				[self concatEndOfDayInfo: root zClose: zclose];
				[zclose free];
				zclose = NULL;
			}

		CATCH
	
			ex_printfmt();
			excode = ex_get_code();
			// Traduzco el codigo de error a mensaje
			TRY
				[[MessageHandler getInstance] processMessage: exceptionDescription messageNumber: excode];
			CATCH
				strcpy(exceptionDescription, "");
			END_TRY
	
			[self concatError: root error: exceptionDescription responseMsg: XML_ENDOFDAY_ERROR];
	
		END_TRY
	}

	// creo el xml con el tree
	scew_writer_tree_file(tree, XML_RESPONSE_FILE);
	scew_tree_free(tree);

	// obtengo el contenido del xml y lo guardo en myMessage
	[self getTreeBuffer: XML_RESPONSE_FILE];

}

/**/
- (void) concatEndOfDayInfo: (scew_element*) aRoot zClose: (ZCLOSE) aZClose
{
	scew_element* endDayDetail = NULL;
	scew_element* element = NULL;
	scew_element* elementCurrencyList = NULL;
	scew_element* elementCurrency = NULL;
	scew_element* manualDropsDetailsElement = NULL;
	scew_element* manualDropDetailElement = NULL;
	char buf[50];
  datetime_t date;
  char dateStr[50];
  struct tm brokenTime;
	ZCLOSE_DETAIL detail;
	COLLECTION details = NULL;
	COLLECTION currecies = NULL;
	COLLECTION manualDrops = NULL;
	COLLECTION validatedDrops = NULL;
	COLLECTION detailsByCurrency = NULL;
	CURRENCY currency;
	int iDetail, iCurrency;
	int totalDecimals = [[AmountSettings getInstance] getTotalRoundDecimalQty];

	endDayDetail = scew_element_add(aRoot, "endDayDetail");

	// numero de cierre
	element = scew_element_add(endDayDetail, "endDayNumber");
	sprintf(buf, "%08ld", [aZClose getNumber]);
	scew_element_set_contents(element, buf);

  // Fecha / hora de la apertura
  date = [aZClose getOpenTime];
	localtime_r(&date, &brokenTime);
	strftime(dateStr, 50, [[RegionalSettings getInstance] getDateTimeFormatString], &brokenTime);
  element = scew_element_add(endDayDetail, "fromDay");
  scew_element_set_contents(element, dateStr);

  // Fecha / hora del cierre
  date = [aZClose getCloseTime];
	localtime_r(&date, &brokenTime);
	strftime(dateStr, 50, [[RegionalSettings getInstance] getDateTimeFormatString], &brokenTime);
  element = scew_element_add(endDayDetail, "toDay");
  scew_element_set_contents(element, dateStr);

  // Desde deposito
  element = scew_element_add(endDayDetail, "fromDrop");
  sprintf(buf, "%08ld", [aZClose getFromDepositNumber]);
  scew_element_set_contents(element, buf);

  // Hasta deposito
  element = scew_element_add(endDayDetail, "toDrop");
  sprintf(buf, "%08ld", [aZClose getToDepositNumber]);
  scew_element_set_contents(element, buf);

	// id de usuario
	element = scew_element_add(endDayDetail, "operatorId");
	sprintf(buf, "%05d", [[aZClose getUser] getUserId]);
	scew_element_set_contents(element, buf);

	// nombre de usuario
	element = scew_element_add(endDayDetail, "operatorName");
	strcpy(buf, [aZClose getUser] != NULL ? [[aZClose getUser] str] : getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
	scew_element_set_contents(element, buf);

	// lista detalles
	details = [aZClose getZCloseDetailsSummary];

	// Obtengo la lista de monedas
	currecies = [aZClose getCurrencies: details];
	if ([currecies size] > 0) {
		elementCurrencyList = scew_element_add(endDayDetail, "currencyList");

		// Recorro la lista de monedas
		for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {
	
			currency = [currecies at: iCurrency];
			
			detailsByCurrency = [aZClose getDetailsByCurrency: details currency: currency];
			manualDrops = [aZClose getManualDetails: detailsByCurrency];
			validatedDrops = [aZClose getValidatedDetails: detailsByCurrency];
			
			elementCurrency = scew_element_add(elementCurrencyList, "currency");
	
			element = scew_element_add(elementCurrency, "currencyCode");
			scew_element_set_contents(element, [currency getCurrencyCode]);
		
			element = scew_element_add(elementCurrency, "totalManualDrop");
			formatMoney(buf, "", [aZClose getTotalAmount: manualDrops], totalDecimals, 20);
			scew_element_set_contents(element, buf);
		
			element = scew_element_add(elementCurrency, "totalValidatedDrop");
			formatMoney(buf, "", [aZClose getTotalAmount: validatedDrops], totalDecimals, 20);
			scew_element_set_contents(element, buf);
				
			element = scew_element_add(elementCurrency, "total");
			formatMoney(buf, "", [aZClose getTotalAmount: detailsByCurrency], totalDecimals, 20);
			scew_element_set_contents(element, buf);

			if ([manualDrops size] > 0) {
				manualDropsDetailsElement = scew_element_add(elementCurrency, "manualDropDetails");

				for (iDetail = 0; iDetail < [manualDrops size]; ++iDetail) {

					detail = [manualDrops at: iDetail];
					manualDropDetailElement = scew_element_add(manualDropsDetailsElement, "manualDropDetail");
		
					// Cantidad
					element = scew_element_add(manualDropDetailElement, "qty");
					sprintf(buf, "%d" , [detail getQty]);
					scew_element_set_contents(element, buf);
			
					// Total
					element = scew_element_add(manualDropDetailElement, "totalValue");
					formatMoney(buf, "", [detail getTotalAmount], totalDecimals, 20);
					scew_element_set_contents(element, buf);
		
					// Nombre del tipo de valor
					element = scew_element_add(manualDropDetailElement, "dropValueName");
					scew_element_set_contents(element, [detail getDepositValueName]);
				}
			}

			[detailsByCurrency free];
			[validatedDrops free];		
			[manualDrops free];
		}
	}

	[currecies free];
  [details freePointers];
  [details free];
}

/**/
- (void) dropsReport: (scew_tree*) aTree
{
	scew_tree* tree = NULL;
	scew_element* root = NULL;
	scew_element* element = NULL;
	scew_element* dropsElement = NULL;
	char buf[50];
	BOOL last = TRUE;
	unsigned long fromDrop = 1;
	unsigned long toDrop = 1;
	BOOL print = FALSE;
	int	excode;
	char exceptionDescription[512];
	int i;
	BOOL dropsOk;
	USER user = NULL;
	PROFILE profile = NULL;

	// analizo los parametros recibidos ********
  root = scew_element_by_name(scew_tree_root(aTree), "params");
  if (root) {

		// ultimo ?
		element =  scew_element_by_name(root, "last");
		if ( scew_element_contents(element) != NULL ) {
  		sprintf(buf, "%s", scew_element_contents(element));
			last = (strcmp(trim(buf), "TRUE") == 0);
		}

		if (!last) {
			// Desde deposito
			element =  scew_element_by_name(root, "fromDrop");
			if ( scew_element_contents(element) != NULL ) {
				sprintf(buf, "%s", scew_element_contents(element));
				if (strlen(buf) > 0)
					fromDrop = atol(trim(buf));
			}
			if (fromDrop <= 0) fromDrop = 1;

			// Hasta deposito
			element =  scew_element_by_name(root, "toDrop");
			if ( scew_element_contents(element) != NULL ) {
				sprintf(buf, "%s", scew_element_contents(element));
				if (strlen(buf) > 0)
					toDrop = atol(trim(buf));
			}
			if (toDrop <= 0) toDrop = 1;
		}

		// imprimir ?
		element =  scew_element_by_name(root, "print");
		if ( scew_element_contents(element) != NULL ) {
  		sprintf(buf, "%s", scew_element_contents(element));
			print = (strcmp(trim(buf), "TRUE") == 0);
		}
	}

	// armo el mensaje de respuesta ************
	myMessage[0] = '\0';

	tree = scew_tree_create();
	root = scew_tree_add_root(tree, XML_MESSAGE_TAG);
	element = scew_element_add(root, XML_MESSAGE_NAME);
	scew_element_set_contents(element, XML_MESSAGE_DROPSREPORT);

	// controlo todo tipo de errores antes de generar el reporte de deposito ******
	mySendError = FALSE;

	// verifico si el usuario tiene el permiso de REPRINT_DROP_OP
	user = [[UserManager getInstance] getUserLoggedIn];
	if (user) {
		profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
		if (![profile hasPermission: REPRINT_DROP_OP])
			[self concatError: root error: getResourceStringDef(RESID_USER_NOT_HAVE_PERMISSION, "El usuario no tiene permiso!") responseMsg: XML_OPENVALIDATEDCASH_ERROR];
	}

	// controlo que el rango sea correcto
	if ( (!mySendError) && (!last) ) {
		if ( fromDrop > toDrop )
			[self concatError: root error: getResourceStringDef(RESID_INVALID_RANGE_DROP, "Rango invalido.") responseMsg: "Error"];
		
		if ( (!mySendError) && ((toDrop - fromDrop + 1) > 5) )
			[self concatError: root error: getResourceStringDef(RESID_BIG_RANGE_DROP, "Cantidad rango maximo = 5.") responseMsg: "Error"];
	}

	// genero el reporte
	if (!mySendError) {
		TRY
			// solo el ultimo
			if (last) {
				// obtengo el ultimo deposito
				myDrop = [[[Persistence getInstance] getDepositDAO] loadLast];
				if (myDrop) {
					element = scew_element_add(root, "response");
					scew_element_set_contents(element, "Ok");

					dropsElement = scew_element_add(root, "drops");

					// concateno la info del deposito
					[self concatDropInfo: dropsElement drop: myDrop];

					// mando a imprimir si corresponde
					if (print) [self printDrop: myDrop];

					[myDrop free];
					[self resetDrop];

				} else [self concatError: root error: getResourceStringDef(RESID_INEXISTENT_DROP, "No hay depositos.") responseMsg: "Error"];

			} else {
				// recorro los depositos del rango
				dropsOk = FALSE;
				for (i = fromDrop; i<= toDrop; i++) {
					myDrop = [[[Persistence getInstance] getDepositDAO] loadById: i];
					if (myDrop) {

						if (!dropsOk) {
							element = scew_element_add(root, "response");
							scew_element_set_contents(element, "Ok");

							dropsElement = scew_element_add(root, "drops");
							dropsOk = TRUE;
						}

						// concateno la info del deposito
						[self concatDropInfo: dropsElement drop: myDrop];

						// mando a imprimir si corresponde
						if (print) [self printDrop: myDrop];

						[myDrop free];
						[self resetDrop];
					}
				}
				if (!dropsOk) [self concatError: root error: getResourceStringDef(RESID_INEXISTENT_DROP, "No hay depositos.") responseMsg: "Error"];
			}

		CATCH
	
			ex_printfmt();
			excode = ex_get_code();
			// Traduzco el codigo de error a mensaje
			TRY
				[[MessageHandler getInstance] processMessage: exceptionDescription messageNumber: excode];
			CATCH
				strcpy(exceptionDescription, "");
			END_TRY
	
			[self concatError: root error: exceptionDescription responseMsg: "Error"];
	
		END_TRY
	}

	// creo el xml con el tree
	scew_writer_tree_file(tree, XML_RESPONSE_FILE);
	scew_tree_free(tree);

	// obtengo el contenido del xml y lo guardo en myMessage
	[self getTreeBuffer: XML_RESPONSE_FILE];

}

/**/
- (void) printDrop: (DEPOSIT) aDrop
{
	scew_tree* treePrint = NULL;
	DepositReportParam depositParam;
	char additional[21];

	depositParam.auditDateTime = [SystemTime getLocalTime];
	sprintf(additional, "%s %ld", getResourceStringDef(RESID_DROP_DESC, "Deposito"), [aDrop getNumber]);
	depositParam.auditNumber = [Audit auditEventCurrentUserWithDate: Event_DROP_RECEIPT_REPRINT 
		additional: additional station: 0 datetime: depositParam.auditDateTime logRemoteSystem: FALSE];	 

	treePrint = [[ReportXMLConstructor getInstance] buildXML: aDrop 
		entityType: DEPOSIT_PRT isReprint: TRUE varEntity: &depositParam];
	[[PrinterSpooler getInstance] addPrintingJob: DEPOSIT_PRT copiesQty: 1 ignorePaperOut: FALSE tree: treePrint additional: [[CimGeneralSettings getInstance] getPrintLogo]];
}

/**/
- (void) depositsReport: (scew_tree*) aTree
{
	scew_tree* tree = NULL;
	scew_element* root = NULL;
	scew_element* element = NULL;
	scew_element* depositsElement = NULL;
	char buf[50];
	BOOL last = TRUE;
	unsigned long fromDeposit = 1;
	unsigned long toDeposit = 1;
	BOOL print = FALSE;
	int	excode;
	char exceptionDescription[512];
	int i;
	BOOL depositsOk;
	EXTRACTION extraction = NULL;
	USER user = NULL;
	PROFILE profile = NULL;

	// analizo los parametros recibidos ********
  root = scew_element_by_name(scew_tree_root(aTree), "params");
  if (root) {

		// ultima ?
		element =  scew_element_by_name(root, "last");
		if ( scew_element_contents(element) != NULL ) {
  		sprintf(buf, "%s", scew_element_contents(element));
			last = (strcmp(trim(buf), "TRUE") == 0);
		}

		if (!last) {
			// Desde extraccion
			element =  scew_element_by_name(root, "fromDeposit");
			if ( scew_element_contents(element) != NULL ) {
				sprintf(buf, "%s", scew_element_contents(element));
				if (strlen(buf) > 0)
					fromDeposit = atol(trim(buf));
			}
			if (fromDeposit <= 0) fromDeposit = 1;

			// Hasta extraccion
			element =  scew_element_by_name(root, "toDeposit");
			if ( scew_element_contents(element) != NULL ) {
				sprintf(buf, "%s", scew_element_contents(element));
				if (strlen(buf) > 0)
					toDeposit = atol(trim(buf));
			}
			if (toDeposit <= 0) toDeposit = 1;
		}

		// imprimir ?
		element =  scew_element_by_name(root, "print");
		if ( scew_element_contents(element) != NULL ) {
  		sprintf(buf, "%s", scew_element_contents(element));
			print = (strcmp(trim(buf), "TRUE") == 0);
		}
	}

	// armo el mensaje de respuesta ************
	myMessage[0] = '\0';

	tree = scew_tree_create();
	root = scew_tree_add_root(tree, XML_MESSAGE_TAG);
	element = scew_element_add(root, XML_MESSAGE_NAME);
	scew_element_set_contents(element, XML_MESSAGE_DEPOSITSREPORT);

	// controlo todo tipo de errores antes de generar el reporte de extraccion ******
	mySendError = FALSE;

	// verifico si el usuario tiene el permiso de REPRINT_DEPOSIT_OP
	user = [[UserManager getInstance] getUserLoggedIn];
	if (user) {
		profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
		if (![profile hasPermission: REPRINT_DEPOSIT_OP])
			[self concatError: root error: getResourceStringDef(RESID_USER_NOT_HAVE_PERMISSION, "El usuario no tiene permiso!") responseMsg: XML_OPENVALIDATEDCASH_ERROR];
	}

	// controlo que el rango sea correcto
	if ( (!mySendError) && (!last) ) {
		if ( fromDeposit > toDeposit )
			[self concatError: root error: getResourceStringDef(RESID_INVALID_RANGE_DROP, "Rango invalido.") responseMsg: "Error"];
		
		if ( (!mySendError) && ((toDeposit - fromDeposit + 1) > 5) )
			[self concatError: root error: getResourceStringDef(RESID_BIG_RANGE_DROP, "Cantidad rango maximo = 5.") responseMsg: "Error"];
	}

	// genero el reporte
	if (!mySendError) {
		TRY
			// solo la ultima
			if (last) {
				// obtengo la ultima extraccion
				extraction = [[ExtractionManager getInstance] loadLast];
				if (extraction) {
					element = scew_element_add(root, "response");
					scew_element_set_contents(element, "Ok");

					depositsElement = scew_element_add(root, "deposits");

					// concateno la info de la extraccion
					[self concatExtractionInfo: depositsElement extraction: extraction];

					// mando a imprimir si corresponde
					if (print) [self printExtraction: extraction];

					[extraction free];
					extraction = NULL;

				} else [self concatError: root error: getResourceStringDef(RESID_INEXISTENT_EXTRACTIONS, "No hay extracciones.") responseMsg: "Error"];

			} else {
				// recorro los depositos del rango
				depositsOk = FALSE;
				for (i = fromDeposit; i<= toDeposit; i++) {
					extraction = [[ExtractionManager getInstance] loadById: i];
					if (extraction) {

						if (!depositsOk) {
							element = scew_element_add(root, "response");
							scew_element_set_contents(element, "Ok");

							depositsElement = scew_element_add(root, "deposits");
							depositsOk = TRUE;
						}

						// concateno la info de la extraccion
						[self concatExtractionInfo: depositsElement extraction: extraction];

						// mando a imprimir si corresponde
						if (print) [self printExtraction: extraction];

						[extraction free];
						extraction = NULL;
					}
				}
				if (!depositsOk) [self concatError: root error: getResourceStringDef(RESID_INEXISTENT_EXTRACTIONS, "No hay extracciones.") responseMsg: "Error"];
			}

		CATCH
	
			ex_printfmt();
			excode = ex_get_code();
			// Traduzco el codigo de error a mensaje
			TRY
				[[MessageHandler getInstance] processMessage: exceptionDescription messageNumber: excode];
			CATCH
				strcpy(exceptionDescription, "");
			END_TRY
	
			[self concatError: root error: exceptionDescription responseMsg: "Error"];
	
		END_TRY
	}

	// creo el xml con el tree
	scew_writer_tree_file(tree, XML_RESPONSE_FILE);
	scew_tree_free(tree);

	// obtengo el contenido del xml y lo guardo en myMessage
	[self getTreeBuffer: XML_RESPONSE_FILE];

}

/**/
- (void) concatExtractionInfo: (scew_element*) aRoot extraction: (EXTRACTION) anExtraction
{
	scew_element* depositDetail = NULL;
	scew_element* element = NULL;
	scew_element *extractionDetailsElement = NULL;
	scew_element *extractionDetailElement = NULL;
	scew_element *elementCimCashs = NULL;
	scew_element *elementCimCash = NULL;
	scew_element *elementAcceptor = NULL;
	scew_element *elementAcceptorList = NULL;
	scew_element *elementCurrency = NULL;
	scew_element *elementCurrencyList = NULL;
	ACCEPTOR_SETTINGS acceptorSettings;
	EXTRACTION_DETAIL extractionDetail;
	CIM_CASH cimCash;
	COLLECTION detailsByCimCash, detailsByAcceptor, detailsByCurrency;
	COLLECTION cimCashs, currecies, acceptorSettingsList;
	CURRENCY currency;
  datetime_t date;
  char dateStr[50];
  struct tm brokenTime;
	int iCash, iAcceptor, iDetail, iCurrency;
	char buf[50];
	int envelopeQty;
	BOOL hasManualCimCash = FALSE;
	BOOL hasAutoCimCash = FALSE;
	int totalDecimals = [[AmountSettings getInstance] getTotalRoundDecimalQty];

	depositDetail = scew_element_add(aRoot, "depositDetail");

	// numero de extraccion
	element = scew_element_add(depositDetail, "depositNumber");
	sprintf(buf, "%08ld", [anExtraction getNumber]);
	scew_element_set_contents(element, buf);

  // Fecha / hora de la extraccion
  date = [anExtraction getDateTime];
	localtime_r(&date, &brokenTime);
	strftime(dateStr, 50, [[RegionalSettings getInstance] getDateTimeFormatString], &brokenTime);
  element = scew_element_add(depositDetail, "date");
  scew_element_set_contents(element, dateStr);

	// id de puerta
  element = scew_element_add(depositDetail, "doorId");
	sprintf(buf, "%d", [[anExtraction getDoor] getDoorId]);
  scew_element_set_contents(element, buf);

  // Nombre de puerta
  element = scew_element_add(depositDetail, "doorName");
  scew_element_set_contents(element, [[anExtraction getDoor] getDoorName]);

	// id de usuario operador
	element = scew_element_add(depositDetail, "operatorId");
	sprintf(buf, "%05d", [[anExtraction getOperator] getUserId]);
	scew_element_set_contents(element, buf);

	// nombre de usuario operador
	element = scew_element_add(depositDetail, "operatorName");
	strcpy(buf, [anExtraction getOperator] != NULL ? [[anExtraction getOperator] str] : getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
	scew_element_set_contents(element, buf);

	// id de usuario collector
	element = scew_element_add(depositDetail, "collectorId");
	if ([anExtraction getCollector] != NULL)
		sprintf(buf, "%05d", [[anExtraction getCollector] getUserId]);
	else sprintf(buf, "%d", 0);
	scew_element_set_contents(element, buf);

	// nombre de usuario collector
	element = scew_element_add(depositDetail, "collectorName");
	strcpy(buf, [anExtraction getCollector] != NULL ? [[anExtraction getCollector] str] : getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
	scew_element_set_contents(element, buf);

  // Desde deposito
  element = scew_element_add(depositDetail, "fromDrop");
  sprintf(buf, "%08ld", [anExtraction getFromDepositNumber]);
  scew_element_set_contents(element, buf);
  
  // Hasta deposito
  element = scew_element_add(depositDetail, "toDrop");
  if ([anExtraction getToDepositNumber] == 0)
    sprintf(buf, "%08ld", [anExtraction getFromDepositNumber]);
  else
    sprintf(buf, "%08ld", [anExtraction getToDepositNumber]);
  scew_element_set_contents(element, buf);

	// lista de cashes
	elementCimCashs = scew_element_add(depositDetail, "cashes");
	cimCashs = [anExtraction getCimCashs: NULL];
  
  // Recorro la lista de cashs
	for (iCash = 0; iCash < [cimCashs size]; ++iCash) {

		cimCash = [cimCashs at: iCash];
		
		if ([cimCash getDepositType] == DepositType_MANUAL) hasManualCimCash = TRUE;
		if ([cimCash getDepositType] == DepositType_AUTO) hasAutoCimCash = TRUE;

		elementCimCash = scew_element_add(elementCimCashs, "cash");

		// Nombre de la caja
		element = scew_element_add(elementCimCash, "name");
		scew_element_set_contents(element, [cimCash getName]);

		// Tipo de caja (1 = automatica / 2 = manual)
		element = scew_element_add(elementCimCash, "cashType");
		sprintf(buf, "%d", [cimCash getDepositType]);
		scew_element_set_contents(element, buf);

		// obtengo la cantidad de sobres en el acceptor manual
		envelopeQty = 0;
		if ([cimCash getDepositType] == DepositType_MANUAL) {
			envelopeQty = [[DepositDetailReport getInstance] getTicketsCountByDepositType: [anExtraction getFromDepositNumber]
				toDepositNumber: [anExtraction getToDepositNumber] depositType: DepositType_MANUAL];

			element = scew_element_add(elementCimCash, "envelopeQty");
			sprintf(buf, "%d", envelopeQty);
			scew_element_set_contents(element, buf);
		}

		// Obtengo los depositos para el cash actual
		detailsByCimCash = [anExtraction getDetailsByCimCash: NULL cimCash: cimCash];

		// Obtengo la lista de validadores
		acceptorSettingsList = [anExtraction getAcceptorSettingsList: detailsByCimCash];
		
		elementAcceptorList = scew_element_add(elementCimCash, "acceptorList");

		// Recorro la lista de validadores
		for (iAcceptor = 0; iAcceptor < [acceptorSettingsList size]; ++iAcceptor) {

			acceptorSettings = [acceptorSettingsList at: iAcceptor];
			elementAcceptor = scew_element_add(elementAcceptorList, "acceptor");

			// Id del aceptador
			element = scew_element_add(elementAcceptor, "acceptorId");
			sprintf(buf, "%d", [acceptorSettings getAcceptorId]);
			scew_element_set_contents(element, buf);

			// Nombre del aceptador
			element = scew_element_add(elementAcceptor, "acceptorName");
			scew_element_set_contents(element, [acceptorSettings getAcceptorName]);
	
			// Obtengo la lista de detalles para el validador en curso
			detailsByAcceptor = [anExtraction getDetailsByAcceptorSettings: detailsByCimCash acceptorSettings: acceptorSettings];

			// Obtengo la lista de monedas
			currecies = [anExtraction getCurrencies: detailsByAcceptor];

			elementCurrencyList = scew_element_add(elementAcceptor, "currencyList");

			// Recorro la lista de monedas
			for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {

				currency = [currecies at: iCurrency];
				detailsByCurrency = [anExtraction getDetailsByCurrency: detailsByAcceptor currency: currency];

				elementCurrency = scew_element_add(elementCurrencyList, "currency");

				element = scew_element_add(elementCurrency, "currencyCode");
				scew_element_set_contents(element, [currency getCurrencyCode]);

				element = scew_element_add(elementCurrency, "qty");
				sprintf(buf, "%04d", [anExtraction getQty: detailsByCurrency]);
				scew_element_set_contents(element, buf);
		
				element = scew_element_add(elementCurrency, "total");
				formatMoney(buf, "", [anExtraction getTotalAmount: detailsByCurrency], totalDecimals, 20);
				scew_element_set_contents(element, buf);            
		
				extractionDetailsElement = scew_element_add(elementCurrency, "depositDetails");
			
				for (iDetail = 0; iDetail < [detailsByCurrency size]; ++iDetail) {
			
					extractionDetail = [detailsByCurrency at: iDetail];
					extractionDetailElement = scew_element_add(extractionDetailsElement, "detail");
		
					// Cantidad
					element = scew_element_add(extractionDetailElement, "qty");
					sprintf(buf, "%04d" , [extractionDetail getQty]);
					scew_element_set_contents(element, buf);
			
					// Importe
					element = scew_element_add(extractionDetailElement, "denomination");
					if ([extractionDetail isUnknownBill]) stringcpy(buf, getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
					else formatMoney(buf, "", [extractionDetail getAmount], totalDecimals, 20);
					scew_element_set_contents(element, buf);
			
					// Total
					element = scew_element_add(extractionDetailElement, "totalDenomination");
					if ([extractionDetail isUnknownBill]) stringcpy(buf, getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
					else formatMoney(buf, "", [extractionDetail getTotalAmount], totalDecimals, 20);
					scew_element_set_contents(element, buf);

					// Nombre del tipo de valor
					element = scew_element_add(extractionDetailElement, "depositValueName");
					scew_element_set_contents(element, [extractionDetail getDepositValueName]);
			
				}
				[detailsByCurrency free];
			}
			[currecies free];
			[detailsByAcceptor free];
		}
		[acceptorSettingsList free];

		elementCurrencyList = scew_element_add(elementCimCash, "totalCurrencyList");

		// Obtengo la lista de monedas para mostrar los totales por cash
		currecies = [anExtraction getCurrencies: detailsByCimCash];
		for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {
				
				currency = [currecies at: iCurrency];
				
				elementCurrency = scew_element_add(elementCurrencyList, "currency");

				element = scew_element_add(elementCurrency, "currencyCode");
				scew_element_set_contents(element, [currency getCurrencyCode]);
				
				element = scew_element_add(elementCurrency, "total");
				formatMoney(buf, "", [anExtraction getTotalAmountByCurreny: detailsByCimCash currency: currency], totalDecimals, 20);
				scew_element_set_contents(element, buf);        
		}

		[currecies free];
		[detailsByCimCash free];
	}

}

/**/
- (void) printExtraction: (EXTRACTION) anExtraction
{
	scew_tree* treePrint = NULL;
	CashReportParam cashParam;
	char additional[21];

	cashParam.cash = NULL;
	cashParam.detailReport = FALSE;

	// levanto el bag tracking
	[[[Persistence getInstance] getExtractionDAO] loadBagTrackingByExtraction: anExtraction];

	// Audito el evento
	cashParam.auditDateTime = [SystemTime getLocalTime];
	sprintf(additional, "%s %ld", getResourceStringDef(RESID_REPRINT_DEPOSIT_DESC, "Retiro"), [anExtraction getNumber]);

	cashParam.auditNumber = [Audit auditEventCurrentUserWithDate: Event_DEPOSIT_REPORT_REPRINT additional: additional station: [[anExtraction getDoor] getDoorId] datetime: cashParam.auditDateTime logRemoteSystem: FALSE];

	// si no hay bag tracking no muestro el campo BAG en el reporte
	cashParam.showBagNumber = [anExtraction hasBagTracking];

	treePrint = [[ReportXMLConstructor getInstance] buildXML: anExtraction entityType: EXTRACTION_PRT isReprint: TRUE  varEntity: &cashParam];
	[[PrinterSpooler getInstance] addPrintingJob: EXTRACTION_PRT copiesQty: 1 ignorePaperOut: FALSE tree: treePrint additional: [[CimGeneralSettings getInstance] getPrintLogo]];

	// imprimo el bag tracking solo si corresponde
	if ([anExtraction hasBagTracking]) {

		if ([self getBagTrackingMode: [anExtraction getDoor]] == BagTrackingMode_AUTO || [self getBagTrackingMode: [anExtraction getDoor]] == BagTrackingMode_MIXED) {

			[anExtraction setBagTrackingMode: BagTrackingMode_AUTO];
			treePrint = [[ReportXMLConstructor getInstance] buildXML: anExtraction entityType: BAG_TRACKING_PRT isReprint: TRUE varEntity: NULL];
			[[PrinterSpooler getInstance] addPrintingJob: BAG_TRACKING_PRT copiesQty: 1 ignorePaperOut: FALSE tree: treePrint additional: ""];
		}

		if ([self getBagTrackingMode: [anExtraction getDoor]] == BagTrackingMode_MANUAL || [self getBagTrackingMode: [anExtraction getDoor]] == BagTrackingMode_MIXED) {
			[anExtraction setBagTrackingMode: BagTrackingMode_MANUAL];
			treePrint = [[ReportXMLConstructor getInstance] buildXML: anExtraction entityType: BAG_TRACKING_PRT isReprint: TRUE varEntity: NULL];
			[[PrinterSpooler getInstance] addPrintingJob: BAG_TRACKING_PRT copiesQty: 1 ignorePaperOut: FALSE tree: treePrint additional: ""];
		}
	}

}

/**/
- (int) getBagTrackingMode: (id) aDoor
{
	id doorAcceptorSettings;
	id doorAcceptors = [aDoor getAcceptorSettingsList];
	int i;
	int bagTrackingMode = BagTrackingMode_NONE;

	for (i=0; i<[doorAcceptors size]; ++i) {
		doorAcceptorSettings = [doorAcceptors at: i];		

		if (([doorAcceptorSettings getAcceptorType] == AcceptorType_MAILBOX) && ([[CimGeneralSettings getInstance] getRemoveBagVerification])) {
			if (bagTrackingMode == BagTrackingMode_AUTO) {
				bagTrackingMode = BagTrackingMode_MIXED;
			} else {
				bagTrackingMode = BagTrackingMode_MANUAL;
			}
		}

		if (([doorAcceptorSettings getAcceptorType] == DepositType_AUTO) && ([[CimGeneralSettings getInstance] getBagTracking])) {
			if (bagTrackingMode == BagTrackingMode_MANUAL) {
				bagTrackingMode = BagTrackingMode_MIXED;
			} else {
				bagTrackingMode = BagTrackingMode_AUTO;
			}
		}

	} // for

	return bagTrackingMode;
}

/**/
- (void) endDayReport: (scew_tree*) aTree
{
	scew_tree* tree = NULL;
	scew_element* root = NULL;
	scew_element* element = NULL;
	scew_element* endDaysElement = NULL;
	ZCLOSE zclose = NULL;
	char buf[50];
	BOOL last = TRUE;
	unsigned long fromEndDay = 1;
	unsigned long toEndDay = 1;
	BOOL print = FALSE;
	int	excode;
	char exceptionDescription[512];
	int i;
	BOOL enddaysOk;
	USER user = NULL;
	PROFILE profile = NULL;

	// analizo los parametros recibidos ********
  root = scew_element_by_name(scew_tree_root(aTree), "params");
  if (root) {

		// ultimo ?
		element =  scew_element_by_name(root, "last");
		if ( scew_element_contents(element) != NULL ) {
  		sprintf(buf, "%s", scew_element_contents(element));
			last = (strcmp(trim(buf), "TRUE") == 0);
		}

		if (!last) {
			// Desde deposito
			element =  scew_element_by_name(root, "fromEndDay");
			if ( scew_element_contents(element) != NULL ) {
				sprintf(buf, "%s", scew_element_contents(element));
				if (strlen(buf) > 0)
					fromEndDay = atol(trim(buf));
			}
			if (fromEndDay <= 0) fromEndDay = 1;

			// Hasta deposito
			element =  scew_element_by_name(root, "toEndDay");
			if ( scew_element_contents(element) != NULL ) {
				sprintf(buf, "%s", scew_element_contents(element));
				if (strlen(buf) > 0)
					toEndDay = atol(trim(buf));
			}
			if (toEndDay <= 0) toEndDay = 1;
		}

		// imprimir ?
		element =  scew_element_by_name(root, "print");
		if ( scew_element_contents(element) != NULL ) {
  		sprintf(buf, "%s", scew_element_contents(element));
			print = (strcmp(trim(buf), "TRUE") == 0);
		}
	}

	// armo el mensaje de respuesta ************
	myMessage[0] = '\0';

	tree = scew_tree_create();
	root = scew_tree_add_root(tree, XML_MESSAGE_TAG);
	element = scew_element_add(root, XML_MESSAGE_NAME);
	scew_element_set_contents(element, XML_MESSAGE_ENDDAYREPORT);

	// controlo todo tipo de errores antes de generar el reporte de deposito ******
	mySendError = FALSE;

	// verifico si el usuario tiene el permiso de REPRINT_END_DAY_OP
	user = [[UserManager getInstance] getUserLoggedIn];
	if (user) {
		profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
		if (![profile hasPermission: REPRINT_END_DAY_OP])
			[self concatError: root error: getResourceStringDef(RESID_USER_NOT_HAVE_PERMISSION, "El usuario no tiene permiso!") responseMsg: XML_OPENVALIDATEDCASH_ERROR];
	}

	// controlo que el rango sea correcto
	if ( (!mySendError) && (!last) ) {
		if ( fromEndDay > toEndDay )
			[self concatError: root error: getResourceStringDef(RESID_INVALID_RANGE_DROP, "Rango invalido.") responseMsg: "Error"];
		
		if ( (!mySendError) && ((toEndDay - fromEndDay + 1) > 5) )
			[self concatError: root error: getResourceStringDef(RESID_BIG_RANGE_DROP, "Cantidad rango maximo = 5.") responseMsg: "Error"];
	}

	// controlo que este habilitado el uso de end day
	if ( (!mySendError) && (![[CimGeneralSettings getInstance] getUseEndDay]) )
		[self concatError: root error: getResourceStringDef(RESID_USE_END_DAY_DISABLE, "Debe habilitar el parametro Use End Day") responseMsg: "Error"];

	// genero el reporte
	if (!mySendError) {
		TRY
			// solo el ultimo
			if (last) {
				// obtengo el ultimo deposito
				zclose = [[ZCloseManager getInstance] loadLastZClose];
				if (zclose) {
					element = scew_element_add(root, "response");
					scew_element_set_contents(element, "Ok");

					endDaysElement = scew_element_add(root, "endDays");

					// concateno la info del deposito
					[self concatEndOfDayInfo: endDaysElement zClose: zclose];

					// mando a imprimir si corresponde
					if (print) [self printEndDay: zclose];

					[zclose free];
					zclose = NULL;

				} else [self concatError: root error: getResourceStringDef(RESID_INEXISTENT_ENDDAYS, "No hay cierres diarios.") responseMsg: "Error"];

			} else {
				// recorro los depositos del rango
				enddaysOk = FALSE;
				for (i = fromEndDay; i<= toEndDay; i++) {
					zclose = [[ZCloseManager getInstance] loadZCloseById: i];
					if (zclose) {

						if (!enddaysOk) {
							element = scew_element_add(root, "response");
							scew_element_set_contents(element, "Ok");

							endDaysElement = scew_element_add(root, "endDays");
							enddaysOk = TRUE;
						}

						// concateno la info del deposito
						[self concatEndOfDayInfo: endDaysElement zClose: zclose];
	
						// mando a imprimir si corresponde
						if (print) [self printEndDay: zclose];

						[zclose free];
						zclose = NULL;
					}
				}
				if (!enddaysOk) [self concatError: root error: getResourceStringDef(RESID_INEXISTENT_ENDDAYS, "No hay cierres diarios.") responseMsg: "Error"];
			}

		CATCH
	
			ex_printfmt();
			excode = ex_get_code();
			// Traduzco el codigo de error a mensaje
			TRY
				[[MessageHandler getInstance] processMessage: exceptionDescription messageNumber: excode];
			CATCH
				strcpy(exceptionDescription, "");
			END_TRY
	
			[self concatError: root error: exceptionDescription responseMsg: "Error"];
	
		END_TRY
	}

	// creo el xml con el tree
	scew_writer_tree_file(tree, XML_RESPONSE_FILE);
	scew_tree_free(tree);

	// obtengo el contenido del xml y lo guardo en myMessage
	[self getTreeBuffer: XML_RESPONSE_FILE];

}

/**/
- (void) printEndDay: (ZCLOSE) aZClose
{
	scew_tree* treePrint = NULL;
	ZCloseReportParam param;
	datetime_t auditDateTime;
	unsigned long auditNumber;
	char additional[21];

	// Audito el evento
	sprintf(additional, "%s %ld", getResourceStringDef(RESID_REPRINT_Z_DESC, "Z"), [aZClose getNumber]);
	auditDateTime = [SystemTime getLocalTime];
	auditNumber = [Audit auditEventCurrentUserWithDate: Event_GRAND_Z_REPRINT additional: additional station: 0 datetime: auditDateTime logRemoteSystem: FALSE];

	param.user = NULL;
	param.includeDetails = FALSE;
	param.auditNumber = auditNumber;
	param.auditDateTime = auditDateTime;

	// Genero el reporte  
	treePrint = [[ReportXMLConstructor getInstance] buildXML: aZClose entityType: CIM_ZCLOSE_PRT isReprint: TRUE varEntity: &param];
	[[PrinterSpooler getInstance] addPrintingJob: CIM_ZCLOSE_PRT copiesQty: 1 ignorePaperOut: FALSE tree: treePrint additional: [[CimGeneralSettings getInstance] getPrintLogo]];
}

/**/
- (void) openManualCash: (scew_tree*) aTree
{
	scew_tree* tree = NULL;
	scew_tree* treePrint = NULL;
	scew_element* root = NULL;
	scew_element* element = NULL;
	scew_element* valueElement = NULL;
	scew_element** listValues;
	char buf[50];
	CIM_CASH cimCash = NULL;
	CASH_REFERENCE reference = NULL;
	USER user = NULL;
	PROFILE profile = NULL;
	ACCEPTOR_SETTINGS acceptorSettings = NULL;
	DEPOSIT deposit = NULL;
	DEPOSIT_DETAIL detail = NULL;
	COLLECTION depositDetails = [Collection new];
	ACCEPTED_DEPOSIT_VALUE acceptedDepositValue = NULL;
	ACCEPTED_CURRENCY acceptedCurrency = NULL;
	CURRENCY currency = NULL;
	EXTRACTION extraction = NULL;
	int stackerQty = 0;
	int qty = 1;
	money_t amount = 0;
	int cashId = 0;
	int acceptorId = 0;
	int referenceId = 0;
	char applyTo[50];
	int	excode;
	char exceptionDescription[512];
	char envelopeNumber[50];
	int valueId, iValues;
	int currencyId;
	int itemsQty;
	BOOL errorInValues = FALSE;

	envelopeNumber[0] = '\0';
	applyTo[0] = '\0';

	// analizo los parametros recibidos ********
  root = scew_element_by_name(scew_tree_root(aTree), "params");
  if (root) {
		// cashId
		element = scew_element_by_name(root, "cashId");
		if ( scew_element_contents(element) != NULL ) {
  		sprintf(buf, "%s", scew_element_contents(element));
			cashId = atoi(trim(buf));
			cimCash = [[[CimManager getInstance] getCim] getCimCashById: cashId];
		}

		// referenceId
		element = scew_element_by_name(root, "referenceId");
		if ( scew_element_contents(element) != NULL ) {
  		sprintf(buf, "%s", scew_element_contents(element));
			referenceId = atoi(trim(buf));
		}

		// applyTo
		element = scew_element_by_name(root, "applyTo");
		if ( scew_element_contents(element) != NULL )
  		sprintf(applyTo, "%s", scew_element_contents(element));

		// envelopeNumber
		element = scew_element_by_name(root, "envelopeNumber");
		if ( scew_element_contents(element) != NULL )
  		sprintf(envelopeNumber, "%s", scew_element_contents(element));

		// acceptorId
		element = scew_element_by_name(root, "acceptorId");
		if ( scew_element_contents(element) != NULL ) {
  		sprintf(buf, "%s", scew_element_contents(element));
			acceptorId = atoi(trim(buf));
			acceptorSettings = [[[CimManager getInstance] getCim] getAcceptorSettingsById: acceptorId];
		}

		// cargo los valores recibidos
		element = scew_element_by_name(root, "insertedValues");
		if (element) {

			listValues = scew_element_list(element, "value", &itemsQty);

			// por cada valor
			for (iValues=0; iValues<itemsQty; ++iValues) {
	
				// id del valor
				valueElement = scew_element_by_name(listValues[iValues], "valueId");
				sprintf(buf, "%s", scew_element_contents(valueElement));
				valueId = atoi(trim(buf));
				if (valueId <= 1) valueId = 2; // por las dudas que se equivoquen y manden el valor cash del validado
				acceptedDepositValue = [acceptorSettings getAcceptedDepositValueByType: valueId];
					
				// id de la moneda
				valueElement = scew_element_by_name(listValues[iValues], "currencyId");
				sprintf(buf, "%s", scew_element_contents(valueElement));
				currencyId = atoi(trim(buf));
				// traigo la moneda del accepted currency
				if (acceptedDepositValue)
					acceptedCurrency = [acceptedDepositValue getAcceptedCurrencyByCurrencyId: currencyId];
				else acceptedCurrency = NULL;

				if (acceptedCurrency)
					currency = [acceptedCurrency getCurrency];
				else currency = NULL;
	
				// cantidad
				valueElement = scew_element_by_name(listValues[iValues], "qty");
				sprintf(buf, "%s", scew_element_contents(valueElement));
				qty = atoi(trim(buf));
	
				// cantidad
				valueElement = scew_element_by_name(listValues[iValues], "amount");
				sprintf(buf, "%s", scew_element_contents(valueElement));
				amount = stringToMoney(trim(buf));

				if ( (acceptedDepositValue) && (currency) ) {
					// creo un detalle
					detail = [DepositDetail new];
					[detail setDepositValueType: [acceptedDepositValue getDepositValueType]];
					[detail setCurrency: currency];
					[detail setQty: qty];
					[detail setAmount: amount];
					[detail setAcceptorSettings: acceptorSettings];
					[depositDetails add: detail];
				} else errorInValues = TRUE;
			}
		} else errorInValues = TRUE;

	}

	// armo el mensaje de respuesta ************
	myMessage[0] = '\0';

	tree = scew_tree_create();
	root = scew_tree_add_root(tree, XML_MESSAGE_TAG);
	element = scew_element_add(root, XML_MESSAGE_NAME);
	scew_element_set_contents(element, XML_MESSAGE_OPENMANUALCASH);

	// controlo todo tipo de errores antes de iniciar deposito ******
	mySendError = FALSE;

	// obtengo el usuario que va a realizar el deposito
	user = [[UserManager getInstance] getUserLoggedIn];

	// verifico si el usuario que va a realizar el deposito tiene permiso de MANUAL_DROP_OP
	if (user) {
		profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
		if (![profile hasPermission: MANUAL_DROP_OP])
			[self concatError: root error: getResourceStringDef(RESID_USER_NOT_HAVE_PERMISSION, "El usuario no tiene permiso!") responseMsg: XML_OPENVALIDATEDCASH_ERROR];
	}

	// controlo que se haya seleccionado un cash validado
	if (!mySendError) {
		if (!cimCash)
			[self concatError: root error: getResourceStringDef(RESID_MUST_SELECT_CASH, "Debe seleccionar un cash.") responseMsg: XML_OPENMANUALCASH_ERROR];
		else if ([cimCash getDepositType] != DepositType_MANUAL)
					[self concatError: root error: getResourceStringDef(RESID_MUST_SELECT_MANUAL_CASH, "Debe seleccionar un cash manual.") responseMsg: XML_OPENMANUALCASH_ERROR];
	}

	// controlo que no haya un deposito validado en curso
	if ( (!mySendError) && (myDrop) ) {
		[self concatError: root error: getResourceStringDef(RESID_DROP_ALREADY_EXISTS, "Ya existe un deposito en curso.") responseMsg: XML_OPENMANUALCASH_ERROR];
	}

	// controlo que la puerta este habilitada
	if ( (!mySendError) && ([[cimCash getDoor] isDeleted]) )
		[self concatError: root error: getResourceStringDef(RESID_DISABLE_DOOR, "La puerta se encuentra deshabilitada!") responseMsg: XML_OPENMANUALCASH_ERROR];

	// controlo que la puerta este cerrada
	if ( (!mySendError) && ([[cimCash getDoor] getDoorState] == DoorState_OPEN) )
		[self concatError: root error: getResourceStringDef(RESID_YOU_MUST_CLOSE_MANUAL_DOOR, "Primero debe cerrar la puerta manual!") responseMsg: XML_OPENMANUALCASH_ERROR];

	// controlo si utiliza el reference
	if ( (!mySendError) && ([[CimGeneralSettings getInstance] getUseCashReference]) ) {
		reference = [[CashReferenceManager getInstance] getCashReferenceById: referenceId];
		if (reference == NULL) [self concatError: root error: getResourceStringDef(RESID_MUST_SELECT_REFERENCE, "Debe seleccionar un reference.") responseMsg: XML_OPENMANUALCASH_ERROR];
	}

	// verifico si el acceptor corresponde con el cash manual
	if ( (!mySendError) && (![cimCash hasAcceptorSettings: acceptorSettings]) )
		[self concatError: root error: getResourceStringDef(RESID_INVALID_ACCEPTOR, "Wrong acceptor.") responseMsg: XML_OPENMANUALCASH_ERROR];

	// si el buzon tiene el stacker full no lo dejo hacer depositos manuales
	if (!mySendError) {
		extraction = [[ExtractionManager getInstance] getCurrentExtraction: [acceptorSettings getDoor]];
		stackerQty = [extraction getCurrentManualDepositCount];
		if ( ([acceptorSettings getStackerSize] != 0) && ([acceptorSettings getStackerSize] <= stackerQty) )
			[self concatError: root error: getResourceStringDef(RESID_STACKER_FULL_MANUAL_DROP, "No puede hacer depositos manuales con el Stacker Lleno!") responseMsg: XML_OPENMANUALCASH_ERROR];
	}

	// verifico si algun parametro de valor tuvo errores
	if ( (!mySendError) && (errorInValues) )
		[self concatError: root error: getResourceStringDef(RESID_WRONG_VALUES, "Valores erroneos.") responseMsg: XML_OPENMANUALCASH_ERROR];

	// verifico si hay valores
	if ( (!mySendError) && ([depositDetails size] == 0) )
		[self concatError: root error: getResourceStringDef(RESID_MUST_INSERT_VALUES, "Debe ingresar valores.") responseMsg: XML_OPENMANUALCASH_ERROR];


	if (!mySendError) {
		TRY

			// si el stacker esta casi lleno le mando un evento de advertencia.
			if ( ([acceptorSettings getStackerWarningSize] != 0) && ([acceptorSettings getStackerWarningSize] <= stackerQty) )
				[self cassetteAlmostFullEvent: [acceptorSettings getAcceptorId] acceptorName: [acceptorSettings getAcceptorName]];

			// chequeo el estado
			[[CimManager getInstance] checkCimCashState: cimCash];

			// marco el comienzo del deposito
			[[CimManager getInstance] setInManualDropState: TRUE];

			// audito el inicio del deposito manual
			[Audit auditEventCurrentUser: Event_START_MANUAL_DROP additional: "" station: 0 logRemoteSystem: FALSE];
	
			// genero el deposito manual temporal
			deposit = [[DepositManager getInstance] getNewDeposit: user cimCash: cimCash depositType: DepositType_MANUAL];
			[deposit setEnvelopeNumber: envelopeNumber];
			[deposit setApplyTo: applyTo];
			[deposit setCashReference: reference];
			[self addDepositDetails: deposit depositDetails: depositDetails];
		
			// Imprimo el comprobante
			// Genero el comprobante del deposito que va en el sobre
			treePrint = [[ReportXMLConstructor getInstance] buildXML: deposit entityType: MANUAL_DEPOSIT_RECEIPT_PRT isReprint: FALSE];
			[[PrinterSpooler getInstance] addPrintingJob: DEPOSIT_PRT copiesQty: 1 ignorePaperOut: FALSE tree: treePrint additional: [[CimGeneralSettings getInstance] getPrintLogo]];
		
			// Libero el deposito anterior (era temporal)
			[deposit free];

			// Genero el deposito real
			deposit = [[CimManager getInstance] startDeposit: cimCash depositType: DepositType_MANUAL];
			[deposit setEnvelopeNumber: envelopeNumber];
			[deposit setApplyTo: applyTo];
			[deposit setCashReference: reference];
			[self addDepositDetails: deposit depositDetails: depositDetails];
		
			// Finalizo el deposito (se graba e imprime)
			[[CimManager getInstance] endDeposit];

			// marco el fin del deposito
			[[CimManager getInstance] setInManualDropState: FALSE];

			element = scew_element_add(root, "response");
			scew_element_set_contents(element, XML_OPENMANUALCASH_SUCCESS);

			// si luego del deposito manual el stacker esta lleno le mando el evento. (stackerQty+1 <- le sumo el sobre que se acaba de ingresar)
			if ( ([acceptorSettings getStackerSize] != 0) && ([acceptorSettings getStackerSize] <= stackerQty+1) )
				[self cassetteFullEvent: [acceptorSettings getAcceptorId] acceptorName: [acceptorSettings getAcceptorName]];
	
		CATCH
	
			ex_printfmt();
			excode = ex_get_code();
			// Traduzco el codigo de error a mensaje
			TRY
				[[MessageHandler getInstance] processMessage: exceptionDescription messageNumber: excode];
			CATCH
				strcpy(exceptionDescription, "");
			END_TRY
	
			[self concatError: root error: exceptionDescription responseMsg: XML_OPENMANUALCASH_ERROR];
	
		END_TRY
	}

	// creo el xml con el tree
	scew_writer_tree_file(tree, XML_RESPONSE_FILE);
	scew_tree_free(tree);

	// obtengo el contenido del xml y lo guardo en myMessage
	[self getTreeBuffer: XML_RESPONSE_FILE];
}

/**/
- (void) addDepositDetails: (DEPOSIT) aDeposit depositDetails: (COLLECTION) aDepositDetails
{
	int i;
	DEPOSIT_DETAIL detail;

	// Agrego la lista de items al deposito
	for (i = 0; i < [aDepositDetails size]; ++i) {

		detail = [aDepositDetails at: i];

		[aDeposit addDepositDetail: [detail getAcceptorSettings]
			depositValueType: [detail getDepositValueType]
			currency: [detail getCurrency]
			qty: [detail getQty]
			amount: [detail getAmount]];
	}

}

@end
