#include "CdmCoinAcceptor.h"
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

//#define LOG(args...) doLog(0,args)

#define CDM_MOTOR_STOPPED	  0
#define CDM_MOTOR_RUNNING		1
#define CDM_FINISH_COUNTING 2

#define CDM_CLOSE_TIMEOUT (5 * 60 * 1000)

typedef struct {
	int cause;
	int resourceString;
	char *defaultString;
} BillAcceptorCause;


static BillAcceptorCause BillAcceptorErrorCauseArray[] = {
	{BillAcceptorStatus_OK, RESID_OK_UPPER, "OK"}
 ,{CDM_BOXFULL, RESID_STACKER_FULL, "Stacker Lleno"}
 ,{CDM_CASEFULL, RESID_STACKER_FULL, "Stacker Lleno"}
 ,{CDM_COVEROPEN, RESID_COVER_OPEN, "Tapa abierta"}
 ,{CDM_COINJAM, RESID_COIN_JAM, "Moneda atascada"}
 ,{CDM_PRESSRAIL, RESID_PRESS_RAIL, "Presione el riel de transporte"}
 ,{CDM_COINUNDERSENSOR, RESID_COIN_UNDER_SENSOR, "Moneda bajo el sensor"}
 ,{CDM_COMMERROR, RESID_COMMUNICATION_ERROR, "Error en comunic."}
 ,{999, RESID_UNDEFINE, "Undefined"}
};

/**/
void cdmCommErrorNotifFcn( int devId, int cause ) 
{
  CimEvent event;

	doLog(0,"SafeBoxHAL -> cdmCommErrorNotifFcn (%d), cause = %d\n", devId, cause);

  event.hardwareId = devId;
  event.status = cause;
  event.amount = 0;
  event.event  = CimEvent_ACCEPTOR_ERROR;

	[[CimEventDispatcher getInstance] addEvent: &event];
}

/**/
void cdmChangeStatusNotif( int devId, unsigned char newStatus ) 
{
	CimEvent event;

	doLog(0,"SafeBoxHAL -> cdmChangeStatusNotif (%d), newStatus = %d\n", devId, newStatus);

	event.hardwareId = devId;
	event.status = newStatus;
	event.event  = CimEvent_STATUS_CHANGE;
	event.amount = 0;

	[[CimEventDispatcher getInstance] addEvent: &event];
}

/**/
void cmdCoinsAcceptedNotif(int devId, DenominationCount* coinsAccepted, int failureCount )
{
	CimEvent event;
  int i;

	doLog(0,"SafeBoxHAL -> cmdCoinsAcceptedNotif (%d), failureCount = %d\n", devId, failureCount);

  // Son 9 elementos fijos los que pueden venir
  for (i = 0; i < 9; i++) {

    if (coinsAccepted[i].qty > 0) {

      event.hardwareId = devId;
      event.status = 0;
	    event.event  = CimEvent_BILL_ACCEPTED;
      event.amount = coinsAccepted[i].amount;
      event.qty = coinsAccepted[i].qty;
      event.currencyId = 0;
  
     [[CimEventDispatcher getInstance] addEvent: &event];

    }

  }

  // Agrego un elemento mas para indicar las monedas rechazadas
  if (failureCount > 0) {
    
    event.hardwareId = devId;
    event.status = 0;
    event.event  = CimEvent_BILL_REJECTED;
    event.amount = 0;
    event.qty = failureCount;
  
    [[CimEventDispatcher getInstance] addEvent: &event];

  }

	// Agrega una unica vez un evento para indicar que termino de contar las monedas
	cdmChangeStatusNotif(devId, CDM_FINISH_COUNTING);
}

@implementation CdmCoinAcceptor


/** implementada en el observer */
- (void) onBillAccepted: (ABSTRACT_ACCEPTOR) anAcceptor currency: (CURRENCY) aCurrency amount: (money_t) anAmount  qty: (int) aQty { }
- (void) onBillRejected: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause  qty: (int) aQty { }
- (void) onBillAccepting: (ABSTRACT_ACCEPTOR) anAcceptor { }
- (void) onAcceptorError: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause { }

/**/
- (BOOL) isEnabled
{
	// Si el motor esta corriendo o todavia tengo un conteo pendiente, debe estar habilitado
	return myCountPending || myMotorRunning;
}

