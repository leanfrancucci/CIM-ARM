#ifndef RECORD_SET_H
#define RECORD_SET_H

#define RECORD_SET id

#include <Object.h>
#include "Table.h"
#include "AbstractRecordSet.h"
#include "Transaction.h"

/**
 *	Implementacion particular para un RecordSet simple, que maneja un archivo de datos y 
 *	obtiene el esquema de Table.
 */
@interface RecordSet : AbstractRecordSet
{
	BOOL myIsDirty;				// indica si el registro esta sucio, si esta modificado
	BOOL myIsNewRecord;		// indica si es un nuevo registro
	char *myBuffer;				// el buffer que contiene los datos del registro actual
	FILE *myHandle;				// el handle al archivo de datos
	id		myTable;				// la tabla asociada
	int		myRecordSize;		// el tamaño del registro en cantidad de bytes
	Field *myFields;			// la definicion de los campos de la tabla
	int		myFieldCount;		// la cantidad de campos (columnas) de la tabla
	OMUTEX myMutex;				// el mutex para asegurar el acceso unico para lecturas/escrituras
	long	myRecordCount;
	BOOL	myIsOpen;				// indica si el archivo fue o no abierto.
	char	myFileName[TABLE_FILE_NAME_SIZE];
	TRANSACTION myTransaction;
}

/**
 *	Inicializa el recordset con el Table pasado como parametro.
 *	Deberia ser llamada unicamente desde Table.
 */
- initWithTable: (id) aTable;

/**
 *	Devuelve la tabla asociada al recordset.
 */
- (id) getTable;

/**
 *
 */
- (void) setTransaction: (TRANSACTION) aTransaction;

/**
 *	Devuelve el identificador de la tabla (para manejo interno)
 */
- (int) getTableId;

/**
 *	Devuelve el numero de parte o archivo (para manejo interno)
 */
- (int) getPartNumber;


/**
 *	Seteo por completo el buffer del RecordSet.
 */
- (void) setRecordBuffer: (char*) aBuffer;

/**
 *	Devuelvo por completo el buffer del RecordSet.
 */
- (char*) getRecordBuffer;


@end

#endif
