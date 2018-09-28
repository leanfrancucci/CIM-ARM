#include <unistd.h>
#include "CtSystem.h"
#include "Acceptor.h"
#include "Configuration.h"
#include "Audit.h"
#include "CommercialStateMgr.h"
#include "system/util/all.h"
#include "ctversion.h"
#include "UserManager.h"
#include "PrintingSettings.h"
#include "system/printer/all.h"
#include "system/db/all.h"
#include "Round.h"
#include "CimManager.h"
#include "TestCim.h"
#include "ExtractionManager.h"
#include "DepositManager.h"
#include "ZCloseManager.h"
#include "CimGeneralSettings.h"
#include "Event.h"
#include "AlarmThread.h"
#include "UpdateFirmwareThread.h"
#include "MessageHandler.h"
#include "CimEventDispatcher.h"
#include "JExceptionForm.h"
#include "TelesupScheduler.h"
#include "StringTokenizer.h"

#include "SafeBoxRecordSet.h"
#include "CimBackup.h"
#include "CimExcepts.h"
#include "UICimUtils.h"
#include "BillSettings.h"
#include "AmountSettings.h"
#include "EventManager.h"
#include "TelesupervisionManager.h"
#include "JMessageDialog.h"
#include "Buzzer.h"
#include "BarcodeScanner.h"
#include "SwipeReaderThread.h"
#include "JNeedMoreTimeForm.h"

#include <openssl/aes.h>  

#ifndef CT_GUI_PC

#include "ROPPersistence.h"
#include "system/ui/InputKeyboardManager.h"
#include "system/ui/jlcd/jvscreen/JVirtualScreen.h"

#else

#include "SQLPersistence.h"

#endif

#include "RegionalSettings.h"
#include "JSystem.h"
#include "SimCardValidator.h"
#include "JSimpleTextForm.h"
#include "ModuleLicenceThread.h"
#include "TemplateParser.h"
#include "DallasDevThread.h"

#include "ServerSocket.h"
#include "AsyncMsgThread.h"

//#define printd(args...) doLogs(args)
#define printd(args...)

static CT_SYSTEM singleInstance = NULL;

/*
 static const unsigned char key[] = {
     0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
       0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff,
         0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
           0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
           };
*/
@implementation CtSystem

- (void) createMessageHandler;
- (void) initCMPTelesup;
- (void) initCMPOutTelesup;
- (void) initSafeBox: (id) anObserver;
- (void) waitForFiles;
- (void) upgradeData: (id) anObserver;
- (void) testSimCard: (id) anObserver;
- (void) checkTemplate: (id) anObserver;

- (void) updateDisplay: (int) aProgress msg: (char*) aMessage
{
}

- (void) toTest
{
	
}

/**/
- (void) printVersion
{
	printf("Relase Date: %s\n", APP_RELEASE_DATE);
	printf("Version: %s\n", APP_VERSION_STR);
}

/**/
- (void) acceptTelesup
{
	ACCEPTOR acceptor = [Acceptor new];

	// Inicializando supervision entrante
//	doLog(0,"Init sup. entrante...\n");
	[acceptor setPort: [[Configuration getDefaultInstance] getParamAsInteger: "TELESUP_PORT"]];
	[acceptor start];
//	doLog(0,"OK\n");
}

/**/
+ new
{
	if (!singleInstance) singleInstance = [[super new] initialize];
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
	strcpy(databasePath, "data/");
	splash = NULL;
	errorInDB = FALSE;
	return self;
}

/**/
- (void) loadConfiguration
{

	TRY
		strcpy(databasePath, [[Configuration getDefaultInstance] getParamAsString: "DATABASE_PATH"]);
		strcpy(telesupPath, [[Configuration getDefaultInstance] getParamAsString: "TELESUP_PATH"]);
	CATCH
		ex_printfmt();
	END_TRY
  
  //Inicializa la semilla del random
 // doLog(0,"Initializing random seed....");
  srand( (unsigned)getTicks() );  
	
}

/**
 *	Sincroniza la fecha/hora del sistema
 */
- (void) syncTime
{
	char fileName[200];
	float diff = 0;
	datetime_t now;
	FILE *f;

	strcpy(fileName, telesupPath);
	strcat(fileName, "synctime.dif");

	f = fopen(fileName, "r");
	if (!f) {
		//doLog(0,"Error al abrir el archivo de fecha/hora: %s\n", fileName);
		return;
	}

	fscanf(f, "%f", &diff);
	now = [SystemTime getLocalTime];
	now = now + (unsigned long)diff;
	[SystemTime setLocalTime: now];
	//doLog(0,"Actualizo la fecha/hora desde el sistema remoto, diferencia %6.2f\n", diff);
	
	fclose(f);

	unlink(fileName);
	
}


/**/
- (void) loadTimeZone
{
	datetime_t currentTime;
/*
	char fileName[200];
	long tzone = 0;
	
	FILE *f;

	strcpy(fileName, "timezone.conf");

	f = fopen(fileName, "r");
	if (!f) {
		doLog(0,"Error al abrir el archivo de zona horaria: %s\n", fileName);
		return;
	}

	fscanf(f, "%ld", &tzone);

	[SystemTime setTimeZone: tzone];
	doLog(0,"Zona horaria %d\n", tzone);
	
	//fclose(f);
*/

	[SystemTime setTimeZone: [[RegionalSettings getInstance] getTimeZone]];
	//doLog(0,"Zona horaria %d\n", [[RegionalSettings getInstance] getTimeZone]);

	currentTime = [SystemTime getLocalTime];
//	doLog(0,"INICIO DEL SISTEMA, HORA ACTUAL %s\n", ctime(&currentTime));
	
}

/**/
- (void) writeVersionFile: (char*) aSoftwareVersion kernelVersion: (char*) aKernerlVersion DateVersion:(char*) aDateVersion
{
	FILE *f;

	//doLog(0,"Guardando archivo de version\n");
	f = fopen("version.txt", "w");
	fprintf(f, "SoftwareVersion=%s\nOSVersion=%s\nDateVersion=%s", aSoftwareVersion, aKernerlVersion != NULL ? aKernerlVersion: "N/D",aDateVersion);
	fclose(f);
}

