#include "cl_genericpkg.h"
#include <stdio.h> 
#include <strings.h>
#include <stdlib.h>
#include "TelesupExcepts.h"
#include "SystemTime.h"

/*
 GenericPackage
   
   v 0.11.2
  
  Note:
	After AddParamAs... must call "readEntities"
*/

@implementation GenericPackage


+ new
{
	return [[super new] initialize];
}

- initialize
{
	myName = malloc(MSGLINE_SIZE+1);
	myMessageLine = malloc(MSGLINE_SIZE+1);
	paramValueBuffer = malloc(MSGLINE_SIZE + 1);
	paramNameBuffer = malloc(MSGLINE_SIZE + 1);
	myTokenBuffer = malloc(MSGLINE_SIZE + 1);
	myEntityTokenBuffer = malloc(MSG_SIZE + 1);
	
	rt = malloc(MSG_SIZE + 1);
	myMessage = malloc(MSG_SIZE + 1);
	
	myTokenizer = [StringTokenizer new];
	[myTokenizer  setTrimMode: TRIM_NONE];
	[myTokenizer  setDelimiter: "\x0A"];	
	
	myEntityTokenizer = [StringTokenizer new];
	[myEntityTokenizer  setTrimMode: TRIM_NONE];
	[myEntityTokenizer  setDelimiter: ENDENTITY_WITHENDLINE_LABEL];	
	myMessage[0] = '\0';
	myName[0] = '\0';
	
	return self;
}

- (void) clear
{
	myMessage[0] = '\0';
	strcpy(myName, "");
	strcpy(myMessageLine, "");
	strcpy(paramValueBuffer, "");
	strcpy(paramNameBuffer, "");
	strcpy(myTokenBuffer, "");
	strcpy(myEntityTokenBuffer, "");
}

/* Entity */
- (void) addEntity
{
  sprintf(myMessageLine, "%s\x0A", ENTITY_LABEL);	
  strcat(myMessage, myMessageLine);	
}

- (void) addEndEntity
{
  sprintf(myMessageLine, "%s\x0A", ENDENTITY_LABEL);	
  strcat(myMessage, myMessageLine);	
}

/* String */
- (void) addParamAsString: (char*) pname value: (char *) aValue
{
	sprintf(myMessageLine, "%s=%s\x0A", pname, aValue);
	strcat(myMessage, myMessageLine);
}


/* Integer */
- (void) addParamAsInteger: (char*) pname value: (int) aValue
{
	
	sprintf(myMessageLine, "%s=%d\x0A", pname, aValue);
	strcat(myMessage, myMessageLine);
}

/* Float */
- (void) addParamAsFloat: (char*) pname value: (float) aValue
{	
	sprintf(myMessageLine, "%s=%.6f\x0A", pname, aValue);
	strcat(myMessage, myMessageLine);
}

/* Boolean */
- (void) addParamAsBoolean: (char*) pname value: (BOOL) aValue
{	
	sprintf(myMessageLine, "%s=%s\x0A", pname, aValue == TRUE ? "True" : "False");
	strcat(myMessage, myMessageLine);
}

/**/
- (void) addParamsFromMap: (MAP) aMap
{
	int count = [aMap getItemCount];
	char *itemName;
	int i;

	for (i = 0; i < count; i++) {
		itemName = [aMap getItemNameAt: i];
		[self addParamAsString: itemName value: [aMap getParamAsString: itemName]];
	}
}

- (BOOL) isEqualsParamName: (char *) aBuffer to: (char *) aParamName
{
	char *p;	
	int len;

	/* seek '=' and return the pointer */
	//p = index(aBuffer, '=');
	p = strchr(aBuffer, '=');
	if (p == NULL)
		return FALSE;
	
	len = p - aBuffer;
//	doLog("len = %d, aParamName = |%s|, aBuffer = |%s|\n, result = %d\n", len, aParamName, aBuffer, strncasecmp(aBuffer, aParamName,len) == 0 && (len == strlen(aParamName)));fflush(stdout);
	return strncasecmp(aBuffer, aParamName,len) == 0 && (len == strlen(aParamName));	
}

/* GetInteger */
- (int) getParamAsInteger: (char *) pname
{
	char *p = [self getParamAsString: pname]; 
	
	if (!p) THROW_MSG( TSUP_PARAM_NOT_FOUND_EX, pname );
	return atoi( p );
}

/* GetFloat */
- (float) getParamAsFloat: (char *) pname
{
	char *p = [self getParamAsString: pname]; 
	
	if (!p) THROW_MSG( TSUP_PARAM_NOT_FOUND_EX, pname );
	return atof( p );
}

/* GetCurrency */
- (money_t) getParamAsCurrency: (char *) pname
{
	char *p = [self getParamAsString: pname]; 

	if (!p) THROW_MSG( TSUP_PARAM_NOT_FOUND_EX, pname );
	return stringToMoney(p);
}

/* GetBoolean */
- (BOOL) getParamAsBoolean: (char *) pname
{
	char *p;
	
	p = [self getParamAsString: pname];	
	if (!p) THROW_MSG( TSUP_PARAM_NOT_FOUND_EX, pname );

	return strcasecmp(p, "True") == 0;	
}

