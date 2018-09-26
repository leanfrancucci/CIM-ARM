#include "FormatParser.h"
#include "StringTokenizer.h"
#include "util.h"
#include "assert.h"
#include "PrinterExcepts.h"

#define TOKEN_LITERAL 1
#define TOKEN_COMMAND 2
#define MULTIPLE_BEGIN_COMMAND "FOR_EACH"
#define MULTIPLE_END_COMMAND "END_FOR"
#define CONDITION_BEGIN_COMMAND "IF"
#define CONDITION_END_COMMAND "END_IF"

typedef enum {
  IfOperation_EQUAL,
  IfOperation_NOT_EQUAL
} IfOperation;


static id singleInstance = NULL;

char *strdup(const char *s);

@implementation FormatParser

- (scew_element*) getElement: (scew_element*) aRoot path: (char*) aPath;

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

/**/
- initialize
{
	myPrinterDefinition = NULL;
	return self;
}


/**/
- (int) loadFormatFile: (char*) aFormatFileName 
{
	FILE *f;
	int  size;
	char fileName[200];
	
	strcpy(fileName, aFormatFileName);

	f = fopen (fileName, "rt");
	
	if (!f) {
	//	doLog(0,"Archivo de formato %s inexistente\n", fileName);
		return FALSE;
  }
	
	fseek(f, 0, SEEK_END);
	size = ftell(f);
	
	formatFile = malloc( size + 1);
	
	fseek(f, 0, SEEK_SET);
	fread(formatFile, size, 1, f);
	fclose(f);
	
	formatFile[size] = '\0';
	
	return TRUE;
}

/**
 *	Toma el token del input pasado como parametro
 *	@param anInput la entrada de donde tiene que tomar el token
 *	@param anOutput devuelve la salida
 *	@param aFormat
 *	@param tokenType el parametro en el cual devuelve el tipo de token encontrado
 */
- (int) getToken: (char*) anInput output: (char*) anOutput format: (char*) aFormat tokenType: (int*) aTokenType
{
	char *p = anInput;
	int  foundCommand = FALSE;
	int  count = 0;
	char *out = anOutput;
	
	strcpy(anOutput, "");
	strcpy(aFormat, "");
	
	*aTokenType = TOKEN_LITERAL;

	while (*p != '\0') {
		
		// Si encuentro un "@" puede ocurrir alguna de las 3 situaciones:
		//	 - Es el inicio de un comando.
		//   - Es el fin de un comando.
		//   - Es el inicio de un comando, pero ya tenia parseada una cadena, por lo
		//		 tanto, devuelvo esa cadena.
		// Si encuentro un ":" dentro de un comando, debo copiar toda la entrada restante
		// aFormat, por lo tanto, configuro out de esa manera

		if (*p == '@') {
		
			if (foundCommand) return p - anInput + 1;
			if (!foundCommand && *anOutput != 0) return p - anInput;
			foundCommand = TRUE;
			*aTokenType = TOKEN_COMMAND;
			
		} else if (*p == ':' && foundCommand) {
		
			out = aFormat;
			count = 0;
			
		}	else if (*p != '\n' && *p != '\r') {
		
			if (*p == '\\' && *(p+1) == 'n') {
				out[count] = '\n';
				p++;
			}	else
				out[count] = *p;
			
			out[++count] = '\0';
		}
		
		p++;
		
	}
	
	return p - anInput;
	
}

/**/
- (void) advanceToEndIf: (char**) p
{
	char *ptrFor;
	char *ptrEndFor;
	char *aux;
	int forCount = 1;
	aux = *p;

	// Avanza hasta un @END_FOR@, pero si encuentra antes un @FOR_EACH@, debe avanzar 
	// hasta el siguiente
	
	do {

	  ptrEndFor = strstr(aux, "@END_IF@");
		ptrFor = strstr(aux, CONDITION_BEGIN_COMMAND);

		// Tenia que encontrar un END_FOR, pero antes me tope con un FOR_EACH
		// Incremento la cantidad de for anidados y me paro al final del FOR_EACH
		if (ptrFor != NULL && ptrFor < ptrEndFor) {
			forCount++;
			aux = strstr(ptrFor, "@") + 1;
		} else {
			forCount--;
			aux = ptrEndFor + strlen("@END_IF@");
		}

	} while (forCount > 0);

  if (aux) {
     *p = aux;
  }
	
}

