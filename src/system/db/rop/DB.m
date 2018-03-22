#include <string.h>
#include "DB.h"
#include "DBExcepts.h"
#include "StringTokenizer.h"
#include "ordcltn.h"
#include "util/all.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation DB

static id singleInstance = NULL;

- (void) loadTables;

/**
 *	Agrega una tabla a la base de datos (Solo al objeto, no al archivo db.dat).
 */
- (void) registerTable: (id) aTable schema: (char*) aSchema;

+ new
{
	if (!singleInstance) singleInstance = [[super new] initialize];
	return singleInstance;
}

- free
{
	int i;
	for (i = 0; i < [myTables size]; ++i) {
		[[myTables at:i] free];
	}
	[myTables free];
	return [super free];
}

+ (id) getInstance
{
	return [DB new];
}

- initialize
{
	myTables = [OrdCltn new];
	strcpy(myDataBasePath, "");
	myStarted = FALSE;
	return self;
}

- (void) setDataBasePath: (char*) aDataBasePath
{
	if ( strlen(aDataBasePath) >= DATABASE_PATH_SIZE ) THROW(BUFFER_OVERFLOW_EX);
	strcpy(myDataBasePath, aDataBasePath);
}

- (const char*) getDataBasePath
{
	return myDataBasePath;
}

- (void) startService
{
	[self loadTables];
	myStarted = TRUE;
}

- (TABLE) getTable: (char*) aTableName
{
	int i;
	char *name;
	
	if (!myStarted) THROW(DATABASE_NOT_RUNNING_EX);

	for (i = 0; i < [myTables size]; ++i) {
		name = (char*) [[myTables at:i] getName];
		if (strcmp(aTableName, name) == 0) return [myTables at:i];
	}

	return NULL;
}

- (TABLE) getTableById: (int) aTableId
{
	int i;
	
	if (!myStarted) THROW(DATABASE_NOT_RUNNING_EX);

	for (i = 0; i < [myTables size]; ++i) {
		if (aTableId == [[myTables at: i] getTableId]) return [myTables at:i];
	}

	return NULL;
}

- (TABLE) createTableWithSchema: (char*) aTableName schema: (char*) aSchema
{
	TABLE dataTable;
	
	if (!myStarted) THROW(DATABASE_NOT_RUNNING_EX);
	
	dataTable = [self getTable: aTableName];

	if (!dataTable) {
		dataTable = [[Table new] initWithTableNameAndSchema: aTableName schema: aSchema type: ROP_TABLE_SINGLE];
		[self registerTable: dataTable schema: aSchema];
	}
	
	return dataTable;
}

- (void) registerTable: (id) aTable schema: (char*) aSchema
{
	TABLE t;
	if (!myStarted) THROW(DATABASE_NOT_RUNNING_EX);
	
	[myTables add: aTable];
	
	/* esto es una chanchada, pero por ahora es lo mas facil, copio el id 
	   desde la tabla cuyo nombre es igual al nombre del esquema a la tabla que intento 
	 	 registrar. 
	*/
	t = [self getTable: aSchema];
	if (t) [aTable setTableId: [t getTableId]];
}

- (void) loadTables
{
	char buffer[255];
	char name[DATABASE_FILE_NAME_SIZE];
	char tableName[TABLE_NAME_SIZE];
	FILE *f;
	id table;
	STRING_TOKENIZER tokenizer;
	char token[20];
	char tableType[20];
	int  maxFiles;
	int	 recordsByFile;
	ROPTableType type;
	int fileId, fileOffset, unitSize;
	int i = 1;
	int order = 0;
	
	strcpy(name, myDataBasePath);
	strcat(name, DATABASE_NAME);
	printd("database file is %s\n", name);
	f = fopen(name, "r");
	if (!f) THROW_MSG(FILE_NOT_FOUND_EX, name);

	tokenizer = [StringTokenizer new];
	[tokenizer setDelimiter: ","];

	// en primer lugar, recorro el archivo para saber cuantos campos hay

	while (!feof(f)) {
	
		if (!fgets(buffer, 255, f)) break;
		if (strlen(buffer) == 0)	break;
		if (*buffer == '#') continue;

		if (buffer[strlen(buffer)-1] == '\n') {
			buffer[strlen(buffer)-1] = 0;
		}

		if (buffer[strlen(buffer)-1] == '\r') {
			buffer[strlen(buffer)-1] = 0;
		}

		[tokenizer setText: buffer];
		
		[tokenizer getNextToken: tableName];
		[tokenizer getNextToken: tableType];

		if (strcmp(tableType, "multi") == 0) {
			type = ROP_TABLE_MULTI;
		} else {
			type = ROP_TABLE_SINGLE; 
		}

		maxFiles = 0;
		recordsByFile = 0;
		fileId = -1;
		fileOffset = 0;
    unitSize = 0;
		
		if ([tokenizer hasMoreTokens]) {

			// La cantidad de registros por archivo
			[tokenizer getNextToken: token];
			recordsByFile = atoi(token);
			
			// La cantidad de archivos maxima
			[tokenizer getNextToken: token];
			maxFiles = atoi(token);
			
			if ([tokenizer hasMoreTokens]) {
				[tokenizer getNextToken: token];
				fileId = atoi(token);
			}

			if ([tokenizer hasMoreTokens]) {
				[tokenizer getNextToken: token];
				fileOffset = atoi(token);
			}

			if ([tokenizer hasMoreTokens]) {
				[tokenizer getNextToken: token];
				unitSize = atoi(token);
			}
			
		}

		table = [[Table new] initWithTableNameAndType: tableName type: type];
		[table setTableId: i];
		[table setFileId: fileId];
		[table setFileOffset: fileOffset];
		[table setUnitSize: unitSize];
		[table setRecordsByFile: recordsByFile];
		[table setMaxFiles: maxFiles];

		// si es una tabla de seteo o usuario (backup) le asigno un orden para luego
		// porder identificarla en el backup. Se utilizara como marca o bandera antes y
		// despues de cincronizarla con la tabla del CT8016. Mediante esta posicion
		// se puede acceder al string de bits.
		if (fileId == 0) {
			order++;
			[table setTableOrder: order];
		} else [table setTableOrder: 0];
		
		printd("Table: %s [%d]\n", tableName, i);
		printd("Records by File: %d\n", recordsByFile);
		printd("Max files: %d\n", maxFiles);
		
		[myTables add: table];
		i++;

	}

	[tokenizer free];
	
	fclose(f);
}

- (COLLECTION) getTables
{
	return myTables;
}

@end
