#include "CimManager.h"
#include "Audit.h"
#include "CimDefs.h"
#include "CimExcepts.h"
#include "Denomination.h"
#include "AcceptedCurrency.h"
#include "AcceptedDepositValue.h"
#include "AcceptorSettings.h"
#include "UserManager.h"
#include "SettingsExcepts.h"
#include "ReportXMLConstructor.h"
#include "PrinterSpooler.h"
#include "Persistence.h"
#include "TempDepositDAO.h"
#include "DepositManager.h"
#include "ExtractionManager.h"
#include "ExtractionWorkflow.h"
#include "SafeBoxHAL.h"
#include "BillAcceptor.h"
#include "MessageHandler.h"
#include "Buzzer.h"
#include "CtSystem.h"
#include "TelesupScheduler.h"
#include "CimEventDispatcher.h"
#include "UICimUtils.h"
#include "Acceptor.h"
#include "CommercialStateMgr.h"
#include "UpdateFirmwareThread.h"
#include "JExceptionForm.h"
#include "POSEventAcceptor.h"

//#define LOG(args...) doLog(0,args)
#define TOTAL_TIME 900000//Tiempo en el que se apaga la CIM si utiliza bateria - Poner 15 minutos

#include "Door.h"


@implementation CimManager

static CIM_MANAGER singleInstance = NULL;

- (void) onInformAlarm: (char*) aBuffer {}




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

	myExtendedDrops = [Collection new];
	myCimStateDeposit = [CimStateDeposit new];
	myCimStateIdle = [CimStateIdle new];
	myCurrentState = myCimStateIdle;
	myObservers = [Collection new];

	myCim = [Cim new];
	[myCim loadCimCashes];
	[myCim setAcceptorsObserver: self];
	[myCim setDoorsObserver: self];
	[myCim loadBoxes];

	// Configura los estados
	[myCimStateDeposit setCim: myCim];
	[myCimStateIdle setCim: myCim];

	myExtractionWorkflowList = [Collection new];

	myShutdownTimer = [OTimer new];
	[myShutdownTimer initTimer: PERIODIC period: 5000 object: self callback: "shutdownTimerHandler"];

	inManualDropState = FALSE;
	myShowAlarmaBattery = TRUE;

	return self;
}

/**/
- (void) start
{
	COLLECTION doors;
	EXTRACTION_WORKFLOW extractionWorkflow;	
	int i;
	DOOR door;
	// Creo la lista de "flujos de extraccion"
	doors = [myCim getDoors];

	for (i = 0; i < [doors size]; i++) {
		door = [doors at: i];
		extractionWorkflow = [ExtractionWorkflow new];
		[extractionWorkflow setExtractionManager: [ExtractionManager getInstance]];
		[extractionWorkflow setDoor: door];
		[myExtractionWorkflowList add: extractionWorkflow];
	}

	printf("startAcceptors \n")	;
	[myCim startAcceptors];
    printf("fin startAcceptors \n")	;
    [myCim startDoors];
    
	// Agrego los dispositivos de control

	[[CimEventDispatcher getInstance] registerDevice: POWER_ST 
		deviceType: DeviceType_POWER 
		object: self];

	[[CimEventDispatcher getInstance] registerDevice: SYSTEM_ST 
		deviceType: DeviceType_HARDWARE_SYSTEM 
		object: self];

	[[CimEventDispatcher getInstance] registerDevice: BATT_ST 
		deviceType: DeviceType_BATTERY 
		object: self];

	[[CimEventDispatcher getInstance] registerDevice: LOCKER0_ERR
		deviceType: DeviceType_LOCKER_ERROR_STATUS
		object: self];

	[[CimEventDispatcher getInstance] registerDevice: LOCKER1_ERR
		deviceType: DeviceType_LOCKER_ERROR_STATUS
		object: self];

	[[CimEventDispatcher getInstance] registerDevice: LOCKER2_ERR
		deviceType: DeviceType_LOCKER_ERROR_STATUS
		object: self];

	[[CimEventDispatcher getInstance] registerDevice: LOCKER3_ERR
		deviceType: DeviceType_LOCKER_ERROR_STATUS
		object: self];

	// seteo los tiempos de Time Locks y Unlock Enable 
	[self setDoorTimes];

}

/**/
- (void) setDoorTimes
{
  COLLECTION doors;
	int timeLock1 = 0;
	int timeLock2 = 0;
	int timeLock3 = 0;
	int timeLock4 = 0;
	int unlockEnable1 = 0;
	int unlockEnable2 = 0;
	int unlockEnable3 = 0;
	int unlockEnable4 = 0;

	doors = [myCim getDoors];

	// Time locks
	if ([doors size] > 0) timeLock1 = [[doors at: 0] getAutomaticLockTime];
	if ([doors size] > 1) timeLock2 = [[doors at: 1] getAutomaticLockTime];
	if ([doors size] > 2) timeLock3 = [[doors at: 2] getAutomaticLockTime];
	if ([doors size] > 3) timeLock4 = [[doors at: 3] getAutomaticLockTime];

	[SafeBoxHAL setAutomaticLockTime: timeLock1 timeLock2: timeLock2 timeLock3: timeLock3 timeLock4: timeLock4];

  // Unlock Enable 
	if ([doors size] > 0) unlockEnable1 = [[doors at: 0] getTUnlockEnable];
	if ([doors size] > 1) unlockEnable2 = [[doors at: 1] getTUnlockEnable];
	if ([doors size] > 2) unlockEnable3 = [[doors at: 2] getTUnlockEnable];
	if ([doors size] > 3) unlockEnable4 = [[doors at: 3] getTUnlockEnable];

	[SafeBoxHAL setUnlockEnableTime: unlockEnable1 unlockEnable2: unlockEnable2 unlockEnable3: unlockEnable3 unlockEnable4: unlockEnable4];
}

/**/
- (DOOR) getDoorById: (int) aDoorId
{
	return [myCim getDoorById: aDoorId];
}

