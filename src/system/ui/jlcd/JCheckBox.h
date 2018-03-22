#ifndef  JCHECK_BOX_H
#define  JCHECK_BOX_H

#define  JCHECK_BOX  id

#include "JComponent.h"


/**
 *
 */
@interface  JCheckBox: JComponent
{
	char   	myCaption[ JComponent_MAX_LEN + 1 ];
	BOOL	myCheckedState;
  id myCheckItem;
}

/**
 *
 */
- (void) setCaption: (char *) aValue;
- (char *) getCaption;


/**
 *
 */
- (void) setChecked: (BOOL) aValue;
- (BOOL) isChecked;

/**
 *
 */
- (void) setCheckItem: (id) anItem;
- (id) getCheckItem; 


@end

#endif

