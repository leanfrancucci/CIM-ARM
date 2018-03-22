#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "SafeBoxHAL.h"
#include "SafeBoxRecordSet.h"
#include "DAOExcepts.h"
#include "DB.h"
#include "DBExcepts.h"
#include "system/io/all.h"
#include "util/endian.h"
#include "util/util.h"
#include "roputil.h"
#include "CimBackup.h"
#include "ResourceStringDefs.h"

//#define LOG(args...)  doLog(0,args)
#define LOG(args...)  

// Chequea que la table/query se encuentre abierta, caso contrario arroja una excepcion
#define CHECK_OPEN() do { if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName); } while (0)

#define GET_CURRENT_BUF	&myBuffer[myCurrentRow * myRecordSize]

@implementation SafeBoxRecordSet

- (void) checkTableBuffer;

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
	myIsOpen = FALSE;
	myAutoFlush	= TRUE;
	myMaxRows = 0;
	myCurrentRow = -1;
	myCurrentRowBuf = NULL;
	return self;
}


/**/
- free
{
	if (myIsOpen) [self close];
	if (myCurrentRowBuf) free(myCurrentRowBuf);
	return [super free];
}


/**/
- initWithTableName: (char*) aTableName
{
	DATABASE db = [DB getInstance];
	return [self initWithTable: [db getTable: aTableName]];
}


/**/
- initWithTable: (id) aTable
{
	if (!aTable) THROW(INVALID_POINTER_EX);

	LOG("creo el recordset %s, fileId = %d\n", [aTable getFileName], [aTable getFileId]);

	myTable = aTable;
	myRecordSize = [myTable getRecordSize];
	myFields = [myTable getFields];
	myFieldCount = [myTable getFieldCount];	
	myMaxRows = [myTable getRecordsByFile];	
	myFileId  = [myTable getFileId];
	myCurrentRowBuf = malloc(myRecordSize);
	stringcpy(myFileName, [aTable getFileName]);
	myBuffer = [aTable getGlobalData];
	myMutex = [SafeBoxHAL fsGetMutex: myFileId];
  myUnitSize = [myTable getUnitSize];
  myFileOffset = [myTable getFileOffset];

/*	if (myRecordSize % myUnitSize != 0) {
		doLog(0,"Error: El recordSize (%d) y el unitSize (%d) no son multiplos\n", myRecordSize, myUnitSize);
	}*/

	return self;
}

/**/
- (void) setUnitSize: (int) aUnitSize
{
	myUnitSize = aUnitSize;
}

/**/
- (void) loadAutoIncValue
{
	Field *autoIncField;
	unsigned long autoIncValue = 0;

	CHECK_OPEN();
	
	autoIncField = [myTable getAutoIncField];	

	LOG("loadAutoIncValue %s\n", [myTable getFileName]);
	
	//si tiene un campo autoincremental, solicito el valor del autoincremental y lo seteo
	//al registro.
	if (autoIncField) {

		if (![self moveLast]) return;

		if (autoIncField->len == 2) {
			autoIncValue = [self getShortValue: autoIncField->name];
		} else if (autoIncField->len == 4) {
			autoIncValue = [self getLongValue: autoIncField->name];
		} else {
			autoIncValue = [self getCharValue: autoIncField->name];
		}

	}

	[myTable setInitialAutoIncValue: autoIncValue];

	LOG("autoIncValue = %ld\n", autoIncValue);


}

/**/
- (void) createFile
{
	
	//doLog(0,"SafeBoxRecordSet -> createFile(). myFiledId=%d | myRecordSize = %d | myMaxRows = %d \n", 
	//	myFileId, myRecordSize, myMaxRows);

 	[SafeBoxHAL fsCreateFile: myFileId 
        unitSize: myUnitSize 
        fileType: [myTable getTableType] == ROP_TABLE_MULTI ? SafeBoxFileType_CIRCULAR : SafeBoxFileType_RANDOM
        rows: myMaxRows * (myRecordSize / myUnitSize)];
}

