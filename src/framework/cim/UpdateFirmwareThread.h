#ifndef UPDATE_FIRMWARE_THREAD_H
#define UPDATE_FIRMWARE_THREAD_H

#define UPDATE_FIRMWARE_THREAD id

#include <Object.h>
#include "system/os/all.h"
#include "system/util/all.h"
#include "JUpdateFirmwareForm.h"

#define UPDATE_FIRMWARE_PATH						BASE_TELESUP_PATH
#define UPDATE_START_WITH_NAME					"firmware_update"
#define UPDATE_INNERBOARD_WITH_NAME			"innerboard_update"
#define UNZIP_PATH											BASE_VAR_PATH


/**
 *	doc template
 */
@interface UpdateFirmwareThread : OThread
{
	JUPDATE_FIRMWARE_FORM myUpdateFirmwareForm;
	JWINDOW myOldForm;
	BOOL myUpgradeIsFinish;
	char myCurrentFile[100];
	BOOL myUpgradeIsSuccess;
	BOOL myUpgradeInProgress;
	char myCompleteFileName[255];
	char myCompleteInnerboardFileName[255];
	BOOL myCanDeleteUpgrade;
}

/**/
+ getInstance;

/**/
- (BOOL) hasPendingUpdates;

/**/
- (BOOL) isUpgradeInProgress;

@end

#endif
