#include "cut.h"
#include <stdio.h>
#include "Extraction.h"
#include "Door.h"
#include "test_common.h"
#include "CimCash.h"

void __CUT_BRINGUP__Extraction( void )
{
	PRINT_TEST_GROUP("\n** Realizando test de extraccion *******************************************\n");
}

void __CUT__Test_Extraction_Test1( void )
{
	DOOR door1 = NULL;
	ACCEPTOR_SETTINGS acceptorSettings1 = NULL;
	ACCEPTOR_SETTINGS acceptorSettings2 = NULL;
	ACCEPTOR_SETTINGS acceptorSettings3 = NULL;
	EXTRACTION extraction;
	CURRENCY currencyARS;
	CIM_CASH cimCash;

	PRINT_TEST("\n    # Probando detalle de extraccion...\n");

	door1 = [Door new];
	[door1 setDoorId: 1];
	[door1 setDoorType: DoorType_COLLECTOR];
	cimCash = [CimCash new];

	acceptorSettings1 = [AcceptorSettings new];
	[acceptorSettings1 setAcceptorId: 1];

	acceptorSettings2 = [AcceptorSettings new];
	[acceptorSettings2 setAcceptorId: 2];

	acceptorSettings3 = [AcceptorSettings new];
	[acceptorSettings3 setAcceptorId: 3];

	[door1 addAcceptorSettings: acceptorSettings1];
	[door1 addAcceptorSettings: acceptorSettings2];
	[door1 addAcceptorSettings: acceptorSettings3];

	currencyARS = [Currency new];
	[currencyARS setCurrencyId: 1];
	[currencyARS setName: "Pesos"];
	[currencyARS setCurrencyCode: "ARS"];

	extraction = [Extraction new];

/*
- (EXTRACTION_DETAIL) addExtractionDetail: (CIM_CASH) aCimCash
		acceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings
		depositValueType: (DepositValueType) aDepositValueType
		currency: (CURRENCY) aCurrency
		qty: (int) aQty
		amount: (money_t) anAmount;
*/
	[extraction addExtractionDetail: cimCash
		acceptorSettings: acceptorSettings1
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyARS
		qty: 1
		amount: 100000000];

	[extraction addExtractionDetail: cimCash
		acceptorSettings: acceptorSettings1
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyARS
		qty: 1
		amount: 100000000];

	[extraction addExtractionDetail: cimCash
		acceptorSettings: acceptorSettings1
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyARS
		qty: 1
		amount: 200000000];

#ifdef __DEBUG_CIM
	[extraction debug];
#endif
}

/**/
void __CUT_TAKEDOWN__Extraction( void )
{
	PRINT_TEST_GROUP("\n** Fin test de extraccion *****************************************************\n");
}

