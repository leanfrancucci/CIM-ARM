#ifndef CIM_GENERAL_SETTINGS_H
#define CIM_GENERAL_SETTINGS_H

#define CIM_GENERAL_SETTINGS id

#include <Object.h>
#include "ctapp.h"

/** */
typedef enum {
	AskEnvelopeNumberType_NEVER
 ,AskEnvelopeNumberType_MANUAL
 ,AskEnvelopeNumberType_AUTO
 ,AskEnvelopeNumberType_BOTH
} AskEnvelopeNumberType;

/** Opcion de imprimir reporte de operador */
typedef enum {
	PrintOperatorReport_UNDEFINED
 ,PrintOperatorReport_NEVER
 ,PrintOperatorReport_ALWAYS
 ,PrintOperatorReport_ASK
} PrintOperatorReport;

/** Opcion de modo de teclado */
typedef enum {
	KeyPadOperationMode_UNDEFINED
 ,KeyPadOperationMode_NUMERIC
 ,KeyPadOperationMode_ALPHANUMERIC
} KeyPadOperationMode;

/** Tipo de dispositivo de login */
typedef enum {
	LoginDevType_UNDEFINED
 ,LoginDevType_NONE
 ,LoginDevType_DALLAS_KEY
 ,LoginDevType_SWIPE_CARD_READER
} LoginDevType;

/** Tipo de bag tracking */

typedef enum {
	BagTrackingMode_NONE,
	BagTrackingMode_AUTO,
	BagTrackingMode_MANUAL, 
	BagTrackingMode_MIXED
} BagTrackingMode;


/**
 *	Configuracion general del subsistema CIM.
 */
@interface CimGeneralSettings : Object
{
	int myId;

	/** (en seg) Tiempo que se mantendra abierto el buzon para depositos manuales. */
	int myMailboxOpenTime;

	/** (en seg) Tiempo maximo de inactividad en deposito, pasado este tiempo, se muestra el cartel de advertencia */
	int myMaxInactivityTimeOnDeposit;

	/** (en seg) Tiempo durante el cual se mantiene el aviso "Necesita mas tiempo?". Pasado este tiempo se cierra el deposito */
	int myWarningTime;

	/** (en seg) Tiempo maximo de inactividad de usuario. Es el tiempo maximo que podra estar "logueado" un usuario
			sin hacer nada (presionar tecla ni depositos) hasta que se desloguea automaticamente. */
	int myMaxUserInactivityTime;

	/** (en seg) Tiempo de bloqueo a causa de realizar 3 intentos de loguin incorrectos */
	int myLockLoginTime;

	/** Numero siguiente de deposito */
	unsigned long myNextDepositNumber;

	/** Numero siguiente de extraccion */
	unsigned long myNextExtractionNumber;

	/** Numero siguiente de X */
	unsigned long myNextXNumber;

	/** Numero siguiente de Z */
	unsigned long myNextZNumber;

	/** Cantidad de copias de depositos */
	int myDepositCopiesQty;

	/** Cantidad de copias de extracciones */
	int myExtractionCopiesQty;

	/** Cantidad de copias de X */
	int myXCopiesQty;

	/** Cantidad de copias de Z */
	int myZCopiesQty;

	/** Impresion automatica de Z */
	BOOL myAutoPrint;

	/** Comienzo de dia Grand Z */
	int myStartDay;

	/** Final de dia Grand Z */
	int myEndDay;

	/** Identificador de punto de venta */
	char myPOSId[30];

	/** Informacion bancaria por defecto */	
	char myDefaultBankInfo[40];

	/** Texto de sistema en ocio */
	char myIdleText[40];

	/** Longitud pin */
	int myPinLenght;

	/** Duracion pin */
	int myPinLife;

	/** Inactivacion automatica de pin */
	int myPinAutoInactivate;

	/** Borrado automatico de pin */
	int myPinAutoDelete;

	/** Utiliza reference o no */
	BOOL myUseCashReference;

 	/** Pregunta el numero de sobre */
	AskEnvelopeNumberType myAskEnvelopeNumber;

	/** Pregunta si desea remover el dinero */
	BOOL myAskRemoveCash;

	/** Mac address del equipo*/
	char myMacAddress[100];

	/** Datos de red del equipo*/
	char myIpAddress[20];
	char myNetMask[20];
	char myGateway[20];
	char myDhcp[20];

