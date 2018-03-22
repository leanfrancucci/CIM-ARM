#ifndef TELESUPTEST_H
#define TELESUPTEST_H

#define TELESUP_TEST id

#include <Object.h>
#include "ctapp.h"
#include "ConnectionSettings.h"

/**/
typedef struct {
	char modemBrand[100];
	char modemVersion[100];
	char imei[50];
	char lineTestReponse[100];
	int	 signal;
	char cpin;
	int  gsmModem;
	int  hasSim;
	int  creg;	// Si es 1 o 5 quiere decir que esta registrado
	char cBand[500];
	char modemResult[100];
	char supervisionResult[100];
	int  useModem;
	int  gprsNetwork;
} TestTelesupData;

/*
 *	Define el tipo de los parsers de mensajes de telesupervision
 */
@interface TelesupTest: Object
{
	TestTelesupData *testTelesupData;
	BaudRateType myBaudRate;
	BOOL myShow;
	BOOL myResetModem;
	CONNECTION_SETTINGS myConnectionSettings;
}

/*
 *	
 */
+ new;

/*
 *	
 */
- initialize;

/**/
- (void) sendCommand: (OS_HANDLE) aComHandle command: (char *) aCommand sendNewLine: (int) aSendNewLine;

/**/
- (void) waitCommandResponse: (OS_HANDLE) aComHandle command: (char *) aCommand dest: (char *) aDest timeout: (int) aTimeout;

/**/
- (void) processCommand: (OS_HANDLE) aComHandle command: (char *) aCommand buf: (char *) aBuf timeout: (int) aTimeout;

/**/
- (int) testModem;

/**/
- (int) getTestModemReport: (char *) aBuf;

/**/
- (void) printReport;

/**/
- (void) setSupervisionResult: (char *) aBuf;

/**/
- (void) setUseModem: (int) aValue;

/**/
- (void) setBaudRate: (BaudRateType) aBaudRate;

/**/
- (void) setShow: (BOOL) aValue;

/**/
- (void) setResetModem: (BOOL) aValue;

/**/
- (void) setConnectionSettings: (CONNECTION_SETTINGS) aValue;

@end

#endif
