#include "CimGeneralSettings.h"
#include "Persistence.h"
#include "util.h"
#include "DepositManager.h"
#include "ExtractionManager.h"
#include "ZCloseManager.h"
#include "MessageHandler.h"
#include "Audit.h"

#define MAC_ADDRESS_FILE_NAME			"mac.ini"

@implementation CimGeneralSettings

static char myCimGeneralSettingsSettingsMessageString[] = "Configuracion";
static CIM_GENERAL_SETTINGS singleInstance = NULL;

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}
 
/**/
- initialize
{
	myMacAddress[0] = '\0';
	myIpAddress[0] = '\0';
	myNetMask[0] = '\0';
	myGateway[0] = '\0';
	myDhcp[0] = '\0';
	myUseEndDay = TRUE;
	myAskBagCode = TRUE;
	myAcceptorsCodeType = KeyPadOperationMode_ALPHANUMERIC;
	myConfirmCode = FALSE;
	myValidateNextNumbers = TRUE;

	myPrintOperatorReport = PrintOperatorReport_NEVER;

	// Busco la mac address en el archivo local. Si no existe el archivo
	// lo busco con la funcion if_netInfo y luego lo guardo en el archivo local
	// Cada vez que se inicie el equipo se obtendra la mac con la funcion if_netInfo
	// y si la misma NO es vacia actualizo el archivo de mac. De esta forma si
	// llegaran a copiar el archivo mac.ini a otro equipo el mismo se actualizaria
	// con la mac real del equipo.
	// Si la mac esta vacia lo audito.

    //************************* logcoment
//	doLog(0,"Obteniendo MAC ADDRESS...\n");fflush(stdout);

	// 1) obtengo la mac con la funcion if_netInfo
	if_netInfo("eth0", myMacAddress);
	strrep(myMacAddress, ':', '-');

	// 2) almaceno la mac en el archivo local si NO es vacia
	if (strlen(myMacAddress) > 0)
		[self saveMacAddressToFile];

	// 3) levanto la mac del archivo local por las dudas de que la mac obtenida con
	// if_netInfo este vacia
	[self loadMacAddressFromFile];

    //************************* logcoment
//	doLog(0,"MAC ADDRESS: %s\n", myMacAddress);

	// 4) Si la mac es vacia genero una auditoria 
	if (strlen(myMacAddress) == 0)
		[Audit auditEvent: NULL eventId: Event_EMPTY_MAC additional: "" station: 0 logRemoteSystem: FALSE];


	// Obtengo ipAddress, netMask, gateway dependiendo del dhcp y luego almaceno 
	// los valores en memoria.
    //************************* logcoment
	//doLog(0,"Obteniendo CONFIGURACION DE RED...\n");fflush(stdout);

	loadIPConfig(myDhcp, myIpAddress, myNetMask, myGateway);

    //************************* logcoment
    /*
	doLog(0,"DHCP: %s\n", myDhcp);
	doLog(0,"IP ADDRESS: %s\n", myIpAddress);
	doLog(0,"NET MASK: %s\n", myNetMask);
	doLog(0,"GATEWAY: %s\n", myGateway);
    */
	return [[[Persistence getInstance] getCimGeneralSettingsDAO] loadById: 1];
}

/**/
+ getInstance
{
  return [self new];
}

/**/
- (void) setCimGeneralSettingsId: (int) aValue { myId = aValue; }
- (int) getCimGeneralSettingsId { return myId; }

/**/
- (void) setMailboxOpenTime: (int) aValue { myMailboxOpenTime = aValue; }
- (int) getMailboxOpenTime { return myMailboxOpenTime; }

/**/
- (void) setMaxInactivityTimeOnDeposit: (int) aValue { myMaxInactivityTimeOnDeposit = aValue; }
- (int) getMaxInactivityTimeOnDeposit { return myMaxInactivityTimeOnDeposit; }

/**/
- (void) setWarningTime: (int) aValue { myWarningTime = aValue; }
- (int) getWarningTime { return myWarningTime; }

/**/
- (void) setMaxUserInactivityTime: (int) aValue { myMaxUserInactivityTime = aValue; }
- (int) getMaxUserInactivityTime { return myMaxUserInactivityTime; }

/**/
- (void) setLockLoginTime: (int) aValue { myLockLoginTime = aValue; }
- (int) getLockLoginTime { return myLockLoginTime; }

/**/
- (void) setNextDepositNumber: (unsigned long) aValue { myNextDepositNumber = aValue; }
- (unsigned long) getNextDepositNumber { return myNextDepositNumber; }

/**/
- (void) setNextExtractionNumber: (unsigned long) aValue { myNextExtractionNumber = aValue; }
- (unsigned long) getNextExtractionNumber { return myNextExtractionNumber; }

/**/
- (void) setNextXNumber: (unsigned long) aValue { myNextXNumber = aValue; }
- (unsigned long) getNextXNumber { return myNextXNumber; }