	/** Modelo de Cim almacenado */
	int myCimModel;

	BOOL myPrintLogo;
	
 	/** Pregunta la cantidad en el deposito manual */
	BOOL myAskQtyInManualDrop;	

 	/** Pregunta "aplicar a" en el deposito manual o validado */
	BOOL myAskApplyTo;

	/** Pregunta si debe imprimir el reporte del operador */
	PrintOperatorReport myPrintOperatorReport;

	int myEnvelopeIdOpMode;
	int myApplyToOpMode;
	int myLoginOpMode;

	/** Paraemtrros de seguimiento de bolsas */
	BOOL myRemoveBagVerification;
	BOOL myBagTracking;

	/** Parametros de configuracion de codigo de barras */
	BOOL myUseBarCodeReader;
	int myBarCodeReaderComPort;

	/** Parametros de configuracion de dispositivos de login */
	LoginDevType myLoginDevType;
	int myLoginDevComPort;

	/** Parametros especificos del Swip Card Reader */
	int mySwipeCardTrack;
	int mySwipeCardOffset;
	int mySwipeCardReadQty;

  /** Indica si al abrir una puerta interna se genera la extraccion de la externa que la contiene */
	BOOL myRemoveCashOuterDoor;

  /** Indica si utiliza el fin de dia */
	BOOL myUseEndDay;

	/** Indica si solicita en las extracciones validadas el codigo de bolsa */
	BOOL myAskBagCode;

	/** Indica si el codigo de acceptador es numerico o alfanumerico */
	KeyPadOperationMode myAcceptorsCodeType;

	/** Indica si solicita confirmacion de codigo de aceptadores */
	BOOL myConfirmCode;

	/** Indica si el backup se ejecuta en forma automatica o no */
	BOOL myAutomaticBackup;

	/** Hora de lanzamiento de backup automatico */
	int myBackupTime;

	/** Marco de backup automatico */
	int myBackupFrame;

	BOOL myValidateNextNumbers;
}

/**
 *	Devuelve la unica instancia posible de esta clase.
 */
+ getInstance;

/**/
- (void) setCimGeneralSettingsId: (int) aValue;
- (int) getCimGeneralSettingsId;


/**/
- (void) setMailboxOpenTime: (int) aValue;
- (int) getMailboxOpenTime;

/**/
- (void) setMaxInactivityTimeOnDeposit: (int) aValue;
- (int) getMaxInactivityTimeOnDeposit;

/**/
- (void) setWarningTime: (int) aValue;
- (int) getWarningTime;

/**/
- (void) setMaxUserInactivityTime: (int) aValue;
- (int) getMaxUserInactivityTime;

/**/
- (void) setLockLoginTime: (int) aValue;
- (int) getLockLoginTime;

/**/
- (void) setNextDepositNumber: (unsigned long) aValue;
- (unsigned long) getNextDepositNumber;

/**/
- (void) setNextExtractionNumber: (unsigned long) aValue;
- (unsigned long) getNextExtractionNumber;

/**/
- (void) setNextXNumber: (unsigned long) aValue;
- (unsigned long) getNextXNumber;

/**/
- (void) setNextZNumber: (unsigned long) aValue;
- (unsigned long) getNextZNumber;

/**/
- (void) setDepositCopiesQty: (int) aValue;
- (int) getDepositCopiesQty;

/**/
- (void) setExtractionCopiesQty: (int) aValue;
- (int) getExtractionCopiesQty;

/**/
- (void) setXCopiesQty: (int) aValue;
- (int) getXCopiesQty;

/**/
- (void) setZCopiesQty: (int) aValue;
- (int) getZCopiesQty;

/**/
- (void) setAutoPrint: (BOOL) aValue;
- (int) getAutoPrint;

/**/
- (void) setStartDay: (int) aValue;
- (int) getStartDay;

/**/
- (void) setEndDay: (int) aValue;
- (int) getEndDay;

/**/
- (void) setPOSId: (char*) aValue;
- (char*) getPOSId;

/**/
- (char*) getMacAddress: (char*) aValue;

/**/
- (char*) getIpAddress: (char*) aValue;
- (char*) getNetMask: (char*) aValue;
- (char*) getGateway: (char*) aValue;
- (char*) getDhcp: (char*) aValue;

