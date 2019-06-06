#include "CommercialStateMgr.h"
#include "Persistence.h"
#include "util.h"
#include "JSystem.h"
#include "SafeBoxHAL.h"
#include "CtSystem.h"
#include "TelesupervisionManager.h"
#include "CimBackup.h"
#include "TelesupDefs.h"
#include "ReportXMLConstructor.h"
#include "PrinterSpooler.h"
#include "scew.h"
#include "CimGeneralSettings.h"
#include "JExceptionForm.h"
#include "CimManager.h"
#include "UserManager.h"
#include "Buzzer.h"
#include "TemplateParser.h"
#include "CommercialUtils.h"
#include <stdio.h>
#include "Audit.h"

//#define printd(args...) doLog(0,args)
//#define printd(args...)

#ifdef __UCLINUX
#define BASE_KEY_FILES_PATH "/pk"
#else
#define BASE_KEY_FILES_PATH "./pk"
#endif

static id singleInstance = NULL;


@implementation CommercialStateMgr

- (void) copyCommercialStateFrom: (id) aCommercialStateSrc commercialStateDest: (id) aCommercialStateDest;
- (void) verifyModulesSign;
- (void) verifyCurrentState: (id) aCommercialState;

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
	FILE* fpub;
	FILE* fpriv;
	FILE* fcert;

	// Levantar las claves
	myLocaldsa = DSA_new();
	myLSdsa = DSA_new();

	// Levanta las claves
	fpub = fopen(BASE_KEY_FILES_PATH "/public.der","r"); 
	fpriv = fopen(BASE_KEY_FILES_PATH "/private.der", "r");

	if (fpub == NULL) THROW(KEY_FILES_NOT_FOUND_EX);
	if (fpriv == NULL) THROW(KEY_FILES_NOT_FOUND_EX);

	// Coloca las claves en la estructura interna
  d2i_DSA_PUBKEY_fp(fpub, &myLocaldsa);
 	d2i_DSAPrivateKey_fp(fpriv, &myLocaldsa);

  fclose(fpub);
  fclose(fpriv);

	// Levanta las claves
	fcert = fopen(BASE_KEY_FILES_PATH "/LSpublic.der","r"); 

	if (fcert == NULL) THROW(KEY_FILES_NOT_FOUND_EX);

	// Coloca las claves en la estructura intera
  d2i_DSA_PUBKEY_fp(fcert, &myLSdsa);

	// Setea el estado actual
	myCurrentCommercialState = [[[Persistence getInstance] getCommercialStateDAO] loadById: 1];
	[myCurrentCommercialState setSignatureVerification: myLSdsa];

	// Esto es por cuestiones de compatibilidad ya que antes existia el estado
	// Blocked use y ahora no existe mas
	[self verifyCurrentState: myCurrentCommercialState];

  myChangingState = FALSE;

  myModules = [[[Persistence getInstance] getLicenceModuleDAO] loadAll];

	[self verifyModulesSign];

  return self;
}

/**/
- (id) getCurrentCommercialState
{
	return myCurrentCommercialState;
}

/**/
- (void) doChangeCommercialState: (id) aCommercialState 
{

//	doLog(0,"****************************************\n");
//	doLog(0,"DO_CHANGE_COMMERCIAL_STATE\n");
//	doLog(0,"****************************************\n");

	if ([aCommercialState getRequestResult] > RESULT_OK) {
		[self generateReport: aCommercialState];
		return;
	}

	if ([self needsAuthentication: [aCommercialState getNextCommState]]) {

		if (![aCommercialState verifyRemoteSignature: myLSdsa]) {

			// tira una excepcion por ahora hace un return
		//	doLog(0,"Error en la verificacion\n"); 
			[self generateReport: aCommercialState];

			THROW(SIGN_AUTHORIZATION_ERROR_EX);
			return;

		} 
	}

	// solo hace el cambio de estado si no pasa a factory blocked
	// porque puede pasar que no llegue a completar el borrado de 
	// la placa entonces queda un estado ficticio.


		[self copyCommercialStateFrom: aCommercialState commercialStateDest: myCurrentCommercialState];
		[myCurrentCommercialState setOldState: [myCurrentCommercialState getCommState]];
		[myCurrentCommercialState setCommState: [aCommercialState getNextCommState]];

		[myCurrentCommercialState setRequestResult: RESULT_OK];

		if ([aCommercialState getNextCommState] != SYSTEM_FACTORY_BLOCKED) {
			[myCurrentCommercialState applyChanges];
			[self generateReport: myCurrentCommercialState];
		}
	
		[myCurrentCommercialState setSignatureVerification: myLSdsa];
	
		// actualiza los modulos
		[self updateModulesState: [myCurrentCommercialState getOldState] currentState: [myCurrentCommercialState getCommState]];

}

