#include "GenericGetRequest.h"
#include "CommercialStateFacade.h"
#include "RegionalSettings.h"
#include "BillSettings.h"
#include "TelesupFacade.h"
#include "ctversion.h"
#include "cl_genericpkg.h"
#include "AmountSettings.h"
#include "TelesupScheduler.h"
#include "FilteredRecordSet.h"
#include "CimGeneralSettings.h"
#include "CimManager.h"
#include "Cim.h"
#include "CurrencyManager.h"
#include "CashReferenceManager.h"
#include "SafeBoxHAL.h"
#include "Persistence.h"
#include "DepositDAO.h"
#include "UserManager.h"
#include "Audit.h"
#include "Acceptor.h"
#include "ResourceStringDefs.h"
#include "MessageHandler.h"
#include "ExtractionManager.h"
#include "RepairOrderManager.h"
#include "DualAccess.h"
#include "DepositManager.h"
#include "ZCloseManager.h"
#include "PrintingSettings.h"
#include "ReportXMLConstructor.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation GenericGetRequest

static GENERIC_GET_REQUEST mySingleInstance = nil;
static GENERIC_GET_REQUEST myRestoreSingleInstance = nil;

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
  
 /**/
- (void) beginEntity
{
	[myRemoteProxy addLine: BEGIN_ENTITY];
}

/**/
- (void) endEntity
{
	[myRemoteProxy addLine: END_ENTITY];
}

/**/
- (void) sendRequestDataList
{ 
	int i;
  SEL aSel;
  
	for (i = 0; i < [myEntityList size]; ++i){
    myRef = [[myEntityList at: i] intValue];
		
    [self beginEntity];
	   
	  /*ejecuta la funcion registrada*/ 
		aSel = [self findSel: myLoadStr];
    [self perform: aSel];
    
		[self endEntity];
	}

	[myEntityList freeContents];
	[myEntityList free];
}

/**
 * PROCESOS INDIVIDUALES DE CADA MENSAJE
 **/
 

/*ESTADO COMERCIAL*/
/**/
- (void) initSendCommercialState
{
  printd("GenericGetRequest->initSendCommercialState\n");

  myReqFacade = [CommercialStateFacade getInstance];
  strcpy(myLoadStr,"sendCommercialState");
}

/**/
- (void) sendCommercialState
{	
  printd("GenericGetRequest->sendCommercialState\n");
  
	[myRemoteProxy addParamAsInteger: "State" value: [myReqFacade getParamAsInteger: "State"]];	
}

/*SETEOS REGIONALES*/
/**/
- (void) initSendRegionalSettings
{
  printd("GenericGetRequest->initSendRegionalSettings\n");

  myReqFacade = [RegionalSettings getInstance];
  strcpy(myLoadStr,"sendRegionalSettings");
}

/**/
- (void) sendRegionalSettings
{	
  printd("GenericGetRequest->sendRegionalSettings\n");
	[myRemoteProxy addParamAsString: "MoneySymbol" value: [myReqFacade getMoneySymbol]];
	[myRemoteProxy addParamAsInteger: "Language" value: [myReqFacade getLanguage]];
	[myRemoteProxy addParamAsString: "TimeZone" value: [myReqFacade getTimeZoneAsString]];
	[myRemoteProxy addParamAsBoolean: "DSTEnable" value: [myReqFacade getDSTEnable]];
	[myRemoteProxy addParamAsInteger: "InitialMonth" value: [myReqFacade getInitialMonth]];
	[myRemoteProxy addParamAsInteger: "InitialWeek" value: [myReqFacade getInitialWeek]];
	[myRemoteProxy addParamAsInteger: "InitialDay" value: [myReqFacade getInitialDay]];
	[myRemoteProxy addParamAsInteger: "InitialHour" value: [myReqFacade getInitialHour]];
	[myRemoteProxy addParamAsInteger: "FinalMonth" value: [myReqFacade getFinalMonth]];
	[myRemoteProxy addParamAsInteger: "FinalWeek" value: [myReqFacade getFinalWeek]];
	[myRemoteProxy addParamAsInteger: "FinalDay" value: [myReqFacade getFinalDay]];
	[myRemoteProxy addParamAsInteger: "FinalHour" value: [myReqFacade getFinalHour]];
	[myRemoteProxy addParamAsBoolean: "BlockDateTimeChange" value: [myReqFacade getBlockDateTimeChange]];
	[myRemoteProxy addParamAsInteger: "DateFormat" value: [myReqFacade getDateFormat]];
}

/*SETEOS GENERALES DE FACTURACION*/
/**/
- (void) initSendGeneralBill
{
  printd("GenericGetRequest->initSendGeneralBill\n");

  myReqFacade = [BillSettings getInstance];
  strcpy(myLoadStr,"sendGeneralBill");
}

/**/
- (void) sendGeneralBill
{	
  printd("GenericGetRequest->sendGeneralBill\n");
  
	[myRemoteProxy addParamAsInteger: "NumeratorType" value: [myReqFacade getNumeratorType]];
	[myRemoteProxy addParamAsInteger: "TicketType" value: [myReqFacade getTicketType]];
	[myRemoteProxy addParamAsInteger: "MaxItemsQty" value: [myReqFacade getTicketMaxItemsQty]];
	[myRemoteProxy addParamAsBoolean: "TicketReprint" value: [myReqFacade getTicketReprint]];
	[myRemoteProxy addParamAsBoolean: "ViewRoundFactor" value: [myReqFacade getViewRoundFactor]];
	[myRemoteProxy addParamAsBoolean: "ViewRoundAdjust" value: [myReqFacade getViewRoundAdjust]];
	[myRemoteProxy addParamAsBoolean: "TaxDiscrimination" value: [myReqFacade getTaxDiscrimination]];
	[myRemoteProxy addParamAsCurrency: "MinAmount" value: [myReqFacade getMinAmount]];
	[myRemoteProxy addParamAsBoolean: "Transport" value: [myReqFacade getTransport]];
	[myRemoteProxy addParamAsInteger: "DigitsQty" value: [myReqFacade getDigitsQty]];
	[myRemoteProxy addParamAsInteger: "TicketQtyViewWarning" value: [myReqFacade getTicketQtyViewWarning]];
	[myRemoteProxy addParamAsDateTime: "DateChange" value: [myReqFacade getDateChange]];
	[myRemoteProxy addParamAsString: "Prefix" value: [myReqFacade getPrefix]];
	[myRemoteProxy addParamAsInteger: "InitialNumber" value: [myReqFacade getInitialNumber]];
	[myRemoteProxy addParamAsInteger: "FinalNumber" value: [myReqFacade getFinalNumber]];
	[myRemoteProxy addParamAsString: "Header1" value: [myReqFacade getHeader1]];
	[myRemoteProxy addParamAsString: "Header2" value: [myReqFacade getHeader2]];
	[myRemoteProxy addParamAsString: "Header3" value: [myReqFacade getHeader3]];
	[myRemoteProxy addParamAsString: "Header4" value: [myReqFacade getHeader4]];
	[myRemoteProxy addParamAsString: "Header5" value: [myReqFacade getHeader5]];
	[myRemoteProxy addParamAsString: "Header6" value: [myReqFacade getHeader6]];
	[myRemoteProxy addParamAsString: "Footer1" value: [myReqFacade getFooter1]];
	[myRemoteProxy addParamAsString: "Footer2" value: [myReqFacade getFooter2]];
	[myRemoteProxy addParamAsString: "Footer3" value: [myReqFacade getFooter3]];
	[myRemoteProxy addParamAsBoolean: "OpenCashDrawer" value: [myReqFacade getOpenCashDrawer]];
	[myRemoteProxy addParamAsBoolean: "RequestCustomerInfo" value: [myReqFacade getRequestCustomerInfo]];	
  [myRemoteProxy addParamAsString: "IdentifierDescription" value: [myReqFacade getIdentifierDescription]];	
}


/*SETEOS GENERALES CIM*/
- (void) initSendCimGeneralSettings
{
  printd("GenericGetRequest->initSendPrintingSystem\n");

  myReqFacade = [CimGeneralSettings getInstance];
  strcpy(myLoadStr,"sendCimGeneralSettings");
}

