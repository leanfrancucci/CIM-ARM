#include "JInfoViewerForm.h"
#include "util.h"
#include "include/keypadlib.h"

#define printd(args...) doLog(0,args)
//#define printd(args...)

@implementation  JInfoViewerForm

/**/
- initialize
{
	[super initialize];
	return self;
}

/**/
- free
{
	return [super free];
}

/**/
- (void) onCreateForm
{
	[super onCreateForm];
	
	[self addFormEol];
	labelMessage = [JLabel new];
	[labelMessage setWidth: 20];
	[labelMessage setHeight: 2];
	[self addFormComponent: labelMessage];
}

/**/
- (void) setCaption: (char*) aCaption
{
	[labelMessage setCaption: aCaption];
}

/**/
- (char*) getCaption1
{
   return NULL;
}

/**/
- (void) onActivateForm
{
	[self closeForm];
}

@end

