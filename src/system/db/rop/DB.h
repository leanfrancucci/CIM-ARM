#ifndef DB_H
#define DB_H

#include <Object.h>
#include "Table.h"
#include "system/lang/all.h"

#define DATABASE id
#define DATABASE_PATH_SIZE 100
#define DATABASE_FILE_NAME_SIZE (DATABASE_PATH_SIZE + 10)
#define DATABASE_NAME	"db.dat"

/**
 *	Es la clase que agrupa todas las tablas, una especie de base de datos.
 *	Inicializa el mecanismo de persistencia y crea los objetos de tipo Table, 
 *	para manejar el acceso a las tablas. Provee un método para obtener una tabla *
 *	particular de acuerdo al nombre de la misma.
 *	
 *	Es un Singleton.
 */
@interface DB : Object
{
	COLLECTION myTables;
	char	   	 myDataBasePath[DATABASE_PATH_SIZE];
	BOOL			 myStarted;
}

+ new;
- free;

/**
 *	Devuelve la unica instancia de DB que se puede crear.
 */
+ (id) getInstance;

/**
 *	Inicializa el mecanismo de persistencia ROP. 
 *	Crea las tablas de acuerdo al contenido de db.dat.
 */
- initialize;


/**
 *	Comienza el servicio de la base de datos. 
 *	Carga el esquema de base de datos en memoria.
 */
- (void) startService;

/**
 *	Seteo el path a la base de datos
 *	Debe finalizar con una barra invertida, por ejemplo: /persistence/
 *
 */
- (void) setDataBasePath: (char*) aDataBasePath;

/**
 *	Devuelve el path a la base de datos.
 *	Termina con una barra invertida, por ejemplo: /persistence/
 *
 */
- (const char*) getDataBasePath;

/**
 *	Devuelve la tabla correspondiente al nombre pasado como parametro.
 */
- (TABLE) getTable: (char*) aTableName;

/**
 *	Devuelve la tabla correspondiente al identificador de tabla pasado como parametro.
 */
- (TABLE) getTableById: (int) aTableId;

/**
 *	Crea una nueva tabla con el nombre de tabla y el esquema pasado como parametro.
 *	En primer lugar busca en su lista de tablas registradas si encuentra una que coincida y la devuelve.
 *	Sino, crea una nueva tabla y la registra en la base de datos.
 */
- (TABLE) createTableWithSchema: (char*) aTableName schema: (char*) aSchema;



- (COLLECTION) getTables;

@end

#endif
