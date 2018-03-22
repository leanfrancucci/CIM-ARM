#ifndef CIM_MANAGER_H
#define CIM_MANAGER_H

#define CIM_MANAGER id
#include "Object.h"
#include "CimDefs.h"
#include "Cim.h"
#include "CimState.h"
#include "AbstractAcceptor.h"
#include "Currency.h"
#include "Deposit.h"
#include "Door.h"
#include "CimStateExtraction.h"
#include "CimStateDeposit.h"
#include "CimStateIdle.h"
#include "system/util/all.h"
#include "CimCash.h"
#include "ExtractionWorkflow.h"
#include "SafeBoxHAL.h"

/**
 *	Clase principal que nuclea todos los eventos que llegan de los dispositivos
 *	y lo distribuye a la clase correspondiente para su tratamiento.
 *	
 *	
 *	Internamente implementa un patron State para diferenciar el comportamiento en los 
 *	diferentes estados (Idle, Deposit, Extraction).
 *
 *	<<singleton>>
 */
@interface CimManager :  Object
{
	CIM_STATE_IDLE myCimStateIdle;
	CIM_STATE_DEPOSIT myCimStateDeposit;
	CIM_STATE myCurrentState;
	COLLECTION myObservers;
	COLLECTION myExtractionWorkflowList;
	COLLECTION myExtendedDrops;
	BOOL myInValidationMode;
	CIM myCim;
	OTIMER myShutdownTimer;
	BOOL inManualDropState;
	BOOL myShowAlarmaBattery;
	unsigned long ticks;
}

/**
 *  Devuelve la unica instancia posible de esta clase
 */
+ getInstance;

/**
 *	Comienza un deposito del tipo pasado como parametro.
 *	@return el deposito creado.
 */
- (DEPOSIT) startDeposit: (CIM_CASH) aCimCash depositType: (DepositType) aDepositType;
- (DEPOSIT) startDeposit: (USER) aUser cimCash: (CIM_CASH) aCimCash depositType: (DepositType) aDepositType;

/**/
- (DEPOSIT) startExtendedDrop: (USER) aUser cimCash: (CIM_CASH) aCimCash cashReference: (CASH_REFERENCE) aCashReference 
	envelopeNumber: (char *) anEnvelopeNumber applyTo: (char *) anApplyTo;
- (void) endExtendedDrop: (CIM_CASH) aCimCash;
- (void) endAllExtendedDropsForUser: (USER) aUser;
- (void) endAllExtendedDrops;
- (DEPOSIT) getExtendedDrop: (CIM_CASH) aCimCash;
- (COLLECTION) getExtendedDrops;
- (DEPOSIT) getExtendedDropByDoor: (DOOR) aDoor;

/**/
- (void) startValidationMode;
- (void) stopValidationMode;

/**/
- (BOOL) hasActiveTimeDelays;

/**
 *	Finaliza un deposito.
 */
- (void) endDeposit;

/**
 *	Metodo para atender al evento de puerta abierta.
 *	@param door la puerta que se abrio.
 */
- (void) onDoorOpen: (DOOR) aDoor;

/**
 *	Metodo para atender al evento de puerta cerrada
 *	@param door la puerta que se cerro.
 */
- (void) onDoorClose: (DOOR) aDoor;

/**/
- (void) onLocked: (DOOR) aDoor;

/**/
- (void) onUnLocked: (DOOR) aDoor;

/**
 *	Metodo para atender al evento de billete aceptado.
 *	El comportamiento del metodo dependera del estado en el cual se encuentre el CIM.
 *	@param acceptor el validador por el cual se ingreso el billete.
 *	@param currency el tipo de divisa aceptada.
 *	@param amount el monto del billete (denominacion).
 */
- (void) onBillAccepted: (ABSTRACT_ACCEPTOR) anAcceptor currency: (CURRENCY) aCurrency amount: (money_t) anAmount qty: (int) aQty;

/**/
- (void) onAcceptorError: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause;

/**/
- (void) onBillAccepting: (ABSTRACT_ACCEPTOR) anAcceptor;