/**/
- (void) sendCimGeneralSettings
{
	char buffer[100];
	unsigned long nextDepositNumber;
	unsigned long nextExtractionNumber;
	unsigned long nextZNumber;

  printd("GenericGetRequest->sendCimGeneralSettings\n");
  
	//[myRemoteProxy addParamAsInteger: "NextDepositNumber" value: [myReqFacade getNextDepositNumber]];
	//[myRemoteProxy addParamAsInteger: "NextExtractionNumber" value: [myReqFacade getNextExtractionNumber]];
	//[myRemoteProxy addParamAsInteger: "NextZNumber" value: [myReqFacade getNextZNumber]];

	// obtengo los valores de los proximos numeros actuales
	if ([myReqFacade getNextDepositNumber] > [[DepositManager getInstance] getLastDepositNumber])
		nextDepositNumber = [myReqFacade getNextDepositNumber];
	else
		nextDepositNumber = [[DepositManager getInstance] getLastDepositNumber] + 1;

	if ([myReqFacade getNextExtractionNumber] > [[ExtractionManager getInstance] getLastExtractionNumber])
		nextExtractionNumber = [myReqFacade getNextExtractionNumber];
	else
		nextExtractionNumber = [[ExtractionManager getInstance] getLastExtractionNumber] + 1;

	if ([myReqFacade getNextZNumber] > [[ZCloseManager getInstance] getLastZNumber])
		nextZNumber = [myReqFacade getNextZNumber];
	else
		nextZNumber = [[ZCloseManager getInstance] getLastZNumber] + 1;

	[myRemoteProxy addParamAsInteger: "NextDepositNumber" value: nextDepositNumber];
	[myRemoteProxy addParamAsInteger: "NextExtractionNumber" value: nextExtractionNumber];
	[myRemoteProxy addParamAsInteger: "NextZNumber" value: nextZNumber];
	[myRemoteProxy addParamAsInteger: "NextXNumber" value: [myReqFacade getNextXNumber]];
	[myRemoteProxy addParamAsInteger: "DepositCopiesQty" value: [myReqFacade getDepositCopiesQty]];
	[myRemoteProxy addParamAsInteger: "ExtractionCopiesQty" value: [myReqFacade getExtractionCopiesQty]];
	[myRemoteProxy addParamAsInteger: "XCopiesQty" value: [myReqFacade getXCopiesQty]];
	[myRemoteProxy addParamAsInteger: "ZCopiesQty" value: [myReqFacade getZCopiesQty]];
	[myRemoteProxy addParamAsBoolean: "AutoPrint" value: [myReqFacade getAutoPrint]];
	[myRemoteProxy addParamAsInteger: "MailBoxOpenTime" value: [myReqFacade getMailboxOpenTime]];
	[myRemoteProxy addParamAsInteger: "MaxInactivityTimeOnDeposit" value: [myReqFacade getMaxInactivityTimeOnDeposit]];
	[myRemoteProxy addParamAsInteger: "WarningTime" value: [myReqFacade getWarningTime]];
	[myRemoteProxy addParamAsInteger: "MaxUserInactivityTime" value: [myReqFacade getMaxUserInactivityTime]];
	[myRemoteProxy addParamAsInteger: "LockLoginTime" value: [myReqFacade getLockLoginTime]];
	[myRemoteProxy addParamAsInteger: "StartDay" value: [myReqFacade getStartDay]];
	[myRemoteProxy addParamAsInteger: "EndDay" value: [myReqFacade getEndDay]];
	[myRemoteProxy addParamAsString: "POSId" value: [myReqFacade getPOSId]];
	[myRemoteProxy addParamAsString: "MacAddress" value: [myReqFacade getMacAddress: buffer]];
	[myRemoteProxy addParamAsString: "DefaultBankInfo" value: [myReqFacade getDefaultBankInfo]];
	[myRemoteProxy addParamAsString: "IdleText" value: [myReqFacade getIdleText]];
	[myRemoteProxy addParamAsInteger: "PinLenght" value: [myReqFacade getPinLenght]];
	[myRemoteProxy addParamAsInteger: "PinLife" value: [myReqFacade getPinLife]];
	[myRemoteProxy addParamAsInteger: "PinAutoInactivate" value: [myReqFacade getPinAutoInactivate]];
	[myRemoteProxy addParamAsInteger: "PinAutoDelete" value: [myReqFacade getPinAutoDelete]];
	[myRemoteProxy addParamAsBoolean: "AskEnvelopeNumber" value: [myReqFacade getAskEnvelopeNumber]];
	[myRemoteProxy addParamAsInteger: "UseCashReference" value: [myReqFacade getUseCashReference]];
	[myRemoteProxy addParamAsInteger: "AskRemoveCash" value: [myReqFacade getAskRemoveCash]];
	[myRemoteProxy addParamAsInteger: "LastDepositNumber" value: [myReqFacade getLastDepositNumber]];
	[myRemoteProxy addParamAsInteger: "LastExtractionNumber" value: [myReqFacade getLastExtractionNumber]];
	[myRemoteProxy addParamAsInteger: "LastZNumber" value: [myReqFacade getLastZNumber]];
	[myRemoteProxy addParamAsBoolean: "PrintLogo" value: [myReqFacade getPrintLogo]];
	[myRemoteProxy addParamAsBoolean: "AskQtyInManualDrop" value: [myReqFacade getAskQtyInManualDrop]];
	[myRemoteProxy addParamAsBoolean: "AskApplyTo" value: [myReqFacade getAskApplyTo]];
	[myRemoteProxy addParamAsInteger: "PrintOperatorReport" value: [myReqFacade getPrintOperatorReport]];
	[myRemoteProxy addParamAsInteger: "EnvelopeIdOpMode" value: [myReqFacade getEnvelopeIdOpMode]];
	[myRemoteProxy addParamAsInteger: "ApplyToOpMode" value: [myReqFacade getApplyToOpMode]];
	[myRemoteProxy addParamAsInteger: "LoginOpMode" value: [myReqFacade getLoginOpMode]];
	[myRemoteProxy addParamAsBoolean: "UseBarCodeReader" value: [myReqFacade getUseBarCodeReader]];
	[myRemoteProxy addParamAsBoolean: "RemoveBagVerification" value: [myReqFacade getRemoveBagVerification]];
	[myRemoteProxy addParamAsBoolean: "BagTracking" value: [myReqFacade getBagTracking]];
	[myRemoteProxy addParamAsInteger: "BarCodeReaderComPort" value: [myReqFacade getBarCodeReaderComPort]];
	[myRemoteProxy addParamAsInteger: "LoginDevType" value: [myReqFacade getLoginDevType]];
	[myRemoteProxy addParamAsInteger: "LoginDevComPort" value: [myReqFacade getLoginDevComPort]];
	[myRemoteProxy addParamAsInteger: "SwipeCardTrack" value: [myReqFacade getSwipeCardTrack]];
	[myRemoteProxy addParamAsInteger: "SwipeCardOffset" value: [myReqFacade getSwipeCardOffset]];
	[myRemoteProxy addParamAsInteger: "SwipeCardReadQty" value: [myReqFacade getSwipeCardReadQty]];
	[myRemoteProxy addParamAsBoolean: "RemoveCashOuterDoor" value: [myReqFacade removeCashOuterDoor]];
	[myRemoteProxy addParamAsBoolean: "UseEndDay" value: [myReqFacade getUseEndDay]];
	[myRemoteProxy addParamAsBoolean: "AskBagCode" value: [myReqFacade getAskBagCode]];
	[myRemoteProxy addParamAsInteger: "AcceptorsCodeType" value: [myReqFacade getAcceptorsCodeType]];
	[myRemoteProxy addParamAsBoolean: "ConfirmCode" value: [myReqFacade getConfirmCode]];
	[myRemoteProxy addParamAsBoolean: "AutomaticBackup" value: [myReqFacade isAutomaticBackup]];
	[myRemoteProxy addParamAsInteger: "BackupTime" value: [myReqFacade getBackupTime]];
	[myRemoteProxy addParamAsInteger: "BackupFrame" value: [myReqFacade getBackupFrame]];
}

/*SETEOS GENERALES DE IMPRESION*/
/**/
- (void) initSendPrintingSystem
{
  printd("GenericGetRequest->initSendPrintingSystem\n");

  myReqFacade = [PrintingSettings getInstance];
  strcpy(myLoadStr,"sendPrintingSystem");
}

/**/
- (void) sendPrintingSystem
{	
  printd("GenericGetRequest->sendPrintingSystem\n");
  
	[myRemoteProxy addParamAsInteger: "PrinterType" value: [myReqFacade getPrinterType]];
	[myRemoteProxy addParamAsInteger: "PrinterCOMPort" value: [myReqFacade getPrinterCOMPort]];
	[myRemoteProxy addParamAsInteger: "LinesQtyBetweenTickets" value: [myReqFacade getLinesQtyBetweenTickets]];
	[myRemoteProxy addParamAsInteger: "PrintTickets" value: [myReqFacade getPrintTickets]];
	[myRemoteProxy addParamAsBoolean: "PrintNextHeader" value: [myReqFacade getPrintNextHeader]];
	[myRemoteProxy addParamAsBoolean: "AutoPaperCut" value: [myReqFacade getAutoPaperCut]];
	[myRemoteProxy addParamAsInteger: "CopiesQty" value: [myReqFacade getCopiesQty]];
	[myRemoteProxy addParamAsBoolean: "PrintZeroTickets" value: [myReqFacade getPrintZeroTickets]];
	[myRemoteProxy addParamAsString: "PrinterCode" value: [myReqFacade getPrinterCode]];
	[myRemoteProxy addParamAsDateTime: "UpdateDate" value: [myReqFacade getUpdateDate]];
}

/*SETEOS GENERALES DE MONTOS*/
/**/
- (void) initSendAmountMoney
{
  printd("GenericGetRequest->initSendAmountMoney\n");

  myReqFacade = [AmountSettings getInstance];
  strcpy(myLoadStr,"sendAmountMoney");
}

/**/
- (void) sendAmountMoney
{
  printd("GenericGetRequest->sendAmountMoney\n");
  
	[myRemoteProxy addParamAsInteger: "RoundType" value: [myReqFacade getRoundType]];
	[myRemoteProxy addParamAsInteger: "DecimalQty" value: [myReqFacade getDecimalQty]];
	[myRemoteProxy addParamAsInteger: "ItemsRoundDecimalQty" value: [myReqFacade getItemsRoundDecimalQty]];
	[myRemoteProxy addParamAsInteger: "SubtotalRoundDecimalQty"	value: [myReqFacade getSubtotalRoundDecimalQty]];
	[myRemoteProxy addParamAsInteger: "TotalRoundDecimalQty" value: [myReqFacade getTotalRoundDecimalQty]];
	[myRemoteProxy addParamAsInteger: "TaxRoundDecimalQty" value: [myReqFacade getTaxRoundDecimalQty]];
	[myRemoteProxy addParamAsCurrency: "RoundValue" value: [myReqFacade getRoundValue]];
}

/*PUERTAS POR USUARIO*/
/*
 * Landa las puertas del id de usuario recibido 
 */
- (void) sendDoorsByUser
{
	int i;
	int entityId;
	
  printd("GenericGetRequest->sendDoorsByUser\n");
    
	myReqFacade = [UserManager getInstance];
	myEntityList = [myReqFacade getDoorsByUserIdList: [myPackage getParamAsInteger: "UserId"]];
	
  [myRemoteProxy newResponseMessage];
	for (i = 0; i < [myEntityList size]; ++i)
	{
		entityId = [[myEntityList at: i] intValue];
		[self beginEntity];
		[myRemoteProxy addParamAsInteger: "DoorId" value: entityId];
  	[myRemoteProxy addParamAsString: "Name" value: [[[CimManager getInstance] getDoorById: entityId] getDoorName]];
		[self endEntity];
	}

	[myEntityList freeContents];
	[myEntityList free];
	[myRemoteProxy sendMessage];
}


