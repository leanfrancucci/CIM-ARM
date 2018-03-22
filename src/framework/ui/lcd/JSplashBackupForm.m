#include "JSplashBackupForm.h"
#include "CtSystem.h"
#include "util.h"
#include "SafeBoxHAL.h"
#include "Audit.h"
#include "JMessageDialog.h"

#define printd(args...) // doLog(0,args)
//#define printd(args...)

static char myCaption1[] = "cancel";

@implementation  JSplashBackupForm

/**/
- (void) showProgress;

/**/
- (void) setBackupType: (BackupType) aBackupType
{
	myBackupType = aBackupType;
}

/**/
- (void) setReinitFiles: (BOOL) aValue
{
	myReinitFiles = aValue;
}

/**/
- (void) setCanCancel: (BOOL) aValue
{
	myCanCancel = aValue;
}

/**/
- (void) setRunBackupProgress: (BOOL) aValue
{
	myRunBackupProgress = aValue;
}

/**/
- (void) onCreateForm
{
	[super onCreateForm];

	progressBar = [JProgressBar new];
	[progressBar setWidth: 18];
	[progressBar advanceProgressTo: 0];
	[self addFormComponent: progressBar];

	[self addFormEol];
	labelMessage = [JLabel new];
	[labelMessage setWidth: 20];
	[labelMessage setHeight: 1];
	[self addFormComponent: labelMessage];
	
	[self addFormEol];
	labelMessage2 = [JLabel new];
	[labelMessage2 setWidth: 20];
	[labelMessage2 setHeight: 1];
	[labelMessage2 setCaption: ""];
	[self addFormComponent: labelMessage2];

	myBackupType = BackupType_UNDEFINED;
	myReinitFiles = FALSE;
	myWasCanceled = FALSE;
	myIsWaitConfirm = FALSE;
	myIsBackupInProgress = FALSE;
	myCanCancel = TRUE;
	myRunBackupProgress = TRUE;

	strcpy(myCaption1, getResourceStringDef(RESID_CANCEL_KEY, "cancel"));

	myTimer = [OTimer new];
}

/**/
- (void) onActivateForm
{
	// este control se hace por si retorna al onActivateForm del mensaje de cancel
	if (!myIsWaitConfirm) {
		[super onActivateForm];
		[self doChangeStatusBarCaptions];

		if (myRunBackupProgress) {
			[myTimer initTimer: ONE_SHOT period: 500 object: self callback: "showProgress"];
			[myTimer start];
		}
	}
}

- (void) updateDisplay: (int) aProgress msg: (char*) aMessage
{
	[labelMessage setCaption: aMessage];
	[labelMessage2 setCaption: ""];
	[progressBar advanceProgressTo: aProgress];
}

- (void) setLabel2: (char*) aMessage
{
	[labelMessage2 setCaption: aMessage];
}

/**/
- (void) refreshScreen
{
	[myGraphicContext clearScreen];
	[labelMessage paintComponent];
	[labelMessage2 paintComponent];
	[progressBar paintComponent];
}

