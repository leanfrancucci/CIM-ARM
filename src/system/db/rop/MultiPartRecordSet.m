/** @todo: Implementar el SEEK, por ahora esta el SEEK_SET unicamente implementado, falta el SEEK_CUR y
    el SEEK_END. */
		
#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include "MultiPartRecordSet.h"
#include "DBExcepts.h"
#include "roputil.h"
#include "DB.h"
#include "util.h"
#include "util/endian.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

#define INDEX_SUFFIX							"_index"
#define DEFAULT_MAX_RECORD_COUNT	200
#define DEFAULT_ID_FIELD					"ID"
#define DEFAULT_DATE_FIELD				"DATE"


@implementation MultiPartRecordSet

- (id) createDataTable: (int) aTableId;
- (void) openDataTable: (int) aTableNumber;
- (void) readCurrentData;
- (const char*) appendFile;
- (void) clearOldExcededData;

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myIsDirty = FALSE;
	myIsNewRecord = FALSE;
	myRecordSize = 0;
	myCurrentTableNumber = -1;
	myMaxRecordCount = DEFAULT_MAX_RECORD_COUNT;
	myAutomaticPartition = TRUE;
	myAppendFileMode = FALSE;
	myTransaction = NULL;
	strcpy(myDateField, DEFAULT_DATE_FIELD);
	strcpy(myIdField, DEFAULT_ID_FIELD);
	myMaxFiles = -1;
	myAutoFlush = TRUE;
	myDataRecordSet = NULL;
	myIndexRecordSet = NULL;
	myShouldCutFile = FALSE;
	return self;
}


/**/
- free
{
	[self close];
	free(myBuffer);
	[myDataRecordSet free];
	[myIndexRecordSet free];
	return [super free];
}


/**/
- initWithTableName: (char*) aTableName
{
	strcpy(myTableName, aTableName);
	return self;
}


/**/
- (id) getTable
{
	return [myDataRecordSet getTable];
}

/**/
- (void) setTransaction: (TRANSACTION) aTransaction
{
	myTransaction = aTransaction;
}

/**/
- (int) getTableId
{
	TABLE table = [[DB getInstance] getTable: myTableName];
	return [table getTableId]; 
}

/**/
- (BOOL) shouldCutFile
{
	return myShouldCutFile;
}

/**/
- (void) setShouldCutFile: (BOOL) aValue
{
	myShouldCutFile = aValue;
}

/**/
- (int) getPartNumber
{
	return myCurrentTableNumber + 1;
}

/**/
- (void) open
{
	DATABASE db = [DB getInstance];
	TABLE dataTable;
	char indexTableName[TABLE_NAME_SIZE];
	char dataTableName[TABLE_NAME_SIZE];

	printd("MultiPartRecordSet --> aTableName = %s\n", myTableName);
		
	//concateno al nombre de la tabla el prefijo "_index" para hacer referencia a la tabla de indices
	strcpy(indexTableName, myTableName);
	strcat(indexTableName, INDEX_SUFFIX);
	
	[[DB getInstance] createTableWithSchema: indexTableName schema: indexTableName];
	
	//creo el RecordSet de indices
	myIndexRecordSet = [[RecordSet new] initWithTableName: indexTableName];
	[myIndexRecordSet open];
	[myIndexRecordSet moveBeforeFirst];
	printd("MultiPartRecordSet --> Index RecordSet created\n");
	
	//recupero el nombre de la primera tabla, si no hay ninguna, creo una con sufijo "_0"
	if (![myIndexRecordSet moveNext]) {
		printd("MultiPartRecordSet --> No index data\n");
		strcpy(dataTableName, myTableName);
		strcat(dataTableName, "_0");
	} else {
		[myIndexRecordSet getStringValue: "TABLE_NAME" buffer: dataTableName];
		printd("MultiPartRecordSet --> Data table name is %s\n", dataTableName);
	}

	//trato de recuperar la tabla de la base de datos, si no existe la creo y la registro.
	dataTable = [db createTableWithSchema: dataTableName schema: myTableName];

	//creo el RecordSet de manejo de datos
	myDataRecordSet = [[RecordSet new] initWithTable: dataTable];
	[myDataRecordSet setAutoFlush: myAutoFlush];
	
	myFields = [[myDataRecordSet getTable] getFields];
	myFieldCount = [[myDataRecordSet getTable] getFieldCount];
	myRecordSize = [[myDataRecordSet getTable] getRecordSize];
	myMaxRecordCount = [[[DB getInstance] getTable: myTableName] getRecordsByFile];
	myMaxFiles = [[[DB getInstance] getTable: myTableName] getMaxFiles];
	myBuffer = malloc(myRecordSize);
	printd("MultiPartRecordSet --> Setting buffer of %d bytes\n", myRecordSize);
	myCurrentTableNumber = 0;
	[myDataRecordSet open];
	[myDataRecordSet moveBeforeFirst];

	// verifico si debo eliminar datos viejos que ya exceden la cantidad de archivos
	// solo lo hago la primera vez al arranque del equipo para cada tabla multi.
	if ([[[DB getInstance] getTable: myTableName] shouldClearOldData]) {
		[[[DB getInstance] getTable: myTableName] setShouldClearOldData: FALSE];
		[self clearOldExcededData];
	}

}

