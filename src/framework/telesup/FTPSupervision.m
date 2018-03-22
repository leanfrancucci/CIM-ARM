#include <unistd.h>
#include <scew.h>
#include "UserManager.h"
#include "Persistence.h"
#include "DepositDAO.h"
#include "FTPSupervision.h"
#include "JExceptionForm.h"
#include "CashReference.h"
#include "DepositDetail.h"
#include "AmountSettings.h"
#include "RegionalSettings.h"
#include "ResourceStringDefs.h"
#include "MessageHandler.h"
#include "Deposit.h"
#include "math.h"
#include "TelesupervisionManager.h"
#include "TelesupDefs.h"
#include "TelesupFacade.h"

#define LOG(args...) printf(args)
//#define LOG(args...)

#define DEFAULT_XML_PATH "/var"
#define DEFAULT_WPUT_CMD "/rw/bin/wput"

@implementation FTPSupervision

/**/
- (int) removeFile: (char *) aFileName;

static FTP_SUPERVISION singleInstance = NULL; 

static void convertTime(datetime_t *dt, struct tm *bt)
{
#ifdef __UCLINUX
	localtime_r(dt, bt);
#else
	gmtime_r(dt, bt);
#endif
}

static char *formatBrokenDateTime(char *dest, struct tm *brokenTime)
{
	strftime(dest, 50, [[RegionalSettings getInstance] getDateTimeFormatString], brokenTime);
	return dest;
}

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}
 
/**/
- initialize
{
	char cmd[255];
	
	myTelesupViewer = NULL;
	myPath = [[Configuration getDefaultInstance] getParamAsString: "TELESUP_XML_FILES_PATH" default: DEFAULT_XML_PATH];
	myWPutCmd = [[Configuration getDefaultInstance] getParamAsString: "WPUT_CMD" default: DEFAULT_WPUT_CMD];

	sprintf(cmd, "mkdir -p %s", myPath);
	system(cmd);
	
	return self;
}

/**/
+ getInstance
{
  return [self new];
}

/**/
- (void) setTelesupViewer: (id) aTelesupViewer
{
	myTelesupViewer = aTelesupViewer;
}

