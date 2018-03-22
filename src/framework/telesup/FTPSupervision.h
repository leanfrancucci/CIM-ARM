#ifndef FTP_SUPERVISION_H
#define FTP_SUPERVISION_H

#define FTP_SUPERVISION id

#include <Object.h>
#include "system/os/all.h"
#include "system/util/all.h"
#include "ctapp.h"

/**
 *	<<thread>> 
 *	<<singleton>>
 */
@interface FTPSupervision : Object
{
	char *myPath;
	char *myWPutCmd;
	id myTelesupViewer;
}

/**
 *  Devuelve la unica instancia posible de esta clase
 */
+ getInstance;

/**/
- (void) setTelesupViewer: (id) aTelesupViewer;
- (void) startFTPSupervision;
- (BOOL) ftpServerAllowed;

@end

#endif
