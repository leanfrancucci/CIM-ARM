#include "TemplateParser.h"
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <ctype.h>

//#define printd(args...) doLog(0,args)
#define printd(args...)

#include "system/lang/all.h"
#include "system/util/all.h"
#include "ctapp.h"
#include "G2TelesupParser.h"
#include "Request.h"
#include "Audit.h"
#include "Event.h"
#include "DummyRemoteProxy.h"
#include "G2TelesupParser.h"
#include "G2InfoFormatter.h"
#include "Request.h"
#include "G2ActivePIC.h"
#include "XMLConstructor.h"
#include "PrinterSpooler.h"
#include "MessageHandler.h"
#include "FileManager.h"
#include "CipherManager.h"
#include "CimManager.h"

#define TEMPLATE_FILE_PATH						BASE_TELESUP_PATH "/"
#define FILES_LIST_FILE_NAME					"fileslist.cmp"
#define INITIAL_FILE_NAME							"initial.stt"
#define START_TEMPLATE_FILE_NAME			"start.tpl"

static id singleInstance = NULL;

@implementation TemplateParser

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
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
	proxy = [DummyRemoteProxy new];
	parser = [G2TelesupParser new];			
	[parser setExecutionMode: STT_ID];
	formatter = [G2InfoFormatter new];
	filesList = [Collection new];
	canProccess = FALSE;
	templateName[0] = '\0';
	myObserver = NULL;
	myCount = 1;
	myIsEmptyTemplate = FALSE;
	myIsInitBoxTemplate = FALSE;

	return self;
}

/**/
- (BOOL) existFile: (char *) aFileName size: (long) aSize
{
	FILE *f;
	char fileName[200];
	long fSize = 0;
	
	strcpy(fileName, TEMPLATE_FILE_PATH);
	strcat(fileName, aFileName);

	// verifico si existe el nombre del archivo
	f = fopen(fileName, "r");
	if (!f) return FALSE;

	fclose(f);

	// verifico si el archivo tiene el peso que debe tener.
	// En caso que no posea el peso adecuado es porque aun se esta terminando de copiar
	fSize = [[FileManager getDefaultInstance] getFilesize: fileName];
	if (fSize != aSize) return FALSE;
	
	return TRUE;
}

