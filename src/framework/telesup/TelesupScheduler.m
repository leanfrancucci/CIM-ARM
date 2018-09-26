/**
 *	@todo: refactorizar, la conexion deberia efectuarla otro objeto, no es responsabilidad del scheduler.
 *
 */
#include "TelesupScheduler.h"
#include "TelesupFactory.h"
#include "TelesupSettings.h"
#include "TelesupervisionManager.h"
#include "ConnectionSettings.h"
#include "TelesupD.h"
#include "Modem.h"
#include "SystemTime.h"
#include "system/util/all.h"
#include "system/net/all.h"
#include "system/CtSystem.h"
#include "CtSystem.h"
#include "Configuration.h"
#include "CommercialState.h"
#include "PrinterSpooler.h"
#include "SystemTime.h"
#include "Audit.h"
#include "Event.h"
#include "DummyTelesupViewer.h"
#include "Event.h"
#include "MessageHandler.h"
#include "RepairOrder.h"

#include "SSLClientSocket.h"

#include "Acceptor.h"
#include "CimManager.h"
#include "CommercialStateMgr.h"
#include "CimBackup.h"
#include "TelesupTest.h"
#include "FTPSupervision.h"
#include "UserManager.h"



//#define printf(args...) doLog(0,args)
#define printd(args...)

#define CHECK_TELESUP_TIME 60000		// 60 segundos
//#define CHECK_TELESUP_TIME 10000		// 10 segundos

@implementation TelesupScheduler

- (BOOL) canStartTelesupWithNewSchema: (id) aTelesup;
- (BOOL) checkInFrame: (datetime_t) aCurrentDTime supDTime: (datetime_t) aSupDTime frame: (int) aFrame;
- (BOOL) checkInEmergencyBand: (int) aFromHour toHour: (int) aToHour
                               frame: (int) aFrame attemptsMinutes: (int) anAttemptsMinutes 
                               currentHour: (int) aCurrentHour currentMinute: (int) aCurrentMinute;
- (void) startTelesup: (TELESUP_SETTINGS) aTelesup getCurrentSettings: (BOOL) aGetCurrentSettings
	telesupViewer: (TELESUP_VIEWER) aTelesupViewer;
                              

static TELESUP_SCHEDULER singleInstance = NULL;

// Metodos privados
- (TELESUP_SETTINGS) getMainTelesup;

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [[super new] initialize];
	return singleInstance;
}

/**/
- initialize
{
	// Saco un numero al azar para ver en que minuto comienza a supervisar
	sysRandomize();
	randMinutes = sysRandom(0, 59);
	inTelesup = FALSE;
	firstTelesup = TRUE;
	myCommunicationIntention = CommunicationIntention_TELESUP;
	myShutdownApp = FALSE;
	myIsManual = FALSE;
	myIsSchedule = FALSE;
	currentTelesup = NULL;
	myIsInBackground = FALSE;
	myBackgTelesupList = [Collection new];
	myMutex = [OMutex new];

	return self;
}

/**/
+ getInstance
{
	return [self new];
}

/**/
- (void) setTelesupViewer: (TELESUP_VIEWER) aTelesupViewer
{
	telesupViewer = aTelesupViewer;
	printd("telesupViewer is %p\n", telesupViewer);
}

/**/
- (void) printSettings: (TELESUP_SETTINGS) aTelesup
{
	datetime_t now = [SystemTime getLocalTime];
	struct tm btNow;
	[SystemTime decodeTime: now brokenTime: &btNow];
	
	printd("Telesup Id : %d\n", [aTelesup getTelesupId]);
	printd("Frecuencia : %d dias\n", [aTelesup getTelesupFrequency]);
//	printd("Ultimo intento: %s\n", formatDateTime([aTelesup getLastAttemptDateTime], datestr));
//	printd("Ultimo exitosa: %s\n", formatDateTime([aTelesup getLastSuceedTelesupDateTime], datestr));
	printd("Banda desde: %d\n", [aTelesup getFromHour]);
	printd("Banda hasta: %d\n", [aTelesup getToHour]);
	printd("Minutos (random): %d\n", randMinutes);
	printd("Hora actual: %d\n", btNow.tm_hour);
	printd("Min  actual: %d\n", btNow.tm_min);
}

/**
 *	Obtengo la supervision principal.
 *	Por ahora lo hago comparando el tipo de version (Delsat, Telefonica, Telecom) conexion
 *	el tipo de supervision (Delsat, Telefonica, Telecom).
 *	p.e: si el tipo de version es Telecom, la telesupervision principal deberia ser Telecom.
 *	@private
 */
- (TELESUP_SETTINGS) getMainTelesup
{
	COLLECTION telesups;
	TELESUP_SETTINGS telesup;	
	int i;

	telesups = [[TelesupervisionManager getInstance] getTelesups];

	for (i = 0; i < [telesups size]; ++i) 	{

		telesup = [telesups at: i];

    if ([telesup getTelcoType] == PIMS_TSUP_ID) {
      return telesup;
    }

	}

	return NULL;
	
}

/**
 * Verifica que la hora actual se encuentre dentro de la fecha y hora de 
 *  supervision y dentro del marco especificado. 
 */
- (BOOL) checkInFrame: (datetime_t) aCurrentDTime supDTime: (datetime_t) aSupDTime frame: (int) aFrame
{
  printd("checkInFrame -> Verifica que la fecha actual se encuentre dentro de la franja de supervision\n");
  printd("frame = %d\n", aFrame);
  printd("aCurrentDateTime = %ld\n", aCurrentDTime);
  printd("aSupDTime = %ld\n", aSupDTime);
  
  // Setearon la fecha y hora de supervision en cero.
  if (aSupDTime == 0) return FALSE;
  
  // Verifica que la fecha actual se encuentre dentro del marco definido en minutos.
  if ((aCurrentDTime >= aSupDTime) && ((aCurrentDTime - aSupDTime) <= aFrame * 60)) return TRUE;

  printd("La fecha actual no se encuentra en la franja de supervision\n");  
  
  return FALSE;
}

/** 
 * Verifica que se encuentre en alguna de las bandas dentro de las horas desde y hasta
 * de la banda de emergencia teniendo en cuenta los marcos y los tiempos de espera de reintento. 
 */
