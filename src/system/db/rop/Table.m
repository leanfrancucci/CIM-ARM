#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include "Table.h"
#include "StringTokenizer.h"
#include "RecordSet.h"
#include "MultiPartRecordSet.h"
#include "DBExcepts.h"
#include "roputil.h"
#include "excepts.h"
#include "system/util/endian.h"
#include "DB.h"
#include "log.h"
#include "util.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation Table

/**/
- (void) loadSchema: (char*)aSchemaName;


/**/
+ new
{
	return [[super new]initialize];
}

/**/
- initialize
{
	myMutex = [OMutex new];
	myFieldCount = 0;
	myAutoIncField = NULL;
	myTableId = -1;
	myAutoIncValue = 0;
	myMaxFiles = 0;
	myRecordsByFile = 0;
	myRecordCount = 0;
	myFileId = -1;
	myGlobalData = NULL;
	myFileOffset = 0;
	myUnitSize = 0;
	myTableOrder = 0;
	myShouldClearOldData = TRUE;
	return self;
}

/**/
- (BOOL) shouldClearOldData
{
	return myShouldClearOldData;
}

/**/
- (void) setShouldClearOldData: (BOOL) aValue
{
	myShouldClearOldData = aValue;
}

/**/
- initWithTableNameAndType: (char*) aTableName type: (ROPTableType) aType
{
	return [self initWithTableNameAndSchema: aTableName schema: aTableName type: aType];
}

/**/
- initWithTableNameAndSchema: (char*) aTableName schema: (char*) aSchema type: (ROPTableType) aType
{
	if (strlen(aTableName) > TABLE_NAME_SIZE ) THROW(BUFFER_OVERFLOW_EX);
	myTableType = aType;
	strcpy(myTableName, aTableName);
	strcpy(myFileName, [[DB getInstance] getDataBasePath]);
	strcat(myFileName, myTableName);
	strcat(myFileName, ".dat");
	printd("file name is %s\n", myFileName);

	[self loadSchema: aSchema];
	[self loadRecordCount];
		
	if (myAutoIncField) [self loadAutoIncValue];
	printd("table %s, myAutoIncValue is %ld\n", aTableName, myAutoIncValue);
	printd("%s,%d\n", aTableName, myRecordSize);
	return self;
}

/**/
- free
{
	[myMutex unLock];
	[myMutex free];
	free(myFields);
	return [super free];
}

- (void) setTableOrder: (int) aTableOrder
{
	myTableOrder = aTableOrder;
}

- (int) getTableOrder
{
	return myTableOrder;
}

/**/
- (void) setTableId: (int) aTableId
{
	myTableId = aTableId;
}

/**/
- (int) getTableId
{
	return myTableId;
}	

/**/
- (void) setRecordsByFile: (int) aValue
{
	myRecordsByFile = aValue;
}

/**/
- (int) getRecordsByFile
{
	return myRecordsByFile;
}

/**/
- (void) setMaxFiles: (int) aValue
{
	myMaxFiles = aValue;
}

/**/
- (int) getMaxFiles
{
	return myMaxFiles;
}

/**/
- (OMUTEX) getMutex
{
	return myMutex;
}

/**/
- (int) getRecordSize
{
	return myRecordSize;
}

/**/
- (Field*) getFields
{
	return myFields;
}

/**/
- (int) getFieldCount
{
	return myFieldCount;
}

/**/
- (Field*) getField: (char*) aFieldName
{
	int i;
	for (i = 0; i < myFieldCount; ++i) {
		if ( strcmp(myFields[i].name, aFieldName) == 0 ) return &myFields[i];
	}
  
	THROW_MSG(FIELD_NOT_FOUND_EX, aFieldName);
	return NULL;
}

/**/
- (Field*) getAutoIncField
{
	return myAutoIncField;
}

/**/
- (char*) getName
{
	return myTableName;
}


/**/
- (char*) getFileName
{
	return myFileName;
}

/**/
- (unsigned long) autoIncValue
{
	myAutoIncValue++;
	return myAutoIncValue;
}

/**/
- (unsigned long) getAutoIncValue
{
	return myAutoIncValue;
}

/**/
- (void) setInitialAutoIncValue: (unsigned long) aValue
{
	myAutoIncValue = aValue;
}

/**/
- (id) getNewRecordSet
{
	RECORD_SET rs;


	if (myFileId != -1) {
		rs = [[self findClass: "SafeBoxRecordSet"] new];
	} else if (myTableType == ROP_TABLE_SINGLE) {
		rs = [RecordSet new];
	} else {
		rs = [MultiPartRecordSet new];
	}

	[rs initWithTableName: myTableName];
	
	return rs;
}

