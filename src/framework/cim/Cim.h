#ifndef CIM_H
#define CIM_H

#define CIM id

#include "Object.h"
#include "Door.h"
#include "AbstractAcceptor.h"
#include "AcceptorSettings.h"
#include "CimCash.h"
#include "Box.h"

/**
 * 
 */
@interface Cim :  Object
{
	COLLECTION myDoors;
	COLLECTION myCollectorDoors;
	COLLECTION myAcceptors;
	COLLECTION myAcceptorSettings;
	COLLECTION myCimCashs;
	COLLECTION myManualCimCashs;
	COLLECTION myAutoCimCashs;
	COLLECTION myNoDevicesCimChashs;
	COLLECTION myCimCashsCompleteList;
	COLLECTION myBoxes;
	char myBoxModel[50];
}


/** Devuelve el cash a partir del id pasado como parametro */
- (id) getCimCashById: (int) aCimCashId;

/** Devuelve el cash a partir del id de un acceptor pasado como parametro */
- (id) getCimCashByAcceptorId: (int) anAcceptorId;

/** Devuelve todas las puerta del sistema */
- (COLLECTION) getDoors;

/** Devuelve todas las puertas de deposito / recaudacion del sistema */
- (COLLECTION) getCollectorDoors;

/** Devuelve los cash definidos */
- (COLLECTION) getCimCashs;

/** Devuelve los cash manuales unicamente */
- (COLLECTION) getManualCimCashs;

/** Devuelve los cash automaticos unicamente */
- (COLLECTION) getAutoCimCashs;

/** Agrega el aceptador a la lista */
- (void) addAcceptor: (ABSTRACT_ACCEPTOR) aValue;

/** Devuelve la lista de aceptadores configurados */
- (COLLECTION) getAcceptors;

/**/
- (void) setAcceptorsObserver: (id) anObserver;
- (void) setDoorsObserver: (id) anObserver;

/**
 *	Comienza la ejecucion de todos los aceptadores.
 */
- (void) startAcceptors;

- (void) startDoors;

/**
 *	Devuelve la configuracion del "aceptador" para el Id de "aceptador" pasado como parametro
 */
- (ACCEPTOR_SETTINGS) getAcceptorSettingsById: (int) anId;

/**/
- (ACCEPTOR_SETTINGS) getCompleteAcceptorSettingsById: (int) anId;

/**
 *	Devuelve el "aceptador" para el Id de "aceptador" pasado como parametro
 */
- (ABSTRACT_ACCEPTOR) getAcceptorById: (int) anId;

/**
 *
 */
- (void) openCimCash: (CIM_CASH) anCimCash;
- (void) closeCimCash: (CIM_CASH) anCimCash;
- (void) reopenCimCash: (CIM_CASH) anCimCash;
- (BOOL) canReopenCimCash: (CIM_CASH) anCimCash;

/**/
- (DENOMINATION) getCurrencyDenomination: (int) aDepositValueType acceptorId: (int) anAcceptorId currencyId: (int) aCurrencyId denomination: (money_t) aDenomination;

/**/
- (COLLECTION) getCurrencyDenominations: (int) aDepositValueType acceptorId: (int) anAcceptorId currencyId: (int) aCurrencyId;

/**/
- (COLLECTION) getDepositValueTypes: (int) anAcceptorId;

/**/
- (COLLECTION) getCurrenciesByDepositValueType: (int) anAcceptorId depositValueType: (int) aDepositValueType;

/**/
- (void) addAcceptorDepositValueType: (int) anAcceptorId depositValueType: (int) aDepositValueType;

/**/
- (void) removeAcceptorDepositValueType: (int) anAcceptorId depositValueType: (int) aDepositValueType;

/**/
- (void) addDepositValueTypeCurrency: (int) anAcceptorId depositValueType: (int) aDepositValueType currencyId: (int) aCurrencyId;

/**/
- (void) removeDepositValueTypeCurrency: (int) anAcceptorId depositValueType: (int) aDepositValueType currencyId: (int) aCurrencyId;

/**/
- (void) closeBillValidators;

/**/
- (void) setBillValidatorsInValidatedMode;