/**/
- (DOOR) getInnerDoor: (int) aDoorId
{
	COLLECTION doors = NULL;
	id door = NULL;
	int i;

	doors = [myCim getDoors];
	// recorro las pruertas y busco a ver si la puerta recibida como parametro tiene
  // puerta hija. Si la tiene la devuelvo.
	for (i = 0; i < [doors size]; i++) {
		door = [doors at: i];
		if ([door getBehindDoorId] == aDoorId) return door;
	}
	
	return NULL;
}

/**/
- (void) setCurrentState: (CIM_STATE) anState
{

	if (myCurrentState) [myCurrentState deactivateState];

	myCurrentState = anState;
	[myCurrentState setObservers: myObservers];
	[myCurrentState activateState];
}

/**/
+ getInstance
{
  return [self new];
}

/**/
- (void) addObserver: (id) anObserver
{
	[myObservers add: anObserver];
    
    printf(">>>>>>>>>>>>>>>>>>>>>>>>>>> ADD OBSERVER  \n");    
    printf("myObservers size = %d\n", [myObservers size]);
	[myCurrentState setObservers: myObservers];
}

/**/
- (void) removeObserver: (id) anObserver
{
	//[myObservers remove: anObserver];
    [myObservers free];
    myObservers = [Collection new];
    printf(">>>>>>>>>>>>>>>>>>>>>>>>>>> REMOVE OBSERVER  \n");
    printf("myObservers size = %d\n", [myObservers size]);    
	[myCurrentState setObservers: myObservers];
}

/**/
- (DEPOSIT) startExtendedDrop: (USER) aUser cimCash: (CIM_CASH) aCimCash cashReference: (CASH_REFERENCE) aCashReference 
	envelopeNumber: (char *) anEnvelopeNumber applyTo: (char *) anApplyTo
{
	DEPOSIT deposit;
	char additional[200];

	if (aUser == NULL) THROW(NO_USER_LOGGED_IN_EX);

	deposit = [[DepositManager getInstance] getNewDeposit: aUser 
		cimCash: aCimCash 
		depositType: DepositType_AUTO];

	// Configuro el cash reference
	[deposit setCashReference: aCashReference];
	[deposit setEnvelopeNumber: anEnvelopeNumber];
	[deposit setApplyTo: anApplyTo];

	// Abro los validadores de billetes / buzon
	[myCim openCimCash: aCimCash];

	[myExtendedDrops add: deposit];

  	additional[0] = '\0';
  	sprintf(additional, "%s-%s", [aUser getLoginName], [aUser getFullName]);
	[Audit auditEventCurrentUser: Event_EXTENDEDDROP_LOGIN additional: additional station: 0 logRemoteSystem: FALSE];

	return deposit;
}

/**/
- (void) closeExtendedDrop: (DEPOSIT) aDeposit
{

	// Cierro los validadores de billetes / buzon
	[myCim closeCimCash: [aDeposit getCimCash]];

	[myExtendedDrops remove: aDeposit];

	[[DepositManager getInstance] endDeposit: aDeposit];

	[Audit auditEventCurrentUser: Event_EXTENDEDDROP_LOGOUT additional: "" station: 0 logRemoteSystem: FALSE];

}

/**/
- (void) endAllExtendedDropsByDoor: (DOOR) aDoor
{
	int i = 0;

	while (i < [myExtendedDrops size]) {

		if ([[[myExtendedDrops at: i] getCimCash] getDoor] == aDoor) {
			[self closeExtendedDrop: [myExtendedDrops at: i]];
		} else i++;

	}
}

/**/
- (void) endAllExtendedDropsForUser: (USER) aUser
{
	int i = 0;

	while (i < [myExtendedDrops size]) {

		if ([[myExtendedDrops at: i] getUser] == aUser) {
			[self closeExtendedDrop: [myExtendedDrops at: i]];
		} else i++;

	}

}

/**/
- (void) endAllExtendedDrops
{
	int i = 0;

	while (i < [myExtendedDrops size]) {
		[self closeExtendedDrop: [myExtendedDrops at: i]];
	}

}

/**/
- (void) endExtendedDrop: (CIM_CASH) aCimCash
{
	int i;
	DEPOSIT deposit = NULL;

	for (i = 0; i < [myExtendedDrops size]; ++i) {
		if ([[myExtendedDrops at: i] getCimCash] == aCimCash) {
			deposit = [myExtendedDrops at: i];
			break;
		}
	}

	// Proceso el deposito
	if (deposit) {
		[self closeExtendedDrop: deposit];
	}

}

/**/
- (COLLECTION) getExtendedDrops
{
	return myExtendedDrops;
}

/**/
- (DEPOSIT) getExtendedDrop: (CIM_CASH) aCimCash
{
	int i;

	for (i = 0; i < [myExtendedDrops size]; ++i) {
		if ([[myExtendedDrops at: i] getCimCash] == aCimCash) return [myExtendedDrops at: i];
	}
	return NULL;	
}

/**/
- (DEPOSIT) getExtendedDropByDoor: (DOOR) aDoor
{
	int i;

	for (i=0; i<[myExtendedDrops size]; ++i) 
		if ([[[myExtendedDrops at: i] getCimCash] getDoor] == aDoor) 
			return [myExtendedDrops at: i];

	return NULL;
}

/**/
- (DEPOSIT) startDeposit: (USER) aUser cimCash: (CIM_CASH) aCimCash depositType: (DepositType) aDepositType
{
	DEPOSIT deposit;

	if (aUser == NULL) THROW(NO_USER_LOGGED_IN_EX);

	deposit = [[DepositManager getInstance] getNewDeposit: aUser 
		cimCash: aCimCash 
		depositType: aDepositType];

	[myCimStateDeposit setDeposit: deposit];

	[self setCurrentState: myCimStateDeposit];

	return deposit;
}


/**/
- (DEPOSIT) startDeposit: (CIM_CASH) aCimCash depositType: (DepositType) aDepositType
{
	USER user = [[UserManager getInstance] getUserLoggedIn];

	if (user == NULL) THROW(NO_USER_LOGGED_IN_EX);

	return [self startDeposit: user cimCash: aCimCash depositType: aDepositType];

}

/**/
- (void) endDeposit
{
	[self setCurrentState: myCimStateIdle];
}