- (BOOL) checkInEmergencyBand: (int) aFromHour toHour: (int) aToHour
                               frame: (int) aFrame attemptsMinutes: (int) anAttemptsMinutes 
                               currentHour: (int) aCurrentHour currentMinute: (int) aCurrentMinute
{
  int i;
  int frameBegin, frameEnd;
  int framesQty = ((aToHour - aFromHour) * 60) / aFrame + anAttemptsMinutes;
  int cHour = (aCurrentHour * 60) + aCurrentMinute;
  
  printd("checkInEmergencyBand\n");
  printd("fromHour = %d\n", aFromHour);
  printd("toHour = %d\n", aToHour);
  printd("frame = %d\n", aFrame);
  printd("attemptsMinutes = %d\n", anAttemptsMinutes);
  printd("currentHour = %d\n", aCurrentHour);
  printd("currentMinute = %d\n", aCurrentMinute);
  printd("randMinutes = %d\n", randMinutes);

// verifica si los datos estan correctos de otra manera no entra en banda de emergencia
	if ( ((aFromHour < 0) || (aFromHour > 24)) || 
			 ((aToHour < 0) || (aToHour > 24)) || 
			 (aFromHour >= aToHour) ||
			 (aFromHour == aToHour) ) return FALSE;

  if (cHour < ((aFromHour * 60) + randMinutes)) {
 //   doLog(0,"No llego a los minutos aleatorios\n");
    return FALSE;
  }    
   
  // Verifica que se encuentre en la franja que corresponde teniendo en cuenta la hora de inicio
  // la hora de fin y los marcos con sus tiempos entre reintentos.
  printd("CurrentHour in minutes = %d\n", cHour);
  
  for (i=0; i<framesQty; ++i) {
  
    printd("Evalua banda %d\n", i);
    
    frameBegin = (aFromHour * 60) + randMinutes + (aFrame * i) + (anAttemptsMinutes * i);
    frameEnd = (aFromHour *60) + randMinutes + (aFrame * (i+1)) + (anAttemptsMinutes * i);
    
    printd("frameBegin = %d\n", frameBegin);
    printd("frameEnd = %d\n", frameEnd);
    
    if (cHour < frameBegin) return FALSE;
    
    printd("Evalua si esta entre las bandas\n");
    if ((cHour >= frameBegin) && (cHour < frameEnd)) return TRUE;
  
  }         

  return FALSE;                       
}

/*
 * Verifica que cumpla con el nuevo esquema de supervision planteado para la
 * supervision al sar2.
 *
 **/
- (BOOL) canStartTelesupWithNewSchema: (id) aTelesup
{
	datetime_t now = [SystemTime getLocalTime];
	datetime_t lastSuceedTelesupDTime = [aTelesup getLastSuceedTelesupDateTime];
	datetime_t lastAttemptTelesupDTime = [aTelesup getLastAttemptDateTime];
	datetime_t nextTelesupDTime = [aTelesup getNextTelesupDateTime];
	int frame = [aTelesup getTelesupFrame];
	int eBFromHour = [aTelesup getFromHour];
	int eBToHour = [aTelesup getToHour];
	int attemptsMinutes = [aTelesup getTimeBetweenAttempts];
	int frequency = [aTelesup getTelesupFrequency];
	struct tm btNow;
  struct tm btNextTel;
  datetime_t sup1;
  
  printd("****************************************************************\n");
  printd("Entra a verificar el nuevo esquema de supervision\n");
  printd("****************************************************************\n");

  [SystemTime decodeTime: now brokenTime: &btNow];
  [SystemTime decodeTime: nextTelesupDTime brokenTime: &btNextTel];
  
	printd("Dia actual = %d\n", btNow.tm_mday);
  printd("Hora actual = %d\n", btNow.tm_hour);
  printd("Minuto actual = %d\n", btNow.tm_min);
	printd("Dia sup = %d\n", btNextTel.tm_mday);
	printd("Hora sup = %d\n", btNextTel.tm_hour);
	printd("Minuto sup = %d\n", btNextTel.tm_min);
  printd("now = %ld\n", now);
  printd("nextTelesupDTime = %ld\n", nextTelesupDTime);
  printd("nextTelesupDTime + frame = %ld\n", nextTelesupDTime + (frame * 60));


   // Si la fecha actual es menor a la de proxima supervision directamente se va.
  printd("Verifica si la fecha de hoy es menor a la fecha de proxima supervision\n");

  if (truncDateTime(now) < truncDateTime(nextTelesupDTime)) {
    printd("********************NO SUPERVISA 3*********************\n");
    return FALSE;
  }    
  
  if (firstTelesup) {
  
   // doLog(0,"Viene de un inicio\n");
    
    if (truncDateTime(lastSuceedTelesupDTime) >= truncDateTime(nextTelesupDTime)) {
      printd("********************NO SUPERVISA*********************\n");      
      return FALSE;
    }    
    
    printd("lastAttemptTelesupDTime = %ld\n", lastAttemptTelesupDTime);
    
    if (now >= nextTelesupDTime + (frame * 60)) 
      return TRUE;

    printd("********************NO SUPERVISA*********************\n");
    return FALSE;
  }
  
  // Verifica que la fecha de exito de supervision sea diferente a la fecha de supervision
  // y que la fecha de hoy sea igual a la fecha en la que se debe supervisar o que se 
  // encuentre en la fecha de restitucion.
  printd("Verifica si se encuentra en fecha para supervisar\n");
  printd("nextTelesupDateTime = %ld\n", nextTelesupDTime);
  printd("frequency = %d\n", frequency);
  printd("cuenta = %ld\n", (truncDateTime(now) - truncDateTime(nextTelesupDTime)) % (frequency * 86400));
	printd("lastSuceedTelesupTime trunc = %ld\n", truncDateTime(lastSuceedTelesupDTime));
	printd("nextTelesupDTime trunc = %ld\n", truncDateTime(nextTelesupDTime));
  
  if (((truncDateTime(now) == truncDateTime(nextTelesupDTime)) || 
      (((truncDateTime(now) - truncDateTime(nextTelesupDTime)) % (frequency * 86400)) == 0))) {
    
    // Verifica que se encuentre en el marco de supervision 1 o en el marco 
    // de supervision 2 (si este ultimo no es cero).
    // Debo convertir a LocalTime (solo si es WIN32 porque la fecha esta en Local time y cuando decodifico la fecha me lo pasa a hora GMT
    // entonces luego lo debo pasar de nuevo a hora local. 
		
    sup1 = truncDateTime(now) + (btNextTel.tm_hour * 3600) + (btNextTel.tm_min * 60);
    

    if ([self checkInFrame: now supDTime: sup1 frame: frame]) { 
        printd("Se encuentra en la primera o segunda banda\n");   
        return TRUE;  
    }

   //Verifica que ya se haya intentado en la primera banda si o si
   if (lastAttemptTelesupDTime < nextTelesupDTime) {
    	printd("********************NO SUPERVISA 5*********************\n");
			return FALSE;
		}

    printd("Verifica si la hora actual se encuentra entre la banda de emergencia\n");
    printd("Hora emergencia inicio = %d\n", eBFromHour);
    printd("Hora emergencia hasta = %d\n", eBToHour);
    

    // Si la hora actual es menor a la hora de inicio de banda no supervisa.
    if (btNow.tm_hour < eBFromHour) {
      printd("********************NO SUPERVISA 1*********************\n");
      return FALSE;
    }      

    // Si la hora actual es mayor o igual a la hora de fin de banda no supervisa.
    if (btNow.tm_hour >= eBToHour) {
      printd("********************NO SUPERVISA 2*********************\n");
      return FALSE;
    }      

    // Verifica si se encuentra en la banda de emergencia en los rangos permitidos de 
    // supervision.
    if (now >= nextTelesupDTime + (frame * 60)) {

      printd("Evalua banda de emergencia porque se vencieron los dos intentos."); 
      if ([self checkInEmergencyBand: eBFromHour toHour: eBToHour 
                                       frame: frame 
                                       attemptsMinutes: attemptsMinutes
                                       currentHour: btNow.tm_hour
                                       currentMinute: btNow.tm_min]) {
                                        printd("Se encuentra en la banda de emergencia\n");
                                        return TRUE;
                                       }
    }                                       
            
  } else {
  
    // Si no superviso y no se encuentra ni en la fecha de supervision ni en la fecha de
    // restitucion unicamente debe verificar que se encuentre en la banda de emergencia.
    printd("Verifica si se encuentra en un dia que debe supervisar unicamente en banda de emergencia\n");
    if ((truncDateTime(now) != truncDateTime(nextTelesupDTime)) || 
			 (((truncDateTime(now) - truncDateTime(nextTelesupDTime)) % (frequency * 86400)) != 0)) {
        
      // Verifica si se encuentra en la banda de emergencia en los rangos permitidos de 
      // supervision.
      if ([self checkInEmergencyBand: eBFromHour toHour: eBToHour 
                                       frame: frame 
                                       attemptsMinutes: attemptsMinutes
                                       currentHour: btNow.tm_hour
                                       currentMinute: btNow.tm_min]) {
                                        printd("Se encuentra en la banda de emergencia\n");
                                        return TRUE;
                                       }                                        
    }                                         
  } 

  printd("********************NO SUPERVISA*********************\n");
  return FALSE;
}

