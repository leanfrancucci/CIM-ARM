#include "ZClose.h"
#include "ResourceStringDefs.h"
#include "MessageHandler.h"
#include "ZCloseDAO.h"
#include "CimManager.h"
#include "CashReferenceManager.h"

@implementation ZClose

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myZCloseDetails = [Collection new];
	myCashReferenceSummaries = [Collection new];
	myIsOpen = TRUE;
	[self clear];
	return self;
}

/**/
- (void) clear
{
	myNumber = 0;
	myUser = NULL;
	myFromDepositNumber = 0;
	myToDepositNumber = 0;
	myOpenTime = 0;
	myCloseTime = 0;
	myRejectedQty = 0;
	myCimCash = NULL;
	myIsOpen = TRUE;
	myCloseType = CloseType_END_OF_DAY;
	myFromCloseNumber = 0;
	myToCloseNumber = 0;
	myParentNumber = 0;
	myParentCloseTime = 0;
	[myZCloseDetails freeContents];
	[myCashReferenceSummaries freeContents];
}

/**/
- (void) setNumber: (unsigned long) aValue { myNumber = aValue; }
- (unsigned long) getNumber { return myNumber; }

/**/
- (void) setUser: (USER) aValue { myUser = aValue; }
- (USER) getUser { return myUser; }

/**/
- (void) setFromDepositNumber: (unsigned long) aValue { myFromDepositNumber = aValue; }
- (unsigned long) getFromDepositNumber { return myFromDepositNumber; }

/**/
- (void) setToDepositNumber: (unsigned long) aValue { myToDepositNumber = aValue; }
- (unsigned long) getToDepositNumber { return myToDepositNumber; }

/**/
- (void) setOpenTime: (datetime_t) aValue { myOpenTime = aValue; }
- (datetime_t) getOpenTime { return myOpenTime; }

/**/
- (void) setCloseTime: (datetime_t) aValue { myCloseTime = aValue; }
- (datetime_t) getCloseTime { return myCloseTime; }

/**/
- (void) setRejectedQty: (int) aRejectedQty { myRejectedQty = aRejectedQty; }
- (void) addRejectedQty: (int) aRejectedQty { myRejectedQty += aRejectedQty; }
- (int) getRejectedQty { return myRejectedQty; }

/**/
- (COLLECTION) getZCloseDetails
{
	return myZCloseDetails;
}

/**/
- (void) addCashReferenceSummary: (CASH_REFERENCE) aCashReference 
	currency: (CURRENCY) aCurrency 
	amount: (money_t) anAmount 
	depositValueType: (DepositValueType) aDepositValueType
{
	int i;
	CASH_REFERENCE_SUMMARY summary;
	BOOL inCashReference = FALSE;
 	int index = -1;
	money_t valAmount;
	money_t manualAmount;
	int manualQty;

	manualAmount = 0;
	valAmount = 0;
	manualQty = 0;

	if (aDepositValueType == DepositValueType_VALIDATED_CASH)
		valAmount = anAmount;
	else {
		manualAmount = anAmount;
		manualQty = 1;
	}
	// Los agregar ordenados por cash reference
	for (i = 0; i < [myCashReferenceSummaries size]; ++i) {

		if ([[myCashReferenceSummaries at: i] getCashReference] == aCashReference) {

			inCashReference = TRUE;

			if ([[myCashReferenceSummaries at: i] getCurrency] == aCurrency) {
				[[myCashReferenceSummaries at: i] addAmount: anAmount];
			
				if (aDepositValueType == DepositValueType_VALIDATED_CASH)
					[[myCashReferenceSummaries at: i] addValAmount: valAmount];
				else {
					[[myCashReferenceSummaries at: i] addManualAmount: manualAmount];
					[[myCashReferenceSummaries at: i] addManualQty: manualQty];
				}

				return;
			}

		} else if (inCashReference) {
			index = i;
			break;
		}

	}

	summary = [CashReferenceSummary newCashReferenceSummary: aCashReference
		currency: aCurrency
		amount: anAmount
		valAmount: valAmount
		manualAmount: manualAmount
 		manualQty: manualQty];

	if (index == -1)
		[myCashReferenceSummaries add: summary];
	else 
		[myCashReferenceSummaries at: index insert: summary];


}

