#ifndef  JWORK_ORDER_FORM_H
#define  JWORK_ORDER_FORM_H

#define  JWORK_ORDER_FORM id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JText.h"

/**
 *
 */
@interface  JWorkOrderForm: JCustomForm
{
  JLABEL 		myLabelOrderNumber;
  JTEXT 		myTextOrderNumber;
}

@end

#endif