/*
 * Manda las puertas de todos los usuarios
 */
- (void) sendDoorsByUsers
{
	int i,j;
	COLLECTION users;
	COLLECTION doors;
	COLLECTION allUsers;
	id user;
	id door;

  printd("GenericGetRequest->sendDoorsByUsers\n");

	// inicializo en memoria las doors de todos los usuarios que NO estan dados de baja y que
	// aun no han sido inicializadas sus doors.
	allUsers = [[UserManager getInstance] getUsers];
	for (j = 0; j < [allUsers size]; ++j) {
		[[allUsers at:j] initializeDoorsByUser];
	}

	// traigo las doors
	doors = [[[CimManager getInstance] getCim] getDoors];

  [myRemoteProxy newResponseMessage];
	for (j = 0; j < [doors size]; ++j) {
			door = [doors at: j];
    	users = [door getUsers];
      for (i = 0; i < [users size]; ++i) {
    		user = [users at: i];
    		[self beginEntity];
    		[myRemoteProxy addParamAsInteger: "UserId" value: [user getUserId]];
    		[myRemoteProxy addParamAsInteger: "DoorId" value: [door getDoorId]];
      	[myRemoteProxy addParamAsString: "Name" value: [door getDoorName]];
    		[self endEntity];
  	  }
	}
	[myRemoteProxy sendMessage];

}

/*DUPLAS*/
/**/
- (void) sendDualAccess
{
	int i;
	int profileId;
  printd("GenericGetRequest->sendDualAccess\n");
  
  profileId = [myPackage getParamAsInteger: "ProfileId"];
  
  myReqFacade = [UserManager getInstance];
  myEntityList = [myReqFacade getVisibleDualAccess: profileId];
  
  [myRemoteProxy newResponseMessage];

	for (i=0; i<[myEntityList size]; ++i) {
	
		[self beginEntity];

		[myRemoteProxy addParamAsInteger: "Profile1Id" value: [[myEntityList at: i] getProfile1Id]];
		[myRemoteProxy addParamAsString: "Profile1Name" value: [[myReqFacade getProfile: [[myEntityList at: i] getProfile1Id]] getProfileName]];
		[myRemoteProxy addParamAsInteger: "Profile2Id" value: [[myEntityList at: i] getProfile2Id]];
		[myRemoteProxy addParamAsString: "Profile2Name" value: [[myReqFacade getProfile: [[myEntityList at: i] getProfile2Id]] getProfileName]];

		[self endEntity];
	}

	[myEntityList free];

	[myRemoteProxy sendMessage];
}

/*ORDENES DE REPARACION*/
/**/
- (void) sendRepairOrderItems
{
	int i;
  printd("GenericGetRequest->sendRepairOrderItems\n");
  
  myEntityList = [[RepairOrderManager getInstance] getRepairOrderItems];
  
  [myRemoteProxy newResponseMessage];

	for (i=0; i<[myEntityList size]; ++i) {
	
		[self beginEntity];

		[myRemoteProxy addParamAsInteger: "ItemId" value: [[myEntityList at: i] getItemId]];
		[myRemoteProxy addParamAsString: "Description" value: [[myEntityList at: i] getItemDescription]];

		[self endEntity];
	}
	
	[myRemoteProxy sendMessage];
}

/*USUARIOS*/

/**/
- (void) sendUsers
{
  int i;
	id user;
	int userId = 0;
  
  printd("GenericGetRequest->sendUsers\n");

	if ([myPackage isValidParam: "UserId"]) {
		userId = [myPackage getParamAsInteger: "UserId"];
		user = [[UserManager getInstance] getUserFromCompleteList: userId];
		if (!user) {
			THROW(USER_NOT_EXIST_EX);
		} else {
			[myRemoteProxy newResponseMessage];
			[myRemoteProxy addParamAsInteger: "UserId" value: [user getUserId]];
			[myRemoteProxy addParamAsInteger: "ProfileId" value: [user getUProfileId]];
			[myRemoteProxy addParamAsString: "LoginName" value: [user getLoginName]];
			[myRemoteProxy addParamAsString: "Name" value: [user getUName]];
			[myRemoteProxy addParamAsString: "SurName" value: [user getUSurname]];
			[myRemoteProxy addParamAsString: "BankAccountNumber" value: [user getBankAccountNumber]];
			[myRemoteProxy addParamAsBoolean: "Active" value: [user isActive]];
			[myRemoteProxy addParamAsBoolean: "TemporaryPassword" value: [user isTemporaryPassword]];
			[myRemoteProxy addParamAsDateTime: "LastLoginDateTime" value: [user getLastLoginDateTime]];
			[myRemoteProxy addParamAsDateTime: "LastChangePasswordDateTime" value: [user getLastChangePasswordDateTime]];
			[myRemoteProxy addParamAsInteger: "LoginMethod" value: [user getLoginMethod]];
			[myRemoteProxy addParamAsInteger: "Language" value: [user getLanguage]];
			[myRemoteProxy addParamAsDateTime: "EnrollDateTime" value: [user getEnrollDateTime]];
			[myRemoteProxy addParamAsString: "Key" value: [user getKey]];
			[myRemoteProxy addParamAsBoolean: "Deleted" value: [user isDeleted]];
			[myRemoteProxy addParamAsBoolean: "UsesDynamicPin" value: [user getUsesDynamicPin]];
			[myRemoteProxy sendMessage];
		}
	} else {
	  myEntityList = [[UserManager getInstance] getUsersCompleteList];

		[myRemoteProxy newResponseMessage];
	
		for (i=0; i<[myEntityList size]; ++i) {
	
			user = [myEntityList at: i];
		
			[self beginEntity];
	
			[myRemoteProxy addParamAsInteger: "UserId" value: [user getUserId]];
			[myRemoteProxy addParamAsInteger: "ProfileId" value: [user getUProfileId]];
			[myRemoteProxy addParamAsString: "LoginName" value: [user getLoginName]];
			[myRemoteProxy addParamAsString: "Name" value: [user getUName]];
			[myRemoteProxy addParamAsString: "SurName" value: [user getUSurname]];
			[myRemoteProxy addParamAsString: "BankAccountNumber" value: [user getBankAccountNumber]];
			[myRemoteProxy addParamAsBoolean: "Active" value: [user isActive]];
			[myRemoteProxy addParamAsBoolean: "TemporaryPassword" value: [user isTemporaryPassword]];
			[myRemoteProxy addParamAsDateTime: "LastLoginDateTime" value: [user getLastLoginDateTime]];
			[myRemoteProxy addParamAsDateTime: "LastChangePasswordDateTime" value: [user getLastChangePasswordDateTime]];
			[myRemoteProxy addParamAsInteger: "LoginMethod" value: [user getLoginMethod]];
			[myRemoteProxy addParamAsInteger: "Language" value: [user getLanguage]];
			[myRemoteProxy addParamAsDateTime: "EnrollDateTime" value: [user getEnrollDateTime]];
			[myRemoteProxy addParamAsString: "Key" value: [user getKey]];
			[myRemoteProxy addParamAsBoolean: "Deleted" value: [user isDeleted]];
			[myRemoteProxy addParamAsBoolean: "UsesDynamicPin" value: [user getUsesDynamicPin]];
	
			[self endEntity];
		}
	
		[myRemoteProxy sendMessage];
	}
}

/**/
- (void) sendUsersWithChildren
{
  int i;
  id user;
	int UserId;
  
  printd("GenericGetRequest->sendUsersWithChildren\n");

  UserId = [myPackage getParamAsInteger: "UserId"];
	myEntityList = [[UserManager getInstance] getUsersWithChildren: UserId];

  [myRemoteProxy newResponseMessage];

	for (i=0; i<[myEntityList size]; ++i) {
	
		[self beginEntity];

		user = [myEntityList at: i];
  	[myRemoteProxy addParamAsInteger: "UserId" value: [user getUserId]];
  	[myRemoteProxy addParamAsInteger: "ProfileId" value: [user getUProfileId]];
  	[myRemoteProxy addParamAsString: "LoginName" value: [user getLoginName]];
  	[myRemoteProxy addParamAsString: "Name" value: [user getUName]];
  	[myRemoteProxy addParamAsString: "SurName" value: [user getUSurname]];
  	[myRemoteProxy addParamAsString: "BankAccountNumber" value: [user getBankAccountNumber]];
  	[myRemoteProxy addParamAsBoolean: "Active" value: [user isActive]];
  	[myRemoteProxy addParamAsBoolean: "TemporaryPassword" value: [user isTemporaryPassword]];
  	[myRemoteProxy addParamAsDateTime: "LastLoginDateTime" value: [user getLastLoginDateTime]];
  	[myRemoteProxy addParamAsDateTime: "LastChangePasswordDateTime" value: [user getLastChangePasswordDateTime]];
  	[myRemoteProxy addParamAsInteger: "LoginMethod" value: [user getLoginMethod]];
		[myRemoteProxy addParamAsInteger: "Language" value: [user getLanguage]];
  	[myRemoteProxy addParamAsDateTime: "EnrollDateTime" value: [user getEnrollDateTime]];
    [myRemoteProxy addParamAsString: "Key" value: [user getKey]];
  	[myRemoteProxy addParamAsBoolean: "Deleted" value: [user isDeleted]];
		[myRemoteProxy addParamAsBoolean: "UsesDynamicPin" value: [user getUsesDynamicPin]];

		[self endEntity];
	}
	
	[myRemoteProxy sendMessage];
}

/*OPERACIONES*/

/**/
- (void) sendOperations
{
  int i;
  
  printd("GenericGetRequest->sendOperations\n");
  
  myReqFacade = [UserManager getInstance];
  myEntityList = [myReqFacade getAllOperations];

  [myRemoteProxy newResponseMessage];

	for (i=0; i<[myEntityList size]; ++i) {
	
		[self beginEntity];

	  [myRemoteProxy addParamAsInteger: "OperationId" value: [[myEntityList at: i] getOperationId]];
	  [myRemoteProxy addParamAsString: "Name" value: [[myEntityList at: i] str]];

		[self endEntity];
	}
	
	[myRemoteProxy sendMessage];
}

