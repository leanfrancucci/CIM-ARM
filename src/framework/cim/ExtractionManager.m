#include "ExtractionManager.h"
#include "UserManager.h"
#include "Persistence.h"
#include "CurrencyManager.h"
#include "CimManager.h"
#include "DepositDAO.h"
#include "ReportXMLConstructor.h"
#include "PrinterSpooler.h"
#include "system/util/all.h"
#include "ExtractionDAO.h"
#include "CimAudits.h"
#include "TelesupScheduler.h"
#include "TelesupervisionManager.h"
#include "CimGeneralSettings.h"
#include "CimManager.h"
#include "ZCloseDAO.h"
#include "ZCloseManager.h"
#include "MessageHandler.h"
#include "CommercialStateMgr.h"
#include "CashReferenceManager.h"
#include "BagTrack.h"

//#define LOG(args...) doLog(0,args)

@implementation ExtractionManager

static EXTRACTION_MANAGER singleInstance = NULL;

- (EXTRACTION) loadExtraction: (DOOR) aDoor;
- (void) addCurrentCashClosesToExtraction: (EXTRACTION) anExtraction;

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}

/**/
+ getInstance
{
  return [self new];
}
 
/**/
- initialize
{
	// Por cada puerta existente, carga la extraccion actual
	myCurrentExtractions = [Collection new];

	myLastExtractionNumber = [[[Persistence getInstance] getExtractionDAO] getLastExtractionNumber];

	[self loadExtractions];

	myIsGeneratingExtraction = FALSE;

	return self;
}

/**/
- (COLLECTION) getCashsForDoor: (DOOR) aDoor
{
	COLLECTION cimCashs = [[[CimManager getInstance] getCim] getCimCashs];
	COLLECTION list = [Collection new];
	int i;
	
	// De todos los cash existentes, paso a una lista a los que estan dentro de esa puerta
	for (i = 0; i < [cimCashs size]; ++i) {
		if ([[cimCashs at: i] getDoor] == aDoor) 
			[list add: [cimCashs at: i]];
	}

	return list;
}

/**/
- (void) loadExtractions
{
	int i;
	COLLECTION doors;
	EXTRACTION extraction;

	doors = [[[CimManager getInstance] getCim] getDoors];

	[myCurrentExtractions freeContents];
	for (i = 0; i < [doors size]; ++i) {

//		if ([[doors at: i] getDoorType] == DoorType_COLLECTOR) {
			extraction = [self loadExtraction: [doors at: i]];
			[myCurrentExtractions add: extraction];
//		}

#ifdef __DEBUG_CIM
//			for (j = 0; j < [breakdownList size]; ++j) [[breakdownList at: j] debug];
#endif

	}

}


