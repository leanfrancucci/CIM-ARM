#include <string.h>
#include <strings.h>
#include "Modem.h"
#include "DevExcepts.h"
#include "util.h"

//#define printd(args...) doLog(args)
//#define printd(args...)
//#define LOG(args...)
#define LOG(args...) logCategory("LOG_MODEM", TRUE, args)

#define DEFAULT_CONNECT_TIMEOUT    60000	// 60 segundos timeout de conexion
#define COMMAND_TIMEOUT							4000  // 4 segundos timeout por comando
#define CMD_ATDT   			"ATDT"
#define CMD_ECHO_OFF    "ATE0"
#define CMD_ESCAPE      "+++"
#define CMD_HANGUP      "ATH0"
#define CMD_EOL         "\r"
#define CMD_LINE_SPEED  "ATW2"
#define CMD_OK 		      "OK"

char *strdup(const char *s);

static int BaudRate[] = { BR_300, BR_1200, BR_2400, BR_4800, BR_9600,
BR_19200, BR_38400, BR_57600, BR_115200};

static int ModemSpeed[] = { 300, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200 };

@implementation Modem

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	initScript = NULL;
	comPort = [ComPort new];
	baudRate = BR_115200;
	connectTimeout = DEFAULT_CONNECT_TIMEOUT;
	connectionSpeed = 0;
	return self;
}

/**/
- free
{
	if (initScript) free(initScript);
	[comPort free];
	return [super free];
}

/**/
- (void) open
{
	[comPort setBaudRate: baudRate];
	[comPort setStopBits: 1];
	[comPort open];
 	[comPort flush];
}

/**/
- (void) close
{
	[comPort close];
}

/**/
- (ModemStatus) mapModemStatus: (char *) s
{
	char *speed;

	if (strstr(s, "NO DIALTONE")) THROW(NO_DIALTONE_EX);
	if (strstr(s, "NO ANSWER")) THROW(NO_ANSWER_EX);
	if (strstr(s, "NO CARRIER")) THROW(NO_CARRIER_EX);
	if (strstr(s, "BUSY")) THROW(BUSY_EX);
	if (strstr(s, "CONNECT")) {
		LOG("Cadena es %s\n", s);
		speed = s + 8;
		LOG("Conecion speed es %s\n", speed);
		connectionSpeed = atoi(speed);
		return ModemStatus_OK;
	}
	THROW(CONNECTION_TIMEOUT_EX);
	return ModemStatus_UNKNOWN_ERROR;
}

/**/
- (void) sendCommand: (char*) aCommand expect: (char*) aExpectValue sendNewLine: (BOOL) aSendNewLine
{
	unsigned char response[100];
	int i = 0;
	unsigned long ticks = getTicks();
	
	LOG("sendCommand -> sending |%s|, expect |%s|\n", aCommand, aExpectValue);
	[comPort write: aCommand qty: strlen(aCommand)];
	if (aSendNewLine) [comPort write: CMD_EOL qty: strlen(CMD_EOL)];

	if (*aExpectValue == 0) return;
	
	while (i < 100 && (getTicks() - ticks) < COMMAND_TIMEOUT )
	{
		if ( [comPort read: &response[i] qty: 1] != 1) continue;

		// Si es un enter, analizo que comando me llego
		if (response[i] == 0xA) {
			response[i] = 0;
			if (i >= 1 && response[i-1] == 0xD) response[i-1] = 0,
			
			LOG("sendCommand -> RESPONSE is %s\n", response);
			if (strstr(response, aExpectValue)) return;
			if (*response == 0 || strstr(response, aCommand)) i = -1;
		}
		i++;
	}

	THROW(MODEM_NOT_RESPONDING_EX);
}

/**/
- (char*) getLine: (char*) aText line: (char*) aLine
{
	char *index;

	index = strchr(aText, 13);
	if (!index) index = strchr(aText, 10);
	if (!index) index = strchr(aText, 0);
	if (!index) return NULL;
	
	strncpy(aLine, aText, index - aText);
	aLine[index-aText] = 0;

	index++;
	if (*index == 10) index++;

	return index;
}

/**/
- (void) processScript: (char*) aScript
{
	char *p = aScript;
	char line[255];
	char command[100];
	char expect[100];
	char *fromIndex, *toIndex;
	
	while (*p != 0) {

		p = [self getLine: p line: line];
		if (*line == 0) continue;
		if (*line == '[') return;			// Termina este tipo de script y comienza otro
		if (*line == '#') continue;		// Es un comentario
		
		fromIndex = strstr(line, "\"");
		if (!fromIndex) continue;
		fromIndex++;
		toIndex = strstr(fromIndex, "\"");
		if (!toIndex) continue;
		strncpy(command, fromIndex, toIndex - fromIndex);
		command[toIndex - fromIndex] = 0;
		
		toIndex++;
		fromIndex = strstr(toIndex, "\"");
		if (!fromIndex) continue;		
		fromIndex++;
		toIndex = strstr(fromIndex, "\"");
		if (!toIndex) continue;
		strncpy(expect, fromIndex, toIndex - fromIndex);
		expect[toIndex - fromIndex] = 0;

		// Debo enviar un comando, a no ser que sea un sleep con lo cual espero cierta cantidad de tiempo
		if (strcasecmp(command, "SLEEP") == 0) {
			LOG("Modem -> Esperando %d milisegundos\n", atoi(expect));
			msleep(atoi(expect));
		}
		else {
			[self sendCommand: command expect: expect sendNewLine: TRUE];
		}
				
	}

}

