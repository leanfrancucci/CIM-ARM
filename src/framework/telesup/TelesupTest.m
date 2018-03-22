#include "system/util/all.h"
#include "Audit.h"
#include "TelesupTest.h"
#include "system/os/comportapi.h"
#include "system/io/all.h"
#include "system/os/all.h"
#include "CommercialStateMgr.h"
#include "UserManager.h"
#include "XMLConstructor.h"
#include "PrinterSpooler.h"
#include "MessageHandler.h"
#include "CimManager.h"
#include "SimCardValidator.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

#define DEFAULT_CONNECT_TIMEOUT    60000	// 60 segundos timeout de conexion
#define COMMAND_TIMEOUT						 4000  // 4 segundos timeout por comando
#define LINE_TEST_TIMEOUT					 30000	// 30 segundos timeout para verificar linea
#define CMD_ECHO_OFF    					 "ATE0"
#define CMD_ESCAPE      					 "+++"
#define CMD_HANGUP      					 "ATH0"
#define CMD_EOL         					 "\r"
#define CMD_LINE_SPEED  					 "ATW2"
#define CMD_OK 		      					 "OK"
#define CMD_AT										 "AT"
#define CMD_ATI3									 "ATI3"
#define CMD_ATI4									 "ATI4"
#define CMD_ATI7									 "ATI7"
#define CMD_ATI8									 "ATI8"
#define CMD_ATCSQ									 "AT+CSQ"
#define CMD_ATCGSN								 "AT+CGSN"
#define CMD_ATCPIN								 "AT+CPIN?"
#define CMD_ATCGMM								 "AT+CGMM?"
#define PIN_READY_RESPONDE 				 "+CPIN: READY"
#define CMD_ATCREG								 "AT+CREG?"
#define CMD_ATDT									 "ATDTW;"
#define CMD_ATS7									 "ATS7=2"
#define CMD_ATZ										 "ATZ"
#define CMD_GPRS_NETWORK_QUERY		 "AT+CGATT?"
#define CMD_GPRS_NETWORK					 "AT+CGATT=1"
#define MAX_CREG_TIMEOUT					 90000

@implementation TelesupTest

+ new
{
	return [[super new] initialize];
}

- initialize
{	
	testTelesupData = (TestTelesupData*)malloc(sizeof(TestTelesupData));
	myBaudRate = BR_19200;	
	myShow = TRUE;
	myResetModem = TRUE;
	return self;
}

/**/
- free
{
	free(testTelesupData);
	return [super free];
}

/**/
- (void) setShow: (BOOL) aValue { myShow = aValue; }

/**/
- (void) setResetModem: (BOOL) aValue { myResetModem = aValue; }

/**/
- (void) sendCommand: (OS_HANDLE) aComHandle command: (char *) aCommand sendNewLine: (int) aSendNewLine
{
	//doLog(0,"sendCommand -> sending |%s|\n", aCommand);
	com_write(aComHandle, aCommand, strlen(aCommand));
	if (aSendNewLine) com_write(aComHandle, CMD_EOL, strlen(CMD_EOL));
}

- (void) waitCommandResponse: (OS_HANDLE) aComHandle command: (char *) aCommand dest: (char *) aDest timeout: (int) aTimeout
{
	unsigned char response[100];
	int i = 0;
	unsigned long ticks = getTicks();
	int n;

	strcpy(aDest, "");

	while (i < 100 && (getTicks() - ticks) < aTimeout )
	{
		n = com_read(aComHandle, &response[i], 1, 1000);
		if (n < 1) continue;

//		doLog(0,"response[i] = %d\n", response[i]);

		// Si es un enter, analizo que comando me llego
		if (response[i] == 0xA) {

			response[i] = 0;

			if (i >= 1 && response[i-1] == 0xD) response[i-1] = 0;
		
			if (*response == 0 || strstr(response, aCommand)) {

				i = -1;

			} else  {

				strcpy(aDest, response);
				return;

			}

		}
		i++;
	}

}


