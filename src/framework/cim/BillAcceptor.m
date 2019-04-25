#include "BillAcceptor.h"
#include "jcmBillAcceptorMgr.h"
#include "MessageHandler.h"
#include "SafeBoxHAL.h"
#include "CurrencyManager.h"
#include "Audit.h"
#include "Persistence.h"
#include "CimEventDispatcher.h"
#include "UserManager.h" 
#include "AcceptorDAO.h"
#include "CimExcepts.h"
#include "POSEventAcceptor.h"
#include "AsyncMsgThread.h"


typedef struct {
	int cause;
	int resourceString;
	char *defaultString;
} BillAcceptorCause;

static BillAcceptorCause BillRejectedCauseArray[] = {
	{113, RESID_INSERTION_ERROR, "Error al Insertar"}
 ,{114, RESID_MAGNETIC_PATTERN_ERROR, "Magnetic Pattern Error"}
 ,{115, RESID_IDLE_SENSOR_DETECTED, "Sensor Inactivo detectado"}
 ,{116, RESID_DATA_AMPLITUDE_ERROR, "Error en Amplitud de datos"}
 ,{117, RESID_FEED_ERROR, "Error en Alimentacion"}
 ,{118, RESID_DENOMINATION_ASSESSING_ERROR, "Error al Evaluar denominacion"}
 ,{119, RESID_PHOTO_PATTERN_ERROR, "Error en Patron de foto"}
 ,{120, RESID_PHOTO_LEVEL_ERROR, "Error en Nivel de foto"}
 ,{121, RESID_BILL_DISABLED, "Billete Inhabilitado"}
 ,{122, RESID_RESERVER, "Reservado"}
 ,{123, RESID_OPERATION_ERROR, "Error de Operacion"}
 ,{124, RESID_WRONG_TIME, "Tiempo Erroneo"}
 ,{125, RESID_LENGHT_ERROR, "Longitud Erronea"}
 ,{126, RESID_COLOR_PATTERN_ERROR, "Patron de Color erroneo"}
 ,{999, RESID_UNDEFINE, "Undefined"}
};

static BillAcceptorCause BillAcceptorErrorCauseArray[] = {

	{BillAcceptorStatus_OK, RESID_OK_UPPER, "OK"}
 ,{BillAcceptorStatus_REJECTING, RESID_REJECTED, "Billete Rechazado"}
 ,{BillAcceptorStatus_POWER_UP, RESID_OK_UPPER, "OK"}
 ,{BillAcceptorStatus_STACKER_FULL, RESID_STACKER_FULL, "Stacker Lleno"}
 ,{BillAcceptorStatus_STACKER_OPEN, RESID_STACKER_OPEN, "Stacker Abierto"}
 ,{BillAcceptorStatus_JAM_IN_ACCEPTOR, RESID_JAM_IN_ACCEPTOR, "Atasco en validador"}
 ,{BillAcceptorStatus_JAM_IN_STACKER, RESID_JAM_IN_STACKER, "Atasco en Stacker"}
 ,{BillAcceptorStatus_PAUSE, RESID_PAUSE, "Pausa"}
 ,{BillAcceptorStatus_CHEATED, RESID_CHEATED, "Fraude"}
 ,{BillAcceptorStatus_FAILURE, RESID_FAILURE, "Fallo"}
 ,{BillAcceptorStatus_COMMUNICATION_ERROR, RESID_COMMUNICATION_ERROR, "Error en comunic."}
 ,{BillAcceptorStatus_STACK_MOTOR_FAILURE, RESID_STACK_MOTOR_FAILURE, "Fallo motor Stacker"}
 ,{BillAcceptorStatus_T_MOTOR_SPEED_FAILURE, RESID_T_MOTOR_SPEED_FAILURE, "Fallo velocidad motor"}
 ,{BillAcceptorStatus_T_MOTOR_FAILURE, RESID_T_MOTOR_FAILURE, "Fallo en motor"}
 ,{BillAcceptorStatus_CASHBOX_NOT_READY, RESID_CASHBOX_NOT_READY, "Validador no listo"}
 ,{BillAcceptorStatus_VALIDATOR_HEAD_REMOVED, RESID_VALIDATOR_HEAD_REMOVED, "Cabezal removido"}
 ,{BillAcceptorStatus_BOOT_ROM_FAILURE, RESID_BOOT_ROM_FAILURE, "Fallo memoria de arranque"}
 ,{BillAcceptorStatus_EXTERNAL_ROM_FAILURE, RESID_EXTERNAL_ROM_FAILURE, "Fallo memoria externa"}
 ,{BillAcceptorStatus_ROM_FAILURE, RESID_ROM_FAILURE, "Fallo en memoria"}
 ,{BillAcceptorStatus_EXTERNAL_ROM_WRITING_FAILURE, RESID_EXTERNAL_ROM_WRITING_FAILURE, "Fallo escritura en memoria externa"}
 ,{BillAcceptorStatus_WAITING_BANKNOTE_TO_BE_REMOVED, RESID_WAIT_BANKNOTE_TO_BE_REMOVED, "Esperando que extraiga billete validador"}
 ,{BillAcceptorStatus_OPEN_DOOR, RESID_OPEN_DOOR_RDM, "Puerta abierta en el validador! Verifique"}


 ,{999, RESID_ERROR, "Error: "}
};

