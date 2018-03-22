#include <objpak.h>
#include "ctapp.h"
#include "MessageHandler.h"
#include "StringTokenizer.h"
#include "stdlib.h"
#include "string.h"
#include "config.h"
#include "MessageExcepts.h"
#include "RegionalSettings.h"
#include "CtSystem.h"
#include "system/util/all.h"

#define MAXLINE 512

char *replace(char *string, char *oldpiece, char *newpiece) {

   int str_index, newstr_index, oldpiece_index, end,

      new_len, old_len, cpy_len;
   char *c;
   static char newstring[MAXLINE];

   if ((c = (char *) strstr(string, oldpiece)) == NULL)

      return string;

   new_len        = strlen(newpiece);
   old_len        = strlen(oldpiece);
   end            = strlen(string)   - old_len;
   oldpiece_index = c - string;


   newstr_index = 0;
   str_index = 0;
   while(str_index <= end && c != NULL)
   {

      /* Copy characters from the left of matched pattern occurence */
      cpy_len = oldpiece_index-str_index;
      strncpy(newstring+newstr_index, string+str_index, cpy_len);
      newstr_index += cpy_len;
      str_index    += cpy_len;

      /* Copy replacement characters instead of matched pattern */
      strcpy(newstring+newstr_index, newpiece);
      newstr_index += new_len;
      str_index    += old_len;

      /* Check for another pattern match */
      if((c = (char *) strstr(string+str_index, oldpiece)) != NULL)
         oldpiece_index = c - string;


   }
   /* Copy remaining characters from the right of last matched pattern */    strcpy(newstring+newstr_index, string+str_index);

   return newstring;
}

static char errorMessage[512];

char *getExceptionDescription(int exceptionNumber, char *exceptionName, char *buf)
{
  char exname[200];
  stringcpy(exname, exceptionName);
	TRY
		[[MessageHandler getInstance] processMessage: buf
									 								 messageNumber: exceptionNumber];
	CATCH
		snprintf(buf, 60, "Exception: %d! %s", exceptionNumber, exname);
		//doLog(0,"Mensaje no encontrado  = !%s!\n", buf);
	END_TRY

  return buf;
}

/**/
char *getCurrentExceptionDescription(char *buf)
{
  return getExceptionDescription(ex_get_code(), ex_get_name(), buf);
}

/**/
char *getResourceString(int messageNumber)
{
  char *result = NULL;
  TRY
    result = [[MessageHandler getInstance] getMessage: messageNumber];
  CATCH
  //  doLog(0,"Error: No se encuentra el ID de mensaje %d\n", messageNumber);
    sprintf(errorMessage, "RES_ID: %d", messageNumber);
    return errorMessage;
  END_TRY
  return result;
}

/**/
char *getResourceStringDef(int messageNumber, char *defaultString)
{
  char *result = NULL;
  TRY
    result = [[MessageHandler getInstance] getMessage: messageNumber];
  CATCH
		return defaultString;
  END_TRY
  return result;
}

/**/
char *formatResourceString(char *buffer, int messageNumber, ...)
{
	OC_VA_LIST ap;
	char myMessage[500];

	[[MessageHandler getInstance] searchMessage: myMessage messageNumber: messageNumber];
	
	OC_VA_START(ap, messageNumber);
	vsprintf(buffer, myMessage, ap);
	OC_VA_END(ap);

	return buffer;
}

/**/
char *formatResourceStringDef(char *buffer, int messageNumber, char *defaultString, ...)
{
	OC_VA_LIST ap;
	char myMessage[500];

	TRY
		[[MessageHandler getInstance] searchMessage: myMessage messageNumber: messageNumber];
	CATCH
		strcpy(myMessage, defaultString);
	END_TRY
	
	OC_VA_START(ap, defaultString);
	vsprintf(buffer, myMessage, ap);
	OC_VA_END(ap);

	return buffer;
}

@implementation MessageHandler

static MESSAGE_HANDLER singleInstance = NULL;
- (void) loadFile: (char *) aFileName language: (LanguageType) aLanguageType;

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [[super new] initialize];
	return singleInstance;
}

/**/
+ getInstance
{
	return [self new];	
}

/**/
- (id) initializeWithLanguage: (int) aLanguage
{
	int i;
  myCurrentLanguage = aLanguage;
	for (i = 0; i < MAX_LANGUAGES; ++i) {
		myMessages[i] = malloc(sizeof(MESSAGES) * MSG_QUANTITY);
		assert(myMessages[i]);
	}

	//doLog(0,"myCurrentLanguage = %d\n", myCurrentLanguage);
	
  [self loadFile: "msg-SPAN.ini" language: SPANISH];
  [self loadFile: "msg-ENG.ini" language: ENGLISH];
	[self loadFile: "msg-FRAN.ini" language: FRENCH];

	return self;
}

