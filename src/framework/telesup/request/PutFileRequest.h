#ifndef PUT_FILE_REQUEST_H
#define PUT_FILE_REQUEST_H

#define PUT_FILE_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "Request.h"
#include "cl_genericpkg.h"

/**
 * Transfiere archivos desde el sistema remoto al sistema local.  
 */
@interface PutFileRequest: Request
{		
  GENERIC_PACKAGE myPackage;

	char mySourceFileName[255];
	char myTargetFileName[255];
	char myPath[255];
}

/**/	
- (void) setTargetFileName: (char *) aFileName;
- (char *) getTargetFileName;

/**/
- (void) setSourceFileName: (char *) aFileName;
- (char *) getSourceFileName;


/**/
- (void) loadPackage: (char*) aMessage;

/**/
- (void) setPath: (char*) aMessage;

@end



#endif



