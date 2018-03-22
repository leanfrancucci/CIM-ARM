#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "SQLRecordSet.h"
#include "DBExcepts.h"
#include "SQLWrapper.h"
#include "SQLResultParser.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

// Esta macro chequea que la tabla sea editable, es decir, que sea una tabla y no una query
// En caso que no sea editable arroja una excepcion
#define CHECK_EDITABLE()	do { if (!myIsTable) THROW_MSG(INVALID_DB_OPERATION_EX, myQuery); } while (0)

// Chequea que exista el registro actual, caso contrario arroja una excepcion
#define CHECK_CURRENT_ROW() do {	if ([self getCurrentRow] == NULL) THROW_MSG(NO_CURRENT_RECORD_EX, myQuery); } while (0)

// Chequea que la table/query se encuentre abierta, caso contrario arroja una excepcion
#define CHECK_OPEN() do { if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myQuery); } while (0)

typedef struct {
  char tableName[255];
  BOOL hasGenerator;
} GeneratorCache;

typedef struct {
  char tableName[255];
  char *result;
} PrimaryKeyCache;

static COLLECTION _generatorsCache = NULL;
static COLLECTION _primaryKeyCache = NULL;

@implementation SQLRecordSet

/* private */
- (void) clearChangedValues;
- (char*) executeQuery: (char *) aQuery resultLen: (int*) aResultLen;
- (int) getFieldPosByName: (char*) aFieldName;

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{

  if (_generatorsCache == NULL) {
    _generatorsCache = [Collection new];
    _primaryKeyCache = [Collection new];
  }

	myQuery = NULL;
	myRows = [Collection new];
	myFields = [Collection new];
	myRecordSize  = 0;
	myCurrentRow = 0;
	myFetchOnOpen = TRUE;
	myIsTable = FALSE;
	stringcpy(myTableName, "");
  myUseGenerator = FALSE;
	myIsOpen = FALSE;
	myValueChanged = NULL;
	myDebug = FALSE;
	myCurrentRow = -1;	
  myTransaction = NULL;
	return self;
}

/**/
- (void) setTransaction: (TRANSACTION) aTransaction
{
	myTransaction = aTransaction;
}


/**/
- (void) setFetchOnOpen: (BOOL) aValue
{
	myFetchOnOpen = aValue;
}

/**/
- initWithQuery: (char*) aQuery
{
	myIsTable = FALSE;
	if (myQuery) free(myQuery);
	myQuery = strdup(aQuery);
	return self;
}

/**/
- initWithTableName: (char*) aTableName
{
  return [self initWithTableNameAndFilter: aTableName filter: ""];
}

/**/
- initWithTableNameAndFilter: (char*) aTableName filter: (char*) aFilter
{
	char query[512];

	if (myQuery) free(myQuery);
	stringcpy(myTableName, aTableName);
	myIsTable = TRUE;

	// Crea la query seleccionando todos los registros de la tabla pasada por parametro
	if (*aFilter=='\0')
    sprintf(query, "select * from %s", aTableName);
  else
    sprintf(query, "select * from %s where %s", aTableName, aFilter);

	myQuery = strdup(query);

	return self;
}

- initWithTableNameAndFilter: (char*) aTableName filter: (char*) aFilter orderFields: (char*) anOrderFields
{
	char query[512];
	char aux[256];

	if (myQuery) free(myQuery);
	stringcpy(myTableName, aTableName);
	myIsTable = TRUE;
	
	sprintf(query, "select * from %s", aTableName);
	
	if (*aFilter!='\0') {
	  sprintf(aux, " where %s", aFilter); 
    strcat(query, aux);
  }    
  
  if (*anOrderFields!='\0') {
    sprintf(aux, " order by %s", anOrderFields);
    strcat(query, aux);
  }
  
	myQuery = strdup(query);
	return self;  
}

/**/
- free
{
  [self close];

  [myRows freePointers];
  [myRows free];
  [myFields freePointers];
  [myFields free];

	if (myQuery) free(myQuery);
  if (myValueChanged) free(myValueChanged);

	return [super free];
}

/**/
- (void) setDebug: (BOOL) aValue
{
  myDebug = aValue;
}