/*Cashes*/
- (COLLECTION) getCashBoxesIdList;
- (int) addCashBox: (char*) aName doorId: (int) aDoorId depositType: (int) aDepositType;
- (void) removeCashBox: (int) aCashId;
- (void) addCimCash: (CIM_CASH) aCimCash;
- (void) removeCimCash: (id) aCimCash;
- (COLLECTION) getAcceptorsByCash: (int) aCashId;
- (void) addAcceptorByCash: (int) aCashId acceptorId: (int) anAcceptorId;
- (void) removeAcceptorByCash: (int) aCashId acceptorId: (int) anAcceptorId;
- (void) loadCimCashes;

/*Boxes*/
- (COLLECTION) getBoxesIdList;
- (id) getBoxById: (int) aBoxId;
- (COLLECTION) getBoxes;
- (int) addCimBox: (char*) aName model: (char*) aModel;
- (void) removeBoxById: (int) aBoxId;
- (void) addBox: (BOX) aBox;
- (void) removeBox: (id) aBox;
- (COLLECTION) getAcceptorsByBox: (int) aBoxId;
- (COLLECTION) getDoorsByBox: (int) aBoxId;
- (void) addAcceptorByBox: (int) aBoxId acceptorId: (int) anAcceptorId;
- (void) removeAcceptorByBox: (int) aBoxId acceptorId: (int) anAcceptorId;
- (void) addDoorByBox: (int) aBoxId doorId: (int) aDoorId;
- (void) removeDoorByBox: (int) aBoxId doorId: (int) aDoorId;
- (void) loadBoxes; 
- (id) getBoxWithAcceptor: (int) anAcceptorId;


/*Acceptors*/
- (COLLECTION) getAcceptorsIdList;
/*
- (int) addCimAcceptor: (int) aType name: (char*) aName brand: (int) aBrand model: (char*) aModel
										protocol: (int) aProtocol hardwareId: (int) aHardwareId stackerSize: (int) aStackerSize
										stackerWarningSize: (int) aStackerWarningSize doorId: (int) aDoorId baudRate: (int) aBaudRate
										dataBits: (int) aDataBits parity: (int) aParity stopBits: (int) aStopBits flowControl: (int) aFlowControl
										startTimeOut: (int) aStartTimeOut echoDisable: (BOOL) aEchoDisable;
*/
- (int) addCimAcceptor: (int) aType name: (char*) aName brand: (int) aBrand model: (char*) aModel
										protocol: (int) aProtocol hardwareId: (int) aHardwareId stackerSize: (int) aStackerSize
										stackerWarningSize: (int) aStackerWarningSize doorId: (int) aDoorId baudRate: (int) aBaudRate
										dataBits: (int) aDataBits parity: (int) aParity stopBits: (int) aStopBits flowControl: (int) aFlowControl;


- (void) removeCimAcceptor: (int) anAcceptorId;

/*
 * Indica si la caja es de transferencia o no
 */
- (BOOL) isTransferenceBoxMode;

/*
 * Devuelve el modelo actual de la caja
 */
- (char*) getBoxModel;

/*Doors*/
- (COLLECTION) getDoorsIdList;
- (void) addDoor: (DOOR) aValue;
- (DOOR) getDoorById: (int) aDoorId;
- (int) addCimDoor: (DOOR) aDoor;
- (void) removeCimDoor: (int) aDoorId;
- (COLLECTION) getDoorsBehind: (DOOR) aDoor;

/**/
- (void) setSerialNumberChangeListener: (id) aListener;

/**/
- (BOOL) verifyBoxModelChange;

/**/
- (BOOL) verifyBoxModelInbackup;

/**/
- (void) verifyAcceptorsSerialNumbers;

/**/
- (COLLECTION) getActiveAcceptorSettings;

/**/
- (BOOL) hasMovements;


/**/
- (int) getTotalStackerSize: (id) anAcceptor;
- (int) getTotalStackerWarningSize: (id) anAcceptor;
- (void) setHasEmitStackerFullByCash: (id) anAcceptor value: (BOOL) aValue;
- (void) setHasEmitStackerWarningByCash: (id) anAcceptor value: (BOOL) aValue;

@end

#endif




