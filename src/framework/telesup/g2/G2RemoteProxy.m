#include <string.h>
#include <ctype.h>
#include "system/util/all.h"
#include "G2TelesupDefs.h"
#include "G2RemoteProxy.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

//#define LOG(args...) doLog(0,args)
//#define LOG(args...) logCategory("LOG_PTSD", FALSE, args)

/* Imprime el mensaje recibido en un formato agradable  */ 

/*
static
void
printmsg(char *tittle, char *msg)
{
	char pbuf[TELESUP_MSG_SIZE];
	
	// Se define un buffer auxiliar para no modificar el mensaje recibido
	strcpy(pbuf, msg);
	// reemplaza los "\n" por ' ' para poder imprimir en una sola linea el mensaje
	strrep(pbuf, '\n', ' ');

	printd("%s \"%s\"\n", tittle, pbuf);
}
*/

/**/
@implementation G2RemoteProxy


/**/
+ new
{
	printd("G2RemoteProxy - new\n");
	return [super new];
}

/**/
- initialize
{
	[super initialize];

	/**/
	myMessage = malloc(TELESUP_MSG_SIZE + 1);
	assert(myMessage);

	myAuxMessage = malloc(TELESUP_MSG_SIZE + 1);
  myMessageLine = malloc(TELESUP_RESPONSE_MSGLINE_SIZE + 1);
	myToken = malloc(TELESUP_RESPONSE_MSGLINE_SIZE + 1);
	assert(myAuxMessage);
	
	myTelesupRol = 0;	
	mySystemId[0] = '\0';
				
	/**/
	myTokenizer = [StringTokenizer new];
	[myTokenizer  setTrimMode: TRIM_NONE];
	[myTokenizer  setDelimiter: "\012"];
	
	/**/	
	myFileTransfer = [DFileTransferProtocol new];	

		
	return self;
}

/**/
- free
{ 
  free(myMessageLine);
  free(myToken);

	free(myMessage);
	free(myAuxMessage);

	[myFileTransfer free];
	[myTokenizer free];

	return [super free];
}

/**/
- (void) newMessage: (const char *) aMessageName
{
	sprintf(myMessage, G2_TELESUP_MESSAGE_HEADER_PLUS_ENTER "%s\012", aMessageName);
}


/**/
- (void) newResponseMessage
{	
	strcpy(myMessage, G2_TELESUP_MESSAGE_HEADER_PLUS_ENTER "OK\012");
	[self appendTimestamp];
}

/**/
- (void) newResponseMessageWithoutDateTime
{
	strcpy(myMessage, G2_TELESUP_MESSAGE_HEADER_PLUS_ENTER "OK\012");
}

/**/
- (void) sendMessage: (char*) aBuffer qty: (int) aQty
{
	[myWriter write: aBuffer qty: aQty];		
}

/**
 * Este metodo se utiliza para enviar el message por bloques sin incluir al final el End
 * Esto se utiliza para evitar que se supere el tamanio maximo del buffer
 */
- (void) sendMessagePart
{	
	int size;
	
	myPartitionMessage = TRUE;

	/**/
	size = [self encodeTelesupMessage: myAuxMessage from: myMessage size: strlen(myMessage)];
		
	/*doLog(0,"G2RemoteProxy:Message Send (%d)  --------------------------\n"
			"%s\n "
			"-----------------------------------------------------------\n", strlen(myAuxMessage), myAuxMessage);
*/
	/**/
	[myWriter write: myAuxMessage qty: size];
}

