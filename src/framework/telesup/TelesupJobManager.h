#ifndef TELESUP_JOB_MANAGER_H
#define TELESUP_JOB_MANAGER_H

#define TELESUP_JOB_MANAGER id

#include <Object.h>
#include "ctapp.h"

#include "TelesupDefs.h"
#include "TelesupSecurityManager.h"

#include "Persistence.h"
#include "TelesupJob.h"


/*
 *	Administra los jobs de telesupervision 
 */
@interface TelesupJobManager: Object
{
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
 * Ejecuta los jobs que quedan pendientes de ejecucion hasta el momento.
 */
- (void) executePendingJobs;

/**
 * Devuelve el primer TelesupJob pendiente - no ejecutado - que encuentre hasta ahora.
 * @result devuelve el primer job encontrado o NULL si no hay ninguno.
 */
- (TELESUP_JOB) getNextPendingJobUntilNow;
	
/**
 * Devuelve el primer TelesupJob pendiente - no ejecutado - que encuentre hasta aDate.
 * @result devuelve el primer job encontrado o NULL si no hay ninguno.
 */
- (TELESUP_JOB) getNextPendingJobUntil: (datetime_t) aDate;

	
@end

#endif