/**/
- (char*) generateDepositXML: (id) aDeposit fileName: (char*) aFileName
{
	int i;
	scew_tree* tree;
  scew_element* root = NULL;
	char file[50];
	char fName[50];
  datetime_t date;
  char dateStr[50];
  struct tm brokenTime;
  char mSymbol[4];
	int totalDecimals = [[AmountSettings getInstance] getTotalRoundDecimalQty];
	COLLECTION referenceList;
	CASH_REFERENCE reference;
	scew_element *element;
	scew_element *generalInfo;
	scew_element *elementDepositDetails;
	scew_element *elementDepositDetail;
	scew_element *elementAcceptors;
	scew_element *elementAcceptor;
	scew_element *elementCurrencyList;
	scew_element *elementCurrency;
	scew_element *elementTotalCurr;
	scew_element *elementTotalByCurrency;
	ACCEPTOR_SETTINGS acceptorSettings;
	COLLECTION acceptors;
	COLLECTION currencies;
	COLLECTION detailsByAcceptor;
	COLLECTION detailsByCurrency;
	CURRENCY currency;
	DEPOSIT_DETAIL depositDetail;
	int iAcceptor, iCurrency, iDetail;
	char buf[50];
	char text[255];

	LOG("FTPSupervision-generateDepositXML\n");

	sprintf(text, getResourceStringDef(RESID_UNDEFINED, "Generando xml dep %d"), [aDeposit getNumber]);
	[myTelesupViewer updateText: text];

	tree = scew_tree_create();
  root = scew_tree_add_root(tree, "deposit");

  strcpy(mSymbol, [[RegionalSettings getInstance] getMoneySymbol]);
	
	generalInfo = scew_element_add(root, "generalInfo");

  // Usuario
  element = scew_element_add(generalInfo, "userName");
	strcpy(buf, [aDeposit getUser] != NULL ? [[aDeposit getUser] str] : getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
	buf[17] = '\0';
  scew_element_set_contents(element, buf);

  // Id de usuario
  element = scew_element_add(generalInfo, "userId");
//  sprintf(buf, "%05d", [[aDeposit getUser] getUserId]);
	strcpy(buf, [aDeposit getUser] != NULL ? [[aDeposit getUser] getLoginName] : getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
  scew_element_set_contents(element, buf);

  // Fecha / hora del cierre
  date = [aDeposit getCloseTime];
	convertTime(&date, &brokenTime);
  formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "closeTime");
  scew_element_set_contents(element, dateStr);

  // Fecha / hora de la apertura
  date = [aDeposit getOpenTime];
	convertTime(&date, &brokenTime);
  formatBrokenDateTime(dateStr, &brokenTime);
  element = scew_element_add(generalInfo, "openTime");
  scew_element_set_contents(element, dateStr);

  // Total
/*
  element = scew_element_add(generalInfo, "total");
  formatMoney(buf, mSymbol, [aDeposit getAmount], totalDecimals, 20);
  scew_element_set_contents(element, buf);
*/

  // Cantidad de billetes rechazados
  element = scew_element_add(generalInfo, "rejectedQty");
  sprintf(buf, "%d", [aDeposit getRejectedQty]);
  scew_element_set_contents(element, buf);

	// Tipo de deposito
  element = scew_element_add(generalInfo, "depositType");
  sprintf(buf, "%d", [aDeposit getDepositType]);
  scew_element_set_contents(element, buf);

  // Numero de deposito
  element = scew_element_add(generalInfo, "number");
  sprintf(buf, "%08ld", [aDeposit getNumber]);
  scew_element_set_contents(element, buf);

  // Numero de sobre
  element = scew_element_add(generalInfo, "envelopeNumber");
  scew_element_set_contents(element, [aDeposit getEnvelopeNumber]);

  // Aplicado a
  element = scew_element_add(generalInfo, "applyTo");
  scew_element_set_contents(element, [aDeposit getApplyTo]);

  // Nombre de puerta
  element = scew_element_add(generalInfo, "doorName");
  scew_element_set_contents(element, [[aDeposit getDoor] getDoorName]);

  // Nombre del cash
  element = scew_element_add(generalInfo, "cimCashName");
  scew_element_set_contents(element, [[aDeposit getCimCash] getName]);

	// Cuenta bancaria
	element = scew_element_add(generalInfo, "bankAccountNumber");
	scew_element_set_contents(element, [aDeposit getBankAccountNumber]);

	// References (los ordeno de padre a hijo)
	referenceList = [Collection new];
	reference = [aDeposit getCashReference];
	while (reference != NULL) {
		[referenceList at: 0 insert: reference];
		reference = [reference getParent];
	}

	element = scew_element_add(generalInfo, "hasReference");
	scew_element_set_contents(element, [referenceList size] == 0 ? "FALSE" : "TRUE");

	for (i = 0; i < [referenceList size]; ++i) {
		element = scew_element_add(generalInfo, "cashReference");
		element = scew_element_add(element, "referenceName");

		memset(buf, '-', i);
		buf[i] = '\0';
		strcat(buf, [[referenceList at: i] getName]);
		buf[26] = '\0';

		scew_element_set_contents(element, buf);
	}

	[referenceList free];

	/*
		
	<acceptorList>

		<acceptor>	
			
			<currencyList>
				<currency>
						<currencyCode>ARS</currencyCode>
						<qty>10</qty>
						<total>50.00</total>
							<depositDetails>
								<depositDetail>...</depositDetail>
								<depositDetail>...</depositDetail>
								<depositDetail>...</depositDetail>
							</depositDetails>
					</currency>
			</currencyList>

			<currencyList>
				<currency>
						<currencyCode>ARS</currencyCode>
						<qty>10</qty>
						<total>50.00</total>
							<depositDetails>
								<depositDetail>...</depositDetail>
								<depositDetail>...</depositDetail>
								<depositDetail>...</depositDetail>
							</depositDetails>
					</currency>
			</currencyList>

		</acceptor>

	</acceptorList>

*/

	acceptors = [aDeposit getAcceptorSettingsList: NULL];
	elementAcceptors = scew_element_add(root, "acceptorList");

	// Recorro la lista de aceptadores
	for (iAcceptor = 0; iAcceptor < [acceptors size]; ++iAcceptor) {

		acceptorSettings = [acceptors at: iAcceptor];
		elementAcceptor = scew_element_add(elementAcceptors, "acceptor");

		// Nombre del aceptador
		element = scew_element_add(elementAcceptor, "acceptorName");
		scew_element_set_contents(element, [acceptorSettings getAcceptorName]);

		// Obtengo la lista de detalles para el aceptador
		detailsByAcceptor = [aDeposit getDetailsByAcceptor: NULL acceptorSettings: acceptorSettings];

		// Obtengo la lista de monedas utilizadas en este aceptador
		currencies = [aDeposit getCurrencies: detailsByAcceptor];
		
		elementCurrencyList = scew_element_add(elementAcceptor, "currencyList");

		// Recorro las monedas
		for (iCurrency = 0; iCurrency < [currencies size]; ++iCurrency) {

			currency = [currencies at: iCurrency];

			// Creo el elemento moneda con los datos de la moneda y la info totalizada

			elementCurrency = scew_element_add(elementCurrencyList, "currency");
			detailsByCurrency = [aDeposit getDetailsByCurrency: detailsByAcceptor currency: currency];

			element = scew_element_add(elementCurrency, "currencyCode");
			scew_element_set_contents(element, [currency getCurrencyCode]);

			element = scew_element_add(elementCurrency, "qty");
			sprintf(buf, "%04d", [aDeposit getQty: detailsByCurrency]);
			scew_element_set_contents(element, buf);
	
			element = scew_element_add(elementCurrency, "total");
			formatMoney(buf, "", [aDeposit getAmount: detailsByCurrency], totalDecimals, 20);
			scew_element_set_contents(element, buf);
	
			elementDepositDetails = scew_element_add(elementCurrency, "depositDetails");

			// Recorro el detalle de los depositos		
			for (iDetail = 0; iDetail < [detailsByCurrency size]; ++iDetail) {
		
				depositDetail = [detailsByCurrency at: iDetail];
				elementDepositDetail = scew_element_add(elementDepositDetails, "depositDetail");
		
				// Cantidad
				element = scew_element_add(elementDepositDetail, "qty");
				sprintf(buf, "%04d" , [depositDetail getQty]);
				scew_element_set_contents(element, buf);
		
				// Importe
				element = scew_element_add(elementDepositDetail, "amount");
				if ([depositDetail isUnknownBill]) stringcpy(buf, getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
				else formatMoney(buf, "", [depositDetail getAmount], totalDecimals, 20);
				scew_element_set_contents(element, buf);
		
				// Total
				element = scew_element_add(elementDepositDetail, "totalAmount");
				if ([depositDetail isUnknownBill]) stringcpy(buf, getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
				else formatMoney(buf, "", [depositDetail getTotalAmount], totalDecimals, 20);
				scew_element_set_contents(element, buf);

				// Nombre del tipo de valor
				element = scew_element_add(elementDepositDetail, "depositValueName");
				scew_element_set_contents(element, [depositDetail getDepositValueName]);
		
			}
			
			[detailsByCurrency free];

		}

		[detailsByAcceptor free];
		[currencies free];

	}

	[acceptors free];


  // Obtengo la lista de monedas para mostrar los totales
	currencies = [aDeposit getCurrencies: NULL];
  elementTotalCurr = scew_element_add(root, "totalCurr");
  for (iCurrency = 0; iCurrency < [currencies size]; ++iCurrency) {
      
      currency = [currencies at: iCurrency];
      
      elementTotalByCurrency = scew_element_add(elementTotalCurr, "totalByCurrency");
			detailsByCurrency = [aDeposit getDetailsByCurrency: NULL currency: currency];

			element = scew_element_add(elementTotalByCurrency, "totalCurrencyCode");
			scew_element_set_contents(element, [currency getCurrencyCode]);
  		
			element = scew_element_add(elementTotalByCurrency, "totalCurrency");
			formatMoney(buf, "", llabs([aDeposit getAmount: detailsByCurrency]), totalDecimals, 20);
			scew_element_set_contents(element, buf);
  }

	[detailsByCurrency free];
	[currencies free];

	// Grabo el XML en disco

/*	Nombre del archivo: Deposit_aaaaaaaaXXhhmm.xml
	Donde:
	
	aaaaaaaa: es el número de deposito
	hhmm: es la hora y minuto
*/

	[SystemTime decodeTime: [SystemTime getLocalTime] brokenTime: &brokenTime];

	sprintf(fName,"deposit_%08d_%4d%0.2d%0.2d%0.2d%0.2d%0.2d.xml", [aDeposit getNumber], brokenTime.tm_year + 1900, brokenTime.tm_mon + 1, brokenTime.tm_mday, brokenTime.tm_hour, brokenTime.tm_min, brokenTime.tm_sec);

	sprintf(aFileName,"deposit_%08d_%4d%0.2d%0.2d%0.2d%0.2d%0.2d.xml", [aDeposit getNumber], brokenTime.tm_year + 1900, brokenTime.tm_mon + 1, brokenTime.tm_mday, brokenTime.tm_hour, brokenTime.tm_min, brokenTime.tm_sec);

	sprintf(file, "%s/%s", BASE_VAR_PATH, fName);
	scew_writer_tree_file(tree, file);
	scew_tree_free(tree);

//	doLog(0,"----------aFileName = %s\n", aFileName);

	return aFileName;
	
}

/**/
- (BOOL) sendFile: (char *) aFileName
{
	char text[255];
	char cmd[512];
	char user[100];
	char password[100];
	char host[100];

	int result;
	int port;
	id telesup;
	id connection;

	char file[255];
	
  telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: FTP_SERVER_TSUP_ID];

	assert(telesup);

	connection = [telesup getConnection1];

	stringcpy(user, [telesup getTelesupUserName]);
	stringcpy(password, [telesup getTelesupPassword]);

	if ([connection getConnectBy] == ConnectionByType_IP)
		stringcpy(host, [connection getIP]);
	
	if ([connection getConnectBy] == ConnectionByType_DOMAIN)
		stringcpy(host, [connection getDomainSup]);

	port = [[telesup getConnection1] getConnectionTCPPortDestination];

/*
	stringcpy(user, "pruebaalexia");
	stringcpy(password, "pruebaalexia");
	stringcpy(host, "fs");
	port = 21;
*/
//	doLog(0,"user = %s\n", user);
//	doLog(0,"host = %s\n", host);
//	doLog(0,"port = %d\n", port);

	// TODO: descablear el host, user y password
	LOG("XMLTicketManager -> Enviando el archivo %s ...\n", aFileName);
	sprintf(text, getResourceStringDef(RESID_UNDEFINED, "Enviando archivo %s"), aFileName);
	[myTelesupViewer updateText: text];


	// Solo uso el usuario y password si el usuario tiene algun valor
	if (*user != '\0')
		sprintf(cmd, "%s --tries=1 -q --waitretry=1 -R %s/%s ftp://%s:%s@%s:%d/%s", myWPutCmd, myPath, aFileName, user, password, host, port, aFileName);
	else
		sprintf(cmd, "%s --tries=1 -q --waitretry=1 -R %s/%s ftp://%s:%d/%s", myWPutCmd, myPath, aFileName, host, port, aFileName);
	
	LOG("XMLTicketManager -> Ejecutando %s\n", cmd);

	result = system(cmd);
	
	LOG("**************************************************\n");
	LOG("Result = %d\n", result);
	LOG("**************************************************\n");

	if (result == 0) {
		[self removeFile: aFileName];
		return TRUE;
	}	

	// Si es 1 el resultado quiere decir que no lo pudo transmitir porque el archivo ya exitia, en ese caso borro este XML
	// y listo

	if (result == 1) {
		[self removeFile: aFileName];
		return TRUE;
	}
	
	// Si el archivo sigue existiendo quiere decir que no lo puedo enviar correctamente (en caso contrario no deberia estar)
	sprintf(file, "%s/%s", myPath, aFileName);
	if ([File existsFile: file]) {
		[self removeFile: aFileName];		
		return FALSE;
	}
	
	return TRUE;
}

/**/
- (int) removeFile: (char *) aFileName
{
	char file[255];
	
	LOG("FTPSupervision -> Elimina el archivo %s ...\n", aFileName);
	
	sprintf(file, "%s/%s", myPath, aFileName);
	
	unlink(file);
	
	return 1;
}

/**/
- (void) sendDepositFiles
{
	ABSTRACT_RECORDSET depositsRS = NULL;
	ABSTRACT_RECORDSET depositDetailsRS = NULL;
	unsigned long myLastDepositNumberTransfered = 0;
	unsigned long from = 0;
	unsigned long telesupId = 0;
	id deposit = NULL;
	char xmlFileName[50];
	BOOL result;
	BOOL error = FALSE;

  id telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: FTP_SERVER_TSUP_ID];

	if (!telesup) return; 	

	telesupId = [telesup getTelesupId];

	myLastDepositNumberTransfered = [[TelesupFacade getInstance] getTelesupParamAsLong: "LastTelesupDepositNumber" telesupRol: telesupId];

	depositsRS = [[[Persistence getInstance] getDepositDAO] getNewDepositRecordSet];
	from = myLastDepositNumberTransfered + 1;

	// Verifica que el recordSet no este vacio.
	if (!depositsRS) return;

	[depositsRS open];

//	doLog(0,"Buscando deposito %ld\n", from);

	[depositsRS findById: "NUMBER" value: from];
	//doLog(0,"depositDetailsRS getLongValue = %ld\n", [depositsRS getLongValue: "NUMBER"]);

	if (([depositsRS eof]) || ([depositsRS getLongValue: "NUMBER"] < from)) {
		[depositsRS close];
		[depositsRS free];
		return;
	}

	// Detalle del deposito
	depositDetailsRS = [[[Persistence getInstance] getDepositDAO] getNewDepositDetailRecordSet];
	[depositDetailsRS open];
	[depositDetailsRS moveFirst];

	TRY

		while (![depositsRS eof]) {

			myLastDepositNumberTransfered = [depositsRS getLongValue: "NUMBER"];

			// Me paro en el registro de detalle (si es que no estoy ahi ya)
			if ([depositDetailsRS eof] || [depositDetailsRS getLongValue: "NUMBER"] != myLastDepositNumberTransfered)
				[depositDetailsRS findFirstById: "NUMBER" value: myLastDepositNumberTransfered];

			// arma el archivo para enviarlo
			deposit = [[[Persistence getInstance] getDepositDAO] getDepositFromRecordSetForTelesup: depositsRS depositDetailRS: depositDetailsRS];

			xmlFileName[0] = '\0';

			[self generateDepositXML: deposit fileName: xmlFileName];

		///	doLog(0,"xmlFileGenerated - %s\n", xmlFileName);

			// libera el deposito
			[deposit free];

			// envia el archivo
			result = [self sendFile: xmlFileName];
			
			// si todo ok actualiza el ultimo numero de deposito enviado
			if (result) {
				[telesup setLastTelesupDepositNumber: [depositsRS getLongValue: "NUMBER"]];
				[telesup applyChanges];
			} else {
				error = TRUE;
				EXIT_TRY;
				break;
			}

			// sigue avanzando
			if (![depositsRS moveNext]) break;
		}
	
	FINALLY

    [depositsRS close];
    [depositsRS free];
	
		[depositDetailsRS close];
		[depositDetailsRS free];
	
	END_TRY;		

	if (error) 
		THROW(GENERAL_IO_EX);

}

/**/
- (void) startFTPSupervision
{

	TRY
		// envia los depositos
		[self sendDepositFiles];
	
	CATCH

		RETHROW();

	END_TRY

}

/**/
- (BOOL) ftpServerAllowed
{
	FILE *f;

	f = fopen(BASE_APP_PATH "/ftpServer", "r");
	if (f) 
		return TRUE;

	return FALSE;
}

@end
