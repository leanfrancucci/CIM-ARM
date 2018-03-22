#include "JActivateDeactivateUserEditForm.h"
#include "UserManager.h"
#include "util.h"
#include "User.h"
#include "MessageHandler.h"
#include "system/util/all.h"
#include "JMessageDialog.h"
#include "JExceptionForm.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation  JActivateDeactivateUserEditForm
static char myCaptionX[] = "marcar";

/**/
- (void) onCreateForm
{
  
  myUsersCheckBoxCollection = [Collection new];
  
	[super onCreateForm];
	printd("JActivateDeactivateUserEditForm:onCreateForm\n");

	[self setConfirmAcceptOperation: TRUE];

}

/**/
- (void) onOpenForm
{
  id users;
  int i;
  id checkBox;
  int userLoguedId;
  
  myCheckBoxList = [JCheckBoxList new];
  [myCheckBoxList setHeight: 3];
  
  // traigo los usuarios excepto al super
  users = [[UserManager getInstance] getVisibleUsers];
  
  // traigo el id del usuario logueado para no incluirlo en la lista
  userLoguedId = [[[UserManager getInstance] getUserLoggedIn] getUserId];
  
  for (i=0; i < [users size]; ++i) {
    if (userLoguedId != [[users at: i] getUserId]) {
      if ([[users at: i] isActive] == [self getViewActiveUsers]){
        checkBox = [JCheckBox new];
        [checkBox setCaption: [[users at: i] str ]];
        [checkBox setCheckItem: [users at: i]];
  
        [myUsersCheckBoxCollection add: checkBox];
      }
    }
  }
  
  [myCheckBoxList addCheckBoxFromCollection: myUsersCheckBoxCollection];
  [self addFormComponent: myCheckBoxList];
}

/**/
- (void) onModelToView: (id) anInstance
{
	int i;
  
  printd("JActivateDeactivateUserEditForm:onModelToView\n");

  for (i = 0; i < [myUsersCheckBoxCollection size]; ++i) {        
    [[myUsersCheckBoxCollection at: i] setChecked: FALSE];
  }   	
}


/**/
- (void) onAcceptForm: (id) anInstance
{
  int i;
  id user;
  BOOL isChequed;
  JFORM processForm = NULL;
  
  printd("JActivateDeactivateUserEditForm:onAcceptForm\n");
  
  TRY
    processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];
    
    isChequed = FALSE;
    for (i = 0; i < [myUsersCheckBoxCollection size]; ++i) {
  		if ([[myUsersCheckBoxCollection at: i] isChecked]){
        user = [[myUsersCheckBoxCollection at: i] getCheckItem];
        
        isChequed = TRUE; //para saber si por lo menos se selecciono algun usuario
        
        [user setActive: (![self getViewActiveUsers])];
        [user setIsTemporaryPassword: TRUE]; // fuerzo el cambio de password

				if (![self getViewActiveUsers]) {
					[user setLastLoginDateTime: [SystemTime getLocalTime]];
				}

        [user applyChanges];
      }
  	}
  	
    // valido que haya seleccionado al menos un usuario
    if (!isChequed) 
      THROW(RESID_SELECT_USER_MSG);
    
    [processForm closeProcessForm];
    [processForm free];
        
    // mensaje de confirmacion
    if ([self getViewActiveUsers]) // mensaje de inactivacion
      [JMessageDialog askOKMessageFrom: self 
  		  withMessage: getResourceStringDef(RESID_CONFIRM_INACTIVATE_OK, "Los usuarios se inactivaron exitosamente!")];
    else  // mensaje de activacion
      [JMessageDialog askOKMessageFrom: self 
  		  withMessage: getResourceStringDef(RESID_CONFIRM_ACTIVATE_OK, "Los usuarios se activaron exitosamente!")];
  	    	  
  	// cierro el formulario
  	[self closeForm];
  	
  CATCH
  
    [processForm closeProcessForm];
    [processForm free];
    RETHROW();
        
  END_TRY
}

/**/
- (char *) getConfirmAcceptMessage: (char *) aMessage toSave: (id) anInstance
{
  if ([self getViewActiveUsers]) // mensaje de inactivacion
	  snprintf(aMessage, JCustomForm_MAX_MESSAGE_SIZE, getResourceStringDef(RESID_CONFIRM_INACTIVATION_QUESTION, "Confirmar inactivacion de usuarios?"));
	else
	  snprintf(aMessage, JCustomForm_MAX_MESSAGE_SIZE, getResourceStringDef(RESID_CONFIRM_ACTIVATION_QUESTION, "Confirmar activacion de usuarios?"));
  return aMessage;
}

/**/
- (char *) getCaptionX
{
  if ([self getFormMode] == JEditFormMode_EDIT)
    return getResourceStringDef(RESID_CHECK, myCaptionX);
    
  return NULL;    
}

/**/
- (void) setViewActiveUsers: (BOOL) aValue { myViewActiveUsers = aValue; }
- (BOOL) getViewActiveUsers { return myViewActiveUsers; }

@end

