#include <assert.h>
#include "SimCardValidator.h"
#include "ComPort.h"
#include "Modem.h"

/* macro para debugging */
//#define LOG(args...) doLog(0,args)
//#define LOG(args...)
//#define printd(args...)

/////// MACROS DE TAMANOS Y TIEMPOS ///////////////////////////
#define MAX_RESPONSE_SIZE         100    // tamanio maximo de la respuesta
#define CHECK_NEW_MESSAGES_TIMER  1000    // cada cuanto verifica si hay mensajes nuevos (en ms)  
#define COMMAND_TIMEOUT           4000    // timeout de envio de comandos
#define WRITE_MESSAGE_RESPONSE_TIMEOUT  40000 // timeout para esperar la confirmacion del envio
#define READ_MESSAGE_BODY_TIMEOUT 15000   // timeout maximo para leer el cuerpo de un mensaje
#define DELETE_MESSAGE_TIMEOUT    10000   // timeout para borrar un mensaje

////// COMANDOS AL MODEM GSM /////////////////////////////////
#define READ_MESSAGE_CMD          "AT+CMGR=%d\x0D"
#define DELETE_MESSAGE_CMD        "AT+CMGD=%d\x0D"     
#define ECHO_OFF_CMD              "ATE0\x0D"    
#define SET_UTF8_ENCODING_CMD     "AT+CSCS=\"UTF8\"\x0D"
#define SET_UCS2_ENCODING_CMD     "AT+CSCS=\"UCS2\"\x0D"
#define SET_TEXT_MODE_PARAMETERS_CMD "AT+CSMP=17,167,0,10\x0D"
#define SET_GSM_ENCODING_CMD      "AT+CSCS=\"GSM\"\x0D"
#define SET_ASCII_ENCODING_CMD    "AT+CSCS=\"ASCII\"\x0D"
#define DELETE_ALL_MESSAGES_CMD   "AT+CMGD=1,4\x0D" 
#define SET_EXTENDED_ERROR_CMD    "AT+CMEE=1\x0D"
#define SIGNAL_QUALITY_CMD        "AT+CSQ\x0D"
#define DISABLE_CALL_PROGRESS_CMD "AT+MCST=0\x0D"
#define PIN_READY_CMD             "AT+CPIN?\x0D"
#define PIN_READY_RESPONSE        "+CPIN: READY"
#define CPIN_RESPONSE							"+CPIN: "
#define WRITE_MESSAGE_CMD         "AT+CMGS=\"%s\"\x0D"  // Ojo, solo es <CR>
#define AT_CMD                    "AT\x0D"
#define ATZ_CMD                   "ATZ\x0D"
#define SET_TEXT_MODE_CMD         "AT+CMGF=1\x0D"
#define END_OF_MESSAGE            "\x1A"    // Ctrl + Z
#define MESSAGE_OK                "OK"
#define ERROR_STRING              "ERROR: "
#define CR_CHAR                   '\xD'
#define LF_CHAR                   '\xA'
#define SIGNAL_QUALITY_RESPONSE   "+CSQ: "
#define WRITE_MESSAGE_RESPONSE    "+CMGS:"
#define WRITE_MESSAGE_PROMPT      ">"
#define WRITE_CANCEL_CMD          "\x18"
#define LIST_MESSAGES_CMD         "AT+CMGL=\"REC UNREAD\"\x0D"
#define MESSAGE_LIST_RESPONSE     "+CMGL: "
#define SIM_READY									"READY"
#define SIM_PIN2									"PIN2"
#define SIM_PUK2									"PUK2"
#define SIM_PIN										"SIM PIN"
#define SIM_PUK										"SIM PUK"
#define CHECK_SIM_CARD_LOCK				"AT+CLCK=\"SC\",2\x0D"
#define CHECK_SIM_CARD_LOCK_RESPONSE "+CLCK: "

#ifdef __UCLINUX
#define PIN_FILE									BASE_APP_PATH "/gpc.dat"
#else
#define PIN_FILE									"gpc.dat"
#endif


/**/
@implementation SimCardValidator

static SIM_CARD_VALIDATOR singleInstance = NULL; 

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}

/**/
+ getInstance
{
  return [self new];
}

- (void) loadPin;

/**/
- initialize
{
  myReader = NULL;
  myWriter = NULL;
	myComPort = NULL;
	myIsSimCardLocked = FALSE;
	myConnectionSpeed = 19200;
	strcpy(myPin, "");
	[self loadPin];
  return self;
}

/**/
- (void) loadPin
{
	char *source;

	source = loadFile(PIN_FILE, FALSE);
	if (source == NULL) {
		//doLog(0,"Error loading pin file\n");
		return;
	}
	decryptSimple(myPin, source, 8);
	myPin[8] = '\0';
//	doLog(0,"PIN = |%s|\n", myPin);

	free(source);
}