/**/
- (BOOL) needsAuthentication: (CommercialStateType) aNextCommState 
{

	if (aNextCommState == SYSTEM_TEST_PIMS) return TRUE;
	if (aNextCommState == SYSTEM_PRODUCTION_PIMS) return TRUE;

	return FALSE;
}

/**/
- (void) setPendingCommercialStateChange: (id) aPendingCommercialStateChange
{
//	doLog(0,"SETEA EL ESTADO PENDIENTE DE SUPERVISAR\n");
	myPendingCommercialStateChange = aPendingCommercialStateChange;
}

/**/
- (id) getPendingCommercialStateChange
{
	return myPendingCommercialStateChange;
}

/**/
- (void) removePendingCommercialStateChange
{
	//doLog(0,"ELIMINA EL ESTADO PENDIENTE DE SUPERVISAR\n");
//	if (myPendingCommercialStateChange) [myPendingCommercialStateChange free];
//	myPendingCommercialStateChange = NULL;
}

/**/
- (char*) getCommercialStateSignature: (id) aCommercialState
{
	return [aCommercialState getSignature: myLocaldsa];
}

/**/
- (BOOL) canExecutePimsSupervision
{
	return [myCurrentCommercialState _canExecutePimsSupervision];
}

/**/
- (void) changeSystemStatus
{
	char command[512];
	id telesup;
	int result;
	int oldState = [myCurrentCommercialState getOldState];
	int state = [myCurrentCommercialState getCommState];
	int tryMaxValue = 0;

//	doLog(0,"CHANGE SYSTEM STATUS!!!!!!!!!!!!!\n");

	// Si no dio OK y viene de una supevision
	if ((myPendingCommercialStateChange) && ([myPendingCommercialStateChange getRequestResult] != RESULT_OK)) {
	//	doLog(0,"hay un estado pendiente\n");
		return;
	}

	myChangingState = TRUE;

	//cualquier estado -> Factory blocked ---- borra todo.
	if (state == SYSTEM_FACTORY_BLOCKED) {

	//	doLog(0,"BORRA TODO! \n");

		// deshabilito el buzzer para evitar que suene al tener la puerta abierta.
		[[Buzzer getInstance] stopAndDisableBuzzer];

		[JExceptionForm showProcessForm: getResourceStringDef(RESID_DELETING_DATA_DONT_CLOSE_DOOR, "Deleting data please wait....")];

		TRY
			// Borrar todo de la placa
		//	doLog(0,"borra los usuarios de la placa\n");
			[SafeBoxHAL sbFormatUsers];
	
			// Borrar todo de la placa
		//	doLog(0,"borra todo de la placa\n");
			[SafeBoxHAL fsBlank];
	
			// Borrar todo el trafico y settings de /data
		//	doLog(0,"borra todo el trafico y settings de /data\n");
	
			sprintf(command, "sh %s", BASE_APP_PATH "/data/clean");
		//	doLog(0,"Ejecutando comando %s\n", command);
			result = system(command);
	
			// creo nuevamente el archivo initial.stt para que quede el equipo como en estado inicial
			[[TemplateParser getInstance] createInitialStateFile];

			[self generateReport: myCurrentCommercialState];

			while (([[PrinterSpooler getInstance] getJobCount] > 0) && (tryMaxValue < 5)) {	
				//	doLog(0,"No es posible imprimir el reporte de cambio de estado a Factory Blocked \n");
					++tryMaxValue;
					msleep(1000);
			}
			
		CATCH

		//	doLog(0,"Ha surgido una excepcion al blanquear el sistema\n");
			ex_printfmt();

			[JExceptionForm showProcessForm: getResourceStringDef(RESID_ERROR_RESETING_SYSTEM, "Error borrando datos.Reiniciando.")];

		END_TRY

		// Reboot system
	//	doLog(0,"reinicia el sistema\n");
		[[CtSystem getInstance] shutdownSystem];
		system("reboot");

		return;
	}

	// SYSTEM_TEST_STAND_ALONE --> SYSTEM_PRODUCTION_STAND_ALONE 
	// SYSTEM_TEST_PIMS --> SYSTEM_PRODUCTION_PIMS 
  // ---- resetea la supervision y borra todos los movimientos menos las auditorias y las configuraciones

	if ( ((oldState == SYSTEM_TEST_STAND_ALONE) && (state == SYSTEM_PRODUCTION_STAND_ALONE)) ||
			 ((oldState == SYSTEM_TEST_STAND_ALONE) && (state == SYSTEM_PRODUCTION_PIMS)) ||
			 ((oldState == SYSTEM_TEST_PIMS) && (state == SYSTEM_PRODUCTION_PIMS)) ) {

		// Modificar supervision y colocar los valores en cero
	//	doLog(0,"actualiza los datos de supervision\n");
		telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];
	
		if (telesup) {
			[telesup setLastAttemptDateTime: 0];
			[telesup setLastSuceedTelesupDateTime: 0];
			[telesup setLastTelesupDepositNumber: 0];
			[telesup setLastTelesupExtractionNumber: 0];
			[telesup setLastTelesupAlarmId: 0];
			[telesup setLastTelesupZCloseNumber: 0];
			[telesup setLastTelesupXCloseNumber: 0];
			[telesup applyChanges];
		}

		[JExceptionForm showProcessForm: getResourceStringDef(RESID_DELETING_DATA, "Deleting data please wait....")];

		// borra los depositos
		[SafeBoxHAL fsReInitFile: 3];

		// borra los detalles de los depositos
		[SafeBoxHAL fsReInitFile: 4];

		// borra las extracciones
		[SafeBoxHAL fsReInitFile: 5];

		// borra los detalles de las extracciones
		[SafeBoxHAL fsReInitFile: 6];

		// borra los x/z
		[SafeBoxHAL fsReInitFile: 7];

		sprintf(command, "sh %s", BASE_APP_PATH "/data/clean_wo_audits");
	//	doLog(0,"Ejecutando comando %s\n", command);
		result = system(command);

		// resetea los proximos nros de ticket, retiro y cierre. (Los pone en 1)
	//	doLog(0,"actualiza los datos proximos numeros de ticket, retiro y cierre\n");
		[[CimGeneralSettings getInstance] setNextDepositNumber: 1];
		[[CimGeneralSettings getInstance] setNextExtractionNumber: 1];
		[[CimGeneralSettings getInstance] setNextXNumber: 1];
		[[CimGeneralSettings getInstance] setNextZNumber: 1];
		[[CimGeneralSettings getInstance] setValidateNextNumbers: FALSE];
		[[CimGeneralSettings getInstance] applyChanges];

		// Reboot system
	//	doLog(0,"reinicia el sistema\n");
		[[CtSystem getInstance] shutdownSystem];
		//system("reboot");

		return;
	}

	// SYSTEM_TEST_PIMS --> SYSTEM_TEST_STAND_ALONE 
	// SYSTEM_PRODUCTION_PIMS --> SYSTEM_PRODUCTION_STAND_ALONE
  // ---- resetea la supervision 

	if ( ((oldState == SYSTEM_TEST_PIMS) && (state == SYSTEM_TEST_STAND_ALONE)) ||
			 ((oldState == SYSTEM_PRODUCTION_PIMS) && (state == SYSTEM_PRODUCTION_STAND_ALONE)) ) {

		// Modificar supervision y colocar los valores en cero
	//	doLog(0,"actualiza los datos de supervision\n");
		telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];
	
		if (telesup) {
			[telesup setLastAttemptDateTime: 0];
			[telesup setLastSuceedTelesupDateTime: 0];
			[telesup setLastTelesupDepositNumber: 0];
			[telesup setLastTelesupExtractionNumber: 0];
			[telesup setLastTelesupAlarmId: 0];
			[telesup setLastTelesupZCloseNumber: 0];
			[telesup setLastTelesupXCloseNumber: 0];
			[telesup applyChanges];
		}

		myChangingState = FALSE;
		return;
	}

	myChangingState = FALSE;

	// Se refresca el menu principal
	if ([[UserManager getInstance] getUserLoggedIn])
		[[JSystem getInstance] onRefreshMenu];
	
}