/**/
- (void) copyFileTo: (char *) aFileName
{
	FILE *f;

//	doLog(0,"SafeBoxRecordSet -> restoreFileTo(). fileName = %s | myFiledId=%d | myRecordSize = %d | myMaxRows = %d \n", 
		//aFileName, myFileId, myRecordSize, myMaxRows);

	f = fopen(aFileName, "a+b");
	if (!f) {
	//	doLog(0,"No se puede abrir el archivo %s\n", aFileName);
		return;
	}

	fwrite(myBuffer, 1, myRecordSize * myMaxRows, f);

	fclose(f);

}

/**/
- (void) clearFile
{
	int i;

  [myMutex lock];

	TRY
		
		// Creo el buffer si no existe
		[self checkTableBuffer];
	
		[SafeBoxHAL fsSeek: myFileId offset: myFileOffset whence: SEEK_SET];

		memset(myBuffer, 0, myMaxRows * myRecordSize);

		for (i = 0; i < myMaxRows; ++i) {
	
	//		doLog(0,"Limpiando registro %d de %d...", i + 1, myMaxRows);
	
			if ([SafeBoxHAL fsWrite: myFileId numRows: myRecordSize / myUnitSize 
					unitSize: myUnitSize buffer: &myBuffer[i * myRecordSize]] != myRecordSize / myUnitSize )
				THROW_MSG(GENERAL_IO_EX, myFileName);
	
		//	doLog(0,"[OK]\n");
		}
	
	
		[SafeBoxHAL fsSeek: myFileId offset: myFileOffset whence: SEEK_SET];
	

	FINALLY

		[myMutex unLock];

	END_TRY

}

/**/
- (void) checkTableBuffer
{
	myBuffer = [myTable getGlobalData];
	if (myBuffer == NULL) {
		myBuffer = malloc(myMaxRows * myRecordSize);
		memset(myBuffer, 0, myMaxRows * myRecordSize);
		[myTable setGlobalData: myBuffer];
	}
}

/**
 * Metodo sobrecargado
 */
- (void) copyFileFrom: (char *) aFileName
{
	[self copyFileFrom: aFileName observer: NULL];
}

/**/
- (void) copyFileFrom: (char *) aFileName observer: (id) anObserver
{
	FILE *f;
	size_t size;
	int recCount;
	int i;
	char msg[50];

//	doLog(0,"SafeBoxRecordSet -> createFileFrom(). fileName = %s | myFiledId=%d | myRecordSize = %d | myMaxRows = %d \n", 
//		aFileName, myFileId, myRecordSize, myMaxRows);

	TRY

		[myMutex lock];
	
		// Creo el buffer si no existe
		[self checkTableBuffer];

		f = fopen(aFileName, "rb");
		if (!f) {
	//		doLog(0,"No se puede abrir el archivo %s\n", aFileName);
			[myMutex unLock];
			EXIT_TRY;
			return;
		}

		fseek(f, 0, SEEK_END);
		size = ftell(f);
		fseek(f, 0, SEEK_SET);

		if (size > (myMaxRows * myRecordSize)) {
		//	doLog(0,"El size del archivo real es mas grande de lo que se puede almacenar, real = %d, maximo = %d\n", size, (myMaxRows*myRecordSize));
			size = myMaxRows * myRecordSize;
		}
	
	
		fread(myBuffer, 1, size, f);
		recCount = size / myRecordSize;
	
		[SafeBoxHAL fsSeek: myFileId offset: myFileOffset whence: SEEK_SET];

		for (i = 0; i < recCount; ++i) {
	
		//	doLog(0,"Copy reg %d de %d...", i + 1, recCount);
			// esto es para mostrar un detalle de que esta procesando desde pantalla CimBackup
			if (anObserver) {
				if (![[CimBackup getInstance] getBackupCanceled]) {
					formatResourceStringDef(msg, RESID_CYNCHRONIZE_RECORD, "Record %d/%d", i+1, recCount);
					[anObserver setLabel2: msg];
				} else break;
			}
	
			if ([SafeBoxHAL fsWrite: myFileId numRows: myRecordSize / myUnitSize 
					unitSize: myUnitSize buffer: &myBuffer[i * myRecordSize]] != myRecordSize / myUnitSize )
				THROW_MSG(GENERAL_IO_EX, myFileName);
	
			//doLog(0,"[OK]\n");
		}
	
		[SafeBoxHAL fsSeek: myFileId offset: myFileOffset whence: SEEK_SET];
		if (recCount > 0) {
			[myTable setRecordCount: recCount];
			myIsOpen = TRUE;
			[self loadAutoIncValue];
			myIsOpen = FALSE;
		}
		
		fclose(f);

	FINALLY

		[myMutex unLock];

	END_TRY
}

