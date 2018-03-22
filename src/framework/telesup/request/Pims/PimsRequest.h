#ifndef PIMS_REQUEST_H
#define PIMS_REQUEST_H

#define PIMS_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "Request.h"
#include "cl_genericpkg.h"

/**
 *	
 */
@interface PimsRequest: Request
{
	char	*myMessage;
	GENERIC_PACKAGE myPackage;
	id myViewer;
}		

- (void) setMessage: (char *)aMessage;
- (void) setViewer: (id) aViewer;

@end

#endif
