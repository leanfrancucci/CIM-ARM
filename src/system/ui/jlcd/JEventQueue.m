#include <assert.h>
#include "JEventQueue.h"
#include "log.h"

@implementation  JEventQueue 


/**/
static id singleInstance = NULL;

	
/**/
+ new
{
	if (!singleInstance) singleInstance = [[super new] initialize];
	return singleInstance;
}


/**/
+ getInstance
{
	return [self new];
}

/**/
- initialize
{
	[super initialize];
		
	mySem = [[OSemaphore new] initWithCount: 0];	
	myMutex = [OMutex new];
	
	myEventQueue = qNew( sizeof (JEvent), MAX_JEVENTS );
	myMessageCount = 0;
	
	return self;
}

/**/
- free
{	
	[mySem free];
	[myMutex free];
	
	qFree(&myEventQueue);
	return [super self];
}

/**/
- (int) getMessageCount
{
	int i;
	
	[myMutex lock];	  // seccion critica
	i = myMessageCount;
	[myMutex unLock]; // fin seccion critica
	
	return i;
}

/**/
- (void) putJEvent: (JEvent *) anEvent
{
	int error;
	JEvent evt;
	BOOL addevt = TRUE;
	BOOL showEx = TRUE;
	
	assert(anEvent != NULL);

	error = 1;	
	[myMutex lock];	  // seccion critica
	TRY

		if (!qIsEmpty(myEventQueue) && anEvent->evtid == JEventQueueMessage_PAINT )
		{
			qGetLastElement(myEventQueue, &evt);
			if (evt.evtid == JEventQueueMessage_PAINT) {
				addevt = FALSE;
			}
		}

		if (addevt) {
			qAdd(myEventQueue, anEvent);
			myMessageCount++;
			error = 0;
		}

		showEx = FALSE;

	FINALLY

		if (showEx) {
			//		doLog(0,"Error en putJEvent\n");
					ex_printfmt();
		}
		
		[myMutex unLock]; // fin seccion critica		
		
	END_TRY;
	
	if (!error)
		[mySem post];  // despierto a alguien que esta esperando
}
 
/**/
- (JEvent *) getJEvent: (JEvent *) anEvent 
{	
	int error;
	
	assert(anEvent != NULL);
	
	error = 1;	
	[mySem wait];
	[myMutex lock];	  // seccion critica
	
	TRY
				
		qRemove(myEventQueue, anEvent);
		myMessageCount--;
		error = 0;
		
	FINALLY
		
		[myMutex unLock]; // fin seccion critica
	
	END_TRY;

	if (error)
		anEvent->evtid = JEventQueueMessage_NONE;

	return anEvent;
}

/**/
- (JEvent *) peekJEvent: (JEvent *) anEvent
{
int error;
	
	assert(anEvent != NULL);
	
	error = 1;	
	[mySem wait];
	[myMutex lock];	  // seccion critica
	
	TRY
				
		qGetElement(myEventQueue, anEvent);
		error = 0;
		
	FINALLY
		
		[myMutex unLock]; // fin seccion critica
	
	END_TRY

	if (error)
		anEvent->evtid = JEventQueueMessage_NONE;

	return anEvent;
}


@end

