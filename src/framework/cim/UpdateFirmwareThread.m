#include "UpdateFirmwareThread.h"
#include "AbstractAcceptor.h"
#include "CimManager.h"
#include "system/util/all.h"
#include "InputKeyboardManager.h"
#include "Audit.h"
#include "MessageHandler.h"
#include "TemplateParser.h"
#include "UserManager.h"
#include <unistd.h>

#define UPDATE_FIRMWARE_CHECK_TIME			60000		// 60 segundos


/**/
typedef struct {
	char file[255];
	COLLECTION acceptors;
} IniFileInfo;

@implementation UpdateFirmwareThread

static UPDATE_FIRMWARE_THREAD singleInstance = NULL; 

- (BOOL) unzipFile: (char *) aFileName;
- (BOOL) unzipInnerBoardFile: (char *) aFileName;
- (void) setIniFileInfo: (char *) anAcceptorSettingIdList fileName: (char *) aFileName;

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}
 
/**/
- initialize
{
	*myCurrentFile = '\0';
	myUpgradeInProgress = FALSE;
	myCanDeleteUpgrade = TRUE;
	return self;
}

/**/
+ getInstance
{
  return [self new];
}

/**/
- (BOOL) isUpgradeInProgress
{
	return myUpgradeInProgress;
}

/**/
- (void) onFirmwareUpdateProgress: (BILL_ACCEPTOR) anAcceptor progress: (int) aProgress
{
	
	if (aProgress == 100) {
		myUpgradeIsSuccess = TRUE;
		myUpgradeIsFinish = TRUE;

		[Audit auditEvent: NULL eventId: Event_VALIDATOR_FIRMWARE_UPGRADE 
			additional: myCurrentFile station: [[anAcceptor getAcceptorSettings] getAcceptorId] logRemoteSystem: FALSE];

		if (myUpdateFirmwareForm){
			[myUpdateFirmwareForm setMessage: getResourceStringDef(RESID_UPDATE_SUCCESS, "Actualizacion Exitosa!")];
			[myUpdateFirmwareForm setMessage2: ""];
		}

	}

	if (aProgress == 255) {

		myUpgradeIsSuccess = FALSE;
		myUpgradeIsFinish = TRUE;

		if (myUpdateFirmwareForm){
			[myUpdateFirmwareForm setMessage: getResourceStringDef(RESID_UPDATE_ERROR, "Error al Actualizar!")];
			[myUpdateFirmwareForm setMessage2: ""];
		}

		[Audit auditEvent: NULL eventId: Event_VALIDATOR_FIRMWARE_UPGRADE_ERROR 
			additional: myCurrentFile station: [[anAcceptor getAcceptorSettings] getAcceptorId] logRemoteSystem: FALSE];

		return;

	}

	if (myUpdateFirmwareForm) {
		[myUpdateFirmwareForm setProgress: aProgress];
	}

}

/**/
- (void) startInnerBoardUpgrade: (char *) aFile
{
	char firmwareFile[255];
	char file[255];
  char myAdditional[255];

	myUpgradeInProgress = TRUE;

	myUpdateFirmwareForm = [JUpdateFirmwareForm createForm: NULL];
									
	myOldForm = [JWindow getActiveWindow];
	if (myOldForm) [myOldForm deactivateWindow];
	
	[[InputKeyboardManager getInstance] setIgnoreKeyEvents: TRUE];

	[myUpdateFirmwareForm showForm];
	[myUpdateFirmwareForm setMessage: getResourceStringDef(RESID_UPDATING_FIRMWARE, "Actualizando Firm...")];
	[myUpdateFirmwareForm setMessage2: getResourceStringDef(RESID_UPD_FIRM_DONT_SHOTDOWN_EQUIP, "NO APAGUE EL EQUIPO!")];
	
	stringcpy(file, aFile);

    //************************* logcoment
    //	doLog(0,"Descomprimiendo archivo de actualizacion de Inner Board %s\n", file);

	stringcpy(myCurrentFile, file);

	[myUpdateFirmwareForm setProgress: 30];

	if ([self unzipInnerBoardFile: file]) {
		[myUpdateFirmwareForm setProgress: 50];
    //************************* logcoment
//		doLog(0,"Pudo descomprimir el archivo\n");
	} else {
		return;
	}

	[myUpdateFirmwareForm setMessage3: getResourceStringDef(RESID_UPDATING_INNERBOARD_FIRMWARE, "Actualizando Placa..")];

	sprintf(firmwareFile, "%s/innerboard_update/innerboard.bin", UNZIP_PATH);
    //************************* logcoment
//  doLog(0,"estoy entrando en safeboxhall para hacer el update\n");
	if (![SafeBoxHAL updateInnerBoardFirmware: 8 path: firmwareFile]) {
			// Tiro un error el metodo de actualizacion
			myUpgradeIsSuccess = FALSE;
          //************************* logcoment
//doLog(0,"******************tiro error*************************************\n");
			[myUpdateFirmwareForm setMessage: getResourceStringDef(RESID_UPDATE_ERROR, "Error al Actualizar!")];
			[myUpdateFirmwareForm setMessage2: ""];

			[Audit auditEvent: NULL eventId: Event_INNERDBOARD_FIRMWARE_UPGRADE_ERROR 
				additional: myCurrentFile station: 0 logRemoteSystem: FALSE];

			return;
	}
	[myUpdateFirmwareForm setProgress: 60];
	msleep(2000);
	[myUpdateFirmwareForm setProgress: 80];
	msleep(2000);
	[myUpdateFirmwareForm setProgress: 100];
  sprintf(myAdditional,"%s %s - %s",getResourceStringDef(RESID_VERSION, "Version:"),mySafeBox.version,myCurrentFile) ;
  [Audit auditEvent: NULL eventId: Event_INNERDBOARD_FIRMWARE_UPGRADE additional: myAdditional station: 0 logRemoteSystem: FALSE];				
	[myUpdateFirmwareForm setMessage: getResourceStringDef(RESID_UPDATE_SUCCESS, "Actualizacion Exitosa!")];
	[myUpdateFirmwareForm setMessage2: ""];
	[myUpdateFirmwareForm setMessage3: ""];

	msleep(1000);

}