/**/
- (void) sendMessage
{	
	int size;
	char msgName[50];

	/**/
	strcat(myMessage, "End\012");
	
	/**/
	size = [self encodeTelesupMessage: myAuxMessage from: myMessage size: strlen(myMessage)];
		
	/**/
	if (size > TELESUP_MSG_SIZE)
		THROW( TSUP_MSG_TOO_LARGE_EX );
		
	/*doLog(0,"G2RemoteProxy:Message Send (%d)  --------------------------\n"
			"%s\n "
			"-----------------------------------------------------------\n", strlen(myAuxMessage), myAuxMessage);
*/
	if (!myPartitionMessage) {
        stringcpy(msgName, [self getRequestName: myAuxMessage requestName: msgName]);

		/*if (strcmp(msgName,"OK") != 0)
			doLog(0,"G2RemoteProxy:Send (%d): %s\n", strlen(myAuxMessage), msgName);*/
	}

	myPartitionMessage = FALSE;

	/**/
    printf("message = %s \n", myAuxMessage);
	[myWriter write: myAuxMessage qty: size];	
}

/**/
- (void) sendAckMessage
{
	strcpy(myMessage, G2_TELESUP_MESSAGE_HEADER_PLUS_ENTER "OK\012");
	[self appendTimestamp];
	[self sendMessage];
}

/**/
- (void) sendAckWithTimestampMessage
{
	strcpy(myMessage, G2_TELESUP_MESSAGE_HEADER_PLUS_ENTER "OK\012");
	[self appendTimestamp];
	[self sendMessage];
}

/**/
- (void) sendAckDataFileMessage
{
	strcpy(myMessage, G2_TELESUP_MESSAGE_HEADER_PLUS_ENTER "OK\012");
	[self appendTimestamp];
	[self sendMessage];
}


/**/
- (void) sendErrorRequestMessage: (int) aCode description: (char *) aDescription
{
	if (aCode == 0)
		strcpy(myMessage, G2_TELESUP_MESSAGE_HEADER_PLUS_ENTER "Error\012");
	else
		sprintf(myMessage, G2_TELESUP_MESSAGE_HEADER_PLUS_ENTER "Error\012Code=%d\012Description=%s\012", aCode, aDescription);

	[self appendTimestamp];
	[self sendMessage];
}

/**/
- (void) addLine: (char *) aLine
{
	sprintf(myMessageLine, "%s\012", aLine);
	strcat(myMessage, myMessageLine);

	// este control se hace para enviar por bloques sin que el buffer se desborde
	if (strcmp(aLine, END_ENTITY) == 0) {
		if (strlen(myMessage) >= (TELESUP_MSG_SIZE - 2000)) { // se le resta 2000 bytes para dejar un margen de espacio sin que se desborde el buffer
			//doLog(0,"enviando bloque **************************************\n");
			[self sendMessagePart];
			//doLog(0,"se mando un bloque ***********************************\n");

			myMessage[0] = '\0';
		}
	}
}


/**/
- (void) addParamAsString: (char *) aParamName value: (char *) aValue
{
	sprintf(myMessageLine, "%s=%s\012", aParamName, aValue);
	strcat(myMessage, myMessageLine);
}

/**/
- (void) addParamAsDateTime: (char *) aParamName value: (datetime_t) aValue
{
	char buf[] = "0000:00:00T00:00:00+00:00\0\0";	
	sprintf(myMessageLine, "%s=%s\012", aParamName, datetimeToISO8106(buf, aValue));
	strcat(myMessage, myMessageLine);
}


/**/
- (void) addParamAsInteger: (char *) aParamName value: (int) aValue
{
	sprintf(myMessageLine, "%s=%d\012", aParamName, aValue);
	strcat(myMessage, myMessageLine);

}

/**/
- (void) addParamAsLong: (char *) aParamName value: (long) aValue
{
	sprintf(myMessageLine, "%s=%ld\012", aParamName, aValue);
	strcat(myMessage, myMessageLine);

}

/**/
- (void) addParamAsFloat: (char *) aParamName value: (float) aValue
{
	sprintf(myMessageLine, "%s=%.6f\012", aParamName, (double)aValue);
	strcat(myMessage, myMessageLine);

}

