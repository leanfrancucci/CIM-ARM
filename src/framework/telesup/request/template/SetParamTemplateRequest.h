#ifndef SET##TEMPLATE##REQUEST_H
#define SET##TEMPLATE##REQUEST_H

#define SET_##TEMPLATE##_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "SetParamRequest.h"


/**
 *	Configura elprotocolo de ##TEMPLATE##
 */
@interface Set##TEMPLATE##Request: SetParamRequest
{

		##ATTRIBUTE_TYPE## 	my##ATTRIBUTE##;
}		
	

/**
 * Los metodos de acceso al objeto
 */

- (void) set##ATTRIBUTE##: (##ATTRIBUTE_TYPE##) a##ATTRIBUTE##;
- (##ATTRIBUTE_TYPE##)  get##ATTRIBUTE##;
		
@end

#endif