/**/
- (id) createPPPConnection: (CONNECTION_SETTINGS) aConnectionSettings
{
//	doLog(0,"createPPPConnection -> no implementado aun,\n");
	return NULL;
}

/**/
- (void) makePPPConnection: (CONNECTION_SETTINGS) aConnectionSettings connection: (id) aConnection telesupViewer: (TELESUP_VIEWER) aTelesupViewer
{
	//doLog(0,"makePPPConnection -> no implementado aun, en uclinux deberia llamar al comando pppd y esperar a que se conecte\n");
}

/**/
- (id) createModemConnection: (CONNECTION_SETTINGS) aConnectionSettings
{
	MODEM modem;
	volatile char *modemScript = NULL;

	printd("Discando numero telefonico: %s\n", [aConnectionSettings getModemPhoneNumber]);
	printd("Configurando baudrate  = %d\n", [Modem getBaudRateFromSpeed: [aConnectionSettings getConnectionSpeed]]);

	modem = [Modem new];
	[modem setPortNumber: [aConnectionSettings getConnectionPortId]];
	[modem setReadTimeout: [[Configuration getDefaultInstance] getParamAsInteger: "MODEM_READ_TIMEOUT"]];
	[modem setWriteTimeout: [[Configuration getDefaultInstance] getParamAsInteger: "MODEM_WRITE_TIMEOUT"]];
	[modem setBaudRate: [Modem getBaudRateFromSpeed: [aConnectionSettings getConnectionSpeed]]];


	TRY
		modemScript = loadFile([[Configuration getDefaultInstance] getParamAsString: "MODEM_SCRIPT_FILE"
													 default: BASE_PATH "/etc/modem.ini"], TRUE);
	CATCH
	END_TRY

	if (modemScript) {
		[modem setInitScript: modemScript];
		free(modemScript);
	}

	[modem open];
	[modem flush];

	return modem;
}

/**/
- (void) makeModemConnection: (CONNECTION_SETTINGS) aConnectionSettings connection: (id) aConnection telesupViewer: (TELESUP_VIEWER) aTelesupViewer
{
	char text[100];

	sprintf(text, "Discando %s", [aConnectionSettings getModemPhoneNumber]);
	[aTelesupViewer updateText: text];
	[aConnection connect: [aConnectionSettings getModemPhoneNumber]];

	sprintf(text, "Conectado %d bps", [aConnection getConnectionSpeed]);
	[aTelesupViewer updateText: text];

}

/**/
- (id) createLanConnection: (CONNECTION_SETTINGS) aConnectionSettings
{
	char host[100];

	SSL_CLIENT_SOCKET socket;

	if ([aConnectionSettings getConnectBy] == ConnectionByType_IP)
		stringcpy(host, [aConnectionSettings getIP]);
	
	if ([aConnectionSettings getConnectBy] == ConnectionByType_DOMAIN)
		stringcpy(host, [aConnectionSettings getDomainSup]);

	socket = [[SSLClientSocket new] initWithHost: host port: [aConnectionSettings getConnectionTCPPortDestination]];

	[socket	setReadTimeout: 120];
	[socket	setWriteTimeout: 120];

	return socket;
}

