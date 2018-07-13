#include "Extraction.h"
#include "CimGeneralSettings.h"

@implementation Extraction

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myDoor = NULL;
	myExtractionDetails = [Collection new];
	myCashCloses = [Collection new];
	myCashReferenceSummaries = [Collection new];
	myBagTrackingCollection = NULL;
	myEnvelopeTrackingCollection = NULL;
	myBagNumber[0] = '\0';
	myBagTrackingMode = BagTrackingMode_NONE;
	[self clear];
	return self;
}

/**/
- (void) clear
{
	myOperator = NULL;
	myCollector = NULL;
	myNumber = 0;
	myDateTime = 0;
	myFromDepositNumber = 0;
	myToDepositNumber = 0;
	myRejectedQty = 0;
	*myBankAccountInfo = '\0';
	myFromCloseNumber = 0;
	myToCloseNumber = 0;
	myCurrentManualDepositCount = 0;
	myHasEmitStackerWarning = FALSE;
	myHasEmitStackerFull = FALSE;
	[myExtractionDetails freeContents];
	[myCashCloses freeContents];
	[myCashReferenceSummaries freeContents];
	myBagTrackingCollection = NULL;
	myEnvelopeTrackingCollection = NULL;
	myBagNumber[0] = '\0';
	myHasBagTracking = FALSE; // solo se utiliza para la reimpresion de extraciones
}

/**/
- free
{
	[myExtractionDetails freeContents];
	[myExtractionDetails free];

	[myCashCloses freeContents];
	[myCashCloses free];

	return [super free];
}

/**/
- (void) setOperator: (USER) aValue { myOperator = aValue; }
- (USER) getOperator { return myOperator; }

/**/
- (void) setCollector: (USER) aValue { myCollector = aValue; }
- (USER) getCollector { return myCollector; }

/**/
- (void) setNumber: (unsigned long) aNumber { myNumber = aNumber; }
- (unsigned long) getNumber { return myNumber; }
					
/**/
- (void) setDateTime: (datetime_t) aDateTime { myDateTime = aDateTime; }
- (datetime_t) getDateTime { return myDateTime; }

/**/
- (void) setFromDepositNumber: (unsigned long) aValue { myFromDepositNumber = aValue; }
- (unsigned long) getFromDepositNumber { return myFromDepositNumber; }

/**/
- (void) setToDepositNumber: (unsigned long) aValue { myToDepositNumber = aValue; }
- (unsigned long) getToDepositNumber { return myToDepositNumber; }

/**/
- (void) setBankAccountInfo: (char *) aBankAccountInfo { stringcpy(myBankAccountInfo, aBankAccountInfo); }
- (char *) getBankAccountInfo { return myBankAccountInfo; }

/**/
- (void) setRejectedQty: (int) aRejectedQty { myRejectedQty = aRejectedQty; }
- (void) addRejectedQty: (int) aRejectedQty { myRejectedQty += aRejectedQty; }
- (int) getRejectedQty { return myRejectedQty; }

/**/
- (void) setDoor: (DOOR) aDoor { myDoor = aDoor; }
- (DOOR) getDoor { return myDoor; }

/**/
- (COLLECTION) getExtractionDetails
{
 return myExtractionDetails;
}

