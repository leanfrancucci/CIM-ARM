#ifndef TELESUP_JOB_H
#define TELESUP_JOB_H

#define TELESUP_JOB id

#include <Object.h>
#include "ctapp.h"
#include "system/io/all.h"
#include "system/os/all.h"

#include "TelesupDefs.h"
#include "TelesupSecurityManager.h"

#include "Persistence.h"
#include "TelesupJobDAO.h"

#include "TelesupErrorManager.h"

/*
 *	Gestiona los jobs de telesupervision almacenando request y ejecutandolos adecuadamente.
 */
@interface TelesupJob: Object
{
	TELESUP_JOB_DAO 		myTelesupJobDAO;
	
	int						myTelesupId;
	int						myTelesupRol;
	unsigned long			myJobId;
	DATETIME				myInitialVigencyDate;	
	
	BOOL					myIsCommited;
	BOOL					myIsExecuted;
	BOOL					myIsNulled;
}

/**
 *	
 */
+ new;

/**
 *
 */
- free;
 
/**
 *	
 */
- initialize;

/**
 *	
 */
- (void) clear;

/**
 *
 */ 
- (void) setJobId: (unsigned long) aJobId;
- (unsigned long) getJobId;

/**
 * Identifica un esquema de telesupervision determinado (telefonica, g2, telecom, etc.)
 */ 
- (void) setTelesupId: (int) aTelesupId;
- (int) getTelesupId;

/**
 * El rol de telesupervision que genero el Job.
 */ 
- (void) setTelesupRol: (int) aTelesupRol;
- (int) getTelesupRol;

/**
 * Indica si el Job fue ejecutado exitosamente.
 */
- (void) setExecuted: (BOOL) aValue;
- (BOOL) isExecuted;

/**
 * Indica si el job ha sido anulado antes de ser ejecutado.
 * Por ahora no se usa pero puede ser que se quiera anular un Job en algun momento
 * por alguna causa particular.
 */
- (void) setNulled: (BOOL) aValue;
- (BOOL) isNulled;

/**
 * Indica si el job ha sido concluido con exito. No indica que ha sido ejecutado sino que
 * todos los Request del Job han sido recibidos y el mensaje CommitJob recibido exitosamente.
 */
- (void) setCommited: (BOOL) aValue;
- (BOOL) isCommited;

/**
 *
 */ 
- (void) setInitialVigencyDate: (DATETIME) anInitialVigencyDate;
- (DATETIME) getInitialVigencyDate;

/**
 * Inicializa un nuevo Job con fecha de vigencia de inicio ahora (ya).
 */
- (void) startTelesupJob;

/**
 * Inicializa un nuevo Job con una fecha de vigencia de inicio.
 * Fecha de vigencia = 0 indica que los request del job deben ejecutarse inmediatamente
 * luego de recibir el Commit.
 */
- (void) startTelesupJobAt: (DATETIME) anInitialVigencyDate;

/**
 *	Almacena los request pero no los ejecuta.
 */
- (void) commitTelesupJob;
	
/**
 *	Elimina todos los request agregados al job.
 * @throws TS_JOB_COMMITED si el Job esta previamente en estado Commit
 */
- (void) rollbackTelesupJob;	

/**
 * Devuelve TRUE si el job esta listo para ejecutarse y FALSE en caso contrario.
 * El Job esta listo para ejecucion si no esta ejecutado, no esta anulado y esta hecho el commit.
 */
- (BOOL) hasToExecute;

				
/**
 * Ejecuta los request del job corriente.
 * @throws TS_JOB_EXECUTED si el Job se encuentra previamente ejecutado.
 * @throws TS_JOB_NULLED si el Job esta anulado.
 */	
- (void) executeTelesupJob;
					
/**
 *	Agrega un nuevo request al job
 */
- (void) addRequest: (REQUEST) aRequest;
	
@end

#endif
