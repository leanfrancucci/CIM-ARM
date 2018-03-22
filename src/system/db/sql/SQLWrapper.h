#ifndef SQL_WRAPPER_H
#define SQL_WRAPPER_H

/**
 *	Tipos de datos SQL que retorna la libreria.
 */
typedef enum {
	// Reservado = 0
	// Reservado = 1
	 FBSQLType_DATE = 2	
	,FBSQLType_TIME
	,FBSQLType_TIMESTAMP
	,FBSQLType_STRING
	,FBSQLType_SMALL_INT
	,FBSQLType_INTEGER
	,FBSQLType_NUMERIC
	,FBSQLType_FLOAT
	,FBSQLType_DOUBLE
} FBSQLType;

/** 
 *	Es un Wrapper para las funciones de la libreria fbwrapc para adaptarla al standard de codificacion CT8016.
 *	Ademas es necesario un archivo .c para que el objective no incluya directamente el .h de la libreria.
 *	El .h de la libreria utiliza unos tags especiales para indicar el "calling convention" y al compilador de objective no 
 *	le gusta.
 */

int sqlConnectDatabase(char *ServerName, char *DbName, char *UserName, char *Password);

int sqlCreateDatabase(char *ServerName, char *DbName, char *UserName, char *Password, short WriteMode, int Dialect);

int sqlDisconnectDatabase();

int sqlExecuteStatement(char *ddlCommand);

char *sqlExecuteSelect(char *dmlCommand, int *retlen, int withMetadata);

void sqlSetDebug(int setdebug);

void sqlSetPageBuffers(short pb);

char *sqlGetPrimaryKeys(char *tableName);

char *sqlGetMetaData(char *tableName);

void sqlFree(char *p);

int sqlStartTransaction(void);

int sqlCommitTransaction(void);

int sqlRollbackTransaction(void);

int sqlExecuteInTransaction(char *ddlCommand);

#endif