/* Datetime */
- (datetime_t) getParamAsDateTime: (char *) pname
{
	/*
	 *	Formato (siempre en hora UTC): 	 2004-10-18T12:53:21
 	 *			 				2004-10-18T12:53:21
	 */
	char *p;
	
	if (!(p = [self getParamAsString: pname]))
	if (!p) THROW_MSG( TSUP_PARAM_NOT_FOUND_EX, pname );

	return ISO8106ToDatetime(p);;
}


- (void) addParamAsDateTime: (char *) pname value: (datetime_t) aValue
{
	char buf[40];	
	snprintf(myMessageLine, 39, "%s=%s\x0A", pname, datetimeToISO8106(buf, aValue));
	strcat(myMessage, myMessageLine);
};


- (void) readToken
{
	[myEntityTokenizer getNextToken: myEntityTokenBuffer];
	
	/* read parameters */
	[self readParameters];
}


- (char *) getEntity
{
	return myEntityTokenBuffer;
}


- (char *) firstEntity
{
	[myEntityTokenizer restart];
	
	if ( [myEntityTokenizer hasMoreTokens] ) {
		[self readToken];
		return myEntityTokenBuffer;
	}
	
	return NULL;
}


- (char *) nextEntity
{
	if ( [myEntityTokenizer hasMoreTokens] ) {
		[self readToken];
		return myEntityTokenBuffer;
	}
	
	return NULL;
}
		
- (void) readEntities
{
	[myEntityTokenizer setText: (char *)myMessage];

	/**/
/*	if (![myTokenizer hasMoreTokens])
		THROW( TSUP_PARAM_NOT_FOUND_EX ); */
	
	if ( [myEntityTokenizer hasMoreTokens] ) {
		[self readToken];		
		}
		
}

/**/
- (void) readParameters
{
	[myTokenizer setText: (char *)myEntityTokenBuffer];	
}

/**/
- (BOOL) isValidParam: (char *) pname
{
	[myTokenizer restart];
	
  while ( [myTokenizer hasMoreTokens] ) {
		[myTokenizer getNextToken: myTokenBuffer];
				
		if ([self isEqualsParamName: myTokenBuffer to: pname])
		  return TRUE;	
	}
	
	return FALSE;
}
		
- (char *) getParamAsString: (char *) pname
{
	sprintf(paramNameBuffer,"%s",pname);
	[myTokenizer restart];
	
	/**/
/*	if (![myTokenizer hasMoreTokens])
		THROW( TSUP_PARAM_NOT_FOUND_EX ); */

	while ( [myTokenizer hasMoreTokens] ) {
		[myTokenizer getNextToken: myTokenBuffer];
		
		/* if detect EndEntity, stop scanning */
		if (strcasecmp(myTokenBuffer, ENDENTITY_LABEL)==0) break;
		
		if ([self isEqualsParamName: myTokenBuffer to: paramNameBuffer]) {
			sprintf(paramValueBuffer,"%s", strchr(myTokenBuffer, '=') + 1);
			return paramValueBuffer;
			}
	}
	
	THROW_MSG( TSUP_PARAM_NOT_FOUND_EX, pname );
	return NULL;
}

- (char *) toString
{
	//rt = malloc(strlen(MSG_HEADER) + strlen(myName) + strlen(myMessage) + strlen(MSG_FOOT)+5);
	
	sprintf(rt, "%s%s\x0A%s%s",MSG_HEADER ,myName,myMessage,MSG_FOOT);
	return rt;
}

- (char *) toStringWithoutHeaders
{
	//rt = malloc(strlen(myName) + strlen(myMessage) +5);
	
	sprintf(rt, "%s\x0A%s",myName,myMessage);
	return rt;
}


/* loadPackage:
   Load package from string. Separate name and body 
*/
- (void) loadPackage: (char *) aValue
{
	char *ca;
	char *cn;

	[self clear];
	[myTokenizer setText: ""];

	ca = aValue + strlen(MSG_HEADER);

	cn = strstr(ca, "\x0A"); /* Name pointer */
	sprintf(myName,"%s", strtok(ca,"\x0A"));	
	
	/* Message body */
	ca = strstr(cn+1, MSG_FOOT);	
	memcpy(myMessage, cn+1, ca - (cn+1));
	myMessage[ca - (cn+1)] = '\0';
		
	[self readEntities]; /* update parameters */
	
}

/* Message */
- (void) setMessage: (char *) aValue
{
	sprintf(myMessage, "%s", aValue);
}

/* Check buffer package format */
- (int) isPackage: (char *) aValue
{
	return (strstr(aValue,MSG_HEADER) != NULL) && (strstr(aValue,MSG_FOOT) != NULL);
}

/* Name */
- (char *) getName
{
	return myName;
}

- (void) setName: (char *) aValue
{
	sprintf(myName, "%s", aValue);
}

- free
{
	free(rt);
	free(myName);
	free(myMessageLine);
	free(paramValueBuffer);
	free(paramNameBuffer);
	free(myTokenBuffer);
	free(myEntityTokenBuffer);	
	free(myMessage);
	
	[myTokenizer free];
	[myEntityTokenizer free];
	return [super free];
}
@end