/**/
- (void) clearOldExcededData
{
	char name[TABLE_NAME_SIZE];
	TABLE dataTable;
	int fileCount, maxFiles, fileCountToDelete, i;

	fileCount = [myIndexRecordSet getRecordCount];
	maxFiles = [[[DB getInstance] getTable: myTableName] getMaxFiles];

	if (fileCount > maxFiles) {

		// calculo la cantidad de tablas a eliminar
		fileCountToDelete = fileCount - maxFiles;

		// elimino la cantidad de tablas sobrantes
		[myIndexRecordSet moveBeforeFirst];
		for (i = 0; i < fileCountToDelete; i++) {
			if ([myIndexRecordSet moveFirst]) {
				[myIndexRecordSet getStringValue: "TABLE_NAME" buffer: name];
				[myIndexRecordSet delete];
	
				if (myDataRecordSet) [myDataRecordSet close];
				dataTable = [[DB getInstance] createTableWithSchema: name schema: myTableName];
	
		/*		doLog(0,"-----> ELIMINO EL ARCHIVO %s <-----\n", name);
				if (unlink([dataTable getFileName]) != 0)
					doLog(0,"Error: no se pudo eliminar el archivo %s\n", name);*/
			}
		}

		[myDataRecordSet open];
		[myDataRecordSet moveBeforeFirst];
	}

}

/**/
- (void) close
{
	[myDataRecordSet close];
	[myIndexRecordSet close];
}


/**/
- (BOOL) moveFirst
{
	// Si no hay ningun registro, no tiene sentido hacer esto
	if ([myIndexRecordSet getRecordCount] == 0) return FALSE;

	if ( myCurrentTableNumber != 0 ) {
		[self openDataTable: 0];
	}

	[myDataRecordSet moveFirst];
	[self readCurrentData];

	return TRUE;
}


/**/
- (BOOL) moveBeforeFirst
{
	if ( myCurrentTableNumber != 0 ) [self openDataTable: 0];
	return [myDataRecordSet moveBeforeFirst];
}


/**/
- (BOOL) moveNext
{
	if ( [myDataRecordSet moveNext] ) {
		[self readCurrentData];
	} else {
		//si es el ultimo archivo, arrojo una excepcion

		/** @todo: revisar esta condicion, se agrego porque arrojaba una excepcion
		    NO_CURRENT_RECORD_EX en ciertos casos */
		if ( [myIndexRecordSet getRecordCount] == 0 ) return FALSE;
		
		if ( myCurrentTableNumber >= [myIndexRecordSet getRecordCount] -1 ) return(FALSE);
		
		[self openDataTable: myCurrentTableNumber+1];

		[myDataRecordSet moveBeforeFirst];

		if (![myDataRecordSet moveNext]) return FALSE;

		[self readCurrentData];
	}
	return (TRUE);
}


/**/
- (BOOL) movePrev
{
	if ( [myDataRecordSet movePrev] ) {
		[self readCurrentData];
	}	else {
		//si es el primer archivo, devuelvo false
		if ( myCurrentTableNumber == 0 ) return FALSE;
		[self openDataTable: myCurrentTableNumber-1];
		[myDataRecordSet moveLast];
		[self readCurrentData];
	}
	return TRUE;
}


