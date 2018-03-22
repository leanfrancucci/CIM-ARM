#ifndef  JDOORS_EDIT_FORM_H
#define  JDOORS_EDIT_FORM_H

#define  JDOORS_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JCombo.h"
#include "ctapp.h"

/**
 *
 */
@interface  JDoorsEditForm: JEditForm
{
	JLABEL myLabelDoorName;
	JTEXT	myTextDoorName;

	JLABEL myLabelSensorType;
	JCOMBO myComboSensorType;

}

@end

#endif