/**/
- (void) advanceToEndFor: (char**) p
{
	char *ptrFor;
	char *ptrEndFor;
	char *aux;
	int forCount = 1;
	aux = *p;

	// Avanza hasta un @END_FOR@, pero si encuentra antes un @FOR_EACH@, debe avanzar 
	// hasta el siguiente
	
	do {

	  ptrEndFor = strstr(aux, "@END_FOR@");
		ptrFor = strstr(aux, MULTIPLE_BEGIN_COMMAND);

		// Tenia que encontrar un END_FOR, pero antes me tope con un FOR_EACH
		// Incremento la cantidad de for anidados y me paro al final del FOR_EACH
		if (ptrFor != NULL && ptrFor < ptrEndFor) {
			forCount++;
			aux = strstr(ptrFor, "@") + 1;
		} else {
			forCount--;
			aux = ptrEndFor + strlen("@END_FOR@");
		}

	} while (forCount > 0);

  if (aux) {
     *p = aux;
  }
	
}


/**
 *	Avanza en la cadena hasta el token pasado como parametro
 *	@param p es la cadena de entrada
 *	@param aToken es el token hasta el cual debe avanzar en la cadena
 */
- (void) advanceTo: (char**) p token: (char*) aToken 
{
	char *ptr;

  ptr = strstr(*p, aToken);

  if (ptr) {
     *p = ptr + strlen(aToken);
  }
	
}

/**
 * Devuelve que tipo de comando es: si es sentencia o ruta y devuelve los mismos.
 */
- (CommandType) getCommandType: (char*) aCommand statement: (char*) aStatement path: (char*) aPath
{
	char *p;

	p = strchr(aCommand, '|');

	if (!p) {
		strcpy(aPath, aCommand);
		return SIMPLE_COMMAND_TYPE;
	}

	strncpy(aStatement, aCommand, p - aCommand);
	aStatement[p-aCommand] = 0;

	strcpy(aPath, &p[1]);
	return STATEMENT_COMMAND_TYPE;

}

/**
 *	Devuelve la informacion encontrada en el archivo XML de los elementos pasados como parametro.
 *	@param aRootElement es el elemento padre del XML
 *	@param anElementName es el nombre del elemento del cual se esta solicitando la informacion.
 *	@param anInfo es la cadena en la cual se devuelve la informacion encontrada
 *	@return la cadena de informacion
 */
- (char*) getXMLInfoByElement: (scew_element*) aRootElement elementName: (char*) anElementName info: (char*) anInfo
{
  scew_element* aux = NULL;
  strcpy(anInfo, "");
  
  aux = scew_element_by_name(aRootElement, anElementName);

  if ( aux != NULL )
    if ( scew_element_contents(aux) != NULL )
      strcpy(anInfo, scew_element_contents(aux));

  return anInfo;
}

/**/
- (char*) getXMLElementInfoByPath: (char*) aPath elementToStart: (scew_element*) anElementToStart info: (char*) anInfo
{
	scew_element *aux;

	aux = [self getElement: anElementToStart path: aPath];
  if (aux == NULL) return NULL;  
  
  if ( scew_element_contents(aux) != NULL )
    strcpy(anInfo, scew_element_contents(aux));
    
  return(anInfo);
}

/**/
- (int) evalCondition: (scew_element*) aRootElement 
  elementName: (char*) anElementName 
  conditionValue: (char*) aConditionValue
  ifOperation: (IfOperation) anOperation
{
  char currentValue[50];
  
//  assert(aRootElement != NULL);
//  assert(strlen(anElementName) > 0);
  
  [self getXMLInfoByElement: aRootElement elementName: anElementName info: currentValue];  
  
  //doLog(0,"anOperation = %d, currentValue = |%s|, conditionValue = |%s|\n", anOperation, currentValue, aConditionValue);
  
  if (anOperation == IfOperation_EQUAL && strcmp(currentValue, aConditionValue) == 0 ) 
    return TRUE;
  else if (anOperation == IfOperation_NOT_EQUAL && strcmp(currentValue, aConditionValue) != 0 )
    return TRUE;
  
  return FALSE;    
} 