/**/
- (void) loadSchema: (char*)aSchemaName
{
	char name[TABLE_FILE_NAME_SIZE+ 50];
	char buffer[100];
	FILE *f;
	int i;
	STRING_TOKENIZER tokenizer;
	char token[50];
	int offset = 0;

	myFieldCount = 0;	
	strcpy(name, [[DB getInstance] getDataBasePath]);
	strcat(name, aSchemaName);
	strcat(name, ".ftd");
	
	f = fopen(name, "r");
	if (!f) THROW_MSG(FILE_NOT_FOUND_EX, name);
	
	// en primer lugar, recorro el archivo para saber cuantos campos hay
	while (!feof(f)) {
		if (!fgets(buffer, 100, f)) break;
		if (strlen(buffer) > 0)	myFieldCount++;
	}
	
	
	// creo suficiente cantidad de espacio para todos los campos que hay
	myFields = (Field*) malloc(sizeof(Field) * myFieldCount);
	fseek(f, 0, SEEK_SET);

	tokenizer = [StringTokenizer new];
	[tokenizer setDelimiter: ","];
	[tokenizer setTrimMode: TRIM_ALL];

	for (i = 0; i < myFieldCount; ++i) {

		//leo la primera linea
		fgets(buffer, 100, f);
		[tokenizer restart];
		[tokenizer setText: buffer];
		
		//nombre del campo
		/*assert( [tokenizer hasMoreTokens] );*/
		[tokenizer getNextToken:token];
		if (strlen(token) >= FIELD_SIZE) THROW(BUFFER_OVERFLOW_EX);
		strcpy(myFields[i].name, token);
		
		//tipo de datos
		/*assert( [tokenizer hasMoreTokens] );*/
		[tokenizer getNextToken:token];
		myFields[i].type = mapDataType(token);

		//tamanio
		/*assert( [tokenizer hasMoreTokens] );*/
		[tokenizer getNextToken:token];
		myFields[i].len = atoi(token);

		//offset desde el inicio del registro
		myFields[i].offset = offset;
		offset += myFields[i].len;
		
		if (myFields[i].type == ROP_AUTOINC) myAutoIncField = &myFields[i];
		printd("%s, %d, %d, %d\n", myFields[i].name, myFields[i].offset, myFields[i].type, myFields[i].len);

	}

	myRecordSize = offset;

	[tokenizer free];

	fclose(f);
}

/**/
- (void) loadAutoIncValue
{
	char name[TABLE_FILE_NAME_SIZE];
	FILE *f;
	unsigned char  cvalue;
	unsigned short svalue;
	unsigned long  lvalue;
	unsigned long fsize = 0;

	if (myAutoIncField == NULL) return;

	strcpy(name,	[self getFileName] );
	myAutoIncValue = 0;
	
	// abro el archivo de datos como solo lectura
	f = fopen(name, "rb");
	if (!f) return;

	fseek(f, 0, SEEK_END);
	fsize = ftell(f);
	fseek(f, 0, SEEK_SET);
	
	if (!feof(f) && fsize != 0) {

		// me posiciono en la posicion correspondiente al ultimo registro y en el campo autoincremental
		fseek(f, -myRecordSize + myAutoIncField->offset, SEEK_END);

		// si es un byte
		if (myAutoIncField->len == 1)
		{
			fread((char*)&cvalue, myAutoIncField->len, 1, f);
			myAutoIncValue = cvalue;
		}

		// si es un short
		if (myAutoIncField->len == 2)
		{
			fread((char*)&svalue, myAutoIncField->len, 1, f);
			svalue = B_ENDIAN_TO_SHORT(svalue);
			myAutoIncValue = svalue;
		}

		// si es un long
		if (myAutoIncField->len == 4)
		{
			fread((char*)&lvalue, myAutoIncField->len, 1, f);
			lvalue = B_ENDIAN_TO_LONG(lvalue);
			myAutoIncValue = lvalue;
		}
		
	}
	
	fclose(f);
}

 
/**/
- (ROPTableType) getTableType
{
	return myTableType;
}

/**/
- (void) setRecordCount: (unsigned long) aRecordCount
{
	myRecordCount = aRecordCount;
}

/**/
- (void) loadRecordCount
{
	FILE *f = fopen([self getFileName], "r+b");
	long size;

	myRecordCount = 0;

	if (!f) return;

	fseek(f, 0, SEEK_END);
	size = ftell(f);
	fclose(f);

	myRecordCount = size / [self getRecordSize];

 /* if (size % [self getRecordSize] != 0)   
    doLog(0,"Warning: error en el archivo %s, size = %ld, recordSize = %d\n", [self getFileName], 
      size, [self getRecordSize]);
*/

}

/**/
- (unsigned long) getRecordCount
{
	return myRecordCount;
}

- (void) incRecordCount
{
	myRecordCount++;
}

- (void) decRecordCount
{
	myRecordCount--;
}

/**/
- (void) setFileId: (int) aFileId { myFileId = aFileId; }
- (int) getFileId { return myFileId; }

/**/
- (void) setGlobalData: (char *) aGlobalData { myGlobalData = aGlobalData; }
- (char *) getGlobalData { return myGlobalData; }

/**/
- (void) setFileOffset: (int) anOffset { myFileOffset = anOffset; }
- (int) getFileOffset { return myFileOffset; }

/**/
- (void) setUnitSize: (int) aUnitSize { myUnitSize = aUnitSize; }
- (int) getUnitSize 
{ 
  if (myUnitSize == 0) return [self getRecordSize];
  return myUnitSize;
}

/**/
- (BOOL) hasBackup
{
	if (myFileId == -1) return FALSE;

	return TRUE;
}

@end
