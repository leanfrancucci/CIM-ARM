#ifndef GET_GENERIC_FILE_REQUEST_H
#define GET_GENERIC_FILE_REQUEST_H

#define GET_GENERIC_FILE_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "Request.h"
#include "GetFileRequest.h"

/**
 *  Transfiere archivos desde el sistema local al sistema remoto.  
 */
@interface GetGenericFileRequest: GetFileRequest
{		
 //Atributo
	BOOL mySendAllLogsCompressed;
  char myPathName[50];
	BOOL myDataNeeded;
}			

/**
 * Setea si se debe enviar todos los archivos de logs comprimidos.
 */

- (void) setCompressed: (BOOL) aValue;
- (void) setPathName: (char *) aPathName;
- (void) setDataNeeded: (BOOL) aValue;
			
@end

#endif