/**/
- (void) startValidationMode
{
	myInValidationMode = TRUE;

	// Cierra todos los validadores para que no se guarden los billetes en el stacker
	[myCim setBillValidatorsInValidatedMode];
}

/**/
- (void) stopValidationMode
{
	int i;

	[myCim closeBillValidators];

	myInValidationMode = FALSE;

	// Abro los validadores de billetes / buzon de los Extended Drop existentes
	for (i = 0; i < [myExtendedDrops size]; ++i) {
		[myCim openCimCash: [[myExtendedDrops at: i] getCimCash]];
	}
}

/**/
- (BOOL) hasActiveTimeDelays
{
	int i;

	for (i = 0; i < [myExtractionWorkflowList size]; ++i) {
		if ([[myExtractionWorkflowList at: i] getCurrentState] == OpenDoorStateType_TIME_DELAY) return TRUE;
	}

	return FALSE;
}

/**/
- (EXTRACTION_WORKFLOW) getExtractionWorkflow: (DOOR) aDoor
{
	int i;

	for (i = 0; i < [myExtractionWorkflowList size]; ++i)
		if ([[myExtractionWorkflowList at: i] getDoor] == aDoor) return [myExtractionWorkflowList at: i];

	return NULL;
}

/**/
- (void) onDoorOpen: (DOOR) aDoor
{
	EXTRACTION_WORKFLOW extractionWorkflow;

	printf("CimManager -> onDoorOpen, doorId = %d\n", [aDoor getDoorId]);

	// Finaliza los Extended Drops asociados a esta puerta
	/** @todo: si se llama a este codigo se puede frizar todo ya que estoy dentro del hilo de eventos y
		  necesita cerrar los validadores (que tambien esperan el hilo de eventos )*/
	//[self endAllExtendedDropsByDoor: aDoor];

	// Seteo el estado actual a extraccion (si la puerta es de recaudacion unicamente)
	if ([aDoor getDoorType] == DoorType_COLLECTOR) {
		extractionWorkflow = [self getExtractionWorkflow: aDoor];

#ifdef CHOW_YANKEE
	 if ( [aDoor getDoorId] == 2 )
	 	[extractionWorkflow onUnLocked: aDoor];
#endif

		if (extractionWorkflow) [extractionWorkflow onDoorOpen: aDoor];		

	}
	
}

/**/
- (void) onDoorClose: (DOOR) aDoor
{
	EXTRACTION_WORKFLOW extractionWorkflow;
	printf("CimManager -> onDoorClose, doorId = %d\n", [aDoor getDoorId]);

	// Seteo el estado actual a Idle (si la puerta es de recaudacion unicamente)
	if ([aDoor getDoorType] == DoorType_COLLECTOR) {
		extractionWorkflow = [self getExtractionWorkflow: aDoor];

		if (extractionWorkflow) [extractionWorkflow onDoorClose: aDoor];

#ifdef CHOW_YANKEE
	 if ( [aDoor getDoorId] == 2 )
 		[extractionWorkflow onLocked: aDoor];
#endif

	}

}

/**/
- (void) onLocked: (DOOR) aDoor
{
	EXTRACTION_WORKFLOW extractionWorkflow;

    //*********************logcoment
	//doLog(0,"CimManager -> onLocked, doorId = %d\n", [aDoor getDoorId]);
#ifndef CHOW_YANKEE
		extractionWorkflow = [self getExtractionWorkflow: aDoor];
		if (extractionWorkflow) [extractionWorkflow onLocked: aDoor];
#endif

}

/**/
- (void) onUnLocked: (DOOR) aDoor
{
	EXTRACTION_WORKFLOW extractionWorkflow;

    //*********************logcoment
//	doLog(0,"CimManager -> onUnLocked, doorId = %d\n", [aDoor getDoorId]);

#ifndef CHOW_YANKEE
		extractionWorkflow = [self getExtractionWorkflow: aDoor];
		if (extractionWorkflow) [extractionWorkflow onUnLocked: aDoor];
#endif

}

/**/
- (DEPOSIT) getDepositByAcceptor: (ABSTRACT_ACCEPTOR) anAcceptor
{
	int i;
	ACCEPTOR_SETTINGS acceptorSettings;

	acceptorSettings = [anAcceptor getAcceptorSettings];

	// Busco 
	for (i = 0; i < [myExtendedDrops size]; ++i) {
		if ([[[myExtendedDrops at: i] getCimCash] hasAcceptorSettings: acceptorSettings]) return [myExtendedDrops at: i];
	}

	return NULL;
}

/**/
- (void) onBillAccepting: (ABSTRACT_ACCEPTOR) anAcceptor
{
	[myCurrentState onBillAccepting: anAcceptor];
}

