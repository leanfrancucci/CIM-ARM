#include "osrt.h"
#include "OSemaphore.h"

//void doLog(char addHour,char *fmt, ...);

@implementation OSemaphore

+ new
{
	return [[super new]initialize];
}

/*
 *	Metodo que inicializa el semaforo.
 */
- initialize
{
	myCount = 0;
	return self;
}

- initWithCount: (int)aCount
{
	myCount = aCount;
	if ( semInit(&mySem, myCount) == -1 ) {
	//	doLog(0,"Error creating sempahore\n");
	}
	return self;
}

/*
 * 	Destruye el semaforo
 */

- free
{
	semDestroy(&mySem);
	return [super free];
}

/*
 *
 */

- (void) wait
{
	if ( semWait(&mySem) == -1 ) {
		//doLog(0,"Error locking the semaphore\n");
	}
}

/*
 *
 */

- (void) post
{
	if ( semPost(&mySem) == -1 ) {
		//doLog(0,"Error locking the semaphore\n");
	}
}

/*
 *
 */
- (void) tryWait
{
	if ( semTrywait(&mySem) == -1 ) {
		//doLog(0,"Error trying locking the semaphore\n");
	}
}

@end
