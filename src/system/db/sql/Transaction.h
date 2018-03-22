#ifndef TRANSACTION_H
#define TRANSACTION_H

#define TRANSACTION id

#include <Object.h>

/**
 *	
 */
@interface Transaction : Object
{
}

/**
 *	Comienza una nueva transaccion. 
 * 	A partir de este momento todas las operaciones realizadas con esta transaccion se 
 *	hacen de forma atomica.
 */
- (void) startTransaction;

/**
 *	Hace un commit (confirma) la transaccion, quedando guardada definitivamente.
 */
- (void) commitTransaction;

/**
 *	Hace un rollback de la transaccion, restaurando todos los cambios realizados.
 *	@warning Si algunos de los recordset que involucran a la transaccion esta abierto, 
 *	este metodo falla porque no puede eliminar el archivo.
 */
- (void) abortTransaction;


@end

#endif
