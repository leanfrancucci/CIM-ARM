#ifndef INSTA_DROP_MANAGER_H
#define INSTA_DROP_MANAGER_H

#define INSTA_DROP_MANAGER id

#include <Object.h>
#include "InstaDrop.h"
#include "CimCash.h"
#include "User.h"
#include "system/util/all.h"
#include "CashReference.h"

/**
 *	
 *	
 */
@interface InstaDropManager : Object
{
  COLLECTION myInstaDrops;
}

/**
 *  Devuelve la unica instancia posible de esta clase
 */
+ getInstance;

/**/
- (void) setInstaDrop: (int) aFunctionKey 
		user: (USER) aUser 
		cimCash: (CIM_CASH) aCimCash
		cashReference: (CASH_REFERENCE) aCashReference
		envelopeNumber: (char *) anEnvelopeNumber
    applyTo: (char *) anApplyTo;

/**/
- (void) clearAll;

/**/
- (void) clearInstaDrop: (int) aFunctionKey; 

/**/
- (void) clearInstaDropByUser: (USER) aUser; 

/**/
- (COLLECTION) getInstaDrops;

/**
 *	Debe liberar la lista (no el contenido)
 */
- (COLLECTION) getActiveInstaDrops;

/**/
- (INSTA_DROP) getInstaDropForKey: (int) aFunctionKey;

/**/
- (INSTA_DROP) getInstaDropForCash: (CIM_CASH) aCimCash;

@end

#endif