/**/
- (BOOL) moveLast
{
	int indexRecordCount = 	[myIndexRecordSet getRecordCount];
	if ( indexRecordCount == 0) return FALSE;
	if ( myCurrentTableNumber != indexRecordCount -1 ) {
		[self openDataTable: indexRecordCount -1];
	}
	[myDataRecordSet moveLast];
	[self readCurrentData];
	return TRUE; 
}


/**/
- (BOOL) moveAfterLast
{
	int indexRecordCount = 	[myIndexRecordSet getRecordCount];
	if ( indexRecordCount == 0) return FALSE;	
	if ( myCurrentTableNumber != indexRecordCount - 1 ) {
		[self openDataTable: indexRecordCount - 1];
	}
	return [myDataRecordSet moveAfterLast];
}


/**/
- (void) seek: (int) aDirection offset: (int) anOffset
{
	unsigned long tableNumber = 0;
	unsigned long n = 0;
	unsigned long lastRecordCount = 0;
	unsigned long tableCount = [myIndexRecordSet getRecordCount];
	
	if (aDirection != SEEK_SET) THROW(FEATURE_NOT_IMPLEMENTED_EX);

	while (tableNumber < tableCount) {
		[self openDataTable: tableNumber];
		lastRecordCount = n;
		n += [myDataRecordSet getRecordCount];
		if (anOffset < n) {
			[myDataRecordSet seek: SEEK_SET offset: anOffset - lastRecordCount ];
			break;
		}
		tableNumber++;
	}

	[self readCurrentData];
	
}


/**/
- (char *) getRecordBuffer
{
	return [myDataRecordSet getRecordBuffer];
}

/**/
- (void) setRecordBuffer: (char*) aBuffer
{
	myIsDirty = TRUE;
	memcpy(myBuffer, aBuffer, myRecordSize);
	[myDataRecordSet setRecordBuffer: aBuffer];
}


/**/
- (void) readCurrentData
{
	myIsNewRecord = FALSE;
	myIsDirty = FALSE;
	memcpy(myBuffer, [myDataRecordSet getRecordBuffer], myRecordSize);
}


/**/
- (void) setValue: (char*)aFieldName value:(char*)aValue len:(int)aLen
{
	Field *field;
	myIsDirty = TRUE;
	if ([self eof] && !myIsNewRecord) THROW_MSG(NO_CURRENT_RECORD_EX, aFieldName);

	for (field = &myFields[0]; field < myFields + myFieldCount; field++) {

		if (strcmp(field->name, aFieldName) == 0) {
			aLen = (aLen < field->len && aLen != -1) ? aLen : field->len;
		//	if (field->type != ROP_STRING && aLen != field->len) doLog(0, "Warning: field size does not match, field %s, size (argument) %d, field size %d\n", aFieldName, aLen, field->len);
			memcpy(myBuffer + field->offset, aValue, aLen);					
			return;
		}

	}
	THROW_MSG(FIELD_NOT_FOUND_EX, aFieldName);
}


/**/
- (void) getValue: (char*)aFieldName value:(char*)aValue
{
	[myDataRecordSet getValue: aFieldName value: aValue];
}

/**/
- (char*) getStringValue: (char*) aFieldName buffer: (char*)aBuffer
{
	return [myDataRecordSet getStringValue: aFieldName buffer: aBuffer];
}

/**/
- (char*) getBcdValue: (char*) aFieldName buffer: (char*) aBuffer
{
  Field *field;
  char bcd[100];
  int len = 0;

  for (field = &myFields[0]; field < myFields + myFieldCount; field++) {
		if (strcmp(field->name, aFieldName) == 0) {
      len = field->len;
      break;
    }
	}

  [self getCharArrayValue: aFieldName buffer: bcd];
  bcdToAscii(aBuffer, bcd, len*2);

  return aBuffer;
}

/**/
- (void) setBcdValue: (char*) aFieldName value: (char*) aValue
{
  char buf[100];
  asciiToBcd(buf, aValue);
  [self setCharArrayValue: aFieldName value: buf];
}


/**/
- (void) add
{
	memset(myBuffer, 0, myRecordSize);
	myIsNewRecord = TRUE;
}


/**/
- (void) delete
{
	[myDataRecordSet delete];
}