- (void) processCommand: (OS_HANDLE) aComHandle command: (char *) aCommand buf: (char *) aBuf timeout: (int) aTimeout
{
	char line[21];

	snprintf(line, 20, "%-20s", aCommand);
	line[20] = '\0';
	if (myShow) {
		lcd_printat(1, 2, line);
		snprintf(line, 20, "%-20s", "");
		lcd_printat(1, 3, line);
	}

	[self sendCommand: aComHandle command: aCommand sendNewLine: 1];

	[self waitCommandResponse: aComHandle command: aCommand dest: aBuf timeout: aTimeout];

	if (myShow) {
		snprintf(line, 20, "%-20s", aBuf);
		line[20] = '\0';
		lcd_printat(1, 3, line);
	}

	//doLog(0,"buf = |%s|\n", aBuf);

	msleep(250);

	com_flush(aComHandle);
}

/**/
- (void) doResetModem
{
	SIM_CARD_VALIDATOR simCardValidator;

	char line[100];

	// Reset del Modem
	if (myShow) {
		snprintf(line, 20, "%-20s", "Modem Reset");
		line[20] = '\0';
		lcd_printat(1, 2, line);

		snprintf(line, 20, "%-20s", " ");
		line[20] = '\0';
		lcd_printat(1, 3, line);

	}

	system(BASE_PATH "/bin/reset");
	msleep(35000);
	
	//doLog(0,"Verificando SIM card\n");

	simCardValidator = [SimCardValidator new];
	[simCardValidator setPortNumber: 4];
	[simCardValidator setConnectionSpeed: 19200];
	[simCardValidator openSimCard];
	[simCardValidator checkSimCard: NULL];
	[simCardValidator close];
	
}