/**/
- (char*) executeQuery: (char *) aQuery resultLen: (int*) aResultLen
{
  char *result;
  unsigned long ticks = getTicks();
  
	result = sqlExecuteSelect(aQuery, aResultLen, 1);
	if (result == NULL) THROW_MSG(SQL_QUERY_EX, aQuery);

  if (myDebug) {
   /* doLog(0,"--------------------------------------------------------\n");
    doLog(0,"query (exec time = %ld ms) = %s", getTicks()-ticks, aQuery);
    doLog(0,"--------------------------------------------------------\n");
    doLog(0,"executeQuery, resultLen = %d, results = \n%s\n", *aResultLen, result);
    doLog(0,"--------------------------------------------------------\n");
    fflush(stdout);*/
  }
    
  return result;
}

/**
 *  Busca si hay un generador asociado a la tabla.
 *  Esto se hace tomando la convencion de que el nombre del generador es 
 *  "GEN_" mas el nombre de la tabla, en otro caso no funciona porque busca
 *  en la metadata de la base de datos por ese criterio.
 */
- (void) hasGenerator 
{
  char sql[512];
  int resultLen;
  COLLECTION _fields;
  COLLECTION _rows;
  char *result;
  int i;
  GeneratorCache *generatorCache;

  // Me fijo en una pequena cache si ya se averiguo si existe el generator
  for (i = 0; i < [_generatorsCache size]; ++i) {
    generatorCache = (GeneratorCache*) [_generatorsCache at: i];
    if (strcasecmp(myTableName, generatorCache->tableName) == 0) { 
      myUseGenerator = generatorCache->hasGenerator;
      return;
    }
  }
  
  _fields = [Collection new];
  _rows = [Collection new];

  sprintf(sql, "select rdb$generators.rdb$generator_name FROM rdb$generators "
               "where upper(rdb$generators.rdb$generator_name)=upper('GEN_%s')", myTableName);

  result = [self executeQuery: sql resultLen: &resultLen];
 // if (myDebug) doLog(0,"hasGenerator result = %s, result len = %d\n", result, resultLen);
  
  if (result == NULL) THROW_MSG(SQL_INVALID_GENERATOR_EX, myTableName);

  parseXMLResults(result, strlen(result), _fields, _rows);

  if ([_fields size] != 1) {
  //  doLog(0,"results = |%s|\n", result);fflush(stdout);
    THROW_MSG(SQL_INVALID_GENERATOR_EX, myTableName);
  }

  myUseGenerator = ([_rows size] != 0);

  // Agrego el dato a la cache
  generatorCache = malloc(sizeof(GeneratorCache));
  strcpy(generatorCache->tableName, myTableName);
  generatorCache->hasGenerator = myUseGenerator;
  [_generatorsCache add: generatorCache];

  [_fields freePointers];
  [_rows freePointers];
  [_fields free];
  [_rows free];   

  free(result);
  
}

/**/
- (void) executeQuery
{
	char *result;
	int resultLen;

	[myFields freePointers];
	[myRows freePointers];
	
	printd("SQLRecordSet -> ejecutando query = \n%s\n----------------------------------------------------\n", myQuery);fflush(stdout);
	result = [self executeQuery: myQuery resultLen: &resultLen];
	printd("SQLRecordSet -> query ejecutada, bytes retonados = %d\n", resultLen);fflush(stdout);

	// Parsea los resultados de la query, en myFields devuelve la coleccion de campos y
	// en myRows las filas o registros resultado de la consulta.
	parseXMLResults(result, resultLen, myFields, myRows);
	assert(myFields);
	assert(myRows);

	if (myValueChanged) free(myValueChanged);
	myValueChanged = malloc(sizeof(BOOL) * [myFields size]);

	printd("SQLRecordset -> Cantidad de campos = %d, cantidad de registros = %d\n", [myFields size], [myRows size]);fflush(stdout);
	myCurrentRow = -1;

	free(result);
}

/**
 *  Obtiene el id para el generador configurado.
 *  Envia una query a la base de datos pidiendo el proximo generador.
 *  Luego analiza el resultado y devuelve el valor del generador.
 */
