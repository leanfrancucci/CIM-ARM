#ifndef COLLECTION_H
#define COLLECTION_H

#ifndef COLLECTION
  #define COLLECTION id
#endif

#include <Object.h>
#include "system/lang/all.h"
#include "system/os/all.h"

/**
 *	Implementa una colleccion de elementos.
 *  Wrapea la OrdCltn (OrderedCollection) del Objective-C
 *	
 */
@interface Collection: Object
{
	id			myCollection;
}

/**
 * Remueve y libera todos los miembros de la coleccion.
 * @return (id) retorna self
 */
- freeContents;

/**
 *	Remueve y libera todos los miembros de la coleccion como punteros "C". Se supone que en la coleccion
 *	hay punteros y llama a free() de cada puntero
 *	@return (id) retorna self
 */
- freePointers;

/**
 * Retorna el numero de elementos en la coleccion
 */
- (unsigned) size;

/**
 * Rettorna TRUE cuando el numero de elementos de la coleccion es cero.
 */
- (BOOL) isEmpty;

/**
 * Retorna el primer elemento de la coleccion.
 * Si no hay elementos retorna NULL.
 */ 
- firstElement;

/**
 * Retorna el ultimo elemento de la coleccion.
 * Si no hay elementos retorna NULL.
 */ 
- lastElement;


/**
 * Retirna TRUE (YES) so aCltn es una coleccion, y si cada elemento responde afirmativamente
 * al mensaje isEqual:  cuando es comparado con el correspondiente miembro del receiver.
 */
- (BOOL) isEqual: (id) aCltn;

 

/**
 * Agrega  anObject en la coleccion n l ultim posicion.
 * @returns self 
 */
- add: (id) anObject;

/**
 * Agrega newObject en el primer lugar de la acoleccion (zero-th).
 * todo slos elementos son relocalizados a la siguiente posicion.
 * @returns self.
 */ 
- addFirst: (id) newObject;
 
/**
 * Identico al metodo  add:
 */
- addLast: (id) newObject;

/**
 * Retorna el objecto en anOffset.
 * el primer objecto se encuentra en el offset 0 y el ultimo se encuentra en size - 1.
 * Si anOffset es mayor que el ultimo offset de la coleccion lanza la excepcion COL_OUT_OF_BOUNDS_EX.
 * @throws  COL_OUT_OF_BOUNDS_EX 
 */ 
- at: (unsigned) anOffset;

/**
 * Reemplaza el objeto en anOffset en anObject y retorna el antiguo miembro en anOffset y 
 * retorna nil si anObject es nil.
 * Si anOffset es mayor que el ultimo offset de la coleccion lanza la excepcion COL_OUT_OF_BOUNDS_EX.
 * @throws  COL_OUT_OF_BOUNDS_EX 
 */
- at: (unsigned) anOffset put: (id) anObject;

/**
 * Inserta el objeto en anOffset en anObject y retorna el antiguo miembro en anOffset y
 * retorna nil si anObject es nil.
 * Si anOffset es mayor que el ultimo offset de la coleccion lanza la excepcion COL_OUT_OF_BOUNDS_EX.
 * @throws  COL_OUT_OF_BOUNDS_EX 
 */
- at: (unsigned) anOffset insert: (id) anObject;

/** 
 * Remueve el primer elemento. 
 * @return el elemento o nil si no hay elementos.
 */ 
- removeFirst;
 

/**
 * Remueve el ultimo elemento. Retorna el elemento o nil si no hay elementos.
 */
- removeLast;

/**
 *	Remueve todos los elementos de la colleccion (pero no los libera).
 */
- removeAll;

/**
 * Remueve el objeto en anOffset. Cuendo el objeto es removido los elementos restantes son 
 * ajustados adecuadamente cambiando los offsets de cada elemento. 
 * Si anOffset es mayor que el ultimo offset de la coleccion lanza la excepcion COL_OUT_OF_BOUNDS_EX.
 * @return el elemento removido
 * @throws  COL_OUT_OF_BOUNDS_EX  
 */ 
- removeAt: (unsigned) anOffset;
 
/**
 * Remueve  oldObject de la coleccion si oldObject es encontrado.
 * @return oldObject si es encontrado o nil en caso contrario..
 */
- remove: (id) oldObject;
 
/**
 * Retorna el primer elemento identico (same) a anObject. La comparacion se realiza comparando
 * los punteros de los objectos.
 * @return el objeto que hace match o nil si no se encuentra ninguno.
 */ 
- find: (id) anObject;

/**
 * Retorna el primer elemento igual (equal) a anObject. La comparacion se realiza comparando
 * enviando mensajes isEqual: a los objectos comparados.
 * @return el objeto que hace match o nil si no se encuentra ninguno.
 */
- findMatching: (id) anObject;

/**
 * Retorna TRUE (YES) so anObject se encuentra en la coleccion (comparando con isEqual:). 
 */ 
- (BOOL) includes: (id) anObject;
 
/**
 * Retorna el primer elemento que matchea su contenido string  con aString, usando el 
 * metodo isEqualSTR: para la comparacion.
 * Si no se encuentra retorna nil.
 */
- findSTR: (STR) aString;
 
/**
 * Retorna TRUE (YES) si el receiver contiene anObject. La implementacion esta en terminos
 * del metodo find: del receiver (el cual es isSame: , no isEqual:).
 */
- (BOOL) contains: (id) anObject;
 

/**
 * Busca anObject en el contenido de la coleccion y retorna el offset del primer puntero igual 
 * al objeto encontrado. retorna (unsigned)-1 i no se encuentra o si anObject es nil.
 */ 
- (unsigned) offsetOf: (id) anObject;

/**
 *  Clona la lista actual, copiando la referencia de los elementos (no clona los elementos).
 */
- (COLLECTION) clone;

@end

#endif
