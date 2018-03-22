#include "cut.h"
#include "DB.h"
#include "ROPPersistence.h"
#include <stdio.h>
#include "Deposit.h"
#include "CimDefs.h"
#include "AcceptorSettings.h"
#include "Currency.h"
#include "Persistence.h"
#include "DepositDAO.h"
#include "test_common.h"

/**/
void __CUT_BRINGUP__DepositDAO( void )
{
	id db;

	PRINT_TEST_GROUP("\n** Realizando test de DepositDAO ******************************************\n");

	db = [DB new];
	[db setDataBasePath: BASE_APP_PATH "/data/"];
	[db startService];
	[ROPPersistence new];

}

/**/
DEPOSIT createTestDeposit(void)
{
	DEPOSIT deposit = NULL;
	CURRENCY currencyDolars = NULL;
	CURRENCY currencyPesos = NULL;
	ACCEPTOR_SETTINGS acceptorSettings = NULL;
	ACCEPTOR_SETTINGS acceptorSettings2 = NULL;
	DOOR door;
	money_t total = 0;
	USER user;

	door = [Door new];
	[door setDoorId: 1];

	user = [User new];
	[user setUserId: 1];

	deposit = [Deposit new];
	[deposit setDoor: door];
	[deposit setUser: user];
	[deposit setOpenTime: [SystemTime getLocalTime]];
	[deposit setCloseTime: [SystemTime getLocalTime]];
	[deposit addRejectedQty: 2];

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

	// Agrego otro deposito de US$ 20 ///////////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyDolars
		qty: 1
		amount: 20];

	total += 20;

	// Agrego otro deposito de US$ 30 ///////////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyDolars
		qty: 1
		amount: 30];


	///////////// /////////////////// ///////////////////// ///////////////// ///////////////

	return deposit;
}

/**/
DEPOSIT createTestDeposit2(void)
{
	DEPOSIT deposit = NULL;
	CURRENCY currencyDolars = NULL;
	CURRENCY currencyPesos = NULL;
	ACCEPTOR_SETTINGS acceptorSettings = NULL;
	ACCEPTOR_SETTINGS acceptorSettings2 = NULL;
	DOOR door;
	money_t total = 0;
	USER user;

	door = [Door new];
	[door setDoorId: 1];

	user = [User new];
	[user setUserId: 1];

	deposit = [Deposit new];
	[deposit setDoor: door];
	[deposit setUser: user];
	[deposit setOpenTime: [SystemTime getLocalTime]];
	[deposit setCloseTime: [SystemTime getLocalTime]];
	[deposit addRejectedQty: 2];

	currencyDolars = [Currency new];
	currencyPesos = [Currency new];
	acceptorSettings = [AcceptorSettings new];
	acceptorSettings2 = [AcceptorSettings new];

	[deposit setDepositType: DepositType_AUTO];

	// Agrego un deposito de US$ 10 ///////////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyPesos
		qty: 1
		amount: 200000000];

	total += 10;

	// Agrego otro deposito de US$ 20 ///////////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyPesos
		qty: 2
		amount: 500000000];

	total += 10;

	// Agrego otro deposito de US$ 30 ///////////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyPesos
		qty: 1
		amount: 1000000000];

// Agrego otro deposito de US$ 30 ///////////////////////////////////////////////////////////
	[deposit addDepositDetail: acceptorSettings
		depositValueType: DepositValueType_VALIDATED_CASH
		currency: currencyPesos
		qty: 2
		amount: 2000000000];

	///////////// /////////////////// ///////////////////// ///////////////// ///////////////

	return deposit;
}


/**/
void __CUT__Test_DepositDAO( void )
{
	DEPOSIT_DAO depositDAO = [DepositDAO new];
	DEPOSIT deposit, deposit2, auxDeposit, auxDeposit2;
	ABSTRACT_RECORDSET depositRS;
	ABSTRACT_RECORDSET depositDetailRS;
	int i, number;
	int recordsByFile = [[[DB getInstance] getTable: "deposits"] getRecordsByFile];
	unsigned long indexCount;
	COLLECTION details;

	depositRS = [depositDAO getNewDepositRecordSet];
	[depositRS open];

	deposit = createTestDeposit();
	deposit2 = createTestDeposit2();

	/**/
	for (i = 0; i < recordsByFile; ++i) {
		doLog(0,"Grabando deposito %d de %d\n", i, recordsByFile);
		[depositDAO store: deposit];
	}

	// Verifico la cantidad de indices
	indexCount = [depositRS getIndexCount];
	ASSERT(indexCount == 1, "");

	// Verifico la cantidad de indices
	[depositDAO store: deposit];
	indexCount = [depositRS getIndexCount];
	ASSERT(indexCount == 2, "");

	// Verifico la cantidad de indices
	[depositDAO store: deposit];
	indexCount = [depositRS getIndexCount];
	ASSERT(indexCount == 2, "");

/*
	depositRS = [depositDAO getNewDepositRecordSet];
	[depositRS open];
	[depositRS moveBeforeFirst];

	number = 1;

	// Verifico cada deposito
	while ([depositRS moveNext]) {

		ASSERT([depositRS getLongValue: "NUMBER"] == number, "Error en el numero de deposito");
		ASSERT([depositRS getCharValue: "DEPOSIT_TYPE"] == [deposit getDepositType], "");
		ASSERT([depositRS getDateTimeValue: "DATE_TIME"] == [deposit getDateTime], "");
		ASSERT([depositRS getLongValue: "USER_ID"] == 1, "");
		ASSERT([depositRS getShortValue: "REJECTED_QTY"] == 2, "");
		ASSERT([depositRS getShortValue: "DOOR_ID"] == 1, "");

		number++;

	}

	depositDetailRS = [depositDAO getNewDepositDetailRecordSet];
	[depositDetailRS open];
	[depositDetailRS moveBeforeFirst];

	i = 0;
	number = 1;
	while ([depositDetailRS moveNext]) {

		ASSERT([depositDetailRS getLongValue: "NUMBER"] == number, "Error en el numero de deposito");
		i++;
		if (i % 3 == 0) number++;
	}


	auxDeposit = [depositDAO loadLast];
	ASSERT([auxDeposit getNumber] == [deposit getNumber], "");
	ASSERT([[auxDeposit getDepositDetails] size] == [[deposit getDepositDetails] size], "");

	///
	for (i = 0; i < 100; ++i) {
		doLog(0,"Grabando deposito %d de %d\n", i, recordsByFile);
		[depositDAO store: deposit2];
		auxDeposit2 = [depositDAO loadLast];
		details = [auxDeposit2 getDepositDetails];
		ASSERT([details size] == 4, "");
		ASSERT([[details at: 0] getQty] == 1, "");
		ASSERT([[details at: 1] getQty] == 2, "");
		ASSERT([[details at: 2] getQty] == 1, "");
		ASSERT([[details at: 3] getQty] == 2, "");

	}
*/
}

/**/
void __CUT_TAKEDOWN__DepositDAO( void )
{
	PRINT_TEST_GROUP("\n** Fin test de DepositDAO ****************************************************\n");
}

