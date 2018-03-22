#ifndef  JCIM_BACKUP_SETTINGS_EDIT_FORM_H
#define  JCIM_BACKUP_SETTINGS_EDIT_FORM_H

#define  JCIM_BACKUP_SETTINGS_EDIT_FORM id

#include "JEditForm.h"
#include "JLabel.h"
#include "JText.h"
#include "JNumericText.h"
#include "JCombo.h"
#include "JTime.h"

/**
 *
 */
@interface  JCimBackupSettingsEditForm: JEditForm
{

	JCOMBO myComboAutoBackup;
	JTIME  myTimeBackupTime;
	JTEXT  myTextBackupFrame;

	BOOL myHasChangedAutomaticBackup;
}


@end

#endif

