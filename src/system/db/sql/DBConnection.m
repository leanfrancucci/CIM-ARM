#include "DBConnection.h"
#include "DBExcepts.h"
#include "SQLWrapper.h"
#include "SQLRecordSet.h"
#include "Transaction.h"

#define printd(args...) //doLog(0,args)
//#define printd(args...)

static DB_CONNECTION singleInstance = NULL;

@implementation DBConnection

/**/
+ new
{
	if (!singleInstance) singleInstance = [[super new] initialize];
	return singleInstance;	
}

/**/
- initialize
{
	char *serverName;
	char *dbName;
	char *userName;
	char *password;
	int errorCode;

	/// NO DEBERIA SACARLO DE UN ARCHIVO DE CONFIGURACION SINO QUE DEBERIA PASARSE POR PARAMETRO
	/// DE ESTA FORMA QUEDA MUY ACOPLADO

	serverName = [[Configuration getDefaultInstance] getParamAsString: "SQL_SERVER_NAME" default: "localhost"];
	dbName = [[Configuration getDefaultInstance] getParamAsString: "SQL_DB_NAME" default: "CT8016.GDB"];
	userName = [[Configuration getDefaultInstance] getParamAsString: "SQL_USER_NAME" default: "SYSDBA"];
  password = decryptFile("dbpass.ini");

  if (password == NULL)
  	password = [[Configuration getDefaultInstance] getParamAsString: "SQL_PASSWORD" default: "masterkey"];

	printd("DBConnection -> realizando conexion con base de datos %s in |%s|\n", dbName, serverName);
	errorCode = sqlConnectDatabase (serverName, dbName, userName, password);
	if (errorCode != 1) THROW_CODE(SQL_CONNECTION_EX, errorCode);
	printd("DBConnection -> Ready\n");

	return self;
}

/**/
+ getInstance
{
	return [self new];
}

/**/
- (ABSTRACT_RECORDSET) createRecordSetFromQuery: (char*) aQuery
{
	SQL_RECORD_SET recordSet;
	recordSet = [[SQLRecordSet new] initWithQuery: aQuery];
	return recordSet;
}

/**/
- (ABSTRACT_RECORDSET) createRecordSet: (char*) aTableName
{
	SQL_RECORD_SET recordSet;
	recordSet = [[SQLRecordSet new] initWithTableName: aTableName];
	return recordSet;
}

/**/
- (ABSTRACT_RECORDSET) createRecordSetWithFilter: (char*) aTableName filter: (char *) aFilter
{
	SQL_RECORD_SET recordSet;
	recordSet = [[SQLRecordSet new] initWithTableNameAndFilter: aTableName filter: aFilter];
	return recordSet;
}

/**/
- (ABSTRACT_RECORDSET) createRecordSetWithFilter: (char*) aTableName filter: (char *) aFilter orderFields: (char *) anOrderFields
{
	SQL_RECORD_SET recordSet;
	recordSet = [[SQLRecordSet new] initWithTableNameAndFilter: aTableName filter: aFilter orderFields: anOrderFields];
	return recordSet;
}

/**/
- (TRANSACTION) createTransaction
{
	return [Transaction new];
}

/**/
- (int) executeStatement: (char*) anStatement
{
  //doLog("DBConnection -> executeStatement = %s", anStatement);fflush(stdout);
  return sqlExecuteStatement(anStatement); 
}

- (int) executeStatement: (char*) anStatement transaction: (TRANSACTION) aTransaction
{
  //doLog("DBConnection -> executeStatement = %s", anStatement);fflush(stdout);
  return sqlExecuteInTransaction(anStatement); 
}

@end