@implementation BillAcceptor


/** implementada en el observer */
- (void) onBillAccepted: (ABSTRACT_ACCEPTOR) anAcceptor currency: (CURRENCY) aCurrency amount: (money_t) anAmount  qty: (int) aQty { }
- (void) onBillRejected: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause qty: (int) aQty { }
- (void) onBillAccepting: (ABSTRACT_ACCEPTOR) anAcceptor { }
- (void) onAcceptorError: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause { }

/**/
- (BOOL) isEnabled
{
	return myAcceptorState == AcceptorState_START;
}

/**/
- (void) initAcceptor
{
	int stackerSensorHardwareId = -1;
	ValConfig valConfig;
	
	myEnableCommunication = FALSE;
	myInValidatedMode = FALSE;
	myCurrency = NULL;
	myAcceptorState = AcceptorState_STOP;
	myHardwareId = [myAcceptorSettings getAcceptorHardwareId];
	myIsInitialize = FALSE;
	myCurrentError = BillAcceptorStatus_OK;
	myHasFirstStatus = FALSE;
	mySyncQueue = [[StaticSyncQueue new] initWithSize: sizeof(int) count: 5];
	myInitStatus = -1;
	//myHasCommunication = TRUE;
	myBillAcceptorStatus = BillAcceptorStatus_OK;	
	myStackerSensorStatus = StackerSensorStatus_UNDEFINED;


	

	// Por ahora obtengo el currency cableado ya que no existen dispositivos para
	// multiples monedas.
	myCurrency = [myAcceptorSettings getDefaultCurrency];

	THROW_NULL(myCurrency);

	// Registra el bill acceptor para recibir los 
	[[CimEventDispatcher getInstance] registerDevice: myHardwareId 
		deviceType: DeviceType_VALIDATOR 
		object: self];

	printf("***************************\n");
	// Configuracion de comunicacion del validador
	valConfig.baudRate = [myAcceptorSettings getAcceptorBaudRate];
	printf("valConfig.baudRate = %d\n",[myAcceptorSettings getAcceptorBaudRate]);
	valConfig.parity = [myAcceptorSettings getAcceptorParity];
	printf("valConfig.parity = %d\n",[myAcceptorSettings getAcceptorParity]);
	valConfig.stopBits = [myAcceptorSettings getAcceptorStopBits];
	printf("valConfig.stopBits = %d\n",[myAcceptorSettings getAcceptorStopBits]);
	valConfig.wordBits = [myAcceptorSettings getAcceptorDataBits];
	printf("valConfig.wordBits = %d\n",[myAcceptorSettings getAcceptorDataBits]);	
	valConfig.startTimeout = [myAcceptorSettings getStartTimeOut];
	printf("valConfig.startTimeout = %d\n",[myAcceptorSettings getStartTimeOut]);	
	valConfig.echoDisable = [myAcceptorSettings isEchoDisable];
	printf("valConfig.echoDisable = %d\n",[myAcceptorSettings isEchoDisable]);
    valConfig.protocol = [myAcceptorSettings getAcceptorProtocol] - 1;
	printf("valConfig.protocol = %d\n",[myAcceptorSettings getAcceptorProtocol]-1);
	printf("***************************\n");
	
	[SafeBoxHAL setBillAcceptorCommConfig: myHardwareId acceptorCommConfig: &valConfig];
    
    if (valConfig.protocol == 7)        
           rdmInit( [myAcceptorSettings getAcceptorHardwareId] + 1 );


	// Habilita el bill acceptor
  if (![myAcceptorSettings isDisabled]) {
      printf("BillAcceptor-enableCommunication\n");
	 [self enableCommunication];
     printf("BillAcceptor-enableCommunication2\n");
  } else printf("----------------BillAcceptor  IS DISABLE!\n");

	// Verifica si utiliza la bolsa como stacker
	if (strstr([myAcceptorSettings getAcceptorModel], "BAG") != NULL) {

        printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>INITAcceptor, getAcceptorModel BAG %s\n", [myAcceptorSettings getAcceptorModel]); 
		// Cableo los validadores junto con su sensor correspondiente
		if (myHardwareId == VAL0) stackerSensorHardwareId = STACKER0;
		else if (myHardwareId == VAL1) stackerSensorHardwareId = STACKER1;

		// Registra el sensor de stacker para recibir sus eventos
		if (stackerSensorHardwareId != -1) {
			[[CimEventDispatcher getInstance] registerDevice: stackerSensorHardwareId
				deviceType: DeviceType_STACKER_SENSOR 
				object: self];
		}
	
	} else
          printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>INITAcceptor, NO ENTRO getAcceptorModel BAG %s\n", [myAcceptorSettings getAcceptorModel]); 


	// 

	myHasEmitStackerWarning = FALSE;
	myHasEmitStackerFull = FALSE;

}