/**/
- (void) createFileFrom: (char *) aFileName
{
	[self createFile];
	if ([myTable getTableType] == ROP_TABLE_MULTI) return;
  [self copyFileFrom: aFileName];	
}

/**/
- (void) reloadAllRecords
{
	// Recarga todos los registros de la memoria
	// Hay que tener cuidado porque esta operacion potencialmente puede tardar bastante.
	// Recorro como maximo hasta myMaxRows
	// Si en el camino encuentro un registro que sea todo 0x00 entonces termine de leer

	int qty;
	int i;
	unsigned char *buf, *bufRow;
	BOOL isEmpty = TRUE;
	int rowsToRead;
	int row;
	unsigned long recordCount = 0;

	[myMutex lock];

	TRY

		[SafeBoxHAL fsSeek: myFileId offset: myFileOffset whence: SEEK_SET];
	
		// Me fijo la maxima cantidad de registros que puedo leer a la vez
		if (myRecordSize > MAX_DATA_SIZE) rowsToRead = 1;
		else rowsToRead = MAX_DATA_SIZE / myRecordSize;
	
		LOG("SafeBoxRecordSet -> levantando informacion a memoria, de a %d registros\n", rowsToRead);
		// Controlo que no lea mas del maximo
		if (rowsToRead > myMaxRows) rowsToRead = myMaxRows;
	
		while (recordCount < myMaxRows) {
	
			// Posiciono el buffer hasta donde corresponde
			buf = &myBuffer[recordCount * myRecordSize];
	
			// Verifico la cantidad de registros a leer
			if (myCurrentRow + rowsToRead > myMaxRows) rowsToRead = myMaxRows - myCurrentRow;
	
			LOG("SafeBoxRecordSet -> Leyendo %d registros. Actual = %ld\n", rowsToRead, recordCount);
	
			// Leo desde la memoria
			qty = [SafeBoxHAL fsRead: myFileId numRows: rowsToRead * (myRecordSize / myUnitSize) unitSize: myUnitSize buffer: buf];
	
			// No leyo nada, hay un error
			if (qty != rowsToRead * (myRecordSize / myUnitSize)) THROW_MSG(GENERAL_IO_EX, myFileName);
			
			// Recorro todos los registros leidos comprobando que no haya ninguno que 
			// este todo vacio
			for (row = 0; row < rowsToRead; ++row) {
	
				bufRow = buf + row * myRecordSize;
	
				// Controlo byte por byte si todos son ceros, en cuyo caso llegue al final del archivo
				isEmpty = TRUE;
				for (i = 0; i < myRecordSize; ++i) if (bufRow[i] != 0) {isEmpty = FALSE; break;}
				if (isEmpty) break;
		
				recordCount++;
				
			}
	
			if (isEmpty) break;
	
		}
	
		// Configura el recordCount
		[myTable setRecordCount: recordCount];
	
		LOG("SafeBoxRecordSet -> recordCount %s = %ld\n", myFileName, recordCount);
	
		// Si tiene valor autoincremental lo levanto ahora
		[self loadAutoIncValue];
	
		// Me posiciono antes del principio del archivo
		[self moveBeforeFirst];

	FINALLY

		[myMutex unLock];

	END_TRY
}

