#include "TestCim.h"
#include "CimDefs.h"
#include "Denomination.h"
#include "AcceptedCurrency.h"
#include "AcceptedDepositValue.h"
#include "AcceptorSettings.h"
#include "BillAcceptor.h"
#include "Deposit.h"
#include "CimManager.h"
#include "AcceptorRunThread.h"
#include "system/util/all.h"
#include "CurrencyManager.h"
#include "Persistence.h"

@implementation TestCim

void _billAccepted(void *data, money_t billAmount);
void _billRejected(void *data, int cause);

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	return self;
}

/**/
static DOOR myDoor1 = NULL;
static OTIMER myOpenDoorTimer = NULL;

/**/
- (void) openDoorTimerHandler
{
	[[CimManager getInstance] onDoorOpen: myDoor1];
}

/**/
- (void) createOpenDoorTimer
{
/*
	myOpenDoorTimer = [OTimer new];
	[myOpenDoorTimer initTimer: ONE_SHOT period: 30000 object: self callback: "openDoorTimerHandler"];
	[myOpenDoorTimer start];
*/
}

/**/
- (void) loadCurrenciesFromFile: (char *) aFileName
{
	STRING_TOKENIZER tokenizer;
	char buffer[255];
	CURRENCY currency;
	char token[100];
	FILE *f;
	char *index;

	f = fopen(aFileName, "r");
	if (!f) {
			    //************************* logcoment
//		doLog(0,"No se puede abrir el archivo de %s\n", aFileName);
		return;
	}

	tokenizer = [StringTokenizer new];
	[tokenizer setDelimiter: ","];

			    //************************* logcoment
//	doLog(0,"Grabando monedas ***********************************************\n");

	// en primer lugar, recorro el archivo para saber cuantos campos hay
	while (!feof(f)) {
		
		if (!fgets(buffer, 255, f)) break;

		if (buffer[0] == '\n') continue;
		if (buffer[0] == '#') continue;

		// Saco los enters del final
		index = strchr(buffer, 13);
		if (index) *index = 0;
		index = strchr(buffer, 10);
		if (index) *index = 0;

			    //************************* logcoment
//		doLog(0,"buffer = |%s|\n", buffer);

		[tokenizer restart];
		[tokenizer setText: buffer];

		currency = [Currency new];

		[tokenizer getNextToken: token];
		[currency setCurrencyCode: token];

		[tokenizer getNextToken: token];
		[currency setCurrencyId: atoi(token)];

		[tokenizer getNextToken: token];
		[currency setName: token];

		[[[Persistence getInstance] getCurrencyDAO] store: currency];

			    //************************* logcoment
//		doLog(0,"%s,%03d,%s\n", [currency getCurrencyCode], [currency getCurrencyId], [currency getName]);

	}

	fclose(f);
}