/**/
- (void) storePin
{
	FILE *f;
	char dest[20];
	char source[20];

	memset(source, 0, 9);
	strcpy(source, myPin);
	encryptSimple(dest, source, 8);

	f = fopen(PIN_FILE, "w+b");
	if (f == NULL) {
	//	doLog(0,"Error in PIN file\n");
		return;
	}

	fwrite(dest, 1, 8, f);
	fclose(f);
}

/**/
- free
{
	if (myComPort) {
		[self close];
	}
	return [super free];
}

/**/
- (void) setPortNumber: (int) aValue { myPortNumber = aValue; }
- (void) setConnectionSpeed: (int) aValue { myConnectionSpeed = aValue; }

/**/
- (char *) readAllResponse: (char *) aBuffer timeout: (int) aTimeout
{
  int i = 0;
  unsigned long ticks = getTicks();
 
  *aBuffer = 0;

	while (i < MAX_RESPONSE_SIZE && (getTicks() - ticks) < aTimeout ) {

		if ( [myReader read: &aBuffer[i] qty: 1] != 1) {
      continue;
    }
		i++;
		aBuffer[i] = 0;
	}
	return aBuffer;

}

/**
 *  Lee la respuesta del modem y la almancena en aBuffer.
 *  Lee caracter por caracter hasta que encuentre un fin de linea. Una vez
 *  que encuentra el fin de linea y si hay datos los devuelve, siempre y 
 *  cuando no haya pasado el timeout (en milisegundos).
 *  El parametro ignoreEmptyEol indica el comportamiento en caso que se lea
 *  unicamente un fin de linea. En caso que sea TRUE lo ignora y sigue leyendo la
 *  siguiente linea. En caso que sea FALSE, retorna de la funcion. 
 */
- (char *) readResponse: (char *) aBuffer timeout: (int) aTimeout ignoreEmptyEol: (BOOL) aIgnoreEmptyEol 
{
  int i = 0;
  unsigned long ticks = getTicks();
 
  *aBuffer = 0;

	while (i < MAX_RESPONSE_SIZE && (getTicks() - ticks) < aTimeout ) {

		if ( [myReader read: &aBuffer[i] qty: 1] != 1) {
      continue;
    }

		// Si es un enter, analizo que comando me llego
		if (aBuffer[i] == LF_CHAR) {

			aBuffer[i] = 0;

			if (i >= 1 && aBuffer[i-1] == CR_CHAR) aBuffer[i-1] = 0;

      // Si el buffer es vacio o es RING o NO CARRIER entonces continuo
      // leyendo
			if ((*aBuffer == 0 && aIgnoreEmptyEol) ||
          strstr(aBuffer, "RING") == aBuffer ||
          strstr(aBuffer, "NO CARRIER") == aBuffer) {
        if (*aBuffer != '\0') {
          // Si es un RING incremento en 3 segundos el timeout, es medio peligroso
          // pero no queda otra, porque el RING hace que el envio del mensaje se me atrase.
          if (strstr(aBuffer, "RING") == aBuffer) aTimeout += 3000;
          //doLog(0,"buf = |%s|\n", aBuffer);
        }
        i = -1;
      } else {
			//		doLog(0,"<---- %s\n", aBuffer);
          return aBuffer;
      }
		}
		i++;
  	aBuffer[i] = 0;

    // Si viene el prompt, entonces lo devuelvo 
    if (strstr(aBuffer, "> ") == aBuffer) {
			//doLog(0,"<---- %s\n", aBuffer);
      return aBuffer;
    }

	}

  aBuffer[i] = 0;
	//doLog(0,"<---- %s\n", aBuffer);
  return aBuffer;
}

/**/
- (char *) readResponse: (char *) aBuffer timeout: (int) aTimeout
{
  return [self readResponse: aBuffer timeout: aTimeout ignoreEmptyEol: TRUE];
}

/**
 *  Escribe
 */
- (void) writeCommand: (char*) aCommand
{
	//doLog(0,"---> %s\n", aCommand);
  [myWriter write: aCommand qty: strlen(aCommand)];
}

/**/
- (void) close
{
	[myComPort flush];
	[myComPort close];
	[myComPort free];
	myComPort = NULL;
}