/**/
- (id) getTable
{
	return myTable;
}

/**/
- (void) open
{
	myIsOpen = TRUE;

	// Creo el buffer si no existe y levanto los datos
	
	if ([myTable getGlobalData] == NULL) {

		[self checkTableBuffer];

		[self reloadAllRecords];

	} else {

		myBuffer = [myTable getGlobalData];

	}

}

/**/
- (void) close
{
	LOG("cerro el recordset %s\n", [myTable getFileName]);
}

/**/
- (BOOL) moveFirst
{
	LOG("moveFirst el recordset %s\n", [myTable getFileName]);
	myCurrentRow = 0;
  if ([self getRecordCount] == 0) return FALSE;
	return TRUE;
}

/**/
- (BOOL) moveBeforeFirst
{
	myCurrentRow = -1;
	return TRUE;
}

/**/
- (BOOL) moveAfterLast
{
	myCurrentRow = [self getRecordCount];
	return TRUE;
}

/**/
- (BOOL) moveNext
{
	int count = [self getRecordCount];
	if (count == 0 || myCurrentRow >= (count)) return FALSE;
	myCurrentRow++;
	if (myCurrentRow >= (count)) return FALSE;
	memcpy(myCurrentRowBuf, GET_CURRENT_BUF, myRecordSize);
	return TRUE;
}

/**/
- (BOOL) movePrev
{
  if ([self getRecordCount] == 0) return FALSE;
	myCurrentRow--;
	if (myCurrentRow < 0) return FALSE;
	memcpy(myCurrentRowBuf, GET_CURRENT_BUF, myRecordSize);
	return TRUE;
}

/**/
- (BOOL) moveLast
{
  if ([self getRecordCount] == 0) return FALSE;	
	myCurrentRow = [self getRecordCount]-1;
  if (myCurrentRow == -1) return FALSE;
	memcpy(myCurrentRowBuf, GET_CURRENT_BUF, myRecordSize);
	return TRUE;
}

/**/
- (void) seek: (int) aDirection offset: (int) anOffset
{
	int row;

	if (aDirection == SEEK_END) row = [self getRecordCount] - anOffset - 1;
	else if (aDirection == SEEK_SET) row = anOffset;
	else row = myCurrentRow - anOffset;

	if (row < -1 || row > [self getRecordCount]) THROW(INVALID_SEEK_EX);

	myCurrentRow = row;

	memcpy(myCurrentRowBuf, GET_CURRENT_BUF, myRecordSize);

}

/**/
- (void) setValue: (char*)aFieldName value:(char*)aValue len:(int)aLen
{
	Field *field;
	unsigned char *buf = myCurrentRowBuf;		//myBuffer + (myCurrentRow * myRecordSize);

	myIsDirty = TRUE;

	CHECK_OPEN();

	if ([self eof] && !myIsNewRecord) THROW_MSG(NO_CURRENT_RECORD_EX, myFileName);

	for (field = &myFields[0]; field < myFields + myFieldCount; field++) {

		if (strcmp(field->name, aFieldName) == 0) {
			
			if (field->type == ROP_STRING) {
				aLen = (aLen < field->len && aLen != -1) ? aLen : field->len-1;
				strncpy2(buf + field->offset, aValue, aLen);
			}	else {
				aLen = (aLen < field->len && aLen != -1) ? aLen : field->len;
			//	if (aLen != field->len) doLog(0,"Warning: field size does not match, field %s, size (argument) %d, field size %d\n", aFieldName, aLen, field->len);
				memcpy(buf + field->offset, aValue, aLen);
			}
			return;
		}
	}

	THROW_MSG(FIELD_NOT_FOUND_EX, aFieldName);
}

