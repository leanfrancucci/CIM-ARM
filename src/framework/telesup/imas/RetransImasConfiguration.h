#ifndef RETRANSIMASCONFIGURATION_H
#define RETRANSIMASCONFIGURATION_H

#define RETRANS_IMAS_CONFIGURATION id

#include <Object.h>
#include "ImasConfiguration.h"
#include "TITelesupD.h"

/**
 *	Configuracion de updates de software
 */
@interface RetransImasConfiguration : ImasConfiguration
{
	TI_TELESUPD tD;
}

/**
*	Toma el archivo pasado por parametro y aplica la configuracion contenida en el mismo
*	@param filename path del archivo que contiene la configuracion
*	@param dest este parametro sera utilizado por algunas configuraciones ya que la mayoria necesita un directorio donde se deben almacenar ciertos archivos, en las configuraciones donde no se necesita depositar archivos en ningun lado puede utilizarse para otro proposito
*	@return si la operacion fue o no un exito
*/
-(int) applyConfiguration:(char *) filename destination:(char*) dest;

/**/
-(void) setTelesupDaemon:(TI_TELESUPD)t;

@end

#endif
