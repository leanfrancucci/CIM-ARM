#include "Cim.h"
#include "BillAcceptor.h"
#include "CdmCoinAcceptor.h"
#include "EnvelopeAcceptor.h"
#include "CimExcepts.h"
#include "SafeBoxHAL.h"
#include "AcceptorDAO.h"
#include "Persistence.h"
#include "CurrencyManager.h"
#include "safeBoxMgr.h"
#include "CimManager.h"
#include "ZCloseManager.h"

@implementation Cim

- (void) addAcceptorToCim: (ACCEPTOR_SETTINGS) anAcceptorSettings initAcceptor: (BOOL) aInitAcceptor;	//forward

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	COLLECTION doors;
	int i;
	id door;

	myDoors = [Collection new];
	myCollectorDoors = [Collection new];
	myAcceptors = [Collection new];

 	myCimCashs = [Collection new];
	myAutoCimCashs = [Collection new];
	myManualCimCashs = [Collection new];	 
	myNoDevicesCimChashs = [Collection new];
	myCimCashsCompleteList = [Collection new];

	// Carga las puertas
	doors = [[[Persistence getInstance] getDoorDAO] loadAll];
	for (i = 0; i < [doors size]; ++i) {
		[self addDoor: [doors at: i]];
	}

	// Relaciono las puertas entre si
	for (i = 0; i < [myDoors size]; ++i) {
		door = [myDoors at: i];
		if ([door getBehindDoorId] > 0)
			[door setOuterDoor: [self getDoorById: [door getBehindDoorId]]];
	}
	[doors free];

	myAcceptorSettings = [[[Persistence getInstance] getAcceptorDAO] loadAll: myDoors];

	for (i=0;i<[myAcceptorSettings size]; ++i) {

		// si el acceptor esta deshabilitada no lo inicio
		if ([[myAcceptorSettings at: i] isDeleted]) continue;

		[self addAcceptorToCim: [myAcceptorSettings at: i] initAcceptor: FALSE];

	}

	

	return self;
}

/**/
- (COLLECTION) getDoorsBehind: (DOOR) aDoor
{
	COLLECTION list = [Collection new];
	int i;

	for (i = 0; i < [myDoors size]; ++i) {
		if ([[myDoors at: i] getOuterDoor] == aDoor)
			[list add: [myDoors at: i]];
	}

	return list;
}

/**/
- (void) loadCimCashes
{
	int i;
	COLLECTION cimCashes = [[[Persistence getInstance] getCimCashDAO] loadAll];

	// Levanta los cash
	for (i = 0; i < [cimCashes size]; ++i) {
		[self addCimCash: [cimCashes at: i]];
	}

	[cimCashes free];
}

/**/
- (void) addDoor: (DOOR) aValue 
{ 
	[myDoors add: aValue]; 

	// Agrego la puerta a la puerta de recaudacion (si corresponde)
	if ([aValue getDoorType] == DoorType_COLLECTOR) [myCollectorDoors add: aValue];
}

- (COLLECTION) getDoors { return myDoors; }
- (COLLECTION) getCollectorDoors { return myCollectorDoors; }

/**/
- (DOOR) getDoorById: (int) aDoorId
{
	int i;

	for (i = 0; i < [myDoors size]; ++i) {
		if ([[myDoors at: i] getDoorId] == aDoorId) return [myDoors at: i];
	}

	return NULL;
}

/**/
- (id) getCimCashById: (int) aCimCashId
{
	int i;

	for (i = 0; i < [myCimCashsCompleteList size]; ++i) {
		if ([[myCimCashsCompleteList at: i] getCimCashId] == aCimCashId) return [myCimCashsCompleteList at: i];
	}

	return NULL;
}

/**/
- (id) getCimCashByAcceptorId: (int) anAcceptorId
{
	int i,j;
	COLLECTION acceptorList;

	for (i = 0; i < [myCimCashsCompleteList size]; ++i) {
		acceptorList = [[myCimCashsCompleteList at: i] getAcceptorSettingsList];
		for (j = 0; j < [acceptorList size]; ++j) {
       if ([[acceptorList at: j] getAcceptorId] == anAcceptorId) return [myCimCashsCompleteList at: i];
    }
	}

	return NULL;
}

/**/
- (void) addCimCash: (CIM_CASH) aCimCash
{
	[myCimCashsCompleteList add: aCimCash];

	if ([aCimCash isDeleted]) return;

	if ([aCimCash getDepositType] != DepositType_WITHOUT_DEVICES)
		[myCimCashs add: aCimCash];

	if ([aCimCash getDepositType] == DepositType_AUTO) 
		[myAutoCimCashs add: aCimCash];
	else if ([aCimCash getDepositType] == DepositType_MANUAL)
		[myManualCimCashs add: aCimCash];
	else
		[myNoDevicesCimChashs add: aCimCash];
}

/**/
- (void) removeCimCash: (id) aCimCash
{	
	int i;
	id collection;

	if ([aCimCash getDepositType] == DepositType_AUTO) 
		collection = myAutoCimCashs;
	else if ([aCimCash getDepositType] == DepositType_MANUAL)
		collection = myManualCimCashs;
	else 
		collection = myNoDevicesCimChashs;

	for (i=0; i<[myCimCashs size]; ++i) {
		if ([[myCimCashs at: i] getCimCashId] == [aCimCash getCimCashId]) {
			[myCimCashs removeAt: i];
		}
	}

	for (i=0; i<[collection size]; ++i) {
		if ([[collection at: i] getCimCashId] == [aCimCash getCimCashId]) {
			[collection removeAt: i];
		}
	}

}


