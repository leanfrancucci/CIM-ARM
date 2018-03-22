#ifndef BILL_ACCEPTOR_H
#define BILL_ACCEPTOR_H

#define BILL_ACCEPTOR id

#include <Object.h>
#include "AbstractAcceptor.h"
#include "Currency.h"

#define BillAcceptorStatus_OK		0



/**
 *	Aceptador / Validador de billetes.
 */
@interface BillAcceptor : AbstractAcceptor
{
	CURRENCY myCurrency;			/** Tipo de divisa que acepta el validador (en el futuro pueden ser varias) */
	AcceptorState myAcceptorState;
	int myHardwareId;
	BOOL myIsInitialize;
	id myFirmwareUpdateObserver;
	int myCurrentError;
	STATIC_SYNC_QUEUE mySyncQueue;
	BOOL myHasFirstStatus;
	int myInitStatus;
	BillAcceptorStatus myBillAcceptorStatus;
	StackerSensorStatus myStackerSensorStatus;
	BOOL myInValidatedMode;
	BOOL myEnableCommunication;
}

/**/
- (char *) getVersion;

/**/
- (BOOL) updateFirmware: (char *) aPath observer: (id) anObserver;

/**
 *	Espera hasta que que llegue el estado inicial y lo devuleve.
 *	Es un procedimiento bloqueante, se queda esperando hasta que el validador le 
 *	reporte el primer estado y lo devuelve.
 */
- (BillAcceptorStatus) waitForInitStatus;

- (StackerSensorStatus) getStackerSensorStatus;

- (BOOL) inValidatedMode;

/**/
- (void) enableCommunication;

/**/
- (void) disableCommunication;

/**/
- (int) getCurrentError;

/**/
- (BOOL) hasCommunicationError;

@end

#endif
