#ifndef CONFIGURATION_H
#define CONFIGURATION_H

#define CONFIGURATION id

#include <Object.h>
#include "Collection.h"

/**
 *	Define un item de configuracion. Tiene un nombre y un valor.
 */
typedef struct {
	char name[50];
	char value[255]; 
} ConfigurationItem;

/**
 *	Mantiene una coleccion con configuraciones levantadas de un archivo tipo ini.
 *	Cada linea de un archivo con el formato nombre=valor se carga a esta objeto para
 *	que pueda accederse de forma sencilla.
 *	Contiene metodos para pedir los valores de un determinado campo como string, long, short, etc.
 */
@interface Configuration : Object
{
	COLLECTION items;		
}

/**
 *	Devuelve la instancia por defecto para esta clase, que esta carga el archivo config.ini
 *	del path actual.
 */
+ getDefaultInstance;

/**
 *	Inicializa la instancia con el nombre del archivo pasado como parametro.
 *	Carga el archivo a memoria y a partir de este momento se puede llamar a los metodos
 *	para consultar los parametros.
 */
- initWithFileName: (char*) aFileName;

- (char*) getItemFromPosition: (int) aItemPos name: (char*) aName;
- (int) getItemsQty;
- (char*) getParamAsString: (char*) aName;
- (long) getParamAsLong: (char*) aName;
- (short) getParamAsShort: (char*) aName;
- (int) getParamAsInteger: (char*) aName;
- (void) getParamAsMoney: (char*) aName integer: (int*) integer decimal: (int*) decimal;

- (char*) getParamAsString: (char*) aName default: (char*) aDefault;
- (long) getParamAsLong: (char*) aName default: (long) aDefault;
- (short) getParamAsShort: (char*) aName default: (short) aDefault;
- (int) getParamAsInteger: (char*) aName default: (int) aDefault;

@end

#endif