/**/
- (void) addParamAsCurrency: (char *) aParamName value: (money_t) aValue decimals: (int) aDecimals
{
	char amountstr[50];
	sprintf(myMessageLine, "%s=%s\012", aParamName, formatMoney(amountstr, "", aValue, aDecimals, 50));
	strcat(myMessage, myMessageLine);	
}

/**/
- (void) addParamAsCurrency: (char *) aParamName value: (money_t) aValue
{
	[self addParamAsCurrency: aParamName value: aValue decimals: 6];
}

/**/
- (void) addParamAsBoolean: (char *) aParamName value: (BOOL) aValue
{
	sprintf(myMessageLine, "%s=%s\012", aParamName, aValue == TRUE ? "True" : "False");
	strcat(myMessage, myMessageLine);
}


/* Transferecnia de informacion */

- (void) sendFile: (char *)aSourceFileName targetFileName: (char *) aTargetFileName
					appendMode: (BOOL) anAppendMode

{	
	anAppendMode = anAppendMode;

	[self configureFileTransfer: myFileTransfer];
	
	[myFileTransfer setSourceFileName: aSourceFileName];
	[myFileTransfer setTargetFileName: aTargetFileName];
	
	[myFileTransfer uploadFile];	
}

/**/
- (char *) receiveFile: (char *)aSourceFileName targetFileName: (char *) aTargetFileName
{	
	[self configureFileTransfer: myFileTransfer];
	
	/*[myFileTransfer setStrictSourceFileName: aSourceFileName != NULL];
	if (aSourceFileName == NULL) 
		[myFileTransfer setSourceFileName: aSourceFileName];
	*/	
	[myFileTransfer setStrictSourceFileName:0];
	[myFileTransfer setSourceFileName: aSourceFileName];	
	
	[myFileTransfer setTargetFileName: aTargetFileName];		
		
	[myFileTransfer downloadFile];
	
	return [myFileTransfer getSourceFileName];
}

/**/
- (BOOL) isRequestComplete: (char *)aBuffer
{	
	int i = strlen(aBuffer);
	char *p = aBuffer + strlen(aBuffer) - 1;

	/* se posiciona en el ultimo caracter que no sea ' ' o '\n' */
	while (--i) { 
		//if (!isspace(*p))
		if (*p != '\012' && *p != ' ')
			break;
		p--;
	}

	/* Por lo menos mas de 4 "...End\n" */
	if (i < 5) return FALSE;

	/* Se fija si hay un "\nEnd"\n" */
	if (*(p + 1) == '\012' && tolower(*(p + 0)) == 'd' && 
		tolower(*(p - 1)) == 'n' && tolower(*(p - 2)) == 'e' && *(p - 3) == '\012')
		return TRUE; 
	
	return FALSE;
}

/**/
- (BOOL) isLogoutTelesupMessage: (char *) aMessage
{
	return strcasecmp(aMessage, G2_TELESUP_MESSAGE_HEADER_PLUS_ENTER "Logout\012End\012") == 0;	 
}

/**/
- (BOOL) isLoginTelesupMessage: (char *) aMessage
{
	return strncasecmp(aMessage, G2_TELESUP_MESSAGE_HEADER_PLUS_ENTER "Login\012", 
											strlen(G2_TELESUP_MESSAGE_HEADER_PLUS_ENTER "Login\012")) == 0; 
}

/**/
- (BOOL) isOkMessage: (char *) aMessage
{
	return strcasecmp(aMessage, G2_TELESUP_MESSAGE_HEADER_PLUS_ENTER "OK\012End\012") == 0;
}