/**/
- (ZCLOSE_DETAIL) addCashCloseDetail: (CIM_CASH) aCimCash
	acceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings
	depositValueType: (DepositValueType) aDepositValueType
	currency: (CURRENCY) aCurrency
	qty: (int) aQty
	amount: (money_t) anAmount
{
	ZCLOSE_DETAIL zCloseDetail;
	int i;

	for (i = 0; i < [myZCloseDetails size]; ++i) {

		zCloseDetail = [myZCloseDetails at: i];

		if ([zCloseDetail getCimCash] != aCimCash) continue;
		if ([zCloseDetail getAcceptorSettings] != anAcceptorSettings) continue;
		if ([zCloseDetail getDepositValueType] != aDepositValueType) continue;

		// Estoy en la misma moneda
		if ([zCloseDetail getCurrency] == aCurrency) {

			[zCloseDetail setAmount: [zCloseDetail getAmount] + anAmount];
			[zCloseDetail addQty: aQty];
			return zCloseDetail;
		}


	}


	zCloseDetail = [ZCloseDetail new];
	[zCloseDetail setAmount: anAmount];
	[zCloseDetail setCurrency: aCurrency];
	[zCloseDetail setCimCash: aCimCash];
	[zCloseDetail setAcceptorSettings: anAcceptorSettings];
	[zCloseDetail setDepositValueType: aDepositValueType];
	[zCloseDetail addQty: aQty];

	[myZCloseDetails add: zCloseDetail];

	return myZCloseDetails;
}


/**/
- (ZCLOSE_DETAIL) addZCloseDetail: 
		(USER) aUser
		door: (DOOR) aDoor
		cimCash: (CIM_CASH) aCimCash
		cashReference: (CASH_REFERENCE) aCashReference
		acceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings
		depositValueType: (DepositValueType) aDepositValueType
		currency: (CURRENCY) aCurrency
		qty: (int) aQty
		amount: (money_t) anAmount
{
	ZCLOSE_DETAIL zCloseDetail;
	int i;
	int index = -1;
	BOOL inCurrency = FALSE;
	money_t amount;

	// Agrego el cash reference summary (si corresponde)
	// Como el importe me viene diference para el deposito manual (el total)
	// y el validado (el unitario) aca hago la diferencia
	if (aCashReference != NULL) {
		if (aDepositValueType != DepositValueType_VALIDATED_CASH) amount = anAmount;
		else amount = anAmount * aQty;
		[self addCashReferenceSummary: aCashReference currency: aCurrency amount: amount depositValueType: aDepositValueType];
	}

	for (i = 0; i < [myZCloseDetails size]; ++i) {

		zCloseDetail = [myZCloseDetails at: i];

		// Me adelanto hasta que coincida el usuario, la puerta, el cash, el validador y el tipo de deposito
		if ([zCloseDetail getUser] != aUser) continue;
		if ([zCloseDetail getDoor] != aDoor) continue;
		if ([zCloseDetail getCimCash] != aCimCash) continue;
		if ([zCloseDetail getAcceptorSettings] != anAcceptorSettings) continue;
		if ([zCloseDetail getDepositValueType] != aDepositValueType) continue;

		// Cambio la moneda que estaba analizando (paso a otra), lo tengo que
		// insertar aca el detalle
		if ([zCloseDetail getCurrency] != aCurrency && inCurrency) {
			index = i;
			break;
		}

		// Estoy en la misma moneda
		if ([zCloseDetail getCurrency] == aCurrency) {

			// Si la caja es manual, no totalizo por billete sino hasta el nivel moneda
			// En ese caso tengo que incremental el importe del detalle unicamente
			if ([aCimCash getDepositType] == DepositType_MANUAL) {
				[zCloseDetail setAmount: [zCloseDetail getAmount] + anAmount];
				[zCloseDetail addQty: aQty];
				return zCloseDetail;
			}

			inCurrency = TRUE;

			// Si encuentra la misma denominacion, aumento la cantidad y me voy
			if ([zCloseDetail getAmount] == anAmount) {
				[zCloseDetail addQty: aQty];
				return zCloseDetail;
			}

			// Si ya me pase a una denominacion mayor, tengo que insertarlo aca
			if ([zCloseDetail getAmount] > anAmount) {
				index = i;
				break;
			}

		}

	}


	zCloseDetail = [ZCloseDetail new];
	[zCloseDetail setDepositValueType: aDepositValueType];
	[zCloseDetail setUser: aUser];
	[zCloseDetail setCimCash: aCimCash];
	[zCloseDetail setDoor: aDoor];
	[zCloseDetail setQty: aQty];
	[zCloseDetail setAmount: anAmount];
	[zCloseDetail setCurrency: aCurrency];
	[zCloseDetail setAcceptorSettings: anAcceptorSettings];

	if (index != -1) {
		[myZCloseDetails at: index insert: zCloseDetail];
	} else {
		[myZCloseDetails add: zCloseDetail];
	}

	return zCloseDetail;
}