/*PERFILES*/

/**/
- (void) sendProfilesWithChildren
{
  int i;
  int profileId;
  unsigned char operationsL[15];
  char buffer[200];
  int j;
  char value[10];
  
  printd("GenericGetRequest->sendProfilesWithChildren\n");
  
  myReqFacade = [UserManager getInstance];
  profileId = [myPackage getParamAsInteger: "ProfileId"];
  myEntityList = [myReqFacade getProfilesWithChildren: profileId];

  [myRemoteProxy newResponseMessage];

	for (i=0; i<[myEntityList size]; ++i) {
	
		[self beginEntity];

	  [myRemoteProxy addParamAsInteger: "ProfileId" value: [[myEntityList at: i] getProfileId]];
	  [myRemoteProxy addParamAsString: "Name" value: [[myEntityList at: i] getProfileName]];
	  [myRemoteProxy addParamAsInteger: "FatherId" value: [[myEntityList at: i] getFatherId]];
	  [myRemoteProxy addParamAsBoolean: "TimeDelayOverride" value: [[myEntityList at: i] getTimeDelayOverride]];
    [myRemoteProxy addParamAsBoolean: "KeyRequired" value: [[myEntityList at: i] getKeyRequired]];
    [myRemoteProxy addParamAsInteger: "SecurityLevel" value: [[myEntityList at: i] getSecurityLevel]];
	  [myRemoteProxy addParamAsBoolean: "Active" value: [[myEntityList at: i] isDeleted]];
		[myRemoteProxy addParamAsBoolean: "UseDuressPassword" value: [[myEntityList at: i] getUseDuressPassword]];

  	memset(operationsL, 0, 14);
  	memcpy(operationsL, [[myEntityList at: i] getOperationsList], 14);
  	buffer[0] = '\0';
    for (j=1; j <= OPERATION_COUNT; ++j) {
        if (getbit(operationsL, j) == 1){
          sprintf(value,"%d",j);
          if (strlen(buffer) == 0){
            strcpy(buffer,value);
          }else{
            strcat(buffer,",");
            strcat(buffer,value);        
          }  
        }
    }      
  	[myRemoteProxy addParamAsString: "OperationsList" value: buffer];

		[self endEntity];
	}

	[myEntityList free];

	[myRemoteProxy sendMessage];
}

/**/
- (void) initSendUserProfiles
{
  printd("GenericGetRequest->initSendUserProfiles\n");
  
  myReqFacade = [UserManager getInstance];
  myEntityList = [myReqFacade getProfileIdList];
  
  /*parametro del sData aRef se debe cargar para poder 
  utilizarlo dentro de los metodos que devuelven los datos*/     
  if (myReqOperation != LIST_REQ_OP)
    myRef = [myPackage getParamAsInteger: "ProfileId"];
  
  strcpy(myLoadStr,"sendProfiles");
}

/**/
- (void) sendProfiles
{
  unsigned char operationsL[15];
  char buffer[200];
  int i;
  char value[10];
  
  buffer[0] = '\0';
  
  printd("GenericGetRequest->sendProfiles\n");
  
	[myRemoteProxy addParamAsInteger: "ProfileId" value: myRef];
	[myRemoteProxy addParamAsString: "Name" value: [myReqFacade getProfileName: myRef]];
	[myRemoteProxy addParamAsInteger: "FatherId" value: [myReqFacade getFatherId: myRef]];
	[myRemoteProxy addParamAsBoolean: "TimeDelayOverride" value: [myReqFacade getTimeDelayOverride: myRef]];
  [myRemoteProxy addParamAsBoolean: "KeyRequired" value: [myReqFacade getKeyRequired: myRef]];
	[myRemoteProxy addParamAsInteger: "SecurityLevel" value: [myReqFacade getSecurityLevel: myRef]];
	[myRemoteProxy addParamAsBoolean: "Active" value: TRUE];
	[myRemoteProxy addParamAsBoolean: "UseDuressPassword" value: [myReqFacade getUseDuressPassword: myRef]];
	
	memset(operationsL, 0, 14);
	memcpy(operationsL, [myReqFacade getOperationsList: myRef], 14);
  for (i=1; i <= OPERATION_COUNT; ++i) {
      if (getbit(operationsL, i) == 1){
        sprintf(value,"%d",i);
        if (strlen(buffer) == 0){
          strcpy(buffer,value);
        }else{
          strcat(buffer,",");
          strcat(buffer,value);        
        }  
      }
  }      
	[myRemoteProxy addParamAsString: "OperationsList" value: buffer];
}

/**/
- (void) sendCashReferences 
{
	COLLECTION references; 
	int i;
	CASH_REFERENCE reference;

	printd("GenericGetRequest->sendCashReferences\n");

	references = [[CashReferenceManager getInstance] getCashReferences];
  
  [myRemoteProxy newResponseMessage];

	for (i = 0; i < [references size]; ++i) {

		reference = [references at: i];

		[self beginEntity];

		[myRemoteProxy addParamAsInteger: "CashReferenceId" value: [reference getCashReferenceId]];
		[myRemoteProxy addParamAsString: "Name" value: [reference getName]];

		if ([reference getParent]) {
			[myRemoteProxy addParamAsInteger: "ParentId" value: [[reference getParent] getCashReferenceId]];
		} else {
			[myRemoteProxy addParamAsInteger: "ParentId" value: 0];
		}

		[myRemoteProxy addParamAsBoolean: "Deleted" value: [reference isDeleted]];

		[self endEntity];
	
	}  
	
	[myRemoteProxy sendMessage];

}

/* DOORS */
- (void) initSendDoors
{
  printd("GenericGetRequest->initSendDoors\n");
  
  myReqFacade = [[CimManager getInstance] getCim];
  myEntityList = [myReqFacade getDoorsIdList];
  
  /*parametro del sData aRef se debe cargar para poder 
  utilizarlo dentro de los metodos que devuelven los datos*/     
  if (myReqOperation != LIST_REQ_OP)
    myRef = [myPackage getParamAsInteger: "DoorId"]; 
  
  strcpy(myLoadStr,"sendDoors");
}

/**/
- (void) sendDoors
{
	id door = [myReqFacade getDoorById: myRef];
	COLLECTION timeLocks;
	char fieldName[20];
	int i;

  printd("GenericGetRequest->sendDoors\n");
  
	[myRemoteProxy addParamAsInteger: "DoorId" value: myRef];
	[myRemoteProxy addParamAsInteger: "DoorType" value: [door getDoorType]];
	[myRemoteProxy addParamAsInteger: "KeyCount" value: [door getKeyCount]];
	[myRemoteProxy addParamAsBoolean: "HasElectronicLock" value: [door hasElectronicLock]];
	[myRemoteProxy addParamAsBoolean: "HasSensor" value: [door hasSensor]];
	[myRemoteProxy addParamAsInteger: "AutomaticLockTime" value: [door getAutomaticLockTime]];
	[myRemoteProxy addParamAsInteger: "DelayOpenTime" value: [door getDelayOpenTime]];
	[myRemoteProxy addParamAsInteger: "AccessTime" value: [door getAccessTime]];
	[myRemoteProxy addParamAsInteger: "MaxOpenTime" value: [door getMaxOpenTime]];
	[myRemoteProxy addParamAsInteger: "FireAlarmTime" value: [door getFireAlarmTime]];
	[myRemoteProxy addParamAsString: "Name" value: [door getDoorName]];
	[myRemoteProxy addParamAsInteger: "BehindDoorId" value: [door getBehindDoorId]];
	[myRemoteProxy addParamAsInteger: "FireTime" value: [door getFireTime]];
	[myRemoteProxy addParamAsBoolean: "Deleted" value: [door isDeleted]];
	[myRemoteProxy addParamAsInteger: "LockerId" value: [door getLockHardwareId]];
	[myRemoteProxy addParamAsInteger: "PlungerId" value: [door getPlungerHardwareId]];
	[myRemoteProxy addParamAsInteger: "TUnlockEnable" value: [door getTUnlockEnable]];
	[myRemoteProxy addParamAsInteger: "SensorType" value: [door getSensorType]];

	timeLocks = [door getTimeLocks];

	i = 0;
	while (i<[timeLocks size]) {

		// Franja 1
		sprintf(fieldName, "TimeUnlock1_%d_From", [[timeLocks at: i] getDayOfWeek] + 1); 
		[myRemoteProxy addParamAsInteger: fieldName value: [[timeLocks at: i] getFromMinute]];

		sprintf(fieldName, "TimeUnlock1_%d_To", [[timeLocks at: i] getDayOfWeek] + 1); 
		[myRemoteProxy addParamAsInteger: fieldName value: [[timeLocks at: i] getToMinute]];

		++i;

		// Franja 2
		sprintf(fieldName, "TimeUnlock2_%d_From", [[timeLocks at: i] getDayOfWeek] + 1); 
		[myRemoteProxy addParamAsInteger: fieldName value: [[timeLocks at: i] getFromMinute]];

		sprintf(fieldName, "TimeUnlock2_%d_To", [[timeLocks at: i] getDayOfWeek] + 1); 
		[myRemoteProxy addParamAsInteger: fieldName value: [[timeLocks at: i] getToMinute]];

		++i;
	}

}

/* ACCEPTORS */
- (void) initSendAcceptors
{
  printd("GenericGetRequest->initSendAcceptors\n");
  
  myReqFacade = [[CimManager getInstance] getCim];
  myEntityList = [myReqFacade getAcceptorsIdList];

  /*parametro del sData aRef se debe cargar para poder 
  utilizarlo dentro de los metodos que devuelven los datos*/     
  if (myReqOperation != LIST_REQ_OP)
    myRef = [myPackage getParamAsInteger: "AcceptorId"]; 
  
  strcpy(myLoadStr,"sendAcceptors");
}