/**/
- (void) generateVersionFile
{
	char buffer[255];
	char tokenSoftwareVersion[50];
	char tokenDateVersion[50];
	char tokenOSVersion[50];
	char field[50];
	STRING_TOKENIZER tokenizer;
	FILE *f;
	char *index;
	char *kernelVersion;
	AUDIT audit;

	kernelVersion = getKernelVersion();	
	*tokenDateVersion = 0;

	tokenizer = [StringTokenizer new];
	[tokenizer setDelimiter: "="];
	[tokenizer setTrimMode: TRIM_ALL];

	f = fopen("version.txt", "r");
	if (!f) {
	//	doLog(0,"Error abriendo archivo de version\n");
		[self writeVersionFile: APP_VERSION_STR kernelVersion: kernelVersion DateVersion: APP_RELEASE_DATE];
		return;
	}
	
	while (!feof(f)) {

		// en primer lugar, recorro el archivo para saber cuantos campos hay
		if (!fgets(buffer, 255, f)) {
		//	doLog(0,"Error leyendo datos en el archivo de version\n");
			fclose(f);
			[self writeVersionFile: APP_VERSION_STR kernelVersion: kernelVersion DateVersion: APP_RELEASE_DATE];
			return;
		}

		// le saco los enter
		index = strchr(buffer, 13);
		if (index) *index = 0;
		index = strchr(buffer, 10);
		if (index) *index = 0;
	

		//doLog(0,"buffer = %s\n", buffer);

		[tokenizer restart];
		[tokenizer setText: buffer];
	
		// Nombre
		if (![tokenizer hasMoreTokens]) return;
			[tokenizer getNextToken: field];
	
		if (strcmp(field, "SoftwareVersion") == 0) {
			
			// Valor
			if (![tokenizer hasMoreTokens]) return;
			[tokenizer getNextToken: tokenSoftwareVersion];
			
		}

		if (strcmp(field, "OSVersion") == 0) {
			
			// Valor
			if (![tokenizer hasMoreTokens]) return;
			[tokenizer getNextToken: tokenOSVersion];
			
		}

		if (strcmp(field, "DateVersion") == 0) {
			
			// Valor
			if (![tokenizer hasMoreTokens]) return;
			[tokenizer getNextToken: tokenDateVersion];
			
		}


	}

	//doLog(0,"SoftwareVersion = %s\n", tokenSoftwareVersion);
	//doLog(0,"OSVersion = %s\n", tokenOSVersion);
	//doLog(0,"DateVersion = %s\n", tokenDateVersion);

	[tokenizer free];
	fclose(f);


	if ( (strcmp(tokenSoftwareVersion, APP_VERSION_STR) != 0) || ((kernelVersion != NULL) && (strcmp(tokenOSVersion, kernelVersion) != 0)) ){

	//	doLog(0,"Hubo cambio en la version de software/OS\n");

		audit = [[Audit new] initAudit: NULL eventId: EVENT_VERSION_UPDATE additional: "" station: 0 logRemoteSystem: FALSE];

    [audit logChangeAsString: RESID_SOFTWARE_VERSION_UPDATE oldValue: tokenSoftwareVersion newValue: APP_VERSION_STR];
    
		[audit logChangeAsString: RESID_DATE_VERSION_UPDATE oldValue: tokenDateVersion newValue: APP_RELEASE_DATE];

    [audit logChangeAsString: RESID_OS_VERSION_UPDATE oldValue: tokenOSVersion newValue: kernelVersion];

		[audit saveAudit];
		[audit free];

		[self writeVersionFile: APP_VERSION_STR kernelVersion: kernelVersion DateVersion: APP_RELEASE_DATE];

	}// else  doLog(0,"NO hubo cambios de version de software/OS\n");

}

/**/
- (void) initDatabase: (id) anObserver
{
	id db;

	//doLog(0,"Initializing database.......");

	TRY

		db = [DB new];
		[db setDataBasePath: databasePath];
		[db startService];
		[ROPPersistence new];
	
	//	doLog(0,"[ OK ]\n");fflush(stdout);

	CATCH

		errorInDB = TRUE;
	//	doLog(0,"[ ERROR ]\n");fflush(stdout);
		ex_printfmt();

	END_TRY
}


- (void) advance
{

        printf("avanza \n");
    
}
    