/**/
- (ZCLOSE_DETAIL) addZCloseDetailSummary: (COLLECTION) aCollection
		door: (DOOR) aDoor
		cimCash: (CIM_CASH) aCimCash
		acceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings
		depositValueType: (DepositValueType) aDepositValueType
		currency: (CURRENCY) aCurrency
		qty: (int) aQty
		amount: (money_t) anAmount
{
	ZCLOSE_DETAIL zCloseDetail;
	int i;
	int index = -1;
	BOOL inCurrency = FALSE;

	for (i = 0; i < [aCollection size]; ++i) {

		zCloseDetail = [aCollection at: i];

		// Me adelanto hasta que coincida el usuario, la puerta, el cash, el validador y el tipo de deposito
		if ([zCloseDetail getDoor] != aDoor) continue;
		if ([zCloseDetail getCimCash] != aCimCash) continue;
		if ([zCloseDetail getAcceptorSettings] != anAcceptorSettings) continue;
		if ([zCloseDetail getDepositValueType] != aDepositValueType) continue;

		// Cambio la moneda que estaba analizando (paso a otra), lo tengo que
		// insertar aca el detalle
		if ([zCloseDetail getCurrency] != aCurrency && inCurrency) {
			index = i;
			break;
		}

		// Estoy en la misma moneda
		if ([zCloseDetail getCurrency] == aCurrency) {

			// Si la caja es manual, no totalizo por billete sino hasta el nivel moneda
			// En ese caso tengo que incremental el importe del detalle unicamente
			if ([aCimCash getDepositType] == DepositType_MANUAL) {
				[zCloseDetail setAmount: [zCloseDetail getAmount] + anAmount];
				[zCloseDetail addQty: aQty];
				return zCloseDetail;
			}

			inCurrency = TRUE;

			// Si encuentra la misma denominacion, aumento la cantidad y me voy
			if ([zCloseDetail getAmount] == anAmount) {
				[zCloseDetail addQty: aQty];
				return zCloseDetail;
			}

			// Si ya me pase a una denominacion mayor, tengo que insertarlo aca
			if ([zCloseDetail getAmount] > anAmount) {
				index = i;
				break;
			}

		}

	}


	zCloseDetail = [ZCloseDetail new];
	[zCloseDetail setDepositValueType: aDepositValueType];
	[zCloseDetail setUser: NULL];
	[zCloseDetail setCimCash: aCimCash];
	[zCloseDetail setDoor: aDoor];
	[zCloseDetail setQty: aQty];
	[zCloseDetail setAmount: anAmount];
	[zCloseDetail setCurrency: aCurrency];
	[zCloseDetail setAcceptorSettings: anAcceptorSettings];

	if (index != -1) {
		[aCollection at: index insert: zCloseDetail];
	} else {
		[aCollection add: zCloseDetail];
	}

	return zCloseDetail;
}

