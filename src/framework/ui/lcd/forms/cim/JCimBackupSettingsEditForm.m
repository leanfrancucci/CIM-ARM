#include "JCimBackupSettingsEditForm.h"
#include "CimGeneralSettings.h"
#include "MessageHandler.h"
#include "JMessageDialog.h"
#include "JInfoViewerForm.h"
#include "CtSystem.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation  JCimBackupSettingsEditForm


/**/
- (void) onCreateForm
{
	char aux[21];
	[super onCreateForm];
	printd("JCimBackupSettingsEditForm:onCreateForm\n");

	// Automatic Backup
	[self addFormNewPage];
	[self addLabelFromResource: RESID_AUTOMATIC_BACKUP_DESC default: "Automatic Backup:"];
	myComboAutoBackup = [self createNoYesCombo];

	// Backup time
	[self addFormNewPage];
	[self addLabelFromResource: RESID_BACKUP_TIME_DESC default: "Backup Time:"];
	myTimeBackupTime = [JTime new];
	[myTimeBackupTime setSystemTimeMode: FALSE];
 	[myTimeBackupTime setShowConfig: TRUE showMinutes: TRUE showSeconds: FALSE];
	[myTimeBackupTime setOperationMode: TimeOperationMode_HOUR_MIN_SECOND];
	[self addFormComponent: myTimeBackupTime];

	// Backup frame
	[self addFormNewPage];
	[self addLabelFromResource: RESID_BACKUP_FRAME_DESC default: "Backup Frame:"];
	myTextBackupFrame = [JText new];
	[myTextBackupFrame setNumericMode: TRUE];
  [myTextBackupFrame setWidth: 2];
	[self addFormComponent: myTextBackupFrame];

 	[self setConfirmAcceptOperation: TRUE];
	myHasChangedAutomaticBackup = FALSE;
}

/**/
- (void) onCancelForm: (id) anInstance
{
	printd("JCimBackupSettingsEditForm:onCancelForm\n");

	assert(anInstance != NULL);

	[anInstance restore];
}

/**/
- (void) onModelToView: (id) anInstance
{
	printd("JCimBackupSettingsEditForm:onModelToView\n");

	assert(anInstance != NULL);

	[myComboAutoBackup setSelectedIndex: [anInstance isAutomaticBackup]];
	[myTimeBackupTime setTimeValue: [anInstance getBackupTime] / 60 minutes: [anInstance getBackupTime] % 60 seconds: 0];
	[myTextBackupFrame setLongValue: [anInstance getBackupFrame]];
}

/**/
- (void) onViewToModel: (id) anInstance
{
	printd("JCimBackupSettingsEditForm:onViewToModel\n");

	assert(anInstance != NULL);

	if ([anInstance isAutomaticBackup] != [myComboAutoBackup getSelectedIndex]) 
		myHasChangedAutomaticBackup = TRUE;

  [anInstance setAutomaticBackup: [myComboAutoBackup getSelectedIndex]];
	[anInstance setBackupTime: [myTimeBackupTime getHours] * 60 + [myTimeBackupTime getMinutes]];
	[anInstance setBackupFrame: [myTextBackupFrame getLongValue]];

}

/**/
- (void) onAcceptForm: (id) anInstance
{
	id infoViewer;

	printd("JCimBackupSettingsEditForm:onAcceptForm\n");

	assert(anInstance != NULL);

	/* Graba el general settings */
	[anInstance applyChanges];


	if (myHasChangedAutomaticBackup) {
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_RESTART_EQUIPMENT_MSG, "El equipo sera reiniciado!")];
	
#ifdef __UCLINUX
		// reinicio la aplicacion y el sistema operativo
		infoViewer = [JInfoViewerForm createForm: NULL];
		[infoViewer setCaption: getResourceStringDef(RESID_REBOOTING, "Reiniciando...")];
		[infoViewer showModalForm];
						
		[[CtSystem getInstance] shutdownSystem];
		
		exit(23);
#else
		// reinicio solo la aplicacion
		[JMessageDialog askOKMessageFrom: self withMessage: "Reinicie la aplicacion !!"];
#endif

	}

}


@end

