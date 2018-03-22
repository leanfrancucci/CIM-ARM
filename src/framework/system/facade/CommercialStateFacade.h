#ifndef COMMERCIAL_STATE_FACADE_H
#define COMMERCIAL_STATE_FACADE_H

#define COMMERCIAL_STATE_FACADE id

#include <Object.h>
#include "ctapp.h"
#include "CommercialState.h"

/**
 * <<singleton>>	
 */

@interface CommercialStateFacade : Object
{
}

+ new;
+ getInstance;
- initialize;

/**
* SET
*/

/*
 * State (1- Habilitado/2- Deshabilitado/3- Demo/4- Suspendido)
 */

- (void) setParamAsInteger: (char*) aParam value: (int) aValue;

/**
* GET
*/

/*
 * State
 */

- (int) getParamAsInteger: (char*) aParam;

/*
 * Aplica los cambios realizados sobre la instancia del estado comercial del sistema
 */
 
- (void) applyChanges;



@end

#endif