/**/
- (void) onAcceptorError: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause
{
	char buf[100];
	char valName[21];
	EXTRACTION_WORKFLOW extractionWorkflow;
	DOOR door;

	if (aCause == BillAcceptorStatus_POWER_UP) return;

	// Por ahora decido ignorar estos eventos ya que se auditan y se procesan por otro lado
	// Tal vez en algun momento se les de algun tratamiento diferente
	if (aCause == BillAcceptorStatus_POWER_UP_BILL_ACCEPTOR) return;
	if (aCause == BillAcceptorStatus_REJECTING) return;

	// Todo este comportamiento se anulo cuando se comenzo a usar el stack2 de JCM con el OPTIONAL
	// FUNCTION para que envie VEND VALID
	if (aCause == BillAcceptorStatus_POWER_UP_BILL_STACKER) return;

	// Error de comunicacion
	// Muestro una alarma indicando el problema
	if (aCause == BillAcceptorStatus_COMMUNICATION_ERROR) {

		// si hay un upgrade de validador o de innerboard en progreso NO muestro la alarma
		if ([[UpdateFirmwareThread getInstance] isUpgradeInProgress]) return;

		buf[0] = '\0';
		if ([[anAcceptor getAcceptorSettings] getAcceptorProtocol] == ProtocolType_CDM3000) {

			stringcpy(valName, [[anAcceptor getAcceptorSettings] getAcceptorName]);
			sprintf(buf, "%-19s %-20s%-20s", valName, 
				[anAcceptor getErrorDescription: aCause], "");
	
			//doLog("alarm = %s\n", buf);

			[UICimUtils showAlarm: buf];

		} else {

			/*stringcpy(valName, [[anAcceptor getAcceptorSettings] getAcceptorName]);
			sprintf(buf, "%-19s %-20s%-20s", valName, 
				[anAcceptor getErrorDescription: aCause], 
				getResourceStringDef(RESID_DISABLE_DEVICE_QUESTION, "Inhabilitar?"));

			[UICimUtils askYesNoQuestion: buf
				data: anAcceptor
				object: self
				callback: "communicationErrorResponseHandler:"];*/

			stringcpy(valName, [[anAcceptor getAcceptorSettings] getAcceptorName]);
			sprintf(buf, "  %-18s%-19s %-20s", 
				getResourceStringDef(RESID_WARNING_MSG, "Advertencia!!"),
				valName, [anAcceptor getErrorDescription: aCause]);

			[UICimUtils showAlarm: buf];

		}

		return;
	}

	// Stacker open (si estoy en una extraccion no debo disparar una alarma
	if (aCause == BillAcceptorStatus_STACKER_OPEN) {

		door = [[anAcceptor getAcceptorSettings] getDoor];
		THROW_NULL(door);

		extractionWorkflow = [self getExtractionWorkflowForDoor: door];
		THROW_NULL(extractionWorkflow);

		if ([extractionWorkflow getCurrentState] == OpenDoorStateType_WAIT_CLOSE_DOOR ||
				[extractionWorkflow getCurrentState] == OpenDoorStateType_WAIT_CLOSE_DOOR_WARNING ||
				[extractionWorkflow getCurrentState] == OpenDoorStateType_WAIT_CLOSE_DOOR_ERROR) {

            //************************* logcoment
//			doLog(0,"CimManager -> retiro el stacker durante una extraccion\n");

			// Si se selecciono que no se va a extraer el dinero 
			// y se recibe un evento de que fue retirado el stacker se emite una alarma critica.
			if (![extractionWorkflow getGenerateExtraction]) {

                //************************* logcoment
				//doLog(0,"CimManager -> El stacker se retiro a pesar de que no se iba a retirar\n");
				[Audit auditEventCurrentUser: Event_STACKER_OUT_WITHOUT_REPORT additional: [[anAcceptor getAcceptorSettings] getAcceptorName] station: [[anAcceptor getAcceptorSettings] getAcceptorId] logRemoteSystem: FALSE];

				// si se retira stacker de validador de la puerta externa se debe generar la extraccion
				// ademas de generar la alarma
				if ([extractionWorkflow getInnerDoorWorkflow] && ![extractionWorkflow isGeneratedOuterDoorExtr]) {
                    //*********************logcoment
                        //doLog(0,"CimManager -> Genero la extraccion por retirar stacker en puerta externa\n");
					[extractionWorkflow generateExtraction: door];
				}

			} else return;
		}

	}
	
	// si estoy en medio de un backup o restore no hago sonar el buzzer
	if ( ([[CimBackup getInstance] getCurrentBackupType] == BackupType_UNDEFINED) && 
			 (![[CimBackup getInstance] inRestore]) )
		[[Buzzer getInstance] buzzerBeep: 1500];

  buf[0] = '\0';
	sprintf(buf, "%-20s%-20s", [[anAcceptor getAcceptorSettings] getAcceptorName], [anAcceptor getErrorDescription: aCause]);
  strcat(buf,"                                   ");

	[UICimUtils showAlarm: buf];

}

/**/
- (void) communicationErrorResponseHandler: (Alarm*) anAlarm
{
	if (anAlarm->modalResult == JDialogResult_YES) {

		[anAlarm->data disableCommunication];

    [[anAlarm->data getAcceptorSettings] setDisabled: TRUE];
    [[anAlarm->data getAcceptorSettings] applyChanges];
	}
}