/**/
- (COLLECTION) getZCloseDetailsSummary
{
	COLLECTION list = [Collection new];
	ZCLOSE_DETAIL zCloseDetail;
	ZCLOSE_DETAIL newZCloseDetail;
	int i;

	for (i = 0; i < [myZCloseDetails size]; ++i) {

		zCloseDetail = [myZCloseDetails at: i];
    
    //************************* logcoment
/*    if ([zCloseDetail getDoor] == NULL)
      doLog(0,"[zCloseDetail getDoor] == NULL *****************\n");
    if ([zCloseDetail getCimCash] == NULL)
      doLog(0,"[zCloseDetail getCimCash] == NULL *****************\n");      
    if ([zCloseDetail getAcceptorSettings] == NULL)
      doLog(0,"[zCloseDetail getAcceptorSettings] == NULL *****************\n");
    if ([zCloseDetail getCurrency] == NULL)
      doLog(0,"[zCloseDetail getCurrency] == NULL *****************\n");
*/
		newZCloseDetail = [self addZCloseDetailSummary: list
			door: [zCloseDetail getDoor]
			cimCash: [zCloseDetail getCimCash]
			acceptorSettings: [zCloseDetail getAcceptorSettings]
			depositValueType: [zCloseDetail getDepositValueType]
			currency: [zCloseDetail getCurrency]
			qty: [zCloseDetail getQty]
			amount: [zCloseDetail getAmount]];

	}

	return list;
}

/**/
- (COLLECTION) getZCloseDetailsByUser: (USER) aUser
{
	COLLECTION list = [Collection new];
	int i;

	for (i = 0; i < [myZCloseDetails size]; ++i) {
/** @todo: TENER CUIDADO QUE ACA ESTABA COMPARANDO LA REFERENCIA DEL USUARIO Y ERA DIFERENTE
 		PORQUE EL USER MANAGER CREA DOS LISTAS SEPARADAS DE USUARIOS ENTONCES NO SIEMPRE PUEDO
		COMPARAR LA REFERENCIA. LO MEJOR SERIA QUE SE CREARA SIEMPRE UN UNICO USUARIO Y LISTO
		DESPUES SE AGREGA A LA LISTA DE ACTIVOS O NO DEPENDIENDO DEL ESTADO.
		REVISAR ESTE MISMO COMPORAMIENTO PARA TODAS LAS ENTIDADES ELIMINABLES DEL SISTEMA */
		if ([[[myZCloseDetails at:i] getUser] getUserId] == [aUser getUserId]) 
			[list add: [myZCloseDetails at:i]];
	}

	return list;
}


/**/
- (int) getDetailCount: (COLLECTION) aSourceCollection
{
	if (aSourceCollection == NULL) aSourceCollection = myZCloseDetails;
	return [aSourceCollection size];
}

/**/
- (COLLECTION) getCimCashs: (COLLECTION) aSourceCollection
{
	COLLECTION list = [Collection new];
	int i;

	if (aSourceCollection == NULL) aSourceCollection = myZCloseDetails;
	
	for (i = 0; i < [aSourceCollection size]; ++i) {
		if (![list contains: [[aSourceCollection at: i] getCimCash]])
			[list add: [[aSourceCollection at: i] getCimCash]];
	}

	return list;
}

/**/
- (money_t) getTotalAmountByCurreny: (COLLECTION) aSourceCollection currency: (CURRENCY) aCurrency
{
  money_t total = 0;
  int i;
  
	if (aSourceCollection == NULL) aSourceCollection = myZCloseDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		if ([[aSourceCollection at: i] getCurrency] == aCurrency)
			total += [[aSourceCollection at: i] getTotalAmount];
	}
	
	return total;
}

