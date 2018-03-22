#ifndef IMASCONFIGLAUNCHER_H
#define IMASCONFIGLAUNCHER_H

#define IMAS_CONFIG_LAUNCHER id

#include <Object.h>
#include "system/util/all.h"
#include "FileManager.h"
#include "TITelesupD.h"

/**
 *	Esta clase sera la encargada de aplicar las configuraciones recibidas en la telesupervision
 */
@interface ImasConfigLauncher : Object
{
	/*lista de archivos del directorio*/
	COLLECTION files;
	
	/*indice de archivos procesados */
	int fIndex;
	
}

/**
*	Ejecuta la funcion asociada a la extension del archivo pasado por parametros
*	@param filename nombre del archivo con la configuracion
* 	@param tD daemon de telesupervision
*	@return si pudo o no ejecutar la funcion asociada a esa extension
*/
-(int) launchConfiguration:(char *)filename telesupD:(TI_TELESUPD)tD;

/**
*	Retorna el nombre del siguiente archivo a procesar
*	@param buffer buffer donde se almacenara el nombre del archivo 
*	@return buffer con el filename
*/
-(char *) nextFile:(char *) buffer;

/**
 * 
 */
 - (COLLECTION) getFilesCollection;
/**
 *	Libera el launcher
 */
- free;

+ (void) applyGeneralConfiguration;

@end

#endif