/**/
- (void) setNextZNumber: (unsigned long) aValue { myNextZNumber = aValue; }
- (unsigned long) getNextZNumber { return myNextZNumber; } 
/**/
- (void) setDepositCopiesQty: (int) aValue { myDepositCopiesQty = aValue; }
- (int) getDepositCopiesQty { return myDepositCopiesQty; }

/**/
- (void) setExtractionCopiesQty: (int) aValue { myExtractionCopiesQty = aValue; }
- (int) getExtractionCopiesQty { return myExtractionCopiesQty; }

/**/
- (void) setXCopiesQty: (int) aValue { myXCopiesQty = aValue; }
- (int) getXCopiesQty { return myXCopiesQty; }

/**/
- (void) setZCopiesQty: (int) aValue { myZCopiesQty = aValue; }
- (int) getZCopiesQty { return myZCopiesQty; }

/**/
- (void) setAutoPrint: (BOOL) aValue { myAutoPrint = aValue; }
- (int) getAutoPrint { return myAutoPrint; }

/**/
- (void) setStartDay: (int) aValue { myStartDay = aValue; }
- (int) getStartDay { return myStartDay; }

/**/
- (void) setEndDay: (int) aValue { myEndDay = aValue; }
- (int) getEndDay { return myEndDay; }

/**/
- (void) setPOSId: (char*) aValue { stringcpy(myPOSId, aValue); }
- (char*) getPOSId { return myPOSId; }

/**/
- (char*) getMacAddress: (char*) aValue 
{
	strcpy(aValue, myMacAddress);
  return myMacAddress;
}

/**/
- (char*) getIpAddress: (char*) aValue
{
	strcpy(aValue, myIpAddress);
  return myIpAddress;
}

- (char*) getNetMask: (char*) aValue
{
	strcpy(aValue, myNetMask);
  return myNetMask;
}

- (char*) getGateway: (char*) aValue
{
	strcpy(aValue, myGateway);
  return myGateway;
}

- (char*) getDhcp: (char*) aValue
{
	strcpy(aValue, myDhcp);
  return myDhcp;
}

/**/
- (void) setIpAddress: (char*) aValue { stringcpy(myIpAddress, aValue); }
- (void) setNetMask: (char*) aValue { stringcpy(myNetMask, aValue); }
- (void) setGateway: (char*) aValue { stringcpy(myGateway, aValue); }
- (void) setDhcp: (char*) aValue { stringcpy(myDhcp, aValue); }

/**/
- (char*) loadMacAddressFromFile
{
	FILE *f;
	char fileName[200];
	char buffer[500];

	strcpy(fileName, MAC_ADDRESS_FILE_NAME);
	f = fopen(fileName, "r");

	if (f) {
		
		if (!feof(f)) {
			fgets(buffer, 500, f);
			strcpy(myMacAddress, buffer);
		}

		fclose(f);
	}

	return myMacAddress;
}

/**/
- (void) saveMacAddressToFile
{
	char fileName[200];
	FILE *f;

	if (strlen(myMacAddress) != 0) {
		strcpy(fileName, MAC_ADDRESS_FILE_NAME);
	
		//doLog(0,"-----> CREO EL ARCHIVO %s <-----\n", fileName);
	
		f = fopen(fileName, "w+");
		fprintf(f, "%s", myMacAddress);
	
		fclose(f);
	}
}

/**/
- (void) setDefaultBankInfo: (char*) aValue { stringcpy(myDefaultBankInfo, aValue); }
- (char*) getDefaultBankInfo { return myDefaultBankInfo; }

/**/
- (void) setIdleText: (char*) aValue { stringcpy(myIdleText, aValue); }
- (char*) getIdleText { return myIdleText; }

 /**/
- (void) setPinLenght: (int) aValue { myPinLenght = aValue; }
- (int) getPinLenght { return myPinLenght; }

 /**/
- (void) setPinLife: (int) aValue { myPinLife = aValue; }
- (int) getPinLife { return myPinLife; }

 /**/
- (void) setPinAutoInactivate: (BOOL) aValue { myPinAutoInactivate = aValue; }
- (BOOL) getPinAutoInactivate { return myPinAutoInactivate; }

 /**/
- (void) setPinAutoDelete: (BOOL) aValue { myPinAutoDelete = aValue; }
- (BOOL) getPinAutoDelete { return myPinAutoDelete; }

/**/
- (void) setUseCashReference: (BOOL) aValue { myUseCashReference = aValue; }
- (BOOL) getUseCashReference { return myUseCashReference; }

/**/
- (void) setAskEnvelopeNumber: (int) aValue { myAskEnvelopeNumber = aValue; }
- (int) getAskEnvelopeNumber { return myAskEnvelopeNumber; }

/**/
- (void) setAskRemoveCash: (BOOL) aValue { myAskRemoveCash = aValue; }
- (BOOL) getAskRemoveCash { return myAskRemoveCash; }

/**/
- (void) setPrintLogo: (BOOL) aValue { myPrintLogo = aValue; }
- (BOOL) getPrintLogo { return myPrintLogo; }

/**/
- (void) setAskQtyInManualDrop: (BOOL) aValue { myAskQtyInManualDrop = aValue; }
- (BOOL) getAskQtyInManualDrop { return myAskQtyInManualDrop; }

