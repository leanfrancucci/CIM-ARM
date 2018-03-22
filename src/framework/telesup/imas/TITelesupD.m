#include <unistd.h>
#include <ctype.h>
#include "system/io/all.h"
#include "system/net/all.h"
#include "system/util/all.h"
#include "TelesupFacade.h"
#include "settings/SettingsExcepts.h"
#include "TITelesupD.h"
#include "TITelesupParser.h"
#include "TIRemoteProxy.h"
#include "TelesupFacade.h"
#include "ctversion.h"
#include "Request.h"
#include "MessagesImas.h"


#define printd(args...)// doLog(0,args)
//#define printd(args...)
	 
	
@implementation TITelesupD

/**/
- (void) login;
- (void) logout;
- (void) generateMoneyDepositFile;

/**/
+ new
{	
	return [super new];
}

/**/
- initialize
{	
	[super initialize];
	myCurrentMsg = malloc(4096);
	imasConfigLauncher	=[ImasConfigLauncher new];
  myGetCurrentSettings = FALSE;
	return self;
}

/**/
- free
{
	/** @todo: aca deberia liberar el buffer myCurrentMsg pero no lo hago porque rompe todo. Investigar! */
	//free(myCurrentMsg);
	[imasConfigLauncher	free];
	return [super free];
}

-(int) sendFiles
{
	char *fn = (char *) malloc(300);
  char fnWithPath[300];
	int aSize;
	COLLECTION photos;
	int i;
	char *photoFileName, *photoPath;
//	TELESUP_FACADE facade = [TelesupFacade getInstance];

	//printd("  #Envio SendAllFiles\n");
	/*inicializo el archivo donde estan los archivos a enviar*/
	//[[FileManager getDefaultInstance] initSendFilesToSend:[facade getTelesupParamAsString: "Extension" telesupRol: myTelesupRol]];
	[[FileManager getDefaultInstance] initSendFilesToSend:"1"];

	/*envio el sendallfiles*/
	[myRemoteProxy newMessage: MSG_SENDALLFILES_ENTER];
	[myRemoteProxy sendMessage];
	
	aSize = [myRemoteProxy receiveMessage:3];
	
	[myRemoteProxy parseAnswer:aSize];
	
	/*verifico si llego ok*/
	if (strncmp([myRemoteProxy getParameterNumber:0],MSG_OK,2) == 0){
		/*mando los archivos*/

		// Aca deberia enviar las fotos -----------------------------------------------------
		photoPath = [[Configuration getDefaultInstance] getParamAsString: "PHOTOS_PATH" default: BASE_APP_PATH "/photos"];
		photos = [File findFilesByExt: photoPath extension: "jpg" caseSensitive: FALSE];
		[[FileManager getDefaultInstance] setSourceDir: photoPath];
		for (i = 0; i < [photos size]; ++i) {
			photoFileName = (char *)[photos at: i];
			sprintf(fnWithPath, "%s/%s", photoPath, photoFileName);
			//doLog(0,"TITelesupD -> Enviando foto = |%s|\n", fnWithPath);
			if ([File getFileSize: fnWithPath] <= 0) {
				[[FileManager getDefaultInstance] deleteFile: fnWithPath];
			} else {
				[myRemoteProxy sendFile: photoFileName targetFileName: [File extractFileName: photoFileName] appendMode: FALSE];
				//doLog(0,"Foto |%s| enviada\n", fnWithPath);
			}
		}

		[[FileManager getDefaultInstance] setSourceDir: NULL];

		// Envio el resto de los archivos ---------------------------------------------------
		//printd("  #SendAllFiles Enviado OK\n");
		while ([[FileManager getDefaultInstance] getNextFileToSend:fn]){
			printd("\n  * * * * * ENVIO ARCHIVO * * * * * *\n\n");
			printd("  #Envio Archivo %s\n",fn);			
      sprintf(fnWithPath, "%s/%s", [[Configuration getDefaultInstance] getParamAsString: "IMAS_FILES_TO_SEND_PATH"], fn);
      // Solo tengo que enviar el archivo si tiene tamanio y no es una
      // retransmision (se identifica con la letra r al comienzo)
      if ([File getFileSize: fnWithPath] <= 0 && fn[0] != 'r') {
        [[FileManager getDefaultInstance] deleteFile: fnWithPath];
      } else {
			  [myRemoteProxy sendFile: fn targetFileName: [File extractFileName: fn] appendMode: FALSE];
      }
			printd("  Archivo Enviado!!!\n");
			
		}
		[[FileManager getDefaultInstance] deinitSendFilesToSend];
	}
	else{
		printd("  ERROR: Enviando SendAllFiles\n");
		free(fn);
		return 0;
	}		
	
	/*endSendAllFiles*/
	//printd("  #Enviando EndSendAllFiles...\n");			

	/*envio el sendallfiles*/
	[myRemoteProxy newMessage: MSG_ENDSENDALLFILES_ENTER];
	[myRemoteProxy sendMessage];
	//printd("  #EndSendAllFiles Enviado OK\n");			

	free(fn);	
	return 1;
}

