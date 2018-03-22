#ifndef ABSTRACT_RECORD_SET_H
#define ABSTRACT_RECORD_SET_H

#define ABSTRACT_RECORDSET id

#include <Object.h>
#include "system/lang/all.h"

/**
 *	Es una clase que permite manipular la información de la tabla. 
 *	Con este objeto se pueden insertar, eliminar, recorrer los registros y 
 *	obtener el valor de cada uno de los campos.
 *	Maneja ademas el endian de los tipos de datos, dependiendo de la platforma.
 *	Los datos siempre son almacenados en BIG-ENDIAN, pero esta clase los contrario
 *	convierte al endin de la plataforma.
 *	Es abstracta.
 */
@interface AbstractRecordSet : Object
{
	BOOL myAutoFlush;
}


/**
 *	Inicializa el recordset con el nombre de la tabla pasado como parametro.
 */
- initWithTableName: (char*) aTableName;

/**
 *	Abre el recordset. 
 *	Debe abrirse el recordset antes de poder utilizarlo con cualquiera de las demas funciones.
 */
- (void) open;

/**
 *	Cierra el recordset.
 *	Debe llamarse a este metodo cuando se deje de utilizar el recordset.
 */
- (void) close;

/**
 *	Se posiciona en el primer registro del recordset.
 */
- (BOOL) moveFirst;

/**
 *	Se posiciona antes del primer registro del recordset.
 *	Con el primer moveNext() se pasa al primer registro.
 *	Es util para recorrer el recordset. Generalmente, la forma de hacerlo es:
 *		[rs moveBeforeFirst];
 *		while ( [rs moveNext] ) {
 *			..do something
 *	  }
 */
- (BOOL) moveBeforeFirst;

/**
 *	Se posiciona en el siguiente registro del recordset.
 *
 *	Es util para recorrer el recordset. Generalmente, la forma de hacerlo es:
 *		[rs moveBeforeFirst];
 *		while ( [rs moveNext] ) {
 *			..do something
 *	  }
 *
 *	@return TRUE si hay mas registos, FALSE en caso contrario.
 */
- (BOOL) moveNext;

/**
 *	Se posiciona en el registro anterior del recordset.
 *
 *	@return TRUE si no llego al principio del recodset, FALSE en caso contrario.
 */
- (BOOL) movePrev;

/**
 *	Se posiciona en el ultimo registro del recordset.
 */
- (BOOL) moveLast;

/**
 *	Se posiciona despues del ultimo registro del recordset.
 *	Con el primer movePrev() se pasa al ultimo registro.
 *	Es util para recorrer el recordset al reves. Generalmente, la forma de hacerlo es:
 *		[rs moveAfterLast];
 *		while ( [rs movePrev] ) {
 *			..do something
 *	  }
 */
- (BOOL) moveAfterLast;

/**
 *	Se posiciona en un registro particular del recordset, de acuerdo a la direccion (SEEK_SET,
 *	SEEK_CUR y SEEK_SET) y un offset.
 */
- (void) seek: (int) aDirection offset: (int) anOffset;

/**
 *	Funciones para setear valores a un registro
 */
- (void) setValue: (char*)aFieldName value:(char*)aValue len:(int)aLen;
- (void) setStringValue: (char*) aFieldName value: (char*)aValue;
- (void) setCharValue: (char*) aFieldName value: (char)aValue;
- (void) setShortValue: (char*) aFieldName value: (short)aValue;
- (void) setLongValue: (char*) aFieldName value: (long)aValue;
- (void) setCharArrayValue: (char*) aFieldName value: (char*)aValue;
- (void) setDateTimeValue: (char*) aFieldName value: (datetime_t)aValue;
- (void) setMoneyValue: (char*) aFieldName value: (money_t)aValue;
- (void) setBoolValue: (char*) aFieldName value: (BOOL) aValue;
- (void) setBcdValue: (char*) aFieldName value: (char*)aValue;

/**
 *	Funciones para recuperar valores de un registro
 */
- (void) getValue: (char*)aFieldName value:(char*)aValue;
- (char*) getStringValue: (char*) aFieldName buffer: (char*)aBuffer;
- (char*) getCharArrayValue: (char*) aFieldName buffer: (char*)aValue;
- (char) getCharValue: (char*) aFieldName;
- (short) getShortValue: (char*) aFieldName;
- (long)  getLongValue: (char*) aFieldName;
- (datetime_t) getDateTimeValue: (char*) aFieldName;
- (money_t) getMoneyValue: (char*) aFieldName;
- (BOOL) getBoolValue: (char*) aFieldName;
- (char*) getBcdValue: (char*) aFieldName buffer: (char*)aBuffer;

/**
 *	Agrega un registro al recordset, siempre se agregan al final de la tabla.
 */
- (void) add;

/**
 *	Elimina el registro actual de la tabla.
 */
- (void) delete;

/**
 *	Graba el registro actual, independientemente si es un registro nuevo o uno modificado.
 *	@return Devuelve el ID del autoincremental si corresponde.
 */
- (unsigned long) save;

/**
 *	Devuelve TRUE si esta al final del recordset, FALSE caso contrario.
 */
- (BOOL) eof;

/**
 *	Devuelve TRUE si esta al inicio del recordset, FALSE caso contrario.
 */
- (BOOL) bof;

/**
 *	Devuelve la cantidad de registros en el Record set.
 */
- (unsigned long) getRecordCount;

/**
 *	Devuelve el tamaño del registro en cantidad de bytes.
 */
- (int) getRecordSize;

/**
 *	Busqueda binaria dentro del RecordSet.
 *	Es un requisito para la busqueda binaria que la Tabla este ordenada por el campo pasado
 *	como parametro.
 *	Si existe la clave pasada como parametro, se queda posicionada en ese registro y devuelve
 *	TRUE, FALSE en caso contrario.
 *
 */
- (BOOL) binarySearch: (char*) aFieldName value: (unsigned long) aValue;

/**
 *
 */
- (BOOL) findById:  (char*) aFieldName value: (unsigned long) aValue;
- (BOOL) findFirstById: (char*) aFieldName value: (unsigned long) aValue;
- (BOOL) findFirstFromId: (char*) aFieldName value: (unsigned long) aValue;

/**
 *	Devuelve el nombre de la tabla.
 */
- (char*) getName;

/**
 *	Devuelve la posicion en la que se encuentra actualmente. El resultado es en numero
 *	de registro y no en bytes. Si esta posicionado en el primer registro, retorna 0.
 *	
 */
- (long) getCurrentPos;

/**
 *
 */
- (int) getTableId;

- (void) setAutoFlush: (BOOL) aValue;
- (void) flush;

/**/
- (void) deleteAll;

@end

#endif
