#ifndef _GENERICPKG
#define _GENERICPKG
/*-------------------------*/
#include <Object.h>
#include <ctype.h>
#include "system/util/StringTokenizer.h"
#include "system/util/all.h"

#define GENERIC_PACKAGE id
#define	MSG_SIZE			32767
#define	MSGLINE_SIZE 			2048
#define ENTITY_LABEL 			"Entity"
#define ENDENTITY_LABEL 		"EndEntity"
#define ENDENTITY_WITHENDLINE_LABEL 	"EndEntity\x0A"
#define MSG_HEADER                      "Message\x0A"
#define MSG_FOOT                        "End\x0A"

@interface GenericPackage : Object
{

	char *myName;
	char *myMessageLine;
	char *myMessage;
		
	char *myTokenBuffer;
	char *myEntityTokenBuffer;

	char *paramNameBuffer;
	char *paramValueBuffer;
	
	char *rt;
	
	STRING_TOKENIZER myTokenizer;	
	STRING_TOKENIZER myEntityTokenizer;	
}	


- (void) addParamAsString: (char*) pname value: (char *) aValue;
- (void) addParamAsFloat: (char*) pname value: (float) aValue;
- (void) addParamAsInteger: (char*) pname value: (int) aValue;
- (void) addParamAsBoolean: (char*) pname value: (BOOL) aValue;
- (void) addParamAsDateTime: (char *) pname value: (datetime_t) aValue;
- (void) addParamsFromMap: (MAP) aMap;

- (void) clear;

- (void) readParameters;
- (float) getParamAsFloat: (char *) pname;
- (int) getParamAsInteger: (char *) pname;
- (BOOL) getParamAsBoolean: (char *) pname;
- (char *) getParamAsString: (char *) pname;
- (datetime_t) getParamAsDateTime: (char *) pname;

- (BOOL) isEqualsParamName: (char *) aBuffer to: (char *) aParamName;

- (char *) toString;
- (char *) toStringWithoutHeaders;

- (int) isPackage: (char *) aValue;
- (void) loadPackage: (char *) aValue;
- (void) setName: (char *) pname;
- (void) setMessage: (char *) aValue;
- (char *) getName;

  /* Entity */
- (void) addEntity;
- (void) addEndEntity;
- (char *) firstEntity;
- (char *) getEntity;
- (char *) nextEntity;
- (void) readEntities;

/**/
- (BOOL) isValidParam: (char *) pname;
@end
#endif
