#include "GenericSetRequest.h"
#include "cl_genericpkg.h"
#include "CommercialStateFacade.h"
#include "BillSettings.h"
#include "CimGeneralSettings.h"
#include "TelesupFacade.h"
#include "AmountSettings.h"
#include "SystemTime.h"
#include "TelesupervisionManager.h"
#include "Audit.h"
#include "User.h"
#include "CimManager.h"
#include "Cim.h"
#include "Event.h"
#include "CashReferenceManager.h"
#include "UserManager.h"
#include "Acceptor.h"
#include "RepairOrderManager.h"
#include "DepositManager.h"
#include "ZCloseManager.h"
#include "RegionalSettings.h"
#include "PrintingSettings.h"

/* macro para debugging */
//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation GenericSetRequest

static GENERICSETREQUEST mySingleInstance = nil;
static GENERICSETREQUEST myRestoreSingleInstance = nil;

static void convertTime(datetime_t *dt, struct tm *bt)
{
#ifdef __UCLINUX
	localtime_r(dt, bt);
#else
	gmtime_r(dt, bt);
#endif
}

/**/
+ getSingleVarInstance
{
	 return mySingleInstance; 
}

/**/
+ (void) setSingleVarInstance: (id) aSingleVarInstance
{
	 mySingleInstance =  aSingleVarInstance;
}

/**/
+ getRestoreVarInstance 
{
	 return myRestoreSingleInstance; 
}

/**/
+ (void) setRestoreVarInstance: (id) aRestoreVarInstance
{
	 myRestoreSingleInstance = aRestoreVarInstance; 
}

/**/
- initialize
{
  myPackage = [GenericPackage new];
	[super initialize];
	return self;
}

/**/
- free
{
	[myPackage free];
	return [super free];
}

/**/
- (void) setTelesupRol: (int) aTelesupRol
{
	myTelesupRol = aTelesupRol;
}

/**
 * PROCESOS GENERALES DE PROCESAMIENTO DE CADA MENSAJE
 **/
/*ESTADO COMERCIAL*/
/**/
-(void) initSetCommercialState
{
  printd("GenericSetRequest->initSetCommercialState\n");
  
  strcpy(mySettingFnc,"setCommercialState"); 
}

/**/
- (void) setCommercialState
{
  COMMERCIAL_STATE_FACADE facade = [CommercialStateFacade getInstance];
  
  printd("GenericSetRequest->setCommercialState\n");
  
  if ([myPackage isValidParam:"State"]) 
    [facade setParamAsInteger:  "State" value: [myPackage getParamAsInteger:"State"]]; 
                  
  [facade applyChanges];
}


/*SETEOS REGIONALES*/
/**/
- (void) initSetRegionalSettings
{
  printd("GenericSetRequest->initSetRegionalSettings\n");
  
  strcpy(mySettingFnc,"setRegionalSettings"); 
}

- (void) setRegionalSettings
{
  id settings = [RegionalSettings getInstance];
  
  printd("GenericSetRequest->setRegionalSettings\n");
  
	if ([myPackage isValidParam: "MoneySymbol"])
		[settings setMoneySymbol: [myPackage getParamAsString:"MoneySymbol"]];
	 
	if ([myPackage isValidParam: "Language"])
		[settings setLanguage: [myPackage getParamAsInteger:"Language"]];

	if ([myPackage isValidParam: "TimeZone"])
		[settings setTimeZoneAsString: [myPackage getParamAsString:"TimeZone"]];

	if ([myPackage isValidParam: "DSTEnable"])
		[settings setDSTEnable: [myPackage getParamAsBoolean:"DSTEnable"]];

	if ([myPackage isValidParam: "InitialMonth"])
		[settings setInitialMonth: [myPackage getParamAsInteger:"InitialMonth"]];

	if ([myPackage isValidParam: "InitialWeek"])
		[settings setInitialWeek: [myPackage getParamAsInteger:"InitialWeek"]];

	if ([myPackage isValidParam: "InitialDay"])
		[settings setInitialDay: [myPackage getParamAsInteger:"InitialDay"]];

	if ([myPackage isValidParam: "InitialHour"])
		[settings setInitialHour: [myPackage getParamAsInteger:"InitialHour"]];

	if ([myPackage isValidParam: "FinalMonth"])
		[settings setFinalMonth: [myPackage getParamAsInteger:"FinalMonth"]];

	if ([myPackage isValidParam: "FinalWeek"])
		[settings setFinalWeek: [myPackage getParamAsInteger:"FinalWeek"]];

	if ([myPackage isValidParam: "FinalDay"])
		[settings setFinalDay: [myPackage getParamAsInteger:"FinalDay"]];

	if ([myPackage isValidParam: "FinalHour"])
		[settings setFinalHour: [myPackage getParamAsInteger:"FinalHour"]];

	if ([myPackage isValidParam: "BlockDateTimeChange"])
		[settings setBlockDateTimeChange: [myPackage getParamAsBoolean:"BlockDateTimeChange"]];

	if ([myPackage isValidParam: "DateFormat"])
		[settings setDateFormat: [myPackage getParamAsInteger:"DateFormat"]];

	TRY 

		[settings applyChanges];

	CATCH

		[settings restore];
		RETHROW();

	END_TRY
}


/*SETEOS GENERALES DE FACTURACION*/
/**/
- (void) initSetGeneralBill
{
  printd("GenericSetRequest->initSetGeneralBill\n");
  
  strcpy(mySettingFnc,"setGeneralBill"); 
}

/**/
- (void) setGeneralBill
{
  id billSettings = [BillSettings getInstance];
  
  printd("GenericSetRequest->setGeneralBill\n");

	if ([myPackage isValidParam: "NumeratorType"]) 		
	  [billSettings setNumeratorType: [myPackage getParamAsInteger: "NumeratorType"]];
 
	if ([myPackage isValidParam: "TicketType"]) 			
		[billSettings setTicketType: [myPackage getParamAsInteger: "TicketType"]];	

	if ([myPackage isValidParam: "MaxItemsQty"]) 			
		[billSettings setTicketMaxItemsQty: [myPackage getParamAsInteger: "MaxItemsQty"]];	

	if ([myPackage isValidParam: "TicketReprint"]) 		
		[billSettings setTicketReprint: [myPackage getParamAsBoolean: "TicketReprint"]];	

	if ([myPackage isValidParam: "ViewRoundFactor"]) 		
		[billSettings setViewRoundFactor: [myPackage getParamAsBoolean: "ViewRoundFactor"]];	

	if ([myPackage isValidParam: "ViewRoundAdjust"]) 		
		[billSettings setViewRoundAdjust: [myPackage getParamAsBoolean: "ViewRoundAdjust"]];	

	if ([myPackage isValidParam: "TaxDiscrimination"]) 	
		[billSettings setTaxDiscrimination: [myPackage getParamAsBoolean: "TaxDiscrimination"]];	

	if ([myPackage isValidParam: "MinAmount"]) 			
		[billSettings setMinAmount: [myPackage getParamAsCurrency: "MinAmount"]];	

	if ([myPackage isValidParam: "Transport"]) 			
		[billSettings setTransport: [myPackage getParamAsBoolean: "Transport"]];	

	if ([myPackage isValidParam: "DigitsQty"]) 			
		[billSettings setDigitsQty: [myPackage getParamAsInteger: "DigitsQty"]];	

	if ([myPackage isValidParam: "TicketQtyViewWarning"]) 
		[billSettings setTicketQtyViewWarning: [myPackage getParamAsInteger: "TicketQtyViewWarning"]];	

	if ([myPackage isValidParam: "DateChange"]) 			
		[billSettings setDateChange: [myPackage getParamAsDateTime: "DateChange"]];	

	if ([myPackage isValidParam: "Prefix"]) 				
		[billSettings setPrefix: [myPackage getParamAsString: "Prefix"]];	

	if ([myPackage isValidParam: "InitialNumber"]) 		
		[billSettings setInitialNumber: [myPackage getParamAsInteger: "InitialNumber"]];	

	if ([myPackage isValidParam: "FinalNumber"]) 			
		[billSettings setFinalNumber: [myPackage getParamAsInteger: "FinalNumber"]];	

	if ([myPackage isValidParam: "Header1"])
		[billSettings setHeader1: [myPackage getParamAsString: "Header1"]];

	if ([myPackage isValidParam: "Header2"])
		[billSettings setHeader2: [myPackage getParamAsString: "Header2"]];

	if ([myPackage isValidParam: "Header3"])
		[billSettings setHeader3: [myPackage getParamAsString: "Header3"]];

	if ([myPackage isValidParam: "Header4"])
		[billSettings setHeader4: [myPackage getParamAsString: "Header4"]];

	if ([myPackage isValidParam: "Header5"])
		[billSettings setHeader5: [myPackage getParamAsString: "Header5"]];

  if ([myPackage isValidParam: "Header6"])
		[billSettings setHeader6: [myPackage getParamAsString: "Header6"]];

	if ([myPackage isValidParam: "Footer1"])
		[billSettings setFooter1: [myPackage getParamAsString: "Footer1"]];

	if ([myPackage isValidParam: "Footer2"])
		[billSettings setFooter2: [myPackage getParamAsString: "Footer2"]];

	if ([myPackage isValidParam: "Footer3"])
		[billSettings setFooter3: [myPackage getParamAsString: "Footer3"]];

	if ([myPackage isValidParam: "OpenCashDrawer"])
		[billSettings setOpenCashDrawer: [myPackage getParamAsBoolean: "OpenCashDrawer"]];
		
	if ([myPackage isValidParam: "RequestCustomerInfo"]) 
		[billSettings setRequestCustomerInfo: [myPackage getParamAsBoolean: "RequestCustomerInfo"]];
   
	if ([myPackage isValidParam: "IdentifierDescription"])
		[billSettings setIdentifierDescription: [myPackage getParamAsString: "IdentifierDescription"]];

	TRY

		[billSettings applyChanges];

	CATCH

		[billSettings restore];
		RETHROW();

	END_TRY
}

/*SETEOS CIM*/
/**/
- (void) initSetCimGeneralSettings
{
  printd("GenericSetRequest->initSetCimGeneralSettings\n");
  
  strcpy(mySettingFnc,"setCimGeneralSettings"); 
}