/**/
- (void) onBillAccepted: (ABSTRACT_ACCEPTOR) anAcceptor currency: (CURRENCY) aCurrency amount: (money_t) anAmount  qty: (int) aQty
{
	DEPOSIT deposit;
	DEPOSIT_DETAIL detail;
	char moneyStr[50];
	char buf[100];
	int stackerQty = 0;
	int stackerSize = 0;
	int stackerWarningSize = 0;
	BOOL isExtendedDrop = FALSE;

	//LOG("CimManager -> llego billete de %s (%s)\n", [aCurrency getName], formatMoney(moneyStr, "", anAmount, 2, 40));

	if (!myInValidationMode) {
		
        printf("1\n");
		if (![anAcceptor isEnabled]) {
           //************************* logcoment
			//doLog(0,"CimManager -> validador en estado STOP\n");
			//doLog(0,"ERROR: nunca deberia estar habilitado el validador en este estado\n");
			formatMoney(moneyStr, [aCurrency getCurrencyCode], anAmount, 2, 40);
			[Audit auditEventCurrentUser: Event_BILL_STACKED_WITHOUT_DROP additional: moneyStr
					station: [[anAcceptor getAcceptorSettings] getAcceptorId]
					logRemoteSystem: FALSE];

			return;
		}

		deposit = [self getDepositByAcceptor: anAcceptor];
	
		if (deposit) {

			detail = [deposit addDepositDetail: [anAcceptor getAcceptorSettings]
				depositValueType: DepositValueType_VALIDATED_CASH
				currency: aCurrency
				qty: aQty
				amount: anAmount];
	
			// Grabo el detalle de forma temporal
			[[[Persistence getInstance] getTempDepositDAO] saveDepositDetail: deposit detail: detail];

			isExtendedDrop = TRUE;
		}

	}

	if (!isExtendedDrop){
		[myCurrentState onBillAccepted: anAcceptor currency: aCurrency amount: anAmount qty: aQty];

		deposit = [myCurrentState getDeposit];
	}

	if (deposit) {

		// Si es FLEX debe tomar la configuracion de algun lado
		if (strstr([[myCim  getBoxById: 1] getBoxModel], "FLEX")) {

			stackerQty = [[[ExtractionManager getInstance] getCurrentExtraction: [[anAcceptor getAcceptorSettings] getDoor]] getQty: NULL] + [deposit getQty];
			// debo tomar el total del tamano que es la sumatoria de los montos de los stackers de cada aceptador
			
			stackerSize = [myCim getTotalStackerSize: anAcceptor];
			stackerWarningSize = [myCim getTotalStackerWarningSize: anAcceptor];

			printf("stacker size = %d\n", stackerSize);
			printf("stacker warning size = %d\n", stackerWarningSize);
			printf("stacker qty = %d\n", stackerQty);

		} else {
			stackerQty = [[[ExtractionManager getInstance] getCurrentExtraction: [[anAcceptor getAcceptorSettings] getDoor]] getQtyByAcceptor: [anAcceptor getAcceptorSettings]] + [deposit getQtyByAcceptorSettings: [anAcceptor getAcceptorSettings]];

			stackerSize = [[anAcceptor getAcceptorSettings] getStackerSize];
			stackerWarningSize = [[anAcceptor getAcceptorSettings] getStackerWarningSize];
		}
		//doLog(0,"cant billetes en stacker %s es %d \n", [[anAcceptor getAcceptorSettings] getAcceptorName], stackerQty);

		if ((![anAcceptor hasEmitStackerFull]) && (stackerSize != 0) && (stackerSize <= stackerQty)) {


			if (strstr([[myCim  getBoxById: 1] getBoxModel], "FLEX")) {			

				sprintf(buf, "%s", getResourceStringDef(RESID_STACKER_FULL, "Stacker Lleno.      Finalice deposito!"));
				[UICimUtils showAlarm: buf];
				[myCim setHasEmitStackerFullByCash: anAcceptor value: TRUE];
				[myCim setHasEmitStackerWarningByCash: anAcceptor value: TRUE];

			} else {

				sprintf(buf, "%-20s%s", [[anAcceptor getAcceptorSettings] getAcceptorName], getResourceStringDef(RESID_STACKER_FULL, "Stacker Lleno.      Finalice deposito!"));
				//doLog("alarm = %s\n", buf);
	
				[UICimUtils showAlarm: buf];
				[anAcceptor setHasEmitStackerFull: TRUE];
				[anAcceptor setHasEmitStackerWarning: TRUE];
			}



			[Audit auditEventCurrentUser: EVENT_STACKER_FULL_BY_SETTING additional: "" station: [[anAcceptor getAcceptorSettings] getAcceptorId] logRemoteSystem: FALSE];

			// me fijo si debo informar al POS del evento.
/*			if ([[POSEventAcceptor getInstance] isTelesupRunning])
				[[POSEventAcceptor getInstance] cassetteFullEvent: [[anAcceptor getAcceptorSettings] getAcceptorId] acceptorName: [[anAcceptor getAcceptorSettings] getAcceptorName]];*/

		} else {
			if ((![anAcceptor hasEmitStackerWarning]) && (stackerWarningSize != 0) && (stackerWarningSize <= stackerQty)){



				if (strstr([[myCim  getBoxById: 1] getBoxModel], "FLEX")) {			
	
					sprintf(buf, "%s", getResourceStringDef(RESID_STACKER_FULL_IS_COMING, "Esta por llegar al stacker lleno"));
					[UICimUtils showAlarm: buf];
					[myCim setHasEmitStackerWarningByCash: anAcceptor value: TRUE];
	
				} else {
					
					sprintf(buf, "%-20s%s", [[anAcceptor getAcceptorSettings] getAcceptorName], getResourceStringDef(RESID_STACKER_FULL_IS_COMING, "Esta por llegar al stacker lleno"));
	
					//doLog("alarm = %s\n", buf);
	
					[UICimUtils showAlarm: buf];
					[anAcceptor setHasEmitStackerWarning: TRUE];
				}
	
				[Audit auditEventCurrentUser: EVENT_VALIDATOR_CAPACITY_WARNING additional: "" station: [[anAcceptor getAcceptorSettings] getAcceptorId] logRemoteSystem: FALSE];
	
				// me fijo si debo informar al POS del evento.
		/*		if ([[POSEventAcceptor getInstance] isTelesupRunning])
					[[POSEventAcceptor getInstance] cassetteAlmostFullEvent: [[anAcceptor getAcceptorSettings] getAcceptorId] acceptorName: [[anAcceptor getAcceptorSettings] getAcceptorName]];*/
		
			}
		}

		// le repito el mensaje de que cierre el deposito cada vez que ingrese un billete
		// al superar el stacker full
		if ((stackerSize != 0) && (stackerSize < stackerQty)) {

			if (strstr([[myCim  getBoxById: 1] getBoxModel], "FLEX")) 			
				sprintf(buf, "%s",  getResourceStringDef(RESID_STACKER_FULL, "Stacker Lleno.      Finalice deposito!"));
			else
				sprintf(buf, "%-20s%s", [[anAcceptor getAcceptorSettings] getAcceptorName], getResourceStringDef(RESID_STACKER_FULL, "Stacker Lleno.      Finalice deposito!"));

			[UICimUtils showAlarm: buf];
		}
	}
}

