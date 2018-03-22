#include <objpak.h>
#include <Object.h>
#include <string.h>
#include "log.h"
#include "system/os/all.h"
#include "OTimer.h"
#include "ctimers.h"


//#define printd(args...) doLog(0,args)
#define printd(args...)

/* una macro que me divide el numero de periodo si estoy compilado para testing 
	 automatico, en cuyo caso quiero que un periodo determinado sea menor para poder
	 acelerar el test. Por ejemplo: 1000 ms, se me convierten en 10 ms cuando estoy
	 en testing
*/

//#ifdef __TESTING
#if 0

  #define PERIOD_ADJUSTMENT 	100

#else

  #define PERIOD_ADJUSTMENT		1
  
#endif

/*
 *	timeoutCTTimer()
 *
 */
static
TIMEOUT_CTIMER_HANDLER(timeoutCtTimer)
{
	[(void *)GET_TIMEOUT_CTIMER_PARAM() expireTimer];
}


@implementation OTimer: Object


/*
 * 	expiresTimer
 *
 */
- (void) expireTimer
{
	if ( myCycle != PERIODIC ) {
		myIsActive = 0;
		del_ctimer( &myTimer );
	}

	if (mySel && myArg)
		[myObject perform: mySel with: myArg];
	else if (mySel) 
		[myObject perform: mySel] ;
}

/*
 *	initTimers
 *
 */
+ (void) initTimers
{
	init_ctimers();
}

/*
 *	cleanupTimers
 *
 */
+ (void) cleanupTimers
{
	cleanup_ctimers();	
}



/*
 *	new
 *
 */
+ new
{	
	return [super new];
}

/*
 *	initalize
 *
 */
- initalize
{
	[super initialize];
	
/* 	ONE_SHOT
	PERIODIC	*/
	myCycle = ONE_SHOT;

	myPeriod = 0;
	myOriginalPeriod = 0;
	myIsActive = 0;
	myInitialTicks = 0;
	myExecutedTimes = 0;	
	return self;
}

/*
 *	init
 *
 */
- (void) initTimer:(int) aCycle period:(long) aPeriod 
							object:(id) anObject callback:(char*) aCallback 
{
	myObject = anObject ;
	myCallback = aCallback ;
	mySel = [myObject findSel: myCallback];
	[self setPeriod: aPeriod];
	myCycle = aCycle;
	myExecutedTimes = 0;
}

/*
 *	init
 *
 */
- (void) initTimerWithArg:(int) aCycle period:(long) aPeriod object:(id) anObject 
						callback:(char*) aCallback arg: (id) anArg
{
	myObject = anObject ;
	myCallback = aCallback ;
	mySel = [myObject findSel: myCallback];
	[self setPeriod: aPeriod];	
	myCycle = aCycle ;
	myArg = anArg ;
	myExecutedTimes = 0;
}


/*
 *	init
 *	[deprecated]
 *
 */
- (void) init:(int) aCycle period:(long) aPeriod object:(id) anObject 
						callback:(char*) aCallback
{
	//doLog(0,"OTimer.init is deprecated!!!\n");
	[self initTimerWithArg: aCycle period: aPeriod object: anObject 
						callback: aCallback arg: 0];
} 

/*
 *	init
 *	[deprecated]
 *
 */
- (void) init:(int) aCycle period:(long) aPeriod object:(id) anObject callback:(char*) aCallback arg1: (id) anObject1 
{
	//doLog(0,"OTimer.init is deprecated!!!\n");
	[self initTimerWithArg: aCycle period: aPeriod object: anObject 
						callback: aCallback arg: anObject1];
}

/*
 *	init
 *	[deprecated]
 *
 */
- (void) init:(int) aCycle period:(long) aPeriod object:(id) anObject callback:(char*) aCallback arg1: (id) anObject1 arg2: anObject2 
{
	//doLog(0,"OTimer.init is deprecated!!!\n");
	[self initTimerWithArg: aCycle period: aPeriod object: anObject 
						callback: aCallback arg: anObject1];
}


/*
 *	setCycle
 */
- (void) setCycle:(int) aCycle
{
	myCycle = aCycle;
}

/*
 *	setPeriod
 *		Setea el per�odo del timer en milisegundos
 */
- (void) setPeriod:(long) aPeriod
{
	myOriginalPeriod = aPeriod / PERIOD_ADJUSTMENT;
	myPeriod = myOriginalPeriod ;
}

/*
 *	setObject
 *		Setea el objeto y el m�todo que se invoca cuando el timer expira 
 *
 */
- (void) setObject: (id) anObject callback: (char *) aCallback arg: (id) anArg
{
	myObject = anObject;
	myCallback = aCallback;
	myArg = anArg;
}


/*
 *	start
 *
 */
- (void) start
{
    
    unsigned long ticks =  getTicks();
    myOriginalPeriod = myOriginalPeriod;
    
	if (myIsActive) [self stop];
	
	init_ctimer( &myTimer );
	myTimer.function = timeoutCtTimer; 
	myTimer.expires = ticks + myOriginalPeriod;
	myTimer.period  = myOriginalPeriod ;
	myTimer.periodic = (myCycle == PERIODIC);
	myTimer.data = (unsigned long)self;
	add_ctimer( &myTimer );

	if (myCycle == PERIODIC && myExecutedTimes == 0)
		myInitialTicks = getTicks();
	
	myIsActive = 1;
}

/**/
- (unsigned long) getTimePassed
{
	long x = myTimer.period - [self getTimeLeft];
	if (x < 0) x = 0;
	return x;
}

/**/
- (unsigned long) getTimeLeft
{
	long left = myTimer.expires - getTicks();
	if (left < 0) left = 0;
	return left;
}

/*
 *	stop
 *
 */
- (void) stop
{
	myIsActive = 0;
	del_ctimer( &myTimer );
	myExecutedTimes = 0;
}

/**
 *	free
 *
 */
- free
{	
	[self stop] ;
	return [super free];
}


@end
 
