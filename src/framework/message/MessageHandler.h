#ifndef MESSAGE_HANDLER_H
#define MESSAGE_HANDLER_H

#define MESSAGE_HANDLER id

#include <Object.h>	
#include "ctapp.h"
#include "ResourceStringDefs.h"

/**
 * Cantidad de mensajes
 */
#define MSG_QUANTITY 1840
#define MAX_LANGUAGES   3

/**/
char *getResourceString(int messageNumber);
char *formatResourceStringDef(char *buffer, int messageNumber, char *defaultString, ...);
char *formatResourceString(char *buffer, int messageNumber, ...);
char *getResourceStringDef(int messageNumber, char *defaultString);

char *getExceptionDescription(int exceptionNumber, char *exceptionName, char *buf);
char *getCurrentExceptionDescription(char *buf);

typedef struct message MESSAGES;
struct message {
	int messageId;
	char* messageDsc;
};

/**
 * SINGLETON
 * Clase que maneja los mensajes del sistema, para poder contemplar multiidioma. 	
 */

@interface MessageHandler : Object
{
	LanguageType myCurrentLanguage; //Lenguaje actual
	int myMessageCount[MAX_LANGUAGES];
	MESSAGES *myMessages[MAX_LANGUAGES];
}

/**
* Crea una instancia de la clase MessageHandler.
*/

+ new;

/**
* Toma una instancia unica, ya que se trata de una clase singleton.
*/

+ getInstance;

/**
 *
 */
- initialize;

/**
* Setea el lenguaje actual.
*/

- (void) setCurrentLanguage: (LanguageType) aLanguage;

/**/
+ newWithDefaultLanguage: (int) aLanguage;

/**
* Retorna el lenguaje actual.
*/

- (LanguageType) getCurrentLanguage;


/**
* Procesa el mensaje deseado, devolviendo el mismo formateado.
*	@param result variable de tipo char * en el cual tambien se almacenara el resultado.
*	@param messageNumber numero de mensaje que se desea procesar. Este parametro es de tipo 
* MessageType.
* En el caso que el mensaje a procesar contega adicionales tales como %s, %d, etc, en la parte donde 
* encuentran los 3 puntos (...) se deben pasar todos los valores que se desean que reemplacen en dichos
* lugares.
*	@return la cadena formateada, lista para ser visualizada.
*/

- (char*) processMessage: (char*) result messageNumber: (int) aMessageNumber, ...; 

/**
* Busca el mensaje pasado como parametro en la lista total de mensajes.
*/

- (char*) searchMessage: (char*) aMessage messageNumber: (int) aMessageNumber;

/**
* Busca el mensaje pasado como parametro en la lista total de mensajes.
*/
- (char*) getMessage: (int) aMessageNumber;

@end

#endif
