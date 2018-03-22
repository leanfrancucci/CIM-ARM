#ifndef G2_ACTIVE_PIC_H
#define G2_ACTIVE_PIC_H

#define G2_ACTIVE_PIC id

#include <Object.h>
#include "ctapp.h"

#include "system/io/all.h"
#include "system/os/all.h"

#include "TelesupDefs.h"

/**
 * Implementa el protocolo de identificacion de comunicacion entre el ct y el 
 * sistema de telesupervision central.
 * Implementa la parte activa del protocolo (la parte del ct)
 *
 *				CT								G2
 *			 (activo)						 (pasivo)
 *	inicia comunicacion cualquiera de los dos
 *			   |---- 	msg de config.  	   ----->
 *				
 *			   <---- msg de aceptacion/rechazo -----|
 *
 *
 */
@interface G2ActivePIC: Object
{
	char						myMessageBuffer[PIC_MSG_SIZE + 1];
													
	READER 						myReader;
	WRITER 						myWriter;
	int             connectionType;

	int myTelcoType;
}		


/**/
- (void) clear;
	
/**
 */
- (void) setReader: (READER) aReader;

/**
 */
- (void) setWriter: (WRITER) aWriter;

/**
 * Inicia el protocolo activo PIC
 */
- (void) executeProtocol;

/**
 * Configura aMessage con los parametros de configuracion del protocolo de transporte y de aplicacion
 * adecuados.
 * Lanza la excepcion TRANSPORT_INVALID_CONNECTION_EX si es un mensaje invalido o
 * un mensaje de rechazo de la conexion. 
 * @throws TRANSPORT_INVALID_CONNECTION_EX 
 * @result (int) devuelve el tamanio de la informacion que se debe transferir. 
 */
- (int) setupConfigurationMessage: (char *) aMessage;

/**
 * Retorna TRUE si aMessage es un mensaje valido de aceptacion.
 */
- (BOOL) checkForAcceptedResponse: (char *) aMessage;

/**/
- (void) setConnectionType: (int) cType;

/**/
- (int) getConnectionType;

/**/
- (void) setTelcoType: (int) aTelcoType;

/**/
- (char*) getPTSDVersion;

@end

#endif


