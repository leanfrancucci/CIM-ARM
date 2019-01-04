#ifndef SUPPORT_THREAD_H
#define SUPPORT_THREAD_H

#define SUPPORT_THREAD id

#include <Object.h>
#include "system/os/all.h"
#include "system/util/all.h"
#include "JUpdateFirmwareForm.h"

#define SUPPORT_PATH						"/rw/CT8016/support"
#define SUPPORT_TASK_START_WITH_NAME					"support"
#define UNZIP_PATH											BASE_VAR_PATH


/**
 *	doc template
 */
@interface SupportThread : OThread
{
	char myCompleteFileName[255];
    BOOL myTaskInProgress;
	BOOL myCanDeleteTask;
    
    BOOL myUpgradeIsFinish;
	char myCurrentFile[100];
	BOOL myUpgradeIsSuccess;
	

	char myCompleteInnerboardFileName[255];

}

/**/
+ getInstance;


@end

#endif