- (unsigned long) genId
{
  char sql[255];
  char *result;
  int resultLen;
  COLLECTION _fields;
  COLLECTION _rows;
  unsigned long gen = 0;
  char *row;

  _fields = [Collection new];
  _rows = [Collection new];

  sprintf(sql, "SELECT cast(gen_id(GEN_%s, 1) as integer) as NEXT_ID FROM RDB$DATABASE", myTableName);
  result = [self executeQuery: sql resultLen: &resultLen];
//  if (myDebug) doLog(0,"genId result = %s\n", result);
  if (result == NULL) THROW_MSG(SQL_INVALID_GENERATOR_EX, myTableName);

  parseXMLResults(result, strlen(result), _fields, _rows);

  if ([_rows size] != 1) THROW_MSG(SQL_INVALID_GENERATOR_EX, myTableName);
  if ([_fields size] != 1) THROW_MSG(SQL_INVALID_GENERATOR_EX, myTableName);

  row = (char*)[_rows at: 0];
  memcpy(&gen, row, 4);

  [_fields freePointers];
  [_rows freePointers];
  [_fields free];
  [_rows free];   

  free(result);
  return gen;
}

/**/
- (void) getPrimaryKeys
{
  char *result;
  int i;
  PrimaryKeyCache *pkCache;

  assert(*myTableName!=0);

  // Verifico si ya tengo las primary key en la cache
  for (i = 0; i < [_primaryKeyCache size]; ++i) {
    pkCache = (PrimaryKeyCache*)[_primaryKeyCache at: i];
    if (strcasecmp(pkCache->tableName, myTableName) == 0) {
      parsePrimaryKeys(pkCache->result, strlen(pkCache->result), myFields);
      return;
    }
  }

  result = sqlGetPrimaryKeys(myTableName);
 // if (myDebug) doLog(0,"primary key result = %s\n", result);
  if (result == NULL) THROW_MSG(SQL_INVALID_PRIMARY_KEY_EX, myTableName);

  // Pongo las primary key en la cache
  pkCache = malloc(sizeof(PrimaryKeyCache));
  strcpy(pkCache->tableName, myTableName);
  pkCache->result = strdup(result);
  [_primaryKeyCache add: pkCache];
 
  parsePrimaryKeys(result, strlen(result), myFields);
  free(result);  
}

/**/
- (void) getMetaData
{
  char *result;
  char sql[512];
  int resultLen;
  
  assert(*myTableName!=0);

//  sprintf(sql, "select * from %s where 0=1", myTableName);  
  sprintf(sql, "select first 0 * from %s", myTableName); 
//  result = sqlGetMetaData(myTableName);
  result = [self executeQuery: sql resultLen: &resultLen];
  
 // if (myDebug) doLog(0,"metadata result = %s\n", result);
  if (result == NULL) THROW_MSG(SQL_INVALID_META_DATA_EX, myTableName);
  parseXMLResults(result, strlen(result), myFields, NULL); // myRows no se utiliza
  
	if (myValueChanged) free(myValueChanged);
	myValueChanged = malloc(sizeof(BOOL) * [myFields size]);
  
  free(result);  
}


/**/
- (void) open
{
  // Si tiene una query definida que debe ser consultada cuando abre el recordset tiro la consulta
	if (myQuery && myFetchOnOpen) [self executeQuery];
	
	// Si es una tabla y no la abre al comienzo es conveniente consultar los metadatos por si
  // quiere insertar, modificar un registro 
	if (myIsTable && !myFetchOnOpen) [self getMetaData];
	
	// Si es una tabla, obtengo las primary keys
  // y si hay un generador asociado a la tabla
	if (myIsTable) {
    [self getPrimaryKeys];
    [self hasGenerator];
  }	

	myIsOpen = TRUE;
	[self clearChangedValues];
}

/**/
- (void) close
{
  if (!myIsOpen) return;
	[myFields freePointers];
	[myRows freePointers];
}

/**/
- (BOOL) moveFirst
{
	myCurrentRow = 0;
	[self clearChangedValues];
  if ([self getRecordCount] == 0) return FALSE;
	return TRUE;
}

/**/
- (BOOL) moveBeforeFirst
{
	myCurrentRow = -1;
	[self clearChangedValues];
	return TRUE;
}

/**/
- (BOOL) moveAfterLast
{
	myCurrentRow = [myRows size];
	[self clearChangedValues];
	return TRUE;
}