- (void) open
{
	if (myStackerSensorStatus == StackerSensorStatus_REMOVED) 
		THROW(CANNOT_OPEN_ACCEPTOR_WITHOUT_BAG_EX);

	myInValidatedMode	= FALSE;

	[SafeBoxHAL openBillAcceptor: myHardwareId];

	// Aca deberia esperar a que el estado sea START o ERROR para seguir adelante
    // ************************ logcoment
	///doLog(0,"Esperando estado START o ERROR...");

	while (1) {
		if (myAcceptorState == AcceptorState_STOP && myEnableCommunication && myBillAcceptorStatus == BillAcceptorStatus_OK) msleep(1);
		else break;
	}

	//************************* logcoment
	//doLog(0,"[START] - Status = %d\n", myBillAcceptorStatus);
}

/**/
- (void) close
{
	myInValidatedMode	= FALSE;

	[SafeBoxHAL closeBillAcceptor: myHardwareId];

	// Aca deberia esperar a que el estado sea STOP o ERROR para seguir adelante
    //************************* logcoment
	//doLog(0,"Esperando estado STOP o ERROR...");

	while (1) {
		if (myAcceptorState == AcceptorState_START && myEnableCommunication && myBillAcceptorStatus == BillAcceptorStatus_OK) msleep(1);
		else break;
	}

    //************************* logcoment
	//doLog(0,"[STOP] - Status = %d\n", myBillAcceptorStatus);

}

/**/
- (void) setValidatedMode
{
	myInValidatedMode = TRUE;
	[SafeBoxHAL setValidatedMode: myHardwareId];
}

/**/
- (BOOL) inValidatedMode
{
	return myInValidatedMode;
}

/**/
- (char *) getRejectedDescription: (int) aCode
{
	int i;

	for (i = 0; ; i++) {

		if (BillRejectedCauseArray[i].cause == aCode || BillRejectedCauseArray[i].cause == 999) {
			return getResourceStringDef(BillRejectedCauseArray[i].resourceString, BillRejectedCauseArray[i].defaultString);
		}

	}

	return NULL;
}

/**/
- (char *) getCurrentErrorDescription
{
	return [self getErrorDescription: myCurrentError];
}

/**/
static char buff[50];

- (char *) getErrorDescription: (int) aCode
{
	int i;
    char *str;

	for (i = 0; ; i++) {

		if (BillAcceptorErrorCauseArray[i].cause == aCode) {
			return getResourceStringDef(BillAcceptorErrorCauseArray[i].resourceString, BillAcceptorErrorCauseArray[i].defaultString);
		} 
		//si llegue al final de la lista
		if (BillAcceptorErrorCauseArray[i].cause == 999) {
            str = getResourceStringDef(BillAcceptorErrorCauseArray[i].resourceString, BillAcceptorErrorCauseArray[i].defaultString);
            sprintf(buff, "%s: %lX", str,aCode);
         //   printf("BillAcceptor GetErrorDescription %s\n", buff);
			return buff;
		} 
	}

	return NULL;
}

/**/
- (char *) getVersion
{
	[SafeBoxHAL getBillValidatorVersion: myHardwareId buffer: myVersion];
	return myVersion;
}