/**/
- (money_t) getCashCloseTotalAmountByCurreny: (COLLECTION) aSourceCollection currency: (CURRENCY) aCurrency
{
  money_t total = 0;
  int i;
  
	if (aSourceCollection == NULL) aSourceCollection = myZCloseDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		if ([[aSourceCollection at: i] getCurrency] == aCurrency)
			total += [[aSourceCollection at: i] getAmount];
	}
	
	return total;
}

/**/
- (money_t) getCashReferenceTotalAmountByCurreny: (COLLECTION) aSourceCollection currency: (CURRENCY) aCurrency reference: (CASH_REFERENCE) aReference totalManual: (money_t*) aTotalManual totalVal: (money_t*) aTotalVal manualQty: (int*) aManualQty
{
  money_t total = 0;
  int i;
  
  *aTotalManual = 0;
  *aTotalVal = 0;
  *aManualQty = 0;

	if (aSourceCollection == NULL) aSourceCollection = myCashReferenceSummaries;

	for (i = 0; i < [aSourceCollection size]; ++i) {
	  if ( (aReference == NULL) || ((aReference != NULL) && ([[aSourceCollection at: i] getCashReference] == aReference)) ) {
  		if ([[aSourceCollection at: i] getCurrency] == aCurrency){
  			total += [[aSourceCollection at: i] getAmount];
				*aTotalManual += [[aSourceCollection at: i] getManualAmount];
				*aManualQty+= [[aSourceCollection at: i] getManualQty];
				*aTotalVal += [[aSourceCollection at: i] getValAmount];
			}
		}
	}
	
	return total;
}

/**/
- (COLLECTION) getDetailsByCimCash: (COLLECTION) aSourceCollection cimCash: (CIM_CASH) aCimCash
{
	COLLECTION list = [Collection new];
	int i;

	if (aSourceCollection == NULL) aSourceCollection = myZCloseDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		if ([[aSourceCollection at: i] getCimCash] == aCimCash)
			[list add: [aSourceCollection at: i]];
	}

	return list;
}

/**/
- (COLLECTION) getAcceptorSettingsList: (COLLECTION) aSourceCollection
{
	COLLECTION list = [Collection new];
	int i;

	if (aSourceCollection == NULL) aSourceCollection = myZCloseDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		if (![list contains: [[aSourceCollection at: i] getAcceptorSettings]])
			[list add: [[aSourceCollection at: i] getAcceptorSettings]];
	}

	return list;
}


/**/
- (COLLECTION) getDetailsByAcceptorSettings: (COLLECTION) aSourceCollection 
	acceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings
{
	COLLECTION list = [Collection new];
	int i;

	if (aSourceCollection == NULL) aSourceCollection = myZCloseDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		if ([[aSourceCollection at: i] getAcceptorSettings] == anAcceptorSettings)
			[list add: [aSourceCollection at: i]];
	}

	return list;
}


/**/
- (COLLECTION) getCurrencies: (COLLECTION) aSourceCollection
{
	COLLECTION list = [Collection new];
	int i;

	if (aSourceCollection == NULL) aSourceCollection = myZCloseDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		if (![list contains: [[aSourceCollection at: i] getCurrency]])
			[list add: [[aSourceCollection at: i] getCurrency]];
	}

	return list;
}


/**/
- (COLLECTION) getDetailsByCurrency: (COLLECTION) aSourceCollection currency: (CURRENCY) aCurrency
{
	COLLECTION list = [Collection new];
	int i;

	if (aSourceCollection == NULL) aSourceCollection = myZCloseDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		if ([[aSourceCollection at: i] getCurrency] == aCurrency)
			[list add: [aSourceCollection at: i]];
	}

	return list;
}

/**/
- (int) getQty: (COLLECTION) aSourceCollection
{
	int i;
	int qty = 0;

	if (aSourceCollection == NULL) aSourceCollection = myZCloseDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		qty += [[aSourceCollection at: i] getQty];
	}

	return qty;
}

