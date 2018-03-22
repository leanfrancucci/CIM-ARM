#ifndef SAFEBOX_RECORD_SET_H
#define SAFEBOX_RECORD_SET_H

#define SAFEBOX_RECORD_SET id

#include <Object.h>
#include "system/db/all.h"

/**
 *	Implementacion de recordset con acceso a la memoria de backup del SafeBox.
 *	Utiliza la clase SafeBoxHAL para acceder a las funciones.
 */
@interface SafeBoxRecordSet : AbstractRecordSet
{
	int  myCurrentRow;			// Registro actual
	BOOL myIsDirty;					// indica si el registro esta sucio, si esta modificado
	BOOL myIsNewRecord;			// indica si es un nuevo registro
	char *myBuffer;					// el buffer que contiene los datos de todos los registros
	int	 myFileId;					// Id de archivo con el hardware
	id		myTable;					// la tabla asociada
	int		myRecordSize;			// el tama�o del registro en cantidad de bytes
	Field *myFields;				// la definicion de los campos de la tabla
	int		myFieldCount;			// la cantidad de campos (columnas) de la tabla
	OMUTEX myMutex;					// el mutex para asegurar el acceso unico para lecturas/escrituras
	BOOL	myIsOpen;					// indica si el archivo fue o no abierto.
	char	myFileName[TABLE_FILE_NAME_SIZE];
	int 	myMaxRows;				// Maxima cantidad de registros que soporta
	char *myCurrentRowBuf;	// Buffer actual
	unsigned long myFileOffset;	// Offset inicial del archivo
	int	myUnitSize;					// Tamanio de la unidad
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
 *	Seteo por completo el buffer del RecordSet.
 */
- (void) setRecordBuffer: (char*) aBuffer;

/**
 *	Devuelvo por completo el buffer del RecordSet.
 */
- (char*) getRecordBuffer;

/**
 *	Recarga todos los registros desde el almacenamiento.
 */
- (void) reloadAllRecords;

/**
 *	Crea el archivo en la memoria, borrando toda la informacion existente.
 */
- (void) createFile;

/**
 *  Crea el archivo a partir del archivo pasado como parametro.
 *  Flash CT8016 -> Backup  
 */
- (void) createFileFrom: (char *) aFileName;

/**
 *  Copia hacia el archivo pasado como parametro.
 *  Backup ->  Flash CT8016
 */
- (void) copyFileTo: (char *) aFileName;

/**
 *  Copiar a partir del archivo pasado como parametro.
 *  Flash CT8016 -> Backup 
 */
- (void) copyFileFrom: (char *) aFileName;

/**
 *  Copiar a partir del archivo pasado como parametro.
 *  Flash CT8016 -> Backup 
 */
- (void) copyFileFrom: (char *) aFileName observer: (id) anObserver;

/**
 *
 */
- (void) writeRecordToFile;

/**
 * este metodo escribe directamente en la placa sin hacer uso del buffer de la tabla
 * se utiliza para evitar tener que hacer un open de una tabla con muchos registros
 * la cual demorara en cargarla en memoria. (caso particular de los usuarios cuando hay muchos)
 */
- (BOOL) updateRecordToFile: (unsigned long) anId recordBuffer: (char*) aRecordBuffer fieldName: (char*) aFieldName;

/**
 * este metodo escribe directamente en la placa sin hacer uso del buffer de la tabla
 * se utiliza para evitar tener que hacer un open de una tabla con muchos registros
 * la cual demorara en cargarla en memoria. (caso particular de los usuarios cuando hay muchos)
 */
- (BOOL) addRecordToFile: (unsigned long) anId recordBuffer: (char*) aRecordBuffer;

@end

#endif
