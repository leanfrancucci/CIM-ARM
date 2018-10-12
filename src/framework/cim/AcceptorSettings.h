#ifndef ACCEPTOR_SETTINGS_H
#define ACCEPTOR_SETTINGS_H

#define ACCEPTOR_SETTINGS id

/**
 *	Especifica el tipo de PROTOCOLO del "aceptador".
 */
/**/
typedef enum {
	 ProtocolType_UNDEFINED
	,ProtocolType_ID0003
	,ProtocolType_CCNET
	,ProtocolType_CCTALK
	,ProtocolType_MAXVEND
	,ProtocolType_EBDS
	,ProtocolType_FUJITSU
  ,ProtocolType_CDM3000
  ,ProtocolType_RDM100
} ProtocolType;

#include <Object.h>
#include "system/util/all.h"
#include "CimDefs.h"
#include "AcceptedDepositValue.h"
#include "Door.h"

/**
 *	Configuracion del dispositivo "aceptador" ya sea validador o buzon.
 *	Contiene la configuracion del dispositivo, los tipos de valores que acepta,
 *	etc.
 */
@interface AcceptorSettings : Object
{
/** Puerto COM al cual pertence el validador, no deberia quedar en la version final */
	int myComPortNumber;

/** Id de dispositivo aceptador */
	int myAcceptorId;

/** Tipo de dispositivo aceptador */
	AcceptorType myAcceptorType;

/** Nombre del aceptador*/	
	char myAcceptorName[40+1];

/** Marca del aceptador (Jcm/CashCode) */
	BrandType myBrand;

/** Modelo del validador*/
	char myModel[50+1];

/** Protocolo a manejar por el validador */
	int myProtocol;

/** Numero de serie del validador */
	char mySerialNumber[60 + 1];	

/** Identificador del hardware */
	int myHardwareId;

/** Cantidad de billetes o sobres que entran en el validador o buzon */
	int myStackerSize;

/** Cantidad de billetes o sobres que entran en el validador o buzon antes de comenzar a emitir un warning.
		Ejemplo: si el StacketSize = 2000 y el StackerFullWarning = 1800, entonces cuando llega a 1800 comienza
		a emitir una alarma. */
	int myStackerWarningSize;

/** Puerta a la cual pertence el validador */
	DOOR myDoor;

/** Bits por segundo */
	int myBaudRate;

/** Bits de datos */
	int myDataBits;

/** Paridad */
	int myParity;

/** Bits de parada*/
	int myStopBits;

/** Control de flujo */
	int myFlowControl;

/** Si esta borrado */
	BOOL myDeleted;

/***/
	int myStartTimeOut;

/***/
	BOOL myEchoDisable;

/** Coleccion de valores aceptados por el dispositivo */
	COLLECTION myAcceptedDepositValues;

	id mySerialNumberChangeListener;

	BOOL myIsDisabled;

	/** ESTO ES RECONTRA CABLE PARA ADAPTAR AL CMP DONDE SE HACE A MANO LA ASIGNACION Y DESASIGNACION DE UN ACCEPTOR BY BOX */
	BOOL hasToActivateAcceptorByBox;
	BOOL hasToInactivateAcceptorByBox;

}

/**/
- (CURRENCY) getDefaultCurrency;

/**/
- (void) setComPortNumber: (int) aNumber;
- (int) getComPortNumber;

/**/
- (void) setAcceptorId: (int) aValue;
- (int) getAcceptorId;

/**/
- (void) setAcceptorType: (AcceptorType) aValue;
- (AcceptorType) getAcceptorType;

/**/
- (void) setAcceptorName: (char*) aValue;
- (char*) getAcceptorName;

/**/
- (void) setAcceptorBrand: (BrandType) aValue;
- (BrandType) getAcceptorBrand;

/**/
- (void) setAcceptorModel: (char*) aValue;
- (char*) getAcceptorModel;

/**/
- (void) setAcceptorProtocol: (int) aValue;
- (int) getAcceptorProtocol;

/**/
- (void) setAcceptorSerialNumber: (char*) aValue;
- (char*) getAcceptorSerialNumber;

/**/
- (void) setAcceptorHardwareId: (int) aValue;
- (int) getAcceptorHardwareId;

/**/
- (void) setStackerSize: (int) aValue;
- (int) getStackerSize;

/**/
- (void) setStackerWarningSize: (int) aValue;
- (int) getStackerWarningSize;

/**/
- (void) setDoor: (DOOR) aValue;
- (DOOR) getDoor;

/**/
- (void) setAcceptorBaudRate: (int) aValue;
- (int) getAcceptorBaudRate;

/**/
- (void) setAcceptorDataBits: (int) aValue;
- (int) getAcceptorDataBits;

/**/
- (void) setAcceptorParity: (int) aValue;
- (int) getAcceptorParity;

/**/
- (void) setAcceptorStopBits: (int) aValue;
- (int) getAcceptorStopBits;

/**/
- (void) setAcceptorFlowControl: (int) aValue;
- (int) getAcceptorFlowControl;


/**/
- (void) addAcceptedDepositValue: (ACCEPTED_DEPOSIT_VALUE) aValue;
- (COLLECTION) getAcceptedDepositValues;
- (ACCEPTED_DEPOSIT_VALUE) getAcceptedDepositValueByType: (int) aType;
- (void) removeAcceptedDepositValue: (int) aValue;

/**/
- (void) setDeleted: (BOOL) aValue;
- (BOOL) isDeleted;

- (void) setStartTimeOut: (int) aValue;
- (int) getStartTimeOut;

//- (void) setEchoDisable: (BOOL) aValue;
- (BOOL) isEchoDisable;


/**/
- (void) applyChanges;

/**/
- (void) storeDenomination: (int) aDepositValueType acceptorId: (int) anAccpetorId currencyId: (int) aCurrencyId denomination: (DENOMINATION) aDenomination;

/**/
- (void) addDepositValueType: (int) aDepositValueType;
- (void) removeDepositValueType: (int) aDepositValueType;

/**
 * Verifica si hay diferencias en los numeros de serie almacenados con los del hw.
 */
- (void) verifySerialNumberChange;
- (void) setSerialNumberChangeListener: (id) aListener;

/**/
- (void) setDisabled: (BOOL) aValue;
- (BOOL) isDisabled;

#ifdef __DEBUG_CIM
- (void) debug;
#endif

@end

#endif