/*
	Algoritmo general:
	
		1) Buscar la ultima extraccion efectuada de la puerta pasada como parametro.
		2) Obtener el numero del ultimo deposito (tengo que buscar a partir de ese mas 1).
		3) Comenzar la busqueda de depositos a partir de este ID.
		4) Solo incluir aquellos depositos cuya DOOR_ID coincide con la puerta pasada como parametro.
	
		Notas: - el FromId debe quedar como el primer deposito hecho en esa puerta.
 					 - el ToId debe quedar como el ultimo deposito hecho en esa puerta.

*/
- (EXTRACTION) loadExtraction: (DOOR) aDoor
{
	EXTRACTION extraction;
	unsigned long fromDepositNumber = 0;
	unsigned long toDepositNumber = 0;
	unsigned long number;
	ABSTRACT_RECORDSET depositRS;
	ABSTRACT_RECORDSET depositDetailRS;
	int doorId;
	ACCEPTOR_SETTINGS acceptorSettings;
	CURRENCY currency;
	CURRENCY_MANAGER currencyManager;
	CIM_MANAGER cimManager;
	unsigned long ticks;
	CURRENCY lastCurrency = NULL;
	EXTRACTION lastExtraction;
	BOOL hasDeposit = TRUE;
	CIM_CASH cimCash;
	money_t amount;
	unsigned long fromCloseNumber = 0;
	COLLECTION cashCloses;
	ZCLOSE cashClose;
	int i;
	COLLECTION list;
	CASH_REFERENCE_MANAGER cashReferenceManager;
	CASH_REFERENCE cashReference;

	// Obtengo los objetos que luego voy a utilizar

	currencyManager = [CurrencyManager getInstance];
	cimManager = [CimManager getInstance];
	cashReferenceManager = [CashReferenceManager getInstance];

	doorId = [aDoor getDoorId];

	extraction = [Extraction new];
	[extraction setDoor: aDoor];

	depositRS = [[[Persistence getInstance] getDepositDAO] getNewDepositRecordSet];
	[depositRS open];

	depositDetailRS = [[[Persistence getInstance] getDepositDAO] getNewDepositDetailRecordSet];
	[depositDetailRS open];

	lastExtraction = [[[Persistence getInstance] getExtractionDAO] loadLastFromDoor: [aDoor getDoorId]];

	// Si existe una ultima extraccion para la puerta indicada, entonces tengo que localizar
	// el deposito siguiente al ultimo efectuado en esa extraccion.
	// Si no existe una ultima extraccion para esa puerta, recorro desde el principio

	if (lastExtraction != NULL) {
		fromCloseNumber = [lastExtraction getToCloseNumber] + 1;
	}

	if (lastExtraction != NULL && [lastExtraction getToDepositNumber] > 0) {
		fromDepositNumber = [lastExtraction getToDepositNumber] + 1;
		hasDeposit = [depositRS findById: "NUMBER" value: fromDepositNumber];
		    //************************* logcoment
    //doLog(0,"ExtractionManager -> buscando a partir del dep %ld, hay dep? = %d\n", fromDepositNumber, hasDeposit);
	} else {
		[depositRS moveFirst];
			    //************************* logcoment
		//doLog(0,"ExtractionManager -> buscando desde primer dep\n");
	}

	[depositDetailRS moveFirst];

	ticks = getTicks();

	// Recorro hasta el fin del recordset de depositos

	while (hasDeposit && ![depositRS eof]) {
        
		// Solo me interesan los depositos de la puerta seleccionada
		if ([depositRS getShortValue: "DOOR_ID"] == doorId) {

			// Asigno el numero de deposito inicial (si corresponde) y final
			number = [depositRS getLongValue: "NUMBER"];
			if (fromDepositNumber == 0) fromDepositNumber = number;
			toDepositNumber = number;

			// cargo en memoria la cantidad de depositos manuales que hay en el buzon
			if ([depositRS getCharValue: "DEPOSIT_TYPE"] == DepositValueType_MANUAL_CASH)
			   [extraction incCurrentManualDepositCount];

			cimCash = [cimManager getCimCashById: [depositRS getShortValue: "CIM_CASH_ID"]];
			cashReference = NULL;
			if ([depositRS getShortValue: "REFERENCE_ID"] != 0) 
				cashReference = [cashReferenceManager getCashReferenceById: [depositRS getShortValue: "REFERENCE_ID"]];

			// Verifico si tiene detalles, en primer lugar me fijo si ya estoy parado
			// en el detalle correspondiente (muy probablemente) y sino lo busco
			// Luego recorro cada uno de los detalles mientras el numero de deposito coincida.
			if ((![depositDetailRS eof] && [depositDetailRS getLongValue: "NUMBER"] == number) ||
					[depositDetailRS findFirstById: "NUMBER" value: number]) {

				while (![depositDetailRS eof] && [depositDetailRS getLongValue: "NUMBER"] == number) {

					// Esto es una especide de "cache" de moneda, para no tener que ir a buscarla todo
					// el tiempo ya que es muy probable que sea la misma que la anterior
					if (lastCurrency != NULL && [lastCurrency getCurrencyId] == [depositDetailRS getShortValue: "CURRENCY_ID"]) {
						currency = lastCurrency;
					} else {
						currency = [currencyManager getCurrencyById: [depositDetailRS getShortValue: "CURRENCY_ID"]];
						lastCurrency = currency;
					}

					acceptorSettings = [cimManager getAcceptorSettingsById: [depositDetailRS getShortValue: "ACCEPTOR_ID"]];

					// Agrego el detalle de la extraccion
					[extraction addExtractionDetail: cimCash
						acceptorSettings: acceptorSettings
						depositValueType: [depositDetailRS getCharValue: "DEPOSIT_VALUE_TYPE"]
						currency: currency
						qty: [depositDetailRS getShortValue: "QTY"]
						amount: [depositDetailRS getMoneyValue: "AMOUNT"]
						cashReference: cashReference];

					// Agrego el detalle al cierre de cash (cierre parcial)
					if ([depositDetailRS getCharValue: "DEPOSIT_VALUE_TYPE"] == DepositValueType_VALIDATED_CASH)
						amount = [depositDetailRS getMoneyValue: "AMOUNT"] * [depositDetailRS getShortValue: "QTY"];
					else
						amount = [depositDetailRS getMoneyValue: "AMOUNT"];

					[depositDetailRS moveNext];

				}

			}

		}

		[depositRS moveNext];

	}

	[extraction setFromDepositNumber: fromDepositNumber];
	[extraction setToDepositNumber: toDepositNumber];

	[depositRS close];
	[depositRS free];
	[depositDetailRS close];
	[depositDetailRS free];
	if (lastExtraction) [lastExtraction free];


	// si esta habilitado el uso de fin de dia cargo los cierres a la extraccion

	if ([[CimGeneralSettings getInstance] getUseEndDay]) {

		list = [self getCashsForDoor: [extraction getDoor]];
	
		// Busco todos los cash close correspondientes
		cashCloses = [[ZCloseManager getInstance] loadCashCloses: list
			fromCloseNumber: fromCloseNumber
			toCloseNumber: 0];
	
		// Agrego los resultados a la extraccion
		for (i = 0; i < [cashCloses size]; ++i) {
			[extraction addCashClose: [cashCloses at: i]];
		}
	
		// Agrego los cash close actuales a la extraccion
		for (i = 0; i < [list size]; ++i) {
			cashClose = [[ZCloseManager getInstance] getCurrentCashCloseForCimCash: [list at: i]];
			[extraction addCashClose: cashClose];
		}
	
		[list free];
		[cashCloses free];

	}

#ifdef __DEBUG_CIM
	[extraction debug];
#endif

	return extraction;
}