/**/
- (int) readTelesupMessage: (char *) aBuffer qty: (int) aQty
{	
	int size;
	char *p = myAuxMessage;
	char msgName[200];
	
	assert(aBuffer);
	assert(myReader);
	
	memset(myAuxMessage, '\0', aQty);
		
	while (1) {
		
		size = [myReader read: p qty: aQty - (p - myAuxMessage)];		
		if (size <= 0) 
			THROW( TSUP_GENERAL_EX );

		p += size;
		
		/* Si recibe un mensaje demasiado largo lanza una excepcion.
		  No deberia pasar esta situacion.*/
		if (p - myAuxMessage > aQty) THROW( TSUP_MSG_TOO_LARGE_EX );

		*p = '\0';

		/* Debe haber un "\nEnd\n" para definir un mensaje.
		   Si no llega vuelve a leer mas */
       
       			   
		if ([self isRequestComplete: myAuxMessage])    
			break;
	}	
		
//	printmsg("G2RemoteProxy:Mensaje: ", myAuxMessage);
//	LOG("G2RemoteProxy:Message Receive (%d)  ----------------------\n"
//			"%s\n "
//			"-----------------------------------------------------------\n", strlen(myAuxMessage), myAuxMessage);

    stringcpy(msgName, [self getRequestName: myAuxMessage requestName: msgName]);
	//doLog(0, "G2RemoteProxy:Receive (%d): %s\n", strlen(myAuxMessage), msgName);
	
	/* Formatea adecuadamente el mensaje desde el parser */
	return [self decodeTelesupMessage: aBuffer from: myAuxMessage size: p - myAuxMessage];
}


/**/
- (int) decodeTelesupMessage: (char *) aTargetBuffer from: (char *) aSourceBuffer size: (int) aSize
{
	char *p, *s;
	char *target, *source;

	assert(myTokenizer);
	assert(aTargetBuffer);
	assert(aSourceBuffer);
	
	[myTokenizer setText: aSourceBuffer];

	target = aTargetBuffer;
			
	/* Copia linea a linea */
	while ([myTokenizer hasMoreTokens]) {
		
		/**/	
		[myTokenizer getNextToken: myToken];
		
		source = myToken;

		/* saca espacios a izquierda */
		s = ltrim(source);
				
		/*Si es un '\n' pasa a la linea siguiente */
		if (*s == '\0' || *s == '\012')
			continue;
			
		/* decodifica la linea actual */
		/* 
		*  Si en la linea no hay un igual es que no es linea de "parametro=valor" por lo
		*  que se sacan los espacios en blanco iniciales y finales.
		*  Puede ser el nombre del mensaje, la cadena "End", el modificador "All".			
		*/
		p = index(source, '=');
		if (p == NULL) {
			
			/* saca espacios iniciales y finales */
			s = trim(source);
			
			/* copia los datos crudos */
			while (*s)
				*target++ = *s++;			
			
		} else {
			
			/* copia datos hasta el '=' o hasta el primer blanco */
			while (*s != '=' && !isblankchar(*s) )
				*target++ = *s++;
			
			/* saltea los blancos hasta el '='  */	
			while (*s && isblankchar(*s))
				s++;
			
			/* El formato del request es invalido */
			if (*s != '=')
				THROW( TSUP_INVALID_REQUEST_EX );	
			
			/* copia el '=' */
			*target++ = *s++;
				
			/* copia los datos del value de la linea param=value decodificando los \\xx */
			while (*s) {
				
				/* Se convierten la cadena "\0A" en el caracter no imprimible "\n" por ejemplo */
				if (*s == '\\') {
					
					s++;
					if (*s == '\0')
						break;
						
					/* La barra invertida '\' se escapa tambien */
					if (*s++ == '\\') 
						*target++ = '\\';
					else /* un ASCII no imprimible que viene en hexa */
						*target++ = [self convertG2HexaCodeToInteger: s];
				
				} else {
					*target++ = *s++;
				}
			}
		}
			
		/* Agrega el '\n' final */
		*target++ = '\012';
		
		/* El tamaño del mensaje */		
		if (target - aTargetBuffer > TELESUP_MSG_SIZE)
			THROW( TSUP_MSG_TOO_LARGE_EX );		
	}
	
	*target = '\0';
		
	return target - aTargetBuffer;
}