/**/
- (id) makeLanConnection: (CONNECTION_SETTINGS) aConnectionSettings connection: (id) aConnection telesupViewer: (TELESUP_VIEWER) aTelesupViewer
{
	[aConnection connect];
  return aConnection;
}

/**/
- (id) makeGprsConnection: (CONNECTION_SETTINGS) aConnectionSettings connection: (id) aConnection telesupViewer: (TELESUP_VIEWER) aTelesupViewer
{
	char text[255];
	char *pppdResultStr;
	int pppdResult = 0;

//	doLog(0,"Evaluando conexion GPRS\n");

	if (system(BASE_PATH "/bin/conectado") == 0) {

		sprintf(text, getResourceStringDef(RESID_ESTABLISH_GPRS_CONNECTION, "Estableciendo conexion GPRS..."));
		[aTelesupViewer updateText: text];

		system(BASE_PATH "/bin/llamar gprs");

		if (system(BASE_PATH "/bin/conectado")) {
			sprintf(text, getResourceStringDef(RESID_ESTABLISHED_CONNECTION, "Conexion establecida"));
			[aTelesupViewer updateText: text];
			msleep(5000);
		} else {
			// Si existe levanta el archivo de error para indicar algo mas especifico
			pppdResultStr = loadFile(BASE_PATH "/bin/pppd.result", TRUE);
			if (pppdResultStr != NULL) {
				pppdResult = atoi(pppdResultStr);
			//	doLog(0,"Resulado del script pppd = %d\n", pppdResult);
				free(pppdResultStr);
			}
			THROW_CODE(TSUP_PPP_CONNECTION_EX, pppdResult);
		}

	}

	sprintf(text, getResourceStringDef(RESID_CONNECTING_MANAGEMENT_SYSTEM, "Conectandose al sistema de gestion..."));
	[aTelesupViewer updateText: text];
	[aConnection connect];

	sprintf(text, getResourceStringDef(RESID_CONNECTED, "Conectado!"));
	[aTelesupViewer updateText: text];

	//doLog(0,"Conexion por socket establecida\n");
	return aConnection;
}

/**/
- (void) releasePPPConnection: (id) aConnection
{
	//doLog(0,"releasePPPConnection -> no implementado aun, en uclinux deberia llamar al comando pppd y esperar a que se conecte\n");
}

/**/
- (void) releaseLanConnection: (id) aConnection
{
	[aConnection close];
	[aConnection free];
}

/**/
- (void) releaseGprsConnection: (id) aConnection
{
	[aConnection close];
	[aConnection free];
}


/**/
- (void) releaseModemConnection: (id) aConnection
{
	[aConnection disconnect];
	[aConnection close];
	[aConnection free];
}

/**/
- (id) createGprsConnection: (CONNECTION_SETTINGS) aConnectionSettings
{
	char host[100];
	SSL_CLIENT_SOCKET socket;

	if ([aConnectionSettings getConnectBy] == ConnectionByType_IP)
		stringcpy(host, [aConnectionSettings getIP]);
	
	if ([aConnectionSettings getConnectBy] == ConnectionByType_DOMAIN)
		stringcpy(host, [aConnectionSettings getDomainSup]);

	socket = [[SSLClientSocket new] initWithHost: host port: [aConnectionSettings getConnectionTCPPortDestination]];

	[socket	setReadTimeout: 120];
	[socket	setWriteTimeout: 120];

	return socket;
}

/**/
- (void) releaseConnection: (CONNECTION_SETTINGS) aConnectionSettings connection: (id) aConnection
{

	switch ([aConnectionSettings getConnectionType]) {
	 	case ConnectionType_PPP: [self releasePPPConnection: aConnection]; break;
		case ConnectionType_LAN: [self releaseLanConnection: aConnection]; break;
		case ConnectionType_MODEM: [self releaseModemConnection: aConnection]; break;
		case ConnectionType_GPRS: [self releaseGprsConnection: aConnection]; break;
	}

}

/**/
- (void) startIncomingPPP
{
//	doLog(0,"Levantando supervision entrante....");
	system(BASE_PATH "/bin/cicloatender &");
//	doLog(0,"OK\n");
}

/**/
- (void) shutdownIncomingPPP
{
//	doLog(0,"Bajando supervision entrante....");
	system(BASE_PATH "/bin/finatender");
//	doLog(0,"OK\n");
}

/**/
- (id) createConnection: (CONNECTION_SETTINGS) aConnectionSettings
{
	id connection = NULL;

	switch ([aConnectionSettings getConnectionType]) {
	 	case ConnectionType_PPP:	return [self createPPPConnection: aConnectionSettings];
		case ConnectionType_LAN:	return [self createLanConnection: aConnectionSettings];
		case ConnectionType_MODEM: return [self createModemConnection: aConnectionSettings];
		case ConnectionType_GPRS: return [self createGprsConnection: aConnectionSettings];
	}

	return connection;	
}

/**/
- (id) makeConnection: (CONNECTION_SETTINGS) aConnectionSettings connection: (id) aConnection
	telesupViewer: (TELESUP_VIEWER) aTelesupViewer
{
	switch ([aConnectionSettings getConnectionType]) {
	 	case ConnectionType_PPP:
			[self makePPPConnection: aConnectionSettings connection: aConnection telesupViewer: aTelesupViewer];
			break;

		case ConnectionType_LAN:
			[self makeLanConnection: aConnectionSettings connection: aConnection telesupViewer: aTelesupViewer];
			break;

		case ConnectionType_MODEM:
			[self makeModemConnection: aConnectionSettings connection: aConnection telesupViewer: aTelesupViewer];
			break;

		case ConnectionType_GPRS:
			[self makeGprsConnection: aConnectionSettings connection: aConnection telesupViewer: aTelesupViewer];
			break;
	}
}

/**/
- (void) startTelesup: (TELESUP_SETTINGS) aTelesup
{
  [self startTelesup: aTelesup getCurrentSettings: FALSE];
}