/**/
- (BOOL) openSimCard
{
	char response[100];
	char *p;

	myComPort = [ComPort new];
	[myComPort setBaudRate: [Modem getBaudRateFromSpeed: myConnectionSpeed]];
	[myComPort setStopBits: 1];
	[myComPort setDataBits: 8];
	[myComPort setParity: CT_PARITY_NONE];
	[myComPort setPortNumber:	myPortNumber];
	[myComPort setReadTimeout: 1000];	
	[myComPort open];	
  myReader = [myComPort getReader];
  myWriter = [myComPort getWriter];

 // Elimino toda la basura que haya quedado en el buffer
	*response = '\0';
  //[myReader read: response qty: MAX_RESPONSE_SIZE];
	[self readAllResponse: response timeout: 3000];
  
  [self writeCommand: AT_CMD];
  [self readResponse: response timeout: 1000];
	if (strstr(response, AT_CMD)) { 		// Tiene ECHO, descarto esa linea
		[self readResponse: response timeout: 1000];
	}

  [self writeCommand: AT_CMD]; 
	[self readResponse: response timeout: 1000];
	if (strstr(response, AT_CMD)) { 		// Tiene ECHO, descarto esa linea
		[self readResponse: response timeout: 1000];
	}

  [self writeCommand: ECHO_OFF_CMD]; 
  [self readResponse: response timeout: COMMAND_TIMEOUT];
	if (strstr(response, ECHO_OFF_CMD)) { 		// Tiene ECHO, descarto esa linea
		[self readResponse: response timeout: COMMAND_TIMEOUT];
	}

	// Verifica si la facility esta bloqueada
	[self writeCommand: CHECK_SIM_CARD_LOCK]; 
  [self readResponse: response timeout: COMMAND_TIMEOUT];
	p = strstr(response, CHECK_SIM_CARD_LOCK_RESPONSE);
	if (p != NULL) {
		p += strlen(CHECK_SIM_CARD_LOCK_RESPONSE);
		myIsSimCardLocked = atoi(p);
  	[self readResponse: response timeout: COMMAND_TIMEOUT];

		return TRUE;
	}
	p = strstr(response, "ERROR");
	if (p != NULL) return TRUE;

	return FALSE;
}

/**/
- (BOOL) enterPuk: (char *) aPuk newPin: (char *) aNewPin
{
	char request[100];
	char response[100];

	// Envio el PIN
	sprintf(request, "AT+CPIN=\"%s\",\"%s\"\x0D", aPuk, aNewPin);
	[self writeCommand: request]; 
	[self readResponse: response timeout: COMMAND_TIMEOUT];

	if (strstr(response, "OK") != NULL) {
		strcpy(myPin, aNewPin);
		[self storePin];
		return TRUE;
	}
	return FALSE;

}

/**/
- (SimCardStatus) checkSimCard: (char *) aPin
{
	char request[100];
	char response[100];
	char response2[100];
	char *p;

	// Verifica si hay SIM disponible
	[self writeCommand: PIN_READY_CMD]; 
	[self readResponse: response timeout: COMMAND_TIMEOUT];
	[self readResponse: response2 timeout: COMMAND_TIMEOUT];	

	if (strstr(response, CPIN_RESPONSE) != NULL)
		p = response + strlen(CPIN_RESPONSE);
	else 
		return SimCardStatus_ERROR;

// 	doLog(0,"RESULT = |%s|\n", p);

	if (strstr(p, SIM_READY) != NULL) 
		return SimCardStatus_READY;

	if (strstr(p, SIM_PIN2) != NULL || strstr(p, SIM_PUK2) != NULL) 
		return SimCardStatus_BLOCKED;
	
	if (strstr(p, SIM_PUK) == p)
		return SimCardStatus_PUK_REQUIRED;

	if (strstr(p, SIM_PIN) == p) {

		if (aPin != NULL && *aPin == '\0') return SimCardStatus_PIN_REQUIRED;

		// Envio el PIN
		if (aPin == NULL)
			sprintf(request, "AT+CPIN=\"%s\"\x0D", myPin);
		else 
			sprintf(request, "AT+CPIN=\"%s\"\x0D", aPin);

		[self writeCommand: request]; 
		[self readResponse: response timeout: COMMAND_TIMEOUT];

		if (strstr(response, "OK") != NULL) {

			// Utilizo un nuevo PIN para validar, debo guardarlo ya que es correcto
			if (aPin != NULL) {
				strcpy(myPin, aPin);
				[self storePin];
			}

			return SimCardStatus_READY;
		}
		else return SimCardStatus_PIN_REQUIRED;

	}
	
	//doLog(0,"PIN READY RESPONSE = |%s|\n", response);
	//[self readResponse: response timeout: COMMAND_TIMEOUT];

	return SimCardStatus_FAILURE;
}

/**/
- (BOOL) changeSimCardPin: (char *) anOldPin newPin: (char *) aNewPin
{
	char request[100];
	char response[100];

	// Envio el PIN

	//at+cpwd="sc","old password","new password"
	sprintf(request, "AT+CPWD=\"SC\",\"%s\",\"%s\"\x0D", anOldPin, aNewPin);
	[self writeCommand: request]; 
	[self readResponse: response timeout: COMMAND_TIMEOUT];

	if (strstr(response, "OK") != NULL) {
		strcpy(myPin, aNewPin);
		[self storePin];
		return TRUE;
	}

	return FALSE;
}

/**/
- (BOOL) lockSimCard: (BOOL) aLock pin: (char *) aPin
{
	char request[100];
	char response[100];

	// Envio el PIN
	sprintf(request, "AT+CLCK=\"SC\",%d,\"%s\"\x0D", aLock, aPin);
	[self writeCommand: request]; 
	[self readResponse: response timeout: COMMAND_TIMEOUT];

	if (strstr(response, "OK") != NULL) {
		myIsSimCardLocked = aLock;
		return TRUE;
	}
	return FALSE;
}

/**/
- (BOOL) isSimCardLocked
{
	return myIsSimCardLocked;
}

@end
