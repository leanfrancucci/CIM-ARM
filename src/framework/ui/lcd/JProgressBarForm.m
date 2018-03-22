#include <string.h>
#include "JProgressBarForm.h"
#include "CtSystem.h"
#include "util.h"
#include "include/keypadlib.h"
#include "system/os/all.h"

#define printd(args...) // doLog(0,args)
//#define printd(args...)

@implementation  JProgressBarForm

/**/
- (void) showProgress;
- (void) setObserver: (id) anObject
{
}

- initialize
{
	[super initialize];
	callBack = NULL;
	object = NULL;
	currentProgress = 0;
	myAdvanceOnTimer = FALSE;
	return self;
}

/**/
- free
{
	if (callBack) free(callBack);
	return [super free];
}

/**/
- (void) onCreateForm
{
	[super onCreateForm];

	progressBar = [JProgressBar new];
	[progressBar setWidth: 18];
	[progressBar advanceProgressTo: 0];
	//[progressBar setFilled: FALSE];
	//[progressBar showPercent: FALSE];
	[self addFormComponent: progressBar];

	[self addFormEol];

	myLabelTitle = [JLabel new];
	[myLabelTitle setWidth: 20];
	[myLabelTitle setHeight: 1];
	[self addFormComponent: myLabelTitle];

	[self addFormEol];
	labelMessage = [JLabel new];
	[labelMessage setWidth: 20];
	[labelMessage setHeight: 1];
	[self addFormComponent: labelMessage];

	[self addFormEol];
	labelMessage2 = [JLabel new];
	[labelMessage2 setWidth: 20];
	[labelMessage2 setHeight: 1];
	[labelMessage2 setCaption: ""];
	[self addFormComponent: labelMessage2];
}

/**/
- (void) setFilled: (BOOL) aFilled
{
	[progressBar setFilled: TRUE];
}

/**/
- (void) setAdvanceOnTimer: (BOOL) aValue
{
	myAdvanceOnTimer = aValue;
}

/**/
- (void) onActivateForm
{
	[super onActivateForm];
	[progressBar advanceProgressTo: currentProgress];
	[self showProgress];
}

/**/
- (void) setCaption: (char*) aCaption
{
	[labelMessage setCaption: aCaption];
}

/**/
- (void) setCaption2: (char*) aCaption
{
	[labelMessage2 setCaption: aCaption];
}

/**/
- (void) setTitle: (char *) aTitle
{
	[myLabelTitle setCaption: aTitle];
}

/**/
- (void) advance
{
	currentProgress = (currentProgress + 10) % 100;
	[progressBar advanceProgressTo: currentProgress];
	if (!object) [progressBar paintComponent];
}

/**/
- (void) advanceTo: (int) aProgress
{
	currentProgress = aProgress;
	[progressBar advanceProgressTo: currentProgress];
	if (!object) [progressBar paintComponent];
}

/**/
- (void) setCallBack: (id) anObject callBack: (char*) aCallBack
{
	callBack = strdup(aCallBack);
	object = anObject;	
}

/**/
- (void) showProgress
{
	SEL mySel = NULL;
	OTIMER timer = NULL;

	[myGraphicContext clearScreen];
	[progressBar advanceProgressTo: 0];

	if (myAdvanceOnTimer) {
		timer = [OTimer new];
		[timer initTimer: PERIODIC period: 1000 object: self callback: "advance"];
		[timer start];
	} else {
		if (object) [object setObserver: self];
	}

	if (object) {
		mySel = [object findSel: callBack];
		assert(mySel);
	}
	
	[myLabelTitle paintComponent];
	[labelMessage paintComponent];
	[labelMessage2 paintComponent];
	[progressBar paintComponent];

	if (object) {
		[object perform: mySel] ;
	}

	if (myAdvanceOnTimer) {
		[timer stop];
		[timer free];
	}

	[self closeForm];
}

/**/
- (char*) getCaption1
{
   return NULL;
}

@end

