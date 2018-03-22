#ifndef CASH_REFERENCE_MANAGER_H
#define CASH_REFERENCE_MANAGER_H

#define CASH_REFERENCE_MANAGER id

#include <Object.h>
#include "CashReference.h"
#include "system/util/all.h"

/**
 *	
 *	
 */
@interface CashReferenceManager : Object
{
  COLLECTION myReferences;
}

/**
 *  Devuelve la unica instancia posible de esta clase
 */
+ getInstance;

/**
 *	Devuelve la lista de cash references hijos para el reference
 *	pasado como parametro.
 */
- (void) getCashReferenceChilds: (COLLECTION) aCollection cashReference: (CASH_REFERENCE) aCashReference;

/**/
- (COLLECTION) getCashReferences;

/**/
- (int) addCashReference: (char *) aName parentId: (int) aParentId;


/**
 *
 */
- (void) addCashReference: (CASH_REFERENCE) aCashReference;

/**/
- (void) removeCashReference: (CASH_REFERENCE) aCashReference;

/**/
- (CASH_REFERENCE) getCashReferenceById: (int) aCashReferenceId;


@end

#endif