/**/
- (BOOL) existsDenomination: (COLLECTION) aDenominationList amount: (money_t) anAmount
{
	int i;

	for (i = 0; i < [aDenominationList size]; ++i) {
		if ([[aDenominationList at: i] getAmount] == anAmount) return TRUE;
	}

	return FALSE;
}

/**/
- (BOOL) hasDenominationInList: (JCMDenomination *) aJcmDenominations amount: (money_t) anAmount
{
	int i;
	money_t amount;

	for (i = 0; i < 24; i++) {
		if (aJcmDenominations[i].amount == 0) continue;
		amount = ENCODE_DECIMAL(aJcmDenominations[i].amount);
		if (amount == anAmount) return TRUE;
	}

	return FALSE;
}

/**/
- (void) configureDenominations: (ACCEPTED_CURRENCY) anAcceptedCurrency denominations: (JCMDenomination *) aJcmDenominations
{
	COLLECTION denominations;
	int i, index = 0, count;
	money_t amount;
	DENOMINATION denomination;
	
    //************************* logcoment
	printf("**************************************************************Verificando denominaciones...\n");

	denominations = [anAcceptedCurrency getDenominations];
	
	// Recorro la lista de denominaciones que me informa el validador y si no estaban
	// en la lista que yo tengo las agrego
	for (i = 0; i < 24; i++) {

        //printf("denominacion %lld a la moneda %d\n", aJcmDenominations[i].amount, [[anAcceptedCurrency getCurrency] getCurrencyId]);
        printf("i= %d\n", i);
        
		if (aJcmDenominations[i].amount == 0) {
                printf("amount es 0\n");
                continue;
        }

		amount = ENCODE_DECIMAL(aJcmDenominations[i].amount);
        
        printf("amount = %lld \n", amount); 

		// No existe la denominacion, voy a agregarla
		if (![self existsDenomination: denominations amount: amount]) {

            //************************* logcoment
			printf("Agrega denominacion de (%d) %lld a la moneda %d\n", aJcmDenominations[i].amount, amount, [[anAcceptedCurrency getCurrency] getCurrencyId]);
	
			denomination = [Denomination new];
			[denomination setAmount: amount];
			[denomination setDenominationState: DenominationState_ACCEPT];
			[denomination setDenominationSecurity: DenominationSecurity_STANDARD];
			
			[anAcceptedCurrency addDenomination: denomination];
        
            
            printf("acceptorId = %d\n", [myAcceptorSettings getAcceptorId]);
            
			[[[Persistence getInstance] getAcceptorDAO] storeDenomination: DepositValueType_VALIDATED_CASH 
				acceptorId: [myAcceptorSettings getAcceptorId]
				currencyId: [[anAcceptedCurrency getCurrency] getCurrencyId]
				denomination: denomination];
			
		}
	}


	// Recorro la lista de denominaciones que tengo almacenadas y verifico si ya no esta
	// mas en lo que me informa el validador, en este caso la quito
	count = [denominations size];
	for (i = 0; i < count; ++i) {

		denomination = [denominations at: index];

		//LOG("Analizando denominacion: %lld\n", [denomination getAmount]);
	
		if (![self hasDenominationInList: aJcmDenominations amount: [denomination getAmount]]) {

//			doLog(0,"Elimina denominacion de %lld de la moneda %d\n", [denomination getAmount], [[anAcceptedCurrency getCurrency] getCurrencyId]);
    //************************* logcoment

			[[[Persistence getInstance] getAcceptorDAO] deleteDenomination: DepositValueType_VALIDATED_CASH 
				acceptorId: [myAcceptorSettings getAcceptorId]
				currencyId: [[anAcceptedCurrency getCurrency] getCurrencyId]
				denomination: denomination];

			[denominations removeAt: index];
	
		} else index++;
	}

}