/**/
- (BOOL) startSystem: (id) anObserver
{
    
  datetime_t timet, powerFailTime;
  struct tm bt;
  PRINTING_SETTINGS printingSettings;
    SAFEBOX_RECORD_SET rs;
	BOOL usingSecondaryHardware = FALSE;
    id timer;
    id myNeedMoreTimeForm;
    int modalResult;
    CONSOLE_ACCEPTOR consoleAcceptor;

	unsigned char text[]="virident";
  unsigned char out[10]; 
  unsigned char decout[10];
  unsigned long ticks;
  
  id ssocket;
  

    BOOL bind = FALSE;

//	AES_KEY wctx;

  // seteo el splash para poder acceder desde CimBackup y poder mostrar que 
  // esta sincronizando con la placa
  [self setSplash: anObserver];
	
	timet = time(NULL);
	localtime_r(&timet, &bt);
	/*

    */
/* 
      AES_set_encrypt_key(key, 128, &wctx);
      AES_encrypt(text, out, &wctx);  
  
      printf("encryp data = %s\n", out);
      
      AES_decrypt(out, decout, &wctx);
      printf(" Decrypted o/p: %s \n", decout);
*/
	// Hago esta pavada para que se registre la clase SafeBoxRecordSet
	rs = [SafeBoxRecordSet new];
	[rs free];

	// Imprime datos de la version
	[self printVersion];

	// Initialize OSServices
//	doLog(0,"Initializing OSServices.....");
	[OSServices OSInit];
//	doLog(0,"[ OK ]\n");fflush(stdout);

	// Cargar la configuracion a partir del archivo del inicio
	//doLog(0,"Loading configuration tariff.ini..\n");
	
	if (anObserver) [anObserver updateDisplay: 10 msg: "System Init..."];
	[self loadConfiguration];
	
	//doLog(0,"[ OK ]\n");fflush(stdout);

	// Initialize database
	
	if (anObserver) [anObserver updateDisplay: 15 msg: "Loading Database..."];
	
	[self initDatabase: anObserver];

   /* timer = [OTimer new];
    
    [timer initTimer: ONE_SHOT
            period: 1 * 1000
				object: self
				callback: "closeTimerHandler"];
   // [timer initTimer: PERIODIC period: 1000 object: self callback: "advance"];
  //  [timer start];
	
    myNeedMoreTimeForm = [JNeedMoreTimeForm createForm: NULL];
    [myNeedMoreTimeForm setCloseTimer: timer];
    modalResult = [myNeedMoreTimeForm showModalForm];
    [myNeedMoreTimeForm free];
    
    return;   */

	//*********************************************************************************
	// Si el equipo no fue inicializado me tengo que quedar esperando hasta
	// que el CMP me copie por ftp el template o hasta que se venza un timer de espera
	if ([[TemplateParser getInstance] isInitialState]) {
		if (anObserver) [anObserver updateDisplay: 20 msg: "Waiting Files..."];
		[self waitForFiles];
	}
	//*********************************************************************************


	TRY

		// Inicializo el manejo de SafeBox
		if (anObserver) [anObserver updateDisplay: 25 msg: "Waiting Safebox..."];
		
		[self initSafeBox: anObserver];
		
		
	CATCH

		ex_printfmt();
	//	doLog(0,"Excepcion inicializando el safebox\n");

		/**/
		if (ex_get_code() == CIM_USER_COMM_NOT_IN_EMER_EX) {
			usingSecondaryHardware = TRUE;
		//	doLog(0,"El sistema esta utilizando hardware secundario\n");
		} else {
			RETHROW();
		}

	END_TRY
	
	
	
	//****************************************
	// EJECUTAR UPGRADE SI CORRESPONDE
	//[self upgradeData: anObserver];
	//****************************************
	
	
	// Carga la zona horaria
	printf("startSystem-loadTimeZone\n");
	[self loadTimeZone];
    
	// Sincroniza la fecha/hora del sistema
//	doLog(0,"Sincronizando la fecha/hora....");
	[self syncTime];
	//doLog(0,"[ OK ]\n");
    // Obtengo los usuarios
	printf("Loading Users....");
	if (anObserver) [anObserver updateDisplay: 30 msg: "Loading Users..."];

	[UserManager getInstance];
	//doLog(0,"[ OK ]\n");
	
	//doLog(0,"Loading Language....");
	if (anObserver) [anObserver updateDisplay: 40 msg: "Loading Language..."];
	/* Inicializa el sistema de lenguajes multiples */
	
	[self createMessageHandler];	
	//doLog(0,"[ OK ]\n");	 	

	if (anObserver) [anObserver updateDisplay: 50 msg: "Init Spooler..."];

	// Inicializando spooler de impresion
	printf(0,"Initializing printing spooler....\n");
    
	printingSettings = [PrintingSettings getInstance];
	

    [[PrinterSpooler getInstance] setPrinterType: [printingSettings getPrinterType]];
    [[PrinterSpooler getInstance] setPrinterCOMPort: [printingSettings getPrinterCOMPort]];
    [[PrinterSpooler getInstance] setPriority: 5];
	// seteo la ruta para ir a buscar los archivos de formato de los reportes segun el idioma
	[[PrinterSpooler getInstance] setReportPathByLanguage: [[MessageHandler getInstance] getCurrentLanguage]];

	// seteo el idioma por defecto en el InputKeyboardManager
	[[InputKeyboardManager getInstance] setCurrentLanguage: [[MessageHandler getInstance] getCurrentLanguage]];

  TRY

    [[PrinterSpooler getInstance] initSpooler];
    [[PrinterSpooler getInstance] setLinesQtyBetweenTickets: [printingSettings getLinesQtyBetweenTickets]];

  CATCH
    
    ex_printfmt();

  END_TRY

	//doLog(0,"[ OK ]\n");fflush(stdout);

	// Configuracion de cantidad de decimales
	//doLog(0,"Configura el Round....");
	[Round getInstance];
//	doLog(0,"[ OK ]\n");

	if (anObserver) [anObserver updateDisplay: 60 msg: "Loading Audits..."];
	// Imprime la fecha/hora de corte de energia
	powerFailTime = [[PowerFailManager getInstance] getPowerFailTime];
	/*if (powerFailTime == 0)
		doLog(0,"No hubo corte de energia\n");
	else
		doLog(0,"Hubo corte de energia a las %s\n", asctime(localtime(&powerFailTime)));
*/
	// Audita el corte de energia
  if (powerFailTime != 0) {
	   [Audit auditEventWithDate: NULL eventId: Event_ABNORMAL_SYSTEM_SHUTDOWN 
              additional: "" station: 0 datetime: powerFailTime logRemoteSystem: FALSE];
	}

	// Audita el arranque del sistema
	[Audit auditEvent: NULL eventId: Event_SYSTEM_STARTUP additional: "" station: 0 logRemoteSystem: FALSE];
	// Genera el archivo de version
	[self generateVersionFile];

	//Inicializa la libreria
  SSL_library_init();
	//Carga los strings de error para SSL & Cryptp APIs
  SSL_load_error_strings();
  
	// creo las supervisiones al CMP entrante y saliente
	[self initCMPTelesup];
	[self initCMPOutTelesup];
    

//	doLog(0,"Starting Power Failed Manager....");

	// el start lo tengo que hacer luego de recuperar las llamadas
	[[PowerFailManager getInstance] start];
	//doLog(0,"[ OK ]\n");fflush(stdout);

    
	if (anObserver) [anObserver updateDisplay: 70 msg: "Init Devices..."];
	[CimManager getInstance];
	[[[CimManager getInstance] getCim] setSerialNumberChangeListener: [JSystem getInstance]];
    [[CimManager getInstance] start];	
    [[CimEventDispatcher getInstance] start];	

//	doLog(0,"[ OK ]\n");fflush(stdout);

//	doLog(0,"Cargando retiros.....");
	if (anObserver) [anObserver updateDisplay: 80 msg: "Loading Deposits..."];
	[ExtractionManager getInstance];
//	doLog(0,"[ OK ]\n");fflush(stdout);
//	doLog(0,"Cargando cierre Z.....");
	[ZCloseManager getInstance];
//	doLog(0,"[ OK ]\n");fflush(stdout);

	// IMPORTANTE: es fundamental que el DepositManager se carge luego
	// que el ExtractionManager y el ZCloseManager de otra forma podria
	// ocurrir que se recuperen depositos duplicados.
	//doLog(0,"Cargando depositos.....");
	if (anObserver) [anObserver updateDisplay: 85 msg: "Loading Drops..."];
	[DepositManager getInstance];
//	doLog(0,"[ OK ]\n");fflush(stdout);

//	doLog(0,"Iniciando hilo de actualizacion de Firmware....");
	if (![[UpdateFirmwareThread getInstance] hasPendingUpdates]) {
		[SafeBoxHAL resetBillAcceptors];
	} /*else {
		doLog(0,"No reseteo los validadores porque hay Updates pendientes\n");
	}*/
    
	// Levanto los singleton ahora asi luego no me consumen tiempo
	if (anObserver) [anObserver updateDisplay: 90 msg: "Loading Settings..."];

	[CimGeneralSettings getInstance];
	[TelesupervisionManager getInstance];
	[BillSettings getInstance];
	[AmountSettings getInstance];
	[EventManager getInstance];
//	[CommercialStateMgr getInstance];
	//doLog(0,"[ OK ]\n");fflush(stdout);
    
    printf("Inicializando console acceptor ...\n ");
  
    
    consoleAcceptor = [ConsoleAcceptor new];
    //msleep(3000);
	[consoleAcceptor setPort: 9001];
	[consoleAcceptor start];

	printf("OK\n");
    
	[[PrinterSpooler getInstance] start];

	// verifica si se debe aplicar algun template
	//[self checkTemplate: anObserver];
	// comienza el hilo de licenciamiento de modulos.

   // [[ModuleLicenceThread getInstance] start];

	// inicio hilo de upgrades
//	[[UpdateFirmwareThread getInstance] start];
/*
	// inicia el hilo de scanner
	if ([[CimGeneralSettings getInstance] getUseBarCodeReader]) {
		[[BarcodeScanner getInstance] setComPortNumber: [[CimGeneralSettings getInstance] getBarCodeReaderComPort]];
		[[BarcodeScanner getInstance] start];
	}

	// Levanto los singleton ahora asi luego no me consumen tiempo
	[self testSimCard: anObserver];

	// Inicia el hilo de control de la llave Dallas
  switch ([[CimGeneralSettings getInstance] getLoginDevType])
  {
		case LoginDevType_UNDEFINED: break;
		case LoginDevType_NONE: break;
		case LoginDevType_DALLAS_KEY: [[DallasDevThread getInstance] start]; break;
		case LoginDevType_SWIPE_CARD_READER: [[SwipeReaderThread getInstance] start]; break;
	}

*/	

	
	
    [self setSplash: NULL];

	// hago verificaciones correspondientes al backup y restore
	//[self checkBackupRestore];
	return ;
}
/**/
- (void) checkBackupRestore
{

	// si el modelo fisico del equipo NO fue seleccionado pero SI fue seleccionado en las 
	// tablas del backup entonces sugiero hacer un restore full.
	// este es el caso de que se cambie una consola (la cual esta inicializada)
	// pero se quiere recuperar los datos de la placa.
	if ( ([[[CimManager getInstance] getCim] verifyBoxModelChange]) &&
		   (![[[CimManager getInstance] getCim] verifyBoxModelInbackup]) ) {

		// sugiero hacer un restore full
		[JMessageDialog askOKMessageFrom: NULL withMessage: getResourceStringDef(RESID_RESTORE_ALL_DATA_MSG, "Datos incompletos. Restaure todos los datos.")];

		// por las dudas limpio la tabla de backup para evitar problemas
		[[CimBackup getInstance] initTransBackupTableCheck];

	} else {

		// si detecto que viene de un restore fallido no ejecuto el hilo de backup ni
		// muestro mensajes de sugerencia de backup.
		if ([[CimBackup getInstance] isRestoreFailure]) {
			// audito error en el restore
			if ([[CimBackup getInstance] shouldAuditRestoreError])
				[Audit auditEventCurrentUser: Event_RESTORE_ERROR additional: "" station: 0 logRemoteSystem: FALSE];
	
			[JMessageDialog askOKMessageFrom: NULL withMessage: getResourceStringDef(RESID_RESTORE_DATA_FAILURE, "Restauracion de datos incompleta. Restaure todo.")];
		} else {
	
			// Si se aplico el restore audito el mismo
			if ([[CimBackup getInstance] isRestoreOk]) {
				[Audit auditEventCurrentUser: Event_RESTORE_APPLIED additional: "" station: 0 logRemoteSystem: FALSE];
			}
	
			// inicia el hilo del backup automatico
			if ([[CimGeneralSettings getInstance] isAutomaticBackup])
				[[CimBackup getInstance] start];
	
			// si alguna de las tablas de backup (settings y users) esta incompleta muestro
			// mensaje al operador
			if (![[CimBackup getInstance] isCheckTablesOk]) {
		
				if (![[CimBackup getInstance] isBackupTransactionsFailure]) {
					if ([[CimBackup getInstance] getSuggestedBackup] == BackupType_SETTINGS)
						[JMessageDialog askOKMessageFrom: NULL withMessage: getResourceStringDef(RESID_BACKUP_TABLE_SETTINGS_ERROR, "Backup incompleto. Se sugiere ejecutar Backup-Configuracion")];
			
					if ([[CimBackup getInstance] getSuggestedBackup] == BackupType_USERS)
						[JMessageDialog askOKMessageFrom: NULL withMessage: getResourceStringDef(RESID_BACKUP_TABLE_USERS_ERROR, "Backup incompleto. Se sugiere ejecutar Backup-Usuarios")];
					
			//		doLog(0,"HAY TABLAS DE CONFIGURACION INCOMPLETAS\n");
				} else {
					[JMessageDialog askOKMessageFrom: NULL withMessage: getResourceStringDef(RESID_BACKUP_TABLE_ALL_ERROR, "Backup incompleto. Se sugiere ejecutar Backup-Completo")];
			//		doLog(0,"HAY TABLAS DE CONFIGURACION Y TRANSACCIONES INCOMPLETAS\n");
				}
		
	
			} else { // verifico que las tablas de transacciones esten ok
				if ([[CimBackup getInstance] isBackupTransactionsFailure]) {
					if (![[CimBackup getInstance] isBackupManualTransFailure]) {
						[JMessageDialog askOKMessageFrom: NULL withMessage: getResourceStringDef(RESID_BACKUP_TABLE_TRANSACTIONS_ERROR, "Backup incompleto. Se sugiere ejecutar Backup-Transacciones")];
			//			doLog(0,"HAY TABLAS DE TRANSACCIONES INCOMPLETAS\n");
					} else {
						[JMessageDialog askOKMessageFrom: NULL withMessage: getResourceStringDef(RESID_BACKUP_TABLE_MANUAL_TRANSACTIONS_ERROR, "Backup incompleto. Se sugiere ejecutar Backup-Manual")];
				//		doLog(0,"HAY TABLAS DE TRANSACCIONES MANUALES INCOMPLETAS\n");
					}
				}
			}
	
		}
	}

}

