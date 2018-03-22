#include <assert.h>
#include "UserInterfaceExcepts.h"
#include "util.h"
#include "JActionMenu.h"

//#define printd(args...) doLog(args)
#define printd(args...)


@implementation  JActionMenu


/**/
- (void) initComponent
{
 [super initComponent];
}

/**/
- free
{
	return [super free];
}


/**/
- initActionMenu: (char *) aCaption
					object: (id) anObject action: (char *)  anAction
{
	[self setCaption: aCaption];
	[self setOnClickAction: anObject action: anAction];
	return self;
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) isPressed
{
	printd("JActionMenuItem.doKeyPressed(%d)\n", aKey);
  printd("Tecla a procesar : (%d)\n", JMenuItem_KEY_ENTER);

	if (aKey == JMenuItem_KEY_ENTER) {
		[self executeOnClickAction];
    printd("JActionMenuItem -- > sendPaintMessage\n");
//    [self sendPaintMessage];
		return TRUE;
	}

	return FALSE;
}


@end