/**/
- (void) initAcceptor
{
	int comPortNumber;

  doLog(0,"CmdCoinAcceptor - inicializa el dispositivo\n");

	myCurrency = NULL;
	myMotorRunning = FALSE;
	myHardwareId = [myAcceptorSettings getAcceptorHardwareId];
	myIsInitialize = FALSE;
	myCurrentError = BillAcceptorStatus_OK;
	strcpy(myVersion, getResourceStringDef(RESID_NOT_AVAILABLE, "N/D"));
	myBillAcceptorStatus = BillAcceptorStatus_OK;	
	myCurrency = [myAcceptorSettings getDefaultCurrency];
	myCountPending = FALSE;

	THROW_NULL(myCurrency);

  comPortNumber = [[Configuration getDefaultInstance] getParamAsInteger: "CDM_COM_PORT" default: 2];
  myCdmData = cdmNew(comPortNumber, myHardwareId, cdmCommErrorNotifFcn, cdmChangeStatusNotif, cmdCoinsAcceptedNotif);

	// Registra para recibir los eventos
	[[CimEventDispatcher getInstance] registerDevice: myHardwareId
		deviceType: DeviceType_VALIDATOR 
		object: self external: TRUE];

  doLog(0,"CmdCoinAcceptor - Arranca\n");

	// 
	myHasEmitStackerWarning = FALSE;
	myHasEmitStackerFull = FALSE;

}

- (void) open
{
	doLog(0,"CmdCoinAcceptor -> open (%d)\n", myHardwareId);

	//cdmClearCounter(myCdmData);
  cdmStartCounting(myCdmData);
	myCountPending = TRUE;

	// Aca deberia esperar a que el estado sea START o ERROR para seguir adelante
	doLog(0,"Esperando estado START o ERROR...");

	while (1) {
		// Tengo que esperar hasta hasta que comience a girar el motor
		if (!myMotorRunning && myBillAcceptorStatus == BillAcceptorStatus_OK) msleep(1);
		else break;
	}

	doLog(0,"[START] - Status = %d\n", myBillAcceptorStatus);
}

/**/
- (void) reopen
{
	doLog(0,"CmdCoinAcceptor -> open (%d)\n", myHardwareId);
  cdmStartCounting(myCdmData);
	myCountPending = TRUE;
}

/**/
- (BOOL) canReopen { return TRUE; }

/**/
- (void) close
{
	unsigned long ticks = getTicks();

	doLog(0,"CmdCoinAcceptor -> close (%d)\n", myHardwareId);

  cdmStopCounting(myCdmData);

	// Aca deberia esperar a que el estado sea STOP o ERROR para seguir adelante
	doLog(0,"Esperando estado STOP o ERROR...");

	while (1) {

		// Por las dudas meto un timeout grande
		if (getTicks() - ticks > CDM_CLOSE_TIMEOUT) break;

		// Si hay error de comunicacion chau, no me quedo esperando
		if (myBillAcceptorStatus == BillAcceptorStatus_COMMUNICATION_ERROR) break;

		// Si el motor esta corriendo o hay un conteo pendiente espero
		if (myMotorRunning || myCountPending) msleep(1);
		else break;
		
	}

	doLog(0,"[STOP] - Status = %d\n", myBillAcceptorStatus);

}

/**/
- (void) setValidatedMode
{
}

/**/
- (char *) getRejectedDescription: (int) aCode
{
  return getResourceStringDef(RESID_UNDEFINE, "Undefined");
}

/**/
- (char *) getCurrentErrorDescription
{
	return [self getErrorDescription: myCurrentError];
}

/**/
- (char *) getErrorDescription: (int) aCode
{
	int i;

	for (i = 0; ; i++) {

		if (BillAcceptorErrorCauseArray[i].cause == aCode || BillAcceptorErrorCauseArray[i].cause == 999) {
			return getResourceStringDef(BillAcceptorErrorCauseArray[i].resourceString, BillAcceptorErrorCauseArray[i].defaultString);
		}

	}

	return NULL;
}

/**/
- (void) initCurrency
{
}