/**/
- (void) initCurrency
{
	int jcmCurrencyId;
	ACCEPTED_DEPOSIT_VALUE acceptedDepositValue;
	ACCEPTED_CURRENCY acceptedCurrency;
	COLLECTION denominationList;
	int i;
	DENOMINATION denom;
	CURRENCY currency;
	JCMDenomination *jcmDenominations;

	if (myIsInitialize) return;

	jcmDenominations = billAcceptorGetDenominationList(myHardwareId, &jcmCurrencyId);
	if ( jcmDenominations == NULL) {
        //************************* logcoment
		//doLog(0,"billAcceptorGetDenominationList() devuelve NULL\n");
		return;
	}

	printf("InitCurrency myHardwareId = %d, jcmCurrencyId = %d\n", myHardwareId, jcmCurrencyId);
    //************************* logcoment

	if (jcmCurrencyId == 0) {
        //************************* logcoment
		//doLog(0,"Todavia no inicializo la moneda\n");
		return;
	}

	myIsInitialize = TRUE;		
	currency = [[CurrencyManager getInstance] getCurrencyById: jcmCurrencyId];

    //************************* logcoment
	printf("currency = %d\n", currency == NULL ? -1 : [currency getCurrencyId]);

	if (currency == NULL) {
        //************************* logcoment
		printf("Error: No se encontro la moneda\n");
		return;
	}

	acceptedDepositValue = [[myAcceptorSettings getAcceptedDepositValues] at: 0];
	acceptedCurrency = [[acceptedDepositValue getAcceptedCurrencies] at: 0];
			
	if ([currency getCurrencyId] != [myCurrency getCurrencyId]) {

        //************************* logcoment
		printf("Warning: cambio la moneda con respecto a la que estaba configurada, nueva (%d)\n", jcmCurrencyId);

		// ANULO LA ELIMINACION DE LA CURRENCY ACTUAL PORQUE ESTO SE HACE EN addDepositValueTypeCurrency
		// PARA CADA MONEDA DE DICHO ACCEPTOR. ESO ES PORQUE POR ALGUNA RAZON QUEDABAN 2 MONEDAS
		// CUANDO SOLO DEBERIA TENER 1.
		//[acceptedDepositValue removeDepositValueTypeCurrency: [myAcceptorSettings getAcceptorId] 
		//		currencyId: [myCurrency getCurrencyId]];

		[acceptedDepositValue addDepositValueTypeCurrency: [myAcceptorSettings getAcceptorId] 
				currencyId: [currency getCurrencyId]];

			myCurrency = currency;
			acceptedCurrency = [[acceptedDepositValue getAcceptedCurrencies] at: 0];

	}

	[self configureDenominations: acceptedCurrency denominations: jcmDenominations];


	denominationList = [acceptedCurrency getDenominations];
	for (i = 0; i < [denominationList size]; ++i) {
		denom = [denominationList at: i];
		if ([denom getDenominationState] == DenominationState_REJECT) {
            //************************* logcoment
			//doLog(0,"Inhabilitando denominacion de %lld\n", [denom getAmount]);
			[SafeBoxHAL setDenomination: myHardwareId amount: [denom getAmount] disable: 1];
		}
	}

}

/**/
- (void) statusChange: (JcmStatus) anStatus
{
    //************************* logcoment
    //	doLog(0,"BillAcceptor (%d) -> statusChange: %d\n", myHardwareId, anStatus);
	
	if (anStatus == JCM_ENABLE) myAcceptorState = AcceptorState_START;
	else if (anStatus == JCM_DISABLE) myAcceptorState = AcceptorState_STOP;

	[self initCurrency];

	//if (myObserver) [myObserver informStatusChange];
}

/**/
- (BillAcceptorStatus) waitForInitStatus
{
	BillAcceptorStatus result;

	if (myInitStatus != -1) return myInitStatus;

	// Se queda esperando hasta que se inicie el validador, es decir, que llegue el primer
	// estado del mismo y lo devuelve
	[mySyncQueue popBuffer: &result];	

	return result;
}