/**/
- (ModemStatus) connect: (char*) aPhone
{
	unsigned char response[100];
	int i = 0;
	unsigned long ticks;
	char *connectScript = NULL;
	static char *connectTag = "[connect]";
	
	// Deshabilito el ECHO para que no moleste
  // Aca me paso que con un modem esto no me funcionaba como corresponde, me devolvia un caracter
  // extranio antes del OK, por lo tanto ignoro todo, pero leo como si fuera basura.
  /*[comPort write: CMD_ECHO_OFF qty: strlen(CMD_ECHO_OFF)];	
  [comPort write: CMD_EOL qty: strlen(CMD_EOL)];
  [comPort read: response qty: 100];
  LOG("ECHO OFF -> RESPONSE is %s\n", response);*/
	[self sendCommand: CMD_ECHO_OFF expect: CMD_OK sendNewLine: TRUE];
	
	// Envia el comando para que cuando se conecte me devuelve la velocidad
	// real de conexion.
  TRY
	  [self sendCommand: CMD_LINE_SPEED expect: CMD_OK sendNewLine: TRUE];
	CATCH
  END_TRY

	// Busco la cadena [connect]	
	if (initScript) connectScript = strstr(initScript, connectTag);
	if (connectScript) [self processScript: connectScript + strlen(connectTag) + 1];
	
	// Disca el numero telefonico
	[comPort write: CMD_ATDT qty: strlen(CMD_ATDT)];
	[comPort write: aPhone qty: strlen(aPhone)];
	[comPort write: CMD_EOL qty: strlen(CMD_EOL)];
	
	ticks = getTicks();
	
	// Se queda esperando un CONNECT xxxxxx\n
	// Cualquier otra condicion NO_DIALTONE, NO_ANSWER, etc...devuelve el codigo de
	// error correspondiente, espera por un timeout determinado
	while (i < 100 && (getTicks() - ticks) < connectTimeout )
	{
		if ( [comPort read: &response[i] qty: 1] != 1) continue;

		// Si es un enter, analizo que comando me llego
		if (response[i] == 0xA) {
			response[i] = 0;
			if (i >= 1 && response[i-1] == 0xD) response[i-1] = 0,
			LOG("connect -> RESPONSE is %s\n", response);
			if (strstr(response, CMD_ATDT) || *response == 0 || strstr(response, "OK")) {
				i = -1;
			} else {
				return [self mapModemStatus: response];
			}
		}
		i++;
	}

	THROW(CONNECTION_TIMEOUT_EX);
	
	return ModemStatus_TIMEOUT;
}

/**/
- (void) setBaudRate: (BaudRateType) aBaudRate
{
	baudRate = aBaudRate;
}

/**/
- (void) setInitScript: (char *) aScript
{
	if (initScript) free(initScript);
	initScript = strdup(aScript);
}

/**/
- (void) setReadTimeout: (int) aReadTimeout
{
	[comPort setReadTimeout: aReadTimeout];
}

/**/
- (void) setWriteTimeout: (int) aWriteTimeout
 {
 	[comPort setWriteTimeout: aWriteTimeout];
 }

/**/
- (void) setConnectTimeout: (int) aConnectTimeout
{
	connectTimeout = aConnectTimeout;
}
 
/**/
- (void) setPortNumber: (int) aPortNumber
{
	[comPort setPortNumber: aPortNumber];
}

/**/
- (void) disconnect
{
	char *disconnectScript = NULL;
	static char *disconnectTag = "[disconnect]";
	
	// Busco la cadena [connect]	
	if (initScript) disconnectScript = strstr(initScript, disconnectTag);
	if (disconnectScript) [self processScript: disconnectScript + strlen(disconnectTag) + 1];

	[comPort flush];

	[comPort write: CMD_ESCAPE qty: strlen(CMD_ESCAPE)];
	msleep(COMMAND_TIMEOUT);	// Espero unos segundos
	[comPort write: CMD_HANGUP qty: strlen(CMD_HANGUP)];
	[comPort write: CMD_EOL qty: strlen(CMD_EOL)];

	[comPort flush];

}

/**/
- (READER) getReader
{
	return [comPort getReader];
}

/**/
- (WRITER) getWriter
{
	return [comPort getWriter];
}

/**/
- (void) flush
{
	[comPort flush];
}

/**/
- (int) getConnectionSpeed
{
	return connectionSpeed;
}

/**/
+ (BaudRateType) getBaudRateFromSpeed: (int) aSpeed
{
	int i;
	
	for (i = 0; i < sizeOfArray(ModemSpeed); i++)
		if (ModemSpeed[i] == aSpeed) return BaudRate[i];
		
	return BR_115200;
	
}

@end
