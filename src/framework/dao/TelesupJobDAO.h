#ifndef  TELESUP_JOB_DAO_H
#define  TELESUP_JOB_DAO_H


#define  TELESUP_JOB_DAO		id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"
#include "Request.h"
#include "system/db/all.h"
#include "DataSearcher.h"

#include "TelesupJob.h"

/** 
 *  Gestiona la persistencia de jobs de telesupervision
 */
@interface TelesupJobDAO: DataObject
{
	ABSTRACT_RECORDSET 		myRecordSet;
	
	ABSTRACT_RECORDSET 		myNextPendingJobRecordSet;
	DATA_SEARCHER 			myNextPendingJobDataSearcher;
	
	ABSTRACT_RECORDSET 		myRequestRecordSet;
	DATA_SEARCHER 			myRequestDataSearcher;
	
	OMUTEX 					myMutex;
	
	TELESUP_JOB				myCurrentJob;	
}

/**
 * Comienza la ejecucion del Job @param (JOB) aJob.
 * Solo puede ser ejecutado un solo Job dentro de un beginJobExecution() y
 * un cancelJob() o un jobExecuted().
 * @param aJob el trabajo que se prepara para su ejecucion.
 */
- (void) beginJobExecution: (TELESUP_JOB) aJob;
 
/**
 * Inidica que finalizo exitosamente la ejecucion del Job.
 * Marca el Job como ejecutado en el medio de persistencia.
 * Hasta que no se marque el job como ejecutado el mismo quedara pendiente, por mas 
 * que se hayan ejecutado algunos requests dentro del job. Los requests ejecutados
 * no se volveran a ejecutar porque quedan marcados como ejecutados. 
 * 
 */
- (void) jobExecuted;

/**
 * Remueve el Job del medio de persistencia y todos sus requests.
 * Cuando se recibe un RollBackJob a traves de la telesupervision el Job
 * debe ser descartado junto con sus requests.
 */
- (void) removeJob: (TELESUP_JOB) aJob;

/**
 * Devuelve el siguiente request pendiente de ejecucion. 
 * Devuelve NULL si no hay mas request pendientes.
 */
- (REQUEST) getNextPendingRequest;

/**
 * Devuelve el primer Job no ejecuta hasta la fecha indicada.
 * Devuelve NULL si no existen Jobs no ejecutados.
 */
- (TELESUP_JOB) getNextPendingJobUntil: (datetime_t) aDate;
 
@end

#endif