/**/
- (void) copyCommercialStateFrom: (id) aCommercialStateSrc commercialStateDest: (id) aCommercialStateDest
{

	[aCommercialStateDest setOldState: [aCommercialStateSrc getOldState]];
	[aCommercialStateDest setCommState: [aCommercialStateSrc getCommState]];
	[aCommercialStateDest setNextCommState: [aCommercialStateSrc getNextCommState]];
	[aCommercialStateDest setAuthorizationId: [aCommercialStateSrc getAuthorizationId]];
	[aCommercialStateDest setRequestDateTime: [aCommercialStateSrc getRequestDateTime]];
	[aCommercialStateDest setRemoteSignatureLen: [aCommercialStateSrc getRemoteSignatureLen]];
	[aCommercialStateDest setRemoteSignature: [aCommercialStateSrc getRemoteSignature] remoteSignatureLen: [aCommercialStateSrc
 getRemoteSignatureLen]];
	[aCommercialStateDest setRequestResult: [aCommercialStateSrc getRequestResult]];
	[aCommercialStateDest setConfirmationResult: 0];
}

/**/
- (void) generateReport: (id) aCommercialState
{
	scew_tree *tree;

	tree = [[ReportXMLConstructor getInstance] buildXML: aCommercialState entityType: COMMERCIAL_STATE_CHANGE_REPORT_PRT isReprint: FALSE];
	[[PrinterSpooler getInstance] addPrintingJob: COMMERCIAL_STATE_CHANGE_REPORT_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];

}

