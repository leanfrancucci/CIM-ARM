#ifndef  JFORCE_ADMIN_PASSW_FORM_H
#define  JFORCE_ADMIN_PASSW_FORM_H

#define  JFORCE_ADMIN_PASSW_FORM id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JText.h"
#include "system/os/all.h"

/**
 *
 */
@interface  JForceAdminPasswForm: JCustomForm
{
  JLABEL 		myLabelCode;

  JLABEL 		myLabelInsertedCode;
  JTEXT 		myTextInsertedCode;

  JLABEL 		myLabelUserPassword;
  JTEXT 		myTextUserPassword;
  
  OTIMER myTimer;
  JFORM processForm;
}

@end

#endif