/**/
- (void) setCimGeneralSettings
{
	unsigned long nextDepositNumber;
	unsigned long nextExtractionNumber;
	unsigned long nextZNumber;
  CIM_GENERAL_SETTINGS settings = [CimGeneralSettings getInstance];
  
  printd("GenericSetRequest->setCimGeneralSettings\n");

	// obtengo los valores de los proximos numeros actuales
	if ([settings getNextDepositNumber] > [[DepositManager getInstance] getLastDepositNumber])
		nextDepositNumber = [settings getNextDepositNumber];
	else
		nextDepositNumber = [[DepositManager getInstance] getLastDepositNumber] + 1;

	if ([settings getNextExtractionNumber] > [[ExtractionManager getInstance] getLastExtractionNumber])
		nextExtractionNumber = [settings getNextExtractionNumber];
	else
		nextExtractionNumber = [[ExtractionManager getInstance] getLastExtractionNumber] + 1;

	if ([settings getNextZNumber] > [[ZCloseManager getInstance] getLastZNumber])
		nextZNumber = [settings getNextZNumber];
	else
		nextZNumber = [[ZCloseManager getInstance] getLastZNumber] + 1;

	// seteo los valores
	if ([myPackage isValidParam: "NextDepositNumber"]) {
		if (nextDepositNumber < [myPackage getParamAsInteger: "NextDepositNumber"])
	  	[settings setNextDepositNumber: [myPackage getParamAsInteger: "NextDepositNumber"]];
	}

	if ([myPackage isValidParam: "NextExtractionNumber"]) {
		if (nextExtractionNumber < [myPackage getParamAsInteger: "NextExtractionNumber"])
	  	[settings setNextExtractionNumber: [myPackage getParamAsInteger: "NextExtractionNumber"]];
	}

	if ([myPackage isValidParam: "NextZNumber"]) {
		if (nextZNumber < [myPackage getParamAsInteger: "NextZNumber"])
	 	  [settings setNextZNumber: [myPackage getParamAsInteger: "NextZNumber"]];
	}

	if ([myPackage isValidParam: "NextXNumber"])
	  [settings setNextXNumber: [myPackage getParamAsInteger: "NextXNumber"]];

	if ([myPackage isValidParam: "DepositCopiesQty"])
	  [settings setDepositCopiesQty: [myPackage getParamAsInteger: "DepositCopiesQty"]];

	if ([myPackage isValidParam: "ExtractionCopiesQty"])
	  [settings setExtractionCopiesQty: [myPackage getParamAsInteger: "ExtractionCopiesQty"]];

	if ([myPackage isValidParam: "XCopiesQty"])
	  [settings setXCopiesQty: [myPackage getParamAsInteger: "XCopiesQty"]];

	if ([myPackage isValidParam: "ZCopiesQty"])
	  [settings setZCopiesQty: [myPackage getParamAsInteger: "ZCopiesQty"]];

	if ([myPackage isValidParam: "AutoPrint"])
	  [settings setAutoPrint: [myPackage getParamAsBoolean: "AutoPrint"]];
 
	if ([myPackage isValidParam: "MailBoxOpenTime"])
	  [settings setMailboxOpenTime: [myPackage getParamAsInteger: "MailBoxOpenTime"]];

	if ([myPackage isValidParam: "MaxInactivityTimeOnDeposit"])
	  [settings setMaxInactivityTimeOnDeposit: [myPackage getParamAsInteger: "MaxInactivityTimeOnDeposit"]];

	if ([myPackage isValidParam: "WarningTime"])
	  [settings setWarningTime: [myPackage getParamAsInteger: "WarningTime"]];

	if ([myPackage isValidParam: "MaxUserInactivityTime"])
	  [settings setMaxUserInactivityTime: [myPackage getParamAsInteger: "MaxUserInactivityTime"]];

	if ([myPackage isValidParam: "LockLoginTime"])
	  [settings setLockLoginTime: [myPackage getParamAsInteger: "LockLoginTime"]];

	if ([myPackage isValidParam: "StartDay"])
	  [settings setStartDay: [myPackage getParamAsInteger: "StartDay"]];

	if ([myPackage isValidParam: "EndDay"])
	  [settings setEndDay: [myPackage getParamAsInteger: "EndDay"]];

	if ([myPackage isValidParam: "POSId"])
	  [settings setPOSId: [myPackage getParamAsString: "POSId"]];

	if ([myPackage isValidParam: "DefaultBankInfo"])
	  [settings setDefaultBankInfo: [myPackage getParamAsString: "DefaultBankInfo"]];

	if ([myPackage isValidParam: "IdleText"])
	  [settings setIdleText: [myPackage getParamAsString: "IdleText"]];

	if ([myPackage isValidParam: "PinLenght"])
	  [settings setPinLenght: [myPackage getParamAsInteger: "PinLenght"]];
	
	if ([myPackage isValidParam: "PinLife"])
	  [settings setPinLife: [myPackage getParamAsInteger: "PinLife"]];

	if ([myPackage isValidParam: "PinAutoInactivate"])
	  [settings setPinAutoInactivate: [myPackage getParamAsBoolean: "PinAutoInactivate"]];

	if ([myPackage isValidParam: "PinAutoDelete"])
	  [settings setPinAutoDelete: [myPackage getParamAsBoolean: "PinAutoDelete"]];

	if ([myPackage isValidParam: "AskEnvelopeNumber"])
	  [settings setAskEnvelopeNumber: [myPackage getParamAsInteger: "AskEnvelopeNumber"]];

	if ([myPackage isValidParam: "UseCashReference"])
	  [settings setUseCashReference: [myPackage getParamAsBoolean: "UseCashReference"]];

	if ([myPackage isValidParam: "AskRemoveCash"])
	  [settings setAskRemoveCash: [myPackage getParamAsBoolean: "AskRemoveCash"]];

	if ([myPackage isValidParam: "PrintLogo"])
	  [settings setPrintLogo: [myPackage getParamAsBoolean: "PrintLogo"]];

	if ([myPackage isValidParam: "AskQtyInManualDrop"])
	  [settings setAskQtyInManualDrop: [myPackage getParamAsBoolean: "AskQtyInManualDrop"]];

	if ([myPackage isValidParam: "AskApplyTo"])
	  [settings setAskApplyTo: [myPackage getParamAsBoolean: "AskApplyTo"]];

	if ([myPackage isValidParam: "PrintOperatorReport"])
	  [settings setPrintOperatorReport: [myPackage getParamAsInteger: "PrintOperatorReport"]];

	if ([myPackage isValidParam: "EnvelopeIdOpMode"])
	  [settings setEnvelopeIdOpMode: [myPackage getParamAsInteger: "EnvelopeIdOpMode"]];

	if ([myPackage isValidParam: "ApplyToOpMode"])
	  [settings setApplyToOpMode: [myPackage getParamAsInteger: "ApplyToOpMode"]];

	if ([myPackage isValidParam: "LoginOpMode"])
	  [settings setLoginOpMode: [myPackage getParamAsInteger: "LoginOpMode"]];

	if ([myPackage isValidParam: "UseBarCodeReader"])
	  [settings setUseBarCodeReader: [myPackage getParamAsBoolean: "UseBarCodeReader"]];

	if ([myPackage isValidParam: "RemoveBagVerification"])
	  [settings setRemoveBagVerification: [myPackage getParamAsBoolean: "RemoveBagVerification"]];

	if ([myPackage isValidParam: "BagTracking"])
	  [settings setBagTracking: [myPackage getParamAsBoolean: "BagTracking"]];

	if ([myPackage isValidParam: "BarCodeReaderComPort"])
	  [settings setBarCodeReaderComPort: [myPackage getParamAsInteger: "BarCodeReaderComPort"]];

	if ([myPackage isValidParam: "LoginDevType"])
	  [settings setLoginDevType: [myPackage getParamAsInteger: "LoginDevType"]];

	if ([myPackage isValidParam: "LoginDevComPort"])
	  [settings setLoginDevComPort: [myPackage getParamAsInteger: "LoginDevComPort"]];

	if ([myPackage isValidParam: "SwipeCardTrack"])
	  [settings setSwipeCardTrack: [myPackage getParamAsInteger: "SwipeCardTrack"]];

	if ([myPackage isValidParam: "SwipeCardOffset"])
	  [settings setSwipeCardOffset: [myPackage getParamAsInteger: "SwipeCardOffset"]];

	if ([myPackage isValidParam: "SwipeCardReadQty"])
	  [settings setSwipeCardReadQty: [myPackage getParamAsInteger: "SwipeCardReadQty"]];

	if ([myPackage isValidParam: "RemoveCashOuterDoor"])
	  [settings setRemoveCashOuterDoor: [myPackage getParamAsBoolean: "RemoveCashOuterDoor"]];

	if ([myPackage isValidParam: "UseEndDay"])
	  [settings setUseEndDay: [myPackage getParamAsBoolean: "UseEndDay"]];

	if ([myPackage isValidParam: "AskBagCode"])
	  [settings setAskBagCode: [myPackage getParamAsBoolean: "AskBagCode"]];

	if ([myPackage isValidParam: "AcceptorsCodeType"])
	  [settings setAcceptorsCodeType: [myPackage getParamAsInteger: "AcceptorsCodeType"]];

	if ([myPackage isValidParam: "ConfirmCode"])
	  [settings setConfirmCode : [myPackage getParamAsBoolean: "ConfirmCode"]];

	if ([myPackage isValidParam: "AutomaticBackup"])
	  [settings setAutomaticBackup : [myPackage getParamAsBoolean: "AutomaticBackup"]];

	if ([myPackage isValidParam: "BackupTime"])
	  [settings setBackupTime: [myPackage getParamAsInteger: "BackupTime"]];

	if ([myPackage isValidParam: "BackupFrame"])
	  [settings setBackupFrame: [myPackage getParamAsInteger: "BackupFrame"]];

	[settings applyChanges];
}

/* SETEOS PUERTAS */
/**/
- (void) addDoor
{
	id timeLocks;
	int i;
	char fieldName[20];
	DOOR door = [Door new];

  printd("GenericSetRequest->addDoor\n");

  if ([myPackage isValidParam: "DoorType"])
   [door setDoorType: [myPackage getParamAsInteger: "DoorType"]];	
  
  if ([myPackage isValidParam: "KeyCount"])
   [door setKeyCount: [myPackage getParamAsInteger: "KeyCount"]];	

  if ([myPackage isValidParam: "HasElectronicLock"])
   [door setHasElectronicLock: [myPackage getParamAsBoolean: "HasElectronicLock"]];	

  if ([myPackage isValidParam: "HasSensor"])
   [door setHasSensor: [myPackage getParamAsBoolean: "HasSensor"]];	

  if ([myPackage isValidParam: "AutomaticLockTime"])
   [door setAutomaticLockTime: [myPackage getParamAsInteger: "AutomaticLockTime"]];	

  if ([myPackage isValidParam: "DelayOpenTime"])
   [door setDelayOpenTime: [myPackage getParamAsInteger: "DelayOpenTime"]];	

  if ([myPackage isValidParam: "AccessTime"])
   [door setAccessTime: [myPackage getParamAsInteger: "AccessTime"]];	

  if ([myPackage isValidParam: "MaxOpenTime"])
   [door setMaxOpenTime: [myPackage getParamAsInteger: "MaxOpenTime"]];	

  if ([myPackage isValidParam: "FireAlarmTime"])
   [door setFireAlarmTime: [myPackage getParamAsInteger: "FireAlarmTime"]];	

  if ([myPackage isValidParam: "Name"])
   [door setDoorName: [myPackage getParamAsString: "Name"]];	

  if ([myPackage isValidParam: "BehindDoorId"]) {
    [door setBehindDoorId: [myPackage getParamAsInteger: "BehindDoorId"]];

		// actualizo el objeto en memoria para el manejo de puertas internas y externas
		if ([door getBehindDoorId] > 0)
			[door setOuterDoor: [[[CimManager getInstance] getCim] getDoorById: [door getBehindDoorId]]];
		else
			[door setOuterDoor: NULL];
	}

  if ([myPackage isValidParam: "FireTime"])
   [door setFireTime: [myPackage getParamAsInteger: "FireTime"]];

	i = 0;

	timeLocks = [door getTimeLocks];

	while (i<[timeLocks size]) {

		//Franja 1
		sprintf(fieldName, "TimeUnlock1_%d_From", [[timeLocks at: i] getDayOfWeek] + 1); 
		[[timeLocks at: i] setFromMinute: [myPackage getParamAsInteger: fieldName]];

		sprintf(fieldName, "TimeUnlock1_%d_To", [[timeLocks at: i] getDayOfWeek] + 1); 
		[[timeLocks at: i] setToMinute: [myPackage getParamAsInteger: fieldName]];

		++i;

		//Franja 2
		sprintf(fieldName, "TimeUnlock2_%d_From", [[timeLocks at: i] getDayOfWeek] + 1); 
		[[timeLocks at: i] setFromMinute: [myPackage getParamAsInteger: fieldName]];

		sprintf(fieldName, "TimeUnlock2_%d_To", [[timeLocks at: i] getDayOfWeek] + 1); 
		[[timeLocks at: i] setToMinute: [myPackage getParamAsInteger: fieldName]];

		++i;
	}

  if ([myPackage isValidParam: "TUnlockEnable"])
   [door setTUnlockEnable: [myPackage getParamAsInteger: "TUnlockEnable"]];

  if ([myPackage isValidParam: "SensorType"])
   [door setSensorType: [myPackage getParamAsInteger: "SensorType"]];
	
	myEntityRef = [[[CimManager getInstance] getCim] addCimDoor: door];
	
}

/**/
- (void) removeDoor
{
  printd("GenericSetRequest->removeDoor\n");
  
  if (![myPackage isValidParam: "DoorId"]) THROW(TSUP_KEY_NOT_FOUND);
	
  [[[CimManager getInstance] getCim] removeCimDoor: [myPackage getParamAsInteger: "DoorId"]];
}

/**/
- (void) setDoor
{
  int doorId;
  id cim = [[CimManager getInstance] getCim];
	id door;
	id timeLocks;
	int i;
	char fieldName[20];
  
  printd("GenericSetRequest->setDoor\n");
  
  if (![myPackage isValidParam: "DoorId"]) THROW(TSUP_KEY_NOT_FOUND);
  doorId = [myPackage getParamAsInteger: "DoorId"];
  door = [cim getDoorById: doorId];

  if ([myPackage isValidParam: "DoorType"])
   [door setDoorType: [myPackage getParamAsInteger: "DoorType"]];	
  
  if ([myPackage isValidParam: "KeyCount"])
   [door setKeyCount: [myPackage getParamAsInteger: "KeyCount"]];	

  if ([myPackage isValidParam: "HasElectronicLock"])
   [door setHasElectronicLock: [myPackage getParamAsBoolean: "HasElectronicLock"]];	

  if ([myPackage isValidParam: "HasSensor"])
   [door setHasSensor: [myPackage getParamAsBoolean: "HasSensor"]];	

  if ([myPackage isValidParam: "AutomaticLockTime"])
   [door setAutomaticLockTime: [myPackage getParamAsInteger: "AutomaticLockTime"]];	

  if ([myPackage isValidParam: "DelayOpenTime"])
   [door setDelayOpenTime: [myPackage getParamAsInteger: "DelayOpenTime"]];	

  if ([myPackage isValidParam: "AccessTime"])
   [door setAccessTime: [myPackage getParamAsInteger: "AccessTime"]];	

  if ([myPackage isValidParam: "MaxOpenTime"])
   [door setMaxOpenTime: [myPackage getParamAsInteger: "MaxOpenTime"]];	

  if ([myPackage isValidParam: "FireAlarmTime"])
   [door setFireAlarmTime: [myPackage getParamAsInteger: "FireAlarmTime"]];	

  if ([myPackage isValidParam: "Name"])
   [door setDoorName: [myPackage getParamAsString: "Name"]];	

  if ([myPackage isValidParam: "Deleted"])
   [door setDeleted: [myPackage getParamAsBoolean: "Deleted"]];

  if ([myPackage isValidParam: "BehindDoorId"]) {
   	[door setBehindDoorId: [myPackage getParamAsInteger: "BehindDoorId"]];

		// actualizo el objeto en memoria para el manejo de puertas internas y externas
		if ([door getBehindDoorId] > 0)
			[door setOuterDoor: [[[CimManager getInstance] getCim] getDoorById: [door getBehindDoorId]]];
		else
			[door setOuterDoor: NULL];
	}

  if ([myPackage isValidParam: "FireTime"])
   [door setFireTime: [myPackage getParamAsInteger: "FireTime"]];

  if ([myPackage isValidParam: "TUnlockEnable"])
    [door setTUnlockEnable: [myPackage getParamAsInteger: "TUnlockEnable"]];

  if ([myPackage isValidParam: "PlungerId"])
	  [door setPlungerHardwareId: [myPackage getParamAsInteger: "PlungerId"]];

  if ([myPackage isValidParam: "LockerId"])
	  [door setLockHardwareId: [myPackage getParamAsInteger: "LockerId"]];

	if ([myPackage isValidParam: "SensorType"])
		[door setSensorType: [myPackage getParamAsInteger: "SensorType"]];

	timeLocks = [door getTimeLocks];

	i = 0;
	while (i<[timeLocks size]) {

		//Franja 1
		sprintf(fieldName, "TimeUnlock1_%d_From", [[timeLocks at: i] getDayOfWeek] + 1);
		if ([myPackage isValidParam: fieldName])
			[[timeLocks at: i] setFromMinute: [myPackage getParamAsInteger: fieldName]];

		sprintf(fieldName, "TimeUnlock1_%d_To", [[timeLocks at: i] getDayOfWeek] + 1); 
		if ([myPackage isValidParam: fieldName])
			[[timeLocks at: i] setToMinute: [myPackage getParamAsInteger: fieldName]];

		++i;

		//Franja 2
		sprintf(fieldName, "TimeUnlock2_%d_From", [[timeLocks at: i] getDayOfWeek] + 1);
		if ([myPackage isValidParam: fieldName])
			[[timeLocks at: i] setFromMinute: [myPackage getParamAsInteger: fieldName]];

		sprintf(fieldName, "TimeUnlock2_%d_To", [[timeLocks at: i] getDayOfWeek] + 1); 
		if ([myPackage isValidParam: fieldName])
			[[timeLocks at: i] setToMinute: [myPackage getParamAsInteger: fieldName]];

		++i;
	}


	TRY

		[door applyChanges];

	CATCH

		[door restore];
		RETHROW();

	END_TRY



}

/**/
- (void) sendKeyValueResponseSetDoor
{
  printd("GenericSetRequest->sendKeyValueResponseSetDoor\n");
  
	[myRemoteProxy addParamAsInteger: "DoorId" value: myEntityRef];  
}

/**/
- (void) initSetDoor
{
  strcpy(mySettingFnc,"setDoor");
  strcpy(mySendKeyValueResponseFnc,"sendKeyValueResponseSetDoor"); 
	strcpy(myAddFnc,"addDoor");
  strcpy(myRemoveFnc,"removeDoor");

}