/**/
- (void) addIndexRecord
{
	char name[TABLE_NAME_SIZE];
	TABLE table = [myDataRecordSet getTable];
	datetime_t date;
	
	if (![table getField: myIdField]) THROW_MSG(INVALID_POINTER_EX, myIdField);

	strcpy(name, [[myDataRecordSet getTable] getName]);
	
	if (myTransaction) {
		[myTransaction appendRecord: self entityId: [self getTableId] 
			entityPart: -1 recNo: [myIndexRecordSet getRecordCount]];
	}
	
	//agrego el registro a la tabla de indices
	[myIndexRecordSet add];
	[myIndexRecordSet setStringValue: "TABLE_NAME" value: name];

	//seteo el FROM_ID
	if ( [table getField: myIdField]->len == sizeof(short) ) 
		[myIndexRecordSet setLongValue: "FROM_ID" value: [myDataRecordSet getShortValue: myIdField]];
	else
		[myIndexRecordSet setLongValue: "FROM_ID" value: [myDataRecordSet getLongValue: myIdField]];

	//seteo el valor FROM_DATE y TO_DATE si corresponde
	if (strcmp(myDateField, "") != 0) {
		date = truncDateTime( [myDataRecordSet getDateTimeValue: myDateField] );
		[myIndexRecordSet setDateTimeValue: "FROM_DATE" value: date];
		[myIndexRecordSet setDateTimeValue: "TO_DATE" value: date];
	}

	[myIndexRecordSet save];

}


/**/
- (void) openDataTable: (int) aTableNumber
{
	char name[TABLE_NAME_SIZE];
	TABLE dataTable;
	DATABASE db = [DB getInstance];

	if ( myCurrentTableNumber == aTableNumber) return ;
	
	[myIndexRecordSet seek: SEEK_SET offset: aTableNumber];
	[myIndexRecordSet getStringValue: "TABLE_NAME" buffer: name];
	dataTable = [db createTableWithSchema: name schema: myTableName];
	[myDataRecordSet free];
	myDataRecordSet = [[RecordSet new] initWithTable: dataTable];
	[myDataRecordSet setAutoFlush: myAutoFlush];
	
	[myDataRecordSet open];
	myCurrentTableNumber = aTableNumber;
	//doLog(0,"--> open table name: %s\n", name);
}


/**/
- (id) createDataTable: (int) aTableId
{
	char name[TABLE_NAME_SIZE];
	TABLE dataTable;
	DATABASE db = [DB getInstance];

	sprintf(name, "%s_%d", myTableName, aTableId);
	dataTable = [db createTableWithSchema: name schema: myTableName];
	[myDataRecordSet free];
	myDataRecordSet = [[RecordSet new] initWithTable: dataTable];
	[myDataRecordSet setAutoFlush: myAutoFlush];
		
	[myDataRecordSet open];
	myCurrentTableNumber = [myIndexRecordSet getRecordCount];
	printd("------> new table name is %s\n", name);
	return dataTable;
}