/**/
- (void) parseTemplate
{
	FILE *f;
	char token[500];
	char msg[2000];
	char fileName[200];
	char buffer[500];
	STRING_TOKENIZER tokenizer = [StringTokenizer new];
	char *index;
	BOOL analiceMark = FALSE;
	BOOL ignoreMessage = FALSE;
	BOOL isFirstLine = TRUE;
	BOOL wrongPTSDVersion = FALSE;
	G2_ACTIVE_PIC pic;
	char PTSDVersion[10];
	id box = NULL;
	
	stringcpy(buffResult, getResourceStringDef(RESID_CONFIG_TEMPLATE_OK, "Configuracion de plantilla exitosa !!!"));
	myIsEmptyTemplate = FALSE;
	myIsInitBoxTemplate = FALSE;

	// creo el archivo que indica el inicio de la ejecucion del template
	[self createStartTemplateFile];

	strcpy(fileName, TEMPLATE_FILE_PATH);
	strcat(fileName, templateName);

	f = fopen(fileName, "r");

	[tokenizer setTrimMode: TRIM_NONE];
	[tokenizer setDelimiter: "\012"];

	// recorro el archivo
	msg[0] = '\0';
	while (!feof(f)) {
		
		if (!fgets(buffer, 500, f)) break;

		[tokenizer restart];
		[tokenizer setText: buffer];

		// concateno la linea
		strcat(msg, buffer);

		if ([tokenizer hasMoreTokens]){
			[tokenizer getNextToken: token];

			// si es la primera linea analizo que tipo de template es y si la version de PTSD corresponda con la actual
			if (isFirstLine){
				msg[0] = '\0'; // vuelvo a vaciar el msg porque la primera linea debo obviarla
				isFirstLine = FALSE;

				// VERIFICO SI EL TEMPLATE ES DE INICIALIZACION FISICA DE CAJA
				index = strstr(trim(token), "INIT TEMPLATE");
				if (index) {
					//doLog(0,"is INIT TEMPLATE ********\n");
					myIsInitBoxTemplate = TRUE;
					// lo vuelvo a poner en true para que analize la proxima linea en la cual viene la version de PTSD.
					isFirstLine = TRUE;
					// elimino el archivo de inicio de template ya que este tipo de template no me 
					// interesa saber si finalizo o no.
					[self deleteStartTemplateFile];
				} else {

					// VERIFICO QUE EL TEMPLATE ESTE O NO VACIO
					index = strstr(trim(token), "EMPTY TEMPLATE");
					if (index) {
						myIsEmptyTemplate = TRUE;
						break;
					}

					// obtengo la version actual de PTSD
					pic = [G2ActivePIC new];
					stringcpy(PTSDVersion, [pic getSystemVersionByTelcoType: CMP_TSUP_ID]);
					[pic free];
	
					index = strstr(trim(token), PTSDVersion);
					if (!index){
						//doLog(0,"No coinciden las versiones de PTSD para aplicar la plantilla\n");
						stringcpy(buffResult, getResourceStringDef(RESID_CONFIG_TEMPLATE_PTSD_ERROR, "Version PTSD de template erronea !!!"));
						wrongPTSDVersion = TRUE;
						break;
					}
				}
			}

			// verifico si debo o no ignorar el mensaje actual
			if (analiceMark){
				index = strstr(trim(token), "PLANTILLAS");
				if (index) ignoreMessage = TRUE;
				analiceMark = FALSE;
			}
			
			// controlo si estoy en Message para luego analizar si hay alguna marca que me 
			// indique que no debo procesar dicho mensaje
			index = strstr(trim(token), "Message");
			if ( (index) && (strlen(trim(token)) == strlen("Message")) ) analiceMark = TRUE;

			// si llego al End debo mandar a ejecutar el mensaje PTSD
			index = strstr(trim(token), "End");
			if ( (index) && (strlen(trim(token)) == strlen("End")) ){
				if (!ignoreMessage){
					// ejecuto el mensaje PTSD
					[self proccessPTSD: msg];

				}else ignoreMessage = FALSE;

				// vacio el mensaje
				msg[0] = '\0';
			}
		}
	}
	
	[tokenizer free];
	fclose(f);

	// seteo para que no vuelva a procesar
	canProccess = FALSE;

	// actualizo el modelo en el box luego de aplicar el template de inicializacion
	if (myIsInitBoxTemplate) {
		box = [[[CimManager getInstance] getCim] getBoxById: 1];
		if (box) {
			[box setBoxModel: [[[CimManager getInstance] getCim] getBoxModel]];
			[box applyChanges];
		}
	}

	// borro el archivo de lista de archivos
	[self deleteFilesListFile];

	// elimino el template
	[self deleteTemplateFile];

	//Solo lo borro si las versiones de PTSD coinciden
	if (!wrongPTSDVersion) {
		// Si NO es un template vacio y NO es un template de inicializacion entonces lo borro
		if ( (!myIsEmptyTemplate) && (!myIsInitBoxTemplate) ) {
			// luego de aplicar la plantilla elimino el archivo de estado inicial
			[self deleteInitialStateFile];
		}
	}

	// elimino el archivo de inicio de template
	if (!myIsInitBoxTemplate)
		[self deleteStartTemplateFile];

	// imprimo el reporte
	if (!myIsEmptyTemplate)
		[self printReport];
}

/**/
- (BOOL) isEmptyTemplate
{
	return myIsEmptyTemplate;
}