/**/
- (BOOL) moveNext
{
	int count = [myRows size];
	[self clearChangedValues];
  if ([self getRecordCount] == 0) return FALSE;
	if (count == 0 || myCurrentRow >= (count)) return FALSE;
	myCurrentRow++;
	if (myCurrentRow >= (count)) return FALSE;
	return TRUE;
}

/**/
- (BOOL) movePrev
{
	[self clearChangedValues];
  if ([self getRecordCount] == 0) return FALSE;
	myCurrentRow--;
	if (myCurrentRow < 0) return FALSE;
	return TRUE;
}

/**/
- (BOOL) moveLast
{
  if ([self getRecordCount] == 0) return FALSE;	
  [self clearChangedValues];
	myCurrentRow = [myRows size]-1;
  if (myCurrentRow == -1) return FALSE;
	return TRUE;
}

/**/
- (void) seek: (int) aDirection offset: (int) anOffset
{
	int row;
	[self clearChangedValues];

	if (aDirection == SEEK_END) row = [myRows size] - anOffset - 1;
	else if (aDirection == SEEK_SET) row = anOffset;
	else row = myCurrentRow - anOffset;

	if (row < -1 || row > [myRows size]) THROW(INVALID_SEEK_EX);

	myCurrentRow = row;
}

/**/
- (SQLField *) getFieldByName: (char*) aFieldName
{
	int i;
	int count = [myFields size];

	for (i = 0; i < count; ++i) 
		if (strcasecmp(((SQLField*)[myFields at: i])->fieldName, aFieldName) == 0) 
			return (SQLField*)[myFields at: i];

	THROW_MSG(FIELD_NOT_FOUND_EX, aFieldName);
  
	return NULL;
}

/**/
- (int) getFieldPosByName: (char*) aFieldName
{
	int i;
	int count = [myFields size];

	for (i = 0; i < count; ++i) 
		if (strcasecmp(((SQLField*)[myFields at: i])->fieldName, aFieldName) == 0) 
			return i;

  //doLog(0,"query = |%s|\n", myQuery); fflush(stdout);
	THROW_MSG(FIELD_NOT_FOUND_EX, aFieldName);

	return 0;
}
/**/
- (char *) getCurrentRow
{
	if (myCurrentRow >= [myRows size]) return NULL;
	return (char*)[myRows at: myCurrentRow];
}

/**/
- (void) setValue: (char*)aFieldName value:(char*)aValue len:(int)aLen
{
	SQLField *field;
	char *row;
	int fieldPos;

	CHECK_EDITABLE();
	CHECK_CURRENT_ROW();

	row = [self getCurrentRow];
	fieldPos = [self getFieldPosByName: aFieldName];
	field = (SQLField*)[myFields at: fieldPos];

	// Se cambio el valor del registro
	myValueChanged[fieldPos] = TRUE;

	if (field->fieldType == SQLType_STRING) {
		aLen = (aLen < field->fieldSize && aLen != -1) ? aLen : field->fieldSize-1;
		strncpy2(row + field->fieldOffset, aValue, aLen);
	}	else {
		aLen = (aLen < field->fieldSize && aLen != -1) ? aLen : field->fieldSize;
		//if (aLen != field->fieldSize) doLog(0, "Warning: field size does not match, field %s, size (argument) %d, field size %d\n", aFieldName, aLen, field->fieldSize);
		memcpy(row + field->fieldOffset, aValue, aLen);
	}

}


/**/
- (void) getValue: (char*)aFieldName value:(char*)aValue
{
	SQLField *field;
	char *row;

	CHECK_OPEN();
	CHECK_CURRENT_ROW();

	row = [self getCurrentRow];
	if (row == NULL) THROW_MSG(NO_CURRENT_RECORD_EX, myQuery);

	field = [self getFieldByName: aFieldName];

	/** @todo: realizar controles necesarios */
	memcpy(aValue, row + field->fieldOffset, field->fieldSize);					

}

/**/
- (void) setStringValue: (char*) aFieldName value: (char*) aValue
{
	[self setValue: aFieldName value:aValue len: strlen(aValue)];
}

/**/
- (void) setCharArrayValue: (char*) aFieldName value: (char*) aValue
{
	[self setValue: aFieldName value:aValue len: -1];
}

