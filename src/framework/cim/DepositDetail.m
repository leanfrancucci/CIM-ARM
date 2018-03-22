#include "DepositDetail.h"
#include "system/util/all.h"
#include "ResourceStringDefs.h"
#include "MessageHandler.h"
#include "UICimUtils.h"

@implementation DepositDetail

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myDepositValueType = DepositValueType_UNDEFINED;
	myAmount = 0;
	myCurrency = NULL;
	myQty = 0;
	myAdditionalId = 0;
	myAcceptorSettings = NULL;
	return self;
}

/**/
- (void) setDepositValueType: (DepositValueType) aDepositValueType { myDepositValueType = aDepositValueType; }
- (DepositValueType) getDepositValueType { return myDepositValueType; }
	
/**/
- (void) setAmount: (money_t) aAmount { myAmount = aAmount; }
- (money_t) getAmount { return myAmount; }

/**/
- (void) setQty: (int) aQty { myQty = aQty; }
- (void) addQty: (int) aQty { myQty += aQty; }
- (int) getQty { return myQty; }

/**/
- (BOOL) isUnknownBill
{
	return myDepositValueType == DepositValueType_VALIDATED_CASH && myAmount == 0;
}

/**/
- (void) setCurrency: (CURRENCY) aCurrency { myCurrency = aCurrency; }
- (CURRENCY) getCurrency { return myCurrency; }

/**/
- (void) setAcceptorSettings: (ACCEPTOR_SETTINGS) aAcceptorSettings { myAcceptorSettings = aAcceptorSettings; }
- (ACCEPTOR_SETTINGS) getAcceptorSettings { return myAcceptorSettings; }

/**/
- (void) setAdditionalId: (unsigned long) aAdditionalId { myAdditionalId = aAdditionalId; }
- (unsigned long) getAdditionalId { return myAdditionalId; }

/**/
- (money_t) getTotalAmount
{
	// Si es cash validado, entonces el total esta dado por el monto x la cantidad
	if (myDepositValueType == DepositValueType_VALIDATED_CASH)
		return myAmount * myQty;

	// En todos los demas tipos de valores, el total = al monto
	return myAmount;
}

/**/
- (char *) getDepositValueName
{
	return [UICimUtils getDepositName: myDepositValueType];
}

/**/
- (STR) str
{
	char moneyStr[20];
	char depositValueName[20];

	strcpy(depositValueName, [self getDepositValueName]);
	depositValueName[8] = '\0';
	formatMoney(moneyStr, "", [self getTotalAmount], 2, 20);
	sprintf(myBuf, "%-8s %10s", depositValueName, moneyStr);

	return myBuf;
}

#ifdef __DEBUG_CIM
/**/
- (void) debug
{
	static char *depositValueTypeStr[] = {"NO DEFINIDO", "Efectivo", "Efectivo", "Cheques", "Bonos", "Cupones", "Otro", "Bookmark"};
	char moneyStr[50];
	char moneyStr2[50];

	doLog(0,"	Tipo valor: %s, Monto: %s, Cant. = %d, Divisa = %s, Total = %s\n",
		depositValueTypeStr[myDepositValueType],
		formatMoney(moneyStr, "", myAmount, 2, 40),
		myQty,
		[myCurrency getName],
		formatMoney(moneyStr2, "", [self getTotalAmount], 2, 40));

}
#endif


@end

