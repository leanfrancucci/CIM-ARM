#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "RecordSet.h"
#include "DB.h"
#include "DBExcepts.h"
#include "system/io/all.h"
#include "util/endian.h"
#include "util/util.h"
#include "roputil.h"

//#define printd(args...) doLog(args)
#define printd(args...)
#define LOG(args...)

/** @todo: utilizar un mutex en el delete. Manejar el tema del borrado si alguien tiene el archivo
	  abierto no lo permite. Arrojar una excepcion si no se puede eliminar. El mutex ya esta, falta
		probarlo. */
		
@implementation RecordSet

/*
	Algunos comentarios con respecto a la implementacion.
	
	El unico modo que sirve para abrir el archivo con r+b (es decir para update y binario). El unico
	problema con este modo es que si acabo de leer y quiero escribir debo hacer un seek, y se acabo de
	escribir y quiero leer tambien debo hacer un seek.

	Cada vez que se pasa a otro registro, directamente se lee la informacion en el buffer interno.
	Por ej: si hago un seek al registro 1, muevo el puntero del archivo y leo el registro en memoria.	
	Debido a esto el puntero del archivo queda posicionado en el inicio del registro 2. Ver como estan
	implementadas las funciones next y prev para tener en cuenta esta condicion.

 */

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
	myHandle = NULL;
	myRecordSize = 0;
	myIsOpen = FALSE;
	myTransaction = NULL;
	myAutoFlush	= TRUE;
	return self;
}


/**/
- free
{
	[self close];
	free(myBuffer);
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

	myTable = aTable;
	myRecordSize = [myTable getRecordSize];
	myBuffer = malloc(myRecordSize);
	myFields = [myTable getFields];
	myFieldCount = [myTable getFieldCount];
	myMutex = [myTable getMutex];
	LOG("creo el recordset %s\n", [aTable getFileName]);
	return self;
}


/**/
- (id) getTable
{
	return myTable;
}

/**/
- (void) setTransaction: (TRANSACTION) aTransaction
{
	myTransaction = aTransaction;
}

/**/
- (int) getTableId
{
	return [myTable getTableId];
}

/**/
- (int) getPartNumber
{
	return 0;
}

/**/
- (void) open
{

	strcpy(myFileName, [myTable getFileName]);

	LOG("abrio el recordset %s\n", [myTable getFileName]);

	myHandle = fopen(myFileName, "a+b");
	if (!myHandle) THROW_MSG(TABLE_NOT_FOUND_EX, myFileName);
	
	fclose(myHandle);			
		
	myHandle = fopen(myFileName, "r+b");
	
	if (!myHandle) THROW_MSG(TABLE_NOT_FOUND_EX, myFileName);
	
	// si devolvio un handle es porque el archivo existe
	if (myHandle) myIsOpen = TRUE;

}


/**/
- (void) close
{
	LOG("cerro el recordset %s\n", [myTable getFileName]);
	if (myHandle == NULL) return;
	if (!myIsOpen) return;
	fclose(myHandle);
	myHandle = NULL;
}


/**/
- (BOOL) moveFirst
{
	LOG("moveFirst el recordset %s\n", [myTable getFileName]);
	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);
	[self seek: SEEK_SET offset: 0];
	return ![self eof];
}


/**/
- (BOOL) moveBeforeFirst
{
	LOG("moveBeforeFirst el recordset %s\n", [myTable getFileName]);
	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);
	fseek(myHandle, 0, SEEK_SET);
	return ![self eof];
}


/**/
- (BOOL) moveNext
{
	LOG("moveNext el recordset %s\n", [myTable getFileName]);
	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);
	if ([self eof]) return(FALSE);

	myIsNewRecord = FALSE;
	myIsDirty = FALSE;
	/** @todo: quitar los comentarios a los mutex. En ciertos casos, y por una razon desconocida,
	    los mutex tardan demasiado y enlentecen todo el sistema */
	//[myMutex lock];
	fread(myBuffer, 1, myRecordSize, myHandle);
  //[myMutex unLock];
	
	return ![self eof];
}


/**/
- (BOOL) movePrev
{
	LOG("movePrev el recordset %s\n", [myTable getFileName]);
	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);
	if ([self bof]) return(FALSE);

	//en primer lugar, trato de retroceder 2 registros, si falla, voy al principio del archivo.
	//notar como esta implementado el moveNext y el movePrev, el next simplemente lee el contenido
	//del registro actual, y el fread hace que el puntero avance hasta el siguiente registro.
	//ademas, el prev debe volver dos posiciones para atras para luego realizar un fread y quedarse
	//posicionado solo una posicion atras.
	if ( fseek(myHandle, -2 * myRecordSize, SEEK_CUR) == 0 ) {
		[myMutex lock];
		fread(myBuffer, 1, myRecordSize, myHandle);
		[myMutex unLock];
	} else {
		fseek(myHandle, 0, SEEK_SET);
	}
	return ![self bof];
}