/**/
- (void) onBillRejected: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause  qty: (int) aQty
{
	DEPOSIT deposit;
	char additional[101];

    //*********************logcoment
//	doLog(0,"CimManager -> se rechazo un billete, codigo = %d\n", aCause);
	if (!myInValidationMode) {

  		if (![anAcceptor isEnabled]) {
    //*********************logcoment
//			doLog(0,"CimManager -> el validador se encuentra en estado STOP\n");
			return;
		}

		deposit = [self getDepositByAcceptor: anAcceptor];
	
		if (deposit) {

			// Audito el evento
			sprintf(additional, "%d ", aCause);
			
    	switch (aCause)
    	{
    		case 113: strcat(additional, getResourceStringDef(RESID_INSERTION_ERROR, "Error al Insertar")); break;
    		case 114: strcat(additional, getResourceStringDef(RESID_MAGNETIC_PATTERN_ERROR, "Magnetic Pattern Error")); break;
    		case 115: strcat(additional, getResourceStringDef(RESID_IDLE_SENSOR_DETECTED, "Sensor Inactivo detectado")); break;
    		case 116: strcat(additional, getResourceStringDef(RESID_DATA_AMPLITUDE_ERROR, "Error en Amplitud de datos")); break;
    		case 117: strcat(additional, getResourceStringDef(RESID_FEED_ERROR, "Error en Alimentacion")); break;
    		case 118: strcat(additional, getResourceStringDef(RESID_DENOMINATION_ASSESSING_ERROR, "Error al Evaluar denominacion")); break;
    		case 119: strcat(additional, getResourceStringDef(RESID_PHOTO_PATTERN_ERROR, "Error en Patron de foto")); break;
    		case 120: strcat(additional, getResourceStringDef(RESID_PHOTO_LEVEL_ERROR, "Error en Nivel de foto")); break;
    		case 121: strcat(additional, getResourceStringDef(RESID_BILL_DISABLED, "Billete Disabilitado")); break;
    		case 122: strcat(additional, getResourceStringDef(RESID_RESERVER, "Reservado")); break;
    		case 123: strcat(additional, getResourceStringDef(RESID_OPERATION_ERROR, "Error de Operacion")); break;
    		case 124: strcat(additional, getResourceStringDef(RESID_WRONG_TIME, "Tiempo Erroneo")); break;
    		case 125: strcat(additional, getResourceStringDef(RESID_LENGHT_ERROR, "Longitud Erronea")); break;
    		case 126: strcat(additional, getResourceStringDef(RESID_COLOR_PATTERN_ERROR, "Patron de Color erroneo")); break;
    		case 999: strcat(additional, getResourceStringDef(RESID_UNDEFINE, "Undefined")); break;
    	}
			
			[Audit auditEventCurrentUser: AUDIT_CIM_BILL_REJECTED additional: additional
				station: [[anAcceptor getAcceptorSettings] getAcceptorId] logRemoteSystem: FALSE];

			[deposit addRejectedQty: aQty];

			// Actualizo el deposito temporal
			[[[Persistence getInstance] getTempDepositDAO] updateDeposit: deposit];

			return;
		}

	}

	[myCurrentState onBillRejected: anAcceptor cause: aCause qty: aQty];
}

/**/
- (CIM) getCim
{
	return myCim;
}

/**/
- (DOOR) getAcceptorSettingsById: (int) anAcceptorSettingsId
{
	return [myCim getAcceptorSettingsById: anAcceptorSettingsId];
}

/**/
- (CIM_CASH) getCimCashById: (int) aCimCashId
{
	return [myCim getCimCashById: aCimCashId];
}

/**/
- (void) needMoreTime
{
	[myCurrentState needMoreTime];
}

/**/
- (COLLECTION) getExtractionWorkflowList
{
	return myExtractionWorkflowList;
}

/**/
- (EXTRACTION_WORKFLOW) getExtractionWorkflowForDoor: (DOOR) aDoor
{
	int i;

	for (i = 0; i < [myExtractionWorkflowList size]; ++i) {

		if ([[myExtractionWorkflowList at: i] getDoor] == aDoor) 
			return [myExtractionWorkflowList at: i];

	}

	return NULL;

}

/**/
- (COLLECTION) getExtractionWorkflowListOnTimeDelay
{
	int i;
	COLLECTION collection = [Collection new];

	for (i = 0; i < [myExtractionWorkflowList size]; ++i) {

		if ([[myExtractionWorkflowList at: i] getCurrentState] == OpenDoorStateType_TIME_DELAY) 
			[collection add: [myExtractionWorkflowList at: i]];

	}

	return collection;
}

/**/
- (void) cancelActiveDeposits
{
	[self endAllExtendedDrops];
	[self setCurrentState: myCimStateIdle];
}

/**/
- (BOOL) canShutdown
{
	/*int i;
		

	for (i = 0; i < [myExtractionsWorflowList size]; ++i) {
	}
*/
	return TRUE;
}

/**/
- (void) onPowerStatusChange: (PowerStatus) aNewStatus
{
    //*********************logcoment
//	doLog(0,"CimManager -> onPowerStatusChange = %d\n", aNewStatus);

	// Mostrar alarma y auditar
	if (aNewStatus == PowerStatus_BACKUP) {
		ticks = getTicks();
		[[Buzzer getInstance] buzzerBeep: 2000];

		// Audito el evento
		[Audit auditEventCurrentUser: EVENT_PPWER_SUPPLY_BATTERY additional: "" station: 0 logRemoteSystem: FALSE];

		// si NO esta en medio de una actualizacion de firmware muestro la alarma, sino la
		// muestro al finalizar
		if (![[UpdateFirmwareThread getInstance] isUpgradeInProgress]) {
				myShowAlarmaBattery = FALSE;
				[UICimUtils showAlarm: getResourceStringDef(RESID_POWER_DOWN_WARNING, "Advertencia: Energia baja!Finalice las transacciones!")];
                //************************* logcoment
				//doLog(0,"\n***************Advertencia: Energia baja!Finalice las transacciones****************************\n");
		}

		// Deberia esperar a que finalice de imprimir ?
		[myShutdownTimer start];

	} else {

		[myShutdownTimer stop];
	}
}

/**/
- (void) onBatteryStatusChange: (BatteryStatus) aNewStatus
{
    //*********************logcoment
//	doLog(0,"CimManager -> onBatteryStatusChange = %d\n", aNewStatus);

	// Mostrar alarma y auditar
	if (aNewStatus == BatteryStatus_LOW) {

		// Audito el evento
		[Audit auditEventCurrentUser: EVENT_LOW_BATTERY_DETECTED additional: "" station: 0 logRemoteSystem: FALSE];

	}


}