/**/
- (BOOL) isChangingState
{
	return myChangingState;
}

/**/
- (BOOL) canChangeState: (int) aNewState msg: (char*) aMsg
{
	int currentState = [myCurrentCommercialState getCommState];

	printf("Verifica si es posible realizar el cambio de estado de acuerdo al estado del sistema\n");
	printf("currentState = %d nextState = %d\n",  currentState, aNewState);

	// Bloqueado -> Prueba PIMS
	// Bloqueado -> Produccion PIMS
	// Bloqueado -> Prueba Stand alone
	// Bloqueado -> Produccion Stand alone
/*
	if (aCurrentState == SYSTEM_FACTORY_BLOCKED) {
		doLog(0,"Respuesta SI\n");
		return TRUE;
	}
*/
	if ( ((currentState == SYSTEM_TEST_PIMS) && ((aNewState == SYSTEM_PRODUCTION_PIMS) ||
        (aNewState == SYSTEM_FACTORY_BLOCKED) ||  (aNewState == SYSTEM_TEST_STAND_ALONE))) ||	
        ((currentState == SYSTEM_PRODUCTION_PIMS) && ((aNewState == SYSTEM_FACTORY_BLOCKED) ||
		(aNewState == SYSTEM_PRODUCTION_STAND_ALONE))) ||
        ((currentState == SYSTEM_TEST_STAND_ALONE) && ((aNewState == SYSTEM_PRODUCTION_STAND_ALONE) || 
        (aNewState == SYSTEM_FACTORY_BLOCKED) ||
        (aNewState == SYSTEM_PRODUCTION_PIMS) ||  
        (aNewState == SYSTEM_TEST_PIMS))) ||
        ((currentState == SYSTEM_PRODUCTION_STAND_ALONE) && ((aNewState == SYSTEM_FACTORY_BLOCKED) ||
        (aNewState == SYSTEM_PRODUCTION_PIMS))) ) {

        printf("entra a la comparacion\n");
		if (![[CimManager getInstance] isSystemIdleForChangeState: aMsg]) {
			printf("canChangeState -> NO\n");
			return FALSE;
		}
    }

	printf("canChangeState -> SI\n");
	return TRUE;

}