/**/
- (void) sendAcceptors
{
	id acceptor = [myReqFacade getAcceptorSettingsById: myRef];

  printd("GenericGetRequest->sendAcceptors\n");

	[myRemoteProxy addParamAsInteger: "AcceptorId" value: myRef];
	[myRemoteProxy addParamAsInteger: "Type" value: [acceptor getAcceptorType]];
	[myRemoteProxy addParamAsString: "Name" value: [acceptor getAcceptorName]];
	[myRemoteProxy addParamAsInteger: "Brand" value: [acceptor getAcceptorBrand]];
	[myRemoteProxy addParamAsString: "Model" value: [acceptor getAcceptorModel]];
	[myRemoteProxy addParamAsInteger: "Protocol" value: [acceptor getAcceptorProtocol]];
	[myRemoteProxy addParamAsString: "SerialNumber" value: [acceptor getAcceptorSerialNumber]];
	[myRemoteProxy addParamAsInteger: "HardwareId" value: [acceptor getAcceptorHardwareId]];
	[myRemoteProxy addParamAsInteger: "StackerSize" value: [acceptor getStackerSize]];
	[myRemoteProxy addParamAsInteger: "StackerWarningSize" value: [acceptor getStackerWarningSize]];
	[myRemoteProxy addParamAsInteger: "DoorId" value: [[acceptor getDoor] getDoorId]];
	[myRemoteProxy addParamAsInteger: "BaudRate" value: [acceptor getAcceptorBaudRate]];
	[myRemoteProxy addParamAsInteger: "DataBits" value: [acceptor getAcceptorDataBits]];
	[myRemoteProxy addParamAsInteger: "Parity" value: [acceptor getAcceptorParity]];
	[myRemoteProxy addParamAsInteger: "StopBits" value: [acceptor getAcceptorStopBits]];
	[myRemoteProxy addParamAsInteger: "FlowControl" value: [acceptor getAcceptorFlowControl]];
	[myRemoteProxy addParamAsBoolean: "Deleted" value: [acceptor isDeleted]];
	[myRemoteProxy addParamAsInteger: "QtyUsed" value: [[[ExtractionManager getInstance] getCurrentExtraction: [acceptor getDoor]] getQtyByAcceptor: acceptor]];
	[myRemoteProxy addParamAsBoolean: "Disabled" value: [acceptor isDisabled]];

	if ((![acceptor isDeleted]) && ([acceptor getAcceptorType] == AcceptorType_VALIDATOR))
		[myRemoteProxy addParamAsString: "Status" value: [[myReqFacade getAcceptorById: myRef] getCurrentErrorDescription]];
	
}

/* DENOMINACIONES POR DIVISA */
- (void) sendCurrencyDenominations
{
	int i;
	id denominations;
	id cim;
	
  printd("GenericGetRequest->sendCurrencyDenominations\n");
    
	cim = [[CimManager getInstance] getCim];
	
  if ((![myPackage isValidParam: "DepositValueType"]) || (![myPackage isValidParam: "AcceptorId"]) || (![myPackage isValidParam: "CurrencyId"]))
		THROW(TSUP_KEY_NOT_FOUND);

	denominations = [cim getCurrencyDenominations: [myPackage getParamAsInteger: "DepositValueType"] acceptorId: [myPackage getParamAsInteger: "AcceptorId"] currencyId: [myPackage getParamAsInteger: "CurrencyId"]];

  [myRemoteProxy newResponseMessage];

	if (denominations) {
		for (i = 0; i < [denominations size]; ++i) {
			[self beginEntity];
			[myRemoteProxy addParamAsCurrency: "Amount" value: [[denominations at: i] getAmount]];
			[myRemoteProxy addParamAsInteger: "State" value: [[denominations at: i] getDenominationState]];
			[myRemoteProxy addParamAsInteger: "Security" value: [[denominations at: i] getDenominationSecurity]];
			[self endEntity];
		}
	}

	[myRemoteProxy sendMessage];
}


/* DENOMINACIONES POR DIVISA */
- (void) sendDenominationList
{
	int i, j;
     CURRENCY aCurrency;
	id denominations;
	id cim;
    id valCurrencies;
	
  printf("GenericGetRequest->sendDenominationList\n");
    
	cim = [[CimManager getInstance] getCim];
	
  if  (![myPackage isValidParam: "AcceptorId"]) 
		THROW(TSUP_KEY_NOT_FOUND);

    valCurrencies = [cim getCurrenciesByDepositValueType: [myPackage getParamAsInteger: "AcceptorId"] depositValueType: 1];
    
    [myRemoteProxy newResponseMessage];
    if (valCurrencies){
        for ( j = 0; j < [valCurrencies size]; ++j) {
            
            aCurrency= [[valCurrencies at: j] getCurrency];
            
            denominations = [cim getCurrencyDenominations: 1 acceptorId: [myPackage getParamAsInteger: "AcceptorId"] currencyId: [aCurrency getCurrencyId]];
            printf("GenericGetRequest->sendDenominationList/>  aCurrency %d\n", [aCurrency getCurrencyId]);

            if (denominations) {
                for (i = 0; i < [denominations size]; ++i) {
                    [self beginEntity];
                    [myRemoteProxy addParamAsCurrency: "Amount" value: [[denominations at: i] getAmount]];
                    [myRemoteProxy addParamAsString: "CurrencyStr" value: [aCurrency getCurrencyCode]];
                    [myRemoteProxy addParamAsInteger: "CurrencyId" value: [aCurrency getCurrencyId]];
                    [self endEntity];
                }
            }
            
        }
    }
    printf("6\n");
	[myRemoteProxy sendMessage];
}

/* VALORES DE DEPOSITOS ACEPTADOS*/
/**/
- (void) sendDepositValueTypes
{
	int i;
	id depositValues;
	id cim;
	
  printd("GenericGetRequest->sendDepositValueTypes\n");
    
	cim = [[CimManager getInstance] getCim];
	
  if (![myPackage isValidParam: "AcceptorId"])
		THROW(TSUP_KEY_NOT_FOUND);

	depositValues = [cim getDepositValueTypes: [myPackage getParamAsInteger: "AcceptorId"]];

  [myRemoteProxy newResponseMessage];

	if (depositValues) 
		for (i = 0; i < [depositValues size]; ++i)
		{
			[self beginEntity];
			[myRemoteProxy addParamAsInteger: "DepositValueType" value: [[depositValues at: i] getDepositValueType]];
			[self endEntity];
		}
	

	[myRemoteProxy sendMessage];
}

/* CURRENCIES DE UN TIPO DE VALOR*/
/**/
- (void) sendDepositValueTypeCurrencies
{
	int i;
	id currencies;
	id cim;
	
  printd("GenericGetRequest->sendDepositValueTypeCurrencies\n");
    
	cim = [[CimManager getInstance] getCim];
	
  if ( (![myPackage isValidParam: "AcceptorId"]) || (![myPackage isValidParam: "DepositValueType"]))
		THROW(TSUP_KEY_NOT_FOUND);

	currencies = [cim getCurrenciesByDepositValueType: [myPackage getParamAsInteger: "AcceptorId"] depositValueType: [myPackage getParamAsInteger: "DepositValueType"]];

  [myRemoteProxy newResponseMessage];

	if (currencies) 
		for (i = 0; i < [currencies size]; ++i)
		{
			[self beginEntity];
			[myRemoteProxy addParamAsInteger: "CurrencyId" value: [[[currencies at: i] getCurrency] getCurrencyId]];
			[self endEntity];
		}
	

	[myRemoteProxy sendMessage];
}

/* CURRENCIES */
- (void) initSendCurrencies
{
	int i;
  //doLog(0,"GenericGetRequest->initSendCurrencies\n");
  
  myReqFacade = [CurrencyManager getInstance];
  myEntityList = [myReqFacade getCurrencies];
  
  [myRemoteProxy newResponseMessage];

	for (i=0; i<[myEntityList size]; ++i) {
	
		[self beginEntity];

		[myRemoteProxy addParamAsInteger: "CurrencyId" value: [[myEntityList at: i] getCurrencyId]];
		[myRemoteProxy addParamAsString: "Name" value: [[myEntityList at: i] getName]];
		[myRemoteProxy addParamAsString: "Code" value: [[myEntityList at: i] getCurrencyCode]];

		[self endEntity];
	}
	
	[myRemoteProxy sendMessage];

}

/**/
- (void) initSendCurrenciesByAcceptor
{
	int i;
	int j;
	COLLECTION currencies;

  myReqFacade = [[CimManager getInstance] getCim]; 

  if (![myPackage isValidParam: "AcceptorId"]) 
		THROW(TSUP_KEY_NOT_FOUND);

  myEntityList = [myReqFacade getDepositValueTypes: [myPackage getParamAsInteger: "AcceptorId"]];
  
  [myRemoteProxy newResponseMessage];

	for (i=0; i<[myEntityList size]; ++i) {
	
		currencies = [myReqFacade getCurrenciesByDepositValueType: [myPackage getParamAsInteger: "AcceptorId"] depositValueType: [[myEntityList at: i] getDepositValueType]];

		for (j=0; j<[currencies size]; ++j) {

			[self beginEntity];
			[myRemoteProxy addParamAsInteger: "DepositValueType" value: [[myEntityList at: i] getDepositValueType]];
			[myRemoteProxy addParamAsInteger: "CurrencyId" value: [[[currencies at: j] getCurrency] getCurrencyId]];
	
			[self endEntity];

		}
	}
	
	[myRemoteProxy sendMessage];

}


/**/
- (void) sendCurrencies
 {
	id currency;
	currency = [myReqFacade getCurrencyById: myRef];

  printd("GenericGetRequest->sendCurrencies\n");
  
	[myRemoteProxy addParamAsInteger: "CurrencyId" value: myRef];
	[myRemoteProxy addParamAsString: "Name" value: [currency getName]];
	[myRemoteProxy addParamAsString: "Code" value: [currency getCurrencyCode]];
}

/*CASH BOXES*/
- (void) initSendCashBoxes
{
  //doLog(0,"GenericGetRequest->initSendCashBoxes\n");
  
  myReqFacade = [[CimManager getInstance] getCim];
  myEntityList = [myReqFacade getCashBoxesIdList];
  
  /*parametro del sData aRef se debe cargar para poder 
  utilizarlo dentro de los metodos que devuelven los datos*/     
  if (myReqOperation != LIST_REQ_OP)
    myRef = [myPackage getParamAsInteger: "CashId"]; 
  
  strcpy(myLoadStr,"sendCashBoxes");

}