/**/
- (money_t) getTotalAmount: (COLLECTION) aSourceCollection
{
	int i;
	money_t amount = 0;

	if (aSourceCollection == NULL) aSourceCollection = myZCloseDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		amount += [[aSourceCollection at: i] getTotalAmount];
	}

	return amount;
}

/**/
- (money_t) getCashCloseTotalAmount: (COLLECTION) aSourceCollection
{
	int i;
	money_t amount = 0;

	if (aSourceCollection == NULL) aSourceCollection = myZCloseDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		amount += [[aSourceCollection at: i] getAmount];
	}

	return amount;
}

/**/
- (COLLECTION) getValidatedDetails: (COLLECTION) aSourceCollection
{
	COLLECTION list = [Collection new];
	int i;

	if (aSourceCollection == NULL) aSourceCollection = myZCloseDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		if ([[aSourceCollection at: i] getDepositValueType] == DepositValueType_VALIDATED_CASH)
			[list add: [aSourceCollection at: i]];
	}

	return list;
}

/**/
- (COLLECTION) getManualDetails: (COLLECTION) aSourceCollection
{

	COLLECTION list = [Collection new];
	int i;

	if (aSourceCollection == NULL) aSourceCollection = myZCloseDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		if ([[aSourceCollection at: i] getDepositValueType] != DepositValueType_VALIDATED_CASH)
			[list add: [aSourceCollection at: i]];
	}

	return list;
}

/**/
- (BOOL) hasDetails
{
	return [myZCloseDetails size] > 0;
}

/**/
- (COLLECTION) getCashReferences
{
	COLLECTION list = [Collection new];
	int i;

	for (i = 0; i < [myCashReferenceSummaries size]; ++i) {
		if (![list contains: [[myCashReferenceSummaries at: i] getCashReference]])
			[list add: [[myCashReferenceSummaries at: i] getCashReference]];
	}

	return list;
}

/**/
- (COLLECTION) getCashReferenceSummaries: (CASH_REFERENCE) aCashReference
{
	COLLECTION list = [Collection new];
	int i;
	
	for (i = 0; i < [myCashReferenceSummaries size]; ++i) {
		if ([[myCashReferenceSummaries at: i] getCashReference] == aCashReference)
			[list add: [myCashReferenceSummaries at: i]];
	}

	return list;
}

/**/
- (COLLECTION) getUsersList
{
	COLLECTION list = [Collection new];
	int i;

	for (i = 0; i < [myZCloseDetails size]; ++i) {
		if (![list contains: [[myZCloseDetails at: i] getUser]])
			[list add: [[myZCloseDetails at: i] getUser]];
	}

	return list;
}

/**/
- (void) setCloseType: (CloseType) aValue { myCloseType = aValue; }
- (CloseType) getCloseType { return myCloseType; }

/**/
- (void) setCimCash: (CIM_CASH) aValue { myCimCash = aValue; }
- (CIM_CASH) getCimCash { return myCimCash; }

/**/
- (BOOL) isOpen { return myCloseTime == 0; }

/**/
- (BOOL) includesDeposit: (unsigned long) aDepositNumber
{
	if (aDepositNumber < myFromDepositNumber) return FALSE;
	if (myToDepositNumber == 0 && [self isOpen]) return TRUE;
	if (aDepositNumber <= myToDepositNumber) return TRUE;
	return FALSE;
}

/**/
- (void) setFromCloseNumber: (unsigned long) aValue { myFromCloseNumber = aValue; }
- (unsigned long) getFromCloseNumber { return myFromCloseNumber; }

/**/
- (void) setToCloseNumber: (unsigned long) aValue { myToCloseNumber = aValue; }
- (unsigned long) getToCloseNumber { return myToCloseNumber; }

/**/
- (void) setParentNumber: (unsigned long) aValue { myParentNumber = aValue; }
- (unsigned long) getParentNumber { return myParentNumber; }

/**/
- (void) setParentCloseTime: (datetime_t) aValue { myParentCloseTime = aValue; }
- (datetime_t) getParentCloseTime { return myParentCloseTime; }

