#ifndef DATA_SEARCHER_H
#define DATA_SEARCHER_H

#define DATA_SEARCHER id

#include <Object.h>
#include "system/db/all.h"
#include "ctapp.h"


/** Cantidad maxima de filtros posibles. */
#define DS_MAX_FILTERS 5

/** Tamano maximo de nombre del campo */
#define DS_MAX_FIELD_SIZE 30

/**
 *	Una estructura para mantener los filtros que me pasan como parametro.
 */
typedef struct {
	char name[DS_MAX_FIELD_SIZE+1];		// nombre del campo
	int  operator;		// operador ("=", "!=", ">", "<")
	int  dataType;		// tipo de datos
	long long value;	// valor (en caso de un string se guarda el puntero a la cadena)
} FilterRec;

/**
 *	Encapsula la busqueda de datos dentro de un RecordSet utilizando filtros.
 *	Debe hacerce un clear() antes de configurar los filtros.
 *	Tener en cuenta que este objeto mueve la posicion actual del recordset pasado como 
 *	parametro y no la restaura.  
 *
 *	La primera vez que se llama al findNext(), luego de un clear() y si nunca se llamo al find(),
 *	el metodo se posiciona en el primer registro y comienza a recorrer desde ahi. Esto es
 *	util para recorrer el recordset facilmente. Por ejemplo:
 *	[searcher clear];
 *	...agregar filtros...
 *	while ( [searcher findNext] ) {
 *		...hago algo con los datos del recordset...
 *	}
 */
@interface DataSearcher : Object
{
	ABSTRACT_RECORDSET myRecordSet;
	FilterRec myFilters[DS_MAX_FILTERS];
	int myCurrentFilter;
	BOOL firstCall;
	id myObserver;
}

/**
 *	Setea el recordset a utilizar para la busqueda de datos.
 */
- (void) setRecordSet: (ABSTRACT_RECORDSET) aRecordSet;

/**
 *	Limpia los filtros configurados actualmente
 */
- (void) clear;

/**
 *	Agrega un filtro para un field de tipo short.
 *	@param fieldName el nombre del campo.
 *	@param operator el tipo de operador. Valores posibles ("=", "!=", ">", "<", "<=", ">=").
 *	@param value el valor del filtro.
 */
- (void) addCharFilter: (char*)aFieldName operator: (char*)anOperator value: (char) aValue;

/**
 *	Agrega un filtro para un field de tipo short.
 *	@param fieldName el nombre del campo.
 *	@param operator el tipo de operador. Valores posibles ("=", "!=", ">", "<", "<=", ">=").
 *	@param value el valor del filtro.
 */
- (void) addShortFilter: (char*)aFieldName operator: (char*)anOperator value: (short) aValue;

/**
 *	Agrega un filtro para un field de tipo long.
 *	@param fieldName el nombre del campo.
 *	@param operator el tipo de operador. Valores posibles ("=", "!=", ">", "<", "<=", ">=").
 *	@param value el valor del filtro.
 */
- (void) addLongFilter: (char*)aFieldName operator: (char*)anOperator value: (long) aValue;

/**
 *	Agrega un filtro para un field de tipo datetime.
 *	@param fieldName el nombre del campo.
 *	@param operator el tipo de operador. Valores posibles ("=", "!=", ">", "<", "<=", ">=").
 *	@param value el valor del filtro.
 */
- (void) addDateTimeFilter: (char*)aFieldName operator: (char*)anOperator value: (datetime_t) aValue;

/**
 *	Agrega un filtro para un field de tipo string.
 *	No se copia la cadena internamente, solo se guarda la referencia.
 *	@param fieldName el nombre del campo.
 *	@param operator el tipo de operador. Valores posibles ("=", "!=", ">", "<", "<=", ">=").
 *	@param value el valor del filtro.
 */
- (void) addStringFilter: (char*)aFieldName operator: (char*)anOperator value: (char*) aValue;

/**
 *	Busca en el recordset de acuerdo a los filtros configurados.
 *	Se queda posicionado en el lugar donde encuentra la coincidencia.
 *	@return TRUE si encontro algun valor que coincida, FALSE en caso contrario.
 */
- (BOOL) find;

/**
 *	Busca la siguiente coincidencia en el recordset de acuerdo a los filtros configurados.
 *	Se queda posicionado en el lugar donde encuentra la coincidencia.
 *	@return TRUE si encontro algun valor que coincida, FALSE en caso contrario.
 */
- (BOOL) findNext;

/**/
- (void) setObserver: (id) anObserver;

@end

#endif
