#include "cut.h"
#include <stdio.h>
#include "Deposit.h"
#include "CimDefs.h"
#include "AcceptorSettings.h"
#include "Currency.h"
#include "test_common.h"

void __CUT_BRINGUP__Deposit( void )
{
	PRINT_TEST_GROUP("\n** Realizando test de deposito *******************************************\n");
}

void __CUT__Test_Deposit_Auto( void )
{
	DEPOSIT deposit = NULL;
	CURRENCY currencyDolars = NULL;
	CURRENCY currencyPesos = NULL;
	ACCEPTOR_SETTINGS acceptorSettings = NULL;
	ACCEPTOR_SETTINGS acceptorSettings2 = NULL;
	money_t total = 0, totalDolars = 0, totalPesos = 0;
	COLLECTION acceptorSettingsList = NULL;
	COLLECTION depositDetails = NULL;
	COLLECTION currencies;
	
	PRINT_TEST("\n    # Probando deposito automatico...\n");

  deposit = [Deposit new];
	currencyDolars = [Currency new];
	currencyPesos = [Currency new];
	acceptorSettings = [AcceptorSettings new];
	acceptorSettings2 = [AcceptorSettings new];

	[deposit setDepositType: DepositType_AUTO];

	// Agrego un deposito de US$ 10 ///////////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyDolars
		qty: 1
		amount: 10];

	total += 10;

	ASSERT([deposit getAmount] == total, "Monto incorrecto");
	ASSERT([[deposit getDepositDetails] size] == 1, "Cantidad de elementos incorrecta.");

	// Agrego otro deposito de US$ 10 ///////////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyDolars
		qty: 1
		amount: 10];

	total += 10;

	ASSERT([deposit getAmount] == total, "Monto incorrecto");
	ASSERT([[deposit getDepositDetails] size] == 1, "Cantidad de elementos incorrecta.");

	// Agrego otro deposito de US$ 20 ///////////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyDolars
		qty: 1
		amount: 20];

	total += 20;

	ASSERT([deposit getAmount] == total, "Monto incorrecto");
	ASSERT([[deposit getDepositDetails] size] == 2, "Cantidad de elementos incorrecta.");

	// Agrego otro deposito de US$ 20, cantidad 5 ///////////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyDolars
		qty: 5
		amount: 20];

	total += (20*5);
	ASSERT([deposit getAmount] == total, "Monto incorrecto");
	ASSERT([[deposit getDepositDetails] size] == 2, "Cantidad de elementos incorrecta.");

	// Agrego otro deposito de US$ 5 ///////////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyDolars
		qty: 1
		amount: 5];

	total += 5;
	ASSERT([deposit getAmount] == total, "Monto incorrecto");
	ASSERT([[deposit getDepositDetails] size] == 3, "Cantidad de elementos incorrecta.");

	// Verifico que esten ordenados de forma correcta ////////////////////////////////
	ASSERT([[[deposit getDepositDetails] at: 0] getAmount] == 5, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 1] getAmount] == 10, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 2] getAmount] == 20, "Orden incorrecto");

	// Agrego otro deposito de US$ 100 ///////////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyDolars
		qty: 1
		amount: 100];

	total += 100;
	
	// Agrego otro deposito de US$ 50 ///////////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyDolars
		qty: 5
		amount: 50];

	total += (5*50);
	
	// Agrego otro deposito de US$ 200 ///////////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyDolars
		qty: 1
		amount: 200];

	total += 200;
	totalDolars = total;

	// Verifico que esten ordenados de forma correcta
	ASSERT([[[deposit getDepositDetails] at: 0] getAmount] == 5, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 1] getAmount] == 10, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 2] getAmount] == 20, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 3] getAmount] == 50, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 4] getAmount] == 100, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 5] getAmount] == 200, "Orden incorrecto");

	ASSERT([deposit getAmount] == total, "Monto incorrecto");

////////////////////////////// DEPOSITOS EN PESOS //////////////////////////////////////////

	// Agrego otro deposito de $ 200 ///////////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyPesos
		qty: 1
		amount: 10];

	total += 10;
	totalPesos += 10;

	// Verifico que esten ordenados de forma correcta
	ASSERT([[[deposit getDepositDetails] at: 0] getAmount] == 5, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 1] getAmount] == 10, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 2] getAmount] == 20, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 3] getAmount] == 50, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 4] getAmount] == 100, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 5] getAmount] == 200, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 6] getAmount] == 10, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 6] getCurrency] == currencyPesos, "Currency incorrecta");
	ASSERT([deposit getAmount] == total, "Monto incorrecto");

