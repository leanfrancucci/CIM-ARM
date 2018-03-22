#ifndef DB_CONNECTION_H
#define DB_CONNECTION_H

#define DB_CONNECTION id

#include <Object.h>
#include "system/lang/all.h"
#include "AbstractRecordSet.h"
#include "rop/Transaction.h"

/**
 *	Abstraccion de una conexion a la base de datos.
 *	Proporciona metodos para crear nuevos RecordSets, que deben ser redefinidos por las 
 *	subclases de acuerdo al tipo (SQL, ROP)
 */
@interface DBConnection : Object
{

}

/**	
 *	Devuelve la unica instancia posible de esta clase.
 */
+ getInstance;

/**
 *
 */
- (ABSTRACT_RECORDSET) createRecordSet: (char*) aTableName;

/**
 * 
 */
- (ABSTRACT_RECORDSET) createRecordSetWithFilter: (char*) aTableName filter: (char *) aFilter;

/**
 *
 */
- (ABSTRACT_RECORDSET) createRecordSetWithFilter: (char*) aTableName filter: (char *) aFilter orderFields: (char *) anOrderFields;

/**
 *	
 */
- (ABSTRACT_RECORDSET) createRecordSetFromQuery: (char*) aQuery;

/**
 *	Crea una nueva transaccion.
 */
- (TRANSACTION) createTransaction;

/**
 *  Ejecuta el statement pasado por parametro. 
 */
- (int) executeStatement: (char*) anStatement;

/**
 *  Ejecuta el statement pasado por parametro en la transaccion pasada por
 *  parametro. 
 */
- (int) executeStatement: (char*) anStatement transaction: (TRANSACTION) aTransaction;

/**
 * Devuelve si una tabla tiene backup
 */
- (BOOL) tableHasBackup: (char*) aTableName;

@end

#endif