/**/
- (void) setCharValue: (char*) aFieldName value: (char)aValue
{
  SQLField *field = [self getFieldByName: aFieldName];
  
  // Si es un long, llamo a setLongValue 
  if (field->fieldSize == 4) {
    long l = aValue;
    [self setLongValue: aFieldName value: l];
  } else if (field->fieldSize == 2) {
    short s = aValue;
    [self setShortValue: aFieldName value: s];
  }
  else
    [self setValue: aFieldName value:(char*)&aValue len: sizeof(char)];
}

/**/
- (void) setShortValue: (char*) aFieldName value: (short)aValue
{
  SQLField *field = [self getFieldByName: aFieldName];
  
  // Si es un long, llamo a setLongValue 
  if (field->fieldSize == 4) [self setLongValue: aFieldName value: aValue];
  else
	 [self setValue: aFieldName value:(char*)&aValue len: sizeof(short)];
}

/**/
- (void) setLongValue: (char*) aFieldName value: (long)aValue
{
	[self setValue: aFieldName value:(char*)&aValue len: sizeof(long)];
}

/**/
- (void) setDateTimeValue: (char*) aFieldName value: (datetime_t)aValue
{
	[self setValue: aFieldName value:(char*)&aValue len: sizeof(datetime_t)];
}

/**/
- (void) setMoneyValue: (char*) aFieldName value: (money_t)aValue
{
	[self setValue: aFieldName value:(char*)&aValue len: sizeof(money_t)];
}

/**/
- (void) setBoolValue: (char*) aFieldName value: (BOOL) aValue
{
  char v = aValue;
  printd("set bool value to %d, %d", aValue, v);fflush(stdout);
	[self setCharValue: aFieldName value: v];	
}

/**/
- (char*) getStringValue: (char*) aFieldName buffer: (char*)aBuffer
{
	[self getValue: aFieldName value: aBuffer];
//	printd("getStringValue (%s->%s) = %s\n", [self getName], aFieldName, aBuffer);
	return aBuffer;
} 

/**/
- (char*) getCharArrayValue: (char*) aFieldName buffer: (char*)aBuffer
{
	[self getValue: aFieldName value: aBuffer];
//	printd("getCharArrayValue (%s->%s) = %s\n", [self getName], aFieldName, aBuffer);
	return aBuffer;
}

/**/
- (char) getCharValue: (char*) aFieldName
{
	short n = 0;
	[self getValue: aFieldName value: (char*)&n];
//	printd("getCharValue (%s->%s) = %d\n", [self getName], aFieldName, n);
	return (char)n;
}

/**/
- (short) getShortValue: (char*) aFieldName
{
	short n;
	[self getValue: aFieldName value: (char*)&n];
//	printd("getShortValue (%s->%s) = %d\n", [self getName], aFieldName, n);
	return n;
}

/**/
- (long) getLongValue: (char*) aFieldName
{
	long n;
	[self getValue: aFieldName value: (char*)&n];
//	printd("getLongValue (%s->%s) = %ld\n", [self getName],aFieldName, n);
	return n;
}

/**/
- (datetime_t) getDateTimeValue: (char*) aFieldName
{
	datetime_t n;
	[self getValue: aFieldName value: (char*)&n];
//	printd("getDateTimeValue (%s->%s) = %ld\n", [self getName], aFieldName, n);
	return n;
}

/**/
- (money_t) getMoneyValue: (char*) aFieldName
{
	money_t m;
	[self getValue: aFieldName value: (char*)&m];
	return m;
}

/**/
- (BOOL) getBoolValue: (char*) aFieldName
{
	char c;
  c = [self getCharValue: aFieldName];
  return c;
}

/**/
- (char*) getBcdValue: (char*) aFieldName buffer: (char*) aBuffer
{
  return [self getStringValue: aFieldName buffer: aBuffer];
}

/**/
- (void) setBcdValue: (char*) aFieldName value: (char*) aValue
{
  [self setStringValue: aFieldName value: aValue];
}

