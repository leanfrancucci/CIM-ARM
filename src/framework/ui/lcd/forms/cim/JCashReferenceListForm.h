#ifndef  JCASH_REFERENCE_LIST_FORM_H
#define  JCASH_REFERENCE_LIST_FORM_H

#define  JCASH_REFERENCE_LIST_FORM id

#include "JListForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JList.h"
#include "CimCash.h"
#include "CashReference.h"

/**
 *
 */
@interface JCashReferenceListForm: JListForm
{
	CASH_REFERENCE myCurrentReference;
}


@end

#endif

