#include "JUsersListForm.h"
#include "JUserEditForm.h"
#include "UserManager.h"
#include "MessageHandler.h"
#include "JExceptionForm.h"

#define printd(args...) // doLog(0,args)
//#define printd(args...)

@implementation  JUsersListForm

- (COLLECTION) getUserList;

/**/
- (void) onConfigureForm
{

  [self setAllowNewInstances: FALSE];
	
  [self setAllowDeleteInstances: [self getCanDelete]];
  [self setConfirmDeleteInstances: [self getCanDelete]];
	
  [self addItemsFromCollection: [self getUserList]];
}

/**/
- (id) onNewInstance
{
	JFORM form;
	volatile USER user;
	
	user = NULL;		
	form = [JUserEditForm createForm: self];
	TRY
	
    	user = [User new];
    
	[form showFormToEdit: user];
    
	if ([form getModalResult] == JFormModalResult_OK) {
		[[UserManager getInstance] addUserToCollection: user];
	} else {
      		[user free];	
  		user = NULL;
	}
	
	FINALLY

		[form free];

	END_TRY

	return user;
}


/**/
- (void) onSelectInstance: (id) anInstance
{
	JFORM form;
	
	if ([self getCanUpdate]){
  	form = [JUserEditForm createForm: self];
  	TRY
  		
  		[form showFormToView: anInstance];
  		
  	FINALLY
  
  		[form free];
  
  	END_TRY
	}
}

/**/
- (char *) getCaption2
{
 	 if ([self getCanUpdate])
     return getResourceStringDef(RESID_ENTER, "entrar");
   else
     return ""; 
}

/**/
- (char *) getCaptionX
{
 	 if ([self getCanDelete])
     return getResourceStringDef(RESID_DELETE, "elimin");
   else
     return ""; 
}

/**/
- (void) onDeleteInstance: (id) anInstance
{
  BOOL canD;
  JFORM processForm = NULL;
  
  if ([self getCanDelete]){
    USER user;
  	
    user = anInstance;	
    
    canD = [[UserManager getInstance] canRemoveUser: [user getUserId]];
    
    if (canD)
      processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];
    
    [[UserManager getInstance] removeUser: [user getUserId]];
  	
    if (canD){
      [processForm closeProcessForm];
      [processForm free];
      
      if ([[self getUserList] size] == 0)
        [self closeForm];
    }
  }
}	

/**/
- (COLLECTION) getUserList
{
  int i;
  COLLECTION myUserList;
  COLLECTION myVisibleUsersList;
  int userLoguedId;

  if ([self getCanDelete]){
    userLoguedId = [[[UserManager getInstance] getUserLoggedIn] getUserId];
    myUserList = [Collection new];
    myVisibleUsersList = [[UserManager getInstance] getVisibleUsers];
    for (i=0; i<[myVisibleUsersList size];++i){ 
  		if ([ [myVisibleUsersList at: i] getUserId] != userLoguedId){
  		  [myUserList add: [myVisibleUsersList at: i]];
  		}
    }
  }else{
    myUserList = [[UserManager getInstance] getVisibleUsers];
  }

  return myUserList;
}

/**/
- (char *) getDeleteInstanceMessage: (char *) aMessage toSave: (id) anInstance
{
	snprintf(aMessage, JCustomForm_MAX_MESSAGE_SIZE, 
            getResourceStringDef(RESID_ASK_DELETE, "Eliminar: %s?"), [anInstance str]);
	return aMessage;
}

/**/
- (void) setCanDelete: (BOOL) aValue { myCanDelete = aValue; }
- (BOOL) getCanDelete { return myCanDelete; }
- (void) setCanUpdate: (BOOL) aValue { myCanUpdate = aValue; }
- (BOOL) getCanUpdate { return myCanUpdate; }

@end

