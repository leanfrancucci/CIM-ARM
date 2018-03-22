#ifndef GET_LOG_REQUEST_H
#define GET_LOG_REQUEST_H

#define GET_LOG_REQUEST 

#include <Object.h>
#include "ctapp.h"

#include "Request.h"

/**
 *  Transfiere archivos desde el sistema local al sistema remoto.  
 */
@interface GetLogRequest: GetFileRequest
{		
	BOOL mySendAllLogsCompressed;
}			

/**
 * Setea si se debe enviar todos los archivos de logs comprimidos.
 */
- (void) sendAllLogsCompressed: (BOOL) aValue;
			
@end

#endif



