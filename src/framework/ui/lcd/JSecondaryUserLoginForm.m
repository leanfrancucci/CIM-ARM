#include "JSecondaryUserLoginForm.h"
#include "util.h"
#include "JMessageDialog.h"
#include "MessageHandler.h"
#include "CimGeneralSettings.h"
#include "Audit.h"
#include "Event.h"
#include "JSystem.h"
#include "SettingsExcepts.h"
#include "UICimUtils.h"
#include "JExceptionForm.h"

#define printd(args...)// doLog(0,args)
//#define printd(args...)

@implementation  JSecondaryUserLoginForm


/**/
- (void) onCreateForm
{

	[super onCreateForm];
	
	processForm = NULL;
	
	myValidateLogin = TRUE;
  	myPersonalId[0] = '\0';
  	myPassword[0] = '\0';
	myUser = NULL;
  	myCantLoginFails = 0;
	forcePasswKey = 0;
	
	// Label Nombre usuario
	myLabelUserName = [JLabel new];
	[myLabelUserName setCaption: getResourceStringDef(RESID_USER, "ID Personal:")];
	[myLabelUserName setAutoSize: FALSE];
	[myLabelUserName setWidth: 15];
	[self addFormComponent: myLabelUserName];
	
  	[self addFormEol];

	myTextUserName = [JText new];
	[myTextUserName setWidth: 9];
	[myTextUserName setHeight: 1];	
	[myTextUserName setMaxLen: 9];
	[myTextUserName setPasswordMode: FALSE];
	[myTextUserName setNumericMode: TRUE];
	[self addFormComponent: myTextUserName];	
				
	[self addFormEol];			
				
	// Label Contrasena
	myLabelUserPassword = [JLabel new];
	[myLabelUserPassword setCaption: getResourceStringDef(RESID_PIN, "Clave:")];
	[myLabelUserPassword setAutoSize: FALSE];
	[myLabelUserPassword setWidth: strlen(getResourceStringDef(RESID_PIN, "Clave:"))];
	[self addFormComponent: myLabelUserPassword];
				
	//Text Contrasena
	myTextUserPassword = [JText new];
	[myTextUserPassword setWidth: 8];
	[myTextUserPassword setHeight: 1];	
	[myTextUserPassword setMaxLen: 8];
	[myTextUserPassword setPasswordMode: TRUE];
	[myTextUserPassword setNumericMode: TRUE];
	[self addFormComponent: myTextUserPassword];
	
	// por defecto loguea al usuario
	myDoLog = TRUE;
	myCanGoBack = FALSE;  
}

/**/
- (void) onActivateForm
{
	myUser = NULL;
	
	// por defecto loguea al usuario
	myDoLog = TRUE;	
}

/**/
- (void) onCloseForm
{
  [super onCloseForm];
	
  if (processForm){
  	[processForm closeProcessForm];
	[processForm free];
	processForm = NULL;
  }
}

/**/
- (void) doLogFormUser
{			        
    [self closeForm];

}

- (void) lockSystem: (int) aSeconds {
/*   JFORM form;
   JFormModalResult modalResult;
	 
   [Audit auditEvent: Event_WRONG_PIN_BLOCK additional: "" station: 0 logRemoteSystem: FALSE];
	 
   form = [JSimpleTimerLockForm createForm: self];
   [form setTimeout: aSeconds];
   [form setTitle: getResourceStringDef(RESID_LOCK_LOGIN_MSG, "Equipo Bloqueado!")];
   [form setShowTimer: TRUE];
   modalResult = [form showModalForm];
   [form free];*/
}

/**/
- (USER) getLoggedUser
{
	return myUser;
}

/**/
- (char *) getCaption1
{
	return NULL;
}

/**/
- (void) onMenu1ButtonClick
{
	[self doChangeStatusBarCaptions];
}

/**/
- (char *) getCaption2
{
	return "login";
}

/**/
- (void) onMenu2ButtonClick
{
	// seteo los valores ingresados
	strcpy(myPersonalId, [myTextUserName getText]);
	strcpy(myPassword, [myTextUserPassword getText]);
	[self closeForm];
}

/**/
- (void) onOpenWindow
{
 	//doLog(0,"%s --> onOpenWindow\n", [self str]);

	[myLabelUserName setCaption: getResourceStringDef(RESID_USER, "ID Personal:")];
	[myLabelUserPassword setCaption: getResourceStringDef(RESID_PIN, "Clave:")];
	[myLabelUserPassword setWidth: strlen(getResourceStringDef(RESID_PIN, "Clave:"))];

  	[self focusFormComponent: myTextUserName];
}

/**/
- (void) onActivateWindow
{
 //   
}

/**/
- (void) setDoLog: (BOOL) aValue
{
  myDoLog = aValue;
}

/**/
- (void) setCanGoBack: (BOOL) aValue 
{
	myCanGoBack = aValue;
}

/**/
- (void) setValidateLogin: (BOOL) aValue
{
  myValidateLogin = aValue;
}

/**/
- (char *) getPersonalId
{
  return myPersonalId;
}

/**/
- (char *) getPassword
{
  return myPassword;
}

@end

