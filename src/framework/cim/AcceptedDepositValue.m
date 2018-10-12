#include "AcceptedDepositValue.h"
#include "Persistence.h"
#include "AcceptorDAO.h"
#include "CurrencyManager.h"
#include "ResourceStringDefs.h"
#include "UICimUtils.h"
#include "CimManager.h"


@implementation AcceptedDepositValue

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myDepositValueType = DepositValueType_UNDEFINED;
	myAcceptedCurrencies = [Collection new];
	return self;
}

/**/
- (void) setDepositValueType: (DepositValueType) aValue { myDepositValueType = aValue; }
- (DepositValueType) getDepositValueType { return myDepositValueType; }

/**/
- (void) addAcceptedCurrency: (ACCEPTED_CURRENCY) aValue
{
	[myAcceptedCurrencies add: aValue];
}

/**/
- (STR) str
{
	return [UICimUtils getDepositName: myDepositValueType];
}

/**/
- (COLLECTION) getAcceptedCurrencies { return myAcceptedCurrencies; }

/**/
- (ACCEPTED_CURRENCY) getAcceptedCurrencyByCurrencyId: (int) aCurrencyId
{
	int i;

    
	for (i=0; i<[myAcceptedCurrencies size]; ++i)
		if ([[[myAcceptedCurrencies at: i] getCurrency] getCurrencyId] == aCurrencyId) return [myAcceptedCurrencies at: i];

	return NULL;
}

/**/
- (void) addDepositValueTypeCurrency: (int) anAcceptorId currencyId: (int) aCurrencyId
{
	id acceptedCurrency;
	id dao = [[Persistence getInstance] getAcceptorDAO];
	int i;
	int currId;
	BOOL existsCurrency = FALSE;
	id acceptorSettings = NULL;

	printf("AcceptedDepositValue AddDepositValueTypeCurrency %d *******************\n", aCurrencyId);
	
    TRY

		// verifico si ya existe la moneda
		i = 0;
		while ( (i < [myAcceptedCurrencies size]) && (!existsCurrency) ) {
			currId = [[[myAcceptedCurrencies at: i] getCurrency] getCurrencyId];
			existsCurrency = (currId == aCurrencyId);
			i++;
		}

		// doy de alta la nueva moneda solo si no existe
		if (!existsCurrency) {
            //************************* logcoment
			printf("comienzo a dar de alta la currency %d *******************\n", aCurrencyId);
			[dao addDepositValueTypeCurrency: anAcceptorId depositValueType: myDepositValueType currencyId: aCurrencyId];
			
			acceptedCurrency = [AcceptedCurrency new];
			[acceptedCurrency	setCurrency: [[CurrencyManager getInstance] getCurrencyById: aCurrencyId]];
	
			[self addAcceptedCurrency: acceptedCurrency];
           //************************* logcoment
			//doLog(0,"OK...\n");
		} else {
			printf("Exists currency %d, is deleted? *******************\n", aCurrencyId);
        }

		// elimino las currencies que no correspondan (solo para los validadores)
		acceptorSettings = [[[CimManager getInstance] getCim] getAcceptorSettingsById: anAcceptorId];
		if ([acceptorSettings getAcceptorType] == AcceptorType_VALIDATOR) {
			i = 0;
			while (i < [myAcceptedCurrencies size]) {
				currId = [[[myAcceptedCurrencies at: i] getCurrency] getCurrencyId];
				if (currId != aCurrencyId) {
                    //************************* logcoment
					//doLog(0,"elimino currency %d *******************\n", currId);
					// elimino la moneda que no corresponde
					[self removeDepositValueTypeCurrency: anAcceptorId currencyId: currId];
				}else{
					i++;
				}
			}
		}

	CATCH

		RETHROW();

	END_TRY
}

/**/
- (void) removeDepositValueTypeCurrency: (int) anAcceptorId currencyId: (int) aCurrencyId
{
	id dao = [[Persistence getInstance] getAcceptorDAO];		

	TRY
	
		[dao removeDepositValueTypeCurrency: anAcceptorId depositValueType: myDepositValueType currencyId: aCurrencyId];
		
		// agrega el deposito aceptado al acceptor
		[self removeAcceptedDepositValueCurrency: aCurrencyId];

	CATCH

		RETHROW();

	END_TRY
}

- (void) removeAcceptedDepositValueCurrency: (int) aCurrencyId
{
	int i = 0;
	
	for (i=0; i<=[myAcceptedCurrencies size]-1; ++i) 
		if ([[[myAcceptedCurrencies at: i] getCurrency] getCurrencyId] == aCurrencyId) {
			[myAcceptedCurrencies removeAt: i];
			return;
		}
}

#ifdef __DEBUG_CIM
/**/
- (void) debug
{
	static char *depositValueTypeStr[] = {"NO DEFINIDO", "Efectivo", "Efectivo", "Cheques", "Bonos", "Cupones", "Otro", "Bookmark"};
	int i;
	doLog(0,"======================================================================\n");
	doLog(0,"	Tipo de valor: %s\n", depositValueTypeStr[myDepositValueType]);
	doLog(0,"	Divisas aceptadas -------------------------------------------\n");
	for (i = 0; i < [myAcceptedCurrencies size]; ++i)
		[[myAcceptedCurrencies at: i] debug];
}
#endif

@end
