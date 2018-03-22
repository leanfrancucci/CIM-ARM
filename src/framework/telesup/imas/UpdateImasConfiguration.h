#ifndef UPDATEIMASCONFIGURATION_H
#define UPDATEIMASCONFIGURATION_H

#define UPDATE_IMAS_CONFIGURATION id

#include <Object.h>
#include "ImasConfiguration.h"

/**
 *	Configuracion de updates de software
 */
@interface UpdateImasConfiguration : ImasConfiguration
{

}

/**
*	Toma el archivo pasado por parametro y aplica la configuracion contenida en el mismo
*	@param filename path del archivo que contiene la configuracion
*	@param dest este parametro sera utilizado por algunas configuraciones ya que la mayoria necesita un directorio donde se deben almacenar ciertos archivos, en las configuraciones donde no se necesita depositar archivos en ningun lado puede utilizarse para otro proposito
*	@return si la operacion fue o no un exito
*/
-(int) applyConfiguration:(char *) filename destination:(char*) dest;

@end

#endif
