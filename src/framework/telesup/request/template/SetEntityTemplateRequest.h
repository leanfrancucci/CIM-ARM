#ifndef SET##TEMPLATE##REQUEST_H
#define SET##TEMPLATE##REQUEST_H

#define SET_##TEMPLATE##_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "SetEntityRequest.h"


/**
 *	Activa, desactiva y configurqa ##TEMPLATE##
 */
@interface Set##TEMPLATE##Request: SetEntityRequest
{
	int							my##TEMPLATE##Ref;

	#ATTRIBUTE_TYPE#			my##ATTRIBUTE##;

}

/**
 * Los metodos de acceso al objeto
 */

- (void) set##TEMPLATE##Ref: (int) a##TEMPLATE##Ref;
- (int)  get##TEMPLATE##Ref;


- (void) set##ATTRIBUTE##: (##ATTRIBUTE_TYPE##) a##ATTRIBUTE##;
- (##ATTRIBUTE_TYPE##)  get##ATTRIBUTE##;
	
@end

#endif
