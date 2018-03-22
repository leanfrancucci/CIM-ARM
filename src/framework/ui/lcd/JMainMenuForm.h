#ifndef  JMAIN_MENU_FORM_H
#define  JMAIN_MENU_FORM_H

#define  JMAIN_MENU_FORM id

#include "ctapp.h"
#include "MessageHandler.h"
#include "UserManager.h"
#include "JCustomForm.h"
#include "JMainMenu.h"
#include "JMenuItem.h"
#include "JActionMenu.h"
#include "JSubMenu.h"
#include "system/os/all.h"
#include "ExtractionManager.h"


/**
 *
 */
@interface  JMainMenuForm: JCustomForm
{  
  int	myLoguedUserId;
	char * myBuffer[21];
  MESSAGE_HANDLER myMsgHandler;
	JMAIN_MENU myMainMenu;
	JMENU_ITEM myCloseMenu;
	JSUB_MENU generalSettingsSubMenu;
	JACTION_MENU jReportsSubMenu;
	JACTION_MENU jDoorAccessMenu;
	JACTION_MENU jManualDepositMenu;
	JACTION_MENU jDepositMenu;
	OTIMER myTimer;
		
}

/**/
- (BOOL) canAccessUserLogued: (int) anOperationId;

/**/
- (void) configureMainMenu;

/**/
- (void) setLoguedUser: (USER) anUser;

/**/
- (void) activateMainMenu: (int) aUserId;

/**/
- (void) stopTimer;

/**/
- (BOOL) canExecuteMenu: (int) op;

/**/
- (void) executeReportMenu;

/**/
- (void) executeDoorAccessMenu;

/**/
- (void) executeManualDropMenu;

/**/
- (void) executeValidatedDropMenu;

- (BOOL) canExecuteReportMenu;

@end

#endif