/**/
- (void) upgradeData: (id) anObserver
{
	int result = -1;
	char command[512];

	result = system("cd " BASE_PATH "/update");
	// si existe el directorio " BASE_PATH "/update puedo ejecutar el upgrade
	if (result == 0) {

	//	doLog(0,"******** INICIO actualizacion de datos y DB ********\n");
		TRY
			// Realizar dump de la configuracion en /var/data
			if (anObserver) [anObserver updateDisplay: 31 msg: "Updating Data..."];
		//	doLog(0,"PASO 1-> copia tablas de configuracion a " BASE_VAR_PATH "/data SOLO si aun no fue copiada a rw/CT8016/data\n");
			[[CimBackup getInstance] dumpTablesToUpdate];
		//	doLog(0,"Fin PASO 1 *******************\n");

			// muevo las tablas traidas por el dump a /rw/CT8016/data para poder actualizarlas
			if (anObserver) [anObserver updateDisplay: 32 msg: "Updating Data..."];
		//	doLog(0,"PASO 2-> muevo los archivos del dump a " BASE_PATH "/CT8016/data\n");
			sprintf(command,"mv %s %s", BASE_VAR_PATH "/data/*", BASE_APP_PATH "/data/");
			result = system(command);
			doLog(0,"result PASO 2: %d *******************\n",result);

			// ejecuto script de update
			if (anObserver) [anObserver updateDisplay: 33 msg: "Updating Data..."];
			//doLog(0,"PASO 3-> ejecuto el script " BASE_PATH "/update/update\n");
			result = system("sh " BASE_PATH "/update/update");
		//	doLog(0,"result PASO 3: %d *******************\n",result);

			// copio los archivos de configuracion modificados a copyFiles
			if (anObserver) [anObserver updateDisplay: 34 msg: "Updating Data..."];
		//	doLog(0,"PASO 4-> copia los archivos de configuracion modificados a copyFiles\n");
			[[CimBackup getInstance] copyUpdatedConfigTablesToCopyFiles];
		//	doLog(0,"Fin PASO 4 *******************\n");

			// hago los fsReInitFile de las tablas que corresponda
			if (anObserver) [anObserver updateDisplay: 35 msg: "Updating Data..."];
		//	doLog(0,"PASO 5-> hago los fsReInitFile que correspondan ****************\n");

			if ([[CimBackup getInstance] mustUpdateTable: "audits"])
				[SafeBoxHAL fsReInitFile: 1]; // borra las auditorias

			if ([[CimBackup getInstance] mustUpdateTable: "change_log"])
				[SafeBoxHAL fsReInitFile: 2]; // borra los detalles de auditorias

			if ([[CimBackup getInstance] mustUpdateTable: "deposits"])
				[SafeBoxHAL fsReInitFile: 3]; // borra los depositos

			if ([[CimBackup getInstance] mustUpdateTable: "deposit_details"])
				[SafeBoxHAL fsReInitFile: 4]; // borra los detalles de depositos

			if ([[CimBackup getInstance] mustUpdateTable: "extractions"])
				[SafeBoxHAL fsReInitFile: 5]; // borra las extracciones

			if ([[CimBackup getInstance] mustUpdateTable: "extraction_details"])
				[SafeBoxHAL fsReInitFile: 6]; // borra los detalles de extracciones

			if ([[CimBackup getInstance] mustUpdateTable: "zclose"])
				[SafeBoxHAL fsReInitFile: 7]; // borra los cierres Z

	//		doLog(0,"Fin PASO 5 *******************\n");

		FINALLY
			// elimino el directorio /rw/update
			if (anObserver) [anObserver updateDisplay: 36 msg: "Updating Data..."];
		//	doLog(0,"PASO 6-> elimino directorio " BASE_PATH "/update ************\n");
			result = system("rm -r " BASE_PATH "/update/");
			//doLog(0,"result PASO 6: %d *******************\n",result);

		//	doLog(0,"******** FIN actualizacion de datos y DB ********\n");
		END_TRY

		// reinicio la aplicacion
	//	doLog(0,"Mando a reiniciar la aplicacion ********\n");
		if (anObserver) [anObserver updateDisplay: 36 msg: "Rebooting..."];
		system("reboot");
	}

}

