#include "JTelesupViewerForm.h"
#include "CtSystem.h"
#include "util.h"
#include "MessageHandler.h"

#define printd(args...) //doLog(0,args)
//#define printd(args...)

@implementation  JTelesupViewerForm

/**/
- (void) onCreateForm
{
	[super onCreateForm];

	[self setWidth: 20];
	[self setHeight: 4];
	
	labelTitle = [JLabel new];
	[labelTitle setWidth: 20];
	[labelTitle setHeight: 1];	
	[labelTitle setCaption: getResourceStringDef(RESID_SUPERVISING, "Supervisando...     ")];
	[self addFormComponent: labelTitle];
	[labelTitle setVisible: TRUE];

	labelMessage = [JLabel new];
	[labelMessage setWidth: 20];
	[labelMessage setHeight: 2];
	[labelMessage setWordWrap: TRUE];
	[labelMessage setCaption: "                                         "];
	[self addFormComponent: labelMessage];
	[labelMessage setVisible: TRUE];

	/*timeElapsed = [JTime new];
	[timeElapsed setTimeValue: 0];
	[self addFormComponent: timeElapsed ];
	[timeElapsed setVisible: TRUE];
	[timeElapsed setReadOnly: TRUE];
	[timeElapsed setCanFocus: FALSE];
	[self addBlanks: 1];
	*/
	labelBytes = [JLabel new];
	[labelBytes setWidth: 20];
	[labelBytes setHeight: 1];
	[labelBytes setCaption: "xxxxxxxxxxxxxxxxxxxx"];
	[self addFormComponent: labelBytes];
	[labelBytes setVisible: TRUE];

	[myGraphicContext clearScreen];
/*	timer = [OTimer new];
	[timer initTimer: PERIODIC period: 1000 object: self callback: "handleTimer"];
	elapsed = 0;*/
}

/**/
- (void) handleTimer
{
	elapsed++;
	[timeElapsed setDateTimeValue: elapsed];
}

/**/
- (void) start
{
	//[timer start];
}

/**/
- (void) stop
{
	/*[timer stop];
	[timer free];*/
}

/**/
- (void) updateDisplay: (char*) aMessage
{
  [labelBytes setCaption: "                    "];
	[labelMessage setCaption: "                                         "];
//	[labelMessage setCaption: "0123456789012345678901234567890123456789"];
	[labelMessage setCaption: aMessage];
}

/**/
- (void) updateTransfered: (long) aBytes totalBytes: (long) aTotalBytes
{
	char s[21];
	char msg[21];
	
	if (aTotalBytes == 0) sprintf(s, "%ld/? bytes", aBytes);
	else sprintf(s, "%ld/%ld bytes", aBytes, aTotalBytes);

	memset(msg, 32, 20);
	msg[20] = 0;
	memcpy(msg, s, strlen(s));
			
	[labelBytes setCaption: msg];
}

/**/
- (void) updateTitle: (char*) aTitle
{
	[labelTitle setCaption: aTitle];
}

/**/
- (char*) getCaption1
{
   return NULL;
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) anIsPressed
{	
	return TRUE;	
}

@end

