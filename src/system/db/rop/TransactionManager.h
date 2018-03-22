#ifndef TRANSACTION_MANAGER_H
#define TRANSACTION_MANAGER_H

#define TRANSACTION_MANAGER id

#include <Object.h>
#include "RecordSet.h"
#include "Transaction.h"
#include "system/os/all.h"

/**
 *	doc template
 */
@interface TransactionManager : Object
{
	OMUTEX mutex;
	unsigned long nextTransactionId;
	RECORD_SET transactionRecordSet;
}

+ getInstance;

- (void) stop;

- (unsigned long) getNextTransactionId;

- (void) startTransaction: (TRANSACTION) aTransaction;

/**
 *	Hace un commit (confirma) la transaccion, quedando guardada definitivamente.
 */
- (void) commitTransaction: (TRANSACTION) aTransaction;

/**
 *	Hace un rollback de la transaccion, restaurando todos los cambios realizados.
 */
- (void) abortTransaction: (TRANSACTION) aTransaction;

/**
 *	Notifica a la transaccion que se agrego un registro.
 *	@param recordset el recordset sobre el cual se esta realizando la operacion. 
 *	@param recNo el numero de registro que se agrego. 	
 */
- (void) appendRecord: (TRANSACTION) aTransaction recordSet: (RECORD_SET) aRecordSet entityId: (int) anEntityId 
           entityPart: (int) anEntityPart recNo: (unsigned long) aRecNo;

/**
 *	Notifica a la transaccion que se elimino un registro.
 *	@param recordset el recordset sobre el cual se esta realizando la operacion. 
 *	@param recNo el numero de registro que se agrego. 	
 */
- (void) deleteRecord: (TRANSACTION) aTransaction recordSet: (RECORD_SET) aRecordSet entityId: (int) anEntityId 
           entityPart: (int) anEntityPart recNo: (unsigned long) aRecNo;

/**
 *	Notifica a la transaccion que se actualizo un registro.
 *	@param recordset el recordset sobre el cual se esta realizando la operacion. 
 *	@param recNo el numero de registro que se agrego. 	
 */
- (void) updateRecord: (TRANSACTION) aTransaction recordSet: (RECORD_SET) aRecordSet entityId: (int) anEntityId 
           entityPart: (int) anEntityPart recNo: (unsigned long) aRecNo;   


@end

#endif
