  #ifndef XML_CONSTRUCTOR_H
#define XML_CONSTRUCTOR_H

#define XML_CONSTRUCTOR id

#include <Object.h>
#include "ctapp.h"
#include <scew.h>
#include "Configuration.h"

#define REPRINT_MSG_DSC "====  REIMPRESION  ===="

/**
 *	Clase que se encarga de construir documentos XML.
 */
@interface XMLConstructor : Object
{
}

/**
 *	Es la interface a la construccion de archivos XML de una entidad en particular.
 *	@param anEntity el nombre de la entidad para construir el XML.
 *	@param isReprint si es reimpresion.
 *	@param tree la referencia al arbol xml	
 */
- (scew_tree*) buildXML: (id) anEntity isReprint: (BOOL) isReprint; 

/**
 *
 */
- (scew_tree*) buildXML: (id) anEntity entityType: (int) anEntityType isReprint: (BOOL) isReprint;

/**
 *	Construye un archivo con el texto pasado por parametro.
 *	@param aText texto a imprimir.
 */
- (scew_tree*) buildXML: (char*) aText;



@end

#endif