/* SETEOS ACEPTADORES */
/**/
- (void) addAcceptor
{
	char name[40+1];
	char model[50+1];
	int brand = 0;
	int protocol = 1;
	int hardwareId = 0;
	int baudRate = 5;
	int dataBits = 0;
	int parity = 1;
	int stopBits = 0;
	int flowControl = 0;
	int startTimeOut = 0;
	BOOL echoDisable = FALSE;

	*model = '\0';

  //doLog(0,"GenericSetRequest->addAcceptor\n");

	if ( (![myPackage isValidParam: "Type"]) || 
			 (![myPackage isValidParam: "Name"]) ||
			 (![myPackage isValidParam: "DoorId"]) ||
			 (![myPackage isValidParam: "StackerSize"]) ||
			 (![myPackage isValidParam: "StackerWarningSize"]) )
	  THROW(TSUP_KEY_NOT_FOUND);

  if ([myPackage isValidParam: "Name"]) 
    stringcpy(name, [myPackage getParamAsString: "Name"]);

  if ([myPackage isValidParam: "Model"]) 
    stringcpy(model, [myPackage getParamAsString: "Model"]);

  if ([myPackage isValidParam: "Brand"]) 
    brand = [myPackage getParamAsInteger: "Brand"];

  if ([myPackage isValidParam: "Protocol"]){
    protocol = [myPackage getParamAsInteger: "Protocol"];
		if (protocol < 1) protocol = 1; // nunca puede venir un 0
	}

  if ([myPackage isValidParam: "HardwareId"]) 
    hardwareId = [myPackage getParamAsInteger: "HardwareId"];

  if ([myPackage isValidParam: "BaudRate"]) 
    baudRate = [myPackage getParamAsInteger: "BaudRate"];

  if ([myPackage isValidParam: "DataBits"]) 
    dataBits = [myPackage getParamAsInteger: "DataBits"];

  if ([myPackage isValidParam: "Parity"]) 
    parity = [myPackage getParamAsInteger: "Parity"];

  if ([myPackage isValidParam: "StopBits"]) 
    stopBits = [myPackage getParamAsInteger: "StopBits"];

  if ([myPackage isValidParam: "FlowControl"]) 
    flowControl = [myPackage getParamAsInteger: "FlowControl"];
/*
  if ([myPackage isValidParam: "StartTimeout"]) 
    startTimeOut = [myPackage getParamAsInteger: "StartTimeout"];

  if ([myPackage isValidParam: "EchoDisable"]) 
    echoDisable = [myPackage getParamAsBoolean: "EchoDisable"];
*/  
	myEntityRef = [[[CimManager getInstance] getCim] 
															addCimAcceptor: [myPackage getParamAsInteger: "Type"] 
																	name: name 
																	brand: brand 
																	model: model 
																	protocol: protocol 
																	hardwareId: hardwareId 
																	stackerSize: [myPackage getParamAsInteger: "StackerSize"]   
																	stackerWarningSize: [myPackage getParamAsInteger: "StackerWarningSize"] 
																	doorId: [myPackage getParamAsInteger: "DoorId"] 
																	baudRate: baudRate
																	dataBits: dataBits
																	parity: parity
																	stopBits: stopBits
																	flowControl: flowControl];
//																	startTimeOut: startTimeOut
//																	echoDisable: echoDisable];
}

/**/
- (void) removeAcceptor
{
  printd("GenericSetRequest->removeAcceptor\n");
  
  if (![myPackage isValidParam: "AcceptorId"]) THROW(TSUP_KEY_NOT_FOUND);		 
	
  [[[CimManager getInstance] getCim] removeCimAcceptor: [myPackage getParamAsInteger: "AcceptorId"]];  
}

/**/
- (void) setAcceptor
{
  int acceptorId;
  id cim = [[CimManager getInstance] getCim];
	id acceptor;
	int protocol = 1;
  
  printd("GenericSetRequest->setAcceptor\n");

  if (![myPackage isValidParam: "AcceptorId"]) 
		THROW(TSUP_KEY_NOT_FOUND);

  acceptorId = [myPackage getParamAsInteger: "AcceptorId"];	
  acceptor = [cim getAcceptorSettingsById: acceptorId];

  if ([myPackage isValidParam: "Type"])
   [acceptor setAcceptorType: [myPackage getParamAsInteger: "Type"]];	

  if ([myPackage isValidParam: "Name"])
   [acceptor setAcceptorName: [myPackage getParamAsString: "Name"]];	

  if ([myPackage isValidParam: "Brand"])
   [acceptor setAcceptorBrand: [myPackage getParamAsInteger: "Brand"]];	

  if ([myPackage isValidParam: "Model"])
   [acceptor setAcceptorModel: [myPackage getParamAsString: "Model"]];

  if ([myPackage isValidParam: "Protocol"]){
		protocol = [myPackage getParamAsInteger: "Protocol"];
		if (protocol < 1) protocol = 1; // nunca puede venir un 0
    [acceptor setAcceptorProtocol: protocol];
	}

  if ([myPackage isValidParam: "HardwareId"])
   [acceptor setAcceptorHardwareId: [myPackage getParamAsInteger: "HardwareId"]];	
  
  if ([myPackage isValidParam: "StackerSize"])
   [acceptor setStackerSize: [myPackage getParamAsInteger: "StackerSize"]];	

  if ([myPackage isValidParam: "StackerWarningSize"])
   [acceptor setStackerWarningSize: [myPackage getParamAsInteger: "StackerWarningSize"]];	

  if ([myPackage isValidParam: "DoorId"])
   [acceptor setDoor: [cim getDoorById: [myPackage getParamAsInteger: "DoorId"]]];	

  if ([myPackage isValidParam: "BaudRate"])
   [acceptor setAcceptorBaudRate: [myPackage getParamAsInteger: "BaudRate"]];	

  if ([myPackage isValidParam: "DataBits"])
   [acceptor setAcceptorDataBits: [myPackage getParamAsInteger: "DataBits"]];	

  if ([myPackage isValidParam: "Parity"])
   [acceptor setAcceptorParity: [myPackage getParamAsInteger: "Parity"]];	

  if ([myPackage isValidParam: "StopBits"])
   [acceptor setAcceptorStopBits: [myPackage getParamAsInteger: "StopBits"]];	

  if ([myPackage isValidParam: "FlowControl"])
   [acceptor setAcceptorFlowControl: [myPackage getParamAsInteger: "FlowControl"]];	

  if ([myPackage isValidParam: "Disabled"])
   [acceptor setDisabled: [myPackage getParamAsBoolean: "Disabled"]];

  if ([myPackage isValidParam: "Deleted"])
   [acceptor setDeleted: [myPackage getParamAsBoolean: "Deleted"]];	
/*
  if ([myPackage isValidParam: "StartTimeout"]) 
   [acceptor setStartTimeOut: [myPackage getParamAsInteger: "StartTimeout"]];

  if ([myPackage isValidParam: "EchoDisable"]) 
   [acceptor setEchoDisable: [myPackage getParamAsBoolean: "EchoDisable"]];
*/
	[acceptor applyChanges];
}

/**/
- (void) sendKeyValueResponseSetAcceptor
{
  printd("GenericSetRequest->sendKeyValueResponseSetAcceptor\n");
  
	[myRemoteProxy addParamAsInteger: "AcceptorId" value: myEntityRef];  
}

/**/
- (void) initSetAcceptor
{
  strcpy(mySettingFnc,"setAcceptor");
	strcpy(myAddFnc,"addAcceptor");
  strcpy(myRemoveFnc,"removeAcceptor");
  strcpy(mySendKeyValueResponseFnc,"sendKeyValueResponseSetAcceptor"); 

}


/*DENOMINACIONES DE DIVISAS*/
/**/
- (void) setCurrencyDenomination
{
  id cim = [[CimManager getInstance] getCim];
	id acceptor;
	id denom;
	id acceptedDepositValue;
	id acceptedCurrency;
  
  printd("GenericSetRequest->initSetCurrencyDenomination\n");
  
  if ((![myPackage isValidParam: "DepositValueType"]) || (![myPackage isValidParam: "AcceptorId"]) || (![myPackage isValidParam: "CurrencyId"]) || (![myPackage isValidParam: "Amount"]))
		THROW(TSUP_KEY_NOT_FOUND);

	acceptor = [cim getAcceptorSettingsById: [myPackage getParamAsInteger: "AcceptorId"]];
	acceptedDepositValue = [acceptor getAcceptedDepositValueByType: [myPackage getParamAsInteger: "DepositValueType"]];
	acceptedCurrency = [acceptedDepositValue getAcceptedCurrencyByCurrencyId: [myPackage getParamAsInteger: "CurrencyId"]];
	if (acceptedCurrency) {
		denom = [acceptedCurrency getDenominationByAmount: [myPackage getParamAsCurrency: "Amount"]];
	
		if (denom == NULL) {
			denom = [Denomination new];
			[denom setAmount: [myPackage getParamAsCurrency: "Amount"]];
	
			if ([myPackage isValidParam: "State"])
				[denom setDenominationState: [myPackage getParamAsInteger: "State"]];
			else
				[denom setDenominationState: DenominationState_ACCEPT];
	
			if ([myPackage isValidParam: "Security"])
				[denom setDenominationSecurity: [myPackage getParamAsInteger: "Security"]];
			else
				[denom setDenominationSecurity: DenominationSecurity_STANDARD];
					
			[acceptedCurrency addDenomination: denom];
	
		}else{
	
			if ([myPackage isValidParam: "State"])
				[denom setDenominationState: [myPackage getParamAsInteger: "State"]];
			
			if ([myPackage isValidParam: "Security"])
				[denom setDenominationSecurity: [myPackage getParamAsInteger: "Security"]];
		}
	
		// guarda la denominacion
		[acceptor storeDenomination: [myPackage getParamAsInteger: "DepositValueType"] acceptorId: [myPackage getParamAsInteger: "AcceptorId"] currencyId: [myPackage getParamAsInteger: "CurrencyId"] denomination: denom];

	}

}

/**/
- (void) initSetCurrencyDenomination
{
  strcpy(mySettingFnc,"setCurrencyDenomination");
}

/*DEPOSIT VALUES*/
/**/
- (void) addDepositValueType
{
  id cim = [[CimManager getInstance] getCim];

  printd("GenericSetRequest->addDepositValueType\n");

  if ((![myPackage isValidParam: "DepositValueType"]) || (![myPackage isValidParam: "AcceptorId"]))
		THROW(TSUP_KEY_NOT_FOUND);
  
	[cim addAcceptorDepositValueType: [myPackage getParamAsInteger: "AcceptorId"] depositValueType: [myPackage getParamAsInteger: "DepositValueType"]];
}

/**/
- (void) removeDepositValueType
{
  id cim = [[CimManager getInstance] getCim];

  printd("GenericSetRequest->removeDepositValueType\n");

  if ((![myPackage isValidParam: "DepositValueType"]) || (![myPackage isValidParam: "AcceptorId"]))
		THROW(TSUP_KEY_NOT_FOUND);
  
	[cim removeAcceptorDepositValueType: [myPackage getParamAsInteger: "AcceptorId"] depositValueType: [myPackage getParamAsInteger: "DepositValueType"]];
}

/**/
- (void) sendKeyValueResponseSetDepositValueType
{
	// No hace nada
}

/**/
- (void) initSetDepositValueType
{
  strcpy(myAddFnc,"addDepositValueType");
  strcpy(myRemoveFnc,"removeDepositValueType");
  strcpy(mySendKeyValueResponseFnc,"sendKeyValueResponseSetDepositValueType"); 
}

/*DEPOSIT VALUES CURRENCIES */
/**/
- (void) addDepositValueTypeCurrency
{
  id cim = [[CimManager getInstance] getCim];

  printd("GenericSetRequest->addDepositValueTypeCurrency\n");

  if ((![myPackage isValidParam: "DepositValueType"]) || (![myPackage isValidParam: "AcceptorId"]) || (![myPackage isValidParam: "CurrencyId"]))
		THROW(TSUP_KEY_NOT_FOUND);
  
	[cim addDepositValueTypeCurrency: [myPackage getParamAsInteger: "AcceptorId"] depositValueType: [myPackage getParamAsInteger: "DepositValueType"] currencyId: [myPackage getParamAsInteger: "CurrencyId"]];
}

/**/
- (void) removeDepositValueTypeCurrency
{
  id cim = [[CimManager getInstance] getCim];

  printd("GenericSetRequest->removeDepositValueTypeCurrency\n");

  if ((![myPackage isValidParam: "DepositValueType"]) || (![myPackage isValidParam: "AcceptorId"]) || (![myPackage isValidParam: "CurrencyId"]))
		THROW(TSUP_KEY_NOT_FOUND);
  
	[cim removeDepositValueTypeCurrency: [myPackage getParamAsInteger: "AcceptorId"] depositValueType: [myPackage getParamAsInteger: "DepositValueType"] currencyId: [myPackage getParamAsInteger: "CurrencyId"]];
}

/**/
- (void) sendKeyValueResponseSetDepositValueTypeCurrency
{
	// No hace nada
}

/**/
- (void) initSetDepositValueTypeCurrency
{
  strcpy(myAddFnc,"addDepositValueTypeCurrency");
  strcpy(myRemoveFnc,"removeDepositValueTypeCurrency");
  strcpy(mySendKeyValueResponseFnc,"sendKeyValueResponseSetDepositValueTypeCurrency"); 
}

/*SETEOS DE IMPRESION*/
/**/
- (void) initSetPrintSystem
{
  printd("GenericSetRequest->initSetPrintSystem\n");
  
  strcpy(mySettingFnc,"setPrintSystem"); 
}

/**/
- (void) setPrintSystem
{
  id printingSettings = [PrintingSettings getInstance];
  
  printd("GenericSetRequest->setPrintSystem\n");
  
	if ([myPackage isValidParam: "PrinterType"]) 		
		[printingSettings setPrinterType: [myPackage getParamAsInteger: "PrinterType"]];

	if ([myPackage isValidParam: "PrinterCOMPort"])
  	[printingSettings setPrinterCOMPort: [myPackage getParamAsInteger: "PrinterCOMPort"]];

	if ([myPackage isValidParam: "LinesQtyBetweenTickets"])
  	[printingSettings setLinesQtyBetweenTickets: [myPackage getParamAsInteger: "LinesQtyBetweenTickets"]];

	if ([myPackage isValidParam: "CopiesQty"])
		[printingSettings setCopiesQty: [myPackage getParamAsInteger: "CopiesQty"]];

	if ([myPackage isValidParam: "PrintTickets"])
    [printingSettings setPrintTickets: [myPackage getParamAsInteger: "PrintTickets"]];

	if ([myPackage isValidParam: "PrintNextHeader"])
  	[printingSettings setPrintNextHeader: [myPackage getParamAsBoolean: "PrintNextHeader"]];		

	if ([myPackage isValidParam: "AutoPaperCut"])
		[printingSettings setAutoPaperCut: [myPackage getParamAsBoolean: "AutoPaperCut"]];

	if ([myPackage isValidParam: "PrintZeroTickets"])
  	[printingSettings setPrintZeroTickets: [myPackage getParamAsBoolean: "PrintZeroTickets"]];
	
  if ([myPackage isValidParam: "PrinterCode"])
  	[printingSettings setPrinterCode: [myPackage getParamAsString: "PrinterCode"]];
	
  if ([myPackage isValidParam: "UpdateDate"])
  	[printingSettings setUpdateDate: [myPackage getParamAsDateTime: "UpdateDate"]];
	
	TRY

		[printingSettings applyChanges];
	
	CATCH
		
		[printingSettings restore];
    RETHROW();
    	
	END_TRY
}