/**/
- (unsigned long) save
{
	unsigned long count;
	datetime_t date;
	unsigned long autoInc = 0, newAutoInc;
	BOOL updateFromDate, updateToDate;
	Field *autoIncField;

	if (!myIsDirty) return -1;	//si no se modifico ningun valor, me voy
	
	printd("table %s, myMaxRecordCount %ld \n", myTableName, myMaxRecordCount);
	
	if (!myIsNewRecord)	{

		autoIncField =  [[myDataRecordSet getTable] getAutoIncField];
		//verifico que no se trate de modifica ni la fecha ni el identificador autoincremental,
		//estos valores son fijos, no pueden modificarse.

		if (strcmp(myDateField, "") != 0) {
			date = [myDataRecordSet getDateTimeValue: myDateField];
			if ( date != [self getDateTimeValue: myDateField] ) THROW(READ_ONLY_FIELD_EX);
		}		

		if (autoIncField->len == 2) {
			autoInc = [myDataRecordSet getShortValue: myIdField];
			newAutoInc = [self getShortValue: myIdField];
		}	else if (autoIncField->len == 4) {
			autoInc = [myDataRecordSet getLongValue: myIdField];
			newAutoInc = [self getLongValue: myIdField];
		} else {
			autoInc = [myDataRecordSet getCharValue: myIdField];
			newAutoInc = [self getCharValue: myIdField];
		}
		
		if ( autoInc != newAutoInc ) THROW(READ_ONLY_FIELD_EX);

		if (myTransaction) {
			[myTransaction updateRecord: self entityId: [self getTableId] 
			entityPart: [self getPartNumber] recNo: [myDataRecordSet getCurrentPos]];
		}
		
		//paso la info almacenada en el buffer de este objeto al buffer de myDataRecordSet y grabo
		[myDataRecordSet setRecordBuffer: myBuffer];
		autoInc = [myDataRecordSet save];

	
  }	else {

		count = 0;

		if ( [myIndexRecordSet getRecordCount] != 0) {

			[self openDataTable: [myIndexRecordSet getRecordCount]-1 ];

			printd("MultiPartRecordSet ---> adding record...");
			count = [myDataRecordSet getRecordCount];
			printd("count is %d\n", count);

			//si llego a la cantidad especificada, creo un nuevo archivo de datos y agrego la entrada al
			//archivo de indices
			if ((myMaxRecordCount != INFINITE_MAX_RECORD_COUNT && count >= myMaxRecordCount) ||
 				  (myMaxRecordCount == INFINITE_MAX_RECORD_COUNT && myAppendFileMode ) ) 
			{
				printd("MultiPartRecordSet ---> appending file\n");
				myAppendFileMode = FALSE;

				if (myMaxRecordCount != INFINITE_MAX_RECORD_COUNT) myShouldCutFile = TRUE;

				[self appendFile];
				count = 0;
			}

		}

		if (myTransaction) {
			[myTransaction appendRecord: self entityId: [self getTableId] 
			entityPart: [self getPartNumber] recNo: count];
		}

		[myDataRecordSet add];
		[myDataRecordSet setRecordBuffer: myBuffer];
		autoInc = [myDataRecordSet save];
		
		if (count == 0) {

			//agrego el indice al archivo de indices.
			[self addIndexRecord];

		} else {
			
			if (strcmp(myDateField, "") != 0) {
				date = truncDateTime([myDataRecordSet getDateTimeValue: myDateField]);
				updateToDate = date > truncDateTime( [myIndexRecordSet getDateTimeValue: "TO_DATE"] );
				updateFromDate = date < truncDateTime( [myIndexRecordSet getDateTimeValue: "FROM_DATE"] );

				//verifico si tengo que actualizar la fecha/hora del archivo de indices.
				if ( updateFromDate || updateToDate ) {
					if (updateToDate) [myIndexRecordSet setDateTimeValue: "TO_DATE" value: date];
					if (updateFromDate) [myIndexRecordSet setDateTimeValue: "FROM_DATE" value: date];
					//doLog(0,"MultiPartRecordSet -> actualizo fecha del archivo\n");
					[myIndexRecordSet save];
				}
			}

		}

		printd("record added\n");

	}

	myIsDirty = FALSE;
	myIsNewRecord = FALSE;
	myAppendFileMode = FALSE;
	
	return autoInc;
}


/**/
- (BOOL) eof
{
	/* Sino tiene nigun registro, entonces asumo que es EOF */
	if ([myIndexRecordSet getRecordCount] == 0) return TRUE;
	return ( [myDataRecordSet eof] ) && 
				 ( myCurrentTableNumber >= [myIndexRecordSet getRecordCount] -1);
}


/**/
- (BOOL) bof
{
	return ( [myDataRecordSet bof] ) && 
				 ( myCurrentTableNumber <= 0 );
}


/**/
- (unsigned long) getRecordCount
{
	int i, oldTableNumber, oldPos, indexRecCount, count = 0;
	
	indexRecCount = [myIndexRecordSet getRecordCount];
	oldTableNumber = myCurrentTableNumber;
	oldPos = [myDataRecordSet getCurrentPos];
	
	for (i = 0; i < indexRecCount; ++i) {
		[self openDataTable: i]; 
		count += [myDataRecordSet getRecordCount]; 
	}
	
	[self openDataTable: oldTableNumber];
	[myDataRecordSet seek: SEEK_SET offset: oldPos];
	
	return count;
}


/**/
- (char*) getName
{
	return [myDataRecordSet getName];
}


/**/
- (unsigned long) getIndexCount
{
	return [myIndexRecordSet getRecordCount];
}


/**/
- (void) cutFile
{
	myAppendFileMode = TRUE;
}