/**/
- (COLLECTION) getCimCashs
{
	return myCimCashs;
}

/**/
- (COLLECTION) getManualCimCashs
{
	return myManualCimCashs;
}

/**/
- (COLLECTION) getAutoCimCashs
{
	return myAutoCimCashs;
}

/**/
- (void) addAcceptor: (ABSTRACT_ACCEPTOR) aValue { [myAcceptors add: aValue]; }
- (COLLECTION) getAcceptors { return myAcceptors; }

/**/
- (void) setAcceptorsObserver: (id) anObserver
{
	int i;

	for (i = 0; i < [myAcceptors size]; ++i) {
		[[myAcceptors at: i] setObserver: anObserver];
	}
}

/**/
- (void) setDoorsObserver: (id) anObserver
{
	int i;

	for (i = 0; i < [myDoors size]; ++i) {
		[[myDoors at: i] setObserver: anObserver];
	}
}

/**/
- (void) startDoors
{
	int i;

	for (i = 0; i < [myDoors size]; ++i) {
		if (![[myDoors at: i] isDeleted])
			[[myDoors at: i] initDoor];
	}

}

/**/
- (void) startAcceptors
{
	ABSTRACT_ACCEPTOR acceptor;
	int i;

	for (i = 0; i < [myAcceptors size]; ++i) {
		acceptor = [myAcceptors at: i];
		[acceptor initAcceptor];
	}
}

/**/
- (ACCEPTOR_SETTINGS) getAcceptorSettingsById: (int) anId
{
	int i;

	for (i = 0; i < [myAcceptorSettings size]; ++i) {
		if ([[myAcceptorSettings at: i] getAcceptorId] == anId) return [myAcceptorSettings at: i];
	}
	return NULL;
}

/**/
- (ACCEPTOR_SETTINGS) getCompleteAcceptorSettingsById: (int) anId
{
	int i;

	for (i = 0; i < [myAcceptorSettings size]; ++i) {
		if ([[myAcceptorSettings at: i] getAcceptorId] == anId) return [myAcceptorSettings at: i];
	}
	return NULL;
}

/**/
- (ABSTRACT_ACCEPTOR) getAcceptorById: (int) anId
{
	int i;

	for (i = 0; i < [myAcceptors size]; ++i) {
		if ([[[myAcceptors at: i] getAcceptorSettings] getAcceptorId] == anId) return [myAcceptors at: i];
	}

	return NULL;
}

/**/
- (int) getTotalStackerSize: (id) anAcceptor
{
	id cimCash;
	COLLECTION acceptors;
	int i;
	int sSize = 0;

	cimCash = [self getCimCashByAcceptorId: [[anAcceptor getAcceptorSettings] getAcceptorId]];
	acceptors = [cimCash getAcceptorSettingsList];
	
	for (i=0; i<[acceptors size]; ++i)  {
		sSize+= [[acceptors at: i] getStackerSize];
}
	
	return sSize;

}

/**/
- (int) getTotalStackerWarningSize: (id) anAcceptor
{
	id cimCash;
	COLLECTION acceptors;
	int i;
	int sWarningSize = 0;

	cimCash = [self getCimCashByAcceptorId: [[anAcceptor getAcceptorSettings] getAcceptorId]];
	acceptors = [cimCash getAcceptorSettingsList];
	
	for (i=0; i<[acceptors size]; ++i) {
		sWarningSize+= [[acceptors at: i] getStackerWarningSize];
	}
	
	return sWarningSize;

}

/**/
- (void) openCimCash: (CIM_CASH) anCimCash
{
	COLLECTION acceptorSettingsList;
	ABSTRACT_ACCEPTOR acceptor;
	int i;
	int stackerQty;
	int stackerSize;
	int stackerWarningSize;

	acceptorSettingsList = [anCimCash getAcceptorSettingsList];

	//
	for (i = 0; i < [acceptorSettingsList size]; ++i) {
		acceptor = [self getAcceptorById: [[acceptorSettingsList at: i] getAcceptorId]];

		if (acceptor){

		// Si es FLEX debe tomar la configuracion de algun lado
		if (strstr([[self  getBoxById: 1] getBoxModel], "FLEX")) {

			stackerQty = [[[ExtractionManager getInstance] getCurrentExtraction: [[acceptor getAcceptorSettings] getDoor]] getQty: NULL];
			// debo tomar el total del tamano que es la sumatoria de los montos de los stackers de cada aceptador
			stackerSize = [self getTotalStackerSize: acceptor];

			stackerWarningSize = [self getTotalStackerWarningSize: acceptor];

			printf("stacker size = %d\n", stackerSize);
			printf("stacker warning size = %d\n", stackerWarningSize);
			printf("stacker qty = %d\n", stackerQty);

		} else {

			// si es stacker full no le habilito el validador
			stackerQty = [[[ExtractionManager getInstance] getCurrentExtraction: [[acceptor getAcceptorSettings] getDoor]] getQtyByAcceptor: [acceptor getAcceptorSettings]];

			stackerSize = [[acceptor getAcceptorSettings] getStackerSize];
			stackerWarningSize = [[acceptor getAcceptorSettings] getStackerWarningSize];
		}

			if ((stackerSize == 0) || (stackerSize > stackerQty))
				[acceptor open];
		}
	}

}