- (void) setIpAddress: (char*) aValue;
- (void) setNetMask: (char*) aValue;
- (void) setGateway: (char*) aValue;
- (void) setDhcp: (char*) aValue;

/**/
- (char*) loadMacAddressFromFile;

/**/
- (void) saveMacAddressToFile;

/**/
- (void) setDefaultBankInfo: (char*) aValue;
- (char*) getDefaultBankInfo;

/**/
- (void) setIdleText: (char*) aValue;
- (char*) getIdleText;

 /**/
- (void) setPinLenght: (int) aValue;
- (int) getPinLenght;

 /**/
- (void) setPinLife: (int) aValue;
- (int) getPinLife;

 /**/
- (void) setPinAutoInactivate: (int) aValue;
- (int) getPinAutoInactivate;

 /**/
- (void) setPinAutoDelete: (int) aValue;
- (int) getPinAutoDelete;

/**/
- (void) setAskEnvelopeNumber: (BOOL) aValue;
- (BOOL) getAskEnvelopeNumber;

/**/
- (void) setUseCashReference: (BOOL) aValue;
- (BOOL) getUseCashReference;

/**/
- (void) setAskRemoveCash: (BOOL) aValue;
- (BOOL) getAskRemoveCash;

/**/
- (void) setPrintLogo: (BOOL) aValue;
- (BOOL) getPrintLogo;

/**/
- (void) setAskQtyInManualDrop: (BOOL) aValue;
- (BOOL) getAskQtyInManualDrop;

/**/
- (void) setAskApplyTo: (BOOL) aValue;
- (BOOL) getAskApplyTo;

/**/
- (void) applyChanges;

/**/
- (void) setCimModel: (int) aCimModel;
- (int) getCimModel;

/**/
- (unsigned long) getLastDepositNumber;
- (unsigned long) getLastExtractionNumber;
- (unsigned long) getLastZNumber;

/**/
- (void) setPrintOperatorReport: (PrintOperatorReport) aValue;
- (PrintOperatorReport) getPrintOperatorReport;

- (void) restore;

/**/
- (void) setEnvelopeIdOpMode: (int) aValue;
- (void) setApplyToOpMode: (int) aValue;
- (void) setLoginOpMode: (int) aValue;

/**/
- (int) getEnvelopeIdOpMode;
- (int) getApplyToOpMode;
- (int) getLoginOpMode;

/**/
- (void) setRemoveBagVerification: (BOOL) aValue;
- (void) setBagTracking: (BOOL) aValue;

/**/
- (BOOL) getRemoveBagVerification;
- (BOOL) getBagTracking;

/**/
- (void) setUseBarCodeReader: (BOOL) aValue;
- (void) setBarCodeReaderComPort: (int) aValue;

/**/
- (BOOL) getUseBarCodeReader;
- (int) getBarCodeReaderComPort;

/**/
- (void) setLoginDevType: (LoginDevType) aValue;
- (void) setLoginDevComPort: (int) aValue;

/**/
- (LoginDevType) getLoginDevType;
- (int) getLoginDevComPort;

/**/
- (void) setSwipeCardTrack: (int) aValue;
- (void) setSwipeCardOffset: (int) aValue;
- (void) setSwipeCardReadQty: (int) aValue;

/**/
- (int) getSwipeCardTrack;
- (int) getSwipeCardOffset;
- (int) getSwipeCardReadQty;

/**/
- (void) setRemoveCashOuterDoor: (BOOL) aValue;
- (BOOL) removeCashOuterDoor;

/**/
- (void) setUseEndDay: (BOOL) aValue;
- (BOOL) getUseEndDay;
	
/**/
- (void) setAskBagCode: (BOOL) aValue;
- (BOOL) getAskBagCode;

/**/
- (void) setAcceptorsCodeType: (int) aValue;
- (int) getAcceptorsCodeType;

/**/
- (void) setConfirmCode: (BOOL) aValue;
- (BOOL) getConfirmCode;

/**/
- (void) setAutomaticBackup: (BOOL) aValue;
- (BOOL) isAutomaticBackup;

/**/
- (void) setBackupTime: (int) aValue;
- (int) getBackupTime;

/**/
- (void) setBackupFrame: (int) aValue;
- (int) getBackupFrame;

/**/
- (void) setValidateNextNumbers: (BOOL) aValue;
- (BOOL) getValidateNextNumbers;

@end

#endif
