#ifndef  JSPLASH_BACKUP_FORM_H
#define  JSPLASH_BACKUP_FORM_H

#define  JSPLASH_BACKUP_FORM  id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JButton.h"
#include "JProgressBar.h"
#include "CimBackup.h"
#include "OTimer.h"

/**
 *
 */
@interface  JSplashBackupForm: JCustomForm
{
	JLABEL			labelMessage;
	JLABEL			labelMessage2;
	JPROGRESS_BAR	progressBar;
	BackupType myBackupType;
	OTIMER myTimer;
	BOOL myReinitFiles;
	BOOL myWasCanceled;
	BOOL myIsWaitConfirm;
	BOOL myIsBackupInProgress;
	BOOL myCanCancel;
	BOOL myRunBackupProgress;
}

/**/
- (void) setBackupType: (BackupType) aBackupType;

/**/
- (void) setReinitFiles: (BOOL) aValue;

/**/
- (void) setCanCancel: (BOOL) aValue;

/**
 * Este metodo setea variable para saber si el splash debe ejecutar el proceso de
 * backup o si el proceso es ejecutado desde afuera y solo se utiliza el splash
 * para visualizar progreso.
 */
- (void) setRunBackupProgress: (BOOL) aValue;

@end

#endif

