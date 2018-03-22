#ifndef TEST_THREAD_H
#define TEST_THREAD_H

#define TEST_THREAD id

#include <Object.h>
#include "ctapp.h"
#include "system/net/all.h"
#include "system/os/all.h"
#include "TelesupDefs.h"
#include "RemoteConsole.h"

/**
 *	Espera una conexion entrante y larga una supervision una vez que se conecta.
 *	
 */
@interface TestThread : OThread
{
    id myReader;
}

/**/
+ new;

/**/
- initialize;
- (void) setReader: (id) aReader;


@end

#endif