/**/
- (void) add
{
	char *newRow;
  int len;

	CHECK_OPEN();
	CHECK_EDITABLE();

	[self clearChangedValues];

	// Agrego un nuevo registro
  len = [self getRecordSize];
	newRow = malloc(len);
  memset(newRow, 0, len);
	[myRows add: newRow];

	// Me paro en el nuevo registro recien agregado
	[self moveLast];
	myIsNewRecord = TRUE;
}

/**/
- (void) clearChangedValues
{
	int i;
	CHECK_OPEN();
	assert(myValueChanged);
	for (i = 0; i < [myFields size]; ++i) myValueChanged[i] = FALSE;
}

/**/
- (void) getValueAsString: (SQLField *) field buffer: (char*) aBuffer
{
	long lvalue;
  short svalue;
	datetime_t dtvalue;
	struct tm bt;

	switch (field->fieldType) {
		case SQLType_INTEGER:
		case SQLType_AUTOINC:
		case SQLType_BOOL:
		case SQLType_CHAR:
			if (field->fieldType == SQLType_INTEGER && field->fieldSize == 2) {
        svalue = 0;
			  [self getValue: field->fieldName value: (char*)&svalue];
			  sprintf(aBuffer, "%d", svalue);
      } else { 
        lvalue = 0;
			  [self getValue: field->fieldName value: (char*)&lvalue];
			  sprintf(aBuffer, "%ld", lvalue);
      }
			break;

		case SQLType_MONEY:
			formatMoney(aBuffer, "", [self getMoneyValue: field->fieldName], 6, 512);
			break;

		case SQLType_STRING:
			[self getStringValue: field->fieldName buffer: aBuffer];
			break;

		case SQLType_DATETIME:
			// YYYY-MM-DD hh:mm:ss
			dtvalue = [self getDateTimeValue: field->fieldName];
			gmtime_r(&dtvalue, &bt);
			sprintf(aBuffer, "%04d-%02d-%02d %02d:%02d:%02d", bt.tm_year + 1900, bt.tm_mon + 1, bt.tm_mday, bt.tm_hour, bt.tm_min, bt.tm_sec);
			break;

	}

}

/**
 *	Devuelve en el buffer pasado por parametro un string SQL con los campos que son primary key y sus valores
 *	separados por AND, para concatenarlo a una sentencia SQL.
 */
- (char *) getPrimaryKeySQL: (char *) aBuffer
{
	int i;
	char value[512];
	SQLField *field;

	strcpy(aBuffer, "");

	for (i = 0; i < [myFields size]; ++i) {
		field = (SQLField*)[myFields at: i];
	//	if (myDebug) doLog(0,"field %s is pk = %d\n", field->fieldName, field->fieldIsPK);
		if (!field->fieldIsPK) continue;
		[self getValueAsString: field buffer: value];
		strcat(aBuffer, "\"");
		strcat(aBuffer, field->fieldName);
		strcat(aBuffer, "\"='");
		strcat(aBuffer, value);
		strcat(aBuffer, "' and ");
	}

	// Quito el ultimo and
	if (strlen(aBuffer) != 0) aBuffer[strlen(aBuffer)-4] = '\0';

	return aBuffer;
}

/**/
- (void) executeStatement: (char *) aQuery
{
	int errorCode;
	
	if (myDebug) {
    //doLog(0,"query a ejecutar (transaction=%d)= |%s|\n\n", myTransaction != NULL, aQuery);
    fflush(stdout);
  }

  if (myTransaction != NULL) {
    errorCode = sqlExecuteInTransaction(aQuery);
  } else {
    errorCode = sqlExecuteStatement(aQuery);
  }

	if (errorCode == 0) {
		//doLog(0,"Error al ejecutar la query |%s|\n", aQuery);
		THROW_MSG(SQL_QUERY_EX, myQuery);
	}
}

/**/
- (void) delete
{
	char sql[1024];
	char pk[512];

	CHECK_OPEN();
	CHECK_EDITABLE();
	CHECK_CURRENT_ROW();
	
	[self getPrimaryKeySQL: pk];
	if (strlen(pk) == 0) THROW_MSG(NO_PRIMARY_KEY_EX, myTableName);
	sprintf(sql, "delete from %s where %s", myTableName, pk);
  
//  doLog(0,"Ejecutando query = |%s|\n", sql);

	// Ejecuto la query
	[self executeStatement: sql];

	free([myRows at: myCurrentRow]);
	[myRows removeAt: myCurrentRow];

	// Si estoy parado en el ultimo registro, me voy uno antes
	if ([self eof]) myCurrentRow--;

	myIsNewRecord = FALSE;
	[self clearChangedValues];
}