/**/
- (EXTRACTION_DETAIL) addExtractionDetail: (CIM_CASH) aCimCash
		acceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings
		depositValueType: (DepositValueType) aDepositValueType
		currency: (CURRENCY) aCurrency
		qty: (int) aQty
		amount: (money_t) anAmount
		cashReference: (CASH_REFERENCE) aCashReference
{
	EXTRACTION_DETAIL extractionDetail;
	int i;
	int index = -1;
	BOOL inCurrency = FALSE;
	int count = [myExtractionDetails size];
	money_t amount;
	DepositType depositType;

	// Agrego el cash reference summary (si corresponde)
	// Como el importe me viene diference para el deposito manual (el total)
	// y el validado (el unitario) aca hago la diferencia
	if (aCashReference != NULL) {
		if (aDepositValueType != DepositValueType_VALIDATED_CASH) amount = anAmount;
		else amount = anAmount * aQty;

		if ([anAcceptorSettings getAcceptorType] == AcceptorType_VALIDATOR)
			depositType = DepositType_AUTO;
		else
			depositType = DepositType_MANUAL;

		[self addCashReferenceSummary: aCashReference currency: aCurrency amount: amount
					depositValueType: aDepositValueType
					depositType: depositType];
	}

	for (i = 0; i < count; ++i) {

		extractionDetail = [myExtractionDetails at: i];

		// Me adelanto hasta que coincida el validador y el tipo de valor
		if ([extractionDetail getAcceptorSettings] != anAcceptorSettings) continue;
		if ([extractionDetail getDepositValueType] != aDepositValueType) continue;
		if ([extractionDetail getCimCash] != aCimCash) continue;

		if ([extractionDetail getCurrency] != aCurrency && inCurrency) {
			index = i;
			break;
		}

		// Estoy en la misma moneda
		if ([extractionDetail getCurrency] == aCurrency) {

			// Si la caja es manual, no totalizo por billete sino hasta el nivel moneda
			// En ese caso tengo que incremental el importe del detalle unicamente
			if ([aCimCash getDepositType] == DepositType_MANUAL) {
				[extractionDetail setAmount: [extractionDetail getAmount] + anAmount];
				[extractionDetail addQty: aQty];
				return extractionDetail;
			}

			inCurrency = TRUE;

			// Si encuentra la misma denominacion, aumento la cantidad y me voy
			if ([extractionDetail getAmount] == anAmount) {
				[extractionDetail addQty: aQty];
				return extractionDetail;
			}

			// Si ya me pase a una denominacion mayor, tengo que insertarlo aca
			if ([extractionDetail getAmount] > anAmount) {
				index = i;
				break;
			}

		}
	}

	extractionDetail = [ExtractionDetail new];
	[extractionDetail setDepositValueType: aDepositValueType];
	[extractionDetail setAmount: anAmount];
	[extractionDetail setQty: aQty];
	[extractionDetail setCimCash: aCimCash];
	[extractionDetail setCurrency: aCurrency];
	[extractionDetail setAcceptorSettings: anAcceptorSettings];

	if (index != -1) {
		[myExtractionDetails at: index insert: extractionDetail];
	} else {
		[myExtractionDetails add: extractionDetail];
	}

	return extractionDetail;
}

/**/
- (int) getDetailCount: (COLLECTION) aSourceCollection
{
	if (aSourceCollection == NULL) aSourceCollection = myExtractionDetails;
	return [aSourceCollection size];
}

/**/
- (COLLECTION) getCimCashs: (COLLECTION) aSourceCollection
{
	COLLECTION list = [Collection new];
	int i;

	if (aSourceCollection == NULL) aSourceCollection = myExtractionDetails;
	
	for (i = 0; i < [aSourceCollection size]; ++i) {
		if (![list contains: [[aSourceCollection at: i] getCimCash]])
			[list add: [[aSourceCollection at: i] getCimCash]];
	}

	return list;
}

/**/
- (COLLECTION) getDetailsByCimCash: (COLLECTION) aSourceCollection cimCash: (CIM_CASH) aCimCash
{
	COLLECTION list = [Collection new];
	int i;

	if (aSourceCollection == NULL) aSourceCollection = myExtractionDetails;

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

	if (aSourceCollection == NULL) aSourceCollection = myExtractionDetails;

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

	if (aSourceCollection == NULL) aSourceCollection = myExtractionDetails;

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

	if (aSourceCollection == NULL) aSourceCollection = myExtractionDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		if (![list contains: [[aSourceCollection at: i] getCurrency]])
			[list add: [[aSourceCollection at: i] getCurrency]];
	}

	return list;
}

/**/
- (money_t) getTotalAmountByCurreny: (COLLECTION) aSourceCollection currency: (CURRENCY) aCurrency
{
  money_t total = 0;
  int i;
  
	if (aSourceCollection == NULL) aSourceCollection = myExtractionDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		if ([[aSourceCollection at: i] getCurrency] == aCurrency)
			total += [[aSourceCollection at: i] getTotalAmount];
	}
	
	return total;
}