/**/
- (void) reopenCimCash: (CIM_CASH) anCimCash
{
	COLLECTION acceptorSettingsList;
	ABSTRACT_ACCEPTOR acceptor;
	int i;

	acceptorSettingsList = [anCimCash getAcceptorSettingsList];

	//
	for (i = 0; i < [acceptorSettingsList size]; ++i) {
		acceptor = [self getAcceptorById: [[acceptorSettingsList at: i] getAcceptorId]];
		if (acceptor){
				[acceptor reopen];
		}
	}

}

/**/
- (BOOL) canReopenCimCash: (CIM_CASH) anCimCash
{
  COLLECTION acceptorSettingsList;
	ABSTRACT_ACCEPTOR acceptor;
	int i;

	acceptorSettingsList = [anCimCash getAcceptorSettingsList];

	//
	for (i = 0; i < [acceptorSettingsList size]; ++i) {
		acceptor = [self getAcceptorById: [[acceptorSettingsList at: i] getAcceptorId]];
		if (acceptor && [acceptor canReopen]) return TRUE;
	}  

  return FALSE;
}

/**/
- (void) closeCimCash: (CIM_CASH) anCimCash
{
	COLLECTION acceptorSettingsList;
	ABSTRACT_ACCEPTOR acceptor;
	int i;

	acceptorSettingsList = [anCimCash getAcceptorSettingsList];

	//
	for (i = 0; i < [acceptorSettingsList size]; ++i) {
		acceptor = [self getAcceptorById: [[acceptorSettingsList at: i] getAcceptorId]];
		if (acceptor) [acceptor close];	
	}
}

/**/
- (COLLECTION) getDoorsIdList
{
	COLLECTION list = [Collection new];
	int i;

	for (i = 0; i < [myDoors size]; ++i)
		[list add: [BigInt int: [[myDoors at: i] getDoorId]]];
	
	return list;
}

/**/
- (COLLECTION) getValidatorsIdList
{
	COLLECTION list = [Collection new];
	int i;

	for (i = 0; i < [myAcceptors size]; ++i) {
		if ([[[myAcceptors at: i] getAcceptorSettings] getAcceptorType] != AcceptorType_VALIDATOR) continue;
		
		[list add: [BigInt int: [[[myAcceptors at: i] getAcceptorSettings] getAcceptorId]]];
	}

	return list;
}

/**/
- (COLLECTION) getMailBoxesIdList
{
	COLLECTION list = [Collection new];
	int i;

	for (i = 0; i < [myAcceptors size]; ++i) {
		if ([[[myAcceptors at: i] getAcceptorSettings] getAcceptorType] != AcceptorType_MAILBOX) continue;
		
		[list add: [BigInt int: [[[myAcceptors at: i] getAcceptorSettings] getAcceptorId]]];
	}
	
	return list;
}

/**/
- (DENOMINATION) getCurrencyDenomination: (int) aDepositValueType acceptorId: (int) anAcceptorId currencyId: (int) aCurrencyId denomination: (money_t) aDenomination
{
	id acceptor = NULL;
	id depositValueType = NULL;
	id acceptedCurrency = NULL;
	id denom = NULL;

	// toma el aceptador
	acceptor = [self getAcceptorSettingsById: anAcceptorId];

	if (acceptor == NULL) return NULL;

	// toma el deposit value
	depositValueType = [acceptor getAcceptedDepositValueByType: aDepositValueType];

	if (depositValueType == NULL) return NULL;

	// toma el currency
	acceptedCurrency = [depositValueType getAcceptedCurrencyByCurrencyId: aCurrencyId];

	if (acceptedCurrency == NULL) return NULL;

	// toma la denomination
	denom = [acceptedCurrency getDenominationByAmount: aDenomination];

	if (denom == NULL) return NULL;

	return denom;

}

/**/
- (COLLECTION) getCurrencyDenominations: (int) aDepositValueType acceptorId: (int) anAcceptorId currencyId: (int) aCurrencyId
{
	id acceptor = NULL;
	id depositValueType = NULL;
	id acceptedCurrency = NULL;
 
	// toma el aceptador

	acceptor = [self getAcceptorSettingsById: anAcceptorId];

	if (acceptor == NULL) return NULL;

	// toma el deposit value
	depositValueType = [acceptor getAcceptedDepositValueByType: aDepositValueType];

	if (depositValueType == NULL) return NULL;

	// toma el currency
	acceptedCurrency = [depositValueType getAcceptedCurrencyByCurrencyId: aCurrencyId];

	if (acceptedCurrency == NULL) return NULL;

	return [acceptedCurrency getDenominations];
}

/**/
- (COLLECTION) getDepositValueTypes: (int) anAcceptorId
{
	id acceptor = NULL;

	acceptor = [self getAcceptorSettingsById: anAcceptorId];

	if (acceptor == NULL) return NULL;

	return [acceptor getAcceptedDepositValues];
}

