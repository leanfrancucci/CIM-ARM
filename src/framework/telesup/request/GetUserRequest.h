#ifndef GET_USER_REQUEST_H
#define GET_USER_REQUEST_H

#define GET_USER_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "GetDataFileRequest.h"


/**
 *	Obtiene los depositos generados en el sistema
 */
@interface GetUserRequest: GetDataFileRequest
{	
	char myBuffer[4096];
	int myUserId;
}
 
/**
 * Indica si se solicitaron todos los usuarios o los hijos de un usuario determinado
 */
- (void) setUserId: (int) aUserId;
			
@end

#endif