/*SETEOS DE MONTOS*/
/**/
- (void) initSetAmountMoney
{
  printd("GenericSetRequest->initSetAmountMoney\n");
  
  strcpy(mySettingFnc,"setAmountMoney"); 
}

/**/
- (void) setAmountMoney
{
  id amountSettings = [AmountSettings getInstance];
  
  printd("GenericSetRequest->setAmountMoney\n");
  
	if ([myPackage isValidParam: "RoundType"])
    [amountSettings setRoundType: [myPackage getParamAsInteger: "RoundType"]];
  
	if ([myPackage isValidParam: "DecimalQty"])
  	[amountSettings setDecimalQty: [myPackage getParamAsInteger: "DecimalQty"]];

	if ([myPackage isValidParam: "ItemsRoundDecimalQty"])
  	[amountSettings setItemsRoundDecimalQty: [myPackage getParamAsInteger: "ItemsRoundDecimalQty"]];
	
  if ([myPackage isValidParam: "SubtotalRoundDecimalQty"])
    [amountSettings setSubtotalRoundDecimalQty: [myPackage getParamAsInteger: "SubtotalRoundDecimalQty"]];
	
  if ([myPackage isValidParam: "TotalRoundDecimalQty"])
  	[amountSettings setTotalRoundDecimalQty: [myPackage getParamAsInteger: "TotalRoundDecimalQty"]];
	
  if ([myPackage isValidParam: "TaxRoundDecimalQty"])
  	[amountSettings setTaxRoundDecimalQty: [myPackage getParamAsInteger: "TaxRoundDecimalQty"]];
	
  if ([myPackage isValidParam: "RoundValue"])
  	[amountSettings setRoundValue: [myPackage getParamAsCurrency: "RoundValue"]];
	
	TRY

		[amountSettings applyChanges];
	
	CATCH
		
		[amountSettings restore];
		RETHROW();

	END_TRY
}

/*PUERTAS POR USUARIO*/

/**/
- (void) sendKeyValueResponseSetDoorByUser
{
  printd("GenericSetRequest->sendKeyValueResponseSetDoorByUser\n");
  
  //No hace nada porque no tiene nada para enviar de vuelta
  
}


/**/
- (void) activateDoorByUser
{
  id user;
  
  printd("GenericSetRequest->activateDoorByUser\n");
  
	if (![myPackage isValidParam: "UserId"]) THROW(TSUP_KEY_NOT_FOUND);
	if (![myPackage isValidParam: "DoorId"]) THROW(TSUP_KEY_NOT_FOUND);

	[[UserManager getInstance] activateDoorByUserId: [myPackage getParamAsInteger: "DoorId"] userId: [myPackage getParamAsInteger: "UserId"]];

  // agrego la puerta en memoria
  user = [[UserManager getInstance] getUser: [myPackage getParamAsInteger: "UserId"]];
	if (user)
  	[user addDoorByUserToCollection: [myPackage getParamAsInteger: "DoorId"]];
    
}

/**/
- (void) deactivateDoorByUser
{
  id user;
  
  printd("GenericSetRequest->deactivateDoorByUser\n");
  
	if (![myPackage isValidParam: "UserId"]) THROW(TSUP_KEY_NOT_FOUND);
	if (![myPackage isValidParam: "DoorId"]) THROW(TSUP_KEY_NOT_FOUND);

	[[UserManager getInstance] deactivateDoorByUser: [myPackage getParamAsInteger: "DoorId"] userId: [myPackage getParamAsInteger: "UserId"]];

	// quito la puerta de memoria
  user = [[UserManager getInstance] getUser: [myPackage getParamAsInteger: "UserId"]];
	if (user)
  	[user removeDoorByUserToCollection: [myPackage getParamAsInteger: "DoorId"]];
     
}

/**/
- (void) initSetDoorByUser
{
  printd("GenericSetRequest->initSetDoorByUser\n");
  
  strcpy(myActivateFnc,"activateDoorByUser");
  strcpy(myDeactivateFnc,"deactivateDoorByUser");
  strcpy(mySendKeyValueResponseFnc,"sendKeyValueResponseSetDoorByUser");
}

/*USUARIOS*/
/**/
- (void) addUser
{
	char loginName[16+1];
	char password[16+1];
	char firstName[50+1];
	char surname[50+1];
	char duressPassword[16+1];
	char bankAccountNumber[30+1];
	BOOL active;
	BOOL usesDynamicPin;
	BOOL temporaryPassword;
	datetime_t lastLoginDateTime;
	datetime_t lastChangePasswordDateTime;
  int loginMethod;
  datetime_t enrollDateTime;
	LanguageType language;
  char key[20+1];
  
	loginName[0] = '\0';   
	password[0] = '\0';   
	firstName[0] = '\0';   
	surname[0] = '\0';
	duressPassword[0] = '\0';
	bankAccountNumber[0] = '\0';
	active = TRUE;
	temporaryPassword = FALSE;
	lastLoginDateTime = 0;
	lastChangePasswordDateTime = 0;
  loginMethod = LoginMethod_PERSONALIDNUMBER;
  enrollDateTime = [SystemTime getLocalTime];
  key[0] = '\0';
	language = [[RegionalSettings getInstance] getLanguage];

  printd("GenericSetRequest->addUser\n");

  if ([myPackage isValidParam: "LoginName"])
    stringcpy(loginName, [myPackage getParamAsString: "LoginName"]);
    
	if ([myPackage isValidParam: "Password"])
    stringcpy(password, [myPackage getParamAsString: "Password"]);
    
	if ([myPackage isValidParam: "Name"])
    stringcpy(firstName, [myPackage getParamAsString: "Name"]);

	if ([myPackage isValidParam: "SurName"])
    stringcpy(surname, [myPackage getParamAsString: "Surname"]);
		
	if ([myPackage isValidParam: "DuressPassword"])
    stringcpy(duressPassword, [myPackage getParamAsString: "DuressPassword"]);
    
	if ([myPackage isValidParam: "BankAccountNumber"])
    stringcpy(bankAccountNumber, [myPackage getParamAsString: "BankAccountNumber"]);

	if ([myPackage isValidParam: "Active"])
    active = [myPackage getParamAsBoolean: "Active"];

	if ([myPackage isValidParam: "UsesDynamicPin"])
    usesDynamicPin = [myPackage getParamAsBoolean: "UsesDynamicPin"];

	if ([myPackage isValidParam: "TemporaryPassword"])
    temporaryPassword = [myPackage getParamAsBoolean: "TemporaryPassword"];

	if ([myPackage isValidParam: "LastLoginDateTime"])
    lastLoginDateTime = [myPackage getParamAsDateTime: "LastLoginDateTime"];
    
	if ([myPackage isValidParam: "LastChangePasswordDateTime"])
    lastChangePasswordDateTime = [myPackage getParamAsDateTime: "LastChangePasswordDateTime"];

	if ([myPackage isValidParam: "LoginMethod"])
    loginMethod = [myPackage getParamAsInteger: "LoginMethod"];
		
	if ([myPackage isValidParam: "EnrollDateTime"])
    enrollDateTime = [myPackage getParamAsDateTime: "EnrollDateTime"];
    
	if ([myPackage isValidParam: "Key"])
    stringcpy(key, [myPackage getParamAsString: "Key"]);

	if ([myPackage isValidParam: "Language"])
    language = [myPackage getParamAsInteger: "Language"];

  if ([myPackage isValidParam: "ProfileId"]) {
		myEntityRef = [[UserManager getInstance] addUserByProfileId: firstName 
                                             surname: surname 
                                             profileId: [myPackage getParamAsInteger: "ProfileId"] 
                                             loginName: loginName 
                                             password: password
                                             duressPassword: duressPassword
                                             active: active
                                             temporaryPassword: temporaryPassword
                                             lastLoginDateTime: lastLoginDateTime
                                             lastChangePasswordDateTime: lastChangePasswordDateTime
                                             bankAccountNumber: bankAccountNumber
                                             loginMethod: loginMethod
                                             enrollDateTime: enrollDateTime
                                             key: key
											 language: language
											 usesDynamicPin : usesDynamicPin];
	} else if ([myPackage isValidParam: "ProfileName"]) {
		myEntityRef = [[UserManager getInstance] addUserByProfileName: firstName 
                                             surname: surname
							                               profileName: [myPackage getParamAsString: "ProfileName"] 
                                             loginName: loginName 
                                             password: password
                                             duressPassword: duressPassword
                                             active: active
                                             temporaryPassword: temporaryPassword
                                             lastLoginDateTime: lastLoginDateTime
                                             lastChangePasswordDateTime: lastChangePasswordDateTime
                                             bankAccountNumber: bankAccountNumber
                                             loginMethod: loginMethod
                                             enrollDateTime: enrollDateTime
                                             key: key
											 language: language
											 usesDynamicPin : usesDynamicPin];
  } else THROW(TSUP_KEY_NOT_FOUND);

}

/**/
- (void) removeUser
{
  printd("GenericSetRequest->removeUser\n");
  
  if (![myPackage isValidParam: "UserId"]) THROW(TSUP_KEY_NOT_FOUND);		 

	[[UserManager getInstance] removeUser: [myPackage getParamAsInteger: "UserId"]];
}

/**/
- (void) setUser
{
  int userId;
  id userManager = [UserManager getInstance];
	id user;
  
  printd("GenericSetRequest->setUser\n");
  
  if (![myPackage isValidParam: "UserId"]) THROW(TSUP_KEY_NOT_FOUND);
  userId = [myPackage getParamAsInteger: "UserId"];

	user = [userManager getUser: userId];
	if (!user || [user isDeleted]) THROW(USER_NOT_EXIST_EX);

	if ([myPackage isValidParam: "ProfileId"])
		[userManager setUserProfileId: userId value: [myPackage getParamAsInteger: "ProfileId"]];
	
	if ([myPackage isValidParam: "ProfileName"])
		[userManager setUserProfileName: userId value: [myPackage getParamAsString: "ProfileName"]];
	
	if ([myPackage isValidParam: "LoginName"])
		[userManager setUserLoginName: userId value: [myPackage getParamAsString: "LoginName"]];
	
	if ([myPackage isValidParam: "Name"])
		[userManager setUserName: userId value: [myPackage getParamAsString: "Name"]];
	
	if ([myPackage isValidParam: "Surname"])
		[userManager setUserSurname: userId value: [myPackage getParamAsString: "Surname"]];

	if ([myPackage isValidParam: "BankAccountNumber"])
		[userManager setUserBankAccountNumber: userId value: [myPackage getParamAsString: "BankAccountNumber"]];
	
	if ([myPackage isValidParam: "Active"])
		[userManager setUserActive: userId value: [myPackage getParamAsBoolean:"Active"]];

	if ([myPackage isValidParam: "TemporaryPassword"])
		[userManager setUserIsTemporaryPassword: userId value: [myPackage getParamAsBoolean:"TemporaryPassword"]];

	if ([myPackage isValidParam: "LastLoginDateTime"])
		[userManager setUserLastLoginDateTime: userId value: [myPackage getParamAsDateTime: "LastLoginDateTime"]];

	if ([myPackage isValidParam: "LastChangePasswordDateTime"])
		[userManager setUserLastChangePasswordDateTime: userId value: [myPackage getParamAsDateTime: "LastChangePasswordDateTime"]];
	
	if ([myPackage isValidParam: "LoginMethod"])
		[userManager setUserLoginMethod: userId value: [myPackage getParamAsInteger: "LoginMethod"]];
	
	if ([myPackage isValidParam: "Language"])
		[userManager setUserLanguage: userId value: [myPackage getParamAsInteger: "Language"]];
		
	if ([myPackage isValidParam: "UsesDynamicPin"])
		[userManager setUserUsesDynamicPin: userId value: [myPackage getParamAsBoolean:"UsesDynamicPin"]];

	if ([myPackage isValidParam: "Password"] ){
		if ([userManager getUserUsesDynamicPin: userId])
			THROW(USER_DYNAM_PIN_CANNOT_CHANGE_PASS_EX);
		else
			[userManager setUserPassword: userId value: [myPackage getParamAsString: "Password"]];
	}

	if ([myPackage isValidParam: "DuressPassword"]){
		if ([userManager getUserUsesDynamicPin: userId])
			THROW(USER_DYNAM_PIN_CANNOT_CHANGE_PASS_EX);
		else
			[userManager setUserDuressPassword: userId value: [myPackage getParamAsString: "DuressPassword"]];
	}

	TRY
	
		[userManager applyUserChanges: userId];
	
	CATCH

		[userManager restoreUser: userId];
		RETHROW();

	END_TRY
}

/**/
- (void) sendKeyValueResponseSetUser
{
  printd("GenericSetRequest->sendKeyValueResponseSetUser\n");
  
	[myRemoteProxy addParamAsInteger: "UserId" value: myEntityRef];
}

/**/
- (void) initSetUser
{
  strcpy(myAddFnc,"addUser");
  strcpy(myRemoveFnc,"removeUser");
  strcpy(mySettingFnc,"setUser");
  strcpy(mySendKeyValueResponseFnc,"sendKeyValueResponseSetUser"); 
}

/*ORDENES DE REPARACION*/

/**/
- (void) addRepairOrderItem
{
	char description[30];
  
	description[0] = '\0';   

  printd("GenericSetRequest->addRepairOrderItem\n");
  
  if (![myPackage isValidParam: "Description"]) THROW(TSUP_KEY_NOT_FOUND);
    stringcpy(description, [myPackage getParamAsString: "Description"]);
    	
	myEntityRef = [[RepairOrderManager getInstance] addRepairOrder: description];

}