/**
 *   Devuelve si el path pasado como parametro es un path completo (ej: /calls/call) o
 *   el path actual (ej: taxDiscrimination)- 
 *	 @param aPath es el path en el archivo XML ej: /calls/call 
 *	 @param aRealPath es la variable en la cual devuelve el path real (ej: calls/call)
 *	 @return el tipo de ruta (completa o actual)
 */
- (PathType) getRealPath: (char*) aPath realPath: (char*) aRealPath
{

  if ( *aPath == '/' ) {
    memcpy(aRealPath, &aPath[1], strlen(aPath));
    return COMPLETE_PATH_TYPE;
  } 
  
  strcpy(aRealPath, aPath);
  return CURRENT_PATH_TYPE;
}

/**/
- (scew_element*) getElement: (scew_element*) aRoot path: (char*) aPath
{
  scew_element* root;
	char *elem;
	char *p;
	char elemName[50];

	if (aRoot == NULL) root = scew_tree_root(myTree);
	else root = aRoot;

	elem = aPath;
	if (*elem == '/') elem++;

	while (elem != '\0') {

		p = strchr(elem, '/');
		if (p == NULL) {
			return scew_element_by_name(root, elem);	
		}

		strncpy(elemName, elem, p-elem);
		elemName[p-elem] = 0;

		root = scew_element_by_name(root, elemName);		
		elem = p + 1;

	}

	return NULL;	

}

/**
 *   Devuelve el elemento padre de acuerdo a un path enviado por parametro y el nombre del
 *   elemento a evaluar.
 *	 @param aPath es el path en el archivo XML ej: /calls/call 
 *	 @param anElementName es la variable en la cual devuelve el nombre del elemento a evaluar
 *	 @return el elemento padre
 */
- (scew_element*) getXMLStructure: (scew_element*) aRootElement path: (char*) aPath elementName: (char*) anElementName 
{
  scew_element* root;
	char *elem;
	char *p;
	char elemName[50];

	//root = scew_tree_root(myTree);
  root = aRootElement;
  if (aRootElement == NULL) {
    root = scew_tree_root(myTree);
  }
  
	elem = aPath;
	if (*elem == '/') {
    elem++;
    root = scew_tree_root(myTree);
  }

	while (elem != '\0') {

		p = strchr(elem, '/');
		if (p == NULL) {
			strcpy(anElementName, elem);
			return root;
		}

		strncpy(elemName, elem, p-elem);
		elemName[p-elem] = 0;

		root = scew_element_by_name(root, elemName);		
		elem = p + 1;

	}

	return NULL;	

}
/**
 *	Evalua una condition del tipo root=value donde root es la ruta en el XML ej: tax/taxDiscrimination.
 *  Actualmente solo se evalua por el signo igual.
 *	@param aRootElement es el padre en el arbol
 *  @param anElementName es el nombre del componente a evaluar en el archivo XML.
 *	@param condition es la condicion a evalue
 *	@return TRUE si es verdadera FALSE en caso contrario
 */
- (IfOperation) getConditionValue: (char*) aCondition realPath: (char*) aRealPath conditionValue: (char*) aConditionValue
{
	char *index, *index2;
  IfOperation operation = IfOperation_EQUAL;
  
	*aConditionValue = 0;

	index = strchr(aCondition, '=');

	if (!index) return IfOperation_EQUAL;

	if (*(index - 1) == '!') {
    operation = IfOperation_NOT_EQUAL;
    index--;
    index2 = index +2;
  } else index2 = index + 1;

	strncpy(aRealPath, aCondition, index - aCondition);
	aRealPath[index - aCondition] = 0;

	strcpy(aConditionValue, index2);

  return operation;
}