/**/
- (COLLECTION) getDetailsByCurrency: (COLLECTION) aSourceCollection currency: (CURRENCY) aCurrency
{
	COLLECTION list = [Collection new];
	int i;

	if (aSourceCollection == NULL) aSourceCollection = myExtractionDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		if ([[aSourceCollection at: i] getCurrency] == aCurrency)
			[list add: [aSourceCollection at: i]];
	}

	return list;
}

/**/
- (int) getQtyByAcceptor: (ACCEPTOR_SETTINGS) anAcceptorSettings
{
	int i;
	int qty = 0;

	for (i = 0; i < [myExtractionDetails size]; ++i) {
		if ([[myExtractionDetails at: i] getAcceptorSettings] == anAcceptorSettings)
			qty += [[myExtractionDetails at: i] getQty];
	}

	return qty;
}

/**/
- (int) getQty: (COLLECTION) aSourceCollection
{
	int i;
	int qty = 0;

	if (aSourceCollection == NULL) aSourceCollection = myExtractionDetails;

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

	if (aSourceCollection == NULL) aSourceCollection = myExtractionDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		amount += [[aSourceCollection at: i] getTotalAmount];
	}

	return amount;
}

/**/
- (void) addCashClose: (ZCLOSE) aCashClose
{
	[myCashCloses add: aCashClose];
}

- (ZCLOSE) getCashClose: (CIM_CASH) aCimCash depositNumber: (unsigned long) aDepositNumber
{
	int i;
	ZCLOSE cashClose;

	for (i = 0; i < [myCashCloses size]; ++i) {

		cashClose = [myCashCloses at: i];
		if ([cashClose getCimCash] != aCimCash) continue;
		if ([cashClose includesDeposit: aDepositNumber]) return cashClose;

	}	

	return NULL;
}

/**/
- (COLLECTION) getCashCloses
{
	return myCashCloses;
}

/**/
- (void) setFromCloseNumber: (unsigned long) aFromCloseNumber { myFromCloseNumber = aFromCloseNumber; }
- (void) setToCloseNumber: (unsigned long) aToCloseNumber { myToCloseNumber = aToCloseNumber; }

/**/
- (unsigned long) getFromCloseNumber { 
	if ([myCashCloses size] > 0) return [[myCashCloses firstElement] getNumber];
	return myFromCloseNumber; 
}

/**/
- (unsigned long) getToCloseNumber { 
	if ([myCashCloses size] > 0) return [[myCashCloses lastElement] getNumber];
	return myToCloseNumber; 

}

/**/
- (BOOL) hasEndOfDay: (COLLECTION) aList value: (unsigned long) aValue
{
	int i;

	for (i = 0; i < [aList size]; ++i) {
		if ([[aList at: i] intValue] == aValue) 
		return TRUE;
	}

	return FALSE;
}

/**/
- (COLLECTION) getEndOfDayNumbers
{
	COLLECTION list = [Collection new];
	id obj;
	int i;
	unsigned long nro;

	for (i = 0; i < [myCashCloses size]; ++i) {

		nro = [[myCashCloses at: i] getParentNumber];
		if (![self hasEndOfDay: list value: nro]) {
			obj = [BigInt int: nro];
			[list add: obj];
		}

	}

	return list;

}

/**/
- (COLLECTION) getCashClosesForEndOfDay: (unsigned long) aCloseNumber
{
	int i;
	COLLECTION list = [Collection new];

	for (i = 0; i < [myCashCloses size]; ++i) {
		if ([[myCashCloses at: i] getParentNumber] == aCloseNumber)
			[list add: [myCashCloses at: i]];
	}

	return list;	
}

/**/
- (datetime_t) getEndDayCloseTime: (unsigned long) aCloseNumber
{
	int i;

	for (i = 0; i < [myCashCloses size]; ++i) {
		if ([[myCashCloses at: i] getParentNumber] == aCloseNumber)
			return [[myCashCloses at: i] getParentCloseTime];
	}

	return 0;
}