/**/
- (void) test
{
	CURRENCY pesos, dolares;
	DENOMINATION denomination5, denomination10, denomination20, denomination50, denomination100;
	ACCEPTED_CURRENCY acceptedCurrency;
	ACCEPTED_DEPOSIT_VALUE acceptedDepositValue;
	ACCEPTOR_SETTINGS acceptorSettings;
	DEPOSIT deposit;

	COLLECTION currencies;
	CURRENCY currency;
	int i;

	[self loadCurrenciesFromFile: "currencies.csv"];

	/*currencies = [[[Persistence getInstance] getCurrencyDAO] loadAll];
	for (i = 0; i < [currencies size]; ++i) {
		currency = [currencies at: i];
		doLog(0,"%s,%03d,%s\n", [currency getCurrencyCode], [currency getCurrencyId], [currency getName]);
	}*/

			    //************************* logcoment
//	doLog(0,"**************************** CREANDO DATOS DE PRUEBA ************************\n");


	acceptorSettings = [AcceptorSettings new];
	[acceptorSettings setAcceptorId: 1];

//	[myDoor1 addAcceptorSettings: acceptorSettings];

/*	pesos = [Currency new];
	[pesos setCurrencyId: 1];
	[pesos setName: "Pesos"];
	[pesos setCurrencyCode: "ARG"];
*/
/*	dolares = [Currency new];
	[dolares setCurrencyId: 2];
	[dolares setName: "Dollars"];
	[dolares setCurrencyCode: "USD"];
*/
	pesos = [[CurrencyManager getInstance] getCurrencyByCode: "ARS"];
	dolares = [[CurrencyManager getInstance] getCurrencyByCode: "USD"];

	denomination5 = [Denomination new];
	[denomination5 setAmount: 50000000];
	[denomination5 setDenominationState: DenominationState_REJECT];
	[denomination5 setDenominationSecurity: DenominationSecurity_STANDARD];

	denomination10 = [Denomination new];
	[denomination10 setAmount: 100000000];
	[denomination10 setDenominationState: DenominationState_REJECT];
	[denomination10 setDenominationSecurity: DenominationSecurity_STANDARD];

	denomination20 = [Denomination new];
	[denomination20 setAmount: 200000000];
	[denomination20 setDenominationState: DenominationState_ACCEPT];
	[denomination20 setDenominationSecurity: DenominationSecurity_STANDARD];

	denomination50 = [Denomination new];
	[denomination50 setAmount: 500000000];
	[denomination50 setDenominationState: DenominationState_ACCEPT];
	[denomination50 setDenominationSecurity: DenominationSecurity_STANDARD];

	denomination100 = [Denomination new];
	[denomination100 setAmount: 1000000000];
	[denomination100 setDenominationState: DenominationState_ACCEPT];
	[denomination100 setDenominationSecurity: DenominationSecurity_HIGH];

	acceptedCurrency = [AcceptedCurrency new];
	[acceptedCurrency setCurrency: pesos];
	[acceptedCurrency addDenomination: denomination5];
	[acceptedCurrency addDenomination: denomination10];
	[acceptedCurrency addDenomination: denomination20];
	[acceptedCurrency addDenomination: denomination50];
	[acceptedCurrency addDenomination: denomination100];

	acceptedDepositValue = [AcceptedDepositValue new];
	[acceptedDepositValue setDepositValueType: DepositValueType_VALIDATED_CASH];
	[acceptedDepositValue addAcceptedCurrency: acceptedCurrency];

	acceptedCurrency = [AcceptedCurrency new];
	[acceptedCurrency setCurrency: dolares];
	[acceptedCurrency addDenomination: denomination5];
	[acceptedCurrency addDenomination: denomination10];
	[acceptedCurrency addDenomination: denomination20];
	[acceptedCurrency addDenomination: denomination50];
	[acceptedCurrency addDenomination: denomination100];
	[acceptedDepositValue addAcceptedCurrency: acceptedCurrency];

	[acceptorSettings addAcceptedDepositValue: acceptedDepositValue];

	acceptedDepositValue = [AcceptedDepositValue new];
	[acceptedDepositValue setDepositValueType: DepositValueType_BOND];

	acceptedCurrency = [AcceptedCurrency new];
	[acceptedCurrency setCurrency: pesos];
	[acceptedDepositValue addAcceptedCurrency: acceptedCurrency];

	acceptedCurrency = [AcceptedCurrency new];
	[acceptedCurrency setCurrency: dolares];
	[acceptedDepositValue addAcceptedCurrency: acceptedCurrency];

	[acceptorSettings addAcceptedDepositValue: acceptedDepositValue];

#ifdef __DEBUG_CIM
	[acceptorSettings debug];
#endif

	[self createOpenDoorTimer];

}

/*	deposit = [Deposit new];
	[deposit setNumber: 1];
	[deposit setDepositType: DepositType_MANUAL];

	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_CASH
		currency: pesos
		qty: 2
		amount: 50000000];

	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_CASH
		currency: pesos
		qty: 2
		amount: 50000000];

	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_CASH
		currency: pesos
		qty: 8
		amount: 100000000];

	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_CASH
		currency: dolares
		qty: 2
		amount: 100000000];

	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_CHECK
		currency: dolares
		qty: 1
		amount: 23100000000];

	[deposit debug];


	deposit = [[CimManager getInstance] startDeposit: DepositType_AUTO];

	_billAccepted(acceptor, 50000000);
	_billRejected(acceptor, 10);
	_billRejected(acceptor, 10);
	_billAccepted(acceptor, 50000000);
	_billAccepted(acceptor, 50000000);
	_billAccepted(acceptor, 50000000);
	_billAccepted(acceptor, 100000000);
	_billAccepted(acceptor, 100000000);

	[deposit debug];

	[[CimManager getInstance] endDeposit];

	_billAccepted(acceptor, 50000000);
*/

@end