/**/
+ newWithDefaultLanguage: (int) aLanguage
{
	if (singleInstance) return singleInstance;
	singleInstance = [[super new] initializeWithLanguage: aLanguage];
	return singleInstance;
}

/**/
- initialize
{
  myCurrentLanguage = [[RegionalSettings getInstance] getLanguage];
  
	return [self initializeWithLanguage: myCurrentLanguage];
}

/**/
- (void) setCurrentLanguage: (LanguageType) aLanguage { myCurrentLanguage = aLanguage; }

/**/
- (LanguageType) getCurrentLanguage { return myCurrentLanguage; };

/**/
- (void) loadFile: (char *) aFileName language: (LanguageType) aLanguageType
{
	char buffer[500];
	char tableName[200];
  char *fileBuffer;
  char *p;
	int i;
  char *toIndex;

	strcpy(tableName, [[CtSystem getInstance] getDatabasePath]);
	strcat(tableName, aFileName);
	
//	doLog(0,"Loading language file %s, type = %d\n", tableName, aLanguageType);
printf("Loading language file %s, type = %d\n", tableName, aLanguageType);
  fileBuffer = loadFile(tableName, TRUE);

	i = 0;
	myMessageCount[aLanguageType-1] = 0;
  p = fileBuffer;

	// Carga en memoria todos los mensajes del archivo correspondiente al idioma actual
	while (TRUE) {
		
		if (i >= MSG_QUANTITY) THROW(MESSAGE_MAX_COUNT_EX);

    toIndex = strchr(p, '\n');
   	if (toIndex == NULL) toIndex = p + strlen(p);
    strncpy(buffer, p, toIndex - p);
    buffer[toIndex-p] = '\0';
    if (strlen(buffer) == 0)	break;

    // Ignoro el ultimo enter
    if (buffer[strlen(buffer)-1] == '\r') buffer[strlen(buffer)-1] = '\0';
    if (buffer[strlen(buffer)-1] == '\n') buffer[strlen(buffer)-1] = '\0';

		p = strchr(buffer, '|');
		if (p == NULL) continue;
		*p='\0';
		myMessages[aLanguageType-1][i].messageId = atoi(buffer);
		p++;
		myMessages[aLanguageType-1][i].messageDsc = strdup(p/*replace(token, "\\n", "\n")*/);

		++i;
		myMessageCount[aLanguageType-1]++;
		p = toIndex;
    if (*p == '\n') p++;
	}

  free(fileBuffer);

}


/**/
- (char*) processMessage: (char*) result messageNumber: (int) aMessageNumber, ...
{
	OC_VA_LIST ap;
	char myMessage[500];

	[self searchMessage: myMessage messageNumber: aMessageNumber];
	
	OC_VA_START(ap, aMessageNumber);
	vsprintf(result, myMessage, ap);
	OC_VA_END(ap);

	return result;
}

/**/
int compareMessageId(const void *element1, const void *element2)
{
	struct message *msg1;
	struct message *msg2;

	msg1 = (struct message *)element1;
	msg2 = (struct message *)element2;

	return msg1->messageId - msg2->messageId;
	
}

/**/
- (char*) searchMessage: (char*) aMessage messageNumber: (int) aMessageNumber
{
	struct message *result; 
	struct message key;
	
	key.messageId = aMessageNumber;

	result = bsearch(&key, myMessages[myCurrentLanguage-1], myMessageCount[myCurrentLanguage-1], sizeof(struct message), compareMessageId);

  if (result ) {
		strcpy(aMessage, result->messageDsc);
		return aMessage;
	}

	THROW (MESSAGE_NOT_FOUND_EX);
	return NULL;
}

/**
* Busca el mensaje pasado como parametro en la lista total de mensajes.
*/
- (char*) getMessage: (int) aMessageNumber
{
	struct message *result; 
	struct message key;
	
	key.messageId = aMessageNumber;
		
	result = bsearch(&key, myMessages[myCurrentLanguage-1], myMessageCount[myCurrentLanguage-1], sizeof(struct message), compareMessageId);

  if (result ) {
		return result->messageDsc;
	}

	THROW (MESSAGE_NOT_FOUND_EX);
	return NULL;
}

@end