/**/
- (COLLECTION) getCurrenciesByDepositValueType: (int) anAcceptorId depositValueType: (int) aDepositValueType
{
	id acceptor = NULL;
	id depositValueType = NULL;
	id acceptedCurrency = NULL;
    int i;
	// toma el aceptadorfile

	acceptor = [self getAcceptorSettingsById: anAcceptorId];

	if (acceptor == NULL) return NULL;

	// toma el deposit value
	depositValueType = [acceptor getAcceptedDepositValueByType: aDepositValueType];

	if (depositValueType == NULL) return NULL;
    
    printf("getCurrenciesByDepositValueType LOG SOLE >>>>>>>>>>>\n");

    for (i = 0; i < [[depositValueType getAcceptedCurrencies]size]; i++){
        acceptedCurrency = [[[depositValueType getAcceptedCurrencies]at: i]getCurrency];
        printf("getCurrenciesByDepositValueType LOG SOLE >>>>>>>>>>> %s\n", [acceptedCurrency getCurrencyCode]);
        
    }
	return [depositValueType getAcceptedCurrencies];
}

/**/
- (void) addAcceptorDepositValueType: (int) anAcceptorId depositValueType: (int) aDepositValueType
{
	id acceptor = [self getAcceptorSettingsById: anAcceptorId];
	if (acceptor == NULL) THROW(CIM_GENERAL_EX);

	[acceptor addDepositValueType: aDepositValueType];
}

/**/
- (void) removeAcceptorDepositValueType: (int) anAcceptorId depositValueType: (int) aDepositValueType
{
	id acceptor = [self getAcceptorSettingsById: anAcceptorId];
	if (acceptor == NULL) THROW(CIM_GENERAL_EX);

	[acceptor removeDepositValueType: aDepositValueType];
}

/**/
- (void) addDepositValueTypeCurrency: (int) anAcceptorId depositValueType: (int) aDepositValueType currencyId: (int) aCurrencyId
{
	id acceptedDepositValueType;
	id acceptor = [self getAcceptorSettingsById: anAcceptorId];
	if (acceptor == NULL) THROW(CIM_GENERAL_EX);

	acceptedDepositValueType = [acceptor getAcceptedDepositValueByType: aDepositValueType];

	if (acceptedDepositValueType == NULL) THROW(CIM_GENERAL_EX);

	[acceptedDepositValueType addDepositValueTypeCurrency: anAcceptorId currencyId: aCurrencyId];
}

/**/
- (void) removeDepositValueTypeCurrency: (int) anAcceptorId depositValueType: (int) aDepositValueType currencyId: (int) aCurrencyId
{
	id acceptedDepositValueType;
	id acceptor = [self getAcceptorSettingsById: anAcceptorId];
	if (acceptor == NULL) THROW(CIM_GENERAL_EX);

	acceptedDepositValueType = [acceptor getAcceptedDepositValueByType: aDepositValueType];

	if (acceptedDepositValueType == NULL) THROW(CIM_GENERAL_EX);

	[acceptedDepositValueType removeDepositValueTypeCurrency: anAcceptorId currencyId: aCurrencyId];
}

/**/
- (void) closeBillValidators
{
	int i;
	ABSTRACT_ACCEPTOR acceptor;

	for (i = 0; i < [myAcceptors size]; ++i) {
		acceptor = [myAcceptors at: i];
		if ([[acceptor getAcceptorSettings] getAcceptorType] != AcceptorType_VALIDATOR) continue;
		[acceptor close];
	}

}

/**/
- (void) setBillValidatorsInValidatedMode
{
	int i;
	ABSTRACT_ACCEPTOR acceptor;

	for (i = 0; i < [myAcceptors size]; ++i) {
		acceptor = [myAcceptors at: i];
		if ([[acceptor getAcceptorSettings] getAcceptorType] != AcceptorType_VALIDATOR) continue;
		[acceptor setValidatedMode];
	}
}

/**/
- (COLLECTION) getCashBoxesIdList
{
	COLLECTION list = [Collection new];
	int i;

	for (i = 0; i < [myCimCashsCompleteList size]; ++i) {
		[list add: [BigInt int: [[myCimCashsCompleteList at: i] getCimCashId]]];
	}
	
	return list;
}

/**/
- (int) addCashBox: (char*) aName doorId: (int) aDoorId depositType: (int) aDepositType
{
	id cimCash;
	id dao = [[Persistence getInstance] getCimCashDAO];

	cimCash = [CimCash new];
	
	TRY

		[cimCash setName: aName];
		[cimCash setDoorId: aDoorId];
		[cimCash setDepositType: aDepositType];

		[dao store: cimCash];

//		[self addCimCash: cimCash];

	CATCH
		
		RETHROW();

	END_TRY

	return [cimCash getCimCashId];

}

/**/
- (void) removeCashBox: (int) aCashId
{
	id cimCash;
	id dao = [[Persistence getInstance] getCimCashDAO];
	
	TRY

		cimCash = [self getCimCashById: aCashId];


		if ([[CimManager getInstance] getExtendedDrop: cimCash]) THROW(CANNOT_REMOVE_CASH_WITH_EXTENDED_DROP_EX);
		[cimCash setDeleted: TRUE];

		[dao store: cimCash];
		[self removeCimCash: cimCash];

	CATCH
		
		RETHROW();

	END_TRY
}

