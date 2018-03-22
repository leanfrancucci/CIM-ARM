#ifndef SQL_RECORD_SET_H
#define SQL_RECORD_SET_H

#define SQL_RECORD_SET id

#include <Object.h>
#include "system/util/all.h"
#include "AbstractRecordSet.h"
#include "Transaction.h"
#include "SQLField.h"

/**
 *	RecordSet para manejo de SQL.
 */
@interface SQLRecordSet: AbstractRecordSet
{
	char *myQuery;
	COLLECTION myRows;
	COLLECTION myFields;
	int	myRecordSize;
	int myCurrentRow;
	BOOL myFetchOnOpen;
	BOOL myIsTable;
	char myTableName[255];
	BOOL myIsNewRecord;
	BOOL myIsOpen;
	BOOL myDebug;           // Activa modo debug (default = false)
  BOOL myUseGenerator;    // Utiliza generator para la primary key ?
  TRANSACTION myTransaction;  // Transaccion asociado (default = null)

	// Mantiene un arreglo con los valores que fueron editados, es decir, cada vez que sea hace
	// un setXXXX() sobre un campo se marca como editado para ese registro
	// Esto se utiliza para saber que valores cambiaron y debo enviar a la base de datos en un update o insert
	BOOL *myValueChanged;
}

/**
 *
 */
- (void) setTransaction: (TRANSACTION) aTransaction;

/**
 *	Configura si realiza la query cuando se abre la tabla o no.
 *	Se utiliza cuando se quiere abrir una tabla que posiblemente tengo muchos registros pero 
 *	solo se va a insertar (no a modificar ni a leer) entonces no trae todos los registros.
 *	Sino se configura, por default hace el fetch.
 */
- (void) setFetchOnOpen: (BOOL) aValue;

/**
 *	Inicializa el recordset con la tabla pasada como parametro.
 *	Unicamente los recordset iniciados de esta forma tienen posibilidades de ser modificados mediante (add, delete y save).
 */
- initWithTableName: (char*) aTableName;

/**
 * 
 */
- initWithTableNameAndFilter: (char*) aTableName filter: (char*) aFilter;

/**
 *
 */
- initWithTableNameAndFilter: (char*) aTableName filter: (char*) aFilter orderFields: (char*) anOrderFields;  

/**
 *	Inicializa el recordset con la query pasada como parametro.
 *	El recordset no es modificable.
 */
- initWithQuery: (char*) aQuery;

/**
 * Activa modo debug.
 */ 
- (void) setDebug: (BOOL) aValue;

/**
 *  Muestra los metadatos de la tabla
 */
- (void) showMetaData;

@end

#endif