/**/
- (BOOL) moveLast
{
	LOG("moveLast el recordset %s\n", [myTable getFileName]);
	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);
	if ( [self bof] && [self eof] ) return FALSE;
	[self seek: SEEK_END offset: -1];
	return ![self bof];
}


/**/
- (BOOL) moveAfterLast
{
	LOG("moveAfterLast el recordset %s\n", [myTable getFileName]);
	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);
	fseek(myHandle, myRecordSize, SEEK_END);
	fread(myBuffer, 1, myRecordSize, myHandle); 
	return ![self bof];
}


/**/
- (void) seek: (int) aDirection offset: (int) anOffset
{
	LOG("seek el recordset %s\n", [myTable getFileName]);
	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);
	myIsNewRecord = FALSE;
	myIsDirty = FALSE;
	if ( fseek(myHandle, anOffset * myRecordSize, aDirection) != 0 ) return ;
	if (!feof(myHandle)) {
		[myMutex lock];
		fread(myBuffer, 1, myRecordSize, myHandle);
		[myMutex unLock];
	}
}


/**/
- (void) setValue: (char*)aFieldName value:(char*)aValue len:(int)aLen
{
	Field *field;
	myIsDirty = TRUE;
	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);
	if ([self eof] && !myIsNewRecord) THROW_MSG(NO_CURRENT_RECORD_EX, myFileName);
	for (field = &myFields[0]; field < myFields + myFieldCount; field++) {
		if (strcmp(field->name, aFieldName) == 0) {
			
			if (field->type == ROP_STRING) {
				aLen = (aLen < field->len && aLen != -1) ? aLen : field->len-1;
				strncpy2(myBuffer + field->offset, aValue, aLen);
			}	else {
				aLen = (aLen < field->len && aLen != -1) ? aLen : field->len;
			//	if (aLen != field->len) doLog(0, "Warning: field size does not match, field %s, size (argument) %d, field size %d\n", aFieldName, aLen, field->len);
				memcpy(myBuffer + field->offset, aValue, aLen);
			}
			return;
		}
	}

	THROW_MSG(FIELD_NOT_FOUND_EX, aFieldName);
}


/**/
- (void) getValue: (char*)aFieldName value:(char*)aValue
{
	Field *field;
	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);
//	if ([self eof]) THROW_MSG(NO_CURRENT_RECORD_EX, myFileName);
	if (ftell(myHandle) <= 0 && !myIsNewRecord) THROW_MSG(NO_CURRENT_RECORD_EX, myFileName);
	//if (ftell(myHandle) < 0) THROW_MSG(NO_CURRENT_RECORD_EX, myFileName);
	
	for (field = &myFields[0]; field < myFields + myFieldCount; field++) {
		if (strcmp(field->name, aFieldName) == 0) {
			memcpy(aValue, myBuffer + field->offset, field->len);					
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

	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);
	
	if (ftell(myHandle) <= 0 && !myIsNewRecord) THROW_MSG(NO_CURRENT_RECORD_EX, myFileName);

  for (field = &myFields[0]; field < myFields + myFieldCount; field++) {
		if (strcmp(field->name, aFieldName) == 0) {
      len = field->len;
			memcpy(aBuffer, myBuffer + field->offset, field->len);
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
	memcpy(myBuffer, aBuffer, myRecordSize);
	myIsDirty = TRUE;
}


/**/
- (char*) getRecordBuffer
{
	return myBuffer;
}


/**/
- (void) add
{
	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);	
	memset(myBuffer, 0, myRecordSize);
	myIsNewRecord = TRUE;
	LOG("add el recordset %s\n", [myTable getFileName]);
}


/**/
- (void) delete
{
	char name[255];
	int  i, result;
	FILE *tmp;
	int  recordCount = [self getRecordCount];
	int	 pos = ftell(myHandle) / myRecordSize - 1;
	
	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);
	
	[myMutex lock];
	
	TRY
	
		strcpy(name, myFileName);
		strcat(name, ".tmp");
		
		tmp = fopen(name, "a+b");
		fseek(myHandle, 0, SEEK_SET);
		
		// copio los primeros n registros
		for (i = 0; i < pos; i++) {
			fread(myBuffer, 1, myRecordSize, myHandle);
			fwrite(myBuffer, 1, myRecordSize, tmp);
		}
		
		// me salteo el que deseo elimininar
		fseek(myHandle, myRecordSize, SEEK_CUR);
	
		// copio los siguientes registros	
		for (i = pos+1; i < recordCount; ++i) {
			fread(myBuffer, 1, myRecordSize, myHandle);
			fwrite(myBuffer, 1, myRecordSize, tmp);
		}
		
		fclose(myHandle);
		fclose(tmp);

	//	doLog(0,"Moviendo archivo de %s a %s\n", name, myFileName);
		result = rename(name, myFileName);
	/*	if (result != 0)
			doLog(0,"Error: No se pudo mover de %s a %s, error = %d\n", name, myFileName, result);
*/
		[self open];
		[myTable decRecordCount];

	FINALLY 

		[myMutex unLock];
	
	END_TRY		
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
	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);
	
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
	
	fseek(myHandle, -1 * myRecordSize, SEEK_CUR);
	
	if (myTransaction) {
		[myTransaction updateRecord: self entityId: [self getTableId] 
			entityPart: [self getPartNumber] recNo: ftell(myHandle) / myRecordSize];
	}
	
	return autoIncValue;
}