/**/
- (EXTRACTION) getCurrentExtraction: (DOOR) aDoor
{
	int i;

	for (i = 0; i < [myCurrentExtractions size]; ++i) {
		if ([[myCurrentExtractions at: i] getDoor] == aDoor)
			return [myCurrentExtractions at: i];
	}

	return NULL;
}

/**/
- (COLLECTION) getCurrentExtractions
{
  return myCurrentExtractions;
}

/**/
- (void) processDeposit: (DEPOSIT) aDeposit
{
	COLLECTION depositDetails;
	DEPOSIT_DETAIL depositDetail;
	EXTRACTION extraction;
	int i;

	THROW_NULL(aDeposit);

	// Obtengo la extraccion para la puerta en la cual se efectuo el deposito
	extraction = [self getCurrentExtraction: [aDeposit getDoor]];
	THROW_NULL(extraction);
	depositDetails = [aDeposit getDepositDetails];
	[extraction addRejectedQty: [aDeposit getRejectedQty]];

	// incremento la cantidad de sobres en buzon
	if ([aDeposit getDepositType] == DepositType_MANUAL)
	  [extraction incCurrentManualDepositCount];

	// Configuro el numero de deposito desde (si es que no existe)
	// y el numero de deposito hasta
	if ([extraction getFromDepositNumber] == 0) {
		[extraction setFromDepositNumber: [aDeposit getNumber]];
	}	
	[extraction setToDepositNumber: [aDeposit getNumber]];

	// Proceso cada uno de los detalles y los agrego a los detalles de
	// la extraccion
	for (i = 0; i < [depositDetails size]; ++i) {

		depositDetail = [depositDetails at: i];

		// Agrego el detalle a la extraccion
		[extraction addExtractionDetail: [aDeposit getCimCash]
			acceptorSettings: [depositDetail getAcceptorSettings]
			depositValueType: [depositDetail getDepositValueType]
			currency: [depositDetail getCurrency]
			qty: [depositDetail getQty]
			amount: [depositDetail getAmount]
			cashReference: [aDeposit getCashReference]];

	}

}

/**/
- (void) processTempDepositDetail: (DEPOSIT) aDeposit depositDetail: (DEPOSIT_DETAIL) aDepositDetail
{

	EXTRACTION extraction;

	// Obtengo la extraccion para la puerta en la cual se efectuo el deposito
	extraction = [self getCurrentExtraction: [aDeposit getDoor]];
	THROW_NULL(extraction);

	// Agrego el detalle a la extraccion
	[extraction addExtractionDetail: [aDeposit getCimCash]
		acceptorSettings: [aDepositDetail getAcceptorSettings]
		depositValueType: [aDepositDetail getDepositValueType]
		currency: [aDepositDetail getCurrency]
		qty: [aDepositDetail getQty]
		amount: [aDepositDetail getAmount]
		cashReference: [aDeposit getCashReference]];

}

