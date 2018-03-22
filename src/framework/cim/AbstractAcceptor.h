#ifndef ABSTRACT_ACCEPTOR_H
#define ABSTRACT_ACCEPTOR_H

#define ABSTRACT_ACCEPTOR id

#include <Object.h>
#include "AcceptorSettings.h"

typedef enum {
	AcceptorState_START,
	AcceptorState_STOP
} AcceptorState;

typedef enum {
  StackerSensorStatus_INSTALLED
 ,StackerSensorStatus_REMOVED
 ,StackerSensorStatus_UNDEFINED
} StackerSensorStatus;

typedef enum {
	 BillAcceptorStatus_REJECTING = 23					// El validador esta en un estado de rechazo de billete
	,BillAcceptorStatus_POWER_UP = 64
	,BillAcceptorStatus_POWER_UP_BILL_ACCEPTOR
	,BillAcceptorStatus_POWER_UP_BILL_STACKER
	,BillAcceptorStatus_STACKER_FULL
	,BillAcceptorStatus_STACKER_OPEN
	,BillAcceptorStatus_JAM_IN_ACCEPTOR
	,BillAcceptorStatus_JAM_IN_STACKER
	,BillAcceptorStatus_PAUSE
	,BillAcceptorStatus_CHEATED
	,BillAcceptorStatus_FAILURE
	,BillAcceptorStatus_COMMUNICATION_ERROR
	,BillAcceptorStatus_STACK_MOTOR_FAILURE = 162
	,BillAcceptorStatus_T_MOTOR_SPEED_FAILURE = 165
	,BillAcceptorStatus_T_MOTOR_FAILURE
	,BillAcceptorStatus_CASHBOX_NOT_READY = 171
	,BillAcceptorStatus_VALIDATOR_HEAD_REMOVED = 175
	,BillAcceptorStatus_BOOT_ROM_FAILURE
	,BillAcceptorStatus_EXTERNAL_ROM_FAILURE
	,BillAcceptorStatus_ROM_FAILURE
	,BillAcceptorStatus_EXTERNAL_ROM_WRITING_FAILURE
	,BillAcceptorStatus_WAITING_BANKNOTE_TO_BE_REMOVED

} BillAcceptorStatus;

/**
 *	Clase abstracta padre de todos los dispositivos aceptadores (validadores, buzones, etc).
 *	Posee los metodos comunes a todas estas clases.
 *
 *	<<abstract>>
 */
@interface AbstractAcceptor : Object
{
	ACCEPTOR_SETTINGS myAcceptorSettings;
	id myObserver;
	BOOL myHasEmitStackerWarning;
	BOOL myHasEmitStackerFull;
	char myVersion[100];
}

/**
 *	Configura el observer al cual se dirigiran todos los eventos 
 *	que se produzcan.
 */
- (void) setObserver: (id) anObserver;

/**
 *	Inicializa el aceptador.
 */
- (void) initAcceptor;

/**
 *	Configura y obtiene la configuracion del validador.
 */
- (void) setAcceptorSettings: (ACCEPTOR_SETTINGS) aValue;
- (ACCEPTOR_SETTINGS) getAcceptorSettings;

- (void) open;
- (void) reopen;
- (void) close;
- (void) setValidatedMode;
- (BOOL) canReopen;

/**/
- (BOOL) isEnabled;

/**/
- (char *) getErrorDescription: (int) aCode;
- (char *) getCurrentErrorDescription;

/**/
- (char *) getVersion;

/**/
- (char *) getRejectedDescription: (int) aCode;

/**/
- (BOOL) hasEmitStackerWarning;
- (void) setHasEmitStackerWarning: (BOOL) aValue;
- (BOOL) hasEmitStackerFull;
- (void) setHasEmitStackerFull: (BOOL) aValue;

@end

#endif