/**/
- (const char*) appendFile
{
	char name[TABLE_NAME_SIZE];
	TABLE dataTable;
	unsigned long autoInc = 0;
	unsigned long tableId;
	char *p;
	int fileCount = [myIndexRecordSet getRecordCount];
	int fileCountToDelete;
	int i;

	tableId = 0;
	printd("myMaxFiles = %d, fileCount = %d\n", myMaxFiles, fileCount);

	// antes de crear una nueva tabla verifico si debo eliminar tablas viejas. Solo si
	// supera la cantidad maxima
	if (fileCount >= myMaxFiles) 	{

		// calculo la cantidad de tablas a eliminar
		fileCountToDelete = (fileCount - myMaxFiles) + 1;

		// elimino la cantidad de tablas sobrantes
		for (i = 0; i < fileCountToDelete; i++) {
			if ([myIndexRecordSet moveFirst]) {
				[myIndexRecordSet getStringValue: "TABLE_NAME" buffer: name];
				[myIndexRecordSet delete];
	
				if (myDataRecordSet) [myDataRecordSet close];
				dataTable = [[DB getInstance] createTableWithSchema: name schema: myTableName];
	
	/*			doLog(0,"-----> ELIMINO EL ARCHIVO %s <-----\n", name);
				if (unlink([dataTable getFileName]) != 0)
					doLog(0,"Error: no se pudo eliminar el archivo %s\n", name);*/
			}
		}

	}

	// obtiene el nombre de la ultima tabla
	if ([myIndexRecordSet moveLast]) {
	
		[myIndexRecordSet getStringValue: "TABLE_NAME" buffer: name];

		// obtiene el valor autoincremental de la ultima tabla
		dataTable = [[DB getInstance] getTable: name];

		printd("MultiPartRecordSet ---> Table is %s\n", name);
		if (!dataTable) {
			dataTable = [[Table new] initWithTableNameAndSchema: name schema: myTableName type: ROP_TABLE_SINGLE];
		}
		autoInc = [dataTable getAutoIncValue];
		printd("MultiPartRecordSet ---> AutoInc is %ld\n", autoInc);
		// incrementa en uno el sufijo de la tabla, por ej: calls_0 para a calls_1
		p = &name[strlen(myTableName)+1];
		printd("------> table name is %s\n", p);
		tableId = atoi(p) + 1;
	}

	// crea la nueva tabla y le setea el valor autoincremental
	dataTable = [self createDataTable: tableId];
	[dataTable setInitialAutoIncValue: autoInc];
	return [dataTable getName];
}


/**/
- (void) setMaxRecordCount: (long) aMaxRecordCount
{
	printd("table %s, setMaxRecordCount, before %ld, after %ld\n", myTableName,
					myMaxRecordCount, aMaxRecordCount);
	myMaxRecordCount = aMaxRecordCount;
}


/**/
- (void) setDateField: (char*) aDateField
{
	strcpy(myDateField, aDateField);
}


/**/
- (void) setIdField: (char*) anIdField
{
	strcpy(myIdField, anIdField);
}


/**/
- (BOOL) findById: (char*) aFieldName value: (unsigned long) aValue
{
	return [self binarySearch: aFieldName value: aValue];
}


/**/
- (BOOL) findFirstById: (char*) aFieldName value: (unsigned long) aValue
{
	unsigned long value;
	
	if (![self binarySearch: aFieldName value: aValue]) return FALSE;

	while ( [self movePrev] ) {
		value = 0;
		[self getValue: aFieldName value: (char*)&value];
		if ( (unsigned long)B_ENDIAN_TO_LONG(value) != aValue ) break; 
	}
	[self moveNext];
	return TRUE;
}

/**/
- (BOOL) findFirstFromId: (char*) aFieldName value: (unsigned long) aValue
{
	unsigned long value;

	if ([self binarySearch: aFieldName value: aValue]) return TRUE;

	if (![self moveFirst]) return FALSE;

	while (![self eof]) {
		value = 0;
		[self getValue: aFieldName value: (char*)&value];
		if ((unsigned long)B_ENDIAN_TO_LONG(value) >= aValue) return TRUE; 
		[self moveNext];
	}

	return FALSE;
}




/**/
- (BOOL) binarySearch: (char*) aFieldName value: (unsigned long) aValue
{
	long high = [myIndexRecordSet getRecordCount] - 1;
	unsigned long value;
	int tableNo = -1;
	
	if (high == -1) return FALSE;

	[myIndexRecordSet moveBeforeFirst];
	while ([myIndexRecordSet moveNext]) {
		value = [myIndexRecordSet getLongValue: "FROM_ID"];
		if (value > aValue) break;
		tableNo++;
	}
	
	[self openDataTable: tableNo];

	if ([myDataRecordSet binarySearch: aFieldName value:aValue]) {
		[self readCurrentData];
		return TRUE;
	}	else
		return FALSE;	
}