/**/
- (void) removeRepairOrderItem
{
  printd("GenericSetRequest->removeRepairOrderItem\n");
  
  if (![myPackage isValidParam: "ItemId"]) THROW(TSUP_KEY_NOT_FOUND);
	
	[[RepairOrderManager getInstance] removeRepairOrder: [myPackage getParamAsInteger: "ItemId"]];
}

/**/
- (void) setRepairOrderItem
{
  int itemId;
  
  printd("GenericSetRequest->setRepairOrderItem\n");
  
  if (![myPackage isValidParam: "ItemId"]) THROW(TSUP_KEY_NOT_FOUND);
  itemId = [myPackage getParamAsInteger: "ItemId"];
	
	if ([myPackage isValidParam: "Description"])
	 [[RepairOrderManager getInstance] setRepairOrderDescription: itemId value: [myPackage getParamAsString: "Description"]];	
    
	TRY
		[[RepairOrderManager getInstance] applyRepairOrderChanges: itemId];
	CATCH
		[[RepairOrderManager getInstance] restoreRepairOrder: itemId];
		RETHROW();
	END_TRY
  	
}

/**/
- (void) sendKeyValueResponseSetRepairOrderItem
{
  printd("GenericSetRequest->sendKeyValueResponseSetRepairOrderItem\n");
  
	[myRemoteProxy addParamAsInteger: "ItemId" value: myEntityRef];  
}

/**/
- (void) initSetRepairOrderItem
{
  strcpy(myAddFnc,"addRepairOrderItem");
  strcpy(myRemoveFnc,"removeRepairOrderItem");
  strcpy(mySettingFnc,"setRepairOrderItem");
  strcpy(mySendKeyValueResponseFnc,"sendKeyValueResponseSetRepairOrderItem"); 
}

/*FORZADO DE CAMBIO DE PIN*/

/**/
- (void) setForcePinChange
{  
  printd("GenericSetRequest->setForcePinChange\n");

	[[UserManager getInstance] ForcePinChange];
}

/**/
- (void) sendKeyValueResponseSetForcePinChange
{
  printd("GenericSetRequest->sendKeyValueResponseSetForcePinChange\n");
  
  //No hace nada porque no tiene nada para enviar de vuelta

}

/**/
- (void) initSetForcePinChange
{
  strcpy(mySettingFnc,"setForcePinChange");
  strcpy(mySendKeyValueResponseFnc,"sendKeyValueResponseSetForcePinChange"); 
}


/*GENERAR ORDEN DE TRABAJO*/

/**/
- (void) initSetWorkOrder
{
  strcpy(mySettingFnc,"setWorkOrder");
  strcpy(mySendKeyValueResponseFnc,"sendKeyValueResponseSetWorkOrder"); 
}

/**/
- (void) setWorkOrder
{
  char OrderNumber[10];
  
  printd("GenericSetRequest->setWorkOrder\n");
  
  OrderNumber[0] = '\0';
  if (![myPackage isValidParam: "OrderNumber"]) THROW(TSUP_KEY_NOT_FOUND);
  
  stringcpy(OrderNumber, [myPackage getParamAsString: "OrderNumber"]);
  
  [Audit auditEventCurrentUser: EVENT_WORK_ORDER additional: OrderNumber station: [[[Acceptor getInstance] getRemoteCurrentUser] getUserId] logRemoteSystem: TRUE];
}

/**/
- (void) sendKeyValueResponseSetWorkOrder
{
  printd("GenericSetRequest->sendKeyValueResponseSetWorkOrder\n");
  
  //No hace nada porque no tiene nada para enviar de vuelta

}

/*DUPLAS*/

/**/
- (void) addDualAccess
{
  id dual;
  int profile1Id;
  int profile2Id;
  
  profile1Id = 0;
  profile2Id = 0;

  printd("GenericSetRequest->addDualAccess\n");
  
	if ([myPackage isValidParam: "Profile1Id"])
    profile1Id = [myPackage getParamAsInteger: "Profile1Id"];
  else THROW(TSUP_KEY_NOT_FOUND);

	if ([myPackage isValidParam: "Profile2Id"])
    profile2Id = [myPackage getParamAsInteger: "Profile2Id"];
  else THROW(TSUP_KEY_NOT_FOUND);

	[[UserManager getInstance] activateDualAccess: profile1Id profile2Id: profile2Id];
  
  // lo agrego en la lista de memoria
  dual = [[UserManager getInstance] getDualAccess: profile1Id profile2Id: profile2Id];
  if (dual != NULL)
    [[UserManager getInstance] addDualAccessToCollection: dual];
}

/**/
- (void) removeDualAccess
{
  id dual;
  int profile1Id;
  int profile2Id;
  
  profile1Id = 0;
  profile2Id = 0;

  printd("GenericSetRequest->removeDualAccess\n");
  
	if ([myPackage isValidParam: "Profile1Id"])
    profile1Id = [myPackage getParamAsInteger: "Profile1Id"];
  else THROW(TSUP_KEY_NOT_FOUND);

	if ([myPackage isValidParam: "Profile2Id"])
    profile2Id = [myPackage getParamAsInteger: "Profile2Id"];
  else THROW(TSUP_KEY_NOT_FOUND);

	[[UserManager getInstance] deactivateDualAccess: profile1Id profile2Id: profile2Id];
  
  // lo quito de la lista de memoria
  dual = [[UserManager getInstance] getDualAccessFromCollection: profile1Id profile2Id: profile2Id];
  if (dual != NULL)
    [[UserManager getInstance] removeDualAccessFromCollection: dual];
}

/**/
- (void) sendKeyValueResponseSetDualAccess
{
  printd("GenericSetRequest->sendKeyValueResponseSetDualAccess\n");
  
  //No hace nada porque no tiene nada para enviar de vuelta
  
}

/**/
- (void) initSetDualAccess
{
  strcpy(myAddFnc,"addDualAccess");
  strcpy(myRemoveFnc,"removeDualAccess");
  strcpy(mySendKeyValueResponseFnc,"sendKeyValueResponseSetDualAccess"); 
}

/*CASH BOX*/
/**/
- (void) addCashBox
{
	char name[20+1];

  printd("GenericSetRequest->addCashBox\n");
  
  if ([myPackage isValidParam: "Name"]) 
    stringcpy(name, [myPackage getParamAsString: "Name"]);
    
	myEntityRef = [[[CimManager getInstance] getCim] addCashBox: name doorId: [myPackage getParamAsInteger: "DoorId"] depositType: [myPackage getParamAsInteger: "DepositType"]];
}

/**/
- (void) removeCashBox
{
  printd("GenericSetRequest->removeCashBox\n");
  
  if (![myPackage isValidParam: "CashId"]) THROW(TSUP_KEY_NOT_FOUND);		 
	
  [[[CimManager getInstance] getCim] removeCashBox: [myPackage getParamAsInteger: "CashId"]];  
}

/**/
- (void) setCashBox
{
  int cashId;
  id facade = [[CimManager getInstance] getCim];
	id cash;
  
  printd("GenericSetRequest->setCashBox\n");
  
  if (![myPackage isValidParam: "CashId"]) THROW(TSUP_KEY_NOT_FOUND);
  cashId = [myPackage getParamAsInteger: "CashId"];	
    
  cash = [facade getCimCashById: cashId];

  if ([myPackage isValidParam: "Name"])
		[cash setName: [myPackage getParamAsString: "Name"]];

	if ([myPackage isValidParam: "DoorId"])
		[cash setDoorId: [myPackage getParamAsInteger: "DoorId"]];

	if ([myPackage isValidParam: "DepositType"])
		[cash setDepositType: [myPackage getParamAsInteger: "DepositType"]];
	
	[cash applyChanges];
}

/**/
- (void) sendKeyValueResponseSetCashBox
{
  printd("GenericSetRequest->sendKeyValueResponseSetCashBox\n");
  
	[myRemoteProxy addParamAsInteger: "CashId" value: myEntityRef];  
}

/**/
- (void) initSetCashBox
{
  strcpy(myAddFnc,"addCashBox");
  strcpy(myRemoveFnc,"removeCashBox");
  strcpy(mySettingFnc,"setCashBox");
  strcpy(mySendKeyValueResponseFnc,"sendKeyValueResponseSetCashBox"); 
}

/*ACCEPTOR BY CASH*/
/**/
- (void) addAcceptorByCash
{
  printd("GenericSetRequest->addAcceptorByCash\n");
  
  if ((![myPackage isValidParam: "CashId"]) || (![myPackage isValidParam: "AcceptorId"])) THROW(TSUP_KEY_NOT_FOUND);

	[[[CimManager getInstance] getCim] addAcceptorByCash: [myPackage getParamAsInteger: "CashId"] acceptorId: [myPackage getParamAsInteger: "AcceptorId"]];
}

/**/
- (void) removeAcceptorByCash
{
  printd("GenericSetRequest->removeAcceptorByCash\n");
  
  if ((![myPackage isValidParam: "CashId"]) || (![myPackage isValidParam: "AcceptorId"])) THROW(TSUP_KEY_NOT_FOUND);	

	[[[CimManager getInstance] getCim] removeAcceptorByCash: [myPackage getParamAsInteger: "CashId"] acceptorId: [myPackage getParamAsInteger: "AcceptorId"]];

}

/**/
- (void) sendKeyValueResponseSetAcceptorByCash
{
	// No hace nada
}

/**/
- (void) initSetAcceptorByCash
{
	strcpy(myAddFnc,"addAcceptorByCash");
	strcpy(myRemoveFnc,"removeAcceptorByCash");
  strcpy(mySendKeyValueResponseFnc,"sendKeyValueResponseSetAcceptorByCash"); 
}



/*BOX*/
/**/
- (void) addBox
{
	char name[20+1];
	char model[50+1];

  printd("GenericSetRequest->addBox\n");
  
  if ([myPackage isValidParam: "Name"]) 
    stringcpy(name, [myPackage getParamAsString: "Name"]);

  if ([myPackage isValidParam: "Model"]) 
    stringcpy(model, [myPackage getParamAsString: "Model"]);

    
	myEntityRef = [[[CimManager getInstance] getCim] addCimBox: name model: model];
}

/**/
- (void) removeBox
{
  printd("GenericSetRequest->removeBox\n");
  
  if (![myPackage isValidParam: "BoxId"]) THROW(TSUP_KEY_NOT_FOUND);		 
	
  [[[CimManager getInstance] getCim] removeBoxById: [myPackage getParamAsInteger: "BoxId"]];  
}

/**/
- (void) setBox
{
  int boxId;
  id facade = [[CimManager getInstance] getCim];
	id box;
  
  //doLog(0,"GenericSetRequest->setBox\n");
  
  if (![myPackage isValidParam: "BoxId"]) THROW(TSUP_KEY_NOT_FOUND);

  boxId = [myPackage getParamAsInteger: "BoxId"];	
    
  box = [facade getBoxById: boxId];

  if ([myPackage isValidParam: "Name"])
		[box setName: [myPackage getParamAsString: "Name"]];

  if ([myPackage isValidParam: "Model"])
		[box setBoxModel: [myPackage getParamAsString: "Model"]];

	[box applyChanges];
}

/**/
- (void) sendKeyValueResponseSetBox
{
  printd("GenericSetRequest->sendKeyValueResponseSetBox\n");
  
	[myRemoteProxy addParamAsInteger: "BoxId" value: myEntityRef];  
}

/**/
- (void) initSetBox
{
  strcpy(myAddFnc,"addBox");
  strcpy(myRemoveFnc,"removeBox");
  strcpy(mySettingFnc,"setBox");
  strcpy(mySendKeyValueResponseFnc,"sendKeyValueResponseSetBox"); 
}

/*ACCEPTOR BY BOX*/
/**/
- (void) addAcceptorByBox
{
  printd("GenericSetRequest->addAcceptorByBox\n");
  
  if ((![myPackage isValidParam: "BoxId"]) || (![myPackage isValidParam: "AcceptorId"])) THROW(TSUP_KEY_NOT_FOUND);	

	[[[CimManager getInstance] getCim] addAcceptorByBox: [myPackage getParamAsInteger: "BoxId"] acceptorId: [myPackage getParamAsInteger: "AcceptorId"]];
}

/**/
- (void) removeAcceptorByBox
{
  printd("GenericSetRequest->removeAcceptorByBox\n");
  
  if ((![myPackage isValidParam: "BoxId"]) || (![myPackage isValidParam: "AcceptorId"])) THROW(TSUP_KEY_NOT_FOUND);	

	[[[CimManager getInstance] getCim] removeAcceptorByBox: [myPackage getParamAsInteger: "BoxId"] acceptorId: [myPackage getParamAsInteger: "AcceptorId"]];

}

/**/
- (void) sendKeyValueResponseSetAcceptorByBox
{
	// No hace nada
}

/**/
- (void) initSetAcceptorByBox
{
	strcpy(myAddFnc,"addAcceptorByBox");
	strcpy(myRemoveFnc,"removeAcceptorByBox");
  strcpy(mySendKeyValueResponseFnc,"sendKeyValueResponseSetAcceptorByBox"); 
}

/*DOOR BY BOX*/
/**/
- (void) addDoorByBox
{
  printd("GenericSetRequest->addDoorByBox\n");
  
  if ((![myPackage isValidParam: "BoxId"]) || (![myPackage isValidParam: "DoorId"])) THROW(TSUP_KEY_NOT_FOUND);	

	[[[CimManager getInstance] getCim] addDoorByBox: [myPackage getParamAsInteger: "BoxId"] doorId: [myPackage getParamAsInteger: "DoorId"]];
}

/**/
- (void) removeDoorByBox
{
  printd("GenericSetRequest->removeDoorByBox\n");
  
  if ((![myPackage isValidParam: "BoxId"]) || (![myPackage isValidParam: "DoorId"])) THROW(TSUP_KEY_NOT_FOUND);	

	[[[CimManager getInstance] getCim] removeDoorByBox: [myPackage getParamAsInteger: "BoxId"] doorId: [myPackage getParamAsInteger: "DoorId"]];

}

/**/
- (void) sendKeyValueResponseSetDoorByBox
{
	// No hace nada
}

/**/
- (void) initSetDoorByBox
{
	strcpy(myAddFnc,"addDoorByBox");
	strcpy(myRemoveFnc,"removeDoorByBox");
  strcpy(mySendKeyValueResponseFnc,"sendKeyValueResponseSetDoorByBox"); 
}


