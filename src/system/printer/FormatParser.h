#ifndef FORMAT_PARSER_H
#define FORMAT_PARSER_H

#define FORMAT_PARSER id

#include <Object.h>
#include "scew.h"
#include "AbstractPrinterDriver.h"

/**
 *	Clase encargada de formatear un archivo XML con un archivo de formato con extension vft,
 *  devolviendo como resultado un buffer con toda la informacion obtenida del XML.
 */

typedef enum {
	STATEMENT_COMMAND_TYPE,
	SIMPLE_COMMAND_TYPE
} CommandType;

typedef enum {
	COMPLETE_PATH_TYPE,
	CURRENT_PATH_TYPE
} PathType;


@interface FormatParser : Object
{
  char* formatFile;
  scew_parser	*myParser;
  scew_tree* myTree;
  id myPrinterDefinition;
}

/**
 *
 */
+ getInstance;


/**
 *	Carga el archivo de formato en formatFile definido como atributo de la clase.
 *	@param aFormatFileName el nombre del archivo de formato a cargar
 *  @return TRUE en el caso que se haya realizado con exito, FALSE en caso contrario.
 */
- (int) loadFormatFile: (char*) aFormatFileName; 


/**
 *
 */
- (scew_tree*) getTree; 

/**
 * Define la impresora, ya que el FormatParser necesita saber los codigos de escape al encontrar 
 * tags que signifiquen negrita, etc.
 */
- (void) setPrinterDefinition: (id) aPrinterDefinition;
- (id) getPrinterDefinition;

/**
 *
 */
- (BOOL) isEscapeCode: (char*) aEscapeCode;

/**
 *
 */
- (void) appendString:(char *) aCadApp value:(char*) aValue format: (char*) aFormat;


@end

#endif
