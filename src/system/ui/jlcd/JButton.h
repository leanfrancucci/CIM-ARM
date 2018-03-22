#ifndef  JBUTTON_H
#define  JBUTTON_H

#define  JBUTTON  id

#include "JComponent.h"


/**
 *
 */
@interface  JButton: JComponent
{
	char   	myCaption[ JComponent_MAX_LEN + 1 - 4];
}

/**
 *
 */
- (void) setCaption: (char *) aValue;
- (char *) getCaption;


@end

#endif