/**/
- (SQLField *) getIdentityField
{
  int i;
  for (i = 0; i < [myFields size]; ++i) {
    if (((SQLField*)[myFields at: i])->fieldIsPK) 
      return (SQLField*)[myFields at: i];
  }
  return NULL;
}

/**/
- (unsigned long) insert
{
	char sql[1024];
	char columns[1024];
	char value[512];
	int  i;
	SQLField *field;
  SQLField *identityField;
  unsigned long genId = 0;

	/** @todo: controlar el maximo tamano para no sobrepasar los string */
	/** @todo: que pasa si no hay ningun campo modificado ? */

  // Tiene un generador asociado tengo que utilizarlo
  if (myUseGenerator) {
    genId = [self genId];
    identityField = [self getIdentityField];
    THROW_NULL(identityField);
    [self setLongValue: identityField->fieldName value: genId];
  }

	strcpy(columns, "");
	sprintf(sql, "insert into %s(", myTableName);

	// Concateno las columnas 
	for (i = 0; i < [myFields size]; ++i) {
		if (!myValueChanged[i]) continue;
		field = (SQLField*)[myFields at: i];
		strcat(columns, "\"");
		strcat(columns, field->fieldName);
		strcat(columns, "\",");
	}

	// Quito la ultima coma
	if (strlen(columns) != 0) columns[strlen(columns)-1] = '\0';
	strcat(sql,columns);
	strcat(sql, ") values (");

	// Concateno los valores
	strcpy(columns, "");
	for (i = 0; i < [myFields size]; ++i) {
		if (!myValueChanged[i]) continue;
		field = (SQLField*)[myFields at: i];
		[self getValueAsString: field buffer: value];
		strcat(columns, "'");
		strcat(columns, value);
		strcat(columns, "',");
	}

	// Quito la ultima coma
	if (strlen(columns) != 0) columns[strlen(columns)-1] = '\0';
	strcat(sql,columns);
	strcat(sql, ")");

	// Ejecuto la query
	[self executeStatement: sql];

  return genId;
}

/**/
- (unsigned long) update
{
	char sql[1024];
	char columns[1024];
	char value[512];
	char pk[512];
	int  i;
	SQLField *field;
  unsigned long result = 0;
  SQLField *identityField;

	/** @todo: controlar el maximo tamano para no sobrepasar los string */
	/** @todo: que pasa si no hay ningun campo modificado ? */

	strcpy(columns, "");
	sprintf(sql, "update %s set ", myTableName);
	[self getPrimaryKeySQL: pk];
	if (strlen(pk) == 0) THROW_MSG(NO_PRIMARY_KEY_EX, myTableName);

	// Concateno las columnas 
	// column=value,
	for (i = 0; i < [myFields size]; ++i) {
		if (!myValueChanged[i]) continue;
		field = (SQLField*)[myFields at: i];
		strcat(columns, "\"");
		strcat(columns, field->fieldName);
		strcat(columns, "\"=");
		[self getValueAsString: field buffer: value];
		strcat(columns, "'");
		strcat(columns, value);
		strcat(columns, "',");
	}

	// Quito la ultima coma
	if (strlen(columns) != 0) columns[strlen(columns)-1] = '\0';
	strcat(sql,columns);

	// Aca viene el where con las PK
	strcat(sql, " where ");
	strcat(sql, pk);

	// Ejecuto la query
	[self executeStatement: sql];

  // Si tenia un generador asociado devuelvo el valor
  if (myUseGenerator) {
    identityField = [self getIdentityField];
    THROW_NULL(identityField);
    result = [self getLongValue: identityField->fieldName];
  //  if (myDebug) doLog(0,"resultado de la tabla %s = %ld\n", myTableName, result);
  }

  return result;
}

/**/
- (unsigned long) save
{
  unsigned long genId = 0;
	CHECK_OPEN();
	CHECK_EDITABLE();
	CHECK_CURRENT_ROW();

	if (myIsNewRecord) genId = [self insert];
	else genId = [self update];

	myIsNewRecord = FALSE;
	[self clearChangedValues];

	return genId;
}

