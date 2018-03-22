#ifndef FILTERED_RECORDSET_H
#define FILTERED_RECORDSET_H

#define FILTERED_RECORDSET 		id

#include <Object.h>
#include "system/lang/all.h"
#include "AbstractRecordSet.h"
#include "DataSearcher.h"

/**
 * Es una clase que permite manipular la informacion de la tabla con capacidades
 * de filtrado de datos agregadas. 
 * Mantiene un DataSearcher interno para filtrar los datos de la tabla.
 * Tiene toda la funcionalidad de los Recordset implementada excepto que solo
 * es posible mover el RecordSet hacia adelante (forward).
 * Tiene implementado los metodos findById() y binarySearch() para buscar por identificadores
 * de registros.
 *
 * Cuando se abre el RecordSet se hace un moveBeforeFirst().
 *
 * Se inicializa el Recordset con initWithRecordset() o con setRecordset() pasandole
 * un Recordset previamente creado.
 *
 * El Recordset filtrado se debe recorrer con el metodo moveNext(). Solo este metodo de 
 * navegacion esta implementado. Los demas metodos de navegacion lanzan la 
 * excepcion FEATURE_NOT_IMPLEMENTED_EX.
 *
 * cuando se liber la instancia se liber tambien el Recordset asociado.
 *
 * Es un decorator de la clase AbstractRecordset.
 */
@interface FilteredRecordSet: AbstractRecordSet
{
	ABSTRACT_RECORDSET 		myRecordSet;	
	DATA_SEARCHER 			myDataSearcher;
}

/**
 * Inicializa la instancia con el Recordset adecuado.
 * @param (ABSTRACT_RECORDSET) aRecordSet es un recordset previamente creado e inicializado con
 * la tabla correspondiente. 
 */
- initWithRecordset: (ABSTRACT_RECORDSET) aRecordset;

/**
 * Inicializa la instancia con el Recordset adecuado.
 * @param (ABSTRACT_RECORDSET) aRecordSet es un recordset previamente creado e inicializado con
 * la tabla correspondiente. 
 */
- (void) setRecordset: (ABSTRACT_RECORDSET) aRecordset;

/**
 * Los metodos agregados de filtrado de registros
 */
 
/**
 *	Limpia los filtros configurados actualmente
 */
- (void) clearFilters;

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

 
@end

#endif