/*SETEOS DE TELESUPERVISION*/
/**/
- (void) addTelesup
{
	char description[60+1];
	char userName[16+1];		
	char password[16+1];		
	char remoteUserName[16+1];		
	char remotePassword[16+1];		
	char systemId[16+1];
	char remoteSystemId[16+1];
 	char acronym[16+1];
	char extension[16+1];
	int	telcoType = 0;
	int	frequency = 1;
	int	startMoment = 0;
	int	attemptsQty = 1;
	int	timeBetweenAttempts = 10;
	int	maxTimeWithoutTelAllowed = 0;
	int	connectionId1 = 0;
	int	connectionId2 = 0;	
	datetime_t nextTelesupDateTime = 0;
	datetime_t lastSuceedTelesupDateTime = 0;
	int	fromHour = 0;
	int	toHour = 24;
	BOOL scheduled = FALSE;
	datetime_t nextSecondaryTelesupDateTime = 0;
  int frame = 5;
  int cabinIdleWaitTime = 0;
	BOOL informDepositsByTrans = FALSE;
	BOOL informExtractionsByTrans = FALSE;
	BOOL informAlarmsByTrans = FALSE;
	BOOL informZCloseByTrans = FALSE;
  CONNECTION_SETTINGS conn;
     
  printd("GenericSetRequest->addTelesup\n");
  
	description[0] = '\0'; 
	userName[0] = '\0';	
	password[0] = '\0';		
	remoteUserName[0] = '\0';		
	remotePassword[0] = '\0';		
	systemId[0] = '\0';
	remoteSystemId[0] = '\0';
 	acronym[0] = '\0';
	extension[0] = '\0';
    
	if ([myPackage isValidParam: "Description"])
		stringcpy(description, [myPackage getParamAsString: "Description"]);
	
	if ([myPackage isValidParam: "UserName"])
	 stringcpy(userName, [myPackage getParamAsString: "UserName"]);
		
	if ([myPackage isValidParam: "Password"]) 
	 stringcpy(password, [myPackage getParamAsString: "Password"]);
		
	if ([myPackage isValidParam: "RemoteUserName"]) 
	 stringcpy(remoteUserName, [myPackage getParamAsString: "RemoteUserName"]);
		
	if ([myPackage isValidParam: "RemotePassword"]) 
	 stringcpy(remotePassword, [myPackage getParamAsString: "RemotePassword"]);
		
	if ([myPackage isValidParam: "SystemId"]) 
	 stringcpy(systemId, [myPackage getParamAsString: "SystemId"]);

	if ([myPackage isValidParam: "RemoteSystemId"]) 
	 stringcpy(remoteSystemId, [myPackage getParamAsString: "RemoteSystemId"]);
		
	if ([myPackage isValidParam: "TelcoType"]) 
	 telcoType = [myPackage getParamAsInteger: "TelcoType"];
		
	if ([myPackage isValidParam: "Frequency"])
   frequency = [myPackage getParamAsInteger: "Frequency"]; 
					
	if ([myPackage isValidParam: "StartMoment"]) 
	 startMoment = [myPackage getParamAsInteger: "StartMoment"]; 
					
	if ([myPackage isValidParam: "AttemptsQty"]) 
	 attemptsQty = [myPackage getParamAsInteger: "AttemptsQty"];
					
	if ([myPackage isValidParam: "TimeBetweenAttempts"]) 
	 timeBetweenAttempts = [myPackage getParamAsInteger: "TimeBetweenAttempts"];
					
	if ([myPackage isValidParam: "MaxTimeWithoutTelAllowed"]) 
	 maxTimeWithoutTelAllowed = [myPackage getParamAsInteger: "MaxTimeWithoutTelAllowed"];
	
  if ([myPackage isValidParam: "ConnectionName"]) {
    conn = [[TelesupervisionManager getInstance] getConnectionByDescription: [myPackage getParamAsString: "ConnectionName"]];
    connectionId1 = [conn getConnectionId];
  } else {				
  	if ([myPackage isValidParam: "ConnectionId1"]) 
  	 connectionId1 = [myPackage getParamAsInteger: "ConnectionId1"];
	}

	if ([myPackage isValidParam: "ConnectionId2"]) 
	 connectionId2 = [myPackage getParamAsInteger: "ConnectionId2"];
					
	if ([myPackage isValidParam: "NextTelesupDateTime"]) {
	  nextTelesupDateTime = [SystemTime convertToLocalTime: [myPackage getParamAsDateTime: "NextTelesupDateTime"]];
  
  // Lamentablemente funciona mal el mktime en windows por lo tanto debo pasar dos veces a hora local
#ifdef WIN32
    nextTelesupDateTime = [SystemTime convertToLocalTime: nextTelesupDateTime]; 
#endif
  }	 
 		
	if ([myPackage isValidParam: "LastSuceedTelesupDateTime"]) 
	 lastSuceedTelesupDateTime = [myPackage getParamAsDateTime: "LastSuceedTelesupDateTime"];


	if ([myPackage isValidParam: "FromHour"]) {
	 fromHour = (([myPackage getParamAsInteger: "FromHour"] * 3600) - [SystemTime getTimeZone]) / 3600;
	 if (fromHour < 0) fromHour = fromHour + 24;
	 //doLog(0,"Configurando hora desde a %d\n", fromHour);
  }   	 
		
	if ([myPackage isValidParam: "ToHour"]) {
	 toHour = (([myPackage getParamAsInteger: "ToHour"] * 3600) - [SystemTime getTimeZone]) / 3600;
	 if (toHour < 0) toHour = toHour + 24;
	 if (toHour < fromHour) toHour = 24;
	 //doLog(0,"Configurando hora hasta a %d\n", toHour);
  }	 

	if ([myPackage isValidParam: "Scheduled"])
	 scheduled = [myPackage getParamAsBoolean: "Scheduled"];

	if ([myPackage isValidParam: "Acronym"])
	 stringcpy(acronym, [myPackage getParamAsString: "Acronym"]);

	if ([myPackage isValidParam: "Extension"])
	 stringcpy(extension, [myPackage getParamAsString: "Extension"]);
	 
	if ([myPackage isValidParam: "NextSecondaryTelesupDateTime"]) {
	 nextSecondaryTelesupDateTime = [SystemTime convertToLocalTime: [myPackage getParamAsDateTime: "NextSecondaryTelesupDateTime"]];
  // Lamentablemente funciona mal el mktime en windows por lo tanto debo pasar dos veces a hora local
#ifdef WIN32
   nextSecondaryTelesupDateTime = [SystemTime convertToLocalTime: nextSecondaryTelesupDateTime];
#endif	 
  }
     
	if ([myPackage isValidParam: "Frame"])
	 frame = [myPackage getParamAsInteger: "Frame"];
   	 
	if ([myPackage isValidParam: "CabinIdleWaitTime"])
	 cabinIdleWaitTime = [myPackage getParamAsInteger: "CabinIdleWaitTime"];

	if ([myPackage isValidParam: "InformDepositsByTransaction"])
		informDepositsByTrans = [myPackage getParamAsBoolean: "InformDepositsByTransaction"];

	if ([myPackage isValidParam: "InformExtractionsByTransaction"])
		informExtractionsByTrans = [myPackage getParamAsBoolean: "InformExtractionsByTransaction"];

	if ([myPackage isValidParam: "InformAlarmsByTransaction"])
		informAlarmsByTrans = [myPackage getParamAsBoolean: "InformAlarmsByTransaction"];

	if ([myPackage isValidParam: "InformZCloseByTransaction"])
		informZCloseByTrans = [myPackage getParamAsBoolean: "InformZCloseByTransaction"];

	myEntityRef = [[TelesupFacade getInstance] addTelesup: description
				                                       userName: userName 
                                               password: password
                                               remoteUserName: remoteUserName 
                                               remotePassword: remotePassword
				                                       systemId: systemId 
                                               remoteSystemId: remoteSystemId
				                                       telcoType: telcoType 
                                               frequency: frequency 
                                               startMoment: startMoment
				                                       attemptsQty: attemptsQty 
                                               timeBetweenAttempts: timeBetweenAttempts
				                                       maxTimeWithoutTelAllowed: maxTimeWithoutTelAllowed 
				                                       connectionId1: connectionId1 
                                               connectionId2: connectionId2
				                                       nextTelesupDateTime: nextTelesupDateTime 
				                                       acronym: acronym 
                                               extension: extension
				                                       fromHour: fromHour 
                                               toHour: toHour 
                                               scheduled: scheduled
                                               nextSecondaryTelesupDateTime: nextSecondaryTelesupDateTime
                                               frame: frame
                                               cabinIdleWaitTime: cabinIdleWaitTime
																							 informDepositsByTransaction: informDepositsByTrans
																							 informExtractionsByTransaction: informExtractionsByTrans
																							 informAlarmsByTransaction: informAlarmsByTrans
																							 informZCloseByTransaction: informZCloseByTrans]; 			

}

/**/
- (void) removeTelesup
{
  printd("GenericSetRequest->removeTelesup\n");

  /**todo si no viene telesupId se deberia realizar las operaciones sobre la 
   *supervision en curso.*/  
  
  if ([myPackage isValidParam: "TelesupId"]) 
    [[TelesupFacade getInstance] removeTelesup: [myPackage getParamAsInteger: "TelesupId"]];
  else THROW(TSUP_KEY_NOT_FOUND);

	[[TelesupervisionManager getInstance] writeTelesupsToFile];  
}

/**/
- (void) setTelesup
{
	TELESUP_FACADE facade = [TelesupFacade getInstance];
	int telesupId;
	datetime_t auxDate;
	int fromHour, toHour;

  printd("GenericSetRequest->setTelesup\n");
  
  if (![myPackage isValidParam: "TelesupId"]) telesupId = myTelesupRol; 
	else telesupId = [myPackage getParamAsInteger: "TelesupId"];
  
	if ([myPackage isValidParam: "Description"])
	 [facade setTelesupParamAsString: "Description" value: [myPackage getParamAsString: "Description"] telesupRol: telesupId];
	
	if ([myPackage isValidParam: "UserName"])
   [facade setTelesupParamAsString: "UserName" value: [myPackage getParamAsString: "UserName"] telesupRol: telesupId];

	if ([myPackage isValidParam: "Password"]) 
	 [facade setTelesupParamAsString: "Password" value: [myPackage getParamAsString: "Password"] telesupRol: telesupId];
		
	if ([myPackage isValidParam: "RemoteUserName"]) 
   [facade setTelesupParamAsString: "RemoteUserName" value: [myPackage getParamAsString: "RemoteUserName"] telesupRol: telesupId];

	if ([myPackage isValidParam: "RemotePassword"]) 
   [facade setTelesupParamAsString: "RemotePassword" value: [myPackage getParamAsString: "RemotePassword"] telesupRol: telesupId];
		
	if ([myPackage isValidParam: "SystemId"]) 
   [facade setTelesupParamAsString: "SystemId" value: [myPackage getParamAsString: "SystemId"] telesupRol: telesupId];

	if ([myPackage isValidParam: "RemoteSystemId"]) 
	 [facade setTelesupParamAsString: "RemoteSystemId" value: [myPackage getParamAsString: "RemoteSystemId"] telesupRol: telesupId];	 
		
	if ([myPackage isValidParam: "TelcoType"]) 
   [facade setTelesupParamAsInteger: "TelcoType" value: [myPackage getParamAsInteger: "TelcoType"] telesupRol: telesupId];
		
	if ([myPackage isValidParam: "Frequency"])
   [facade setTelesupParamAsInteger: "Frequency" value: [myPackage getParamAsInteger: "Frequency"] telesupRol: telesupId];
 
	if ([myPackage isValidParam: "StartMoment"]) 
   [facade setTelesupParamAsInteger: "StartMoment" value: [myPackage getParamAsInteger: "StartMoment"] telesupRol: telesupId];
 
	if ([myPackage isValidParam: "AttemptsQty"]) 
   [facade setTelesupParamAsInteger: "AttemptsQty" 	value: [myPackage getParamAsInteger: "AttemptsQty"] telesupRol: telesupId];

	if ([myPackage isValidParam: "TimeBetweenAttempts"]) 
 	 [facade setTelesupParamAsInteger: "TimeBetweenAttempts" value: [myPackage getParamAsInteger: "TimeBetweenAttempts"] telesupRol: telesupId];
					
	if ([myPackage isValidParam: "MaxTimeWithoutTelAllowed"]) 
 	 [facade setTelesupParamAsInteger: "MaxTimeWithoutTelAllowed" value: [myPackage getParamAsInteger: "MaxTimeWithoutTelAllowed"] telesupRol: telesupId];

	if ([myPackage isValidParam: "ConnectionId1"]) 
 	 [facade setTelesupParamAsInteger: "ConnectionId1" value: [myPackage getParamAsInteger: "ConnectionId1"] telesupRol: telesupId];

	if ([myPackage isValidParam: "ConnectionId2"]) 
   [facade setTelesupParamAsInteger: "ConnectionId2" value: [myPackage getParamAsInteger: "ConnectionId2"] telesupRol: telesupId];

	if ([myPackage isValidParam: "NextTelesupDateTime"]) {
	 auxDate = [SystemTime convertToLocalTime: [myPackage getParamAsDateTime: "NextTelesupDateTime"]];
  
  // Lamentablemente funciona mal el mktime en windows por lo tanto debo pasar dos veces a hora local
#ifdef WIN32
   auxDate = [SystemTime convertToLocalTime: auxDate];
#endif	     
	 [facade setTelesupParamAsDateTime: "NextTelesupDateTime" value: auxDate telesupRol: telesupId];
  }	 

	if ([myPackage isValidParam: "LastSuceedTelesupDateTime"]) 
   [facade setTelesupParamAsDateTime: "LastSuceedTelesupDateTime" value: [myPackage getParamAsDateTime: "LastSuceedTelesupDateTime"] telesupRol: telesupId];

	if ([myPackage isValidParam: "FromHour"]) {
	 //doLog("fromHour = %d systemTime = %d\n", [myPackage getParamAsInteger: "FromHour"], [SystemTime getTimeZone]);

	 //fromHour = (([myPackage getParamAsInteger: "FromHour"] * 3600) - [SystemTime getTimeZone]) / 3600;
	 //if (fromHour < 0) fromHour = fromHour + 24;
	 fromHour = (([myPackage getParamAsInteger: "FromHour"] * 3600) + ([SystemTime getTimeZone] * -1)) / 3600;
	 if (fromHour < 0) fromHour = fromHour + 24;
	 if (fromHour > 23) fromHour = fromHour - 24;
	 //doLog("Configurando hora desde a %d\n", fromHour);
 	 [facade setTelesupParamAsInteger: "FromHour" value: fromHour telesupRol: telesupId];
  }

  
	if ([myPackage isValidParam: "ToHour"]) {
	 //toHour = (([myPackage getParamAsInteger: "ToHour"] * 3600) + [SystemTime getTimeZone]) / 3600;
	 //if (toHour < 0) toHour = toHour + 24;
	 toHour = (([myPackage getParamAsInteger: "ToHour"] * 3600) + [SystemTime getTimeZone]) / 3600;
	 if (toHour > 24) toHour = toHour - 24;

	 if (toHour < fromHour) toHour = 24;
	 //doLog(0,"Configurando hora hasta a %d\n", toHour);
   [facade setTelesupParamAsInteger: "ToHour" value: toHour telesupRol: telesupId];
  }   

	if ([myPackage isValidParam: "ToHour"]) {
	 //toHour = (([myPackage getParamAsInteger: "ToHour"] * 3600) + [SystemTime getTimeZone]) / 3600;
	 //if (toHour < 0) toHour = toHour + 24;
	 toHour = (([myPackage getParamAsInteger: "ToHour"] * 3600) + ([SystemTime getTimeZone] * -1)) / 3600;

	 if (toHour < 0) toHour = toHour + 24;

	 if (toHour < fromHour) toHour = 24;
	 if (toHour > 23) toHour = toHour - 24;

	 //doLog("Configurando hora hasta a %d\n", toHour);
   [facade setTelesupParamAsInteger: "ToHour" value: toHour telesupRol: telesupId];
  }   



	if ([myPackage isValidParam: "Scheduled"])
 	 [facade setTelesupParamAsInteger: "Scheduled" value: [myPackage getParamAsBoolean: "Scheduled"] telesupRol: telesupId];

	if ([myPackage isValidParam: "Acronym"])
	 [facade setTelesupParamAsString: "Acronym" value: [myPackage getParamAsString: "Acronym"] telesupRol: telesupId];

	if ([myPackage isValidParam: "Extension"])
   [facade setTelesupParamAsString: "Extension" value: [myPackage getParamAsString: "Extension"] telesupRol: telesupId];

	if ([myPackage isValidParam: "NextSecondaryTelesupDateTime"]) {
	 auxDate = [SystemTime convertToLocalTime: [myPackage getParamAsDateTime: "NextSecondaryTelesupDateTime"]];

  // Lamentablemente funciona mal el mktime en windows por lo tanto debo pasar dos veces a hora local
#ifdef WIN32
   auxDate = [SystemTime convertToLocalTime: auxDate];
#endif	
	
   [facade setTelesupParamAsDateTime: "NextSecondaryTelesupDateTime" value: auxDate telesupRol: telesupId];
  }   

	if ([myPackage isValidParam: "Frame"])
   [facade setTelesupParamAsInteger: "Frame" value: [myPackage getParamAsInteger: "Frame"] telesupRol: telesupId];

	if ([myPackage isValidParam: "CabinIdleWaitTime"])
   [facade setTelesupParamAsInteger: "CabinIdleWaitTime" value: [myPackage getParamAsInteger: "CabinIdleWaitTime"] telesupRol: telesupId];

	if ([myPackage isValidParam: "InformDepositsByTransaction"])
   [facade setTelesupParamAsBoolean: "InformDepositsByTransaction" value: [myPackage getParamAsBoolean: "InformDepositsByTransaction"] telesupRol: telesupId];

	if ([myPackage isValidParam: "InformExtractionsByTransaction"])
   [facade setTelesupParamAsBoolean: "InformExtractionsByTransaction" value: [myPackage getParamAsBoolean: "InformExtractionsByTransaction"] telesupRol: telesupId];

	if ([myPackage isValidParam: "InformAlarmsByTransaction"])
   [facade setTelesupParamAsBoolean: "InformAlarmsByTransaction" value: [myPackage getParamAsBoolean: "InformAlarmsByTransaction"] telesupRol: telesupId];

	if ([myPackage isValidParam: "InformZCloseByTransaction"])
   [facade setTelesupParamAsBoolean: "InformZCloseByTransaction" value: [myPackage getParamAsBoolean: "InformZCloseByTransaction"] telesupRol: telesupId];

	[facade telesupApplyChanges: telesupId];	   

}