/**/
- (COLLECTION) getAcceptorsByCash: (int) aCashId
{
	id cimCash = [self getCimCashById: aCashId];
	return [cimCash getAcceptorSettingsList];
}

/**/
- (void) addAcceptorByCash: (int) aCashId acceptorId: (int) anAcceptorId
{
	id cimCash;
	id acceptorSettings;

	TRY

		cimCash = [self getCimCashById: aCashId];
		acceptorSettings = [self getAcceptorSettingsById: anAcceptorId];

		if (![cimCash hasAcceptorSettings: acceptorSettings])
			[cimCash addAcceptorSettingsByCash: acceptorSettings];

	CATCH

		RETHROW();		

	END_TRY
		
}

- (void) removeAcceptorByCash: (int) aCashId acceptorId: (int) anAcceptorId
{
	id cimCash;

	TRY

		cimCash = [self getCimCashById: aCashId];
		[cimCash removeAcceptorSettings: [self getAcceptorSettingsById: anAcceptorId]]; 

	CATCH

		RETHROW();		

	END_TRY
}

/**/
- (COLLECTION) getAcceptorSettings
{
	return myAcceptorSettings;
}

/**/
- (COLLECTION) getActiveAcceptorSettings
{
	int i;
	COLLECTION acc = [Collection new];

	for (i=0; i<[myAcceptorSettings size]; ++i) 
		if (![[myAcceptorSettings at: i] isDeleted]) [acc add: [myAcceptorSettings at: i]];

	return acc;
}

/**/
- (id) getBoxById: (int) aBoxId
{
	int i;

	for (i = 0; i < [myBoxes size]; ++i) 
		if ([[myBoxes at: i] getBoxId] == aBoxId) return [myBoxes at: i];

	return NULL;
}

/**/
- (COLLECTION) getBoxesIdList
{
	COLLECTION list = [Collection new];
	int i;

	for (i = 0; i < [myBoxes size]; ++i)
		[list add: [BigInt int: [[myBoxes at: i] getBoxId]]];
	
	return list;
}

/**/
- (COLLECTION) getBoxes
{
	return myBoxes;
}

/**/
- (int) addCimBox: (char*) aName model: (char*) aModel
{
	id box;
	id dao = [[Persistence getInstance] getBoxDAO];

	box = [Box new];
	
	[box setName: aName];
	[box setBoxModel: aModel];

	[dao store: box];
	[self addBox: box];

	return [box getBoxId];
}

/**/
- (void) removeBoxById: (int) aBoxId
{
	id box;
	id dao = [[Persistence getInstance] getBoxDAO];
	
	box = [self getBoxById: aBoxId];

	[box setDeleted: TRUE];

	[dao store: box];
	[self removeBox: box];

}

/**/
- (void) addBox: (BOX) aBox
{
	[myBoxes add: aBox];
}

/**/
- (void) removeBox: (id) aBox
{
	[myBoxes remove: aBox];
}

/**/
- (COLLECTION) getAcceptorsByBox: (int) aBoxId
{
	id box = [self getBoxById: aBoxId];
	return [box getAcceptorSettingsList];
}

/**/
- (COLLECTION) getDoorsByBox: (int) aBoxId
{
	id box = [self getBoxById: aBoxId];
	return [box getDoorsList];
}

/**/
- (void) addAcceptorToCim: (ACCEPTOR_SETTINGS) anAcceptorSettings initAcceptor: (BOOL) aInitAcceptor
{
	ABSTRACT_ACCEPTOR acceptor;

	if ([anAcceptorSettings getAcceptorType] == AcceptorType_VALIDATOR) {
		if ([anAcceptorSettings getAcceptorProtocol] == ProtocolType_CDM3000) {
      acceptor = [CdmCoinAcceptor new];
    } else {
      acceptor = [BillAcceptor new];
	  }
  	[acceptor setAcceptorSettings: anAcceptorSettings];
		[myAcceptors add: acceptor];
		if (aInitAcceptor) [acceptor initAcceptor];
		return;
	}

	if ([anAcceptorSettings getAcceptorType] == AcceptorType_MAILBOX) {
		acceptor = [EnvelopeAcceptor new];
		[acceptor setAcceptorSettings: anAcceptorSettings];
		[myAcceptors add: acceptor];
		if (aInitAcceptor) [acceptor initAcceptor];
		return;
	}

}

/**/
- (void) addAcceptorByBox: (int) aBoxId acceptorId: (int) anAcceptorId
{
	id box;
	ACCEPTOR_SETTINGS acceptorSettings = [self getCompleteAcceptorSettingsById: anAcceptorId];

	THROW_NULL(acceptorSettings);

	// Lo agrego a esta lista (la que tiene los validadores activos)
	//[myAcceptorSettings add: acceptorSettings];

	// Crea el objeto Acceptor y comienza el proceso correspondiente
	[self addAcceptorToCim: acceptorSettings initAcceptor: FALSE];

	box = [self getBoxById: aBoxId];
	if (![box boxHasAcceptorSettings: anAcceptorId])
		[box addAcceptorSettingsByBox: acceptorSettings];
}