/**/
- (void) configureNextTelesup: (TELESUP_SETTINGS) aTelesup
{
  int frequency;
  datetime_t now;
  datetime_t nextTelesupDateTime;
  datetime_t nextSecondaryTelesupDateTime;
 
  printd("------------------------ Configurando proxima supervision ---------------\n");

  now = [SystemTime getLocalTime];                        // Obtengo la hora local
  frequency = [aTelesup getTelesupFrequency] * 86400;     // Paso la frecuencia a segundos  
  nextTelesupDateTime = [aTelesup getNextTelesupDateTime];
  nextSecondaryTelesupDateTime = [aTelesup getNextSecondaryTelesupDateTime];

  // La forma de calcular la proxima fecha/hora de supervision es sumar a la
  // fecha/hora que ya existe la frecuencia x cantidad de veces hasta que
  // la fecha de proxima supervision sea mayor a la fecha actual.

  // Calculo la proxima fecha hora de supervision A
  while (truncDateTime(nextTelesupDateTime) <= truncDateTime(now)) {nextTelesupDateTime += frequency;}

  // Calculo la proxima fecha hora de supervision B
  while (truncDateTime(nextSecondaryTelesupDateTime) <= truncDateTime(now)) {nextSecondaryTelesupDateTime += frequency; } 

  [aTelesup setNextTelesupDateTime: nextTelesupDateTime];
  [aTelesup setNextSecondaryTelesupDateTime: nextSecondaryTelesupDateTime];

  printd("-------------------------------------------------------------------------\n");
}

/**/
- (void) startTelesup: (TELESUP_SETTINGS) aTelesup getCurrentSettings: (BOOL) aGetCurrentSettings
{
	[self startTelesup: aTelesup getCurrentSettings: aGetCurrentSettings telesupViewer: telesupViewer];
}

/**/
- (void) testGprsConnection: (TELESUP_SETTINGS) aTelesup telesupViewer: (TELESUP_VIEWER) aTelesupViewer
{
	TELESUP_TEST telesupTest;
	CONNECTION_SETTINGS connectionSettings;
	int result;

//	doLog(0,"Testeando conexion GPRS...............................\n");

	// creo el objeto de test de supervision
	telesupTest = [TelesupTest new];

	connectionSettings = [aTelesup getConnection1];

	result = 1;

	// Configuro si tengo que mostrar o no el progreso del Test
	if (aTelesupViewer == NULL || [aTelesupViewer isKindOf: [DummyTelesupViewer class]]) {
		[telesupTest setShow: FALSE];
	}

	[telesupTest setConnectionSettings: connectionSettings];
	[telesupTest setUseModem: 1];
	[telesupTest setBaudRate: [Modem getBaudRateFromSpeed: [connectionSettings getConnectionSpeed]]];
	
	result = [telesupTest testModem];

	[telesupTest free];
}

/**
 *	Comienza la telesupervision pasada por parametro.
 */