/**/
-(int) receiveFiles
{
	int endSendAllFiles=0;
	int pCount;
	unsigned long bytesRx;

	TRY
		/*espero el sendallfiles*/		
		if ([myRemoteProxy receiveMessage:strlen(MSG_SENDALLFILES)]){
			/*envio el OK para sincronizar*/
			//printd("  #SendAllFiles Recibido.\n");
	
			[myRemoteProxy newMessage: MSG_OK_ENTER];
			[myRemoteProxy sendMessage];
	
			/*espero los archivos*/
			while (!endSendAllFiles){
				bytesRx=[myRemoteProxy receiveMessage:50];
				if (bytesRx >0){
					pCount=[myRemoteProxy parseAnswer:bytesRx];
					if (pCount == 1){					
						/*puede ser endsendallfiles*/
						if (strncmp([myRemoteProxy getParameterNumber:0],MSG_ENDSENDALLFILES,strlen(MSG_ENDSENDALLFILES))== 0){					
							printd("  #Fin Transferencia de Archivos del Server\n");
							endSendAllFiles	=1;
						}
						else
							printd("  ERROR: Recibio pocos parametros(endSendFile)!!!!\n");
					}
					else{
						/*es un sendFile??*/
						if (pCount == 3)
							[myRemoteProxy receiveFile: [myRemoteProxy getParameterNumber:1] targetFileName: [File extractFileName: [myRemoteProxy getParameterNumber:1]]];
						else
							printd("  ERROR: Recibio pocos parametros (sendFile) %d!!!!\n",pCount);
					}
				}
				else{
					printd("  ERROR: Recibiendo el SendFile\n");
					RETURN_TRY(0);
				}
			}/*fin while endSendallFiles*/
			
			RETURN_TRY(1);	
		}
		else
			printd("  ERROR: Recibiendo el SendAllFiles\n");
			
		RETURN_TRY(0);
	CATCH
		ex_printfmt();
		myErrorCode = ex_get_code();
	END_TRY;
  
  return 0;		

}

-(int) genFile:(char*) reqMsg fileName:(char *) fName fixedFilename:(char *) fFName fromDate:(datetime_t) fDate toDate:(datetime_t) tDate activefilter:(int) filtered
{
	REQUEST request;
  CIPHER_MANAGER cipherManager;
  int fSize;
  char encFileName[255];
  char sourceFileName[255];
  char aux[255];
		
	/*generacion del archivo de auditorias*/
	printd("Enviando %s.......\n",fName);
	[myTelesupViewer informEvent: TelesupEventType_FILE_GENERATION name:fName];

//doLog(0,"Creando request\n");fflush(stdout);
	request = [myTelesupParser getRequest: reqMsg activateFilter:filtered fromDate:fDate toDate:tDate];
//doLog(0,"Ejecutando request\n");fflush(stdout);
	[self processRequest: request];
//doLog(0,"Limpiando request\n");fflush(stdout);
	[request clear];

//doLog(0,"Encriptando archivo\n");fflush(stdout);
  cipherManager = [CipherManager new];
  sprintf(sourceFileName, "%s/%s", [[Configuration getDefaultInstance] getParamAsString: "IMAS_FILES_TO_SEND_PATH"], fName );  
	fSize = [[FileManager getDefaultInstance] getFilesize: sourceFileName];
  //doLog(0,"Archivo a enviar = %s, size = %d\n", sourceFileName, fSize);fflush(stdout);
  sprintf(encFileName, "%s.enc", sourceFileName);

  sprintf(aux, "%s.enc", fName);

	[cipherManager encodeFile: sourceFileName destination: encFileName size: fSize];
	[[FileManager getDefaultInstance] deleteFile: sourceFileName];

  unlink(sourceFileName);
  rename(encFileName,sourceFileName);

	/*renombro y particiono el archivo*/
	[[FileManager getDefaultInstance] prepareFile: fName fixedFileName: fFName];

	return 1;
}
/**/

-(int) genFilesToSend
{	
	BOOL sendTraffic;
	BOOL sendAudits;
	TELESUP_FACADE facade = [TelesupFacade getInstance];
	
	printd("Obtiene datos\n");
/*	sendTraffic	= [facade getTelesupParamAsInteger: "SendTraffic" telesupRol: myTelesupRol];
	printd("traffic %d\n",sendTraffic);*/
	sendAudits	= [facade getTelesupParamAsInteger: "SendAudits" telesupRol: myTelesupRol];	
	printd("audits %d\n",sendAudits);	
	
	if (sendAudits) [self genFile: "GET_AUDITS_IMAS" fileName:"audits.auc" fixedFilename:"" fromDate:0 toDate:0 activefilter:0];

	[self genFile: "GetDeposits" fileName:"deposits.trc" fixedFilename:"" fromDate:0 toDate:0 activefilter:0];

	//[self generateMoneyDepositFile];

	return 1;
}

