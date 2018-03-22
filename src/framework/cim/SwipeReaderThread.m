#include "SwipeReaderThread.h"
#include "system/util/all.h"
#include "MessageHandler.h"
#include "Buzzer.h"
#include <unistd.h>
#include "ComPort.h"
#include "CimGeneralSettings.h"

#define CONTROL_CHECK_TIME	100		

//#define printd(args...) doLog(0,args)
#define printd(args...)


/**/
@implementation SwipeReaderThread

static SWIPE_READER_THREAD singleInstance = NULL; 

// Avoid warning
- (void) onExternalLoginKey: (char *) aSwipeCardRead { }

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}
 
/**/
- initialize
{
  myObserver = NULL;
  myIsEnable = FALSE;
	myComPortNumber = [[CimGeneralSettings getInstance] getLoginDevComPort];
	myBaudRate = BR_9600;
	myComPort = NULL;
	myReadTimeout = 0;

	return self;
}

/**/
+ getInstance
{
  return [self new];
}

/**/
- (void) setObserver: (id) anObserver
{
  myObserver = anObserver;
}

/**/
- (void) open
{
	myComPort = [ComPort new];
	[myComPort setBaudRate: myBaudRate];
	[myComPort setStopBits: 1];
	[myComPort setPortNumber: myComPortNumber];
	[myComPort open];
 	[myComPort flush];
}

/**/
- (void) close
{
	[myComPort close];
}

/**/
- (void) enable 
{ 
  			    //************************* logcoment
//doLog(0,"SwipeReaderThread -> enable\n");
 	if (myComPort) [myComPort flush];
  myIsEnable = TRUE;
}

/**/
- (void) disable
{
			    //************************* logcoment
//  doLog(0,"SwipeReaderThread -> disable\n");
  myIsEnable = FALSE;
}

/**/
- (int) readCard: (char *) aBuffer
{
	int n;
	int nRead = 0;

	*aBuffer = '\0';

	while (1) {

		n = [myComPort read: &aBuffer[nRead] qty: 1];
		if (n <= 0) return nRead;

		//printf("[%c] - [%d]\n", aBuffer[nRead], aBuffer[nRead]);

		if (aBuffer[nRead] == 13) {
			aBuffer[nRead] = 0;
			return nRead;
		}

		nRead += n;	

	}

	aBuffer[nRead] = '\0';

	return nRead;
}

/**/
- (char) getInitCharByTrack: (int) aTrackNumber 
{
	switch (aTrackNumber) {
	
		case 1: return '%';
		case 2: return ';';
		case 3: return '+';

		default: return '0';
	}

}

/**/
- (int) processCardId: (char*) aCard idBuffer: (char*) anIdBuffer
{
	int trackNumber;
	int offset;
	int charToRead;
	char initChar;
	char *p = aCard;
	int index = 0;

	[[Buzzer getInstance] buzzerBeep: 200];

	trackNumber = [[CimGeneralSettings getInstance] getSwipeCardTrack];
	offset = [[CimGeneralSettings getInstance] getSwipeCardOffset];
	charToRead = [[CimGeneralSettings getInstance] getSwipeCardReadQty];

	anIdBuffer[0] = '\0';

	initChar = [self getInitCharByTrack: trackNumber];

	while ((*p != initChar) && (*p != '\0')) 
		++p;

	if (*p == '\0') return -1;

	++p;

	if (*p == 'E') return -1;

	while ((*p != '?') && (*p != '\0')) {

		if (index >= offset) {
			*anIdBuffer	= *p;
			++anIdBuffer;
		}

		++index;

		if ((index - offset) >= charToRead) break;

		++p;
		
	}

	if (*p == '\0') {
		anIdBuffer[0] = '\0';
		return -1;
	}

	*anIdBuffer = '\0';

	return 0;	

}

/**/
- (void) run 
{
	char cardBuffer[512];
	char idBuffer[255];
	
	int n;
	int processCardResult;

			    //************************* logcoment
//	doLog(0,"comienzo del hilo de swipe card reader\n");

	TRY

		[self open];

		while (TRUE) {

			msleep(100);
 
      if (!myIsEnable) {
				msleep(100);
        continue;
      }

			n = [self readCard: cardBuffer];
			
			if (n > 0 && myObserver != NULL) {

			    //************************* logcoment
//				doLog(0,"CODIGO (%d) = |%s|\n", n, cardBuffer);
				processCardResult = [self processCardId: cardBuffer idBuffer: idBuffer];
			    //************************* logcoment
//				doLog(0,"idBuffer  = %s\n", idBuffer);

 				[myComPort flush];

				if (strlen(idBuffer) > 0) {
					[myObserver onExternalLoginKey: idBuffer];
				}

			}

		}

	CATCH

			    //************************* logcoment
//		doLog(0,"Ha ocurrido un error en el hilo del codigo de barras\n");
		ex_printfmt();
		
	END_TRY

	[self close];

}



@end
