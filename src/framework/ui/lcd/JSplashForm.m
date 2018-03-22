#include "JSplashForm.h"
#include "CtSystem.h"
#include "util.h"

#define printd(args...) //doLog(0,args)
//#define printd(args...)

@implementation  JSplashForm

/**/
- (void) showProgress;

/**/
- (void) onCreateForm
{
	[super onCreateForm];
	
	[self addFormEol];
	progressBar = [JProgressBar new];
	[progressBar setWidth: 14];
	[progressBar advanceProgressTo: 0];
	[self addFormComponent: progressBar];

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
- (void) onActivateForm
{
    //doLog(0,"[ SHOW PROGRESS ]\n");fflush(stdout);
  
	[super onActivateForm];
	[self showProgress];
}

- (void) updateDisplay: (int) aProgress msg: (char*) aMessage
{
	[labelMessage setCaption: aMessage];
	[labelMessage2 setCaption: ""];
	[progressBar advanceProgressTo: aProgress];
}

- (void) setLabel2: (char*) aMessage
{
	[labelMessage2 setCaption: aMessage];
}

/**/
- (void) refreshScreen
{
	[myGraphicContext clearScreen];
	[labelMessage paintComponent];
	[progressBar paintComponent];
}

/**/
- (void) showProgress
{
    
    printf("JSplashForm-showProgress\n");
    
	[[CtSystem getInstance] startSystem: self];
  
	[self closeForm];
}

/**/
- (char*) getCaption1
{
   return NULL;
}

@end