/**/
- (int) encodeTelesupMessage: (unsigned char *) aTargetBuffer from: (unsigned char *) aSourceBuffer size: (int) aSize
{
	unsigned char *s;
	unsigned char *target;

	assert(myTokenizer);
	assert(aTargetBuffer);
	assert(aSourceBuffer);

	/**/
	target = aTargetBuffer;
	[myTokenizer setText: aSourceBuffer];

	/* Copia linea a linea */
	while ([myTokenizer hasMoreTokens]) {
	
		/**/	
		[myTokenizer getNextToken: myToken];
	
		/* saca espacios a izquierda */
		s = ltrim(myToken);
				
		/*Si es un '\n' pasa a la linea siguiente */
		if (*s == '\0' || *s == '\012')
			continue;
			
		/* encodifica la linea actual */
		while (*s) {
		
			if (*s < ' ') {
			
				*target++ = '\\';
				snprintf(target, 2, "%02x", *s++);
				target += 2;
			
			} else
				*target++ = *s++;
		}
		
		/* Agrega el '\n' final */
		*target++ = '\012';
		
		/* El tamaño del mensaje */		
		if (target - aTargetBuffer > TELESUP_MSG_SIZE)
			THROW( TSUP_MSG_TOO_LARGE_EX );
		
	}

	*target = '\0';
	return target - aTargetBuffer;
}


/**/
- (int) convertG2HexaCodeToInteger: (char *) aString
{
	char s[5];
	char *sp = &s[0];
		
	assert(aString);
	
	*sp = '\0';
	if (aString[0] != '\0' && isxdigit(aString[0]))
		*sp++ = aString[0];
	else		
		return 0;
		
	if (aString[1] != '\0' && isxdigit(aString[1]))
		*sp++ = aString[1];
	
	*sp = '\0';
	
	return atoi(s);
}


/**  Por razones de testing con el frontal los mensajes pueden venir con la palabra
 *  "Message" como inicio de mensaje o puede que venga directamente en la primer linea
 *  el nombre del mensjae (esto se define en tiempo de compilacion).
 */
- (char *) getRequestName: (char *) aMessage requestName: (char*) aRequestName
{
	STRING_TOKENIZER tokenizer;
	char tokenBuffer[1025];
	char paramNameBuffer[1025];

	tokenizer = [StringTokenizer new];
	[tokenizer  setTrimMode: TRIM_NONE];
	[tokenizer  setDelimiter: "\012"];

	/* La cadena viene sin espacios inciales */
	[tokenizer setText: (char *) aMessage];

	/**/
	if (![tokenizer hasMoreTokens])
		THROW( TSUP_INVALID_REQUEST_EX );
		
	/* La primera linea: el inicio de mensaje "Message\n" */
	
	/* El if porque agregamos y sacamos "Message" de los mensajes para testear */
	if (strlen(G2_TELESUP_MESSAGE_HEADER) > 0) {		
		[tokenizer getNextToken: tokenBuffer];
		if (strcasecmp(tokenBuffer, G2_TELESUP_MESSAGE_HEADER) != 0) {
		//	doLog(0,"MSG = |%s|\n", tokenBuffer);
			THROW( TSUP_INVALID_REQUEST_EX );
		}
	}
	
	/**/
	if (![tokenizer hasMoreTokens])
		THROW( TSUP_INVALID_REQUEST_EX );
	
	/* La segunda linea: el nombre del mensaje "MessageName\n" */			
	[tokenizer getNextToken: tokenBuffer];
	
	/* si el nombre es demasiado largo ... */	
	if (strlen(tokenBuffer) > TELESUP_REQUEST_NAME_SIZE  ) 
		THROW(TSUP_NAME_TOO_LARGE_EX);

	/* Copia el nombre del Request */
	stringcpy(paramNameBuffer, tokenBuffer);

	[tokenizer free];
    
    stringcpy(aRequestName, paramNameBuffer);
    
	return aRequestName;	    

}
	
@end
