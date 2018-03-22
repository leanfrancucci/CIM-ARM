#ifndef TABLE_H
#define TABLE_H

#define TABLE id

#include <Object.h>
#include "system/os/all.h"

#define TABLE_NAME_SIZE 25
#define FIELD_SIZE			40
#define	TABLE_FILE_NAME_SIZE	150

/**
 *	Contiene la informacion de un campo en particular de una tabla.
 */
typedef struct {
	char name[FIELD_SIZE];	/** nombre del campo */
	int  offset;		/** desplazamiento en bytes desde el comienzo del registro */
	int  type;			/** tipo de dato */
	int	 len;			  /** tama�o (en bytes) */
} Field;

/**
 *	El tipo de tabla.
 *	Single es una tabla con un solo archivo.
 *	Multi es una tabla MultiPart.
 */
typedef enum {
	ROP_TABLE_SINGLE,
	ROP_TABLE_MULTI
} ROPTableType;


/**
 *	Representa una tabla f�sica del sistema, cada tabla esta directamente asociada 
 *	a un archivo que contiene los datos almacenados. Existe una sola instancia de 
 *	Table para tipo de archivo (una instancia para el archivo de llamadas, una para 
 *	el archivo de usuarios, etc).
 *
 */
@interface Table : Object
{
	unsigned long myAutoIncValue;
	unsigned long myCount;
	char	 myTableName[TABLE_NAME_SIZE];
	char	 myFileName[TABLE_FILE_NAME_SIZE];
	Field  *myFields;
	int	   myFieldCount;
	Field	 *myAutoIncField;
	int		 myRecordSize;
	OMUTEX myMutex;
	ROPTableType myTableType;
	int		 myMaxFiles;
	int		 myRecordsByFile;
	int myTableId;
	int	myRecordCount;
	int	myFileId;
	char *myGlobalData;
	int myFileOffset;
	int myUnitSize;
	int myTableOrder; // campo que sera utilizado para el checkeo de backup
	BOOL myShouldClearOldData;
}

+ new;

/**
 *	Inicializa el objeto, creando todos los objetos necesarios.
 *	Metodo protected;
 */
- initialize;

/**
 *	Inicializa el objeto con el nombre de la tabla pasada como parametro.
 *	En base al nombre de la tabla, va a buscar el archivo de datos y el archivo que contiene
 *	el esquema (o formato) de la tabla. Por eso es muy importante si el nombre esta en mayusculas
 *	o minusculas. Por convencion todos los nombres de tabla van en minusculas al igual que el nombre
 *	de los archivos.
 */
- initWithTableNameAndType: (char*) aTableName type: (ROPTableType) aType ;

/**
 *	Inicializa el objeto con el nombre de la tabla pasada como parametro y el nombre del archivo
 *	de esquema (donde se encuentra la informacion del formato de la tabla).
 */
//- initWithTableNameAndSchema: (char*) aTableName schema: (char*) aSchema;
- initWithTableNameAndSchema: (char*) aTableName schema: (char*) aSchema type: (ROPTableType) aType;

- (void) setTableOrder: (int) aTableOrder;
- (int) getTableOrder;

- (void) setTableId: (int) aTableId;
- (int) getTableId;

- (void) setRecordsByFile: (int) aValue;
- (int) getRecordsByFile;

- (void) setMaxFiles: (int) aValue;
- (int) getMaxFiles;

- (BOOL) shouldClearOldData;
- (void) setShouldClearOldData: (BOOL) aValue;

/**
 *	Devuelve el Mutex asociado a la tabla.
 */
- (OMUTEX) getMutex;

/**
 *	Devuelve el tama�o de cada registro, en cantidad de bytes.
 */
- (int) getRecordSize;

/**
 *	Devuelve el conjunto de campos asociados a la tabla.
 */
- (Field*) getFields;

/**
 *	Devuelve la cantidad de campos asociados a la tabla.
 */
- (int) getFieldCount;

/** 
 *	Devuelve el campo que es autoincremental.
 */
- (Field*) getAutoIncField;

/**
 *	Devuelve el campo de acuerdo al nombre pasado como parametro.
 *	@throws FIELD_NOT_FOUND_EX si no encuentra el campo pasado como parametro.
 */
- (Field*) getField: (char*) aFieldName;

/**
 *	Devuelve el nombre de la tabla.
 */
- (char*) getName;

/**
 *	Devuelve el nombre del archivo que contiene la informacion.
 */	
- (char*) getFileName;
 
/**
 *	Devuelve el proximo valor autoincremental y lo aumenta en uno.
 */
- (unsigned long) autoIncValue;

/**
 *	Devuelve el valor autoincremental actual pero no lo modifica.
 */
- (unsigned long) getAutoIncValue;

/**
 *	Setea el valor autoincremental inicial, por defecto el valor autoincremental inicial es 1 (uno).
 */
- (void) setInitialAutoIncValue: (unsigned long) aValue;

/**
 *	Devuelve un nuevo RecordSet asociado a la tabla.
 */
- (id) getNewRecordSet;

/**
 *	Devuelve el tipo de tabla.
 */
- (ROPTableType) getTableType;

/**/
- (void) loadRecordCount;
- (void) setRecordCount: (unsigned long) aRecordCount;
- (unsigned long) getRecordCount;
- (void) incRecordCount;
- (void) decRecordCount;
/**/
- (void) loadAutoIncValue;


/**/
- (void) setFileId: (int) aFileId;
- (int) getFileId;

/**/
- (void) setGlobalData: (char *) aGlobalData;
- (char *) getGlobalData;

/**/
- (void) setFileOffset: (int) anOffset;
- (int) getFileOffset;

/**/
- (void) setUnitSize: (int) aUnitSize;
- (int) getUnitSize;

/**/
- (BOOL) hasBackup;

@end

#endif