/**/
- (void) communicationError: (int) aCause
{
	BillAcceptorStatus eventId = -1;
	char cause[50];
	char statusName[50];

    
    printf("BillAcceptor communicationError\n");
    
        
	// El primer estado que sea 0 lo meto en una cola bloqueante
	// para el que esta esperando ese primer estado lo pueda tomar
	//modificacion sole para que se quede esperando la salida del estado FirstState de Mei
	if (!myHasFirstStatus)  {
		[mySyncQueue pushElement: &aCause];
		myHasFirstStatus = TRUE;
		myInitStatus = aCause;
	}

	// Si el error es el mismo que el anterior no tengo que hacer nada (solo informo lo cambios)
	//LOG("BillAcceptor (%d) -> communicationError. old = %d, new = %d\n", myHardwareId, myCurrentError, aCause);
	if (myCurrentError == aCause) return;
	
	myCurrentError = aCause;

	// El POWER_UP o Causa = 0 lo considero como exactamente lo mismo
	if (aCause == 0 || aCause == BillAcceptorStatus_POWER_UP) {

		// Verifica si volvio la comunicacion con el validador (si antes esta con error de comunicacion)
		if (myBillAcceptorStatus == BillAcceptorStatus_COMMUNICATION_ERROR) {
	
			[Audit auditEventCurrentUser: EVENT_DEVICE_COMMUNICATION_RECOVERY additional: "" 
				station: [myAcceptorSettings getAcceptorId] logRemoteSystem: FALSE];
	
            //************************* logcoment
			//doLog(0,"TIENE COMUNICACION ------\n");

			// me fijo si debo informar al POS del evento.
/*			if ([[POSEventAcceptor getInstance] isTelesupRunning])
				[[POSEventAcceptor getInstance] validatorStatusEvent: [myAcceptorSettings getAcceptorId] acceptorName: [myAcceptorSettings getAcceptorName] statusName: "communicationRecovery"];
*/
		}

		myBillAcceptorStatus = BillAcceptorStatus_OK;

		if ((aCause == BillAcceptorStatus_POWER_UP) && ([[UserManager getInstance] getUserLoggedIn]))
			[myAcceptorSettings verifySerialNumberChange];

		return;
	}


	if (myObserver) [myObserver onAcceptorError: self cause: aCause];
    

	switch (aCause) {

		case BillAcceptorStatus_POWER_UP: eventId = EVENT_DEVICE_COMMUNICATION_RECOVERY; break;
    case BillAcceptorStatus_POWER_UP_BILL_ACCEPTOR: eventId = Event_POWER_UP_WITH_BILL_IN_ACCEPTOR; break;
		case BillAcceptorStatus_POWER_UP_BILL_STACKER: eventId = Event_POWER_UP_WITH_BILL_IN_STACKER; break;
		case BillAcceptorStatus_STACKER_FULL: eventId = Event_VALIDATOR_FULL; break;
		case BillAcceptorStatus_STACKER_OPEN: eventId = Event_STACKER_OUT; break;
		case BillAcceptorStatus_JAM_IN_ACCEPTOR: eventId = Event_VALIDATOR_JAM; break;
		case BillAcceptorStatus_JAM_IN_STACKER: eventId = Event_VALIDATOR_JAM_IN_STACKER; break;
		case BillAcceptorStatus_PAUSE: eventId = Event_VALIDATOR_PAUSE; break;
		case BillAcceptorStatus_CHEATED: eventId = Event_VALIDATOR_CHEATED; break;
		case BillAcceptorStatus_FAILURE: eventId = Event_VALIDATOR_FAILURE; break;
		case BillAcceptorStatus_COMMUNICATION_ERROR: eventId = Event_COMUNICATION_LOST_WITH_VALIDATOR; break;
		case BillAcceptorStatus_STACK_MOTOR_FAILURE: eventId = Event_STACK_MOTOR_FAILURE; break;
		case BillAcceptorStatus_T_MOTOR_SPEED_FAILURE: eventId = Event_T_MOTOR_SPEED_FAILURE; break;
		case BillAcceptorStatus_T_MOTOR_FAILURE: eventId = Event_T_MOTOR_FAILURE; break;
		case BillAcceptorStatus_CASHBOX_NOT_READY: eventId = Event_CASHBOX_NOT_READY; break;
		case BillAcceptorStatus_VALIDATOR_HEAD_REMOVED: eventId = Event_VALIDATOR_HEAD_REMOVED; break;
		case BillAcceptorStatus_BOOT_ROM_FAILURE: eventId = Event_BOOT_ROM_FAILURE; break;
		case BillAcceptorStatus_EXTERNAL_ROM_FAILURE: eventId = Event_EXTERNAL_ROM_FAILURE; break;
		case BillAcceptorStatus_ROM_FAILURE: eventId = Event_ROM_FAILURE; break;
		case BillAcceptorStatus_EXTERNAL_ROM_WRITING_FAILURE: eventId = Event_EXTERNAL_ROM_WRITING_FAILURE; break;
		case BillAcceptorStatus_WAITING_BANKNOTE_TO_BE_REMOVED: eventId = Event_WAIT_BANKNOTE_TO_BE_REMOVED; break;
        
	}

	// me fijo si debo informar al POS del evento.
	/*if ([[POSEventAcceptor getInstance] isTelesupRunning]) {

		statusName[0] = '\0';
		switch (aCause) {
			case BillAcceptorStatus_POWER_UP_BILL_ACCEPTOR: strcpy(statusName,"validatorPowerUp"); break;
			case BillAcceptorStatus_POWER_UP_BILL_STACKER: strcpy(statusName,"cassettePowerUp"); break;
			case BillAcceptorStatus_JAM_IN_ACCEPTOR: strcpy(statusName,"validatorJam"); break;
			case BillAcceptorStatus_JAM_IN_STACKER: strcpy(statusName,"cassetteJam"); break;
			case BillAcceptorStatus_PAUSE: strcpy(statusName,"pause"); break;
			case BillAcceptorStatus_CHEATED: strcpy(statusName,"cheated"); break;
			case BillAcceptorStatus_FAILURE: strcpy(statusName,"validatorFailure"); break;
			case BillAcceptorStatus_COMMUNICATION_ERROR: strcpy(statusName,"communicationError"); break;
			case BillAcceptorStatus_STACK_MOTOR_FAILURE: strcpy(statusName,"stackMotorFailure"); break;
			case BillAcceptorStatus_T_MOTOR_SPEED_FAILURE: strcpy(statusName,"motorSpeedFailure"); break;
			case BillAcceptorStatus_T_MOTOR_FAILURE: strcpy(statusName,"motorFailure"); break;
			case BillAcceptorStatus_CASHBOX_NOT_READY: strcpy(statusName,"cashboxNotReady"); break;
			case BillAcceptorStatus_VALIDATOR_HEAD_REMOVED: strcpy(statusName,"validatorHeadRemoved"); break;
		}

		if (strlen(statusName) > 0)
			[[POSEventAcceptor getInstance] validatorStatusEvent: [myAcceptorSettings getAcceptorId] acceptorName: [myAcceptorSettings getAcceptorName] statusName: statusName];
	}*/

	// Si es un codigo de error (todo lo que va de STACKER_FULL en adelante) lo guardo en
	// una variable
	if (aCause >= BillAcceptorStatus_STACKER_FULL || aCause == BillAcceptorStatus_REJECTING) myBillAcceptorStatus = aCause;

	// No logueo el evento de REJECTING porque ya lo va a auditar con la funcion de callback 
	// propia del Bill Rejected
    //No logueo waiting banknotetoberemoved , es solo un msj al usuario 
	if ((aCause != BillAcceptorStatus_REJECTING) && (aCause != BillAcceptorStatus_WAITING_BANKNOTE_TO_BE_REMOVED)){
		if (eventId != -1)
			[Audit auditEventCurrentUser: eventId additional: [myAcceptorSettings getAcceptorName] station: [myAcceptorSettings getAcceptorId] logRemoteSystem: FALSE];
		else { // es un evento desconocido. En el adicional pongo el numero de la causa
			sprintf(cause,"%d",aCause);
			[Audit auditEventCurrentUser: Event_UNKNOWN_CAUSE additional: cause station: [myAcceptorSettings getAcceptorId] logRemoteSystem: FALSE];
		}
	}

	// Control de cheated y mei
	if (aCause == BillAcceptorStatus_CHEATED) {
        //************************* logcoment
		//doLog(0, "is cheated\n");
		if ( [myAcceptorSettings getAcceptorProtocol] == ProtocolType_EBDS ){
            //************************* logcoment
			//doLog(0, "is cheated 1\n");
			
			[myAcceptorSettings setDisabled:TRUE];
            //************************* logcoment
			//doLog(0, "is cheated2\n");
			[myAcceptorSettings applyChanges];
			//doLog(0, "is cheated3\n");
            //************************* logcoment

			[self disableCommunication];
			//doLog(0, "is cheate4d\n");
            //************************* logcoment
		}
	}


/*     //************************* logcoment
 
 * if (aCause == BillAcceptorStatus_COMMUNICATION_ERROR) {
    doLog(0,"\n*************************************\n");
    doLog(0,"**** PERDIDA DE COMUNICACION VAL ****\n");
    doLog(0,"*************************************\n");
  }
  */
}

