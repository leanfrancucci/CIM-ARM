#ifndef RESTART_SYSTEM_REQUEST_H
#define RESTART_SYSTEM_REQUEST_H

#define RESTART_SYSTEM_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "Request.h"


/**
 *	Reinicia el sistema (solo si las cabinas estan deshabilitadas).
 */
@interface RestartSystemRequest: Request
{
	BOOL myForceReboot;
}		

- (void) setForceReboot: (BOOL) aValue;

@end

#endif