/**/
- (void) startUpgrade: (IniFileInfo *) aIniFileInfo
{
	BILL_ACCEPTOR acceptor;
	BILL_ACCEPTOR acceptorAux;
	int i,j;
	char firmwareFile[255];
	int iTry;
	char acceptorsIdList[50];
	char auxAcceptorId[10];

	myUpgradeInProgress = TRUE;

	myUpgradeIsFinish = FALSE;
	myUpgradeIsSuccess = FALSE;

	myUpdateFirmwareForm = [JUpdateFirmwareForm createForm: NULL];
									
	myOldForm = [JWindow getActiveWindow];
	if (myOldForm) [myOldForm deactivateWindow];
	
	[[InputKeyboardManager getInstance] setIgnoreKeyEvents: TRUE];

	[myUpdateFirmwareForm showForm];

    //************************* logcoment
//	doLog(0,"Descomprimiendo archivo de actualizacion %s\n", aIniFileInfo->file);

	stringcpy(myCurrentFile, aIniFileInfo->file);

	if ([self unzipFile: aIniFileInfo->file]) {
//		doLog(0,"Pudo descomprimir el archivo\n");
    //************************* logcoment
        
	} else {
		return;
	}

	sprintf(firmwareFile, "%s/firmware_update/firmware.bin", UNZIP_PATH);

	myCanDeleteUpgrade = TRUE;
	for (i = 0; i < [aIniFileInfo->acceptors size]; ++i) {

		acceptor = [aIniFileInfo->acceptors at: i];

		// antes de arrancar con la actualizacion del validador verifico que no este en modo bateria
		if ([SafeBoxHAL getPowerStatus] == PowerStatus_BACKUP) {
    //************************* logcoment
//			doLog(0,"No arranco la actualizacion de firmware del validador por estar con bateria.\n");

			// Genero nuevamente el archivo .ini el cual indica los validadores a
			// actualizar. De esta manera si el quipo se apaga por bateria baja,
			// al iniciar puedo retomar con la actualizacion del validador restante. (si es
			// que lo hay)
			acceptorsIdList[0] = '\0';
			for (j = i; j < [aIniFileInfo->acceptors size]; ++j) {
				acceptorAux = [aIniFileInfo->acceptors at: j];
				sprintf(auxAcceptorId, "%d", [[acceptorAux getAcceptorSettings] getAcceptorId]);
				if (strlen(acceptorsIdList) != 0)
					strcat(acceptorsIdList, ",");
				strcat(acceptorsIdList, auxAcceptorId);
			}

			[self setIniFileInfo: acceptorsIdList fileName: aIniFileInfo->file];
			myCanDeleteUpgrade = FALSE;

			break;
		}

		for (iTry = 0; iTry < 2; ++iTry) {
    //************************* logcoment
//			doLog(0,"JUpdateFirmwareForm -> comenzo actualizacion de firmware\n");
			[myUpdateFirmwareForm setMessage: getResourceStringDef(RESID_UPDATING_FIRMWARE, "Actualizando Firm...")];
			[myUpdateFirmwareForm setMessage2: getResourceStringDef(RESID_UPD_FIRM_DONT_SHOTDOWN_EQUIP, "NO APAGUE EL EQUIPO!")];
			[myUpdateFirmwareForm setBillAcceptor: acceptor];

			if (![acceptor updateFirmware: firmwareFile observer: self]) {
	
					// Tiro un error el metodo de actualizacion
					myUpgradeIsSuccess = FALSE;
					return;
			}

			while (!myUpgradeIsFinish) msleep(1000);

			msleep(2000);

			if (myUpgradeIsSuccess) break;

		}
	}

}