- (void) startTelesup: (TELESUP_SETTINGS) aTelesup getCurrentSettings: (BOOL) aGetCurrentSettings
	telesupViewer: (TELESUP_VIEWER) aTelesupViewer
{
	volatile TELESUPD telesupd;
	volatile id connection = NULL;
	CONNECTION_SETTINGS connectionSettings;
	int connectionId;
	volatile int retries = 0;
	volatile BOOL success = FALSE;
	int errorCode, adCode;
	datetime_t attemptTime;
	char text[100];
	char exCodeStr[20];
	volatile int attemptsQty = 0;
	char textError[100];
	volatile BOOL connectionError;
	char additional[100];
	char telcoTypeSt[20];

//	doLog(0,"myCommunicationIntention = %d\n", myCommunicationIntention);

	// Si ya estoy en una supervisio, me voy
	if (inTelesup) {
//		doLog(0,"No es posible - Se encuentra dentro de una supervision\n");
		return;
	}

	if ([[Acceptor getInstance] isTelesupRunning]) {
//		doLog(0,"No es posible - Se encuentra dentro de una supervision entrante\n");
		return;
	}


	if ((![[CimManager getInstance] isSystemIdleForTelesup]) && (myCommunicationIntention != CommunicationIntention_CHANGE_STATE_REQUEST) && (myCommunicationIntention != CommunicationIntention_TEST_TELESUP)) {
//		doLog(0,"No es posible - El sistema no se encuentra ocioso\n");
		return;
	}


//	doLog(0,"[aTelesup getTelcoType] = %d\n", 	[aTelesup getTelcoType]);

	// Si no tengo permiso porque esta mal la autorizacion, me voy
	if (([aTelesup getTelcoType] == PIMS_TSUP_ID) && (myCommunicationIntention != CommunicationIntention_CHANGE_STATE_REQUEST) && (myCommunicationIntention != CommunicationIntention_TEST_TELESUP)) {
		if (![[CommercialStateMgr getInstance] canExecutePimsSupervision]) {
		//	doLog(0,"No es posible - La autorizacion es incorrecta\n");
			return;
		}
	}

	if (([aTelesup getTelcoType] == FTP_SERVER_TSUP_ID) && (![[FTPSupervision getInstance] ftpServerAllowed])) {
		//	doLog(0,"No es posible - No puede supervisar por FTP\n");
			return;
	}

	myErrorInTelesupMsg[0] = '\0';
	// Audito el inicio de la supervision. (SOLO si es manual. El resto se audita en otro lado)
	if (myIsManual) {
		myIsManual = FALSE;
		stringcpy(telcoTypeSt, getResourceString(RESID_TelesupSettings_TELCO_TYPE_Desc + [aTelesup getTelcoType]));
		strcat(telcoTypeSt, " - ");
		strcat(telcoTypeSt, getResourceStringDef(RESID_TELESUP_TYPE_MANUAL, "Manual"));
		[Audit auditEventCurrentUser: TELESUP_START additional: telcoTypeSt station: 0 logRemoteSystem: FALSE];
	}
	// Audito el inicio de la supervision. (SOLO si es programada. El resto se audita en otro lado)
	if (myIsSchedule) {
		myIsSchedule = FALSE;
	//	doLog(0,"*****************************SUPERVISA***********************\n");
		// Audito el comienzo de supervision
		stringcpy(telcoTypeSt, getResourceString(RESID_TelesupSettings_TELCO_TYPE_Desc + [aTelesup getTelcoType]));
		strcat(telcoTypeSt, " - ");
		strcat(telcoTypeSt, getResourceStringDef(RESID_TELESUP_TYPE_SCHEDULE, "Programada"));
		[Audit auditEventCurrentUser: TELESUP_START additional: telcoTypeSt station: 0 logRemoteSystem: FALSE];
	}

	// Actualizo la informacion
	[aTelesupViewer start];
	[aTelesupViewer updateTitle: [aTelesup str]];

	[aTelesupViewer updateText: getResourceStringDef(RESID_STARTING_TELESUP, "Iniciando....")];

  inTelesup = TRUE;

//	doLog(0,"TelesupScheduler->startTelesup\n"); 
  [aTelesupViewer setTelesupId: [aTelesup getTelesupId]];

	// Si no tiene una conexion asociada, no puedo realizar la supervision
	connectionId = [aTelesup getConnectionId1];
	if (connectionId == 0) {
    inTelesup = FALSE;
    return;
  }

	connectionSettings = [[TelesupervisionManager getInstance] getConnection: connectionId];

	if (!connectionSettings) {
    inTelesup = FALSE;
		myCommunicationIntention = CommunicationIntention_TELESUP;
    return;
  } 

	// Baja la supervision PPP entrante, esto lo tiene que hacer unicamente
	// si utiliza conexion por Modem (Modem solo o PPP), para LAN no hace falta

	//if ([connectionSettings getConnectionType] != ConnectionType_LAN &&
		//	[connectionSettings getConnectionType] != ConnectionType_GPRS) [self shutdownIncomingPPP];

	if (([connectionSettings getConnectionType] != ConnectionType_LAN) && ([connectionSettings getConnectionType] != ConnectionType_GPRS)) [self shutdownIncomingPPP];

	// Si estoy utilizando el SAR II, entonces tengo que salir de la aplicacion con el codigo 24
	// para que el script que lo llama ejecute la supervision
	if ([aTelesup getTelcoType] == SARII_TSUP_ID) {
    inTelesup = FALSE;
		myCommunicationIntention = CommunicationIntention_TELESUP;
		[[CtSystem getInstance] shutdownSystem];
		exit(24);
	}

	if (myCommunicationIntention == CommunicationIntention_TEST_TELESUP || 
			[aTelesup getTelcoType] == SARII_PTSD_TSUP_ID || 
			[aTelesup getTelcoType] == G2_TSUP_ID || 
			[aTelesup getTelcoType] == FTP_SERVER_TSUP_ID ) attemptsQty = 1;
	else attemptsQty = [aTelesup getAttemptsQty];

	//doLog(0,"Cantidad de reintentos = %d\n", attemptsQty);

	while (retries < attemptsQty && !success)
	{
		errorCode = 0;
		telesupd  = NULL;

	//	doLog(0,"Intento de supervision = %d\n", retries);
		sprintf(text, getResourceStringDef(RESID_CONNECTION_ATTEMPT, "Intento %d"), retries+1);
		[aTelesupViewer updateTitle: text];

		TRY

			
			connectionError = TRUE;

			if ( ([aTelesup getTelcoType] != FTP_SERVER_TSUP_ID) ||
					 (([aTelesup getTelcoType] == FTP_SERVER_TSUP_ID) && ([connectionSettings getConnectionType] != ConnectionType_LAN))){

				// Creo la conexion
				connection = [self createConnection: connectionSettings];
	
				THROW_NULL(connection);
	
				// Establezco la conexion
				[self makeConnection: connectionSettings connection: connection telesupViewer: aTelesupViewer];

			}

			connectionError = FALSE;

			// si la supervision es PIMS o CMP OUT
			if ([aTelesup getTelcoType] != FTP_SERVER_TSUP_ID) {

				// Obtiene el demonio
				telesupd = [[TelesupFactory getInstance] getNewTelesupDaemon: [aTelesup getTelcoType]
															rol: [aTelesup getTelesupId] viewer: aTelesupViewer
															reader: [connection getReader] writer: [connection getWriter]];
	
	
				[telesupd setFreeOnExit: 0];
				[telesupd start];
				[telesupd setGetCurrentSettings: aGetCurrentSettings];
	
				printd("Waiting for telesup thread to finish\n");	fflush(stdout);
				
				// Espero hasta que termine de ejecutarse este hilo y verifico si
				// salio con error o esta todo bien.
				[telesupd waitFor: telesupd];
				errorCode = [telesupd getErrorCode];
			
			//	doLog(0,"errorcode = %d\n", errorCode);fflush(stdout);
				if (errorCode != 0) THROW(errorCode);

				printd("Telesup thread finish\n");


			}

			// si la supervision es FTP
			if ([aTelesup getTelcoType] == FTP_SERVER_TSUP_ID) {
				[[FTPSupervision getInstance] setTelesupViewer: aTelesupViewer];
				[[FTPSupervision getInstance] startFTPSupervision];
			}

			if (myCommunicationIntention == CommunicationIntention_TELESUP) {
				attemptTime = [SystemTime getLocalTime];
				[aTelesup setLastAttemptDateTime: attemptTime];
				[aTelesup setLastSuceedTelesupDateTime: attemptTime];
				[aTelesup applyChanges];
			}


			// Genero la auditoria de error en la supervision con el codigo de error
			// como adicional
			[Audit auditEvent: TELESUP_SUCCESS additional: "" station: 0 logRemoteSystem: FALSE];
								

			if (connection)
				[self releaseConnection: connectionSettings connection: connection];

			if (telesupd)
				[telesupd free];

			success = TRUE;
			[aTelesupViewer updateText: getResourceStringDef(RESID_SUPERVISION_OK, "Supervision exitosa")];

			if (myCommunicationIntention == CommunicationIntention_GENERATE_REPAIR_ORDER) {
				[myRepairOrder setRepairOrderState: RepairOrderState_OK];
			}

		CATCH
			
			ex_printfmt();

			if (myCommunicationIntention == CommunicationIntention_TELESUP) {
				attemptTime = [SystemTime getLocalTime];
				[aTelesup setLastAttemptDateTime: attemptTime];
				[aTelesup applyChanges];
			}

			errorCode = ex_get_code();
			sprintf(exCodeStr, "%d", errorCode);
			adCode = ex_get_additional_code();

			// Mapeo el codigo de error
			textError[0] = '\0';
			strcpy(textError, getResourceStringDef(RESID_SUPERVISION_ERROR, "Error en supervision"));
			strcat(textError, " ");
			if (errorCode == NO_DIALTONE_EX) strcpy(text, getResourceStringDef(RESID_TELESUP_NO_DIALTONE, "NO HAY TONO"));
			else if (errorCode == NO_CARRIER_EX) strcpy(text, getResourceStringDef(RESID_TELESUP_NO_CARRIER, "SIN PORTADORA"));
			else if (errorCode == BUSY_EX) strcpy(text, getResourceStringDef(RESID_TELESUP_BUSY, "OCUPADO"));
			else if (errorCode == NO_ANSWER_EX) strcpy(text, getResourceStringDef(RESID_TELESUP_NO_ANSWER, "NO CONTESTA"));
			else if (errorCode == CONNECTION_TIMEOUT_EX) strcpy(text, getResourceStringDef(RESID_TELESUP_CONNECTION_TIMEOUT, "TIEMPO AGOTADO"));
			else if (errorCode == MODEM_NOT_RESPONDING_EX) strcpy(text, getResourceStringDef(RESID_TELESUP_MODEM_NOT_RESPONDING, "MODEM NO RESPONDE"));
			else if (errorCode == TSUP_BAD_LOGIN_EX) strcpy(text, getResourceStringDef(RESID_TELESUP_TSUP_BAD_LOGIN, "USUARIO INVALIDO"));
			else if (errorCode == GENERAL_IO_EX) strcpy(text, getResourceStringDef(RESID_GENERAL_IO, "ERROR COMUNICACION"));
			else if (errorCode == CANNOT_OPEN_DEVICE_EX) strcpy(text, getResourceStringDef(RESID_CANNOT_OPEN_DEVICE, "PUERTO NO FUNCIONA"));
			else if (errorCode == SOCKET_CONNECT_EX) strcpy(text, getResourceStringDef(RESID_SOCKET_CONNECT, "ERROR CONEXION"));
			else if (errorCode == TSUP_PPP_CONNECTION_EX) {
				strcpy(text, getResourceStringDef(RESID_UNDEFINED, "ERROR PPP"));
				sprintf(additional, "%d", adCode);
				strcat(text, " ");
				strcat(text, additional);
			}
			else {

				TRY
					[[MessageHandler getInstance] processMessage: text messageNumber: errorCode];
				CATCH
					strcpy(text, getResourceStringDef(RESID_TELESUP_ERROR, "ERROR"));
					strcat(text, " ");
					strcat(text, exCodeStr);
				END_TRY

			}

      strcat(textError, text);
			strcpy(myErrorInTelesupMsg, text);
      
			// Genero la auditoria de error en la supervision con el codigo de error
			// como adicional
			[Audit auditEvent: TELESUP_FAILED additional: text station: 0 logRemoteSystem: FALSE];
								
			[aTelesupViewer updateText: textError];
      [aTelesupViewer informError: errorCode];
		
			TRY
        if (connection) 
				  [self releaseConnection: connectionSettings connection: connection];
			CATCH
			END_TRY

			if (telesupd) [telesupd free];

			//doLog(0,"Ha ocurrido una excepcion en TelesupScheduler\n");
			ex_printfmt();
			
			retries++;

			// Espero x segundos para volver a marcar
			if (retries < attemptsQty)  {
				printd("Esperando %d segundos antes de reintentar...\n", [aTelesup getTimeBetweenAttempts]);
				msleep([aTelesup getTimeBetweenAttempts] * 1000);
			} else {
				msleep(2000);	// Lo dejo 2 segunditos para que muestre el cartel de error
				// ocurrio un error y no hay mas intentos
				if (myCommunicationIntention == CommunicationIntention_GENERATE_REPAIR_ORDER) {
					[myRepairOrder setRepairOrderState: RepairOrderState_ERROR];
				}

			}
			
		END_TRY

	}

	//doLog(0,"CONNECTION ERROR =%d\n", connectionError);

	// No pudo establecer la conexion por algun motivo, debo realizar el test y reseteo correspondiente
	if (connectionError && 
		 [connectionSettings getConnectionType] == ConnectionType_GPRS && 
		  myCommunicationIntention != CommunicationIntention_TEST_TELESUP) {
		[self testGprsConnection: aTelesup telesupViewer: aTelesupViewer];
	}

	[aTelesupViewer finish];

	// Levantando el servicio PPP si lo habia bajado anteriormente
	if ([connectionSettings getConnectionType] != ConnectionType_LAN &&
			[connectionSettings getConnectionType] != ConnectionType_GPRS) [self startIncomingPPP];
  
  inTelesup = FALSE;
	if (myCommunicationIntention == CommunicationIntention_CHANGE_STATE_REQUEST) {

		if (success) [[CommercialStateMgr getInstance] changeSystemStatus];			

		[[CommercialStateMgr getInstance] removePendingCommercialStateChange];
	}

	// si se recibe un update de applicacion (mediante supervision) se manda a
	// reiniciar la aplicacion luego de finalizar la supervision
	if (myShutdownApp){
		[self shutdownApp];
	}

	myCommunicationIntention = CommunicationIntention_TELESUP;

}