/**/
- (char*) process: (char*) anInput              /* Archivo de formato*/
    finalDoc: (char*) aFinalDoc                 /* Archivo de salida */
    rootElement: (scew_element*) aRootElement   /* Elemento a partir del cual comienzo a buscar */
    elementName: (char*) anElementName          /* Nombre del elemento a buscar */
    path: (char*) aPath                         /* Path al elemento a buscar ?? */
{
	char *p = anInput;
  int	 tokenType;
  static char out[512];
  char format[64];
  int itemsQty;
  scew_element** list; 
  int i;
  static char info[255];
  int count;
  static char statement[255];
  static char path[255];
  static char realPath[255];
  CommandType commandType;
  static char initialPath[255];
  scew_element* rootElement = NULL;
  static char elementName[255];
  static char conditionValue[255];
  static char escapeCode[255];
  IfOperation operation;
	strcpy(format, "");
	strcpy(out, "");
  itemsQty = 0;

	//doLog(0,"process -> path = %s\n", aPath);fflush(stdout);
  /*
	p = strrchr(aPath, '/');
	strncpy(realPath, aPath, p - aPath);
	realPath[p-aPath] = 0;
	p++;
*/
//  rootElement = [self getElement: aFromElement path: realPath];
	
	//if (rootElement == NULL) return anInput;
  rootElement = aRootElement;
  
  p = anInput;
    
	while ( TRUE )
	{
		
    count = [self getToken: p output: out format: format tokenType: &tokenType];
    
		if (count == 0) break;
		p = p + count;

		// Si es un literal, lo concateno directamente
		if (tokenType == TOKEN_LITERAL) {
		//  doLog(0,"out = %s\n", out);
    	strcat(aFinalDoc, out);
			continue;
		}
      
    if (strcmp(out, MULTIPLE_END_COMMAND) == 0) break;
    if (strcmp(out, CONDITION_END_COMMAND) == 0 ) break;
    
    strcpy(statement, "");
    strcpy(path, "");
    strcpy(realPath, "");
          
    commandType = [self getCommandType: out statement: statement path: path];
    
    ///// Es un reemplazo simple //////////////////////////////////////////////
    if ( commandType == SIMPLE_COMMAND_TYPE ) {

      // Codigo de escape?
      if ( [self isEscapeCode: out] ) {
        if (myPrinterDefinition) strcat(aFinalDoc, [myPrinterDefinition getEscapeCode: out escapeCode: escapeCode]);
        continue;
      }                
    
      // Variable a reemplazar
      if ([self getRealPath: path realPath: realPath] == COMPLETE_PATH_TYPE) 
        rootElement = [self getXMLStructure: NULL path: realPath elementName: elementName];
      else {        
				rootElement = aRootElement;
        strcpy(elementName, realPath);
      }          
      
      [self appendString: aFinalDoc value: [self getXMLInfoByElement: rootElement elementName: elementName info: info] format: format];                
      continue;
    }
    
    ///// Comienza un IF /////////////////////////////////////////////////////
    if (strcmp(statement, CONDITION_BEGIN_COMMAND) == 0 ) {
    
      
      operation = [self getConditionValue: path realPath: initialPath conditionValue: conditionValue];
      //doLog(0,"=======> IF (%s:%s)\n", path, conditionValue);
      if ( [self getRealPath: initialPath realPath: realPath] == COMPLETE_PATH_TYPE) 
          rootElement = [self getXMLStructure: NULL path: realPath elementName: elementName];
      else {
        strcpy(elementName, initialPath);
      }
  
      if ([self evalCondition: rootElement elementName: elementName conditionValue: conditionValue ifOperation: operation]) {
        [self process: p finalDoc: aFinalDoc rootElement: aRootElement elementName: anElementName path: ""];
      }
 
      //doLog(0,"======= > TERMINO EL IF %s\n", elementName);fflush(stdout);
 
      [self advanceToEndIf: &p];
        
      continue;
    }

    ///// Comienza un Si encuentra un FOR_EACH //////////////////////////////
    if (strcmp(statement, MULTIPLE_BEGIN_COMMAND) == 0 ) {
        
				[self getRealPath: path realPath: realPath];
        
        rootElement = [self getXMLStructure: aRootElement path: realPath elementName: elementName];
        //rootElement = scew_element_by_name(aRootElement, "cimCashs");
        //doLog(0,"realPath = %s, elementName = %s\n", realPath, elementName);
        
        list = scew_element_list(rootElement, elementName, &itemsQty);
          	
        //doLog(0,"======= > FOR %s\n", elementName);fflush(stdout);
        
        for (i = 0; i < itemsQty; ++i ) {
        
          [self process: p finalDoc: aFinalDoc rootElement: list[i] elementName: elementName path: realPath];

        }
        // Libera la lista
        scew_element_list_free(list);
                
        [self advanceToEndFor: &p];
        //doLog(0,"======= > TERMINO EL FOR %s\n", elementName);fflush(stdout);
               
        //doLog(0,"p = %s\n", p);
      	continue;
    }     
    
  }



	return p;
}