/**/
- (void) showProgress
{
	char additional[100];

	myIsBackupInProgress = TRUE;

	// detengo el timer
	[myTimer stop];
	[myTimer free];

	// seteo el splash en CimBackup
	[[CimBackup getInstance] setSplashBackup: self];
	[[CimBackup getInstance] setBackupCanceled: FALSE];
	[[CimBackup getInstance] setFinishWithError: FALSE];

	switch (myBackupType) {
	
		case BackupType_UNDEFINED:
				[[CimBackup getInstance] setCurrentBackupType: BackupType_UNDEFINED];
			break;

		case BackupType_ALL:
				// audito el comienzo del backup
				strcpy(additional, getResourceStringDef(RESID_BCK_TYPE_FULL_ALL_DESC, "Full-All"));
				[Audit auditEventCurrentUser: Event_BACKUP_STARTED additional: additional station: 0 logRemoteSystem: FALSE];

				// cincronizo transacciones
				[[CimBackup getInstance] setCurrentBackupType: BackupType_ALL];
				// indico el comienzo del backup de transacciones
				[[CimBackup getInstance] beginBackupTransactions];
				[[CimBackup getInstance] reinitTransactionsBackupFiles];
				if (!myWasCanceled) {
					[[CimBackup getInstance] syncTransactionsBackupFiles];
					// indico el fin del backup de transacciones
					if (!myWasCanceled) {
						if (![[CimBackup getInstance] getFinishWithError])
							[[CimBackup getInstance] endBackupTransactions];
					}
				}
				// cincronizo settings y users
				if (!myWasCanceled)
					if (![[CimBackup getInstance] getFinishWithError])
						[[CimBackup getInstance] syncSettingsBackupFiles];
			break;

		case BackupType_TRANSACTIONS:
				[[CimBackup getInstance] setCurrentBackupType: BackupType_TRANSACTIONS];
				// indico el comienzo del backup de transacciones
				[[CimBackup getInstance] beginBackupTransactions];
				if (myReinitFiles) {
					myReinitFiles = FALSE;
					// audito el comienzo del backup
					strcpy(additional, getResourceStringDef(RESID_BCK_TYPE_FULL_TRANS_DESC, "Full-Transactions"));
					[Audit auditEventCurrentUser: Event_BACKUP_STARTED additional: additional station: 0 logRemoteSystem: FALSE];

					[[CimBackup getInstance] reinitTransactionsBackupFiles];
				} else {
					// indico el comienzo del backup de transacciones
					[[CimBackup getInstance] beginBackupManualTrans];
					// audito el comienzo del backup
					strcpy(additional, getResourceStringDef(RESID_BCK_TYPE_MANUAL_DESC, "Manual"));
					[Audit auditEventCurrentUser: Event_BACKUP_STARTED additional: additional station: 0 logRemoteSystem: FALSE];
				}
				if (!myWasCanceled) {
					[[CimBackup getInstance] syncTransactionsBackupFiles];
					// indico el fin del backup de transacciones
					if (!myWasCanceled) {
						if (![[CimBackup getInstance] getFinishWithError])
							[[CimBackup getInstance] endBackupTransactions];
					}
				}
			break;

		case BackupType_SETTINGS:
				// audito el comienzo del backup
				strcpy(additional, getResourceStringDef(RESID_BCK_TYPE_FULL_SETT_DESC, "Full-Settings"));
				[Audit auditEventCurrentUser: Event_BACKUP_STARTED additional: additional station: 0 logRemoteSystem: FALSE];

				[[CimBackup getInstance] setCurrentBackupType: BackupType_SETTINGS];
				[[CimBackup getInstance] syncSettingsBackupFiles];
			break;

		case BackupType_USERS:
				// audito el comienzo del backup
				strcpy(additional, getResourceStringDef(RESID_BCK_TYPE_FULL_USERS_DESC, "Full-Users"));
				[Audit auditEventCurrentUser: Event_BACKUP_STARTED additional: additional station: 0 logRemoteSystem: FALSE];

				[[CimBackup getInstance] setCurrentBackupType: BackupType_USERS];
				[[CimBackup getInstance] syncSettingsBackupFiles];
			break;
	}

	if (!myWasCanceled) {
		if (![[CimBackup getInstance] getFinishWithError]) {
			// audito la finalizacion del backup solo si NO fue cancelado y no termino con error
			[Audit auditEventCurrentUser: Event_BACKUP_FINISHED additional: "" station: 0 logRemoteSystem: FALSE];
		//	doLog(0,"BackUp Finalizado\n");
		}
	}

	// seteo el splash en NULL
	[[CimBackup getInstance] setCurrentBackupType: BackupType_UNDEFINED];
	[[CimBackup getInstance] setSplashBackup: NULL];
	[[CimBackup getInstance] setBackupCanceled: FALSE];

	myIsBackupInProgress = FALSE;

	// cierro el form
	if (!myIsWaitConfirm)
		if (myCanCancel) [self closeForm];

}

/**/
- (char *) getCaption1
{
	if (myCanCancel)
		return myCaption1;
	else
		return NULL;
}

/**/
- (void) onMenu1ButtonClick
{
	if (myCanCancel) {
		if (![[CimBackup getInstance] getBackupCanceled]) {
			myIsWaitConfirm = TRUE;
		
			if ([JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_BACKUP_CANCEL_QUESTION, "Are you sure you want to cancel the backUp?")] == JDialogResult_YES) {
		
				if (myIsBackupInProgress) {
					myWasCanceled = TRUE;
					myModalResult = JFormModalResult_CANCEL;
					myCaption1[0] = '\0';
				
					// Le indico al CimBackup que debe abortar el proceso
					[[CimBackup getInstance] setBackupCanceled: TRUE];

					[self updateDisplay: 100 msg: getResourceStringDef(RESID_BACKUP_CANCELING, "Cancelando ...")];
					[self doChangeStatusBarCaptions];
		
				} else [self closeForm];
		
			} else {
				if (myIsBackupInProgress)
					[self refreshScreen];
				else [self closeForm];
			}
		
			myIsWaitConfirm = FALSE;
		}
	}
}

/**/
- (void) onMenuXButtonClick
{
}

/**/
- (void) onMenu2ButtonClick
{
}

@end