/**/
- (void) onHardwareSystemStatusChange: (HardwareSystemStatus) aNewStatus
{
    //*********************logcoment
	//doLog(0,"CimManager -> onHardwareSystemStatusChange = %d\n", aNewStatus);

	// Mostrar alarma y auditar
	if (aNewStatus == HardwareSystemStatus_SECONDARY) {
		[[Buzzer getInstance] buzzerBeep: 2000];
		[UICimUtils showAlarm: getResourceStringDef(RESID_PRIMARY_HARDWARE_FAILURE, "Advertencia: Falla en hardware primario!")];
		[Audit auditEventCurrentUser: Event_PRIMARY_HARDWARE_FAILURE additional: "" station: 0 logRemoteSystem: FALSE];
	}

}

/**/
- (void) activateAlarm
{
    //*********************logcoment
//	doLog(0,"******************* ACTIVA LA ALARMA ************************\n");
	[SafeBoxHAL setAlarm: ALARM1 alarmState: AlarmState_ON];
	[Audit auditEventCurrentUser: Event_SHOT_ALARM additional: "" station: 0 logRemoteSystem: FALSE];
}

/**/
- (void) deactivateAlarm
{

    //*********************logcoment
//	doLog(0,"******************* DESACTIVA LA ALARMA ************************\n");
	[SafeBoxHAL setAlarm: ALARM1 alarmState: AlarmState_OFF];
}

/**/
- (void) activateSoundAlarm
{
    //*********************logcoment
	//doLog(0,"******************* ACTIVA LA SOUND ALARM ************************\n");
	[SafeBoxHAL setAlarm: ALARM0 alarmState: AlarmState_ON];
	[Audit auditEventCurrentUser: Event_SHOT_ALARM additional: "" station: 0 logRemoteSystem: FALSE];
}

/**/
- (void) deactivateSoundAlarm
{
    //*********************logcoment
//	doLog(0,"******************* DESACTIVA LA SOUND ALARM ************************\n");
	[SafeBoxHAL setAlarm: ALARM0 alarmState: AlarmState_OFF];
}

/**/
- (BOOL) isSystemIdle
{
	int i;

	if (myCurrentState != myCimStateIdle) return FALSE;
	if ([[TelesupScheduler getInstance] inTelesup]) return FALSE;
	if ([[Acceptor getInstance] isTelesupRunning]) return FALSE;

	for (i = 0; i < [myExtractionWorkflowList size]; ++i) {
		if ([[myExtractionWorkflowList at: i] getCurrentState] != OpenDoorStateType_IDLE) return FALSE;
	}

	return TRUE;
}

/**/
- (BOOL) isOnDeposit
{
	if (myCurrentState != myCimStateIdle) 
		return TRUE;

	if (inManualDropState) 
		return TRUE;

	return FALSE;
}

/**/
- (BOOL) isDoorOpen
{
	int i;

	for (i = 0; i < [myExtractionWorkflowList size]; ++i) {
		if ([[myExtractionWorkflowList at: i] getCurrentState] != OpenDoorStateType_IDLE) 
			return TRUE;
	}
	return FALSE;
}

/**/
- (BOOL) isSystemIdleForTelesup
{
	int i;

	if (myCurrentState != myCimStateIdle) {
		printf("isSystemIdleForTelesup 1\n");
		return FALSE;
	}

	if (inManualDropState) {
        printf("isSystemIdleForTelesup 2\n");
		return FALSE;
}

	for (i = 0; i < [myExtractionWorkflowList size]; ++i) {
		if ([[myExtractionWorkflowList at: i] getCurrentState] != OpenDoorStateType_IDLE) {
             printf("isSystemIdleForTelesup 3 state %d\n", [[myExtractionWorkflowList at: i] getCurrentState]);   
			return FALSE;
		}		
	}

	if ([[CommercialStateMgr getInstance] isChangingState]) {
        printf("isSystemIdleForTelesup 4\n");
			return FALSE;
	}
	return TRUE;

}

/**/
- (BOOL) isSystemIdleForChangeState: (char*) aMsg
{
	int i;

	if (myCurrentState != myCimStateIdle) {
		strcpy(aMsg, getResourceStringDef(RESID_CANNOT_CHANGE_STATE_DROP_IN_PROGRESS, "DEPOSITO EN PROGRESO."));
		return FALSE;
	}

	if ([[TelesupScheduler getInstance] inTelesup]) {
		strcpy(aMsg, getResourceStringDef(RESID_CANNOT_CHANGE_STATE_TELESUP_IN_PROGRESS, "SUPERVISION EN PROGRESO."));
		return FALSE;
	}

	if ([[Acceptor getInstance] isTelesupRunning]) {
		strcpy(aMsg, getResourceStringDef(RESID_CANNOT_CHANGE_STATE_TELESUP_IN_PROGRESS, "SUPERVISION EN PROGRESO."));
		return FALSE;
	}

	for (i = 0; i < [myExtractionWorkflowList size]; ++i) {
		if ([[myExtractionWorkflowList at: i] getCurrentState] != OpenDoorStateType_IDLE) {
			strcpy(aMsg, getResourceStringDef(RESID_CANNOT_CHANGE_STATE_DOOR_OPEN, "PUERTA ABIERTA."));
			return FALSE;
		}
	}

	if ([myExtendedDrops size] > 0) {
		strcpy(aMsg, getResourceStringDef(RESID_CANNOT_CHANGE_STATE_EXTENDED_DROP_IN_PROGRESS, "DEPOSITO EXTEND. EN PROGRESO."));
		return FALSE;
	}

	return TRUE;
}

/**/
- (BOOL) isSystemIdleForAutoZClose
{
	int i;

	if (myCurrentState != myCimStateIdle) return FALSE;

	if (inManualDropState) return FALSE;

	for (i = 0; i < [myExtractionWorkflowList size]; ++i) {
		if ([[myExtractionWorkflowList at: i] getCurrentState] != OpenDoorStateType_IDLE) return FALSE;
	}

	if ([myExtendedDrops size] > 0) {
		return FALSE;
	}

	return TRUE;

}