/**/
- (void) stopUpgrade
{
	[myUpdateFirmwareForm closeForm];
	[[InputKeyboardManager getInstance] setIgnoreKeyEvents: FALSE];
	[myUpdateFirmwareForm free];
	if (myOldForm) [myOldForm activateWindow];
	myUpdateFirmwareForm = NULL;
	myUpgradeInProgress = FALSE;
}

/**/
- (BOOL) unzipFile: (char *) aFileName
{
	char command[512];
	int result;

	sprintf(command, "rm -r %s/firmware_update", UNZIP_PATH);
	result = system(command);
    //************************* logcoment
//	doLog(0,"Ejecutando comando %s, resultado = %d\n", command, result);

	sprintf(command, "mkdir %s/firmware_update", UNZIP_PATH);
	result = system(command);
    //************************* logcoment
//	doLog(0,"Ejecutando comando %s, resultado = %d\n", command, result);
	if (result != 0) return FALSE;

	sprintf(command, "gunzip -c %s/%s 2> /dev/null | tar -xvf - -C %s/firmware_update/ 2> /dev/null", UPDATE_FIRMWARE_PATH,
		aFileName, UNZIP_PATH);
    //************************* logcoment
//	doLog(0,"Ejecutando comando %s\n", command);
	result = system(command);
    //************************* logcoment
//	doLog(0,"Comando ejecutado %s, resultado = %d\n", command, result);
	if (result != 0) return FALSE;

	return TRUE;
}

/**/
- (BOOL) unzipInnerBoardFile: (char *) aFileName
{
	char command[512];
	int result;

	sprintf(command, "rm -r %s/innerboard_update", UNZIP_PATH);
	result = system(command);
    //************************* logcoment
//	doLog(0,"Ejecutando comando %s, resultado = %d\n", command, result);

	sprintf(command, "mkdir %s/innerboard_update", UNZIP_PATH);
	result = system(command);
    //************************* logcoment
//	doLog(0,"Ejecutando comando %s, resultado = %d\n", command, result);
	if (result != 0) return FALSE;

	sprintf(command, "gunzip -c %s/%s 2> /dev/null | tar -xvf - -C %s/innerboard_update/ 2> /dev/null", UPDATE_FIRMWARE_PATH,
		aFileName, UNZIP_PATH);
    //************************* logcoment
//	doLog(0,"Ejecutando comando %s\n", command);
	result = system(command);
    //************************* logcoment
//	doLog(0,"Comando ejecutado %s, resultado = %d\n", command, result);
	if (result != 0) return FALSE;

	return TRUE;
}

/**/
- (BOOL) hasPendingUpdates
{
	COLLECTION files;
	BOOL result = FALSE;

	files = [File findFilesByExt: UPDATE_FIRMWARE_PATH 
		extension: "ini" 
		caseSensitive: FALSE 
		startsWith: UPDATE_START_WITH_NAME];

	result = [files size] > 0;

	[files freePointers];
	[files free];

	return result;
}

/**/
- (void) setIniFileInfo: (char *) anAcceptorSettingIdList fileName: (char *) aFileName
{
	FILE *f;

    //************************* logcoment
//	doLog(0,"-----> CREO NUEVAMENTE EL ARCHIVO %s <-----\n", myCompleteFileName);

	f = fopen(myCompleteFileName, "w+");

	fprintf(f, "Acceptors=%s\012", anAcceptorSettingIdList);
	fprintf(f, "File=%s", aFileName);

	fclose(f);
}