/**/
- (void) startTelesupById: (int) aTelesupId getCurrentSettings: (BOOL) aGetCurrentSettings
{
	TELESUP_SETTINGS telesup = [[TelesupervisionManager getInstance] getTelesup: aTelesupId];

	if (telesup == NULL) THROW(REFERENCE_NOT_FOUND_EX);


	[self startTelesup: telesup getCurrentSettings: aGetCurrentSettings];

}

/**/
- (void) doStartTelesupInBackground
{
	TELESUP_SETTINGS telesup;
	TELESUP_VIEWER viewer;
	char telcoTypeSt[20];
	int telcoType;	

	// Comienza la supervision principal en background.
	// La supervision en si es igual que siempre solo que con un DummyTelesupViewer
	// para que los mensajes no se muestren por pantalla


    printf("telesup 1\n");
	if ([myBackgTelesupList size] > 0) {

		telcoType = [[myBackgTelesupList at: 0] intValue];
		[myBackgTelesupList removeAt: 0];

		myCommunicationIntention = [[myBackgTelesupList at: 0] intValue];
		[myBackgTelesupList removeAt: 0];

	}
    printf("telesup 2\n");
	if ([myBackgTelesupList size] == 0) {
		[myMutex lock];
            printf("telesup 3\n");
		myStartTelesupInBackground = FALSE;
		[myMutex unLock];
	}	
	    printf("telesup 4\n");
	currentTelesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: telcoType];

	
	if (currentTelesup) {
		viewer = [DummyTelesupViewer new];
            printf("telesup 5\n");
		myIsInBackground = TRUE;

		// Audito el comienzo de supervision
/*
		stringcpy(telcoTypeSt, getResourceString(RESID_TelesupSettings_TELCO_TYPE_Desc + [currentTelesup getTelcoType]));
		strcat(telcoTypeSt, " - ");
		strcat(telcoTypeSt, getResourceStringDef(RESID_TELESUP_TYPE_AUTOMATIC, "Automatica"));
		[Audit auditEventCurrentUser: TELESUP_START additional: telcoTypeSt station: 0 logRemoteSystem: FALSE];
*/
    printf("telesup 6\n");
		[[TelesupScheduler getInstance] startTelesup: currentTelesup getCurrentSettings: FALSE telesupViewer:viewer];
//		[viewer free];
		currentTelesup = NULL;
		myIsInBackground = FALSE;


	}
		
}