/**/
- (void) checkTemplate: (id) anObserver
{
	int userId = 0;
	int result;
	char command[512];
  COLLECTION dallasKeys = [Collection new];

	// Me fijo si debo ejecutar el template *************************************
	// Si estoy en estado inicial y el admin ya cambio su password 
	// (osea su clave no es temporal) no lo dejo ejecutar el template.
	if ([[TemplateParser getInstance] isInitialState]) {
		if (![[[UserManager getInstance] getUser: 1] isTemporaryPassword]) {
			// borro el archivo de estado inicial
			[[TemplateParser getInstance] deleteInitialStateFile];
		}
	}

	if (![[TemplateParser getInstance] wasExecuted]) {
		if ([[TemplateParser getInstance] canProccessTemplate]) {
			if ([[TemplateParser getInstance] isInitialState]) {

				// antes de aplicar el template me devo loguear como admin
				TRY
					userId = [[UserManager getInstance] logInUser: "1111" password: "5231" dallasKeys: dallasKeys];
          [dallasKeys freePointers];
          [dallasKeys free];
				CATCH
					userId = 0;
				END_TRY

				if (userId != 0) {

					// deshabilito el buzzer
					[[Buzzer getInstance] stopAndDisableBuzzer];
	
					// ********* Hago una copia de seguridad de los settings por si falla el template **********
					if (anObserver) [anObserver updateDisplay: 93 msg: "Dump Backup..."];
	
					// Realizar backup de la configuracion en /dumpBackup
		//			doLog(0,"copia la configuracion a " BASE_VAR_PATH "\n");
					[[CimBackup getInstance] dumpTables];
			
			//		doLog(0,"descomprime la configuracion en " BASE_VAR_PATH "\n");
					sprintf(command, "tar -xvf %s/%s -C %s 2> /dev/null", BASE_VAR_PATH "", "data.tar", BASE_VAR_PATH "");
			//		doLog(0,"Ejecutando comando %s\n", command);
					result = system(command);
				//	doLog(0,"Comando ejecutado %s, resultado = %d\n", command, result);
					if (result != 0) return;
			
					// Copia los archivos a dumpBackup
			//		doLog(0,"copia los archivos a dumpBackup\n");
					sprintf(command, "cp %s %s", BASE_VAR_PATH "/data/*", BASE_APP_PATH "/dumpBackup/");
		//			doLog(0,"Ejecutando comando %s\n", command);
					result = system(command);
	
					// ********* Aplico el template **********
					[[TemplateParser getInstance] applyTemplate: anObserver];
	
					// ********* Borro los archivos de dumpBackup porque el template se ejecuto ok ***********
		//			doLog(0,"borro los archivos de dumpBackup\n");
					sprintf(command, "rm " BASE_PATH "/CT8016/dumpBackup/*");
		//			doLog(0,"Ejecutando comando %s\n", command);
					system(command);
	
					// deslogueo al usuario admin
					[[UserManager getInstance] logOffUser: userId];
		
					// agrego un sleep para que me de tiempo a imrpimir
					msleep(5000);

					// si el template no estaba vacio mando a reiniciar
					if (![[TemplateParser getInstance] isEmptyTemplate]) {
						// reinicio el sistema operativo
						system("reboot");
					}
	
				}else{
					// aborto la ejecucion del template
					[[TemplateParser getInstance] abortProccess: TRUE delStartFile: FALSE];
					// imprimo reporte indicando que no se pudo ejecutar el template
					// porque el equipo no esta en estado inicial.
					[[TemplateParser getInstance] printReport];
				}
	
			}else{
				// aborto la ejecucion del template
				[[TemplateParser getInstance] abortProccess: FALSE delStartFile: FALSE];
				// imprimo reporte indicando que no se pudo ejecutar el template
				// porque el equipo no esta en estado inicial.
				[[TemplateParser getInstance] printReport];
			}
		}
	}else{
		// aborto la ejecucion del template
		[[TemplateParser getInstance] abortProccess: TRUE delStartFile: TRUE];
		// imprimo reporte indicando que no se pudo ejecutar el template
		// porque hubo una falla
		[[TemplateParser getInstance] printErrorReport];
	}
}