/**/
- (void) generateMoneyDepositFile
{
  CIPHER_MANAGER cipherManager;
  int fSize;
  char encFileName[255];
  char sourceFileName[255];
  char aux[255];
	char fName[255];
	char fFName[255];
	char command[255];

	/** @todo: hago esto por las dudas para que cambie la fecha/hora y el archivo se genere con otro nombre */
	msleep(2000);

	sprintf(command, "cp money.trc %s", [[Configuration getDefaultInstance] getParamAsString: "IMAS_FILES_TO_SEND_PATH"]);
	//doLog(0,"Ejecutando comando %s\n", command);
	system(command);

	strcpy(fName, "money.trc");
	strcpy(fFName, "");

	/*generacion del archivo de auditorias*/
	printd("Enviando %s.......\n",fName);
	[myTelesupViewer informEvent: TelesupEventType_FILE_GENERATION name:fName];

//doLog(0,"Encriptando archivo\n");fflush(stdout);
  cipherManager = [CipherManager new];
  sprintf(sourceFileName, "%s/%s", [[Configuration getDefaultInstance] getParamAsString: "IMAS_FILES_TO_SEND_PATH"], fName );  
	fSize = [[FileManager getDefaultInstance] getFilesize: sourceFileName];
  //doLog(0,"Archivo a enviar = %s, size = %d\n", sourceFileName, fSize);fflush(stdout);
  sprintf(encFileName, "%s.enc", sourceFileName);

  sprintf(aux, "%s.enc", fName);

	[cipherManager encodeFile: sourceFileName destination: encFileName size: fSize];
	[[FileManager getDefaultInstance] deleteFile: sourceFileName];

  unlink(sourceFileName);
  rename(encFileName,sourceFileName);

	/*renombro y particiono el archivo*/
	[[FileManager getDefaultInstance] prepareFile: fName fixedFileName: fFName];

	return 1;
}

