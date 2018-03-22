#ifndef TEMPLATE_H
#define TEMPLATE_H

#define TEMPLATE id

#include <Object.h>
#include "ctapp.h"

/**
 *	doc template
 *	<<singleton>>
 */
@interface Template : Object
{

}

/**
 *  Devuelve la unica instancia posible de esta clase
 */
+ getInstance;

@end

#endif