/**/
- (unsigned long) generateExtraction: (DOOR) aDoor user1: (USER) aUser1 user2: (USER) aUser2 bagNumber: (char*) aBagNumber bagTrackingMode: (int) aBagTrackingMode
{
	EXTRACTION extraction;
	scew_tree *tree;
	char additional[20];
	id telesup;
	unsigned long auditNumber = 0;
	datetime_t auditDateTime = 0;	
  CashReportParam cashParam;
	datetime_t now;
	COLLECTION acceptorsList;
	int i;

    printf("myIsGeneratingExtraction = TRUE\n");
	myIsGeneratingExtraction = TRUE;

	now = [SystemTime getLocalTime];
    printf("generate 1\n");
	extraction = [self getCurrentExtraction: aDoor];
	THROW_NULL(extraction);
    printf("generate 2\n");
	// Controlo si me configuraron un proximo numero de extraccion
	if ([[CimGeneralSettings getInstance] getNextExtractionNumber] > myLastExtractionNumber) {
		myLastExtractionNumber = [[CimGeneralSettings getInstance] getNextExtractionNumber] - 1;
	}

	if ([[CimGeneralSettings getInstance] getUseEndDay]) 
		[[ZCloseManager getInstance] generateCashCloseForDoor: aDoor user: aUser1 closeTime: now];
    printf("generate 3\n");
	// Numero de cuenta bancaria
	[extraction setBankAccountInfo: [[CimGeneralSettings getInstance] getDefaultBankInfo]];

	// Configuro el numero de extraccion
	[extraction setNumber: myLastExtractionNumber + 1];

	// Configuro la fecha/hora de la extraccion
	[extraction setDateTime: now];

	// Configuro el usuario 1
	[extraction setOperator: aUser1];

	// Configuro el usuario 2
	[extraction setCollector: aUser2];
    printf("generate 4\n");
	// inicializo las alarmas de stacker full y warning de la extraccion y de los acceptors
	// detras de la puerta
	[extraction setHasEmitStackerFull: FALSE];
	[extraction setHasEmitStackerWarning: FALSE];
	 printf("generate 5\n");
	acceptorsList = [[[CimManager getInstance] getCim] getAcceptors];
	for (i = 0; i < [acceptorsList size]; ++i) {
		[[acceptorsList at: i] setHasEmitStackerFull: FALSE];
		[[acceptorsList at: i] setHasEmitStackerWarning: FALSE];
	}
    printf("generate 6\n");
	// setea el numero de bolsa
	[extraction setBagNumber: aBagNumber];

	// Guardo la extraccion
	[[[Persistence getInstance] getExtractionDAO] store: extraction];
    printf("generate 7\n");
	// Audito el evento
	auditDateTime = [SystemTime getLocalTime];
	sprintf(additional, "%s %ld", getResourceStringDef(RESID_REPRINT_DEPOSIT_DESC, "Retiro"), [extraction getNumber]);
	auditNumber = [Audit auditEvent: aUser1 eventId: AUDIT_CIM_EXTRACTION additional: additional
		station: [[extraction getDoor] getDoorId] logRemoteSystem: FALSE];

	cashParam.cash = NULL;
	cashParam.detailReport = FALSE;
  cashParam.auditNumber = auditNumber;
	cashParam.auditDateTime = auditDateTime;
	cashParam.showBagNumber = (aBagTrackingMode != BagTrackingMode_NONE);

	if ([[[CimManager getInstance] getCim] isTransferenceBoxMode]) {
		tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: TRANS_BOX_MODE_EXTRACTION_PRT isReprint: FALSE varEntity: &cashParam];
		[[PrinterSpooler getInstance] addPrintingJob: TRANS_BOX_MODE_EXTRACTION_PRT 
			copiesQty: [[CimGeneralSettings getInstance] getExtractionCopiesQty]
			ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
	} else {
		tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: EXTRACTION_PRT isReprint: FALSE varEntity: &cashParam];
		[[PrinterSpooler getInstance] addPrintingJob: EXTRACTION_PRT 
			copiesQty: [[CimGeneralSettings getInstance] getExtractionCopiesQty]
			ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
	}
    printf("generate 8\n");
	if (aBagTrackingMode != BagTrackingMode_NONE) {
		[self storeBagTrackHeader: extraction bagNumber: aBagNumber bagTrackingMode: aBagTrackingMode];
	}

#ifdef __CIM_DEBUG
	[extraction debug];
#endif
	
	// Obtengo el ultimo numero de extraccion
	myLastExtractionNumber++;
printf("generate 9\n");
	// Limpio la extraccion (resetea los valores en 0)
	[extraction clear];
printf("generate 10\n");
	[self addCurrentCashClosesToExtraction: extraction];
printf("generate 11\n");
	
	printf("aBagTrackingMode = %d, aBagTrackingMode\n");

        /* supervisa si:
		1.existe la supervision
		2.puede ejecutar el modulo
		3.el modulo tiene configurado online
		4.esta configurada online el envio de extracciones en la telesup
		*/
	
/*
	if (aBagTrackingMode == BagTrackingMode_NONE || aBagTrackingMode == BagTrackingMode_AUTO) {


		telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];

	if ([[CommercialStateMgr getInstance] canExecuteModule: ModuleCode_SEND_EXTRACTIONS])
		printf("canExecuteModule \n");
	else 
		printf("NO canExecuteModule \n");

	if ([[[CommercialStateMgr getInstance] getModuleByCode: ModuleCode_SEND_EXTRACTIONS] getOnline])
		printf("getOnline \n");
	else
		printf("NO getOnline \n");

		if ( telesup && 
					[[CommercialStateMgr getInstance] canExecuteModule: ModuleCode_SEND_EXTRACTIONS] &&
					[[[CommercialStateMgr getInstance] getModuleByCode: ModuleCode_SEND_EXTRACTIONS] getOnline] &&
					[telesup getInformExtractionsByTransaction] ) {

					printf("Supervisa la extraccion \n"); 
			[[TelesupScheduler getInstance] setCommunicationIntention: CommunicationIntention_INFORM_EXTRACTIONS];
			[[TelesupScheduler getInstance] startTelesupInBackground];
		}
	}
*/
printf("myIsGeneratingExtraction = FALSE\n");
	myIsGeneratingExtraction = FALSE;

	return myLastExtractionNumber;
}