/**/
- (char*) parseDocument: (char*) aFormatFileName finalDoc: (char*) finalDoc tree: (scew_tree*) tree
{
	char *p;
  char realPath[255];
  scew_element* rootElement = NULL;
  char elementName[255];

	strcpy(finalDoc, "");

	if ( [self loadFormatFile: aFormatFileName]  == FALSE ) {
    THROW(ERROR_LOADING_FORMAT_FILE_EX);
    return NULL;
  }

	myTree = tree;
  rootElement = scew_tree_root(myTree);
	p = formatFile;

  [self process: p 
      finalDoc: finalDoc 
      rootElement: rootElement 
      elementName: elementName 
      path: realPath];


	// Libero la memoria anterior si ya existia
	if (formatFile) free(formatFile);

	return finalDoc;
}

/**/
- (scew_tree*) getTree
{
  return myTree;
}

/**/
- (void) setPrinterDefinition: (id) aPrinterDefinition { myPrinterDefinition = aPrinterDefinition; }
- (id) getPrinterDefinition { return myPrinterDefinition; }

/**/
- (BOOL) isEscapeCode: (char*) aEscapeCode
{
 	if ( ( strcmp(aEscapeCode, BOLD_ON) == 0 ) ||
       ( strcmp(aEscapeCode, BOLD_OFF) == 0 ) ||
       ( strcmp(aEscapeCode, DBL_HEIGHT_ON) == 0 ) ||
       ( strcmp(aEscapeCode, DBL_HEIGHT_OFF) == 0 ) ||
       ( strcmp(aEscapeCode, DBL_HEIGHT_OFF) == 0 ) ||
       ( strcmp(aEscapeCode, CLEAR_FORMAT) == 0 ) ||
			 (strcmp(aEscapeCode, BAR_CODE_ITF) == 0) ||
			 (strcmp(aEscapeCode, ITALIC_FONT) == 0) ||
			 (strcmp(aEscapeCode, STANDARD_FONT) == 0) ||
			 (strcmp(aEscapeCode, COURIER_FONT) == 0) ||
			 (strcmp(aEscapeCode, COURIER_8x16_FONT) == 0) ||
			 (strcmp(aEscapeCode, VERDANA_SMALL_FONT) == 0) ||
			 (strcmp(aEscapeCode, VERDANA_BIG_FONT) == 0) ||
			 (strcmp(aEscapeCode, TAHOMA_FONT) == 0) ||
			 (strcmp(aEscapeCode, BITSTREAM_FONT) == 0) ||
			 (strcmp(aEscapeCode, COMIC_FONT) == 0) ||
			 (strcmp(aEscapeCode, INVERSE_ON) == 0) ||
			 (strcmp(aEscapeCode, CUT_PAPER) == 0) ||
			 (strcmp(aEscapeCode, CHAR_SPACE) == 0) ||
			 (strcmp(aEscapeCode, FEED_LINE) == 0) ||
			 (strcmp(aEscapeCode, INVERSE_OFF) == 0))
  

    return TRUE;
              
  return FALSE;  
}

/**/
- (void) appendString:(char *) aCadApp value:(char*) aValue format: (char*) aFormat
{
	char auxCad[256];
	char auxFormat[20];
	int  len;

	// Si tiene un formato, genera una cadena para aplicarlo
	if (*aFormat != 0) {
		sprintf(auxFormat, "%%%ss", aFormat);
	} else
		strcpy(auxFormat, "%s");

	// Genera la cadena
	sprintf(auxCad, auxFormat, aValue);
	
	if (*aFormat != 0) {
		if (aFormat[0] == '-') strcpy(auxFormat, &aFormat[1]); else strcpy(auxFormat, aFormat);
		len = atoi(auxFormat);
		auxCad[len] = '\0';
	}
			

	strcat(aCadApp, auxCad);
}

@end