/**/
- (void) sendCashBoxes
 {
	id cash;
	cash = [myReqFacade getCimCashById: myRef];

  printd("GenericGetRequest->sendCashBoxes\n");
  
	[myRemoteProxy addParamAsInteger: "CashId" value: myRef];
	[myRemoteProxy addParamAsString: "Name" value: [cash getName]];
	[myRemoteProxy addParamAsInteger: "DoorId" value: [[cash getDoor] getDoorId]];
	[myRemoteProxy addParamAsInteger: "DepositType" value: [cash getDepositType]];
	[myRemoteProxy addParamAsBoolean: "Deleted" value: [cash isDeleted]];
}

/*ACCEPTORS BY CASH */
/**/
- (void) sendAcceptorsByCash
{
	int i;
	id acceptors;
	id cim;
	
  printd("GenericGetRequest->sendAcceptorsByCash\n");
    
	cim = [[CimManager getInstance] getCim];
	
  if (![myPackage isValidParam: "CashId"]) 
		THROW(TSUP_KEY_NOT_FOUND);

	acceptors = [cim getAcceptorsByCash: [myPackage getParamAsInteger: "CashId"]];

  [myRemoteProxy newResponseMessage];

	if (acceptors) 
		for (i = 0; i < [acceptors size]; ++i)
		{
			[self beginEntity];
			[myRemoteProxy addParamAsInteger: "AcceptorId" value: [[acceptors at: i] getAcceptorId]];
			[self endEntity];
		}
	

	[myRemoteProxy sendMessage];
}


/*BOXES*/
- (void) initSendBoxes
{
 // doLog(0,"GenericGetRequest->initSendBoxes\n");
  
  myReqFacade = [[CimManager getInstance] getCim];
  myEntityList = [myReqFacade getBoxesIdList];
 
  /*parametro del sData aRef se debe cargar para poder 
  utilizarlo dentro de los metodos que devuelven los datos*/     
  if (myReqOperation != LIST_REQ_OP)
    myRef = [myPackage getParamAsInteger: "BoxId"]; 
  
  strcpy(myLoadStr,"sendBoxes");
}

/**/
- (void) sendBoxes
 {
	id box;
	box = [myReqFacade getBoxById: myRef];

  printd("GenericGetRequest->sendBoxes\n");
  
	[myRemoteProxy addParamAsInteger: "BoxId" value: myRef];
	[myRemoteProxy addParamAsString: "Name" value: [box getName]];
	[myRemoteProxy addParamAsString: "Model" value: [[[CimManager getInstance] getCim] getBoxModel]];
	[myRemoteProxy addParamAsBoolean: "Deleted" value: [box isDeleted]];
	// este campo indica si en el equipo ya se realizaron o no movimientos.
	// en base a este campo el CMP permitira o no cambiar el modelo fisico.
	[myRemoteProxy addParamAsBoolean: "HasMovements" value: [[[CimManager getInstance] getCim] hasMovements]];
}

/*ACCEPTORS BY BOX */
/**/
- (void) sendAcceptorsByBox
{
	int i;
	id acceptors;
	id cim;
	
  printd("GenericGetRequest->sendAcceptorsByBox\n");
    
	cim = [[CimManager getInstance] getCim];
	
  if (![myPackage isValidParam: "BoxId"]) 
		THROW(TSUP_KEY_NOT_FOUND);

	acceptors = [cim getAcceptorsByBox: [myPackage getParamAsInteger: "BoxId"]];

  [myRemoteProxy newResponseMessage];

	if (acceptors) 
		for (i = 0; i < [acceptors size]; ++i)
		{
			[self beginEntity];
			[myRemoteProxy addParamAsInteger: "AcceptorId" value: [[acceptors at: i] getAcceptorId]];
			[self endEntity];
		}
	

	[myRemoteProxy sendMessage];
}

/*DOORS BY BOX */
/**/
- (void) sendDoorsByBox
{
	int i;
	id doors;
	id cim;
	
  printd("GenericGetRequest->sendDoorsByBox\n");
    
	cim = [[CimManager getInstance] getCim];
	
  if (![myPackage isValidParam: "BoxId"]) 
		THROW(TSUP_KEY_NOT_FOUND);

	doors = [cim getDoorsByBox: [myPackage getParamAsInteger: "BoxId"]];

  [myRemoteProxy newResponseMessage];

	if (doors) 
		for (i = 0; i < [doors size]; ++i) {
			[self beginEntity];
			[myRemoteProxy addParamAsInteger: "DoorId" value: [[doors at: i] getDoorId]];
			[self endEntity];
		}
	
	[myRemoteProxy sendMessage];

}

/*TELESUP SETTINGS*/
/**/
- (void) initSendTelesupSettings
{
  printd("GenericGetRequest->initSendTelesupSettings\n");
  
  myReqFacade = [TelesupFacade getInstance];
  myEntityList = [myReqFacade getTelesupRolList];
  
  /*parametro del sData aRef se debe cargar para poder 
  utilizarlo dentro de los metodos que devuelven los datos*/     
  if (myReqOperation != LIST_REQ_OP) {

		// Si no me envia el Rol, por default tomo la supervision actualmente en curso
		// y utilizo esta
		if ([myPackage isValidParam: "Rol"])
			myRef = [myPackage getParamAsInteger: "Rol"];
		else if ([myPackage isValidParam: "TelesupId"])
			myRef = [myPackage getParamAsInteger: "TelesupId"];
    else
			myRef = myTelesupRol; 
	}
	
  strcpy(myLoadStr,"sendTelesupSettings");
}

/**/
- (void) sendTelesupSettings
{
  printd("GenericGetRequest->sendTelesupSettings\n");
  
	[myRemoteProxy addParamAsInteger: "TelesupId" value: myRef];
	[myRemoteProxy addParamAsString: "Description" value: [myReqFacade getTelesupParamAsString: "Description" telesupRol: myRef]];
	[myRemoteProxy addParamAsString: "UserName" value: [myReqFacade getTelesupParamAsString: "UserName" telesupRol: myRef]];
	[myRemoteProxy addParamAsString: "Password" value: [myReqFacade getTelesupParamAsString: "Password" telesupRol: myRef]];
	[myRemoteProxy addParamAsString: "RemoteUserName" value: [myReqFacade getTelesupParamAsString: "RemoteUserName" telesupRol: myRef]];
	[myRemoteProxy addParamAsString: "RemotePassword" value: [myReqFacade getTelesupParamAsString: "RemotePassword" telesupRol: myRef]];
	[myRemoteProxy addParamAsString: "SystemId" value: [myReqFacade getTelesupParamAsString: "SystemId" telesupRol: myRef]];
	[myRemoteProxy addParamAsString: "RemoteSystemId" value: [myReqFacade getTelesupParamAsString: "RemoteSystemId" telesupRol: myRef]];
	[myRemoteProxy addParamAsInteger: "TelcoType" value: [myReqFacade getTelesupParamAsInteger: "TelcoType" telesupRol: myRef]];
	[myRemoteProxy addParamAsInteger: "Frequency" value: [myReqFacade getTelesupParamAsInteger: "Frequency" telesupRol: myRef]];
	[myRemoteProxy addParamAsInteger: "StartMoment" value: [myReqFacade getTelesupParamAsInteger: "StartMoment" telesupRol: myRef]];
	[myRemoteProxy addParamAsInteger: "AttemptsQty" value: [myReqFacade getTelesupParamAsInteger: "AttemptsQty" telesupRol: myRef]];
	[myRemoteProxy addParamAsInteger: "TimeBetweenAttempts" value: [myReqFacade getTelesupParamAsInteger: "TimeBetweenAttempts" telesupRol: myRef]];
	[myRemoteProxy addParamAsInteger: "MaxTimeWithoutTelAllowed" value: [myReqFacade getTelesupParamAsInteger: "MaxTimeWithoutTelAllowed" telesupRol: myRef]];
	[myRemoteProxy addParamAsInteger: "ConnectionId1" value: [myReqFacade getTelesupParamAsInteger: "ConnectionId1" telesupRol: myRef]];
	[myRemoteProxy addParamAsInteger: "ConnectionId2" value: [myReqFacade getTelesupParamAsInteger: "ConnectionId2" telesupRol: myRef]];
	[myRemoteProxy addParamAsDateTime: "NextTelesupDateTime" value: [myReqFacade getTelesupParamAsDateTime: "NextTelesupDateTime" telesupRol: myRef]];
	[myRemoteProxy addParamAsDateTime: "LastSuceedTelesupDateTime" value: [myReqFacade getTelesupParamAsDateTime: "LastSuceedTelesupDateTime" telesupRol: myRef]];
	[myRemoteProxy addParamAsString: "Acronym" value: [myReqFacade getTelesupParamAsString: "Acronym" telesupRol: myRef]];
	[myRemoteProxy addParamAsString: "Extension" value: [myReqFacade getTelesupParamAsString: "Extension" telesupRol: myRef]];
	[myRemoteProxy addParamAsInteger: "FromHour" value: [myReqFacade getTelesupParamAsInteger: "FromHour" telesupRol: myRef]];
	[myRemoteProxy addParamAsInteger: "ToHour" value: [myReqFacade getTelesupParamAsInteger: "ToHour" telesupRol: myRef]];
	[myRemoteProxy addParamAsBoolean: "Scheduled" value: [myReqFacade getTelesupParamAsInteger: "Scheduled" telesupRol: myRef]]; 	
	[myRemoteProxy addParamAsDateTime: "NextSecondaryTelesupDateTime" value: [myReqFacade getTelesupParamAsDateTime: "NextSecondaryTelesupDateTime" telesupRol: myRef]];
	[myRemoteProxy addParamAsInteger: "Frame" value: [myReqFacade getTelesupParamAsInteger: "Frame" telesupRol: myRef]];
	[myRemoteProxy addParamAsInteger: "CabinIdleWaitTime" value: [myReqFacade getTelesupParamAsInteger: "CabinIdleWaitTime" telesupRol: myRef]];    	
	[myRemoteProxy addParamAsBoolean: "InformDepositsByTransaction" value: [myReqFacade getTelesupParamAsBoolean: "InformDepositsByTransaction" telesupRol: myRef]];
	[myRemoteProxy addParamAsBoolean: "InformExtractionsByTransaction" value: [myReqFacade getTelesupParamAsBoolean: "InformExtractionsByTransaction" telesupRol: myRef]];
	[myRemoteProxy addParamAsBoolean: "InformAlarmsByTransaction" value: [myReqFacade getTelesupParamAsBoolean: "InformAlarmsByTransaction" telesupRol: myRef]];
	[myRemoteProxy addParamAsBoolean: "InformZCloseByTransaction" value: [myReqFacade getTelesupParamAsBoolean: "InformZCloseByTransaction" telesupRol: myRef]];

}

