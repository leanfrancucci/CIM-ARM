#ifndef  JSYSTEM_H__
#define  JSYSTEM_H__

#define  JSYSTEM id

#include "JApplication.h"
#include "UserManager.h"



/**
 *
 */
 

/**
 *  
 */
@interface  JSystem: JWindow
{		
  USER		myLoggedUser;
  JFORM 	myMainMenuForm;		
  JFORM 	myUserLoginForm;
  JFORM 	myDateTimeForm;	
	JFORM   myInstaDropForm;
	JFORM 	myUserChangePinForm;

  id dateTimeApp;
  id callCenterApp;
  id wStationControlApp;
	id productSaleApp;
	id instaDropApp;
    
  COLLECTION myApplicationsList;
  JAPPLICATION myCurrentApplication;
  
  JAPPLICATION myLastApplication;
  
  INPUT_KEYBOARD_MANAGER 		myInputManager;	    
	int myLastKeyPressedTime;	
}


/***
 * Metodos Publicos
 */  

/**/
+ getInstance;

/**/
+ new;

/**/
- initialize;

/**/
- free;

/**
 *
 */
- (void) startSystem;

/**
 *
 */
- (void) addApplication: (id) anApplication;

/**
 *
 */
- (void) activateTelesupScheduler;


/**
 *
 */
- (void) CMPStartUp;

/**
 *
 */
- (void) showSplashForm;

/**
 *
 */
- (void) doLogoutApplication;

/**
 *
 */
- (BOOL) doLoginApplication;

/**
 *
 */
- (void) switchApplication;

/**
 *
 */
- (void) sendActivateNextApplicationFormMessage;

/**
 *
 */
- (void) sendActivateMainApplicationFormMessage;

/**
 *
 */
- (void) deleteAllApplicationMessages;

/**
 *
 */
- (void) sendLoginApplicationMessage;

/**
 *
 */
- (void) createApplications;

/**
 *
 */
- (id) getCurrentApplication;

/**
 *
 */
- (void) sendLogoutApplicationMessage;

/**
 *
 */
- (void) onRefreshMenu;


@end

#endif