/**/
- (void) removeAcceptorByBox: (int) aBoxId acceptorId: (int) anAcceptorId
{
	id box;
	id acceptor = [self getAcceptorSettingsById: anAcceptorId];

	box = [self getBoxById: aBoxId];
	if ([box boxHasAcceptorSettings: anAcceptorId])
		[box removeAcceptorSettings: acceptor]; 

	//[myAcceptorSettings remove: acceptor];

}

/**/
- (void) addDoorByBox: (int) aBoxId doorId: (int) aDoorId
{
	id box;

	box = [self getBoxById: aBoxId];
	[box addDoorByBox: [self getDoorById: aDoorId]]; 
}

/**/
- (void) removeDoorByBox: (int) aBoxId doorId: (int) aDoorId
{
	id box;

	box = [self getBoxById: aBoxId];
	[box removeDoor: [self getDoorById: aDoorId]]; 
}

/**/
- (void) loadBoxes
{
	myBoxes = [[[Persistence getInstance] getBoxDAO] loadAll];
}

/**/
- (id) getBoxWithAcceptor: (int) anAcceptorId
{
	int i;

	for (i=0; i<[myBoxes size]; ++i) {
		if ([[myBoxes at: i] boxHasAcceptorSettings: anAcceptorId]) return [myBoxes at: i];
	}

	return NULL;
}

/**/
- (COLLECTION) getAcceptorsIdList
{
	COLLECTION list = [Collection new];
	int i;

	for (i = 0; i < [myAcceptorSettings size]; ++i) 
		[list add: [BigInt int: [[myAcceptorSettings at: i] getAcceptorId]]];

	return list;
}

/**/
/*
- (int) addCimAcceptor: (int) aType name: (char*) aName brand: (int) aBrand model: (char*) aModel
										protocol: (int) aProtocol hardwareId: (int) aHardwareId stackerSize: (int) aStackerSize
										stackerWarningSize: (int) aStackerWarningSize doorId: (int) aDoorId baudRate: (int) aBaudRate
										dataBits: (int) aDataBits parity: (int) aParity stopBits: (int) aStopBits flowControl: (int) aFlowControl
										startTimeOut: (int) aStartTimeOut echoDisable: (BOOL) aEchoDisable
*/

- (int) addCimAcceptor: (int) aType name: (char*) aName brand: (int) aBrand model: (char*) aModel
										protocol: (int) aProtocol hardwareId: (int) aHardwareId stackerSize: (int) aStackerSize
										stackerWarningSize: (int) aStackerWarningSize doorId: (int) aDoorId baudRate: (int) aBaudRate
										dataBits: (int) aDataBits parity: (int) aParity stopBits: (int) aStopBits flowControl: (int) aFlowControl								
{
	id obj = [AcceptorSettings new];

	[obj setAcceptorType: aType];
	[obj setAcceptorName: aName];
	[obj setAcceptorBrand: aBrand];
	[obj setAcceptorModel: aModel];
	[obj setAcceptorProtocol: aProtocol];
	[obj setAcceptorHardwareId: aHardwareId];
	[obj setStackerSize: aStackerSize];
	[obj setStackerWarningSize: aStackerWarningSize];
	[obj setDoor: [self getDoorById: aDoorId]];
	[obj setAcceptorBaudRate: aBaudRate];
	[obj setAcceptorDataBits: aDataBits];
	[obj setAcceptorParity: aParity];
	[obj setAcceptorStopBits: aStopBits];
	[obj setAcceptorFlowControl: aFlowControl];
//	[obj setStartTimeOut: aStartTimeOut];
//	[obj setEchoDisable: aEchoDisable];

	[obj applyChanges];


	/**@todo agregar a la coleccion o hacer algo!!!!*/

	return [obj getAcceptorId];

}

/**/
- (void) removeCimAcceptor: (int) anAcceptorId
{
	id obj = [self getAcceptorSettingsById: anAcceptorId];

	[obj setDeleted: TRUE];
	[obj applyChanges];
	
	/**@todo remover de la coleccion o hacer algo!!!!*/
	
}

/**/
- (BOOL) isTransferenceBoxMode
{
	int i;
	FILE *f;
	BOOL result;

	result = FALSE;

	// para saber si es caja de transferencia las Puertas 1 y 2 NO debe tener 
	// cerradura electronica y ademas debe haber una puerta deshabilitada.

	// Antes debo verificar si se encuentra el archivo transBoxMode que se utilizaba antes.
	// Si existe debo setear las puertas para que no utilicen cerradura electronica.
	// Luego elimino el archivo.
	// ESTE CONTROL SE HACE PARA LOS EQUIPOS DE PROSEGUR QUE YA ESTAN EN CAMPO Y QUE FUERON ACTUALIZADOS.
	f = fopen("transBoxMode", "r");
	if (f) {
		fclose(f);

		// seteo las puertas
		for (i = 0; i < [myDoors size]; ++i) {
			if ([[myDoors at: i] hasElectronicLock]) {
				[[myDoors at: i] setHasElectronicLock: FALSE];
				[[myDoors at: i] applyChanges];
			}

			// si es la puerta 2 la deshabilito
			if ( ([[myDoors at: i] getDoorId] == 2) && (![[myDoors at: i] isDeleted]) ) {
				[[myDoors at: i] setDeleted: TRUE];
				[[myDoors at: i] applyChanges];
			}
		}

		// elimino el archivo
		unlink("transBoxMode");
		return TRUE;
	}

	for (i = 0; i < [myDoors size]; ++i) {
		// si tiene alguna cerradura electronica retorno
		if ([[myDoors at: i] hasElectronicLock]) {
			return FALSE;
		}
		// verifico si una de las puertas esta deshabilitada
		if ([[myDoors at: i] isDeleted]) {
			result = TRUE;
		}
	}

	return result;
}