/**/
- (unsigned long) append
{
	Field *autoIncField;
	unsigned long autoIncValue = 0;
	unsigned long lvalue;
	unsigned short svalue;
	unsigned char cvalue;
	
	autoIncField = [myTable getAutoIncField];	
	
	LOG("append el recordset %s\n", [myTable getFileName]);

	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);
	
	if (!myIsOpen) {
		//si no existe, lo abro en este modo, que lo crea
		myHandle = fopen(myFileName, "a+b");	  
		fclose(myHandle);
		//lo vuelvo abrir en el modo original, una vez creado
		myHandle = fopen(myFileName, "r+b");		
		if (!myHandle) {
			[myMutex unLock];
			THROW_MSG(GENERAL_IO_EX, myFileName);
		} else
			myIsOpen = TRUE;
	}

	//es un nuevo registro, me paro al final del archivo
	/** @todo: agregado como optimizacion el if feof() */
	if (!feof(myHandle)) {

		fseek(myHandle, 0, SEEK_END);
		/** @todo: no me acuerdo porque hace un fread */
//		fread(&cvalue, 1, 1, myHandle);

	}
	
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

	if (myTransaction) { 
		[myTransaction appendRecord: self entityId: [self getTableId] 
			entityPart: [self getPartNumber] recNo: ftell(myHandle) / myRecordSize];
	}
	
	return autoIncValue;

}


/**/
- (unsigned long) save
{
	unsigned long autoIncValue = 0;

	LOG("save el recordset %s\n", [myTable getFileName]);
	
	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);
	
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

	if ( fwrite(myBuffer, 1, myRecordSize, myHandle) != myRecordSize ) {
		[myMutex unLock];
		THROW_MSG(GENERAL_IO_EX, myFileName);
	}

	if (myIsNewRecord) [myTable incRecordCount];

	if (myAutoFlush) fflush(myHandle);

	[myMutex unLock];
	myIsDirty = FALSE;
	myIsNewRecord = FALSE;

	return autoIncValue;
}


/**/
- (BOOL) eof
{
	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);
	if ([myTable getRecordCount] == 0) return TRUE;
	return feof(myHandle);
}


/**/
- (BOOL) bof
{
	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);
	return ftell(myHandle) == 0;
}


/**/
- (unsigned long) getRecordCount
{
	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);

/** @optimizacion: ver si hay que dejar esta linea o comentarla */
	clearerr(myHandle);

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

/**/
- (BOOL) binarySearch: (char*) aFieldName value: (unsigned long) aValue
{
	long high = [self getRecordCount] - 1;
	long low = 0, middle;
	unsigned long value;
	unsigned short svalue;
	unsigned char cvalue;
	Field *field;
	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);
	if (high == -1) return FALSE;
	
	field = [myTable getField: aFieldName];

	while( low <= high ) {
		middle = ( low  + high ) / 2;
		value = 0;
		[self seek: SEEK_SET offset: middle];
		
		
		if (field->len == 2) {
			[self getValue: aFieldName value: (char*)&svalue];
			svalue = B_ENDIAN_TO_SHORT(svalue);
			value = svalue;
		} else if (field->len == 4) {
			[self getValue: aFieldName value: (char*)&value];
			value = B_ENDIAN_TO_LONG(value);
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
- (long) getCurrentPos
{
	if (!myIsOpen) THROW_MSG(TABLE_NOT_OPEN_EX, myFileName);
	return ftell(myHandle) / myRecordSize;
}

/**/
- (void) flush
{
	fflush(myHandle);
}

/**/
- (void) deleteAll
{
	[myMutex lock];

	fflush(myHandle);

	[self close];

	if ( remove([myTable getFileName]) != 0 ) {
        ;
		//	if (errno != ENOENT) doLog(0,"CANNOT REMOVE FILE %s\n", [myTable getFileName]);
	}

	[myTable loadAutoIncValue];
	[myTable loadRecordCount];

	[self open];

	[myMutex unLock];
}

/**/
- (void) setInitialAutoIncValue: (unsigned long) aValue
{
	[myTable setInitialAutoIncValue: aValue];
}
@end
