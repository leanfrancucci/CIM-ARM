#include <assert.h>
#include "util.h"
#include "JCustomStatusBar.h"


#include "JListForm.h"
#include "JEditForm.h"

#include "JText.h"
#include "JCombo.h"
#include "JList.h"
#include "JGrid.h"
#include "JMainMenu.h"
#include "JButton.h"

#define printd(args...) //doLog(0,args)
//#define printd(args...)


@implementation  JCustomStatusBar

/**/
- (void) initComponent
{
 [super initComponent];
 	
	myCanFocus = FALSE;

	myLabelMenu1 = [JLabel new];
	[myLabelMenu1 setAutoSize: FALSE];	
	[myLabelMenu1 setWidth: myWidth / 3];		
	[myLabelMenu1 setTextAlign: UTIL_AlignLeft];
	[myLabelMenu1 setCaption: ""];		
	[self addComponent: myLabelMenu1];

	[self  addBlanks: 1];
	
	myLabelMenuX = [JLabel new];	
	[myLabelMenuX setAutoSize: FALSE];
	[myLabelMenuX setWidth: myWidth / 3];			
	[myLabelMenuX setTextAlign: UTIL_AlignCenter];
	[myLabelMenuX setCaption: ""];	
	[self  addComponent: myLabelMenuX];
	
	[self  addBlanks: 1];
	
	myLabelMenu2 = [JLabel new];	
	[myLabelMenu2 setAutoSize: FALSE];
	[myLabelMenu2 setWidth: myWidth / 3];		
	[myLabelMenu2 setTextAlign: UTIL_AlignRight];
	[myLabelMenu2 setCaption: ""];		
	[self  addComponent: myLabelMenu2];
}


/**/
- free
{
	return [super free];
}

/**/
- (void) setCaption1: (char *) aCaption { [myLabelMenu1 setCaption: aCaption]; } 
- (char *) getCaption1 { return [myLabelMenu1 getCaption]; } 

/**/
- (void) setCaptionX: (char *) aCaption { [myLabelMenuX setCaption: aCaption]; } 
- (char *) getCaptionX { return [myLabelMenuX getCaption]; } 

/**/
- (void) setCaption2: (char *) aCaption { [myLabelMenu2 setCaption: aCaption]; } 
- (char *) getCaption2 { return [myLabelMenu2 getCaption]; } 
	
@end