/**/
- (char*) getBoxModel
{
	int i;
	int doorsCount = 0;
	int valsCount = 0;
	int mailboxCount = 0;
	char auxStr[40];
	char auxValStr[40];
	char valBrandStr[40];
	char val2BrandStr[40];
	char valModelStr[40];
	char val2ModelStr[40];
	char valStackerStr[40];
	char val2StackerStr[40];
	STRING_TOKENIZER tokenizer;

	strcpy(myBoxModel, "Box");


	// Si en el archivo box se encuentra la palabra FLEX se devuelve Box_FLEX
	// esto sirve para mandar a la PIMS la version correcta y no la estructura de validadores
 // y puertas ya que FLEX es dos validadores una puerta validada y un buzon detras siempre fijos
	if (strstr([[self getBoxById: 1] getBoxModel], "FLEX")) {
		strcat(myBoxModel,"_FLEX");
		return myBoxModel;
	}

	// concateno la cantidad de puertas activas
	for (i = 0; i < [myDoors size]; ++i)
		if (![[myDoors at: i] isDeleted]) doorsCount++;

	sprintf(auxStr,"%d",doorsCount);
	strcat(myBoxModel,auxStr);

	// concateno si tiene cerradura electronica
	if (![self isTransferenceBoxMode]) {
		strcat(myBoxModel,"E");
	}

	// concateno la D (de puerta)
	strcat(myBoxModel,"D");

	// concateno si tiene alguna puerta interna
	auxStr[0] = '\0';
	for (i = 0; i < [myDoors size]; ++i)
		if ([[myDoors at: i] isInnerDoor]) strcpy(auxStr,"I");

	if (strlen(auxStr) > 0)
		strcat(myBoxModel,auxStr);

	// concateno la cantidad de validadores
	for (i = 0; i < [myAcceptorSettings size]; ++i) {
		if (![[myAcceptorSettings at: i] isDeleted]) {
			if ([[myAcceptorSettings at: i] getAcceptorType] == AcceptorType_VALIDATOR)
				valsCount++;
			else mailboxCount++;
		}
	}
	if (valsCount > 0) {
		sprintf(auxStr,"%dV",valsCount);
		strcat(myBoxModel,auxStr);
	}

	// cantidad de buzones
	if (mailboxCount > 0) {
		sprintf(auxStr,"%dM",mailboxCount);
		strcat(myBoxModel,auxStr);
	}

	// concateno info de validadores *****************
	valBrandStr[0] = '\0';
	val2BrandStr[0] = '\0';
	valModelStr[0] = '\0';
	val2ModelStr[0] = '\0';
	valStackerStr[0] = '\0';
	val2StackerStr[0] = '\0';
	auxValStr[0] = '\0';

	for (i = 0; i < [myAcceptorSettings size]; ++i) {
		if (![[myAcceptorSettings at: i] isDeleted]) {
			if ([[myAcceptorSettings at: i] getAcceptorType] == AcceptorType_VALIDATOR) {
				// concateno marca
				switch ([[myAcceptorSettings at: i] getAcceptorBrand]) {
					case BrandType_UNDEFINED:
								if (strlen(valBrandStr) == 0)
									strcat(valBrandStr,"-NA");
								else strcat(val2BrandStr,"-NA");
						break;
					case BrandType_JCM:
								if (strlen(valBrandStr) == 0)
									strcat(valBrandStr,"-JCM");
								else strcat(val2BrandStr,"-JCM");
						break;
					case BrandType_CASH_CODE:
								if (strlen(valBrandStr) == 0)
									strcat(valBrandStr,"-CC");
								else strcat(val2BrandStr,"-CC");
						break;
					case BrandType_MEI:
								if (strlen(valBrandStr) == 0)
									strcat(valBrandStr,"-MEI");
								else strcat(val2BrandStr,"-MEI");
						break;
					case BrandType_CDM:
								if (strlen(valBrandStr) == 0)
									strcat(valBrandStr,"-CDM");
								else strcat(val2BrandStr,"-CDM");

                                break;
					case BrandType_RDM:
								if (strlen(valBrandStr) == 0)
									strcat(valBrandStr,"-RDM");
								else strcat(val2BrandStr,"-RDM");

                                break;

                    
                }

				// concateno modelo
				tokenizer = [[StringTokenizer new] initTokenizer: [[myAcceptorSettings at: i] getAcceptorModel] delimiter: "|"];
				auxStr[0] = '\0';

				if ([tokenizer hasMoreTokens]) {
					// primer token es el modelo
					[tokenizer getNextToken: auxStr];
					if (strlen(valModelStr) == 0) {
						strcat(valModelStr,"-");
						strcat(valModelStr,auxStr);
					} else {
						strcat(val2ModelStr,"-");
						strcat(val2ModelStr,auxStr);
					}
				}
				[tokenizer free];

				// concateno si es Stacker o Bag
				if (strstr([[myAcceptorSettings at: i] getAcceptorModel], "BAG") != NULL) {
					if (strlen(valStackerStr) == 0)
						strcat(valStackerStr,"-Bag");
					else strcat(val2StackerStr,"-Bag");
				} else {
					if (strlen(valStackerStr) == 0)
						strcat(valStackerStr,"-Stacker");
					else strcat(val2StackerStr,"-Stacker");
				}

				if (strlen(auxValStr) == 0) {
					strcat(auxValStr,valBrandStr);
					strcat(auxValStr,valModelStr);
					strcat(auxValStr,valStackerStr);
				} else {
					if (strcmp(valBrandStr, val2BrandStr) != 0)
						strcat(auxValStr,val2BrandStr);
					if (strcmp(valModelStr, val2ModelStr) != 0) {
						strcat(auxValStr,val2ModelStr);
						strcat(auxValStr,val2StackerStr);
					}else{
						if (strcmp(valStackerStr, val2StackerStr) != 0)
							strcat(auxValStr,val2StackerStr);
					}
				}

			}
		}
	}

	if (strlen(auxValStr) > 0)
		strcat(myBoxModel,auxValStr);

	return myBoxModel;
}

