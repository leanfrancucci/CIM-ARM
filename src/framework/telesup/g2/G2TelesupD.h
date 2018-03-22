#ifndef G2TELESUPD_H
#define G2TELESUPD_H

#define G2TELESUPD id

#include <Object.h>
#include "ctapp.h"

#include "G2TelesupDefs.h"
#include "G2ActivePIC.h"
#include "TelesupD.h"
#include "TelesupJob.h"
#include "../dmodem/DModemProto.h"

/*
 *	Implementa el protocolo de telesupervision con el sistema G2
 */
@interface G2TelesupD: TelesupD
{
	BOOL					myExecutePICProtocol;
	BOOL					myIamInAJob;	
	TELESUP_JOB				myCurrentJob;
	G2_ACTIVE_PIC			myActivePIC;
	
	int						myJobError;
	char 				 *myCurrentMsg;
	DMODEM_PROTO myDmodemProto;
}

/*
 *	
 */
+ new;

/*
 *	
 */
- initialize;

/**/	
- (void) run;

/**
 * Inicia el proceso de login cruzado.
 * Si no logra concluir el proceso con exito lanaza la excepcion TSUP_BAD_LOGIN_EX.
 */
- (void) login;

/**
 *
 */
- (void) logout;

/**
 * Debe ser llamada al iniciar un Job recibiendo un mensaje Startjob.
 * @param (DATETIME) anInitialVigencyDate especifica la fecha inicial de vigencia del Job
 */
- (void) startTelesupJob: (DATETIME) anInitialVigencyDate;

/**
 *  Se llama al recibir un CommitJobRequest
 *  Ejecuta los Request recibidos en el Job si es que son inmediatos.
 */
- (void) commitTelesupJob;

/**
 *  Se llama al recibir un RollBackJobRequest
 * Elimina la lista de Request recibidos hasta el momento en el job.
 */
- (void) rollbackTelesupJob;

/**
 * Manda a ejecutar el job actual
 */
- (void) executeTelesupJob;

/**
 * envia el mensaje PTSD de login hacia el sistema remoto y
 * espera la respuesta satisfactoria.
 * {Privado}
 */
- (void) loginMe;

/**
 * Espera un mensaje PTSD de login y autentica el sistema remoto
 * y envia la respuesta satisfactoria, o lanza la excepcion TSUP_BAD_LOGIN_EX.
 * {Privado}
 */
- (void) loginHim;

/**
 * Configura el protocolo PIC adecuado para configurar la comunicacion
 */
- (void) setActivePIC: (G2_ACTIVE_PIC) anActivePIC;
- (G2_ACTIVE_PIC) getActivePIC;

/**
 * Configura la telesupervision para ejecutar o no el protocolo PIC.
 * Lo hace para cuestiones de testing.
 */
- (void) setExecutePICProtocol: (BOOL) aValue;
- (BOOL) isExecutePICProtocol;

/**/
- (id) getDmodemProto;

@end

#endif