#ifdef __DEBUG_CIM
/**/
- (void) debug
{
	int i;
/*
	doLog(0,"*******************************\n");
	doLog(0,"Numero:     %ld\n", myNumber);
	doLog(0,"Puerta:     %d\n", myDoor != NULL ? [myDoor getDoorId]: 0);
	doLog(0,"Operador:   %s\n", myOperator != NULL ? [myOperator getLoginName] : "DESCONOCIDO");
	doLog(0,"Recaudador: %s\n", myCollector != NULL ? [myCollector getLoginName] : "DESCONOCIDO");
    */
	/*doLog(0,"Monto acumulado:     %s\n", formatMoney(moneyStr, "", [self getAmount], 2, 40));
	doLog(0,"Cantidad valores:    %d\n", [self getQty]);*/

    //doLog(0,"Detalle -----------------------\n");

	for (i = 0; i < [myExtractionDetails size]; ++i)
		[[myExtractionDetails at: i] debug];

	for (i = 0; i < [myCashCloses size]; ++i)
		[[myCashCloses at: i] debug];	
}

/**/
- (int) getCurrentManualDepositCount
{
	return myCurrentManualDepositCount;
}

/**/
- (void) incCurrentManualDepositCount
{
	myCurrentManualDepositCount++;
}

/**/
- (BOOL) hasEmitStackerWarning { return myHasEmitStackerWarning; }
- (void) setHasEmitStackerWarning: (BOOL) aValue { myHasEmitStackerWarning = aValue; }
- (BOOL) hasEmitStackerFull { return myHasEmitStackerFull; }
- (void) setHasEmitStackerFull: (BOOL) aValue { myHasEmitStackerFull = aValue; }

/**/
- (void) addCashReferenceSummary: (CASH_REFERENCE) aCashReference 
	currency: (CURRENCY) aCurrency 
	amount: (money_t) anAmount
	depositValueType: (DepositValueType) aDepositValueType
	depositType: (DepositType) aDepositType
{
	int i;
	CASH_REFERENCE_SUMMARY summary;
	BOOL inCashReference = FALSE;
 	int index = -1;

	// Los agregar ordenados por cash reference
	for (i = 0; i < [myCashReferenceSummaries size]; ++i) {

		if ([[myCashReferenceSummaries at: i] getCashReference] == aCashReference) {

			inCashReference = TRUE;

			if ([[myCashReferenceSummaries at: i] getDepositType] == aDepositType) {

				if ([[myCashReferenceSummaries at: i] getDepositValueType] == aDepositValueType) {
	
					if ([[myCashReferenceSummaries at: i] getCurrency] == aCurrency) {
						[[myCashReferenceSummaries at: i] addAmount: anAmount];
						return;
					}
				}
			}

		} else 
			if (inCashReference) {
				index = i;
				break;
			}

	}

	summary = [CashReferenceSummary newCashReferenceSummary: aCashReference
		currency: aCurrency
		amount: anAmount
		depositValueType: aDepositValueType
		depositType: aDepositType];

	if (index == -1)
		[myCashReferenceSummaries add: summary];
	else 
		[myCashReferenceSummaries at: index insert: summary];

}

/**/
- (money_t) getCashReferenceTotalAmountByCurrenyByDepType: (COLLECTION) aSourceCollection currency: (CURRENCY) aCurrency reference: (CASH_REFERENCE) aReference depositType: (DepositType) aDepositType
{
  money_t total = 0;
  int i;
  
	if (aSourceCollection == NULL) aSourceCollection = myCashReferenceSummaries;

	for (i = 0; i < [aSourceCollection size]; ++i) {
	  if ( (aReference == NULL) || ((aReference != NULL) && ([[aSourceCollection at: i] getCashReference] == aReference)) ) {
  		if ([[aSourceCollection at: i] getCurrency] == aCurrency)
				if ([[aSourceCollection at: i] getDepositType] == aDepositType)
  				total += [[aSourceCollection at: i] getAmount];
		}
	}
	
	return total;
}