/**/
- (BOOL) getIniFileInfo: (char *) aFileName iniFileInfo: (IniFileInfo *) aIniFileInfo
{
	CONFIGURATION iniFile;
	char *acceptors;
	char *file;
	STRING_TOKENIZER tokenizer;
	char token[50];
	ABSTRACT_ACCEPTOR acceptor;

	iniFile = [[Configuration new] initWithFileName: aFileName];

	file = [iniFile getParamAsString: "File"];
	acceptors = [iniFile getParamAsString: "Acceptors"];
	
	stringcpy(aIniFileInfo->file, file);
	tokenizer = [[StringTokenizer new] initTokenizer: acceptors delimiter: ","];

	[aIniFileInfo->acceptors removeAll];

	while ([tokenizer hasMoreTokens]) {

		[tokenizer getNextToken: token];
		acceptor = [[[CimManager getInstance] getCim] getAcceptorById: atoi(token)];

		if (acceptor != NULL && [[acceptor getAcceptorSettings] getAcceptorType] == AcceptorType_VALIDATOR) {

			[aIniFileInfo->acceptors add: acceptor];

		}/* else {

    //************************* logcoment
			doLog(0,"UpdateFirmwareThread -> el dispositivo %s no se encuentra o no es un validador\n", token);

		}*/

	}

	[tokenizer free];
	[iniFile free];

	return TRUE;

}

/**/
- (void) checkForNewUpdatesInnerBoard
{
	COLLECTION files;
	char *fileName;
	int i;

	files = [File findFilesByExt: UPDATE_FIRMWARE_PATH 
		extension: "gz" 
		caseSensitive: FALSE 
		startsWith: UPDATE_INNERBOARD_WITH_NAME];

	for (i = 0; i < [files size]; ++i) {

		fileName = (char *)[files at: i];

		sprintf(myCompleteInnerboardFileName, "%s/%s", UPDATE_FIRMWARE_PATH, fileName);

    //************************* logcoment
//		doLog(0,"Encontro un nuevo archivo de actualizacion de firmware de Innerboard |%s|\n", myCompleteInnerboardFileName);

		[self startInnerBoardUpgrade: fileName];
		[self stopUpgrade];

		unlink(myCompleteInnerboardFileName);
		
	}

	[files freePointers];
	[files free];
}

/**/
- (void) checkForNewUpdates
{
	COLLECTION files;
	char *fileName;
	int i;
	IniFileInfo iniFileInfo;

	files = [File findFilesByExt: UPDATE_FIRMWARE_PATH 
		extension: "ini" 
		caseSensitive: FALSE 
		startsWith: UPDATE_START_WITH_NAME];

    //************************* logcoment
//	doLog(0,"CheckFornewupdates filesqty |%d|\n", [files size]);
	for (i = 0; i < [files size]; ++i) {

		iniFileInfo.acceptors = [Collection new];

		fileName = (char *)[files at: i];

		sprintf(myCompleteFileName, "%s/%s", UPDATE_FIRMWARE_PATH, fileName);

    //************************* logcoment
//		doLog(0,"Encontro un nuevo archivo de actualizacion de firmware |%s|\n", myCompleteFileName);

		[self getIniFileInfo: myCompleteFileName iniFileInfo: &iniFileInfo];

		if ([iniFileInfo.acceptors size] != 0) {
			[self startUpgrade: &iniFileInfo];
			[self stopUpgrade];
		}

		[iniFileInfo.acceptors free];

		if (myCanDeleteUpgrade) {
			unlink(myCompleteFileName);
			sprintf(myCompleteFileName, "%s/%s", UPDATE_FIRMWARE_PATH, iniFileInfo.file);
			unlink(myCompleteFileName);
		}
		
	}

	[files freePointers];
	[files free];
}

/**/
- (void) run 
{

    //************************* logcoment
//	doLog(0,"Iniciando hilo de actualizacion de firmware...\n");

  TRY

	while (TRUE) {

		msleep(UPDATE_FIRMWARE_CHECK_TIME);

		// Controlo que el equipo ya halla aplicado el template y que el usuario
		// admin NO se haya logueado en cuyo caso no
		// debo controlar que el sistema este idle. Esto se hace para que puedan enviar
		// el upgrade por FTP desde el CMP (en la inicializacion) y que se pueda aplicar
		// el upgrade con la puerta abierta.
		if (![[TemplateParser getInstance] isInitialState]) {
			if (![[UserManager getInstance] isAdminInInitialState]) {
				// Si el sistema esta realizando alguna operacion no actualiza el firmware
				if (![[CimManager getInstance] isSystemIdle]) {	
					//doLog(0,"Iniciando hilo de actualizacion de firmware  SISTEMAS IDLE...\n");
	
					continue;
 				}
			}
		}

		// Validadores
		[self checkForNewUpdates];

		// InnerBoard
		[self checkForNewUpdatesInnerBoard];
	
	}

	CATCH

    //************************* logcoment
//			doLog(0,"Excepcion en el hilo de actualizacion de firmware...\n");
			ex_printfmt();

	END_TRY


}



@end