/**/
- (void) testSimCard: (id) anObserver
{
	SIM_CARD_VALIDATOR simCardValidator;
	static char *simCardStatusStr[] = {"Ready", "Not Inserted", "PIN Req", "PUK Req", "Failure", "Error", "Blocked"};
	SimCardStatus simCardStatus;
	char pin[20], puk[20];
	BOOL refreshScreen = FALSE;
	BOOL cancel = FALSE;
	TELESUP_SETTINGS telesup;
	int portNumber;
	int connectionSpeed;
	BOOL result;

	telesup = [[TelesupScheduler getInstance] getMainTelesup];
	if (telesup == NULL) return;
	if ([[telesup getConnection1] getConnectionType] != ConnectionType_GPRS) return;

	if (anObserver) [anObserver updateDisplay: 98 msg: "Checking SIM Card..."];

	portNumber = [[telesup getConnection1] getConnectionPortId];
	connectionSpeed = [[telesup getConnection1] getConnectionSpeed];

	simCardValidator = [SimCardValidator new];
	[simCardValidator setPortNumber: portNumber];
	[simCardValidator setConnectionSpeed: connectionSpeed];
	result = [simCardValidator openSimCard];
	if (!result) return;

//	doLog(0,"IsSimCardLocked = %d\n", [simCardValidator isSimCardLocked]);

	simCardStatus = [simCardValidator checkSimCard: NULL];

	// Mientras pueda ingresar PIN o PUK
	while (simCardStatus == SimCardStatus_PIN_REQUIRED || simCardStatus == SimCardStatus_PUK_REQUIRED) {

		refreshScreen = TRUE;

		// Existe un PIN requerido diferente al almacenado
		if (simCardStatus == SimCardStatus_PIN_REQUIRED) {
	
			cancel = ![UICimUtils askForPassword: NULL
				result: pin
				title: getResourceStringDef(RESID_PIN_REQUIRED, "PIN Required")
				message: getResourceStringDef(RESID_ENTER_PIN, "Enter PIN:")];

			if (cancel) break;

			simCardStatus = [simCardValidator checkSimCard: pin];
	
			if (simCardStatus != SimCardStatus_READY) {
				[JMessageDialog askOKMessageFrom: NULL withMessage: getResourceStringDef(RESID_INCORRECT_PIN, "Incorrect PIN!")];
				if (simCardStatus == SimCardStatus_PUK_REQUIRED) {
					[JMessageDialog askOKMessageFrom: NULL withMessage: getResourceStringDef(RESID_PIN_BLOCKED, "PIN Blocked! You must enter PUK Code!")];
				}
			} else {
				[JMessageDialog askOKMessageFrom: NULL withMessage: getResourceStringDef(RESID_PIN_ENTER_OK, "PIN entered successfully!")];
			}
	
		}

		// La SIM requiere el ingreso de un PUK
		if (simCardStatus == SimCardStatus_PUK_REQUIRED) {
	
			cancel = ![UICimUtils askForPassword: NULL
				result: puk
				title: getResourceStringDef(RESID_SIM_CARD_PUK_REQUIRED, "PUK Required")
				message: getResourceStringDef(RESID_SIM_CARD_ENTER_PUK, "Enter PUK:")];
			
			if (cancel) break;

			cancel = ![UICimUtils askForPassword: NULL
				result: pin
				title: getResourceStringDef(RESID_SIM_CARD_PUK_REQUIRED, "PUK Required")
				message: getResourceStringDef(RESID_SIM_CARD_NEW_PIN, "Enter New PIN:")];
	
			if (cancel) break;

			if (![simCardValidator enterPuk: puk newPin: pin]) {
				[JMessageDialog askOKMessageFrom: NULL withMessage: getResourceStringDef(RESID_SIM_CARD_INVALID_PUK, "Invalid PUK!")];
			}

			simCardStatus = [simCardValidator checkSimCard: pin];

		}

	}

	// La SIM Card esta bloqueada
	if (simCardStatus == SimCardStatus_BLOCKED) {
		[JMessageDialog askOKMessageFrom: NULL withMessage: getResourceStringDef(RESID_SIM_CARD_BLOCKED, "SIM Card is blocked! Please contact your provider.")];
		refreshScreen = TRUE;
	}

//	doLog(0,"SIM CARD STATUS = %s\n", simCardStatusStr[simCardStatus]);
	[simCardValidator close];

	if (refreshScreen) [anObserver refreshScreen];

}


/**/
- (id) getExistingGprsConnection
{
	COLLECTION telesups = [[TelesupervisionManager getInstance] getTelesups];
	int i;

	assert(telesups);

	for (i=0; i<[telesups size]; ++i) 
		if (([[[telesups at: i] getConnection1] getConnectionType] == ConnectionType_GPRS) && ([[telesups at: i] getTelcoType] == PIMS_TSUP_ID )) return [[telesups at: i] getConnection1];

	return NULL;
}