/*SETEOS DE CONECCIONES*/
/**/
- (void) initSendConnectionSettings
{
  printd("GenericGetRequest->initSendConnectionSettings\n");
  
  myReqFacade = [TelesupFacade getInstance];
  myEntityList = [myReqFacade getConnectionIdList];
  
  /*parametro del sData aRef se debe cargar para poder 
  utilizarlo dentro de los metodos que devuelven los datos*/     
  if (myReqOperation != LIST_REQ_OP)
    myRef = [myPackage getParamAsInteger: "ConnectionId"]; 
  
  strcpy(myLoadStr,"sendConnectionSettings");
}

/**/
- (void) sendConnectionSettings
{
  printd("GenericGetRequest->sendConnectionSettings\n");
  
	[myRemoteProxy addParamAsInteger: "ConnectionId" value: myRef];
	[myRemoteProxy addParamAsString: "Description" value: [myReqFacade getConnectionParamAsString: "Description" connectionId: myRef]];
	[myRemoteProxy addParamAsInteger: "Type" value: [myReqFacade getConnectionParamAsInteger: "Type" connectionId: myRef]];
	[myRemoteProxy addParamAsInteger: "PortType" value: [myReqFacade getConnectionParamAsInteger: "PortType" connectionId: myRef]];
	[myRemoteProxy addParamAsInteger: "PortId" value: [myReqFacade getConnectionParamAsInteger: "PortId" connectionId: myRef]];
	[myRemoteProxy addParamAsString: "ModemPhoneNumber" value: [myReqFacade getConnectionParamAsString: "ModemPhoneNumber" connectionId: myRef]];
	[myRemoteProxy addParamAsInteger: "RingsQty" value: [myReqFacade getConnectionParamAsInteger: "RingsQty" connectionId: myRef]];
	[myRemoteProxy addParamAsString: "Domain" value: [myReqFacade getConnectionParamAsString: "Domain" connectionId: myRef]];
	[myRemoteProxy addParamAsString: "IP" value: [myReqFacade getConnectionParamAsString: "IP" connectionId: myRef]];	
	[myRemoteProxy addParamAsInteger: "TCPPortSource" value: [myReqFacade getConnectionParamAsInteger: "TCPPortSource" connectionId: myRef]];
	[myRemoteProxy addParamAsInteger: "TCPPortDestination" value: [myReqFacade getConnectionParamAsInteger: "TCPPortDestination" connectionId: myRef]];
	[myRemoteProxy addParamAsInteger: "PPPConnectionId" value: [myReqFacade getConnectionParamAsInteger: "PPPConnectionId" connectionId: myRef]];
	[myRemoteProxy addParamAsString: "ISPPhoneNumber" value: [myReqFacade getConnectionParamAsString: "ISPPhoneNumber" connectionId: myRef]];
	[myRemoteProxy addParamAsString: "UserName" value: [myReqFacade getConnectionParamAsString: "UserName" connectionId: myRef]];
	[myRemoteProxy addParamAsString: "Password" value: [myReqFacade getConnectionParamAsString: "Password" connectionId: myRef]];
	[myRemoteProxy addParamAsInteger: "Speed" value: [myReqFacade getConnectionParamAsInteger: "Speed" connectionId: myRef]]; 	
	[myRemoteProxy addParamAsInteger: "ConnectBy" value: [myReqFacade getConnectionParamAsInteger: "ConnectBy" connectionId: myRef]]; 	
	[myRemoteProxy addParamAsString: "DomainSup" value: [myReqFacade getConnectionParamAsString: "DomainSup" connectionId: myRef]];

}

/*VERSION*/
/**/
- (void) sendVersion
{
	[myRemoteProxy newResponseMessage];
	[myRemoteProxy addParamAsString: "AppVersion" value: APP_VERSION_STR];
	[myRemoteProxy addParamAsString: "AppRelease" value: APP_RELEASE_DATE];
	[myRemoteProxy sendMessage];
}   



/**/
- (void) initSendSystemInfo
{
  printd("GenericGetRequest->initSendSystemInfo\n");

  strcpy(myLoadStr,"sendSystemInfo");
}

#define LAST_APP_UPDATE_EXEC BASE_APP_PATH "/telesup/lastAppUpdateExec.txt"

