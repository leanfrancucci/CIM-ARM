#ifndef  JDATE_TIME_FORM_H
#define  JDATE_TIME_FORM_H

#define  JDATE_TIME_FORM  id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JDate.h"
#include "JTime.h"
#include "User.h"


/**
 *
 */
@interface  JDateTimeForm: JCustomForm
{
  JLABEL myLabelDescription;
  JLABEL myLabelDescription2;
        
  JLABEL myLabelDate;
	JLABEL myLabelTime;
	
	JDATE	myDate;
	JTIME myTime;
  
  JLABEL myLabelCurrentUser;
  JLABEL myDescCurrentUser;

	OTIMER mySignalTimer;
  
}

@end

#endif