/**/
- (unsigned long) getValueFromField: (Field *) aField buffer: (char *) aBuffer
{
	unsigned long value;
	unsigned short svalue;
	unsigned long lvalue;
	unsigned char cvalue;

	if (aField->len == 2) {
		memcpy(&svalue, aBuffer + aField->offset, aField->len);
		svalue = B_ENDIAN_TO_SHORT(svalue);
		value = svalue;
	} else if (aField->len == 4) {
		memcpy(&lvalue, aBuffer + aField->offset, aField->len);
		lvalue = B_ENDIAN_TO_LONG(lvalue);
		value = lvalue;
	} else {
		memcpy(&cvalue, aBuffer + aField->offset, aField->len);
		value = cvalue;
	}

	return value;

}

/**/
- (void) getValue: (char*)aFieldName value:(char*)aValue
{
	Field *field;
	unsigned char *buf = myCurrentRowBuf; //myBuffer + (myCurrentRow * myRecordSize);

	CHECK_OPEN();

	if (myCurrentRow > [self getRecordCount]) THROW(NO_CURRENT_RECORD_EX);
	
	for (field = &myFields[0]; field < myFields + myFieldCount; field++) {
		if (strcmp(field->name, aFieldName) == 0) {
			memcpy(aValue, buf + field->offset, field->len);					
			return;
		}
	}

	THROW_MSG(FIELD_NOT_FOUND_EX, aFieldName);

}