/**/
- (void) setAskApplyTo: (BOOL) aValue { myAskApplyTo = aValue; }
- (BOOL) getAskApplyTo { return myAskApplyTo; }


/**/
- (void) applyChanges
{
	id dao = [[Persistence getInstance] getCimGeneralSettingsDAO];		

	[dao store: self];
 }

/**/
- (void) restore
{
	[self initialize];
}

/**/
- (void) setCimModel: (int) aCimModel { myCimModel = aCimModel; }
- (int) getCimModel { return myCimModel; }


/**/
- (unsigned long) getLastDepositNumber
{
	return [[DepositManager getInstance] getLastDepositNumber];
}

/**/
- (unsigned long) getLastExtractionNumber
{
	return [[ExtractionManager getInstance] getLastExtractionNumber];
}

- (unsigned long) getLastZNumber
{
	return [[ZCloseManager getInstance] getLastZNumber];
}

/**/
- (void) setPrintOperatorReport: (PrintOperatorReport) aValue { myPrintOperatorReport = aValue; }
- (PrintOperatorReport) getPrintOperatorReport { return myPrintOperatorReport; }

/**/
- (STR) str
{
  return getResourceStringDef(RESID_SAVE_CONFIGURATION_QUESTION, myCimGeneralSettingsSettingsMessageString);
}

/**/
- (void) setEnvelopeIdOpMode: (int) aValue { myEnvelopeIdOpMode = aValue; }
- (void) setApplyToOpMode: (int) aValue { myApplyToOpMode = aValue; }
- (void) setLoginOpMode: (int) aValue { myLoginOpMode = aValue; }

/**/
- (int) getEnvelopeIdOpMode { return myEnvelopeIdOpMode; }
- (int) getApplyToOpMode { return myApplyToOpMode; }
- (int) getLoginOpMode { return myLoginOpMode; }

/**/
- (void) setRemoveBagVerification: (BOOL) aValue { myRemoveBagVerification = aValue; }
- (void) setBagTracking: (BOOL) aValue { myBagTracking = aValue; }

/**/
- (BOOL) getRemoveBagVerification { return myRemoveBagVerification; }
- (BOOL) getBagTracking { return myBagTracking; }

/**/
- (void) setUseBarCodeReader: (BOOL) aValue { myUseBarCodeReader = aValue; }
- (void) setBarCodeReaderComPort: (int) aValue { myBarCodeReaderComPort = aValue; }

/**/
- (BOOL) getUseBarCodeReader { return myUseBarCodeReader; }
- (int) getBarCodeReaderComPort { return myBarCodeReaderComPort; }

/**/
- (void) setLoginDevType: (LoginDevType) aValue { myLoginDevType = aValue; }
- (void) setLoginDevComPort: (int) aValue { myLoginDevComPort = aValue; }

/**/
- (LoginDevType) getLoginDevType { return myLoginDevType; }
- (int) getLoginDevComPort { return myLoginDevComPort; }

/**/
- (void) setSwipeCardTrack: (int) aValue { mySwipeCardTrack = aValue; }
- (void) setSwipeCardOffset: (int) aValue { mySwipeCardOffset = aValue; }
- (void) setSwipeCardReadQty: (int) aValue { mySwipeCardReadQty = aValue; }

/**/
- (int) getSwipeCardTrack { return mySwipeCardTrack; }
- (int) getSwipeCardOffset { return mySwipeCardOffset; }
- (int) getSwipeCardReadQty { return mySwipeCardReadQty; }

/**/
- (void) setRemoveCashOuterDoor: (BOOL) aValue { myRemoveCashOuterDoor = aValue; }
- (BOOL) removeCashOuterDoor { return myRemoveCashOuterDoor; }

/**/
- (void) setUseEndDay: (BOOL) aValue { myUseEndDay = aValue; }
- (BOOL) getUseEndDay { return myUseEndDay; }

/**/
- (void) setAskBagCode: (BOOL) aValue { myAskBagCode = aValue; }
- (BOOL) getAskBagCode { return myAskBagCode; }

/**/
- (void) setAcceptorsCodeType: (int) aValue { myAcceptorsCodeType = aValue; }
- (int) getAcceptorsCodeType { return myAcceptorsCodeType; }

/**/
- (void) setConfirmCode: (BOOL) aValue { myConfirmCode = aValue; }
- (BOOL) getConfirmCode { return myConfirmCode; }

/**/
- (void) setAutomaticBackup: (BOOL) aValue { myAutomaticBackup = aValue; }
- (BOOL) isAutomaticBackup { return myAutomaticBackup; }

/**/
- (void) setBackupTime: (int) aValue { myBackupTime = aValue; }
- (int) getBackupTime { return myBackupTime; }

/**/
- (void) setBackupFrame: (int) aValue { myBackupFrame = aValue; }
- (int) getBackupFrame { return myBackupFrame; }

/**/
- (void) setValidateNextNumbers: (BOOL) aValue { myValidateNextNumbers = aValue; }
- (BOOL) getValidateNextNumbers { return myValidateNextNumbers; }

@end
