#ifndef TELESUPSECURITYMANAGER_H
#define TELESUPSECURITYMANAGER_H

#define TELESUP_SECURITY_MANAGER id

#include <Object.h>
#include "ctapp.h"

/*
 *	Implementa el esquema de proteccion  de acceso
 *  del sistema de telesupervision.
 */
@interface TelesupSecurityManager: Object
{

}

/*
 *	
 */
+ new;

/*
 * Devuelve la unica instancia de la clase
 */
+ getInstance;

/*
 *	
 */
- initialize;


/*
 * Chequea si el rol tiene tiene acceso para ejecutar las operaciones dadas.
 * Si tiene acceso sale silencioso, si no tiene dispara una excepcion. 
 * 
 */	
- (void) checkAccess: (int) aRol groupOp: (int) aGroupOperation;

/*
 * 
 * 
 */	
- (void) grantAccess: (int) aRol groupOp: (int) aGroupOperation;

/*
 * 
 * 
 */	
- (void) denyAccess: (int) aRol groupOp: (int) aGroupOperation;



@end

#endif