/**/
- (void) statusChange: (JcmStatus) anStatus
{
	doLog(0,"CmdCoinAcceptor (%d) -> statusChange: %d\n", myHardwareId, anStatus);
	
	if (anStatus == CDM_MOTOR_RUNNING) myMotorRunning = TRUE;
	else if (anStatus == CDM_MOTOR_STOPPED) myMotorRunning = FALSE;
	else if (anStatus == CDM_FINISH_COUNTING) myCountPending = FALSE;

}

/**/
- (BillAcceptorStatus) waitForInitStatus
{
  return BillAcceptorStatus_OK;
}

/**/
- (void) communicationError: (int) aCause
{
	BillAcceptorStatus eventId = -1;

	// Si el error es el mismo que el anterior no tengo que hacer nada (solo informo lo cambios)
	//LOG("BillAcceptor (%d) -> communicationError. old = %d, new = %d\n", myHardwareId, myCurrentError, aCause);
	if (myCurrentError == aCause) return;
	
	myCurrentError = aCause;

	// El POWER_UP o Causa = 0 lo considero como exactamente lo mismo
	if (aCause == CDM_NOERROR) {

		// Verifica si volvio la comunicacion con el validador (si antes esta con error de comunicacion)
		if (myBillAcceptorStatus == CDM_COMMERROR) {
	
			[Audit auditEventCurrentUser: EVENT_DEVICE_COMMUNICATION_RECOVERY additional: "" 
				station: [myAcceptorSettings getAcceptorId] logRemoteSystem: FALSE];
	
			doLog(0,"TIENE COMUNICACION ------\n");

		}

		myBillAcceptorStatus = CDM_NOERROR;

		return;
	}


	if (myObserver) [myObserver onAcceptorError: self cause: aCause];

	switch (aCause) {

		case CDM_COINJAM: eventId = Event_VALIDATOR_JAM; break;
		case CDM_BOXFULL: eventId = Event_VALIDATOR_FULL; break;
		case CDM_COINUNDERSENSOR: eventId = Event_VALIDATOR_JAM; break;
		case CDM_COVEROPEN: eventId = Event_STACKER_OUT; break;
/** @todo - cdm: ver que significa este evento */
//		case CDM_PRESSRAIL: eventId = Event_VALIDATOR_PAUSE; break;
		case CDM_CASEFULL: eventId = Event_VALIDATOR_FULL; break;
		case CDM_COMMERROR: eventId = Event_COMUNICATION_LOST_WITH_VALIDATOR; break;

	}


  myBillAcceptorStatus = aCause;

	if (eventId != -1) {
	  [Audit auditEventCurrentUser: eventId additional: [myAcceptorSettings getAcceptorName] station: [myAcceptorSettings getAcceptorId] logRemoteSystem: FALSE];
	}

  if (aCause == BillAcceptorStatus_COMMUNICATION_ERROR){
    doLog(0,"\n*****************************************\n");
		doLog(0,"**** PERDIDA DE COMUNICACION CDMCOIN ****\n");
    doLog(0,"*****************************************\n");
  }
  
}

/**/
- (StackerSensorStatus) getStackerSensorStatus
{
	return StackerSensorStatus_UNDEFINED;
}

/**/
- (void) stackerSensorStatusChange: (StackerSensorStatus) anStatus
{
}

/**/
- (void) billAccepted: (money_t) anAmount currencyId: (int) aCurrencyId qty: (int) aQty
{
	doLog(0,"CmdCoinAcceptor (%d) -> billAccepted = %lld %d, qty=%d\n", myHardwareId, anAmount, aCurrencyId, aQty);
	if (myObserver) [myObserver onBillAccepted: self currency: myCurrency amount: anAmount qty: aQty];

	// me fijo si debo informar al POS del evento.
	/*if ([[POSEventAcceptor getInstance] isTelesupRunning])
		[[POSEventAcceptor getInstance] billAcceptedEvent: [[self getAcceptorSettings] getAcceptorId] amount: anAmount currencyId: aCurrencyId];
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
	/*if ([[POSEventAcceptor getInstance] isTelesupRunning])
		[[POSEventAcceptor getInstance] billRejectedEvent: [[self getAcceptorSettings] getAcceptorId]];*/
}

/**/
- (BOOL) updateFirmware: (char *) aPath observer: (id) anObserver
{
	doLog(0,"CmdCoinAcceptor -> Actualizando firmware a %s del validador %d\n", aPath, myHardwareId);
	myFirmwareUpdateObserver = anObserver;
  return 1;
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

@end
