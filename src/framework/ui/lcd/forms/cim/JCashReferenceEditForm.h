#ifndef  JCASH_REFERENCE_EDIT_FORM_H
#define  JCASH_REFERENCE_EDIT_FORM_H

#define  JCASH_REFERENCE_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JDate.h"
#include "JTime.h"
#include "JCombo.h"
#include "ctapp.h"

/**
 *
 */
@interface  JCashReferenceEditForm: JEditForm
{
	JLABEL myLabelParent;
	JLABEL myLabelReference;
	JTEXT	myTextReference;
}

@end

#endif

