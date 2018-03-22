#ifndef CLEAN_DATA_REQUEST_H
#define CLEAN_DATA_REQUEST_H

#define CLEAN_DATA_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "Request.h"


/**
 *	Request que permite limpiar datos del equipo.
 *	Inicializar auditoria, tickets (que incluye llamadas y venta de productos) y cierres de caja.
 */
@interface CleanDataRequest: Request
{
	BOOL myCleanAudits;
	BOOL myCleanTickets;
	BOOL myCleanCashRegister;
}		

/**
 *	Configura los grupos de datos que desea limpiar.
 */
 
- (void) setCleanAudits: (BOOL) aValue;
- (void) setCleanTickets: (BOOL) aValue;
- (void) setCleanCashRegister: (BOOL) aValue;
		
@end

#endif
