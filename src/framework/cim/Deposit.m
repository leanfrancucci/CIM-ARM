#include "CimExcepts.h"
#include "Deposit.h"
#include "system/util/all.h"

@implementation Deposit

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myDepositDetails = [Collection new];
	myRejectedQty = 0;
	myDepositType = DepositType_UNDEFINED;
	myNumber = 0;
	myOpenTime = 0;
	myCloseTime = 0;
	myUser = NULL;
	myDoor = NULL;
	myCimCash = NULL;
	*myEnvelopeNumber = '\0';
	*myBankAccountNumber = '\0';
	myCashReference = NULL;
	*myApplyTo = '\0';
	return self;
}

/**/
- free
{
	[myDepositDetails freeContents];
	[myDepositDetails free];
	return [super free];
}

/**/
- (money_t) getAmount
{
	int i;
	money_t amount = 0;

	for (i = 0; i < [myDepositDetails size]; ++i) {
		amount += [[myDepositDetails at: i] getTotalAmount];
	}

	return amount;
}

/**/
- (int) getQty
{
	int i;
	int qty = 0;

	for (i = 0; i < [myDepositDetails size]; ++i) {
		qty += [[myDepositDetails at: i] getQty];
	}

	return qty;

}

/**/
- (void) setUser: (USER) aUser { myUser = aUser; }
- (USER) getUser { return myUser; }

/**/
- (void) setNumber: (unsigned long) aNumber { myNumber = aNumber; }
- (unsigned long) getNumber { return myNumber; }

/**/
- (void) setOpenTime: (datetime_t) aValue { myOpenTime = aValue; }
- (datetime_t) getOpenTime { return myOpenTime; }

/**/
- (void) setCloseTime: (datetime_t) aValue { myCloseTime = aValue; }
- (datetime_t) getCloseTime { return myCloseTime; }

/**/
- (void) setEnvelopeNumber: (char *) anEnvelopeNumber { stringcpy(myEnvelopeNumber, anEnvelopeNumber); }
- (char *) getEnvelopeNumber { return myEnvelopeNumber; }

/**/
- (void) setBankAccountNumber: (char *) aBankAccountNumber { stringcpy(myBankAccountNumber, aBankAccountNumber); }
- (char *) getBankAccountNumber { return myBankAccountNumber; }

/**/
- (void) setCashReference: (CASH_REFERENCE) aCashReference { myCashReference = aCashReference; }
- (CASH_REFERENCE) getCashReference { return myCashReference; }

/**/
- (void) setDoor: (DOOR) aDoor { myDoor = aDoor; }
- (DOOR) getDoor { return myDoor; }

/**/
- (void) setRejectedQty: (int) aRejectedQty { myRejectedQty = aRejectedQty; }
- (void) addRejectedQty: (int) aRejectedQty { myRejectedQty += aRejectedQty; }
- (int) getRejectedQty { return myRejectedQty; }

/**/
- (void) setDepositType: (DepositType) aDepositType { myDepositType = aDepositType; }
- (DepositType) getDepositType { return myDepositType; }

/**/
- (void) setCimCash: (CIM_CASH) aValue { myCimCash = aValue; }
- (CIM_CASH) getCimCash { return myCimCash; }

/**/
- (void) setApplyTo: (char *) anApplyTo { stringcpy(myApplyTo, anApplyTo); }
- (char *) getApplyTo { return myApplyTo; }

/**/
- (DEPOSIT_DETAIL) addDepositDetail: (ACCEPTOR_SETTINGS) anAcceptorSettings
		depositValueType: (DepositValueType) aDepositValueType
		currency: (CURRENCY) aCurrency
		qty: (int) aQty
		amount: (money_t) anAmount
{
	DEPOSIT_DETAIL depositDetail;
	int i;
	int index = -1;
	BOOL inCurrency = FALSE;

	// Si es un deposito automatico, en primer lugar me fijo si ya estaba
	// ese detalle en la lista (para el mismo validador, tipo de valor, moneda y denominacion) e
	// incremento la cantidad en caso de encontrarlo, si no existe el detalle lo crea y lo agrega a la lista
  // en la posicion adecuada (ordenada por validador, tipo de deposito, moneda y denominacion)

	// En el caso de deposito manual siempre lo agrega al final de la lista

	if (myDepositType == DepositType_AUTO) {

		for (i = 0; i < [myDepositDetails size]; ++i) {

			depositDetail = [myDepositDetails at: i];

			// Me adelanto hasta que coincida el validador y el tipo de valor
			if ([depositDetail getAcceptorSettings] != anAcceptorSettings) continue;
			if ([depositDetail getDepositValueType] != aDepositValueType) continue;

			// Cambio la moneda que estaba analizando (paso a otra), lo tengo que
			// insertar aca el detalle
			if ([depositDetail getCurrency] != aCurrency && inCurrency) {
				index = i;
				break;
			}

			// Estoy en la misma moneda
			if ([depositDetail getCurrency] == aCurrency) {

				inCurrency = TRUE;

				// Si encuentra la misma denominacion, aumento la cantidad y me voy
				if ([depositDetail getAmount] == anAmount) {
					[depositDetail addQty: aQty];
					return depositDetail;
				}

				// Si ya me pase a una denominacion mayor, tengo que insertarlo aca
				if ([depositDetail getAmount] > anAmount) {
					index = i;
					break;
				}

			}

		}

	};

	// Controlo si se excede la cantidad maxima de detalle posible
	if ([myDepositDetails size] >= MAX_DEPOSIT_DETAIL_QTY) THROW(CIM_MAX_DEPOSIT_DETAIL_QTY_EX);

	depositDetail = [DepositDetail new];
	[depositDetail setDepositValueType: aDepositValueType];
	[depositDetail setAmount: anAmount];
	[depositDetail setQty: aQty];
	[depositDetail setCurrency: aCurrency];
	[depositDetail setAcceptorSettings: anAcceptorSettings];

	if (index != -1) {
		[myDepositDetails at: index insert: depositDetail];
	} else {
		[myDepositDetails add: depositDetail];
	}

	return depositDetail;
}