/**/
- (void) startTelesupInBackground
{
	[self startTelesupInBackground: NULL];
}

/**/
- (void) startTelesupInBackground: (int) aTelcoType
{
	int telcoType;
	id obj;
	
	if (aTelcoType == NULL) 
		telcoType = [[self getMainTelesup] getTelcoType];
	else
		telcoType = aTelcoType;
	
	// en la lista agrega la telco type y el siguiente objeto es la communicationIntention, 
	// entonces cada vez que saca un objeto, el primer int es la telcoType y la siguiente 
	// la communicationIntention es decir que debe sacar dos objetos por supervision en background

	obj = [BigInt int: telcoType];
 	[myBackgTelesupList add: obj];

	obj = [BigInt int: myCommunicationIntention];
 	[myBackgTelesupList add: obj];

	[myMutex lock];
	myStartTelesupInBackground = TRUE;
	[myMutex unLock];

}

/**/
- (void) run
{
	COLLECTION telesups;
	TELESUP_SETTINGS telesup;
	volatile int i;

	myStartTelesupInBackground = FALSE;

	//msleep(CHECK_TELESUP_TIME); // Duermo x tiempo
	msleep(10000);
	
	TRY
	
		while (TRUE)
		{

            // Si ya estoy haciendo una supervision, espero
			if (inTelesup) {
				msleep(10000);
				continue;
			}

/*			if ([[Acceptor getInstance] isTelesupRunning]) {
//				doLog(0,"No supervisa porque existe una supervision entrante en curso\n");
				msleep(10000);
				continue;
			}
*/
/*
			if ((![[CimManager getInstance] isSystemIdleForTelesup]) && (myCommunicationIntention != CommunicationIntention_CHANGE_STATE_REQUEST)){
//				doLog(0,"No supervisa porque el sistema posee depositos o extracciones en curso\n");
                printf("3\n");
				msleep(10000);
				continue;
			}

			if ([[CimBackup getInstance] inRestore]) {
				//doLog(0,"No supervisa porque esta restaurando...\n");
                printf("4\n");
				msleep(10000);
				continue;
			}
    
			if ([[CimBackup getInstance] getCurrentBackupType] != BackupType_UNDEFINED) {
				//doLog(0,"No supervisa porque esta backupeando...\n");
                printf("5\n");
				msleep(10000);
				continue;
			}
*/
			// si se esta en proceso de login espero hasta que este finalize.
			if ([[UserManager getInstance] isLoginInProgress]) {
				//doLog(0,"No supervisa porque esta procesando login...\n");
				msleep(10000);
				continue;
			}

//////////////////  CIM: DESCOMENTAR //////////////////////////////////////// 
            //msleep(100);

            printf("analiza si es en background\n");
			//// ////

			if (myStartTelesupInBackground) {
				[self doStartTelesupInBackground];
				continue;
			}

			telesups = [[TelesupervisionManager getInstance] getTelesups];
            
			
			for (i = 0; i < [telesups size]; ++i)
			{
			  printf("Verifica supervision %d\n", i);
			  
				telesup = [telesups at: i];
				// No es una supervision activa
				if (![telesup isActive]) continue;
				
				[self printSettings: telesup];
				// Para supervisar debo verificar que la supervision sea del tipo apropiado,
				// que se den las condiciones de ultima fecha de supervision, que no haya cabinas
				// con tickets pendientes o tubos descolgados y que la cantidad de impresiones en cola sea 0
				// Esta restriccion podria quitarse en un futuro si se cambia la supervision al SAR II como es actualmente
				// y no se sale de la aplicacion al iniciar dicha supervision

				if (([telesup getTelcoType] == PIMS_TSUP_ID) && ([self canStartTelesupWithNewSchema: telesup])) {

          TRY

  					// Comienza la supervision, sale de este metodo unicamente cuando termina
  					// de supervisar exitosamente o halla fallado.
						myIsSchedule = TRUE;
  					[self startTelesup: telesup];

          CATCH

            //doLog(0,"Ha ocurrido un error en el hilo TelesupScheduler\n");
            ex_printfmt();

          END_TRY

					
				}

			}

			msleep(CHECK_TELESUP_TIME); // Duermo x tiempo

      // Pone el firstTelesup en FALSE aca para que cuando haya preguntado por las cabinas osciosas no haya evaluado
      // el tiempo la primera vez.
      if (firstTelesup) firstTelesup = FALSE;
 
			
		}
	
	CATCH
		
		//doLog(0,"Ha ocurrido una excepcion grave en TelesupScheduler.\n");
		//doLog(0,"No se podran hacer mas supervisiones programadas.\n");
		ex_call_default_handler();
		fflush(stdout);

	END_TRY		
	
}

/**/
- (BOOL) inTelesup
{
  return inTelesup;
}

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

/**/
- (void) setRepairOrder: (id) aRepairOrder
{
	myRepairOrder = aRepairOrder;
}

/**/
- (id) getRepairOrder
{
	return myRepairOrder;
}

- (char *) getErrorInTelesupMsg
{
	return myErrorInTelesupMsg;
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

- (void) isManual: (BOOL) aValue
{
	myIsManual = aValue;
}

- (BOOL) isInBackground
{
	return myIsInBackground;
}

@end