/**/
- (void) sendKeyValueResponseSetTelesup
{
  printd("GenericSetRequest->sendKeyValueResponseSetTelesup\n");
  
	[myRemoteProxy addParamAsInteger: "TelesupId" value: myEntityRef];  
}

/**/
- (void) initSetTelesupSettings
{
  printd("GenericSetRequest->initSetTelesupSettings\n");
  
  strcpy(myAddFnc,"addTelesup");
  strcpy(myRemoveFnc,"removeTelesup");
  strcpy(mySettingFnc,"setTelesup");
  strcpy(mySendKeyValueResponseFnc,"sendKeyValueResponseSetTelesup");
}

/*SETEOS DE CONECCIONES*/
/**/

/**/

/**/
- (void) addConnection
{
	char description[30+1]; 
	char modemPhoneNumber[32+1];
	char domain[60+1];
	char IP[60+1];	
	char ispPhoneNumber[32+1];
	char userName[16+1];
	char password[16+1];

	int	connectionType = 0;
	int	portType = 0;
	int	portId = 0;
	int	ringsQty = 0;
	int	tcpPortSource = 0;
	int	tcpPortDestination = 0;
	int	pppConnectionId = 0;
	int	speed = 0;   
	int connectBy = 0;
	char domainSup[100];
	

  printd("GenericSetRequest->addConnection\n");

	description[0] = '\0'; 
	modemPhoneNumber[0] = '\0';
	domain[0] = '\0';
	IP[0] = '\0';
	ispPhoneNumber[0] = '\0';
	userName[0] = '\0';
	password[0] = '\0';
	domainSup[0] = '\0';
    
	if ([myPackage isValidParam: "Description"]) 
 	  stringcpy(description, [myPackage getParamAsString: "Description"]);
 	  
	if ([myPackage isValidParam: "Type"])
    connectionType = [myPackage getParamAsInteger: "Type"]; 

	if ([myPackage isValidParam: "PortType"])
    portType = [myPackage getParamAsInteger: "PortType"];  
	
	if ([myPackage isValidParam: "PortId"])  
	 portId = [myPackage getParamAsInteger: "PortId"];

	if ([myPackage isValidParam: "ModemPhoneNumber"]) 
    stringcpy(modemPhoneNumber, [myPackage getParamAsString: "ModemPhoneNumber"]); 

	if ([myPackage isValidParam: "RingsQty"]) 
	 ringsQty = [myPackage getParamAsInteger: "RingsQty"];
	
	if ([myPackage isValidParam: "Domain"]) 
	 stringcpy(domain, [myPackage getParamAsString: "Domain"]);
	 
	if ([myPackage isValidParam: "IP"]) 
	 stringcpy(IP, [myPackage getParamAsString: "IP"]);
	
	if ([myPackage isValidParam: "TCPPortSource"]) 
	 tcpPortSource = [myPackage getParamAsInteger: "TCPPortSource"];
	
	if ([myPackage isValidParam: "TCPPortDestination"]) 
	 tcpPortDestination = [myPackage getParamAsInteger: "TCPPortDestination"];
	
	if ([myPackage isValidParam: "PPPConnectionId"]) 
	 pppConnectionId = [myPackage getParamAsInteger: "PPPConnectionId"];
	
	if ([myPackage isValidParam: "ISPPhoneNumber"]) 
	 stringcpy(ispPhoneNumber, [myPackage getParamAsString: "ISPPhoneNumber"]);
	
	if ([myPackage isValidParam: "UserName"]) 
	 stringcpy(userName, [myPackage getParamAsString: "UserName"]);
	
	if ([myPackage isValidParam: "Password"]) 
	 stringcpy(password, [myPackage getParamAsString: "Password"]);
	
	if ([myPackage isValidParam: "Speed"]) 
	 speed = [myPackage getParamAsInteger: "Speed"];

	if ([myPackage isValidParam: "Speed"]) 
	 speed = [myPackage getParamAsInteger: "Speed"];

	if ([myPackage isValidParam: "Speed"]) 
	 speed = [myPackage getParamAsInteger: "Speed"];

	if ([myPackage isValidParam: "Speed"]) 
	 speed = [myPackage getParamAsInteger: "Speed"];

	if ([myPackage isValidParam: "ConnectBy"]) 
	 connectBy = [myPackage getParamAsInteger: "ConnectBy"];

	if ([myPackage isValidParam: "DomainSup"]) 
	 stringcpy(domainSup, [myPackage getParamAsString: "DomainSup"]);
    
	myEntityRef = [[TelesupFacade getInstance] addConnection: connectionType 
                                                description: description
                                                portType: portType
                                                portId: portId
                                                modemPhoneNumber: modemPhoneNumber
                                                ringsQty: ringsQty
                                                domain: domain
                                                tcpPortSource: tcpPortSource
                                                tcpPortDestination: tcpPortDestination
                                                pppConnectionId: pppConnectionId
                                                ispPhoneNumber: ispPhoneNumber
                                                userName: userName
                                                password: password
                                                speed: speed
                                                IP: IP
																								connectBy: connectBy
																								domainSup: domainSup];



}

/**/
- (void) removeConnection
{
  printd("GenericSetRequest->removeConnection\n");

  if (![myPackage isValidParam: "ConnectionId"]) THROW(TSUP_KEY_NOT_FOUND); 
  
  [[TelesupFacade getInstance] removeConnection: [myPackage getParamAsInteger: "ConnectionId"]]; 
}

/**/
- (void) setConnection
{
	TELESUP_FACADE facade = [TelesupFacade getInstance];
	int connectionId;
	int error;

  printf("GenericSetRequest->setConnection\n");
  
  if (![myPackage isValidParam: "ConnectionId"])
    connectionId = [facade getTelesupParamAsInteger: "ConnectionId1" telesupRol: myTelesupRol];
  else 
		connectionId = [myPackage getParamAsInteger: "ConnectionId"];
  
  printf("GenericSetRequest->2\n");
	if ([myPackage isValidParam: "Description"])
	 [facade setConnectionParamAsString: "Description" value: [myPackage getParamAsString: "Description"] connectionId: connectionId];
    	  
	if ([myPackage isValidParam: "Type"])
	 [facade setConnectionParamAsInteger:  "Type" value: [myPackage getParamAsInteger: "Type"] connectionId: connectionId];

	if ([myPackage isValidParam: "PortType"])
	 [facade setConnectionParamAsInteger:  "PortType" value: [myPackage getParamAsInteger: "PortType"] connectionId: connectionId];
	
	if ([myPackage isValidParam: "PortId"])  
	 [facade setConnectionParamAsInteger:  "PortId" value: [myPackage getParamAsInteger: "PortId"] connectionId: connectionId];

	if ([myPackage isValidParam: "ModemPhoneNumber"]) 
	 [facade setConnectionParamAsString:  "ModemPhoneNumber" value: [myPackage getParamAsString: "ModemPhoneNumber"] connectionId: connectionId];

	if ([myPackage isValidParam: "RingsQty"]) 
	 [facade setConnectionParamAsInteger: "RingsQty" value: [myPackage getParamAsInteger: "RingsQty"] connectionId: connectionId];
	
	if ([myPackage isValidParam: "Domain"]) 
	 [facade setConnectionParamAsString:  "Domain" value: [myPackage getParamAsString: "Domain"] connectionId: connectionId];
	
	if ([myPackage isValidParam: "IP"]) 
	 [facade setConnectionParamAsString:  "IP" value: [myPackage getParamAsString: "IP"] connectionId: connectionId];

	if ([myPackage isValidParam: "TCPPortSource"]) 
	 [facade setConnectionParamAsInteger:  "TCPPortSource" value: [myPackage getParamAsInteger: "TCPPortSource"] connectionId: connectionId];
	
	if ([myPackage isValidParam: "TCPPortDestination"]) 
	 [facade setConnectionParamAsInteger:  "TCPPortDestination" value: [myPackage getParamAsInteger: "TCPPortDestination"] connectionId: connectionId];

	if ([myPackage isValidParam: "PPPConnectionId"]) 
	 [facade setConnectionParamAsInteger:  "PPPConnectionId" value: [myPackage getParamAsInteger: "PPPConnectionId"] connectionId: connectionId];
	
	if ([myPackage isValidParam: "ISPPhoneNumber"]) 
	 [facade setConnectionParamAsString:  "ISPPhoneNumber" value: [myPackage getParamAsString: "ISPPhoneNumber"] connectionId: connectionId];
	
	if ([myPackage isValidParam: "UserName"]) 
	 [facade setConnectionParamAsString:  "UserName" value: [myPackage getParamAsString: "UserName"] connectionId: connectionId];
	
	if ([myPackage isValidParam: "Password"]) 
	 [facade setConnectionParamAsString:  "Password" value: [myPackage getParamAsString: "Password"] connectionId: connectionId];
	
	if ([myPackage isValidParam: "Speed"]) 
	 [facade setConnectionParamAsInteger:  "Speed" value: [myPackage getParamAsInteger: "Speed"] connectionId: connectionId];

	if ([myPackage isValidParam: "ConnectBy"]) 
	 [facade setConnectionParamAsInteger:  "ConnectBy" value: [myPackage getParamAsInteger: "ConnectBy"] connectionId: connectionId];

	if ([myPackage isValidParam: "DomainSup"]) 
	 [facade setConnectionParamAsString:  "DomainSup" value: [myPackage getParamAsString: "DomainSup"] connectionId: connectionId];
  printf("GenericSetRequest->3\n");
	[facade connectionApplyChanges: connectionId];   
printf("GenericSetRequest->4\n");
	TRY
	printf("GenericSetRequest->5\n");
		if (![[TelesupervisionManager getInstance] writeTelesupsToFile])
			error = 1;
printf("GenericSetRequest->6\n");
		[[TelesupervisionManager getInstance] updateGprsConnections:  [[TelesupervisionManager getInstance] getConnection: connectionId]];
printf("GenericSetRequest->7\n");
	CATCH
		error = 1;
	END_TRY

	if (error)
	{
		//doLog(0,"ERROR writing supervision config to file\n");
	}


}

/**/
- (void) sendKeyValueResponseSetConnection
{
  printd("GenericSetRequest->sendKeyValueResponseSetConnection\n");
  
	[myRemoteProxy addParamAsInteger: "ConnectionId" value: myEntityRef];    
}

/**/
- (void) initSetConnectionSettings
{
  printd("GenericSetRequest->initSetConnectionSettings\n");
  
  strcpy(myAddFnc,"addConnection");
  strcpy(myRemoveFnc,"removeConnection");
  strcpy(mySettingFnc,"setConnection");
  strcpy(mySendKeyValueResponseFnc,"sendKeyValueResponseSetConnection");
}


