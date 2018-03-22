#ifndef  JCIM_DEVICE_LOGIN_SETTINGS_EDIT_FORM_H
#define  JCIM_DEVICE_LOGIN_SETTINGS_EDIT_FORM_H

#define  JCIM_DEVICE_LOGIN_SETTINGS_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JNumericText.h"
#include "JCombo.h"
#include "JTime.h"

/**
 *
 */
@interface  JCimDeviceLoginSettingsEditForm: JEditForm
{

	JCOMBO myComboLoginDevType;
	JLABEL myLabelLoginDevComPort;
	JCOMBO myComboLoginDevComPort;
	JLABEL myLabelSwipeCardTrack;
	JCOMBO myComboSwipeCardTrack;
	JLABEL myLabelSwipeCardOffset;
	JTEXT  myTextSwipeCardOffset;
	JLABEL myLabelSwipeCardReadQty;
  JTEXT  myTextSwipeCardReadQty;

	int myLastLoginDevType;
	int myLastLoginDevComPort;

}

@end

#endif