/**
 *	Metodo para atender al evento de billete rechazado
 *	El comportamiento del metodo dependera del estado en el cual se encuentre el CIM.
 *	@param acceptor el validador por el cual se ingreso el billete.
 *	@param cause causa de rechazo del billete.
 */
- (void) onBillRejected: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause  qty: (int) aQty;

/**
 *	Agrega un observer a la lista.
 */
- (void) addObserver: (id) anObserver;

/**
 *	Remueve un observer de la lista.
 */
- (void) removeObserver: (id) anObserver;

/**
 *	Devuelve la puerta en base al identificador pasado como parametro.
 */
- (DOOR) getDoorById: (int) aDoorId;

/**
 *	Devuelve la puerta interna de la puerta con el identificador pasado como parametro.
 */
- (DOOR) getInnerDoor: (int) aDoorId;

/**
 *	Devuelve la puerta en base al identificador pasado como parametro.
 */
- (CIM_CASH) getCimCashById: (int) aCimCashId;

/**
 *	Devuelve la puerta en base al identificador pasado como parametro.
 */
- (DOOR) getAcceptorSettingsById: (int) anAcceptorSettingsId;

/**
 *	Devuelve el CIM.
 */
- (CIM) getCim;

/**
 *	Arranca los aceptadores.
 *	Este metodo deberia llamarse una unica vez al inicio del sistema cuando ya esta todo configurado.
 */
- (void) start;

/**
 *	Esto metodo se utiliza cuando el usuario responde afirmativamente a la pregunta
 *	de "Necesita mas tiempo?". Resetea los timers.
 */
- (void) needMoreTime;

/**
 *	Devuelve la lista de el workflow de puertas.
 */
- (COLLECTION) getExtractionWorkflowList;

/**
 *	Devuelve el workflow de extraccion para la puerta pasada como parametro.
 */
- (EXTRACTION_WORKFLOW) getExtractionWorkflowForDoor: (DOOR) aDoor;

/**
 *	Devuelve la lista de workflow de puertas que actualmente estan en time delay.
 *	La lista debe ser eliminada por quien llama a este metodo (pero no el contenido).
 */
- (COLLECTION) getExtractionWorkflowListOnTimeDelay;

/**/
- (void) onPowerStatusChange: (PowerStatus) aNewStatus;

/**/
- (void) onBatteryStatusChange: (BatteryStatus) aNewStatus;


/**/
- (void) onHardwareSystemStatusChange: (HardwareSystemStatus) aNewStatus;

/**/
- (void) activateAlarm;
- (void) deactivateAlarm;

/**/
- (void) activateSoundAlarm;
- (void) deactivateSoundAlarm;

/**
 *	Devuelve si el sistema esta en estado ocioso (ningun deposito ni extraccion en curso).
 */
- (BOOL) isSystemIdle;

/**
 * Devuelve si el sistema esta en estado ocioso para supervisar (no hay ni deposito ni extraccion en curso).
 */
- (BOOL) isSystemIdleForTelesup;

/**
 * Devuelve si el sistema esta en estado ocioso para generar el ZClose en forma automatica
 */
- (BOOL) isSystemIdleForAutoZClose;

/**
 * Devuelve si el sistema esta en estado ocioso para poder realizar el cambio de estado comercial.
 */
- (BOOL) isSystemIdleForChangeState: (char*) aMsg;

/**
 * Verifica de esta manera si hay validadores activos.
 */
- (BOOL) isSystemIdleForSyncFiles;

/** 
 * Setea si el sistema se encuentra realizando un manual drop o no.
 */
- (void) setInManualDropState: (BOOL) aValue;

/**/
- (void) checkCimCashState: (CIM_CASH) aCimCash;

/**/
- (void) lockerErrorStatusChange: (int) aDeviceId newStatus: (int) aNewStatus;

/**/
- (BOOL) isOnDeposit;
- (BOOL) isDoorOpen;

/**/
- (void) disableAcceptorsWithCommError;
- (void) enableAcceptorsWithCommError;

/**/
- (void) setDoorTimes;

/**/
- (void) informAlarmToObservers: (char*) aBuffer;


@end

#endif

