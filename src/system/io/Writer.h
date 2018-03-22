#ifndef WRITER_H
#define WRITER_H

#define WRITER id

#include <Object.h>
#include "IOExcepts.h"

/**
 *	Clase base para todos los Writer
 */
@interface Writer : Object
{

}


- (void) close;
- (int) write: (char *)aBuf qty:(int) aQty;
- (void) seek: (int)aQty from: (int) aFrom;
- (void) flush;

@end

#endif