/**/
- (int) testModem
{
	ComPortConfig comPortConfig;
	OS_HANDLE comHandle;
	char buf[255];
	char *index, *index2, *index3;
	int creg = 2;
	unsigned long ticks;
	int i=0;
	char sys[30];
	STRING_TOKENIZER tokenizer;
  char token[50];
	char aux[500];
	char line[50];
	int status;
	int comPort;

	testTelesupData->signal = -1;
	strcpy(testTelesupData->modemBrand, getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
	strcpy(testTelesupData->modemVersion, getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
	strcpy(testTelesupData->imei, getResourceStringDef(RESID_UNKNOWN, "DESCONOCIDO"));
	strcpy(testTelesupData->cBand, "");
	testTelesupData->gsmModem = 0;
	testTelesupData->hasSim = 0;

	if (myShow) {
		lcd_clear();
		lcd_printat(1,1, getResourceStringDef(RESID_MODEM_TEST_MSG, "Probando modem..."));
	}

	comPortConfig.baudRate = myBaudRate;
	comPortConfig.parity = CT_PARITY_NONE;
	comPortConfig.stopBits = 1;
	comPortConfig.dataBits = 8;
	comPortConfig.readTimeout = 1000;
	comPortConfig.writeTimeout = 1000;

	// Si el COM esta tomado lo desconecto
  status = system(BASE_PATH "/bin/ppptest");
  //doLog(0,"Valor retornado %d\n",status);

  if (status) {

		sprintf(sys, BASE_PATH "/bin/colgar %s", "gprs");
   	system(sys);

		for (i = 0; i < 10; ++i) {
    	msleep(1);
      status = system(BASE_PATH "/bin/ppptest");
			if (status == 0) break;
    }
  }

	// Abro el COM
	// Por default es /dev/ttyS3 (modem interno)
	comPort = [myConnectionSettings getConnectionPortId];
	if (comPort == 0) comPort = 4;

	comHandle = com_open(comPort, &comPortConfig);
	if (comHandle == -1) {
		//doLog(0,"TelesupTest -> Error al abrir puerto\n");
		[Audit auditEvent: Event_TELESUP_TEST_OPEN_PORT_ERROR additional: "" station: 0 logRemoteSystem: FALSE];
		strcpy(testTelesupData->modemResult, getResourceStringDef(RESID_ERROR_OPENING_COM_PORT_MSG, "Error abriendo puerto COM"));
		return 0;
	}

	com_flush(comHandle);

	// Comando AT para ver si responde	
	[self processCommand: comHandle command: CMD_AT buf: buf timeout: COMMAND_TIMEOUT];
	[self processCommand: comHandle command: CMD_AT buf: buf timeout: COMMAND_TIMEOUT];

	msleep(1000);
	com_flush(comHandle);

	[self processCommand: comHandle command: CMD_AT buf: buf timeout: COMMAND_TIMEOUT];

	if (strcmp(buf, "OK") != 0) {
		//doLog(0,"TelesupTest -> Error en comando AT\n");
		[Audit auditEvent: Event_TELESUP_TEST_MODEM_NO_RESPONSE additional: "" station: 0 logRemoteSystem: FALSE];
		strcpy(testTelesupData->modemResult, getResourceStringDef(RESID_MODEM_DONT_RESPOND_AT_MSG, "Modem no responde (AT)"));
		com_close(comHandle);
		if (myResetModem) [self doResetModem];
		return 0;
	}

	// Comando para solicitar el IMEI
	[self processCommand: comHandle command: CMD_ATCGSN buf: buf timeout: COMMAND_TIMEOUT];

	index = NULL;

	// Para SIM COM viene directamente el IMEI
	if (isdigit(*buf)) {
		index = buf;
		index2 = index;
	// Para otros modems viene antepuesto con +CGSN: 
	} else {
		index = strstr(buf, "+CGSN: ");
		index2 = &index[strlen("+CGSN: ")];
	}

	if (index) {
		if (*index2 == '"') index2++;
		index3 = strchr(index2, '"');
		if (*index3) *index3 = '\0';
		strcpy(testTelesupData->imei, index2);
		testTelesupData->gsmModem = 1;
	}


	// Si es modem GSM
	if (testTelesupData->gsmModem) {

		// Comando para solicitar el modelo
		[self processCommand: comHandle command: CMD_ATI7 buf: buf timeout: COMMAND_TIMEOUT];
		strcpy(testTelesupData->modemBrand, buf);
	
		// Comando para solicitar la version
		[self processCommand: comHandle command: CMD_ATI8 buf: buf timeout: COMMAND_TIMEOUT];
		strcpy(testTelesupData->modemVersion, buf);

		// Comando para solicitar la senial
		[self processCommand: comHandle command: CMD_ATCSQ buf: buf timeout: COMMAND_TIMEOUT];
		index = strstr(buf, "+CSQ: ");
		if (index) {
			index2 = strstr(index, ",");
			if (index2) {
				index2 = '\0';
				testTelesupData->signal = atoi(&index[strlen("+CSQ: ")]);
				testTelesupData->signal = testTelesupData->signal * 3;
			}
		}

		// Comando para solicitar si tiene SIM correcto
		[self processCommand: comHandle command: CMD_ATCPIN buf: buf timeout: COMMAND_TIMEOUT];
		index = strstr(buf, PIN_READY_RESPONDE);
		if (index) {
			testTelesupData->hasSim = 1;
		}				

		// Comando ver si tiene Red GPRS
		testTelesupData->gprsNetwork = 0;
		[self processCommand: comHandle command: CMD_GPRS_NETWORK buf: buf timeout: COMMAND_TIMEOUT];

		msleep(2000);

		[self processCommand: comHandle command: CMD_GPRS_NETWORK_QUERY buf: buf timeout: COMMAND_TIMEOUT];
		index = strstr(buf, "+CGATT:");
		if (index) {
			testTelesupData->gprsNetwork = atoi(&index[strlen("+CGATT:")]);
		}
	
		// Comando para ver si esta registrado
		ticks = getTicks();
		while (creg == 2 && getTicks() - ticks < MAX_CREG_TIMEOUT) {
			creg = 0;
			[self processCommand: comHandle command: CMD_ATCREG buf: buf timeout: COMMAND_TIMEOUT];
			index = strstr(buf, "+CREG: ");
			if (index) {
				index2 = strstr(index, ",");
				if (index2) {
					creg = atoi(&index2[1]);
				}
			}
		}
		testTelesupData->creg = creg;


		// Comando para ver la cantidad de bandas
		aux[0] = '\0';
		strcpy(testTelesupData->cBand, aux);
		if (strcmp(testTelesupData->modemVersion,"SIMCOM_Ltd") != 0){
			[self processCommand: comHandle command: CMD_ATCGMM buf: buf timeout: COMMAND_TIMEOUT];
			index = strstr(buf, "+CGMM: ");
			if (index) {
				index2 = strstr(index, ",");
				if (index2) {
					index2 = '\0';

					tokenizer = [[StringTokenizer new] initTokenizer: &index[strlen("+CGMM: ")] delimiter: ","];

					while ([tokenizer hasMoreTokens]) {
						[tokenizer getNextToken: token];
						strcat(aux, "   ");
						strcat(aux, token);
						strcat(aux, "\n");
					}
					strcpy(testTelesupData->cBand, aux);
					[tokenizer free];
				}
			}
		}

	} else {

		// Comando para solicitar el modelo
		[self processCommand: comHandle command: CMD_ATI4 buf: buf timeout: COMMAND_TIMEOUT];
		strcpy(testTelesupData->modemBrand, buf);
	
		// Comando para solicitar la version
		[self processCommand: comHandle command: CMD_ATI3 buf: buf timeout: COMMAND_TIMEOUT];
		strcpy(testTelesupData->modemVersion, buf);

		// Comando para probar linea (ATDT)
		[self processCommand: comHandle command: CMD_ATDT buf: buf timeout: LINE_TEST_TIMEOUT];
		if (*buf == '\0') {
			strcpy(testTelesupData->lineTestReponse, "TIMEOUT");
		} else {
			strcpy(testTelesupData->lineTestReponse, buf);
		}
		//doLog(0,"response = %s\n", buf);

	}


	com_close(comHandle);

	if (myResetModem) [self doResetModem];

	//doLog(0,"GSM Modem : %d\n", testTelesupData->gsmModem);
	//doLog(0,"Brand     : %s\n", testTelesupData->modemBrand);
	//doLog(0,"Version   : %s\n", testTelesupData->modemVersion);
	//doLog(0,"IMEI      : %s\n", testTelesupData->imei);
	//doLog(0,"Signal    : %d %%\n", testTelesupData->signal);
	//doLog(0,"Has SIM   : %d\n", testTelesupData->hasSim);
	//doLog(0,"Register  : %d\n", testTelesupData->creg);
	//doLog(0,"GPRS      : %d\n", testTelesupData->gprsNetwork);

	if (testTelesupData->gsmModem && !testTelesupData->hasSim){
		//doLog(0,"TelesupTest -> Error en tarjeta SIM\n");
		strcpy(testTelesupData->modemResult, getResourceStringDef(RESID_SIM_CARD_ERROR_MSG, "Error en tarjeta SIM"));
		[Audit auditEvent: Event_TELESUP_TEST_SIM_CARD_ERROR additional: "" station: 0 logRemoteSystem: FALSE];
		return 0;
	}else if (testTelesupData->gsmModem && testTelesupData->creg != 1 && testTelesupData->creg != 5){
		//doLog(0,"TelesupTest -> No esta registrado a la red\n");
		[Audit auditEvent: Event_TELESUP_TEST_SIM_NOT_REGISTERED additional: "" station: 0 logRemoteSystem: FALSE];
		strcpy(testTelesupData->modemResult, getResourceStringDef(RESID_NOT_REG_TO_NETWORK_MSG, "No registrado en la red"));
		return 0;
	}else if (testTelesupData->gsmModem && !testTelesupData->gprsNetwork) {
		//doLog(0,"TelesupTest -> Red GPRS no disponible\n");
		[Audit auditEvent: Event_TELESUP_TEST_GPRS_NETWORK_ERROR additional: "" station: 0 logRemoteSystem: FALSE];
		strcpy(testTelesupData->modemResult, getResourceStringDef(RESID_GPRS_NETWORK_ERROR_MSG, "Error en Red GPRS"));
		return 0;
	}else if (!testTelesupData->gsmModem && strcmp(testTelesupData->lineTestReponse, "OK") != 0) {
		sprintf(buf, getResourceStringDef(RESID_LINE_ERROR_MSG, "Error en linea: %-13s"), testTelesupData->lineTestReponse);
		strcpy(testTelesupData->modemResult, buf);
		//doLog(0,"%s\n",buf);
		sprintf(line, "%s", testTelesupData->lineTestReponse);
		[Audit auditEvent: Event_TELESUP_TEST_LINE_ERROR additional: line station: 0 logRemoteSystem: FALSE];
		return 0;
	} else {
		[Audit auditEvent: Event_TELESUP_TEST_MODEM_OK additional: "" station: 0 logRemoteSystem: FALSE];
		strcpy(testTelesupData->modemResult, "Modem OK");
	}

	return 1;
}

/**/
- (int) getTestModemReport: (char *) aBuf
{
	char line[100];
	static char *modemTypeStr[] = {"Fixed", "GSM"};

	int isRegistered;

	aBuf[0] = '\0';

	if (testTelesupData->useModem){
		strcat(aBuf, "    ---> MODEM TEST <---\n");

		strcat(aBuf, " \n");
		sprintf(line, "%s\n", testTelesupData->modemResult);
		strcat(aBuf, line);

		sprintf(line, " %s    : %s\n", getResourceStringDef(RESID_MODEM_TYPE_MSG, "Tipo"),modemTypeStr[testTelesupData->gsmModem]);
		strcat(aBuf, line);
	
		sprintf(line, " %s   : %-18s\n", getResourceStringDef(RESID_MODEM_BRAND_MSG, "Marca"), testTelesupData->modemBrand);
		strcat(aBuf, line);
	
		sprintf(line, " Version : %-18s\n", testTelesupData->modemVersion);
		strcat(aBuf, line);
	
		if (testTelesupData->gsmModem) {

			sprintf(line, " IMEI    : %-18s\n", testTelesupData->imei);
			strcat(aBuf, line);
		
			sprintf(line, " %s  : %d %%\n", getResourceStringDef(RESID_MODEM_SIGNAL_MSG, "Senial"), testTelesupData->signal);
			strcat(aBuf, line);
		
			if (testTelesupData->hasSim)
				sprintf(line, " SIM     : %s\n", getResourceStringDef(RESID_YES, "Si"));
			else
				sprintf(line, " SIM     : %s\n", getResourceStringDef(RESID_NO, "No"));
			strcat(aBuf, line);

			isRegistered = (testTelesupData->creg == 1 || testTelesupData->creg == 5);
			if (isRegistered)
				sprintf(line, " %s: %s (%d)\n", getResourceStringDef(RESID_MODEM_REGISTER_MSG, "Registr."), getResourceStringDef(RESID_YES, "Si"), testTelesupData->creg);
			else
				sprintf(line, " %s: %s (%d)\n", getResourceStringDef(RESID_MODEM_REGISTER_MSG, "Registr."), getResourceStringDef(RESID_NO, "No"), testTelesupData->creg);
			strcat(aBuf, line);

			sprintf(line, " GPRS    : %s\n", testTelesupData->gprsNetwork ? "OK" : "Error");
			strcat(aBuf, line);

			if (strlen(testTelesupData->cBand) != 0){
				sprintf(line, " %s   : \n%s", getResourceStringDef(RESID_MODEM_BANDS_MSG, "Banda"), testTelesupData->cBand);
				strcat(aBuf, line);
			}
		}
	}

	// si corrio la supervision muestro el resultado
	if (strcmp(testTelesupData->supervisionResult, "NOT RUN") != 0){
		strcat(aBuf, " \n");
		strcat(aBuf, "  ---> SUPERVISION TEST <---\n");
		strcat(aBuf, " \n");
		sprintf(line, "%s\n", testTelesupData->supervisionResult);
		strcat(aBuf, line);		
	}
	

}

/**/
- (int) getCimStateDescription: (char *) aBuf
{
	char line[512];
	char title[128];

	BOOL ok = TRUE;

	aBuf[0] = '\0';
	*line = '\0';

	strcat(aBuf, " \n");

	if ([[CimManager getInstance] isDoorOpen]) {
		strcat(line, getResourceStringDef(RESID_TELESUP_PROBLEM_DOOR_IS_OPEN, "* Door is open"));
		strcat(line, " \n");
		ok = FALSE;
	}

	if ([[CimManager getInstance] isOnDeposit]) {
		strcat(line, getResourceStringDef(RESID_TELESUP_PROBLEM_ON_DROP, "* On Drop"));
		strcat(line, " \n");
		ok = FALSE;
	}

	if ([[CommercialStateMgr getInstance] isChangingState]) {
		strcat(line, getResourceStringDef(RESID_TELESUP_PROBLEM_CHANGING_STATE, "* Changing State"));
		strcat(line, " \n");
		ok = FALSE;
	}

	if (![[CommercialStateMgr getInstance] canExecutePimsSupervision]) {
		strcat(line, getResourceStringDef(RESID_TELESUP_PROBLEM_INVALID_COMMERCIAL_STATE, "* Invalid Commercial State"));
		strcat(line, " \n");
		ok = FALSE;
	}

	if (!ok) {
		sprintf(title, "   --> %s <--\n \n", getResourceStringDef(RESID_TELESUP_CURRENT_PROBLEMS, "CURRENT PROBLEMS"));
		strcat(aBuf, title);
		strcat(aBuf, line);
		strcat(aBuf, "\n");
	}

	return 1;

}

/**/
- (void) printReport
{
	char *testReport;
	char line[500], datestr[50];
	time_t now;
	struct tm *brokenTime;
	char buff[10000];
	scew_tree* tree;

	testReport = malloc(32768);
	*testReport = '\0';
	now = time(NULL);
	brokenTime = localtime(&now);

	sprintf(datestr, "%04d-%02d-%02d %02d:%02d:%02d", 
			brokenTime->tm_year + 1900, 
			brokenTime->tm_mon + 1,
			brokenTime->tm_mday,
			brokenTime->tm_hour,
			brokenTime->tm_min,
			brokenTime->tm_sec
		);

	sprintf(line, "f \n \n"
								 "-----------------------------\n"
								 "  %s\n"
								 "-----------------------------\n"
								 "  %s GMT\n"
								 "-----------------------------\n \n", getResourceStringDef(RESID_REPORT_TEST_TITLE, " REPORTE PRUEBA SUPERVISION"), datestr);

	strcat(testReport, line);

	[self getTestModemReport: buff];
	strcat(testReport, buff);

	[self getCimStateDescription: buff];
	strcat(testReport, buff);

	strcat(testReport, "\n \n \n \n \n \n");

	// Mando a imprimir el documento generado
	tree = [[XMLConstructor getInstance] buildXML: testReport];
	[[PrinterSpooler getInstance] addPrintingJob: TEXT_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree];

	free(testReport);

}

/**/
- (void) setSupervisionResult: (char *) aBuf
{
	strcpy(testTelesupData->supervisionResult, aBuf);
}

/**/
- (void) setUseModem: (int) aValue
{
	testTelesupData->useModem = aValue;
}

/**/
- (void) setBaudRate: (BaudRateType) aBaudRate
{ 
	myBaudRate = aBaudRate; 
}

/**/
- (void) setConnectionSettings: (CONNECTION_SETTINGS) aValue
{
	myConnectionSettings = aValue;
}

@end
