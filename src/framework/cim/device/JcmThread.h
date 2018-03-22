#ifndef JCM_THREAD_H
#define JCM_THREAD_H

#define JCM_THREAD id

#include <Object.h>
#include "ctapp.h"
#include "system/os/all.h"

/**
 *	doc template
 */

typedef void (*ExecFunction)(void* obj);

@interface JcmThread : OThread
{
	ExecFunction threadExecFun;
	void* myObjectPtr;
}


- ( void ) setExecFun: (ExecFunction) execfun;
- ( void ) setObjectPtr: (void*) objPtr;

@end

#endif