/**/
- (money_t) getCashReferenceTotalAmountByCurrenyByDepTypeByValType: (COLLECTION) aSourceCollection currency: (CURRENCY) aCurrency reference: (CASH_REFERENCE) aReference depositType: (DepositType) aDepositType depositValueType: (DepositValueType) aDepositValueType
{
  money_t total = 0;
  int i;
  
	if (aSourceCollection == NULL) aSourceCollection = myCashReferenceSummaries;

	for (i = 0; i < [aSourceCollection size]; ++i) {
	  if ( (aReference == NULL) || ((aReference != NULL) && ([[aSourceCollection at: i] getCashReference] == aReference)) ) {
  		if ([[aSourceCollection at: i] getCurrency] == aCurrency)
				if ([[aSourceCollection at: i] getDepositType] == aDepositType)
					if ([[aSourceCollection at: i] getDepositValueType] == aDepositValueType)
						total += [[aSourceCollection at: i] getAmount];
		}
	}
	
	return total;
}

/**/
- (COLLECTION) getCashReferences: (DepositType) aDepositType
{
	COLLECTION list = [Collection new];
	int i;

	for (i = 0; i < [myCashReferenceSummaries size]; ++i) {
		if ([[myCashReferenceSummaries at: i] getDepositType] == aDepositType)
			if (![list contains: [[myCashReferenceSummaries at: i] getCashReference]])
				[list add: [[myCashReferenceSummaries at: i] getCashReference]];
	}

	return list;
}

/**/
- (COLLECTION) getCashReferencesByCurr: (DepositType) aDepositType currency: (id) aCurrency
{
	COLLECTION list = [Collection new];
	int i;

	for (i = 0; i < [myCashReferenceSummaries size]; ++i) {
		if ([[myCashReferenceSummaries at: i] getDepositType] == aDepositType)
			if ([[myCashReferenceSummaries at: i] getCurrency] == aCurrency)
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
- (BOOL) hasValue: (int) aValue list: (COLLECTION) aList
{
	int i;

	for (i = 0; i < [aList size]; ++i) {
		if ([[aList at: i] intValue] == aValue) return TRUE;
	}

	return FALSE;
}

/**/
- (COLLECTION) getDepositValueTypes: (CASH_REFERENCE) aCashReference depositType: (DepositType) aDepositType
{
	COLLECTION list = [Collection new];
	id obj;
	int i,nro;
	
	for (i = 0; i < [myCashReferenceSummaries size]; ++i) {
		if ([[myCashReferenceSummaries at: i] getCashReference] == aCashReference) {
			if ([[myCashReferenceSummaries at: i] getDepositType] == aDepositType) {
				nro = [[myCashReferenceSummaries at: i] getDepositValueType];
				if (![self hasValue: nro list: list]) {
					obj = [BigInt int: nro];
					[list add: obj];
				}
			}
		}
	}

	return list;
}

/**/
- (COLLECTION) getCurrenciesByDepType: (DepositType) aDepositType
{
	COLLECTION list = [Collection new];
	int i;

	for (i = 0; i < [myCashReferenceSummaries size]; ++i) {
		if ([[myCashReferenceSummaries at: i] getDepositType] == aDepositType)
			if (![list contains: [[myCashReferenceSummaries at: i] getCurrency]])
				[list add: [[myCashReferenceSummaries at: i] getCurrency]];
	}

	return list;
}

/**/
- (COLLECTION) getAllCashReferences
{
	return myCashReferenceSummaries;
}

/**/
- (void) setBagNumber: (char*) aBagNumber { stringcpy(myBagNumber, aBagNumber); }
- (char*) getBagNumber { return myBagNumber; }

/**/
- (void) setBagTrackingCollection: (COLLECTION) aCollection { myBagTrackingCollection = aCollection; }
- (COLLECTION) getBagTrackingCollection { return myBagTrackingCollection; }

/**/
- (void) setEnvelopeTrackingCollection: (COLLECTION) aCollection { myEnvelopeTrackingCollection = aCollection; }
- (COLLECTION) getEnvelopeTrackingCollection { return myEnvelopeTrackingCollection; }

/**/
- (void) setHasBagTracking: (BOOL) aValue { myHasBagTracking = aValue; }
- (BOOL) hasBagTracking { return myHasBagTracking; }

/**/
- (void) setBagTrackingMode: (int) aValue { myBagTrackingMode = aValue; }
- (int) getBagTrackingMode { return myBagTrackingMode; }


#endif

@end