/**/
- (void) proccessPTSD: (char *) aMsg
{
	id request;
	char msg[2000];
	char msgDisplay[21];
	int i;
	
	TRY
		// hago una copia del mensaje por si lo tengo que mostrar en el CATCH
		// ya que al setearlo en el getRequest y generar excepcion se corta el mensaje
		// que se mostraba al hacer //doLog(0,)
		strcpy(msg, aMsg);

		// actualizo los puntos supencivos en el display
		if (myObserver) {
			stringcpy(msgDisplay, "Applying Template");
			if (myCount == 4) myCount = 1;
			for (i=1; i<=myCount; i++)
				strcat(msgDisplay,".");

			myCount++;
			[myObserver updateDisplay: 95 msg: msgDisplay];
		}

		request = [parser getRequest: aMsg];
		[request setReqRemoteProxy: proxy];
		[request setReqInfoFormatter: formatter];

		// Procesa el Request
		[request processRequest];

		// Se ejecuto con exito
		[request requestExecuted];
	CATCH
		// Fallo la ejecucion
		ex_printfmt();
		//doLog(0,"FALLO EJECUCION PTSD ****************************\n");
		//doLog(0,msg);
		//doLog(0,"*************************************************\n");
	END_TRY;

}

/**/
- (void) applyTemplate: (id) anObserver
{
	assert(proxy);
	assert(parser);
	assert(formatter);

	myObserver = anObserver;

	buffResult[0] = '\0';

	// desencripto el template
	[self decodeTemplate];

	// parseo el template
	[self parseTemplate];
}

/**/
- (BOOL) isInitialState
{
	FILE *f;
	char fileName[200];
	
	strcpy(fileName, INITIAL_FILE_NAME);

	f = fopen(fileName, "r");
	
	if (!f) return FALSE;

	fclose(f);
	
	return TRUE;
}

/**/
- (BOOL) wasExecuted
{
	FILE *f;
	char fileName[200];
	
	strcpy(fileName, START_TEMPLATE_FILE_NAME);

	f = fopen(fileName, "r");
	
	if (!f) return FALSE;

	fclose(f);
	
	return TRUE;
}

- (void) deleteFilesListFile
{
	char fileName[200];

	strcpy(fileName, TEMPLATE_FILE_PATH);
	strcat(fileName, FILES_LIST_FILE_NAME);

	//doLog(0,"-----> ELIMINO EL ARCHIVO %s <-----\n", fileName);
	unlink(fileName);
}

- (void) deleteInitialStateFile
{
	char fileName[200];
	
	strcpy(fileName, INITIAL_FILE_NAME);

	//doLog(0,"-----> ELIMINO EL ARCHIVO %s <-----\n", fileName);
	unlink(fileName);
}

/**/
- (void) createInitialStateFile
{
	char fileName[200];
	FILE *f;

	strcpy(fileName, INITIAL_FILE_NAME);

	//doLog(0,"-----> CREO EL ARCHIVO %s <-----\n", fileName);

	f = fopen(fileName, "w+");
	fprintf(f, "/* Equipo en estado inicial */");
	fclose(f);
}

- (void) deleteStartTemplateFile
{
	char fileName[200];
	FILE *f;
	
	strcpy(fileName, START_TEMPLATE_FILE_NAME);

	f = fopen(fileName, "r");
	
	if (f) {
		//doLog(0,"-----> ELIMINO EL ARCHIVO %s <-----\n", fileName);
		fclose(f);
		unlink(fileName);
	}

}

- (void) deleteTemplateFile
{
	char fileName[200];
	
	if (strlen(templateName) > 0){
		strcpy(fileName, TEMPLATE_FILE_PATH);
		strcat(fileName, templateName);
	
		//doLog(0,"-----> ELIMINO EL ARCHIVO %s <-----\n", fileName);
		/*if (unlink(fileName) != 0)
			doLog(0,"Error: no se pudo eliminar el archivo %s\n", fileName);*/
	}
}

/**/
- (void) printErrorReport
{
	stringcpy(buffResult, getResourceStringDef(RESID_CONFIG_TEMPLATE_ERROR, "La plantilla no puede ser \n aplicada.\n Error general !!!"));

	[self printReport];
}

