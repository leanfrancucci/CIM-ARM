#ifndef GENERALIMASCONFIGURATION_H
#define GENERALIMASCONFIGURATION_H

#define GENERAL_IMAS_CONFIGURATION id

#include <Object.h>
#include "ImasConfiguration.h"

/**
 *	Configuracion General
 */
@interface GeneralImasConfiguration : ImasConfiguration
{
	char fechaVigencia[13]; /*'ddmmyyyyhh24mi'  	12*/
	char tiempoTelesupervision[13];
	char enviarAuditoria[2];
	char enviarTrafico[2];
	char prefijoTicket[7];
	char numeroInicialTicket[5];
	char tipoTicket[2];/* 0 unitario 1 total*/	
	char valorImpuesto1[11];
	char siglaImpuesto1[11];
	char valorImpuesto2[11];
	char siglaImpuesto2[11];
	char valorImpuesto3[11];
	char siglaImpuesto3[11];
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