/************************************************************************************************
DOORS
*************************************************************************************************/

/**/
- (int) addCimDoor: (DOOR) aDoor
{
	[aDoor applyChanges];

	/**@todo agregar a la coleccion o hacer algo!!!!*/

	return [aDoor getDoorId];
}

/**/
- (void) removeCimDoor: (int) aDoorId
{
	id door = [self getDoorById: aDoorId];

	if (!door) return;

	// elimino la puerta
	[door setDeleted: TRUE];
	[door applyChanges];

}

- (void) removeCimDoorFromCollection: (int) aDoorId
{
	int i = 0;
	
	for (i=0; i<[myDoors size]; ++i)
		if ([ [myDoors at: i] getDoorId] == aDoorId) {
			[myDoors removeAt: i];
			return;
		}
}

/**/
- (void) setSerialNumberChangeListener: (id) aListener
{
	int i;

	assert(myAcceptorSettings);

	for (i=0;i<[myAcceptorSettings size]; ++i) 
		[[myAcceptorSettings at: i] setSerialNumberChangeListener: aListener];

}

/**/
- (BOOL) verifyBoxModelChange
{
    
    printf("modelo de caja = %d\n", strlen(trim([[self getBoxById: 1] getBoxModel])));
    
	// verifico si el model ya fue seleccionado en las tablas locales del equipo
	if ( (strlen(trim([[self getBoxById: 1] getBoxModel])) == 0) && (![self hasMovements]) ) {
		return TRUE;
	}

	return FALSE;
}

/**/
- (BOOL) verifyBoxModelInbackup
{
	char model[51] = "";
	// si en la tabla de backup de box hay un modelo ya cargado entonces no hace falta seleccionar 
	// modelo pues ya fue hecho antes. Este control sirve para cuando se limpian los datos
	// del equipo para luego hacer un restore.
	if (strlen(trim([[[Persistence getInstance] getBoxDAO] loadModelFromBackupById: 1 model: model])) == 0) {
		return TRUE;
	}

	return FALSE;
}

/**/
- (void) verifyAcceptorsSerialNumbers
{
	int i;

	assert(myAcceptorSettings);

	for (i=0;i<[myAcceptorSettings size]; ++i) 
		[[myAcceptorSettings at: i] verifySerialNumberChange];

}

/**/
- (BOOL) hasMovements
{
	id deposit = NULL;
	BOOL result;

	deposit = [[[Persistence getInstance] getDepositDAO] loadLast];
	result = (deposit != NULL);
	if (deposit) [deposit free];

	return result;

}

/**/
- (void) setHasEmitStackerFullByCash: (id) anAcceptor value: (BOOL) aValue
{
	id cimCash;
	COLLECTION acceptorsSettingsList;
	id acceptor;
	int i;

	cimCash = [self getCimCashByAcceptorId: [[anAcceptor getAcceptorSettings] getAcceptorId]];
	acceptorsSettingsList = [cimCash getAcceptorSettingsList];
	
	for (i=0; i<[acceptorsSettingsList size]; ++i) {
		acceptor = [self getAcceptorById: [[acceptorsSettingsList at: i] getAcceptorId]];

		[acceptor	setHasEmitStackerFull: aValue];	
	}
	
}


/**/
- (void) setHasEmitStackerWarningByCash: (id) anAcceptor value: (BOOL) aValue
{
	id cimCash;
	COLLECTION acceptorsSettingsList;
	id acceptor;
	int i;

	cimCash = [self getCimCashByAcceptorId: [[anAcceptor getAcceptorSettings] getAcceptorId]];
	acceptorsSettingsList = [cimCash getAcceptorSettingsList];
	
	for (i=0; i<[acceptorsSettingsList size]; ++i) {
		acceptor = [self getAcceptorById: [[acceptorsSettingsList at: i] getAcceptorId]];

		[acceptor	setHasEmitStackerWarning: aValue];	
	}
}

@end

