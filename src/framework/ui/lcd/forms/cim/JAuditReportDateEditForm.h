#ifndef  JAUDIT_REPORT_DATE_EDIT_FORM_H
#define  JAUDIT_REPORT_DATE_EDIT_FORM_H

#define  JAUDIT_REPORT_DATE_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JDate.h"

/**
 *
 */
@interface  JAuditReportDateEditForm: JCustomForm
{
  JLABEL myLabelDate;	

  JLABEL myLabelFromDate;
	JDATE myDateFromDateText;

	JLABEL myLabelToDate;
	JDATE myDateToDateText;
}

@end

#endif