////////////////////////////// DEPOSITOS EN EL VALIDADOR 2 ///////////////////////////////////////

	// Agrego otro deposito de $ 200 ///////////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings2
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyPesos
		qty: 1
		amount: 20];

	total += 20;
	totalPesos += 20;

	// Agrego otro deposito de $ 200 ///////////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings2
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyPesos
		qty: 1
		amount: 10];

	total += 10;
	totalPesos += 10;

	// Verifico que esten ordenados de forma correcta
	ASSERT([[[deposit getDepositDetails] at: 0] getAmount] == 5, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 1] getAmount] == 10, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 2] getAmount] == 20, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 3] getAmount] == 50, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 4] getAmount] == 100, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 5] getAmount] == 200, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 6] getAmount] == 10, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 6] getCurrency] == currencyPesos, "Currency incorrecta");

	ASSERT([[[deposit getDepositDetails] at: 7] getCurrency] == currencyPesos, "Currency incorrecta");
	ASSERT([deposit getAmount] == total, "Monto incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 7] getAcceptorSettings] == acceptorSettings2, "");
	ASSERT([[[deposit getDepositDetails] at: 7] getAmount] == 10, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 8] getAcceptorSettings] == acceptorSettings2, "");
	ASSERT([[[deposit getDepositDetails] at: 8] getAmount] == 20, "Orden incorrecto");

	// Verifico que la funcion getAcceptorSettingsList devuelve el resultado correcto
	doLog(0,"\n         > Probando getAcceptorSettingsList() \n");
	acceptorSettingsList = [deposit getAcceptorSettingsList: NULL];
	ASSERT([acceptorSettingsList size] == 2, "getAcceptorSettingsList() error");
	ASSERT([acceptorSettingsList at: 0] == acceptorSettings, "getAcceptorSettingsList() error");
	ASSERT([acceptorSettingsList at: 1] == acceptorSettings2, "getAcceptorSettingsList() error");

	// Verifico que la funcion getDetailsByAcceptor() devuelve el resultado correcto
	doLog(0,"\n         > Probando getDepositDetailsByAcceptor() \n");
	depositDetails = [deposit getDetailsByAcceptor: NULL acceptorSettings: acceptorSettings];
	ASSERT([depositDetails size] == 7, "Error en getDetailsByAcceptor()");

	depositDetails = [deposit getDetailsByAcceptor: NULL acceptorSettings: acceptorSettings2];
	ASSERT([depositDetails size] == 2, "Error en getDetailsByAcceptor()");

	// Devuelve las monedas utilizadas en el deposito
	doLog(0,"\n         > Probando getDepositCurrencies() \n");
	currencies = [deposit getCurrencies: NULL];
	ASSERT([currencies size] == 2, "Error en getDepositCurrencies()");
	ASSERT([currencies at: 0] == currencyDolars, "Error en getDepositCurrencies()");
	ASSERT([currencies at: 1] == currencyPesos, "Error en getDepositCurrencies()");
	
	// Devuelve el total por cada monedas
	doLog(0,"\n         > Probando getAmountByCurrency() \n");
	ASSERT([deposit getAmountByCurrency: currencyDolars] == totalDolars, "Error en getAmountByCurrency");
	ASSERT([deposit getAmountByCurrency: currencyPesos] == totalPesos, "Error en getAmountByCurrency");
	
}

/**/
void __CUT__Test_Deposit_Manual(void )
{
	DEPOSIT deposit = NULL;
	CURRENCY currencyDolars = NULL;
	CURRENCY currencyPesos = NULL;
	ACCEPTOR_SETTINGS acceptorSettings = NULL;
	ACCEPTOR_SETTINGS acceptorSettings2 = NULL;
	money_t total = 0;

	PRINT_TEST("\n    # Probando deposito manual...\n");

  deposit = [Deposit new];
	currencyDolars = [Currency new];
	currencyPesos = [Currency new];
	acceptorSettings = [AcceptorSettings new];
	acceptorSettings2 = [AcceptorSettings new];

	[deposit setDepositType: DepositType_MANUAL];

	// DEPOSITO DE $200 /////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyPesos
		qty: 1
		amount: 200];

	total += 200;

	// DEPOSITO DE $200 /////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyPesos
		qty: 1
		amount: 200];

	total += 200;

	ASSERT([[[deposit getDepositDetails] at: 0] getAmount] == 200, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 1] getAmount] == 200, "Orden incorrecto");

	// DEPOSITO DE US$ 200 /////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyDolars
		qty: 1
		amount: 200];

	total += 200;

	// DEPOSITO DE US$ 300 (CHEQUE) ////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_CHECK
		currency: currencyDolars
		qty: 1
		amount: 300];

	total += 300;

	ASSERT([[[deposit getDepositDetails] at: 2] getAmount] == 200, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 2] getDepositValueType] == DepositValueType_VALIDATED_CASH, "");
	ASSERT([[[deposit getDepositDetails] at: 3] getAmount] == 300, "Orden incorrecto");
	ASSERT([[[deposit getDepositDetails] at: 3] getDepositValueType] == DepositValueType_CHECK, "");
	ASSERT([deposit getAmount] == total, "Total incorrecto");

}

/**/
void __CUT__Test_Deposit_Max_Qty(void )
{
	DEPOSIT deposit = NULL;
	CURRENCY currencyPesos = NULL;
	ACCEPTOR_SETTINGS acceptorSettings = NULL;
	money_t total = 0;
	int i;
	BOOL error = FALSE;

	PRINT_TEST("\n    # Probando maxima cantidad en un deposito...\n");

  deposit = [Deposit new];
	currencyPesos = [Currency new];
	acceptorSettings = [AcceptorSettings new];

	[deposit setDepositType: DepositType_MANUAL];

	for (i = 0; i < MAX_DEPOSIT_DETAIL_QTY; i++) {

		[deposit addDepositDetail: acceptorSettings
			depositValueType: DepositValueType_VALIDATED_CASH
			currency: currencyPesos
			qty: 1
			amount: 200];

	}

	TRY

		[deposit addDepositDetail: acceptorSettings
			depositValueType: DepositValueType_VALIDATED_CASH
			currency: currencyPesos
			qty: 1
			amount: 200];

	CATCH

		error = TRUE;

	END_TRY

	ASSERT(error == TRUE, "No lanza excepcion de maxima cantidad en un deposito\n");
	ASSERT([deposit getQty] == MAX_DEPOSIT_DETAIL_QTY, "No lanza excepcion de maxima cantidad en un deposito\n");
}

/**/
void __CUT_TAKEDOWN__Deposit( void )
{
	PRINT_TEST_GROUP("\n** Fin test de deposito *****************************************************\n");
}