/**/
- (BOOL) eof
{ 
	CHECK_OPEN();
	return (myCurrentRow >= [myRows size]) || ([myRows size] == 0);
}

/**/
- (BOOL) bof
{
	CHECK_OPEN();
	return (myCurrentRow < 0) || ([myRows size] == 0);
}

/**/
- (unsigned long) getRecordCount
{
	CHECK_OPEN();
	return [myRows size];
}

/**/
- (int) getRecordSize
{
	int i;
	int size = 0;

	CHECK_OPEN();

	for (i = 0; i < [myFields size]; ++i)
		size += ((SQLField*)[myFields at: i])->fieldSize;

	return size;
}

- (BOOL) binarySearch: (char*) aFieldName value: (unsigned long) aValue
{
	long high = [self getRecordCount] - 1;
	long low = 0, middle;
	unsigned long value;
	SQLField *field;
	
	CHECK_OPEN();

	if (high == -1) return FALSE;
	
	field = [self getFieldByName: aFieldName];

	while( low <= high ) {
		middle = ( low  + high ) / 2;
		value = 0;

		[self seek: SEEK_SET offset: middle];
		[self getValue: aFieldName value: (char*)&value];
		
		if ( value == aValue ) 
			return TRUE;
		else if( aValue < value )
			high = middle - 1;	//search low end of array
		else
			low = middle + 1;		//search high end of array
	}

	return FALSE;  //search key not found
}

/**/
- (BOOL) findById: (char*) aFieldName value: (unsigned long) aValue
{
	CHECK_OPEN();
	return [self binarySearch: aFieldName value: aValue];
}

/**/
- (BOOL) findFirstById: (char*) aFieldName value: (unsigned long) aValue
{
	unsigned long value = -1;
	CHECK_OPEN();

	if (![self binarySearch: aFieldName value: aValue]) return FALSE;

	while ( [self movePrev] ) {
		value = 0;
		[self getValue: aFieldName value: (char*)&value];
		if ( value != aValue ) break; 
	}
//  if (hasMoved)
	//if ( value != aValue && value != -1) [self moveNext];
  // No me gusta para nada que el movePrev si estas parado en el primer
  // registro te devuelva FALSE pero te lo mueva al -1, es feo, por eso
  // aca siempre hago un moveNext
  [self moveNext];
	return TRUE;
}


/**/
- (char*) getName
{
	return myTableName;
}

/**/
- (int) getTableId
{
	THROW(ABSTRACT_METHOD_EX);
	return -1;
}

/**/
- (long) getCurrentPos
{
	return myCurrentRow;
}

/**/
- (void) setAutoFlush: (BOOL) aValue
{
	myAutoFlush = aValue;
}

/**/
- (void) flush
{
	// Nada que hacer
}

/**/
- (void) showMetaData
{
  int i;
  SQLField *field;
  static char *fieldTypes[] = {"INTEGER", "STRING", "CHAR", "DATETIME", "MONEY", "BOOL", "AUTOINC"};

  //doLog(0,"Table name: %s\n", myTableName);
  //doLog(0,"Use generator: %s\n", myUseGenerator ? "YES": "NO");

  for (i = 0; i < [myFields size]; ++i) {

    
    field = (SQLField*)[myFields at: i];
    //doLog(0,"--------------------------------------------\n");
    //doLog(0,"Name = %s\n", field->fieldName);
    //doLog(0,"Size = %d\n", field->fieldSize);
    //doLog(0,"Offset = %d\n", field->fieldOffset);
    //doLog(0,"Type = %s\n", fieldTypes[field->fieldType]);
    //doLog(0,"Scale = %d\n", field->fieldScale);
    //doLog(0,"fieldIsPk = %s\n", field->fieldIsPK ? "YES": "NO");
    fflush(stdout);

  }

}

/**/
- (void) deleteAll
{
  char sql[128];

	CHECK_OPEN();
	CHECK_EDITABLE();

  /** @todo: probar este metodo */
  [self close];

  sprintf(sql, "delete from %s", myTableName);
  [self executeStatement: sql];
  
  [self open];  
}

@end