/**/
- (void) addCurrentCashClose: (ZCLOSE) aCashClose
{
	EXTRACTION extraction;

	extraction = [self getCurrentExtraction: [[aCashClose getCimCash] getDoor]];
	[extraction addCashClose: aCashClose];

}

/**/
- (void) addCurrentCashClosesToExtraction: (EXTRACTION) anExtraction
{
	COLLECTION cimCashs;
	ZCLOSE cashClose;
	int i;

	if (![[CimGeneralSettings getInstance] getUseEndDay]) return; 

	// Carga las nuevos Cash Closes
	cimCashs = [[[CimManager getInstance] getCim] getCimCashs];
	for (i = 0; i < [cimCashs size]; ++i) {
		if ([[cimCashs at: i] getDoor] != [anExtraction getDoor]) continue;
		cashClose = [[ZCloseManager getInstance] getCurrentCashCloseForCimCash: [cimCashs at: i]];
		[anExtraction addCashClose: cashClose];
	}
}

/**/
- (unsigned long) getLastExtractionNumber
{
	return myLastExtractionNumber;
}

/**/
- (BOOL) getZCloseByDeposit: (ABSTRACT_RECORDSET) aZCloseRS depositNumber: (unsigned long) aDepositNumber
{
	while (![aZCloseRS eof]) {
		if ([aZCloseRS getLongValue: "TO_DEPOSIT_NUMBER"] != 0 &&
				aDepositNumber >= [aZCloseRS getLongValue: "FROM_DEPOSIT_NUMBER"] &&
				aDepositNumber <= [aZCloseRS getLongValue: "TO_DEPOSIT_NUMBER"]) return TRUE;
		[aZCloseRS moveNext];
	}

	return FALSE;
}

- (void) addCashClosesToExtraction: (EXTRACTION) anExtraction
{
	COLLECTION list;
	COLLECTION cashCloses;
	int i;

	if (![[CimGeneralSettings getInstance] getUseEndDay]) return;

	if ([anExtraction getToCloseNumber] != 0) {

		list = [self getCashsForDoor: [anExtraction getDoor]];
	
		// Busco todos los cash close correspondientes
		cashCloses = [[ZCloseManager getInstance] loadCashCloses: list
			fromCloseNumber: [anExtraction getFromCloseNumber]
			toCloseNumber: [anExtraction getToCloseNumber] ];
	
		// Agrego los resultados a la extraccion
		for (i = 0; i < [cashCloses size]; ++i) {
			[anExtraction addCashClose: [cashCloses at: i]];
		}

		[list free];
		[cashCloses free];

	}
}