/**/
- (void) verifyCurrentState: (id) aCommercialState
{
	// verifca si el estado es blocked use (si no no hace nada)
	if ([aCommercialState getCommState] != SYSTEM_BLOCKED_USE) return;

//	doLog(0,"El estado es bloqueo de uso!!!\n");


	// verifica de que estado venia
	if ([aCommercialState getOldState] == SYSTEM_TEST_PIMS) {

	//	 doLog(0,"Viene de test pims -> Pasa a test stand alone\n");	
		// si venia de un test pims lo vuelve a test stand alone
		 [aCommercialState setCommState: SYSTEM_TEST_STAND_ALONE];
		 [aCommercialState setOldState: SYSTEM_TEST_PIMS];
	}
	
	if ([aCommercialState getOldState] == SYSTEM_PRODUCTION_PIMS) {
	//	doLog(0,"Viene de production pims -> Pasa a production stand alone\n");	
		// si venia de un production pims lo vuelve a production stand alone
		 [aCommercialState setCommState: SYSTEM_PRODUCTION_STAND_ALONE];
		 [aCommercialState setOldState: SYSTEM_PRODUCTION_PIMS];
	}

	[aCommercialState applyChanges];

}

/***** MODULES *****/

/**/
- (COLLECTION) getModules
{
	return myModules;
}

/**/
- (unsigned char*) buildModuleData: (unsigned char*) data
																	moduleCode: (int) aModuleCode
																	baseDateTime: (datetime_t) aBaseDateTime	
																	expireDateTime: (datetime_t) anExpireDateTime
																	hoursQty: (int) anHoursQty
																	online: (BOOL) isOnline
																	enable: (BOOL) isEnable
																	authorizationId: (int) anAuthorizationId																
{
	char modCode[5];
	char buf2[] = "0000:00:00T00:00:00+00:00\0\0";		
	char buf3[] = "0000:00:00T00:00:00+00:00\0\0";		
	char expireDateTime[40];
	char baseDateTime[40];
	char hQty[10];
	char pimsId[40];
	id telesup;
	char mac[50];
	
	telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];
	
	if (!telesup) stringcpy(pimsId, "0");
	else stringcpy(pimsId, [telesup getRemoteSystemId]);


	sprintf(modCode, "%d", aModuleCode);

	sprintf(baseDateTime, "%s", datetimeToISO8106(buf3, aBaseDateTime));
	sprintf(expireDateTime, "%s", datetimeToISO8106(buf2, anExpireDateTime));
	
//	sprintf(baseDateTime, "%s", "2008-12-22T11:32:04");
	//sprintf(expireDateTime, "%s", "2008-12-22T14:32:03");

	sprintf(hQty, "%d", anHoursQty);

	// Module code
	// Base date time
	// Expire date time
	// Hours qty
	// Online
	// Enable
  // AuthorizationId

	/*doLog(0,"Build module data\n");
	doLog(0,"PimsId = %s\n", pimsId);
	doLog(0,"Module code = %d\n", aModuleCode);
	doLog(0,"Base date time = %s\n", baseDateTime);
	doLog(0,"Expire date time = %s\n", expireDateTime);
	doLog(0,"Hours qty = %d\n", anHoursQty);
	doLog(0,"Online = %d\n", isOnline);
	doLog(0,"IsEnable = %d\n", isEnable);
	doLog(0,"AuthorizationId = %d\n", anAuthorizationId);
*/

	sprintf(data, "%s%s%s%s%s%s%d%d%d", pimsId,  [[CimGeneralSettings getInstance] getMacAddress: mac], modCode, baseDateTime, expireDateTime, hQty, isOnline, isEnable, anAuthorizationId);

//	doLog(0,"data = %s\n", data);

	return data;

}

/**/
- (MODULE) getModuleByCode: (int) aModuleCode
{
  int i;

  for (i=0; i<[myModules size]; ++i) {
    if ([[myModules at: i] getModuleCode] == aModuleCode) return [myModules at: i];
  }

  return NULL;
} 


/**/
- (BOOL) verifyModuleSignature: (int) aModuleCode 
                              baseDateTime: (datetime_t) aBaseDateTime
                              expireDateTime: (datetime_t) anExpireDateTime
                              hoursQty: (int) anHoursQty
															online: (BOOL) isOnline
															enable: (BOOL) isEnable
															authorizationId: (int) anAuthorizationId
                              encodeRemoteSignature: (char*) anEncodeRemoteSignature
{
	unsigned char sign[50];
	int sigLen;
	unsigned char data[200];

	data[0] = '\0';

	[self buildModuleData: data moduleCode: aModuleCode
										baseDateTime: aBaseDateTime
										expireDateTime: anExpireDateTime
										hoursQty: anHoursQty
										online: isOnline
										enable: isEnable
										authorizationId: anAuthorizationId];
										
	sigLen = [CommercialUtils decodeSignature: anEncodeRemoteSignature signature: sign];

	return [CommercialUtils verifySignature: myLSdsa data: data signature: sign signatureLen: sigLen];

}

