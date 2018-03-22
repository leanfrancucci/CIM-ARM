#ifndef  JREPAIR_ORDER_REPORT_H
#define  JREPAIR_ORDER_REPORT_H

#define  JREPAIR_ORDER_REPORT id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"

#include "User.h"

/**
 *
 */
@interface  JRepairOrderReport: JCustomForm
{
	JLABEL myRepairReport;
	id myRepairOrder;
}

/**/
- (void) setRepairOrder: (id) aRepairOrder;

@end

#endif