/**/
- (BOOL) isSystemIdleForSyncFiles
{
	int i;

	// supervisiones en progreso
	if ([[TelesupScheduler getInstance] inTelesup]) return FALSE;
	if ([[TelesupScheduler getInstance] inTelesup]) return FALSE;

	// hay depositos en curso
	if (myCurrentState != myCimStateIdle) return FALSE;
	if (inManualDropState) return FALSE;

	// puerta abierta
	for (i = 0; i < [myExtractionWorkflowList size]; ++i) {
		if ([[myExtractionWorkflowList at: i] getCurrentState] != OpenDoorStateType_IDLE) return FALSE;
	}

	// hay extended drops abiertos
	if ([myExtendedDrops size] > 0) return FALSE;

	return TRUE;
}

/**/
- (void) shutdownTimerHandler
{
	int shutDownTime;

	shutDownTime = ticks + TOTAL_TIME;

    //************************* logcoment
	/* doLog(0,"\n>>>> Tiempo transcurrido = %ld\n", getTicks() - ticks);
	doLog(0,"Chequeando si se puede apagar el sistema...\n");
    */

    // Finalizo los Extended Drops
	[self endAllExtendedDrops];

	if (![[UpdateFirmwareThread getInstance] isUpgradeInProgress]) {

		if (myShowAlarmaBattery) {
			[UICimUtils showAlarm: getResourceStringDef(RESID_POWER_DOWN_WARNING, "Advertencia: Energia baja!Finalice las transacciones!")];
			msleep(2000);
		}

		if (![[TelesupScheduler getInstance] inTelesup]) {
			// Cancelar todas las extracciones en progreso
			if ( ([self isSystemIdle] && [[PrinterSpooler getInstance] getJobCount] == 0) ||
					(getTicks() > shutDownTime)) {

                //************************* logcoment
                /*if (getTicks() > shutDownTime)
					doLog(0,"\nShutdown: Se agoto el tiempo de espera\n");
				*/
				if (myCurrentState == myCimStateDeposit){
					[self endDeposit];
                   //************************* logcoment
					//doLog(0,"finalizo el deposito ***********************\n");
				}

				[myShutdownTimer stop];

				[[CtSystem getInstance] shutdownSystem];
				[SafeBoxHAL shutdown];

				// Espero 10 segundos para que se procece el shutdown
				msleep(20000);
			}
		}
        //************************* logcoment
		//doLog(0,"Aun no es posible\n");
	}
}

/**/
- (void) setInManualDropState: (BOOL) aValue
{
	inManualDropState = aValue;
}

/**/
- (void) checkAcceptorState: (ACCEPTOR_SETTINGS) anAcceptorSettings
{
	ABSTRACT_ACCEPTOR acceptor;

	//@PROSEGUR

	//if ([anAcceptorSettings getAcceptorType] == AcceptorType_VALIDATOR) {
		acceptor = [myCim getAcceptorById: [anAcceptorSettings getAcceptorId]];
	
		//doLog(0,"acceptor id = %d  -  Stacker sensor status = %d\n", [anAcceptorSettings getAcceptorId], [acceptor getStackerSensorStatus]);
		
		if (acceptor && [acceptor getStackerSensorStatus] == StackerSensorStatus_REMOVED) {
			THROW(CANNOT_OPEN_ACCEPTOR_WITHOUT_BAG_EX);
		}
	//}
}

/**/
- (void) checkCimCashState: (CIM_CASH) aCimCash
{
	COLLECTION acceptorsSettingsList;
	int i;
	acceptorsSettingsList = [aCimCash getAcceptorSettingsList];

	for (i = 0; i < [acceptorsSettingsList size]; ++i) {
		[self checkAcceptorState: [acceptorsSettingsList at: i]];
	}

}

/**/
- (void) lockerErrorStatusChange: (int) aDeviceId newStatus: (int) aNewStatus
{
	char buf[100];
	static char *lockErrStr[] = {"OK", "DRVA", "DRVB", "OPEN", "FAIL"};
	int lockerId = 0;
	COLLECTION doors;
	DOOR door = NULL;
	int i;

	if (aNewStatus != 0) {

		//lockerId = aDeviceId - 14;
		if (aDeviceId == LOCKER0_ERR) lockerId = LOCKER0;
		else if (aDeviceId == LOCKER1_ERR) lockerId = LOCKER1;
        
        //************************* logcoment
		//doLog(0,"lockerErrorStatusChange (%d) = %d\n", aDeviceId, aNewStatus);

		// Busco la puerta correspondiente
		doors = [myCim getDoors];
		for (i = 0; i < [doors size]; ++i) {
			if ([[doors at: i] getLockHardwareId] == lockerId) {
				door = [doors at: i];
				break;
			}
		}

		// Encontro la puerta, genero la alarma y auditoria correspondiente
		if (door) {

			formatResourceStringDef(buf, RESID_LOCKER_ERROR, "Locker error! %s, error %s", [door getDoorName], lockErrStr[aNewStatus]);
			[UICimUtils showAlarm: buf];
			sprintf(buf, "%s,%s", lockErrStr[aNewStatus], [door getDoorName]);
			[Audit auditEventCurrentUser: Event_LOCKER_ERROR additional: buf 
				station: [door getDoorId] logRemoteSystem: FALSE];
						
		}

	}

}

/**/
- (void) disableAcceptorsWithCommError
{
	COLLECTION acceptors;
	int i;

	acceptors = [myCim getAcceptors];

	for (i = 0; i < [acceptors size]; ++i) {
		if ([[acceptors at: i] isKindOf: [BillAcceptor class]] && [[acceptors at: i] hasCommunicationError]) {
			[[acceptors at: i] disableCommunication];
		}
	}

}

- (void) enableAcceptorsWithCommError
{
	COLLECTION acceptors;
	int i;

	acceptors = [myCim getAcceptors];

	for (i = 0; i < [acceptors size]; ++i) {
		if ([[acceptors at: i] isKindOf: [BillAcceptor class]] && [[acceptors at: i] hasCommunicationError] &&
				![[[acceptors at: i] getAcceptorSettings] isDisabled]) {
			[[acceptors at: i] enableCommunication];
		}
	}

}

- (void) informAlarmToObservers: (char*) aBuffer
{
    int i;
	for (i = 0; i < [myObservers size]; ++i)
		[[myObservers at: i] onInformAlarm: aBuffer];

}

@end