/**/
- (StackerSensorStatus) getStackerSensorStatus
{
	return myStackerSensorStatus;
}

/**/
- (void) stackerSensorStatusChange: (StackerSensorStatus) anStatus
{
    
    //************************* logcoment
	//doLog(0,"BillAcceptor (%d) -> stackerSensorStatusChange = %d\n", myHardwareId, anStatus);
	
	// El sensor de la bolsa se comporta de la misma manera al stacker del validador
	// La unica diferencia es que ahora tengo por un lado el estado del validador y 
	// por otro el estado de la bolsa pero lo integro como si fuera una sola cosa
	
	// Si estaba removido y ahora lo colocaron entonces genero una auditoria
	if (myStackerSensorStatus == StackerSensorStatus_REMOVED && anStatus == StackerSensorStatus_INSTALLED) {
		[Audit auditEventCurrentUser: Event_STACKER_OK additional: [myAcceptorSettings getAcceptorName] station: [myAcceptorSettings getAcceptorId] 
				logRemoteSystem: FALSE];
	}

	myStackerSensorStatus = anStatus;


	// me fijo si debo informar al POS del evento.
    /*
	if ([[POSEventAcceptor getInstance] isTelesupRunning]) {
		if (anStatus == StackerSensorStatus_REMOVED)
			[[POSEventAcceptor getInstance] cassetteRemovedEvent: [myAcceptorSettings getAcceptorId] acceptorName: [myAcceptorSettings getAcceptorName]];

		if (anStatus == StackerSensorStatus_INSTALLED)
			[[POSEventAcceptor getInstance] cassetteInstalledEvent: [myAcceptorSettings getAcceptorId] acceptorName: [myAcceptorSettings getAcceptorName]];
	}
*/
	// Si la bolsa esta removida informo un error de STACKER_OPEN
	if (anStatus == StackerSensorStatus_REMOVED) {

		[self communicationError: BillAcceptorStatus_STACKER_OPEN];

	// Si la bolsa fue instalada y el error actual es STACKER_OPEN limpio el error actual
	} else if (anStatus == StackerSensorStatus_INSTALLED && myCurrentError == BillAcceptorStatus_STACKER_OPEN) {

		// Limpio el error
		[self communicationError: BillAcceptorStatus_OK];

	}
	
}