/**/
- (COLLECTION) getDepositDetails { return myDepositDetails; }

/**/
- (COLLECTION) getAcceptorSettingsList: (COLLECTION) aSourceCollection
{
	COLLECTION list = [Collection new];
	int i;

	if (aSourceCollection == NULL) aSourceCollection = myDepositDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		if (![list contains: [[aSourceCollection at: i] getAcceptorSettings]])
			[list add: [[aSourceCollection at: i] getAcceptorSettings]];
	}

	return list;
}

/**/
- (COLLECTION) getDetailsByAcceptor: (COLLECTION) aSourceCollection 
	acceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings
{
	COLLECTION list = [Collection new];
	int i;

	if (aSourceCollection == NULL) aSourceCollection = myDepositDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		if ([[aSourceCollection at: i] getAcceptorSettings] == anAcceptorSettings)
			[list add: [aSourceCollection at: i]];
	}

	return list;
}

/**/
- (COLLECTION) getDetailsByCurrency: (COLLECTION) aSourceCollection 
	currency: (CURRENCY) aCurrency
{
	COLLECTION list = [Collection new];
	int i;

	if (aSourceCollection == NULL) aSourceCollection = myDepositDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		if ([[aSourceCollection at: i] getCurrency] == aCurrency)
			[list add: [aSourceCollection at: i]];
	}

	return list;
}


/**/
- (COLLECTION) getCurrencies: (COLLECTION) aSourceCollection
{
	COLLECTION list = [Collection new];
	int i;

	if (aSourceCollection == NULL) aSourceCollection = myDepositDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		if (![list contains: [[aSourceCollection at: i] getCurrency]])
			[list add: [[aSourceCollection at: i] getCurrency]];
	}

	return list;
}

/**/
- (int) getDetailCount
{
	return [myDepositDetails size];
}


/**/
- (int) getQty: (COLLECTION) aSourceCollection
{
	int i;
	int qty = 0;

	if (aSourceCollection == NULL) aSourceCollection = myDepositDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		qty += [[aSourceCollection at: i] getQty];
	}

	return qty;
}

/**/
- (money_t) getAmount: (COLLECTION) aSourceCollection
{
	int i;
	money_t amount = 0;

	if (aSourceCollection == NULL) aSourceCollection = myDepositDetails;

	for (i = 0; i < [aSourceCollection size]; ++i) {
		amount += [[aSourceCollection at: i] getTotalAmount];
	}

	return amount;
}

/**/
- (money_t) getAmountByCurrency: (CURRENCY) aCurrency
{
	int i;
	money_t amount = 0;

	for (i = 0; i < [myDepositDetails size]; ++i) {
		if ([[myDepositDetails at: i] getCurrency] == aCurrency)
			amount += [[myDepositDetails at: i] getTotalAmount];
	}

	return amount;
}

/**/
- (money_t) getAmountByAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings
{
	int i;
	money_t amount = 0;

	for (i = 0; i < [myDepositDetails size]; ++i) {
		if ([[myDepositDetails at: i] getAcceptorSettings] == anAcceptorSettings)
			amount += [[myDepositDetails at: i] getTotalAmount];
	}

	return amount;
}

/**/
- (int) getQtyByAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings
{
	int i;
	int qty = 0;

	for (i = 0; i < [myDepositDetails size]; ++i) {
		if ([[myDepositDetails at: i] getAcceptorSettings] == anAcceptorSettings)
			qty += [[myDepositDetails at: i] getQty];
	}

	return qty;
}

/**/
- (int) getUnknownBillCountByAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings
{
	int i;
	int qty = 0;

	for (i = 0; i < [myDepositDetails size]; ++i) {
		if ([[myDepositDetails at: i] getAcceptorSettings] == anAcceptorSettings &&
				[[myDepositDetails at: i] isUnknownBill])
			qty += [[myDepositDetails at: i] getQty];
	}

	return qty;

}

#ifdef __DEBUG_CIM
/**/
- (void) debug
{
	int i;
	char *depositTypeStr[] = {"NO DEFINIDO", "Automatico", "Manual"};
	char moneyStr[50];

	doLog(0,"**************************\n");
	//doLog(0,"Numero:              %ld\n", myNumber);
	doLog(0,"Tipo deposito:    %s\n", depositTypeStr[myDepositType]);
	//doLog(0,"Numero de sobre:     %s\n", myEnvelopeNumber);
	//doLog(0,"Billetes rechazados: %d\n", myRejectedQty);
	//doLog(0,"Puerta:            : %d\n", myDoor != NULL ? [myDoor getDoorId] : 0);
	//doLog(0,"Usuario:             %s\n", myUser != NULL ? [myUser getLoginName] : "DESCONOCIDO");
	//doLog(0,"Monto:     %s\n", formatMoney(moneyStr, "", [self getAmount], 2, 40));
	doLog(0,"Cant. valores:    %d\n", [self getQty]);
	doLog(0,"Detalle ------------------\n");

	for (i = 0; i < [myDepositDetails size]; ++i)
		[[myDepositDetails at: i] debug];
	
}

#endif

@end