/**/
- (EXTRACTION) loadLast
{
	EXTRACTION extraction;

	extraction = [[[Persistence getInstance] getExtractionDAO] loadLast];

	if (extraction == NULL) return NULL;
	[self addCashClosesToExtraction: extraction];

	return extraction;

}

/**/
- (EXTRACTION) loadById: (unsigned long) anId
{
	EXTRACTION extraction;

	extraction = [[[Persistence getInstance] getExtractionDAO] loadById: anId];

	if (extraction == NULL) return NULL;
	[self addCashClosesToExtraction: extraction];

	return extraction;

}

/**/
- (void) storeBagTrackingCollection: (COLLECTION) aCollection bagTrackingMode: (int) aBagTrackingMode
{
	int i;
	id obj;
	id dao;
	id telesup;
	char add[20];

	assert(aCollection);

	dao = [[Persistence getInstance] getExtractionDAO];

	for (i=0; i<[aCollection size]; ++i) {
		obj = [aCollection at: i];
		[dao storeBagTracking: obj];	
		

		// si se trata de automatico audita el nuevo stacker
		if ( ([obj getBType] == BagTrackingMode_AUTO) && ([obj getBParentId] > 0) ) {
			stringcpy(add, [obj getBNumber]);
			[Audit auditEventCurrentUser: Event_NEW_STACKER additional: add station: [obj getAcceptorId] logRemoteSystem: FALSE];
		}
	}

	if (aBagTrackingMode == BagTrackingMode_MANUAL || aBagTrackingMode == BagTrackingMode_MIXED) {

		/* supervisa si:
		1.existe la supervision
		2.puede ejecutar el modulo
		3.el modulo tiene configurado online
		4.esta configurada online el envio de extracciones en la telesup
		*/
	
		telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];
	
		if ( telesup && 
					[[CommercialStateMgr getInstance] canExecuteModule: ModuleCode_SEND_EXTRACTIONS] &&
					[[[CommercialStateMgr getInstance] getModuleByCode: ModuleCode_SEND_EXTRACTIONS] getOnline] &&
					[telesup getInformExtractionsByTransaction] ) {
	
			[[TelesupScheduler getInstance] setCommunicationIntention: CommunicationIntention_INFORM_EXTRACTIONS];
			[[TelesupScheduler getInstance] startTelesupInBackground];
		}
	}

}

/**/
- (void) storeBagTrackHeader: (id) anExtraction bagNumber: (char*) aBagNumber bagTrackingMode: (int) aBagTrackingMode
{
	COLLECTION bagTrackCollection;
	scew_tree *tree;

	id bagTrack = NULL;

	bagTrack = [BagTrack new];
	[bagTrack setExtractionNumber: [anExtraction getNumber]];
	[bagTrack setBNumber: aBagNumber];

	// si es bag tracking auto debe invocar a otro metodo
	if (aBagTrackingMode == BagTrackingMode_AUTO || aBagTrackingMode == BagTrackingMode_MIXED) {

		[bagTrack setBType: BagTrackingMode_AUTO]; 

		//[bagTrack debugBagTrack];

		bagTrackCollection = [[[Persistence getInstance] getExtractionDAO] storeAutoBagTrack: bagTrack];

		[anExtraction setBagTrackingCollection: bagTrackCollection];
		[anExtraction setBagTrackingMode: BagTrackingMode_AUTO];
	
		tree = [[ReportXMLConstructor getInstance] buildXML: anExtraction entityType: BAG_TRACKING_PRT isReprint: FALSE varEntity: NULL];
	
		[[PrinterSpooler getInstance] addPrintingJob: BAG_TRACKING_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: 0];
		
		[bagTrackCollection freeContents];
		[bagTrackCollection free];

	}

	// si es bag tracking manual directamente guarda
	if (aBagTrackingMode == BagTrackingMode_MANUAL || aBagTrackingMode == BagTrackingMode_MIXED) {
		[bagTrack setBType: BagTrackingMode_MANUAL]; 
		//[bagTrack debugBagTrack];

		[[[Persistence getInstance] getExtractionDAO] storeBagTracking: bagTrack];
	}


	[bagTrack free];
}

/**/
- (BOOL) isGeneratingExtraction { return myIsGeneratingExtraction; }


@end