/*SETEOS DE USUARIOS*/
/**/
- (void) addUserProfile
{
	char name[30+1];
	int fatherId;
	BOOL timeDelayOverride;
	BOOL keyRequired;
	BOOL useDuressPassword;
	STRING_TOKENIZER tokenizer;
	unsigned char operationsL[15];
	char buffer[200];
	char token[50];
	SecurityLevel securityLevel = SecurityLevel_1;

  name[0] = '\0';
	fatherId = 1;
	timeDelayOverride = FALSE;
	keyRequired = FALSE;
	useDuressPassword = FALSE;
	tokenizer = [StringTokenizer new];
	[tokenizer setDelimiter: ","];
	
	
  printd("GenericSetRequest->addUserProfile\n");
  
  if ([myPackage isValidParam: "Name"]) 
    stringcpy(name, [myPackage getParamAsString: "Name"]);

  if ([myPackage isValidParam: "FatherId"]) 
    fatherId = [myPackage getParamAsInteger: "FatherId"];
    
  if ([myPackage isValidParam: "TimeDelayOverride"]) 
    timeDelayOverride = [myPackage getParamAsBoolean: "TimeDelayOverride"];

  if ([myPackage isValidParam: "KeyRequired"]) 
    keyRequired = [myPackage getParamAsBoolean: "KeyRequired"];

  if ([myPackage isValidParam: "SecurityLevel"]) 
    securityLevel = [myPackage getParamAsInteger: "SecurityLevel"];    

  if ([myPackage isValidParam: "UseDuressPassword"]) 
    useDuressPassword = [myPackage getParamAsBoolean: "UseDuressPassword"];

  memset(operationsL, 0, 14);
  if ([myPackage isValidParam: "OperationsList"]){ 
    stringcpy(buffer, [myPackage getParamAsString: "OperationsList"]);
   	[tokenizer restart];
		[tokenizer setText: buffer];
    while ([tokenizer hasMoreTokens]) {
      token[0] = '\0';
      [tokenizer getNextToken: token];
      
      // seteo los bits
      setbit(operationsL, atoi(token), 1);
    }
  }
  [tokenizer free];
  
	myEntityRef = [[UserManager getInstance] addProfile: name resource: 0 keyRequired: keyRequired fatherId: fatherId timeDelayOverride: timeDelayOverride operationsList: operationsL securityLevel: securityLevel useDuressPassword: useDuressPassword];
}

/**/
- (void) removeUserProfile
{
  printd("GenericSetRequest->removeUserProfile\n");
  
  if (![myPackage isValidParam: "ProfileId"]) THROW(TSUP_KEY_NOT_FOUND);

  // elimino el perfil y sus hijos en caso de tenerlos
	[[UserManager getInstance] removeProfile: [myPackage getParamAsInteger: "ProfileId"]];  
}

/**/
- (void) setUserProfile
{
  int profileId;
  id userManager = [UserManager getInstance];
	STRING_TOKENIZER tokenizer;
	unsigned char operationsL[15];
	char buffer[200];
	char token[50];
  
	tokenizer = [StringTokenizer new];
	[tokenizer setDelimiter: ","];	  
  
  printd("GenericSetRequest->setUserProfile\n");
  
  if (![myPackage isValidParam: "ProfileId"]) THROW(TSUP_KEY_NOT_FOUND);
  profileId = [myPackage getParamAsInteger: "ProfileId"];	

	if ([userManager getProfile: profileId]) {

		if ([myPackage isValidParam: "Name"])
			[userManager setProfileName: profileId value: [myPackage getParamAsString: "Name"]];
			
		if ([myPackage isValidParam: "KeyRequired"])
			[userManager setKeyRequired: profileId value: [myPackage getParamAsBoolean: "KeyRequired"]];
		
		if ([myPackage isValidParam: "TimeDelayOverride"])
			[userManager setTimeDelayOverride: profileId value: [myPackage getParamAsBoolean: "TimeDelayOverride"]];

        if ([myPackage isValidParam: "UseDuressPassword"]) 
			[userManager setUseDuressPassword: profileId value: [myPackage getParamAsBoolean: "UseDuressPassword"]];

		memset(operationsL, 0, 14);
		if ([myPackage isValidParam: "OperationsList"]){ 
			stringcpy(buffer, [myPackage getParamAsString: "OperationsList"]);
			[tokenizer restart];
			[tokenizer setText: buffer];
			while ([tokenizer hasMoreTokens]) {
				token[0] = '\0';
				[tokenizer getNextToken: token];
				
				// seteo los bits
				setbit(operationsL, atoi(token), 1);
			}
			
			[userManager setOperationsList: profileId value: operationsL];
            [tokenizer free];
		
            // elimino de sus hijos las operaciones eliminadas
            [userManager deactivateOpByChildrenProfile: profileId operationsList: operationsL];
        }
	
		TRY
		
			[userManager applyProfileChanges: profileId];
		
		CATCH
	
			[userManager restoreProfile: profileId];
	
		END_TRY

	}
} 

/**/
- (void) sendKeyValueResponseSetUserProfile
{
  printd("GenericSetRequest->sendKeyValueResponseSetUserProfile\n");
  
  [myRemoteProxy addParamAsInteger: "ProfileId" value: myEntityRef];
}

/**/
- (void) initSetUserProfile
{
  strcpy(myAddFnc,"addUserProfile");
  strcpy(myRemoveFnc,"removeUserProfile");
  strcpy(mySettingFnc,"setUserProfile");
  strcpy(mySendKeyValueResponseFnc,"sendKeyValueResponseSetUserProfile");
}

- (void) addCashReference
{
	char name[30+1];

  printd("GenericSetRequest->addCashReference\n");
  
  if ([myPackage isValidParam: "Name"]) 
    stringcpy(name, [myPackage getParamAsString: "Name"]);
    
	myEntityRef = [[CashReferenceManager getInstance] addCashReference: name parentId: [myPackage getParamAsInteger: "ParentId"]];

}

/**/
- (void) removeCashReference
{
    id cashReference;
    printd("GenericSetRequest->removeCashReference\n");
  
    if (![myPackage isValidParam: "CashReferenceId"]) THROW(TSUP_KEY_NOT_FOUND);		 
	
    cashReference = [[CashReferenceManager getInstance] getCashReferenceById: [myPackage getParamAsInteger: "CashReferenceId"]];
    
    if (cashReference == NULL) THROW(REFERENCE_NOT_FOUND_EX);
    
    [[CashReferenceManager getInstance] removeCashReference: cashReference];  
}

/**/
- (void) setCashReference
{
  int cashReferenceId;
	id cashReference;
  
  printd("GenericSetRequest->setCashReference\n");
  
  if (![myPackage isValidParam: "CashReferenceId"]) THROW(TSUP_KEY_NOT_FOUND);
  cashReferenceId = [myPackage getParamAsInteger: "CashReferenceId"];	
    
  cashReference = [[CashReferenceManager getInstance] getCashReferenceById: cashReferenceId];
	if (cashReference == NULL) THROW(TSUP_KEY_NOT_FOUND);

  if ([myPackage isValidParam: "Name"])
		[cashReference setName: [myPackage getParamAsString: "Name"]];

	[cashReference applyChanges];
}

/**/
- (void) sendKeyValueResponseSetCashReference
{
  printd("GenericSetRequest->sendKeyValueResponseSetCashReference\n");
  
	[myRemoteProxy addParamAsInteger: "CashReferenceId" value: myEntityRef];  
}

- (void) initSetCashReference
{
  strcpy(myAddFnc,"addCashReference");
  strcpy(myRemoveFnc,"removeCashReference");
  strcpy(mySettingFnc,"setCashReference");
  strcpy(mySendKeyValueResponseFnc,"sendKeyValueResponseSetCashReference");
}

/*FECHA/HORA*/
- (void) setDateTimeReq
{
  char aux[50];
  BOOL lastState;
  datetime_t myDateTime;
  datetime_t now = [SystemTime getGMTTime];
  char buff[50];
  struct tm brokenTime;

  //doLog(0,"GenericSetRequest->setDateTime\n");

  myDateTime = [myPackage getParamAsDateTime: "DateTime"];

	// Audito el evento
  // lo audito antes del cambio de hora
  convertTime(&myDateTime, &brokenTime);
  strftime(buff, 50, [[RegionalSettings getInstance] getDateTimeFormatString], &brokenTime);
  [Audit auditEvent: TELESUP_SET_DATE_TIME additional: buff station: 0 logRemoteSystem: TRUE];

	// Lo hago de esta forma porque el facade utiliza la fecha/hora local y en este
	// punto yo tengo la fecha/hora GMT.
	//doLog(0,"DateTime = %s\n", formatDateTime(myDateTime, aux));
  // Para Windows debe hacerlo de esta manera porque la fecha viene en GMT y
  // la funcion ISOToDateTime utiliza el mktime que la pasa nuevamente a GMT 
  // why? i don't know.
 
  // Se debe setear el estado de esta variable en FALSE para que la fecha y hora
  // pueda ser modificada. Luego debe volverse al estado anterior.	
  lastState = [[RegionalSettings getInstance] getBlockDateTimeChange];
  [[RegionalSettings getInstance] setBlockDateTimeChange: FALSE];
#ifdef WIN32	
	[SystemTime setGMTTime: [SystemTime convertToLocalTime: myDateTime]];
#else
  [SystemTime setGMTTime: myDateTime];
#endif	
	[[RegionalSettings getInstance] setBlockDateTimeChange: lastState];

  [myRemoteProxy newResponseMessage];
  [myRemoteProxy addParamAsDateTime: "PreviousDateTime" value: now];
  [myRemoteProxy sendMessage];

}
 
/**
 * PROCESOS GENERALES DE PROCESAMIENTO DE CADA MENSAJE
 **/
/**/
- (void) executeRequest 
{	
  SEL mySel;
  
  //doLog(0,"Execute SetRequest\n ");
  
  strcpy(myActivateFnc,"");
  strcpy(myDeactivateFnc,"");
  strcpy(myAddFnc,"");
  strcpy(myRemoveFnc,"");
  strcpy(mySendKeyValueResponseFnc,"");
  strcpy(mySettingFnc,"");
  myEntityRef = 0;
  myIDRef = NULL;
   
  /*dependiendo de que tipo de mensaje sea decido que hacer*/
	switch (myReqType) {

    case SET_GENERAL_BILL_REQ:
      [self initSetGeneralBill];
      break;

		case SET_CIM_GENERAL_SETTINGS_REQ:
			[self initSetCimGeneralSettings];
			break;

		case SET_DOOR_REQ:
			[self initSetDoor];
			break;

		case SET_ACCEPTOR_REQ:
			[self initSetAcceptor];
			break;

		case SET_CURRENCY_DENOMINATION_REQ:
			[self initSetCurrencyDenomination];
			break;

		case SET_DEPOSIT_VALUE_TYPE_REQ:
			[self initSetDepositValueType];
			break;

		case SET_DEPOSIT_VALUE_TYPE_CURRENCY_REQ:
			[self initSetDepositValueTypeCurrency];
			break;

		case SET_CASH_BOX_REQ:
			[self initSetCashBox];
			break;	

		case SET_ACCEPTORS_BY_CASH_REQ:
			[self initSetAcceptorByCash];
			break;

		case SET_BOX_REQ:
			[self initSetBox];
			break;	

		case SET_ACCEPTORS_BY_BOX_REQ:
			[self initSetAcceptorByBox];
			break;

		case SET_DOORS_BY_BOX_REQ:
			[self initSetDoorByBox];
			break;

    case SET_COMMERCIAL_STATE_REQ:
      [self initSetCommercialState];
      break;	   

    case SET_REGIONAL_SETTINGS_REQ:
      [self initSetRegionalSettings];
      break;      
  
    case SET_PRINT_SYSTEM_REQ:
      [self initSetPrintSystem];
      break;
      
    case SET_AMOUNT_MONEY_REQ:
      [self initSetAmountMoney];
      break;
      
    case SET_USER_REQ:
      [self initSetUser];
      break;
      
    case SET_TELESUP_SETTINGS_REQ:
      [self initSetTelesupSettings];
      break;
      
    case SET_CONNECTION_REQ:
      [self initSetConnectionSettings];
      break;
      
    case SET_USER_PROFILE_REQ:
      [self initSetUserProfile];
      break;          

    case SET_CASH_REFERENCE_REQ:
      [self initSetCashReference];
      break;       
      
		case SET_DATETIME_REQ:
	   [self setDateTimeReq];
	   return;

    case SET_DOOR_BY_USER_REQ:
      [self initSetDoorByUser];
      break;

    case SET_DUAL_ACCESS_REQ:
      [self initSetDualAccess];
      break;

    case SET_FORCE_PIN_CHANGE_REQ:
      [self initSetForcePinChange];
      break;

    case SET_WORK_ORDER_REQ:
      [self initSetWorkOrder];
      break;

    case SET_REPAIR_ORDER_REQ:
      [self initSetRepairOrderItem];
      break;

    default:
     //doLog(0,"Invalid Message!!!\n");
     break;	  
	}
	
	/*parte comun a todos los mensajes*/
	switch (myReqOperation) {
	
		case ACTIVATE_REQ_OP:
			mySel = [self findSel: myActivateFnc];
      [self perform: mySel]; 
      if (strlen(mySettingFnc) != 0) {    
        mySel = [self findSel: mySettingFnc];
        [self perform: mySel];
      }         
			break;
    
		case DEACTIVATE_REQ_OP:
			mySel = [self findSel: myDeactivateFnc];
      [self perform: mySel];
			break;
    
		case ADD_REQ_OP:
      mySel = [self findSel: myAddFnc];
      [self perform: mySel];
			break;
    
		case REMOVE_REQ_OP:
			mySel = [self findSel: myRemoveFnc];
      [self perform: mySel];
			break;
    
		case SETTINGS_REQ_OP:
			mySel = [self findSel: mySettingFnc];
      [self perform: mySel];
			break;

		default:
			THROW(TSUP_INVALID_OPERATION_EX );
			break;
	}
}

/**/
- (void) endRequest
{
  SEL mySel;
  
	assert(myRemoteProxy);
	[super endRequest];

  // Esto es una chanchada porque en el SET_DATETIME_REQ ya envie el ACK con la
  // fecha hora anterior
  if (myReqType == SET_DATETIME_REQ) return;

	switch (myReqOperation) {
	
		case ADD_REQ_OP:
		case ACTIVATE_REQ_OP:
    	[myRemoteProxy newResponseMessage];
    	mySel = [self findSel: mySendKeyValueResponseFnc];
      [self perform: mySel];
    	//[myRemoteProxy appendTimestamp];
    	[myRemoteProxy sendMessage];
			break;
		
    case REMOVE_REQ_OP:
		case DEACTIVATE_REQ_OP:
   	default:
			[myRemoteProxy sendAckWithTimestampMessage];
			break;
	}
}

/**/
- (void) loadPackage: (char*) aMessage
{
  [myPackage loadPackage: aMessage];
}
@end