/**/
- (void) billAccepted: (money_t) anAmount currencyId: (int) aCurrencyId qty: (int) aQty
{
	id 	currency = [[CurrencyManager getInstance] getCurrencyById: aCurrencyId];

    //************************* logcoment
	printf("BBillAcceptor (%d) -> billAccepted = %lld %d\n", myHardwareId, anAmount, aCurrencyId );

	if (myObserver) [myObserver onBillAccepted: self currency: currency amount: anAmount qty: aQty];

	//if (myObserver) [myObserver onBillAccepted: self currency: myCurrency amount: anAmount qty: aQty];

	// me fijo si debo informar al POS del evento.
/*	if ([[POSEventAcceptor getInstance] isTelesupRunning]) {
		[[POSEventAcceptor getInstance] billAcceptedEvent: [myAcceptorSettings getAcceptorId] amount: anAmount currencyId: aCurrencyId];
	}
*/
}

/**/
- (void) billAccepting
{
	if (myObserver) [myObserver onBillAccepting: self];
}

/**/
- (void) billRejected: (int) aCause qty: (int) aQty
{
	if (myObserver) [myObserver onBillRejected: self cause: aCause qty: aQty];

	// me fijo si debo informar al POS del evento.
/*	if ([[POSEventAcceptor getInstance] isTelesupRunning]) {
		[[POSEventAcceptor getInstance] billRejectedEvent: [myAcceptorSettings getAcceptorId]];
	}*/
}

/**/
- (BOOL) updateFirmware: (char *) aPath observer: (id) anObserver
{
	doLog(0,"Actualizando firmware a %s del validador %d\n", aPath, myHardwareId);
	myFirmwareUpdateObserver = anObserver;
	return [SafeBoxHAL updateFirmware: myHardwareId path: aPath];
}

/**/
- (void) onFirmwareUpdateProgress: (BILL_ACCEPTOR) anAcceptor progress: (int) aProgress { }

/**/
- (void) firmwareUpdateProgress: (int) aProgress 
{
	if (myFirmwareUpdateObserver) [myFirmwareUpdateObserver onFirmwareUpdateProgress: self progress: aProgress];

	// Si termino de actualizar el firmware, puedo inicializar todo nuevamente
	// por las dudas que haya cambiado la moneda, denominaciones, etc.
	if (aProgress == 100) {
		myIsInitialize = FALSE;
	}
}

/**/
- (int) getCurrentError { return myCurrentError; }


/**/
- (BOOL) hasCommunicationError { return myCurrentError == BillAcceptorStatus_COMMUNICATION_ERROR; }

/**/
- (void) enableCommunication 
{
	// Habilita el bill acceptor
    printf("1 myHardwareId = %d\n", myHardwareId);
	[SafeBoxHAL setBillAcceptorStatus: myHardwareId enabled: TRUE];
    printf("2\n");
	myEnableCommunication = TRUE;
}

/**/
- (void) disableCommunication 
{
	// deshabilita el bill acceptor
	[SafeBoxHAL setBillAcceptorStatus: myHardwareId enabled: FALSE];
	myEnableCommunication = FALSE;
}


@end
