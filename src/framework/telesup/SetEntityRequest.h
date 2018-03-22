#ifndef SETENTITYREQUEST_H
#define SETENTITYREQUEST_H

#define SET_ENTITY_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "Request.h"



/**
 *	Define el tipo de los Request utilizados para configurar
 *  remotamente las entidades del sistema
 */
@interface SetEntityRequest: Request /* {Abstract} */
{

}


 /**
  * Los siguientes son método abstractos que deben ser
  * reimplementados por las clases que los necesiten.
  */

/**
 * Agrega una entidad nueva al sistema.

*/
- (void) addEntity;

/**
 * Cuando se hace un addEntity se devuelve una respuesta con los
 * valores de la clave de la entidad agregada.
 * El inicia un mensaje en el RemoteProxy llama al
 * hook method sendKeyValueResponse() remiplementado por cada subclase
 * y envia el mensaje al otro extremo de la conexion.
 * Es llamadao por el endRequest de SetEntityRequest.
 */
- (void) sendAddEntityResponse;

/**
 *
 */
- (void) sendRemoveEntityResponse;

/**
 *
 */
- (void) sendActivateEntityResponse;

/**
 *
 */
- (void) sendDeactivateEntityResponse;

/**
 * Envia los valores de los parametros clave de la entidad agregada al otro
 * extremo de la conexion.
 * Es llamado por  sendAddEntityResponse() y debe ser reimplementado con :
 *
 * 		[myRemoteProxy addParamAsXXX: "ParamName1" value: val];
 * 		[myRemoteProxy addParamAsXXX: "ParamName2" value: val];
 *		. . .
 * (en donde Param1 y Param son los campo clave de la entidad agregada)
 * {A}
 */
- (void) sendKeyValueResponse;


/**
 * Elimina una entidad existente.
 */
- (void) removeEntity;

/**
 * Activa una entidad del sistema
 */
- (void) activateEntity;

/**
 * Desactiva una entidad del sistema
 */
- (void) deactivateEntity;

/**
 * Configura una entidad del sistema
 */
- (void) setEntitySettings;

@end

#endif