/**/
- (void) flush
{
	[myDataRecordSet flush];
}


/**/
- (BOOL) findNextRecordSetByDateTime: (datetime_t) aFromDate
	toDate: (datetime_t) aToDate
{
	datetime_t fromDate, toDate;
	int tableNumber = myCurrentTableNumber;

/*	fromDate = truncDateTime(aFromDate);
	toDate = truncDateTime(aToDate);
*/
	fromDate = aFromDate;
	toDate = aToDate;

	while ([myIndexRecordSet moveNext]) {

			tableNumber++;

			printd("Buscando en recordset %ld...\n", tableNumber);
			printd("fromDate = %ld, toDate = %ld\n", fromDate, toDate);
			printd("recordSetFromDate = %ld, recordSetToDate = %ld\n", 
				[myIndexRecordSet getDateTimeValue: "FROM_DATE"], 
				[myIndexRecordSet getDateTimeValue: "TO_DATE"]);
/*
			if ((fromDate >= [myIndexRecordSet getDateTimeValue: "FROM_DATE"] &&
					 fromDate <= [myIndexRecordSet getDateTimeValue: "TO_DATE"]) ||
					(toDate >= [myIndexRecordSet getDateTimeValue: "FROM_DATE"] &&
					 toDate <= [myIndexRecordSet getDateTimeValue: "TO_DATE"])) {
*/
			if ((fromDate < [myIndexRecordSet getDateTimeValue: "FROM_DATE"] &&
					 toDate   < [myIndexRecordSet getDateTimeValue: "FROM_DATE"]) ||
					(fromDate > [myIndexRecordSet getDateTimeValue: "TO_DATE"] &&
					 toDate   > [myIndexRecordSet getDateTimeValue: "TO_DATE"]))
			{
				printd("No Encontrado\n");

			} else {	

				[self openDataTable: tableNumber];
			
				printd("Encontrado\n");

				return TRUE;

			}

	}

	return FALSE;
}

/**/
- (BOOL) findNextByDateTime: (datetime_t) aFromDate
	toDate: (datetime_t) aToDate
{

	while (1) {

		// Me fijo si se cumple la condicion
		while ([myDataRecordSet moveNext]) {
			
			printd("Buscando registro %ld......\n", [myDataRecordSet getLongValue: myIdField]);
			printd("Fecha hora = %ld\n", [myDataRecordSet getDateTimeValue: myDateField]);

			if ([myDataRecordSet getDateTimeValue: myDateField] >= aFromDate &&
					[myDataRecordSet getDateTimeValue: myDateField] <= aToDate) return TRUE;

			printd("Ignorado\n");

		}

		if ([myIndexRecordSet getRecordCount] == 0) return FALSE;
		if (myCurrentTableNumber >= [myIndexRecordSet getRecordCount] -1) return FALSE;

		if ([self findNextRecordSetByDateTime: aFromDate toDate: aToDate]) {

			[myDataRecordSet moveBeforeFirst];

		} else return FALSE;

	}
	
	return FALSE;

}


/**/
- (BOOL) findFirstByDateTime: (datetime_t) aFromDate toDate: (datetime_t) aToDate
{
	if (![myIndexRecordSet moveBeforeFirst]) return FALSE;

	myCurrentTableNumber = -1;

	if (![self findNextRecordSetByDateTime: aFromDate toDate: aToDate]) return FALSE;

	[myDataRecordSet moveBeforeFirst];

	return [self findNextByDateTime: aFromDate toDate: aToDate];
}

/**/
- (void) deleteAll
{
	int i;
	int indexRecordCount = 	[myIndexRecordSet getRecordCount];

/** @todo: probar si funciona bien este metodo */

	for (i = 0; i < indexRecordCount; ++i) {
		[self openDataTable: i];
		[myDataRecordSet deleteAll];
	}

	[myIndexRecordSet deleteAll];
}

/**/
- (void) setInitialAutoIncValue: (unsigned long) aValue
{
	[myDataRecordSet setInitialAutoIncValue: aValue];
}

@end