/**/
- (void) initCMPOutTelesup
{
	COLLECTION telesups;
	int i;
	BOOL exists = FALSE;
	TELESUP_SETTINGS telesup;
	CONNECTION_SETTINGS connection;
	char phoneNumber[40];
	char userName[60];
	char userPassword[60];
	char apn[60];
	int speed;
	id existingGprsConnection = NULL;

	[self acceptTelesup];

	telesups = [[TelesupervisionManager getInstance] getTelesups];

	// recorro las supervisiones del equipo para ver si ya existe
	for (i = 0; i < [telesups size]; ++i) 
		if ([[telesups at: i] getTelcoType] == CMP_OUT_TSUP_ID) exists = TRUE;

	if (!exists) {

		stringcpy(phoneNumber, "1");
		stringcpy(userName, "0");
		stringcpy(userPassword, "0");
		stringcpy(apn, "internet.com");
		speed = 9600;
		
		existingGprsConnection = [self getExistingGprsConnection];

		if (existingGprsConnection) {
			stringcpy(phoneNumber, [existingGprsConnection getISPPhoneNumber]);
			stringcpy(userName, [existingGprsConnection getConnectionUserName]);
			stringcpy(userPassword, [existingGprsConnection getConnectionPassword]);
			stringcpy(apn, [existingGprsConnection getDomain]);
			speed = [existingGprsConnection getConnectionSpeed];
		}

		telesup = [TelesupSettings new];
		connection = [ConnectionSettings new];

	//	doLog(0,"Agrego una supervision saliente al CMP ya que no existe\n");
		[telesup setConnection1: connection];
		[telesup setTelcoType: CMP_OUT_TSUP_ID];
		[telesup setRemoteSystemId: "CMP OUT"];

		// Graba la conexion
  	[connection setConnectionDescription: getResourceStringDef(RESID_CMP_OUT_CONNECTION, "CMP Remoto")];
		[connection setConnectionType: ConnectionType_GPRS];
		[connection setPortId: 4];
		/*Datos falsos para que no salte un error*/
		[connection setConnectionIP: "0.0.0.0"];
		[connection setTCPPortDestination: 9008];
		[connection setISPPhoneNumber: phoneNumber];
		[connection setConnectionUserName: userName];
		[connection setConnectionPassword: userPassword];
		[connection setDomain: apn];
		[connection setConnectionSpeed: speed];
		[connection applyChanges];
		[[TelesupervisionManager getInstance] addConnectionToCollection: connection];

		// Graba la supervision
		[telesup setTelesupDescription: getResourceStringDef(RESID_CMP_OUT_CONNECTION, "CMP Remoto")];
		[telesup setConnectionId1: [connection getConnectionId]];
		[telesup setActive: FALSE];
		[telesup applyChanges];
		[[TelesupervisionManager getInstance] addTelesupToCollection: telesup];
	//	doLog(0,"Agrego con exito la supervision saliente al CMP\n");

	}
}

/**/
- (void) initCMPTelesup
{
	COLLECTION telesups;
	int i;
	BOOL exists = FALSE;
	TELESUP_SETTINGS telesup;
	CONNECTION_SETTINGS connection;

	telesups = [[TelesupervisionManager getInstance] getTelesups];

	// recorro las supervisiones del equipo para ver si ya existe
	for (i = 0; i < [telesups size]; ++i) 
		if ([[telesups at: i] getTelcoType] == CMP_TSUP_ID) exists = TRUE;

	if (!exists) {

		telesup = [TelesupSettings new];
		connection = [ConnectionSettings new];

	//	doLog(0,"Agrego una supervision al CMP ya que no existe\n");
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
	//	doLog(0,"Agrego con exito la supervision al CMP\n");
	}
}

/**/
- (void) initSafeBox: (id) anObserver
{
	STATIC_SYNC_QUEUE syncQueue;
	FILE *f;
	HardwareSystemStatus hardwareSystemStatus;
	MemoryStatus primaryMemoryStatus, secondaryMemoryStatus;

	syncQueue = [[StaticSyncQueue new] initWithSize: sizeof(CimEvent) count: 300];
	[SafeBoxHAL setEventQueue: syncQueue];
	[[CimEventDispatcher getInstance] setEventQueue: syncQueue];
	[SafeBoxHAL start: [[Configuration getDefaultInstance] getParamAsInteger: "CIM_COM_PORT" default: 3]];

	while ([SafeBoxHAL getHardwareSystemStatus] == HardwareSystemStatus_UNDEFINED) msleep(5);
	while ([SafeBoxHAL getMemoryStatus: PRIMARY_MEM] == MemoryStatus_UNDEFINED) msleep(5);
	while ([SafeBoxHAL getMemoryStatus: SECONDARY_MEM] == MemoryStatus_UNDEFINED) msleep(5);

	hardwareSystemStatus  = [SafeBoxHAL getHardwareSystemStatus];
	primaryMemoryStatus   = [SafeBoxHAL getMemoryStatus: PRIMARY_MEM];
	secondaryMemoryStatus = [SafeBoxHAL getMemoryStatus: SECONDARY_MEM];

	if (hardwareSystemStatus == HardwareSystemStatus_SECONDARY ||
			primaryMemoryStatus == MemoryStatus_FAILURE ||
			secondaryMemoryStatus == MemoryStatus_FAILURE) {

		[UICimUtils hardwareFailure: NULL
			hardwareSystemStatus: hardwareSystemStatus
			primaryMemoryStatus: primaryMemoryStatus
			secondaryMemoryStatus: secondaryMemoryStatus];
	}

	TRY


		f = fopen(BASE_APP_PATH "/sbFormatUsers", "r");
		
		if (f) {
			//printf("Encuentra el de usuarios\n");
			// Inicializo el manejo de SafeBox  
			if (anObserver) [anObserver updateDisplay: 28 msg: "Format users..."];

			[SafeBoxHAL sbFormatUsers];
			fclose(f);
			unlink(BASE_APP_PATH "/sbFormatUsers");
		}
	
		f = fopen(BASE_APP_PATH "/fsBlank", "r");
		if (f) {
	
			// Inicializo el manejo de SafeBox  
			if (anObserver) [anObserver updateDisplay: 28 msg: "FileSystem blank..."];
	
			[SafeBoxHAL fsBlank];
			fclose(f);
			unlink(BASE_APP_PATH "/fsBlank");
		}


		f = fopen(BASE_APP_PATH "/fsReinitAudits", "r");
		if (f) {
	
			// Inicializo el manejo de SafeBox  
			if (anObserver) [anObserver updateDisplay: 28 msg: "Audits file blank..."];
	
			[SafeBoxHAL fsReInitFile: 1];
			fclose(f);
			unlink(BASE_APP_PATH "/fsReinitAudits");
		}


	CATCH

		if (ex_get_code() == CIM_CANNOT_FORMAT_USERS_EX) {

			//[JMessageDialog askOKMessageFrom: anObserver withMessage: "Cannot initialize users. Verify that door is open"];
			[JExceptionForm showException: CIM_CANNOT_FORMAT_USERS_EX exceptionName: "Verify that door is open"];
			[anObserver refreshScreen];

			// En caso que tire una excepcion de puerta abierta elimino los archivos para
			// que siga un curso normal, se pueda loguear y el usuario puede abrir la puerta
			unlink(BASE_APP_PATH "/sbFormatUsers");
			unlink(BASE_APP_PATH "/fsBlank");
			unlink(BASE_APP_PATH "/cmpStartUp");

		} else RETHROW();

	END_TRY

	// si la DB esta rota muestro un mensaje por pantalla excepto que este con hardware secundario
	// el mensaje lo muestro aca antes de que intente acceder a la DB y se rompa sin poder
	// advertirle al usuario del problema.
	if (hardwareSystemStatus != HardwareSystemStatus_SECONDARY &&
			primaryMemoryStatus != MemoryStatus_FAILURE &&
			secondaryMemoryStatus != MemoryStatus_FAILURE) {
		  if (errorInDB) {
				if (anObserver) [anObserver updateDisplay: 25 msg: "Database Error..."];
		  }
	}

	//****************************************
	// chequeo que no haya tablas de configuracion rotas luego de un restore
	// si encuentra algo mal intenta solucionarlo
	TRY
		[[CimBackup getInstance] checkRestoredTables: anObserver];
	CATCH
		RETHROW();
	END_TRY
	//****************************************



	[[CimBackup getInstance] initBackupFileSystem];

	TRY
		// creo al usuario admin
		[SafeBoxHAL sbAddUser: 30 personalId: "1111" password: "5231" duressPassword: "5232"];
	CATCH
		ex_printfmt();
	END_TRY
	f = fopen(BASE_APP_PATH "/dumpTables", "r");
	if (f) {

		TRY
			[[CimBackup getInstance] dumpTables];
		CATCH
			ex_printfmt();
		END_TRY
		fclose(f);
		unlink(BASE_APP_PATH "/dumpTables");
	}

	

}

