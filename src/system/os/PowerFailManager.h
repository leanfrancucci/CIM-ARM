#ifndef POWER_FAIL_MANAGER_H
#define POWER_FAIL_MANAGER_H

#define POWER_FAIL_MANAGER id

#include <Object.h>
#include "system/lang/all.h"
#include "OTimer.h"

/**
 *	Maneja el tiempo de corte de energia.
 *	Actualiza constantemente la hora actual en el almacenamiento (RTC o Archivos,
 *	dependiendo de la version) con el fin de recuperar la fecha/hora de corte.
 *
 *	<<singleton>> 	
 */
@interface PowerFailManager : Object
{
	OTIMER timer;
	datetime_t powerFailTime;				// fecha/hora del corte de energia
	int currentFile;
}

/**
 *	Devuelve la unica instancia posible de esta clase.
 */
+ getInstance;


/**
 *	Devuelve la fecha/hora de corte de energia.
 *	@return 0 si no hubo corte de energia y el sistema se cerro correctamente.
 */
- (datetime_t) getPowerFailTime;

/**
 *	Comienza a guardar la fecha/hora actual del sistema.
 */
- (void) start;

/**
 *	Termina de guardar la fecha/hora actual del sistema.
 *	Debe llamarse al cerrarse el sistema, para que al volver a iniciarse recupere
 *	la fecha/hora correspondiente.
 */
- (void) stop;

@end

#endif