/**/
- (void) updateDepData: (id) aDepositRS
{
	unsigned long number = [aDepositRS getLongValue: "NUMBER"];

	if (number < myFromDepositNumber) return;

	if (myCloseType == CloseType_END_OF_DAY) {

		if (myFromDepositNumber == 0) myFromDepositNumber = number;
		myToDepositNumber = number;

	}

	if (myCloseType == CloseType_CASH_CLOSE) {

		if ([aDepositRS getShortValue: "CIM_CASH_ID"] == [myCimCash getCimCashId]) {
			if (myFromDepositNumber == 0) myFromDepositNumber = number;
			myToDepositNumber = number;
		}

	}

}

/**/
- (void) updateDepDetData: (id) aDepositRS depositDetailRS: (id) aDepositDetailRS user: (id) aUser currency: (id) aCurrency
{
	id cimCash;
	id door;
	id cashReference = NULL;
	id acceptorSettings;
	money_t amount;
	unsigned long number = [aDepositRS getLongValue: "NUMBER"];

	if (number < myFromDepositNumber) return;

	cimCash = [[CimManager getInstance] getCimCashById: [aDepositRS getShortValue: "CIM_CASH_ID"]];

	if (myCloseType == CloseType_END_OF_DAY) {

		door = [[CimManager getInstance] getDoorById: [aDepositRS getShortValue: "DOOR_ID"]];

		if ([aDepositRS getShortValue: "REFERENCE_ID"] != 0) 
			cashReference = [[CashReferenceManager getInstance] getCashReferenceById: [aDepositRS getShortValue: "REFERENCE_ID"]];

		acceptorSettings = [[CimManager getInstance] getAcceptorSettingsById: [aDepositDetailRS getShortValue: "ACCEPTOR_ID"]];

		// Agrego el detalle
		[self addZCloseDetail: aUser
			door: door
			cimCash: cimCash
			cashReference: cashReference
			acceptorSettings: acceptorSettings
			depositValueType: [aDepositDetailRS getCharValue: "DEPOSIT_VALUE_TYPE"]
			currency: aCurrency
			qty: [aDepositDetailRS getShortValue: "QTY"]
			amount: [aDepositDetailRS getMoneyValue: "AMOUNT"]];


	}

	if (myCloseType == CloseType_CASH_CLOSE) {

		if ([cimCash getCimCashId] != [myCimCash getCimCashId]) return;

		if ([aDepositDetailRS getCharValue: "DEPOSIT_VALUE_TYPE"] == DepositValueType_VALIDATED_CASH)
			amount = [aDepositDetailRS getMoneyValue: "AMOUNT"] * [aDepositDetailRS getShortValue: "QTY"];
		else
			amount = [aDepositDetailRS getMoneyValue: "AMOUNT"];

		acceptorSettings = [[CimManager getInstance] getAcceptorSettingsById: [aDepositDetailRS getShortValue: "ACCEPTOR_ID"]];

		[self addCashCloseDetail: cimCash
			acceptorSettings: acceptorSettings
			depositValueType: DepositValueType_MANUAL_CASH
			currency: aCurrency
			qty: [aDepositDetailRS getShortValue: "QTY"]
			amount: amount];
	
	}


}


#ifdef __DEBUG_CIM
/**/
- (void) debug
{
/*
	int i;

	doLog(0, "*******************************\n");
	doLog(0, "*******************************\n");
	doLog(0, "CLOSE Numero:       %ld\n", myNumber);
	doLog(0, "Tipo:   %ld\n", myCloseType);
	doLog(0, "*******************************\n");
	doLog(0, "From Deposit: %ld\n", myFromDepositNumber); 
	doLog(0, "To Deposit:   %ld\n", myToDepositNumber);
	doLog(0, "Detalle -----------------------\n");

	for (i = 0; i < [myZCloseDetails size]; ++i)
		[[myZCloseDetails at: i] debug];

	doLog(0, "*******************************\n");
	doLog(0, "*******************************\n");
*/	
}

#endif

@end