/**/
- (void) closeAll: (BOOL) closeScreen
{
	int status;
	char sys[255];
	int i;
	
	//doLog(0,"The system is shutting down....\n");

	// Audita el apagado del equipo
	[Audit auditEventCurrentUser: Event_SYSTEM_SHUTDOWN additional: "" station: 0 logRemoteSystem: FALSE];

	// Espera a que se termine la supervision en curso (si es que la hay).
 	if ([[TelesupScheduler getInstance] inTelesup]) {

		[JExceptionForm showProcessForm: getResourceStringDef(RESID_WAITING_FOR_TELESUP_TO_FINISH, "Waiting for telesup to finish...")];
		
		while ([[TelesupScheduler getInstance] inTelesup]) msleep(10);
	
	}

	[JExceptionForm showProcessForm: getResourceStringDef(RESID_SHUTING_DOWN_SYSTEM, "Shutting down system...")];

	// Si el COM esta tomado lo desconecto
	status = system(BASE_PATH "/bin/ppptest");
//	doLog(0,"Valor retornado %d\n",status);

  if (status) {

		sprintf(sys, BASE_PATH "/bin/colgar %s", "gprs");
   	system(sys);
    
		for (i = 0; i < 10; ++i) {
    	msleep(1);
      status = system(BASE_PATH "/bin/ppptest");
			if (status == 0) break;
    }
  }    

	status = system("killall -9 syslogd");

	[JExceptionForm showProcessForm: getResourceStringDef(RESID_SYSTEM_IS_DOWN, "System is down!")];

	//doLog(0,"Stoping Power Failed Manager......");
	[[PowerFailManager getInstance] stop];	
	//doLog(0,"[ OK ]\n");

	//doLog(0,"Esperando a que termine el thread de CimBackup\n");
	//[[CimBackup getInstance] setTerminated: TRUE];
	doLog(0,"[ OK ]\n");

	if (closeScreen) {
	//	doLog(0,"Stoping keyboard and lcd.........");
#ifndef CT_GUI_PC
		//doLog(0,"Stoping keyboard and lcd.........");
		[[InputKeyboardManager getInstance] close];
		[[JVirtualScreen getInstance] close];
#endif
	}

	//doLog(0,"OK! Bye.\n");



}

/**/
- (void) shutdownSystem 
{
	[self closeAll: TRUE];
}

/**/
- (void) shutdownSystemWoVirtualScreen
{
	[self closeAll: FALSE];
}

/**/
- (void) createMessageHandler
{
	MESSAGE_HANDLER messageHandler;
	
	messageHandler = [MessageHandler getInstance];

}

/**/
- (char*) getDatabasePath
{
	return databasePath;
}

/**/
- (char*) getTelesupPath
{
	return telesupPath;
}

- (id) getSplash
{
  return splash;
}

- (void) setSplash: (id) anObserver
{
  splash = anObserver;
}

- (void) waitForFiles
{
	unsigned long ticks;
	unsigned long maxTime;
	unsigned long maxTimeFilesList;
	int i;
	COLLECTION fList = NULL;
	int filesCount = 0;
	BOOL wasListLoad = FALSE;
	TemplateDataFile *dFile;

//	doLog(0,"Me quedo esperando a que el CMP copie los archivos por FTP. ***************\n");

	maxTime = 600000; // con 10 minutos deberia alcanzar. (esta en msg)
	maxTimeFilesList = 120000; // tiempo que voy a esperar al archivo fileslist.cmp (2 min)

	ticks = getTicks();
	while ((getTicks() - ticks) < maxTime) {

		if (!wasListLoad){
			wasListLoad = [[TemplateParser getInstance] loadFilesList];

			if (wasListLoad)
				fList = [[TemplateParser getInstance] getFilesList];

			if ((!wasListLoad) && ((getTicks() - ticks) >= maxTimeFilesList))
				maxTime = 0; // reseteo la variable para forzar la salida del while
		}

		if (wasListLoad){

			filesCount = 0;
			for (i = 0; i < [fList size]; ++i) {

				dFile = (TemplateDataFile *)[fList at: i];

				if ([[TemplateParser getInstance] existFile: dFile->fileName size: dFile->fileSize])
					filesCount++;
			}

			// si ya llegaron todos los archivos entonces corto el while
			if (filesCount == [fList size]) {
				// si la cantidad de archivos recibidos es mayor a 1 quiere decir que ademas
				// del template se enviaron los archivos de upgrade, con lo cual debo reiniciar
				// el sistema operativo para que primero se aplique el upgrede y luego de
				// que reinicie aplique el template.
				if ([fList size] > 1) {
	
					// borro el archivo de lista de archivos
					[[TemplateParser getInstance] deleteFilesListFile];

					// creo nuevamente el archivo fileslist.cmp para que al reiniciar procese
					// el template.
					[[TemplateParser getInstance] createFilesListFile];

					// reinicio el sistema operativo
					msleep(3000);
					system("reboot");
				}

		//		doLog(0,"Se encontro el template. Sigo iniciando el equipo. ***************\n");

				// indico que ya puedo procesar
				[[TemplateParser getInstance] setCanProccessTemplate: TRUE];

				maxTime = 0; // reseteo la variable para forzar la salida del while
			}
		}

		msleep(1000);
	}

/*	if (maxTime > 0)
		doLog(0,"Los archivos no llegaron. Salgo por TimeOut. ***************\n");*/
}

@end