/**/
- (void) sendSystemInfo
{
	char aux[100];
	long total, free;
	float percUsed;
	FILE *f;
	char buf[50];
	datetime_t appUpdateDate = 0;
	char ipAddress[20];
	char netMask[20];
	char gateway[20];
	char dhcp[20];
	int sPercent;
	char gsmSignal[30];
	
	char *kernelVersion = getKernelVersion();
	  
  [myRemoteProxy addParamAsInteger: "VersionType" value: 0];
  [myRemoteProxy addParamAsString: "VersionTypeName" value: "DELSAT"];
  [myRemoteProxy addParamAsString: "VersionNumber" value: APP_VERSION_STR];
  [myRemoteProxy addParamAsString: "Release" value: APP_RELEASE_DATE];
  [myRemoteProxy addParamAsString: "OSVersion" value: ((kernelVersion != NULL) ? kernelVersion: "NO DISPONIBLE")];
	
#ifndef _WIN32      
	if ( getFileSystemInfo(BASE_PATH "", &total, &free) == 0 ) {
		percUsed = (float)(total-free)/(float)total*100.0;
		sprintf(aux, "%.1f%%", percUsed );      
	} else
#endif
	sprintf(aux, "NO DISPONIBLE" );
	[myRemoteProxy addParamAsString: "FlashMemoryUsage" value: aux];
	
	f = fopen( LAST_APP_UPDATE_EXEC, "r" );

	if (f) {
		fgets(buf, 40, f);
		appUpdateDate = atoi(buf) - [SystemTime getTimeZone];
		fclose(f);
	}	
	
//	doLog(0,"fecha de actualizacion = %s\n", formatDateTimeComplete(appUpdateDate, aux));
	
	[myRemoteProxy addParamAsDateTime: "UpdateDate" value: appUpdateDate];   

	[myRemoteProxy addParamAsString: "EqType" value: "CIM"];   

/*
#ifndef _WIN32        
	[myRemoteProxy addParamAsString: "EqType" value: "CT8016"];   
#else
	[myRemoteProxy addParamAsString: "EqType" value: "WINCAB"];   
#endif 	
*/

	[myRemoteProxy addParamAsBoolean: "HasMainTelesup" value: [[TelesupScheduler getInstance] getMainTelesup] != NULL];

	// version de hw
	[SafeBoxHAL getCimVersion: aux];
	[myRemoteProxy addParamAsString: "HardwareVersion" value: aux];

	// power status
	switch ([SafeBoxHAL getPowerStatus]) { 

		case PowerStatus_EXTERNAL:
					strcpy(aux, getResourceStringDef(RESID_POWERSTATUS_EXTERNAL, "Externa"));
					break;

		case PowerStatus_BACKUP:
					strcpy(aux, getResourceStringDef(RESID_POWERSTATUS_BACKUP, "De respaldo"));
					break;

		default: strcpy(aux, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE")); break;

  }

	[myRemoteProxy addParamAsString: "PowerStatus" value: aux];

	// system status

	switch ([SafeBoxHAL getHardwareSystemStatus]) {
 
		case HardwareSystemStatus_PRIMARY:
					strcpy(aux, getResourceStringDef(RESID_SYSTEMSTATUS_PRIMARY, "Primaria"));
					break;

		case HardwareSystemStatus_SECONDARY:
					strcpy(aux, getResourceStringDef(RESID_SYSTEMSTATUS_SECONDARY, "Secundaria"));
					break;

		default: strcpy(aux, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE")); break;

  }

	[myRemoteProxy addParamAsString: "SystemStatus" value: aux];

	// battery status

	switch ([SafeBoxHAL getBatteryStatus]) { 

		case BatteryStatus_LOW:
					strcpy(aux, getResourceStringDef(RESID_BATTERYSTATUS_LOW, "Baja"));
					break;

		case BatteryStatus_REMOVED:
					strcpy(aux, getResourceStringDef(RESID_BATTERYSTATUS_REMOVED, "Removida"));
					break;

		case BatteryStatus_OK:
					strcpy(aux, getResourceStringDef(RESID_BATTERYSTATUS_OK, "OK"));
					break;

		default: strcpy(aux, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE")); break;
  }

	[myRemoteProxy addParamAsString: "BatteryStatus" value: aux];

	//loadIPConfig(dhcp, ipAddress, netMask, gateway);

	[[CimGeneralSettings getInstance] getIpAddress: ipAddress];
	[myRemoteProxy addParamAsString: "IP" value: ipAddress];
	[[CimGeneralSettings getInstance] getNetMask: netMask];
	[myRemoteProxy addParamAsString: "Mask" value: netMask];
	[[CimGeneralSettings getInstance] getGateway: gateway];
	[myRemoteProxy addParamAsString: "Gateway" value: gateway];

	// senial de modulo GSM
	sPercent = [[ReportXMLConstructor getInstance] getSignalPercent];

	// -2 NO DISPONIBLE
	// -1 SIN SENIAL
	// > 0 PORCENTAJE DE SENIAL
	if ( sPercent == -2 ) {
		strcpy(gsmSignal, getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE"));
	} else if ( sPercent == -1 ) {
			strcpy(gsmSignal, getResourceStringDef(RESID_NO_SIGNAL, "SIN SENAL"));
	} else { 
			sprintf(buf, "%d%s", sPercent, "%");
			strcpy(gsmSignal, buf);
	}

	[myRemoteProxy addParamAsString: "GSMSignal" value: gsmSignal];
	

} 

/**/
- (void) sendCurrentBalance
{
	COLLECTION currentExtractions, cimCashs, acceptorSettingsList, detailsByCimCash;
	COLLECTION detailsByAcceptor, currecies, detailsByCurrency;
	CIM_CASH cimCash;
	ACCEPTOR_SETTINGS acceptorSettings;
	CURRENCY currency;
	EXTRACTION lastExtraction;
	int i, iCash, iAcceptor, iCurrency, iDetail;
	EXTRACTION_DETAIL extractionDetail;

  [myRemoteProxy newResponseMessage];

  currentExtractions = [[ExtractionManager getInstance] getCurrentExtractions];

	for(i=0; i < [currentExtractions size]; i++) {
	
    lastExtraction = [currentExtractions at: i];
    
    // Obtengo la lista de cashs
	  cimCashs = [lastExtraction getCimCashs: NULL];
  
    // Recorro la lista de cashs
	  for (iCash = 0; iCash < [cimCashs size]; ++iCash) {
        
        cimCash = [cimCashs at: iCash];
        
    		// Obtengo los depositos para el cash actual
    		detailsByCimCash = [lastExtraction getDetailsByCimCash: NULL cimCash: cimCash];
    
    		// Obtengo la lista  de validadores
    		acceptorSettingsList = [lastExtraction getAcceptorSettingsList: detailsByCimCash];
    
    		// Recorro la lista de validadores
    		for (iAcceptor = 0; iAcceptor < [acceptorSettingsList size]; ++iAcceptor) {
    		    
          acceptorSettings = [acceptorSettingsList at: iAcceptor];
    		
    			// Obtengo la lista de detalles para el validador en curso
    			detailsByAcceptor = [lastExtraction getDetailsByAcceptorSettings: detailsByCimCash acceptorSettings: acceptorSettings];
    
    			// Obtengo la lista de monedas
    			currecies = [lastExtraction getCurrencies: detailsByAcceptor];
          
    			// Recorro la lista de monedas
    			for (iCurrency = 0; iCurrency < [currecies size]; ++iCurrency) {
    
    				currency = [currecies at: iCurrency];
    				detailsByCurrency = [lastExtraction getDetailsByCurrency: detailsByAcceptor currency: currency];          
              		
    				for (iDetail = 0; iDetail < [detailsByCurrency size]; ++iDetail) {
    			
    					extractionDetail = [detailsByCurrency at: iDetail];              		
              		
    					if (![extractionDetail isUnknownBill]){
                [self beginEntity];
      					[myRemoteProxy addParamAsInteger: "AcceptorId" value: [acceptorSettings getAcceptorId]];
      					[myRemoteProxy addParamAsInteger: "CurrencyId" value: [currency getCurrencyId]];
      					[myRemoteProxy addParamAsInteger: "Qty" value: [extractionDetail getQty]];
  							[myRemoteProxy addParamAsCurrency: "Amount" value: [extractionDetail getAmount]];
      					[self endEntity];
    					}
  					}
						[detailsByCurrency free];
  				}
					[currecies free];
					[detailsByAcceptor free];
  			}
				[acceptorSettingsList free];
				[detailsByCimCash free];
    }
		[cimCashs free];

  }

	[myRemoteProxy sendMessage];

}

/**/
- (void) loginRemoteUser
{
  id user = NULL;
  char loginName[20];
  char password[20];
	SecurityLevel secLevel;

  if ((![myPackage isValidParam: "LoginName"]) || (![myPackage isValidParam: "Password"]))
	THROW(TSUP_KEY_NOT_FOUND);

  strcpy(loginName, [myPackage getParamAsString: "LoginName"]);
  strcpy(password, [myPackage getParamAsString: "Password"]);

  TRY
  	user = [[UserManager getInstance] validateRemoteUser: loginName password: password];
  	assert(user);

		secLevel = [[[UserManager getInstance] getProfile: [user getUProfileId]] getSecurityLevel];

  	[myRemoteProxy newResponseMessage];
 	  [myRemoteProxy addParamAsInteger: "ProfileId" value: [user getUProfileId]];
    [myRemoteProxy addParamAsString: "UserName" value: [user getFullName]];
		if (secLevel != SecurityLevel_0)
   		[myRemoteProxy addParamAsBoolean: "IsTemporaryPassword" value: [user isTemporaryPassword]];
		else [myRemoteProxy addParamAsBoolean: "IsTemporaryPassword" value: FALSE];
 	  [myRemoteProxy sendMessage];

  CATCH
    
    	if ([[Acceptor getInstance] getCantLoginFails] < 3)
	   RETHROW();
    
    	[myRemoteProxy newResponseMessage];
    	[myRemoteProxy addParamAsBoolean: "HasToLogout" value: TRUE];
    	[myRemoteProxy sendMessage];
  	
  END_TRY
  
  [[Acceptor getInstance] setRemoteCurrentUser: user];

}

/**/
- (void) executeRequest 
{	 
  SEL aSel;
  
  printd("GenericGetRequest->executeRequest\n");						           
  
  /*seleccion del metodo a ejecutar */ 
  switch (myReqType) {
  
    case GET_COMMERCIAL_STATE_REQ:
      [self initSendCommercialState];
      break;
    
    case GET_REGIONAL_SETTINGS_REQ:
      [self initSendRegionalSettings];
      break;                  

    case GET_GENERAL_BILL_REQ:
      [self initSendGeneralBill];
      break;

		case GET_CIM_GENERAL_SETTINGS_REQ:
			[self initSendCimGeneralSettings];
			break;

		case GET_DOOR_REQ:
			[self initSendDoors];
			break;

		case GET_ACCEPTOR_REQ:
			[self initSendAcceptors];
			break;

		case GET_CURRENCY_DENOMINATION_REQ:
			// este es especial por eso es return
			[self sendCurrencyDenominations];
			return;

        case GET_DENOMINATION_LIST_REQ:
			// este es especial por eso es return
            printf("GetDenomnationList\n");
			[self sendDenominationList];
			return;

		case GET_DEPOSIT_VALUE_TYPE_REQ:
			// este es especial por eso es return
			[self sendDepositValueTypes];
			return;

		case GET_DEPOSIT_VALUE_TYPE_CURRENCY_REQ:
			// este es especial por eso es return
			[self sendDepositValueTypeCurrencies];
			return;

		case GET_CURRENCY_REQ:
			[self initSendCurrencies];
			return;

		case GET_CURRENCY_BY_ACCEPTOR_REQ:
			[self initSendCurrenciesByAcceptor];
			return;

		case GET_CASH_BOX_REQ:
			[self initSendCashBoxes];
			break;

		case GET_ACCEPTORS_BY_CASH_REQ:
			// este es especial por eso es return
			[self sendAcceptorsByCash];
			return;

		case GET_BOX_REQ:
			[self initSendBoxes];
			break;

		case GET_ACCEPTORS_BY_BOX_REQ:
			[self sendAcceptorsByBox];		
			return;

		case GET_DOORS_BY_BOX_REQ:
			[self sendDoorsByBox];		
			return;

    case GET_PRINT_SYSTEM_REQ:
      [self initSendPrintingSystem];
      break;
  
    case GET_AMOUNT_MONEY_REQ:
      [self initSendAmountMoney];
      break;
 
    case GET_USER_REQ:
      [self sendUsers];
      return;

    case GET_TELESUP_SETTINGS_REQ:
      [self initSendTelesupSettings];
      break;
      
    case GET_CONNECTION_REQ:
      [self initSendConnectionSettings];
      break;

  	case GET_USER_PROFILE_REQ:
      [self initSendUserProfiles];
      break;

    case GET_USER_WITH_CHILDREN_REQ:
      [self sendUsersWithChildren];
      return;
      
  	case GET_USER_PROFILE_CHILDREN_REQ:
      [self sendProfilesWithChildren];
      return;

  	case GET_OPERATION_REQ:
      [self sendOperations];
      return;

  	case GET_CASH_REFERENCE_REQ:
      [self sendCashReferences];
      return;
      
    case GET_VERSION_REQ:
      [self sendVersion];
      return;                                                      
 
    case GET_SYSTEM_INFO_REQ:
      [self initSendSystemInfo];
      break;

    case GET_CURRENT_BALANCE_REQ:
			[Audit auditEvent: Event_STATUS_ACCOUNT_REQUEST additional: "" station: 0 logRemoteSystem: TRUE]; 		
      [self sendCurrentBalance];
      return;

    case GET_DOORS_BY_USER_REQ:
      [self sendDoorsByUser];
      return;

    case GET_DOORS_BY_USERS_REQ:
      [self sendDoorsByUsers];
      return;      

    case GET_DUAL_ACCESS_REQ:
      [self sendDualAccess];
			return;

		case LOGIN_REMOTE_USER_REQ:
			[self loginRemoteUser];
			return;

    case GET_REPAIR_ORDER_REQ:
      [self sendRepairOrderItems];
      return;

    default:
   //   doLog(0,"Invalid Message!!!\n ");
      return;

  }
   
  /*ejecucion propia del request*/
  [myRemoteProxy newResponseMessage];
  
  /*solicitaron un listado*/
  if (myReqOperation == LIST_REQ_OP) 	
		[self sendRequestDataList];	
  else {
    /*solicitaron un solo registro o se trata de un parametro*/
    aSel = [self findSel: myLoadStr];
    [self perform: aSel];
	}
	
	[myRemoteProxy sendMessage];
}

/**/
- (void) loadPackage: (char*) aMessage
{
	[myPackage loadPackage: aMessage];
}

@end