/**/
- (void) applyModuleLicence: (int) aModuleCode 
                              baseDateTime: (datetime_t) aBaseDateTime
                              expireDateTime: (datetime_t) anExpireDateTime
                              hoursQty: (int) anHoursQty
															online: (BOOL) isOnline
															enable: (BOOL) isEnable
															authorizationId: (int) anAuthorizationId
                              encodeRemoteSignature: (char*) anEncodeRemoteSignature
{
	unsigned char sign[50];
	int sigLen;
  id module = [self getModuleByCode: aModuleCode];

  if (module == NULL) THROW(MODULE_NOT_FOUND_EX);

	// solo reseteo el tiempo transcurrido si cambio la fecha de vencimiento,
	// ya que la pims me envia la licencia siempre.
	if ([module getExpireDateTime] != anExpireDateTime)
  	[module setElapsedTime: 0];

  [module setBaseDateTime: aBaseDateTime];
  [module setExpireDateTime: anExpireDateTime];
  [module setHoursQty: anHoursQty];

  [module setEncodedRemoteSignature: anEncodeRemoteSignature];
  [module setEnable: isEnable];
	[module setOnline: isOnline];
	[module setAuthorizationId: anAuthorizationId];

	sigLen = [CommercialUtils decodeSignature: anEncodeRemoteSignature signature: sign];

	[module setRemoteSignatureLen: sigLen];
	[module setRemoteSignature: sign remoteSignatureLen: sigLen];

  [module applyChanges];

	[module setSignatureVerification: myLSdsa];

	// debug
	[module printInfo];
}

/**/
- (char*) getModuleApplySignature: (int) aModuleCode 
                              baseDateTime: (datetime_t) aBaseDateTime
                              expireDateTime: (datetime_t) anExpireDateTime
                              hoursQty: (int) anHoursQty
															online: (BOOL) isOnline
															enable: (BOOL) isEnable
															authorizationId: (int) anAuthorizationId
                              signatureBuffer: (char*) aSignatureBuffer
{
	unsigned char data[200];

	//doLog(0,"getModuleApplySignature\n");

	[self buildModuleData: data moduleCode: aModuleCode
										baseDateTime: aBaseDateTime
										expireDateTime: anExpireDateTime
										hoursQty: anHoursQty
										online: isOnline
										enable: isEnable
										authorizationId: anAuthorizationId];

	return [CommercialUtils signAndEncodeData: myLocaldsa data: data signature: aSignatureBuffer];

}

/**/
- (void) disableModule: (int) aModuleCode
{
  id module = [self getModuleByCode: aModuleCode];

	if (module == NULL) THROW(MODULE_NOT_FOUND_EX);

	[Audit auditEventCurrentUser: Event_DISABLE_MODULE additional: [module getModuleName] station: [module getModuleCode] logRemoteSystem: FALSE]; 			

	[module setEnable: FALSE];
 	[module applyChanges];
}

/**/
- (void) forceDisable: (int) aModuleCode expireDateTime: (datetime_t) anExpireDateTime
{
  id module = [self getModuleByCode: aModuleCode];

  if (module == NULL) THROW(MODULE_NOT_FOUND_EX);

	[Audit auditEventCurrentUser: Event_FORCE_DISABLE_MODULE additional: [module getModuleName] station: [module getModuleCode] logRemoteSystem: FALSE]; 			

	[module setExpireDateTime: anExpireDateTime];
	[module setElapsedTime: 0];
	[module setEnable: FALSE];
 	[module applyChanges];

//	[module printInfo];
}


/**/
- (BOOL) hasExpiredModules
{
	int i;

    printf("11\n");
	for (i=0; i<[myModules size]; ++i) 
		if (([[myModules at: i] hasExpired]) && ([[myModules at: i] isEnable])) return TRUE;

	return FALSE;
}

/**/
- (COLLECTION) getExpiredModules
{
	int i;
	COLLECTION expiredModules = [Collection new];

    printf("12\n");
	for (i=0; i<[myModules size]; ++i) 
		if (([[myModules at: i] hasExpired]) && ([[myModules at: i] isEnable])) [expiredModules add: [myModules at: i]];

	return expiredModules;
}

