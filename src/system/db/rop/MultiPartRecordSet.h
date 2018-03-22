#ifndef MULTI_PART_RECORD_SET_H
#define MULTI_PART_RECORD_SET_H

#define MULTI_PART_RECORD_SET id

#define INFINITE_MAX_RECORD_COUNT -1

#include <Object.h>
#include "OMutex.h"
#include "Table.h"
#include "AbstractRecordSet.h"
#include "RecordSet.h"

/**
 *	Implementacion de un RecordSet particionado en varios archivos y con un archivo de indices.
 *	La idea es tener una cierta cantidad maxima de registros por archivo, supongamos 1000 para hacer
 *	mas sencilla su eliminacion (todo esto esta relacionado con el filesystem y el manejo de flash).
 *	Cada vez que se llena el archivo, se crea otro de las mismas caracteristicas para contener los
 *	nuevo registros que se van agregando y asi sucesivamente.
 *
 *	Como sabemos, el RecordSet por si solo es capaz de manejar un archivos de datos a la vez. Esta
 *	clase, tiene como objetivo, manejar, de la forma mas transparente posible el particionado automatico
 *	de los archivos. Al hablar de transparencia, quiero decir que para el usuario de esta clase, el
 *	manejo sea identico al del RecordSet.
 *
 *	Internamente maneja dos RecordSet normales, uno para un archivo de indices, y otro para el archivo
 *	de datos actual, que va cambiando (se destruye el objeto y se crea otro) a medida que navegamos
 *	por el RecordSet e insertamos nuevos registros. El archivo de indices se utiliza para poder 
 *	mantener una organizacion de estos archivos particionados. Cada registro de esta tabla tiene:
 *
 *	TABLE_NAME: el nombre de la tabla (por ejemplo: calls_0, calls_1)
 *	FROM_DATE : desde que fecha abarca la tabla.
 *	TO_DATE   : hasta que fecha abarca la tabla.
 *	FROM_ID		: desde que id abarca.
 *	
 */
@interface MultiPartRecordSet : AbstractRecordSet
{
	BOOL myIsDirty;				// indica si el registro esta sucio, si esta modificado
	BOOL myIsNewRecord;		// indica si es un nuevo registro
	char *myBuffer;				// el buffer que contiene los datos del registro actual
	int		myRecordSize;		// el tama�o del registro en cantidad de bytes
	Field *myFields;			// la definicion de los campos de la tabla
	int		myFieldCount;		// la cantidad de campos (columnas) de la tabla
//	OMUTEX myMutex;				// el mutex para asegurar el acceso unico para lecturas/escrituras
	RECORD_SET myIndexRecordSet;
	RECORD_SET myDataRecordSet;
	char	myTableName[TABLE_NAME_SIZE];
	char  myDateField[FIELD_SIZE];
	char  myIdField[FIELD_SIZE];
	long	myCurrentTableNumber;
	long	myMaxRecordCount;
	BOOL  myAutomaticPartition;
	BOOL  myAppendFileMode;
	int   myMaxFiles;
	TRANSACTION myTransaction;
	BOOL myShouldCutFile;
}

/**
 *	Establece el campo que se va a utilizar para ordenar y hacer el corte por fechas.
 */
- (void) setDateField: (char*) aDateField;

/**
 *	Establece el campo que se va a utilizar para ordenar y hacer el corte por identificador.
 */
- (void) setIdField: (char*) anIdField;

/**
 *	Indica si debe hacer el cutfile
 */
- (BOOL) shouldCutFile;
- (void) setShouldCutFile: (BOOL) aValue;

/**
 *	Agrega un archivo mas a la lista de archivos MultiPart.
 *
 *	@return el nombre de la tabla recien creada.
 */
- (const char*) appendFile;

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
 *	Seteo la cantidad maxima de registros que puede contener un RecordSet antes de dividirse en
 *	varios archivos.
 *	Si aMaxRecordCount = -1, entonces no hay cantidad maxima de registros.
 */
- (void) setMaxRecordCount: (long) aMaxRecordCount;

/**
 *	Devuelve la cantidad de registros en el archivo de indices.
 */
- (unsigned long) getIndexCount;

- (void) cutFile;

- (BOOL) findById: (char*) aFieldName value: (unsigned long) aValue;

- (BOOL) findFirstById: (char*) aFieldName value: (unsigned long) aValue;

- (BOOL) findFirstFromId: (char*) aFieldName value: (unsigned long) aValue;

- (BOOL) findNextByDateTime: (datetime_t) aFromDate
	toDate: (datetime_t) aToDate;

- (BOOL) findFirstByDateTime: (datetime_t) aFromDate 
	toDate: (datetime_t) aToDate;

@end

#endif