/**/
- (void) run
{
	BOOL telesupHaltError = FALSE;
	BOOL error = FALSE;
	char *filename;
	char *completePath;
	TELESUP_FACADE facade = [TelesupFacade getInstance];
	char *dirIp;
	int portNumber;
  int connectionId;
	char command[255];

	TRY			
		/*genero los archivos a enviar*/
		if (![self genFilesToSend]){
			printd("  #Error al intentar generar los archivos a enviar\n");
			THROW(TSUP_FILE_GENERATION_EX);
		}
	CATCH
		ex_printfmt();
		myErrorCode = ex_get_code();
		return;
		
	END_TRY;

  connectionId = [facade getTelesupParamAsInteger: "ConnectionId1" telesupRol: myTelesupRol];

	dirIp		= [facade getConnectionParamAsString: "IP" connectionId: connectionId];
	portNumber 	= [facade getConnectionParamAsInteger: "TCPPortDestination" connectionId: connectionId];
	printd("Conectando a IP = %s, puerto = %d\n", dirIp, portNumber);

	printd("Inicio Telesup\n");
	[self startTelesup];
	printd("Telesup Iniciada\n");
	TRY
		/* Configura el proxy*/
		printd("Intento Conectar\n");
		/*if ([myRemoteProxy initConnection: dirIp port: portNumber])
			printd("Conectado\n");
		else{
			printd("NO Conectado!!!\n");
			THROW(TSUP_CONNECTION_TIMEOUT_EX);
		}
*/
		/* Ejecuta el proceso de login*/
		[self login];
		
	CATCH
	
		[self stopTelesup];
		ex_printfmt();
		myErrorCode = ex_get_code();
		return;
		
	END_TRY;


	TRY

		printd("\n--------------------------------------------------------------\n");	
		
		printd("\n >RECEPCION DE ARCHIVOS\n");
		/*recepcion de archivos del server*/
		if (![self receiveFiles]){
			printd("  ERROR: Recibiendo Archivos del Server\n");
			THROW(GENERAL_IO_EX);
		}

		printd("\n >ENVIO DE ARCHIVOS\n");
		printd(" -------------------------------------\n");
		
		/*envio de archivos al server*/
		if (![self sendFiles]){
			printd("  ERROR: Enviando Archivos al Server\n");
			THROW(GENERAL_IO_EX);
		}
		
    /**/
    if (myGetCurrentSettings) {
     	
      //doLog(0,"Solicitando configuracion actual\n");fflush(stdout);

      [myRemoteProxy newMessage: "GETCONFACTUAL\xD\xA"];     
      [myRemoteProxy sendMessage];

      /*recepcion de archivos del server*/
		  if (![self receiveFiles]){
			   printd("  ERROR: Recibiendo Archivos del Server\n");
			   THROW(GENERAL_IO_EX);
		  }
   
    }

	CATCH
			
			/**/
			EXCEPTION_GROUP	( IO_EXCEPT ) 				telesupHaltError = TRUE;
			
			/**/
			EXCEPTION_GROUP	( NET_EXCEPT ) 				telesupHaltError = TRUE;			
			EXCEPTION( GENERAL_IO_EX ) 						telesupHaltError = TRUE;
			
			error = TRUE;
			
			ex_printfmt();

			myErrorCode = ex_get_code();
						
	END_TRY
		
	printd(">>>>>>>>>>>>>> FIN DE LA SUPERVISION <<<<<<<<<<<<<<<\n");

	if (error)
		printd("ERROR EN LA SUPERVISION\n");
	else {
		printd("SUPERVISION EXITOSA!!!\n");

		// Elimino el archivo money.trc original
		sprintf(command, "rm money.trc");
		//doLog(0,"Ejecutando comando %s\n", command);
		system(command);

	}
			
	TRY		
		if (!telesupHaltError)
			[self logout];
	CATCH
	
	END_TRY

	if (!error){
		/*verificar las configuraciones recibidas*/
		/*proceso las configuraciones que descargo*/
		printd("Proceso configuraciones recibidas\n");



		[[FileManager getDefaultInstance] loadDirectory:[[FileManager getDefaultInstance] getDataDestinationDir] list: [imasConfigLauncher getFilesCollection]];
		filename= (char *) malloc(100);
		completePath= (char *) malloc(500);
		while ([imasConfigLauncher nextFile:filename]!= NULL){
			sprintf(completePath,"%s/%s",[[FileManager getDefaultInstance] getDataDestinationDir],filename);
			printd("%s---\n",completePath);
			[imasConfigLauncher launchConfiguration:completePath telesupD:self];		
		  [myTelesupViewer informEvent: TelesupEventType_APPLY_CONFIGURATION name:filename];
		}
		
		free(filename);
		free(completePath);
		printd("Configuraciones procesadas\n");
	} else {

		[myTelesupViewer informError: myErrorCode];

	}

	[self stopTelesup];
};


/**/
- (void) login
{
	char *userName;
	char *password;
	char *idSoft;
	char *versionSoft;
	int aSize;
	char *versionClienteTelesup;
	
	TELESUP_FACADE facade = [TelesupFacade getInstance];

	password	= [facade getTelesupParamAsString: "Password" telesupRol: myTelesupRol];
	userName 	= [facade getTelesupParamAsString: "UserName" telesupRol: myTelesupRol];
	idSoft 		= [facade getTelesupParamAsString: "SystemId" telesupRol: myTelesupRol];
  versionSoft = APP_VERSION_STR;
	versionClienteTelesup = [[Configuration getDefaultInstance] getParamAsString: "IMAS_VERSION_CLIENTE_TELESUP"];

	/*envio la version de telesupervision*/
	printd("USR %s\nIDS %s\nVER %s\n",userName,idSoft,versionSoft);
	printd("VERSION CLIENTE %s\n",versionClienteTelesup);
	
	if (![myRemoteProxy sendVersion: versionClienteTelesup])
		THROW(TSUP_BAD_LOGIN_EX);
		
	aSize = [myRemoteProxy receiveMessage:20];

	[myRemoteProxy parseAnswer:aSize];

	printd("Parseo Ok %selkekek\n",[myRemoteProxy getParameterNumber:2]);
	
	if (strcmp([myRemoteProxy getParameterNumber:2],MSG_OK) != 0)
		THROW(TSUP_BAD_LOGIN_EX);
	
	printd("YA Verfiico okn\n");
	
	/*identifico el equipo*/
	printd("Login....\n");
	[myRemoteProxy login: userName password: password extension: idSoft appVersion: versionSoft];
	aSize = [myRemoteProxy receiveMessage:30];
	printd("Envio Login\n");
	
	[myRemoteProxy parseAnswer:aSize];
	
//	printd("Respuesta del login = %s\n", myCurrentMsg);
	if (strcmp([myRemoteProxy getParameterNumber:0],MSG_ALLOW)!=0)
		THROW(TSUP_BAD_LOGIN_EX);
	
	/*envio el ok mas enter*/
	[myRemoteProxy newMessage: MSG_OK_ENTER];
	[myRemoteProxy sendMessage];
}

/**/
- (void) logout
{
	[myRemoteProxy logout];
};

			
@end