/**/
- (char*) getExpiredModulesStr: (char*) anExpireModulesStr
{
	int i;
	char modCode[10];
	COLLECTION expiredModules = [self getExpiredModules];

	anExpireModulesStr[0] = '\0';

	for (i=0; i<[expiredModules size]; ++i) {

		sprintf(modCode, "%d", [[expiredModules at: i] getModuleCode]);

		if (i==0) strcat(anExpireModulesStr, modCode);
		else {
			strcat(anExpireModulesStr, ",");
			strcat(anExpireModulesStr, modCode);
		}
	}
	
	return anExpireModulesStr;
}

/**/
- (BOOL) canExecuteModule: (int) aModuleCode
{
  id module = [self getModuleByCode: aModuleCode];

  if (module == NULL) THROW(MODULE_NOT_FOUND_EX);

	// para deshabilitar los modulos, directamente se retorna TRUE siempre.
	return TRUE;

	//return [module canBeExecuted];
}

/**/
- (BOOL) canExecuteModule: (int) aModuleCode executionMode: (int) anExecutionMode
{
	switch (anExecutionMode) {

		case CMP_TSUP_ID:
		case CMP_OUT_TSUP_ID:
		case STT_ID:
		case HOYTS_BRIDGE_TSUP_ID:
		case BRIDGE_TSUP_ID:
	
			return TRUE;

		case PIMS_TSUP_ID:
			return [self canExecuteModule: aModuleCode];

		default: return TRUE;

	}

}

/**/
- (void) updateModulesTimeElapsed: (unsigned long) anElapsedTime
{
	int i;

	for (i=0; i<[myModules size]; ++i) {

        printf("20\n");
		// si esta habilitado y la cantidad de horas es cero quiere
	  // decir que esta habilitado por tiempo ilimitado, por lo tanto
	  // no tiene sentido actualizar el tiempo transcurrido.
		if ( ([[myModules at: i] isEnable]) && ([[myModules at: i] getHoursQty] == 0) )
			continue;

		// modifico el tiempo transcurrido si el modulo esta habilitado, sin 
		// importar que este vencido por fechas o por tiempo transcurrido,
		// total cuando se setea una nueva licencia el tiempo transcurrido
		// se resetea
		if (![[myModules at: i] hasExpired]) {
//			doLog(0,"Modifica el tiempo transcurrido del modulo %d\n", [[myModules at: i] getModuleCode]);
			[[myModules at: i] updateTimeElapsed: anElapsedTime];
		}

	} 

}

/**/
- (void) updateModulesState: (int) anOldState currentState: (int) aCurrentState
{
	int i;

	// Test pims -> Test stand alone
	// Prod pims -> Prod stand alone

	if ( ((anOldState == SYSTEM_TEST_PIMS) && (aCurrentState == SYSTEM_TEST_STAND_ALONE)) ||
 			 ((anOldState == SYSTEM_PRODUCTION_PIMS) && (aCurrentState == SYSTEM_PRODUCTION_STAND_ALONE)) ) {

	// Deshabilita los modulos
		for (i=0; i<[myModules size]; ++i) 
			[self disableModule: [[myModules at: i] getModuleCode]];

	}


	// Test stand alone -> Test pims
	// Test stand alone -> Prod pims
	// Prod stand alone -> Prod pims

	if ( ((anOldState == SYSTEM_TEST_STAND_ALONE) && (aCurrentState == SYSTEM_TEST_PIMS)) ||
 			 ((anOldState == SYSTEM_TEST_STAND_ALONE) && (aCurrentState == SYSTEM_PRODUCTION_PIMS)) ||
			 ((anOldState == SYSTEM_PRODUCTION_STAND_ALONE) && (aCurrentState == SYSTEM_PRODUCTION_PIMS))) {

	// Deshabilita forzosamente los modulos
		for (i=0; i<[myModules size]; ++i) 
			[self forceDisable: [[myModules at: i] getModuleCode] expireDateTime: [SystemTime getGMTTime]];

	}

}

/**/
- (void) verifyModulesSign
{
	int i;

	for (i=0; i<[myModules size]; ++i)
		[[myModules at: i] setSignatureVerification: myLSdsa];
	
}


@end
