#ifndef CDM_COIN_ACCEPTOR_H
#define CDM_COIN_ACCEPTOR_H

#define CDM_COIN_ACCEPTOR id

#include <Object.h>
#include "AbstractAcceptor.h"
#include "Currency.h"
#include "cdm3000.h"
#include "BillAcceptor.h"

/**
 *	Aceptador / Validador de monedas.
 */
@interface CdmCoinAcceptor: AbstractAcceptor
{
	CURRENCY myCurrency;			/** Tipo de divisa que acepta el validador (en el futuro pueden ser varias) */
	int myHardwareId;
	BOOL myIsInitialize;
	id myFirmwareUpdateObserver;
	int myCurrentError;
	BillAcceptorStatus myBillAcceptorStatus;
	BOOL myCountPending;
	BOOL myMotorRunning;
  Cdm3000Data *myCdmData;
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


@end

#endif
