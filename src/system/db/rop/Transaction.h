#ifndef TRANSACTION_H
#define TRANSACTION_H

#define TRANSACTION id

#include <Object.h>
#include "RecordSet.h"

typedef enum {
	OP_APPEND,
	OP_DELETE,
	OP_UPDATE,
	OP_COMMIT,
	OP_ABORT
} TransactionOperation;

/**
 *	
 */
@interface Transaction : Object
{
	unsigned long transactionId;
}


- (unsigned long) getTransactionId;

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

/**
 *	Notifica a la transaccion que se agrego un registro.
 *	Solo debe ser utilizado por la clase RecordSet o subclases de esta.
 *	No debe llamarse directamente a estos metodos.
 *	@param recordset el recordset sobre el cual se esta realizando la operacion.
 *	@param entityId el numero de tabla a la cual se hace referencia.
 *	@param entityPart el numero de parte (en caso de multipart) a la cual se hace referencia. 
 *	@param recNo el numero de registro que se agrego. 	
 */
- (void) appendRecord: (RECORD_SET) aRecordSet entityId: (int) anEntityId 
           entityPart: (int) anEntityPart recNo: (unsigned long) aRecNo;

/**
 *	Notifica a la transaccion que se elimino un registro.
 *	Solo debe ser utilizado por la clase RecordSet o subclases de esta.
 *	No debe llamarse directamente a estos metodos.
 *	@param recordset el recordset sobre el cual se esta realizando la operacion.
 *	@param entityId el numero de tabla a la cual se hace referencia.
 *	@param entityPart el numero de parte (en caso de multipart) a la cual se hace referencia. 
 *	@param recNo el numero de registro que se agrego. 	
 */
- (void) deleteRecord: (RECORD_SET) aRecordSet entityId: (int) anEntityId 
           entityPart: (int) anEntityPart recNo: (unsigned long) aRecNo;

/**
 *	Notifica a la transaccion que se actualizo un registro.
 *	Solo debe ser utilizado por la clase RecordSet o subclases de esta.
 *	No debe llamarse directamente a estos metodos.
 *	@param recordset el recordset sobre el cual se esta realizando la operacion.
 *	@param entityId el numero de tabla a la cual se hace referencia.
 *	@param entityPart el numero de parte (en caso de multipart) a la cual se hace referencia. 
 *	@param recNo el numero de registro que se agrego. 	
 */
- (void) updateRecord: (RECORD_SET) aRecordSet entityId: (int) anEntityId 
           entityPart: (int) anEntityPart recNo: (unsigned long) aRecNo;   

@end

#endif
