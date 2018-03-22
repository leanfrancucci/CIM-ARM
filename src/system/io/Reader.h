#ifndef READER_H
#define READER_H

#define READER id

#include <Object.h>
#include "IOExcepts.h"

/**
 *	Clase base para todos los Reader
 */
@interface Reader : Object
{

}


/**/



- (int) read: (char *)aBuf qty:(int) aQty;
- (void) seek: (int)aQty from: (int) aFrom; 
- (void) close;
- (void) flush;


@end

#endif