/**/
- (char*) getStringValue: (char*) aFieldName buffer: (char*)aBuffer
{
  Field *field;
  int len = 0;
	unsigned char *buf = myCurrentRowBuf; //myBuffer + (myCurrentRow * myRecordSize);


	CHECK_OPEN();

	if (myCurrentRow > [self getRecordCount]) THROW(NO_CURRENT_RECORD_EX);
	
  for (field = &myFields[0]; field < myFields + myFieldCount; field++) {
		if (strcmp(field->name, aFieldName) == 0) {
      len = field->len;
			memcpy(aBuffer, buf + field->offset, field->len);
			aBuffer[len] = 0;
      return aBuffer;
    }
	}

	THROW_MSG(FIELD_NOT_FOUND_EX, aFieldName);

	return aBuffer;
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
- (void) setRecordBuffer: (char*) aBuffer
{
	memcpy(myCurrentRowBuf, aBuffer, myRecordSize);
	myIsDirty = TRUE;
}


/**/
- (char*) getRecordBuffer
{
	return myCurrentRowBuf;
}


/**/
- (void) add
{
	CHECK_OPEN();

  if ([self getRecordCount] >= myMaxRows) {
    THROW_MSG(DAO_MAX_ROWS_LIMIT_EX, myFileName);
  }

	myCurrentRow = [self getRecordCount];
	myIsNewRecord = TRUE;
	memset(myCurrentRowBuf, 0, myRecordSize);

	LOG("add el recordset %s\n", [myTable getFileName]);
}


/**/
- (void) delete
{

}

/**/
- (unsigned long) update
{
	Field *autoIncField;
	unsigned long autoIncValue = 0;
	unsigned long lvalue;
	unsigned short svalue;
	unsigned char cvalue;
	
	autoIncField = [myTable getAutoIncField];	
	CHECK_OPEN();
	
	//es una modificacion de registro, me paro al inicio del registro que mofique

	if (autoIncField)
	{
		if (autoIncField->len == 2) {
			[self getValue: autoIncField->name value: (char*)&svalue];
			svalue = B_ENDIAN_TO_SHORT(svalue);
			autoIncValue = svalue;
		} else if (autoIncField->len == 4) {
			[self getValue: autoIncField->name value: (char*)&lvalue];
			lvalue = B_ENDIAN_TO_LONG(lvalue);
			autoIncValue = lvalue;
		} else {
			[self getValue: autoIncField->name value: (char*)&cvalue];
			autoIncValue = cvalue;
		}

	}
	
	return autoIncValue;
}


/**/
- (unsigned long) append
{
	Field *autoIncField;
	unsigned long lvalue;
	unsigned short svalue;
	unsigned char cvalue;
	unsigned long autoIncValue = 0;
	
	autoIncField = [myTable getAutoIncField];	
	
	LOG("append el recordset %s\n", [myTable getFileName]);

	CHECK_OPEN();
	
	//si tiene un campo autoincremental, solicito el valor del autoincremental y lo seteo
	//al registro.
	if (autoIncField) {

		autoIncValue = [myTable autoIncValue];
		
		if (autoIncField->len == 2) {
			svalue = SHORT_TO_B_ENDIAN(autoIncValue);
			[self setValue: autoIncField->name value: (char*)&svalue len: autoIncField->len];
		} else if (autoIncField->len == 4) {
			lvalue = LONG_TO_B_ENDIAN(autoIncValue);
			[self setValue: autoIncField->name value: (char*)&lvalue len: autoIncField->len];
		} else {
			cvalue = autoIncValue;
			[self setValue: autoIncField->name value: (char*)&cvalue len: autoIncField->len];
		}

	}


	return autoIncValue;

}

/**/
- (BOOL) addRecordToFile: (unsigned long) anId recordBuffer: (char*) aRecordBuffer
{
	int rowsToRead = 1;
	BOOL result = FALSE;

	[myMutex lock];

	TRY

		// me posiciono en el archivo (al final)
		[SafeBoxHAL fsSeek: myFileId offset: myFileOffset + ((anId-1) * myRecordSize) whence: SEEK_SET];

		// escrivo en el archivo
		if ([SafeBoxHAL fsWrite: myFileId 
				numRows: myRecordSize / myUnitSize 
				unitSize: myUnitSize 
				buffer: aRecordBuffer] == myRecordSize / myUnitSize) result = TRUE;

	FINALLY

		[myMutex unLock];

	END_TRY

	return result;

}

/**/
- (BOOL) updateRecordToFile: (unsigned long) anId recordBuffer: (char*) aRecordBuffer fieldName: (char*) aFieldName
{
	char *buffer;
	int qty;
	unsigned char *buf;
	int rowsToRead = 1;
	Field *field;
	unsigned long value;
	BOOL result = FALSE;

	buffer = NULL;
	buffer = malloc(myRecordSize);
	memset(buffer, 0, myRecordSize);

	[myMutex lock];

	TRY

		// me posiciono en el archivo (al comienzo del registro a editar)
		[SafeBoxHAL fsSeek: myFileId offset: myFileOffset + ((anId-1) * myRecordSize) whence: SEEK_SET];
	
		// Posiciono el buffer hasta donde corresponde
		buf = &buffer[0];

		// Leo desde la memoria
		qty = [SafeBoxHAL fsRead: myFileId numRows: rowsToRead * (myRecordSize / myUnitSize) unitSize: myUnitSize buffer: buf];

		// si leyo bien sigo procesando
		if (qty == rowsToRead * (myRecordSize / myUnitSize)) {

			field = [myTable getField: aFieldName];
			value = [self getValueFromField: field buffer: buf];
	
			// verifico si el registro a actualizar es el indicado
			if (value == anId) {

				// me vuelvo a posicionar en el archivo (al comienzo del registro a editar)
				[SafeBoxHAL fsSeek: myFileId offset: myFileOffset + ((anId-1) * myRecordSize) whence: SEEK_SET];

				// escrivo en el archivo
				if ([SafeBoxHAL fsWrite: myFileId 
						numRows: myRecordSize / myUnitSize 
						unitSize: myUnitSize 
						buffer: aRecordBuffer] == myRecordSize / myUnitSize) result = TRUE;
			}
		}

	FINALLY

		free(buffer);
		[myMutex unLock];

	END_TRY

	return result;

}

/**/
- (void) writeRecordToFile
{
	unsigned char *buf;

	buf = myBuffer + (myCurrentRow * myRecordSize);

	[SafeBoxHAL fsSeek: myFileId offset: myFileOffset + myCurrentRow * (myRecordSize / myUnitSize) whence: SEEK_SET];	

	if ([SafeBoxHAL fsWrite: myFileId 
			numRows: myRecordSize / myUnitSize 
			unitSize: myUnitSize 
			buffer: myCurrentRowBuf] != myRecordSize / myUnitSize)
		THROW_MSG(GENERAL_IO_EX, myFileName);

	memcpy(GET_CURRENT_BUF, myCurrentRowBuf, myRecordSize);

}

/**/
- (unsigned long) save
{
	unsigned long autoIncValue = 0;

	LOG("save el recordset %s\n", [myTable getFileName]);
	
	CHECK_OPEN();
	
	//si no se modifico ningun valor, me voy
	if (!myIsDirty) return 0;	

	[myMutex lock];

	// si es un nuevo registro ?
	if (myIsNewRecord)	{
		
		// hago un append del registro
		autoIncValue = [self append];
		
  }	else {

		// hago un update (modificacion) del registro actual
		autoIncValue = [self update];

	}

	/**/
	TRY
		[self writeRecordToFile];
	CATCH
		LOG("error al guardar en archivo %s\n", [myTable getFileName]);
		ex_printfmt();
		memcpy(myCurrentRowBuf, GET_CURRENT_BUF, myRecordSize);
		myIsNewRecord = FALSE;
		myIsDirty = FALSE;
		[myMutex unLock];
		RETHROW();
	END_TRY


	if (myIsNewRecord) {[myTable incRecordCount];}

	[myMutex unLock];
	myIsDirty = FALSE;
	myIsNewRecord = FALSE;

	return autoIncValue;
}

/**/
- (BOOL) eof
{ 
	CHECK_OPEN();
	return (myCurrentRow >= [self getRecordCount]) || ([self getRecordCount] == 0);
}

/**/
- (BOOL) bof
{
	CHECK_OPEN();
	return (myCurrentRow < 0) || ([self getRecordCount] == 0);
}

/**/
- (unsigned long) getRecordCount
{
	return [myTable getRecordCount];
}


/**/
- (char*) getName
{
	return [myTable getName];
}


/**/
- (int) getRecordSize
{
	return myRecordSize;
}

- (BOOL) binarySearch: (char*) aFieldName value: (unsigned long) aValue
{
	long high = [self getRecordCount] - 1;
	long low = 0, middle;
	unsigned long lvalue;
	unsigned short svalue;
	unsigned char cvalue;
	unsigned long value;
	Field *field;
	
	CHECK_OPEN();

	if (high == -1) return FALSE;
	field = [myTable getField: aFieldName];

	while( low <= high ) {
		middle = ( low  + high ) / 2;
		value = 0;

		[self seek: SEEK_SET offset: middle];
		if (field->len == 2) {
			[self getValue: aFieldName value: (char*)&svalue];
			value = SHORT_TO_B_ENDIAN(svalue);
		} else if (field->len == 4) {
			[self getValue: aFieldName value: (char*)&lvalue];
			value = LONG_TO_B_ENDIAN(lvalue);
		} else {
			[self getValue: aFieldName value: (char*)&cvalue];
			value = cvalue;
		}
		
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
	return [self binarySearch: aFieldName value: aValue];
}

/**/
- (BOOL) findFirstById: (char*) aFieldName value: (unsigned long) aValue
{
	unsigned long value = -1;

	if (![self binarySearch: aFieldName value: aValue]) return FALSE;

	while ( [self movePrev] ) {
		value = 0;
		[self getValue: aFieldName value: (char*)&value];
		if ( value != aValue ) break; 
	}
  [self moveNext];
	return TRUE;
}

/**/
- (long) getCurrentPos
{
	CHECK_OPEN();
	return myCurrentRow;
}

/**/
- (void) flush
{
}

/**/
- (void) deleteAll
{
	[myMutex lock];

	[myMutex unLock];
}

@end
