#ifndef GET_FILE_REQUEST_H
#define GET_FILE_REQUEST_H

#define GET_FILE_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "Request.h"

/**
 *  Transfiere archivos desde el sistema local al sistema remoto.  
 */
@interface GetFileRequest: Request
{		
	char		mySourceFileName[255];
	char		myTargetFileName[255];
}			

/**/	
- (void) setTargetFileName: (char *) aFileName;
- (char *) getTargetFileName;

/**/
- (void) setSourceFileName: (char *) aFileName;
- (char *) getSourceFileName;
			
@end

#endif