/**/
- (void) printReport
{
	char *templateReport;
	char line[500], datestr[50], timestr[50];
	time_t now;
	struct tm *brokenTime;
	scew_tree* tree;

	templateReport = malloc(1000);
	*templateReport = '\0';
	now = time(NULL);
	brokenTime = localtime(&now);

	if (strlen(buffResult) == 0)
		stringcpy(buffResult, getResourceStringDef(RESID_CONFIG_TEMPLATE_NOT_INITIAL_STATE, "La plantilla no puede ser \n aplicada.\n El equipo no se encuentra \n en estado inicial !!!"));

	sprintf(datestr, "%04d-%02d-%02d", 
			brokenTime->tm_year + 1900, 
			brokenTime->tm_mon + 1,
			brokenTime->tm_mday
		);

	sprintf(timestr, "%02d:%02d:%02d", 
			brokenTime->tm_hour,
			brokenTime->tm_min,
			brokenTime->tm_sec
		);

	sprintf(line, "f \n \n"
								 "*****************************\n"
								 "   %s\n"
								 "*****************************\n \n"
								 "%s %s\n"
								 "%s %s\n"
								 " \n",
								 getResourceStringDef(RESID_REPORT_CONFIG_TEMPLATE_TITLE, "PLANTILLA DE CONFIGURACION"),
								 getResourceStringDef(RESID_DATE, "Fecha:"), datestr,
								 getResourceStringDef(RESID_HOUR, "Hora:"), timestr);

	strcat(templateReport, line);

	// nombre del template
	if (strlen(templateName) > 0) {
		sprintf(line,"%s\n"
			"%s\n"
			" \n",
			getResourceStringDef(RESID_TEMPLATE_NAME, "Plantilla--------------------"),
			templateName);
	}else{
		sprintf(line,"%s\n"
			"%s\n"
			" \n",
			getResourceStringDef(RESID_TEMPLATE_NAME, "Plantilla--------------------"),
			getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
	}
	strcat(templateReport, line);

	// estado
	sprintf(line,"%s\n",
		getResourceStringDef(RESID_TEMPLATE_STATUS, "Estado-----------------------"));
	strcat(templateReport, line);
	strcat(templateReport, buffResult);
	strcat(templateReport, " \n");
	strcat(templateReport, "\n*****************************\n");

	strcat(templateReport, "\n \n \n");

	// Mando a imprimir el documento generado
	tree = [[XMLConstructor getInstance] buildXML: templateReport];
	[[PrinterSpooler getInstance] addPrintingJob: TEXT_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree];

	free(templateReport);

}

/**/
- (BOOL) loadFilesList
{
	FILE *f;
	char fileName[200];
	char token[500];
	char tok[500];
	STRING_TOKENIZER tokenizer;
	STRING_TOKENIZER tk;
	char buffer[500];
	char *index;
	TemplateDataFile *dFile;
	long fsize = 0;
	char name[100];
	
	strcpy(fileName, TEMPLATE_FILE_PATH);
	strcat(fileName, FILES_LIST_FILE_NAME);

	f = fopen(fileName, "r");
	if (!f) return FALSE;

	tokenizer = [StringTokenizer new];
	[tokenizer setTrimMode: TRIM_NONE];
	[tokenizer setDelimiter: "\012"];

	tk = [StringTokenizer new];
	[tk setTrimMode: TRIM_NONE];
	[tk setDelimiter: ","];

	// limpio la lista
	[filesList removeAll];

	// Cargo la lista
	while (!feof(f)) {
	
		if (!fgets(buffer, 500, f)) break;

		[tokenizer restart];
		[tokenizer setText: buffer];

		if ([tokenizer hasMoreTokens]){
			[tokenizer getNextToken: token];

			// separo el nombre del tamano
			[tk restart];
			[tk setText: token];
			name[0] = '\0';
			if ([tk hasMoreTokens]){
				[tk getNextToken: tok];
				stringcpy(name, tok);
			}
			fsize = 0;
			if ([tk hasMoreTokens]){
				[tk getNextToken: tok];
				fsize = atoi(tok);
			}

			index = strstr(trim(token), ".cmp");
			if (index) stringcpy(templateName, name);

			// agrego el nombre del archivo
			dFile = malloc(sizeof(TemplateDataFile));
			stringcpy(dFile->fileName, name);
			dFile->fileSize = fsize;
			[filesList add: dFile];
			//doLog(0,"Agrego a la lista el archivo: %s (size: %ld)\n", name, fsize);
		}
	}

	[tokenizer free];
	[tk free];
	fclose(f);

	return TRUE;
}

/**/
- (COLLECTION) getFilesList
{
	return filesList;
}

/**/
- (void) setCanProccessTemplate: (BOOL) aValue
{
	canProccess = aValue;
}

/**/
- (BOOL) canProccessTemplate
{
	return ((canProccess) && (strlen(templateName) > 0));
}

/**/
- (void) createFilesListFile
{
	char fileName[200];
	FILE *f;
	long fSize = 0;
	char fileTemplateName[200];

	strcpy(fileName, TEMPLATE_FILE_PATH);
	strcat(fileName, FILES_LIST_FILE_NAME);

	strcpy(fileTemplateName, TEMPLATE_FILE_PATH);
	strcat(fileTemplateName, templateName);

	if (strlen(templateName) > 0){
		//doLog(0,"-----> CREO NUEVAMENTE EL ARCHIVO %s <-----\n", fileName);
	
		f = fopen(fileName, "w+");
	
		fSize = [[FileManager getDefaultInstance] getFilesize: fileTemplateName];
		fprintf(f, "%s,%ld\012", templateName, fSize);
	
		fclose(f);
	}
}

/**/
- (void) createStartTemplateFile
{
	char fileName[200];
	FILE *f;

	strcpy(fileName, START_TEMPLATE_FILE_NAME);

	//doLog(0,"-----> CREO EL ARCHIVO %s <-----\n", fileName);

	f = fopen(fileName, "w+");
	fprintf(f, "Comienzo de la ejecucion del template.");
	fclose(f);
}

/**/
- (void) encode: (char *) aFileName path: (char *) aPath
{
	id cipherManager;
	int fSize;
	char fileName[200];
	char fileNameAux[200];

	fileName[0] = '\0';
	stringcpy(fileName, aPath);
	strcat(fileName, aFileName);

	fileNameAux[0] = '\0';
	stringcpy(fileNameAux, aPath);
	strcat(fileNameAux, "auxFile.enc");

	cipherManager = [CipherManager new];
	fSize = [[FileManager getDefaultInstance] getFilesize: fileName];
	[cipherManager encodeFile: fileName destination: fileNameAux size: fSize];
  unlink(fileName); // borro el archivo sin encriptar
  rename(fileNameAux,fileName); // renombre el archivo encriptado
	[cipherManager free];
}

/**/
- (void) decodeTemplate
{
	if (strlen(templateName) > 0)
		[self decode: templateName path: TEMPLATE_FILE_PATH];
}

/**/
- (void) decode: (char *) aFileName path: (char *) aPath
{
	id cipherManager;
	int fSize;
	char fileName[200];
	char fileNameAux[200];

	fileName[0] = '\0';
	stringcpy(fileName, aPath);
	strcat(fileName, aFileName);

	fileNameAux[0] = '\0';
	stringcpy(fileNameAux, aPath);
	strcat(fileNameAux, "auxFile.dec");

	cipherManager = [CipherManager new];
	fSize = [[FileManager getDefaultInstance] getFilesize: fileName];
	[cipherManager decodeFile: fileName destination: fileNameAux size: fSize];
  unlink(fileName); // borro el archivo encriptado
  rename(fileNameAux,fileName); // renombre el archivo desencriptado
	[cipherManager free];
}

/**/
- (void) abortProccess: (BOOL) aDelInitialFile delStartFile: (BOOL) aDelStartFile
{
	// borro el archivo de lista de archivos
	[self deleteFilesListFile];

	// borro el template
	[self deleteTemplateFile];

	// borro el archivo de estado inicial
	if (aDelInitialFile)
		[self deleteInitialStateFile];

	// borro el archivo de inicio del template
	if (aDelStartFile)
		[self deleteStartTemplateFile];

	[self setCanProccessTemplate: FALSE];
}

@end
