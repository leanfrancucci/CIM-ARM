#include "CimStateDeposit.h"
#include "Persistence.h"
#include "CimAudits.h"
#include "system/util/all.h"
#include "CimManager.h"
#include "CimGeneralSettings.h"
#include "TempDepositDAO.h"
#include "DepositManager.h"
#include "AbstractAcceptor.h"
#include "MessageHandler.h"
#include "POSAcceptor.h"

//#define LOG(args...) doLog(0,args)

@implementation CimStateDeposit

// Forward
- (void) resetTimers;

// Implementados en el observers (solo estan aqui para que no den warning)
- (void) onCloseDeposit { }
- (void) onOpenDeposit { }
- (void) onInactivityWarning: (OTIMER) aTimer { }

/**/
- initialize
{
	[super initialize];
	myDeposit = NULL;
	myInactivityTimer = [OTimer new];
	myCloseTimer = [OTimer new];
	myMutex = [OMutex new];
	return self;
}

/**/
- (void) setDeposit: (DEPOSIT) aDeposit
{
	myDeposit = aDeposit;
}

/**/
- (DEPOSIT) getDeposit
{
	return myDeposit;
}

/**/
- (void) activateState
{
	int i;

	[super activateState];

	[myMutex lock];

	TRY
		
		// Abro los validadores de billetes / buzon
		[myCim openCimCash: [myDeposit getCimCash]];
	
		// Notifico a los observers
		for (i = 0; i < [myObservers size]; ++i) {
			[[myObservers at: i] onOpenDeposit];
		}
	
		//LOG("CimStateDeposit -> activateState\n");
		
		[myInactivityTimer initTimer: ONE_SHOT
				period: [[CimGeneralSettings getInstance] getMaxInactivityTimeOnDeposit] * 1000
				object: self
				callback: "inactivityTimerHandler"];
		[myInactivityTimer start];
	
		[myCloseTimer initTimer: ONE_SHOT
				period: [[CimGeneralSettings getInstance] getWarningTime] * 1000
				object: self
				callback: "closeTimerHandler"];

	FINALLY

		[myMutex unLock];

	END_TRY

}

/**/
- (void) resetTimers
{
	[myCloseTimer stop];
	[myInactivityTimer start];
}

/**/
- (void) deactivateState
{
	int i;

	[super deactivateState];

	// Esto es un maneje para evitar que me cierre 2 veces el mismo deposito por cuestiones
	// de concurrencia, solo 1 puede estar cerrando el deposito al mismo tiempo
	[myMutex lock];

	TRY

		if (myDeposit != NULL) {
		
			//LOG("CimStateDeposit -> deactivateState\n");
		
			[myInactivityTimer stop];
			[myCloseTimer stop];
		
			// Cierro los validadores de billetes
			[myCim closeCimCash: [myDeposit getCimCash]];
		
			// Notifico a los observers
			for (i = 0; i < [myObservers size]; ++i) {
				[[myObservers at: i] onCloseDeposit];
			}
		
			// Finalizo el deposito
			[[DepositManager getInstance] endDeposit: myDeposit];

			// reseteo la variable myDrop
			if ([[POSAcceptor getInstance] isTelesupRunning])
				[[POSAcceptor getInstance] resetDrop];

			myDeposit = NULL;

		}

	FINALLY

		[myMutex unLock];

	END_TRY

}

/**/
- (void) onAcceptorError: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause
{
}

/**/
- (void) onBillAccepted: (ABSTRACT_ACCEPTOR) anAcceptor currency: (CURRENCY) aCurrency amount: (money_t) anAmount  qty: (int) aQty
{
	int i;
	DEPOSIT_DETAIL detail;

	[super onBillAccepted: anAcceptor currency: aCurrency amount: anAmount qty: aQty];

	//LOG("CimStateDeposit -> llego un billete de %s (%s)\n", [aCurrency getName], formatMoney(moneyStr, "", anAmount, 2, 40));

	if (![anAcceptor isEnabled]) {
    //************************* logcoment
//		doLog(0, "CimStateDeposit -> validador en estado STOP\n");
		return;
	}

	[self resetTimers];

	detail = [myDeposit addDepositDetail: [anAcceptor getAcceptorSettings]
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: aCurrency
		qty: aQty
		amount: anAmount];

	// Grabo el detalle de forma temporal
	[[[Persistence getInstance] getTempDepositDAO] saveDepositDetail: myDeposit detail: detail];

	// Notifico a los observadores de este evento
	for (i = 0; i < [myObservers size]; ++i)
		[[myObservers at: i] onBillAccepted: anAcceptor currency: aCurrency amount: anAmount qty: aQty];

}

/**/
- (void) onBillRejected: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause  qty: (int) aQty
{
	int i;
	char additional[100];

	[super onBillRejected: anAcceptor cause: aCause qty: aQty];

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

    //************************* logcoment
	//doLog(0,"CimStateDeposit -> se rechazo a  un billete, codigo = %d\n", aCause);

    if (![anAcceptor isEnabled]) {
    //************************* logcoment
//		doLog(0, "CimStateDeposit -> el validador se encuentra en estado STOP\n");
		return;
	}

	[self resetTimers];

	// Actualizo la cantidad de billetes rechazada
	[myDeposit addRejectedQty: aQty];

	// Actualizo el deposito temporal
	[[[Persistence getInstance] getTempDepositDAO] updateDeposit: myDeposit];

	// Notifico a los observadores de este evento
	for (i = 0; i < [myObservers size]; ++i)
		[[myObservers at: i] onBillRejected: anAcceptor cause: aCause qty: aQty];
}

/**/
- (void) onBillAccepting: (ABSTRACT_ACCEPTOR) anAcceptor
{
	int i;

	// Notifico a los observadores de este evento
	for (i = 0; i < [myObservers size]; ++i)
		[[myObservers at: i] onBillAccepting: anAcceptor];

}

/**/
- (void) inactivityTimerHandler
{
	int i;

    //************************* logcoment
	//doLog(0, "CimStateDeposit -> se termino el tiempo sin actividad\n");

	// Si no hay tiempo de warning, entonces lo cierro automaticamente
	if ([[CimGeneralSettings getInstance] getWarningTime] == 0) {
        //************************* logcoment
		//doLog(0, "CimStateDeposit -> cierra el deposito por inactividad\n");
		[[CimManager getInstance] endDeposit];

		// reseteo la variable myDrop
		if ([[POSAcceptor getInstance] isTelesupRunning])
			[[POSAcceptor getInstance] resetDrop];

		return;
	}

	[myCloseTimer start];

	// Notifico a los observadores de este evento
	for (i = 0; i < [myObservers size]; ++i)
		[[myObservers at: i] onInactivityWarning: myCloseTimer];

}

/**/
- (void) closeTimerHandler
{
    //************************* logcoment
	//doLog(0, "CimStateDeposit -> cierra el deposito por inactividad\n");

	[[CimManager getInstance] endDeposit];

	// reseteo la variable myDrop
	if ([[POSAcceptor getInstance] isTelesupRunning])
		[[POSAcceptor getInstance] resetDrop];
}

/**/
- (void) needMoreTime
{
	[self resetTimers];
}

@end

