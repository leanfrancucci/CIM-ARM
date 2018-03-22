#include "JDateTimeForm.h"
#include "JSystem.h"
#include "MessageHandler.h"
#include "RegionalSettings.h"
#include "UserManager.h"
#include "cttypes.h"
#include "UICimUtils.h"
#include "Audit.h"
#include "JWorkOrderForm.h"
#include "JMessageDialog.h"
#include "CommercialStateMgr.h"

#define printd(args...) doLog(0,args)
//#define printd(args...)

@implementation  JDateTimeForm

static char myMainMenuMessage[] 			= " menu";
static char myWOrderMessage[] 			  = "OrdTra";
static char myFirstLine[30];

/**/
- (void) updateFirstLine
{
	strcpy(myFirstLine, "");

	strcat(myFirstLine, "      AUTOBANK      ");
	[myLabelDescription setCaption: myFirstLine];

}


/**/
- (void) onCreateForm
{
  [super onCreateForm];
 
    printf("JDateTimeForm-onCreateForm\n");
    //[self addFormBlanks: 3];
    myLabelDescription = [JLabel new];
	[self updateFirstLine];
    [self addFormComponent: myLabelDescription];
       
	myDate = [JDate new];	
	[myDate setReadOnly: TRUE];
	[myDate setSystemTimeMode: TRUE];
	[myDate setJDateFormat: [[RegionalSettings getInstance] getDateFormat]];
	[self addFormComponent: myDate];

    [self addFormBlanks: 1];
	myTime = [JTime new];	
	[myTime setReadOnly: TRUE];
	[myTime setSystemTimeMode: TRUE];		
	[self addFormComponent: myTime];
  
    [self addFormEol];
  
    myLabelCurrentUser = [JLabel new];
    [myLabelCurrentUser setReadOnly: TRUE];
    [myLabelCurrentUser setCaption: getResourceStringDef(RESID_ACTUAL_USER, "Usuario:")];
    [self addFormComponent: myLabelCurrentUser];
  
  /*[self addFormBlanks: 1];
  
  myDescCurrentUser = [JLabel new];
  [myDescCurrentUser setReadOnly: TRUE];
  [self addFormComponent: myDescCurrentUser];*/

}

/**/
- (void) onMenuXButtonClick
{
    printf("onMenuXButtonClick\n");
	[[JSystem getInstance] sendActivateMainApplicationFormMessage];
}

/**/
- (char *) getCaptionX
{	
	return myMainMenuMessage;		
}


/**/
- (void) onMenu1ButtonClick
{
	id profile;
    id user;
    int option;
    JFORM form;
      
	// si esta funcionando con hardware secundario no creo el menu
  if ([UICimUtils canMakeDeposits]){
        
    user = [[UserManager getInstance] getUserLoggedIn];
    profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
    if ([profile hasPermission: WORK_ORDER_OP]) {
  	  	
        option = [UICimUtils selectCollectorWorkOrder: self];
      	
        switch (option) {
      		case ITEM_BACK_WORDER: return;
      		case ITEM_NEW_WORDER:
        	        [Audit auditEventCurrentUser: EVENT_WORK_ORDER additional: "" station: 0 logRemoteSystem: FALSE];
        	        [JMessageDialog askOKMessageFrom: self 
  				            withMessage: getResourceStringDef(RESID_NEW_WORDER_OK, "Nueva orden de trabajo exitosa!")];
    						break;
      		case ITEM_INSERT_WORDER:
                  form = [JWorkOrderForm createForm: self];
  	              [form showModalForm];
  	              [form free];
      					break;
      	}	    
  	    
  	}
	}
}

/**/
- (char *) getCaption1
{
	id profile;
  id user;

	// si esta funcionando con hardware secundario no creo el menu
  if ([UICimUtils canMakeDeposits]){
        
    user = [[UserManager getInstance] getUserLoggedIn];
    profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
		if ([profile hasPermission: WORK_ORDER_OP])
  	  return getResourceStringDef(RESID_WORK_ORDER_MSG, myWOrderMessage);
  	else
  	  return NULL;
  	  
  }else 
    return NULL;	  
}

/**/
- (void) onActivateForm
{
	char buff[50];
    
    printf("JDateTimeForm-onActivateForm\n");
	
	[myDate setJDateFormat: [[RegionalSettings getInstance] getDateFormat]];
  
  buff[0] = '\0';
  strcpy(buff, getResourceStringDef(RESID_ACTUAL_USER, "Usuario:"));
  strcat(buff, " ");
  strcat(buff, [[[UserManager getInstance] getUserLoggedIn] getUSurname]);
  if (strlen(buff) > 20)
    buff[20] = '\0';

  [myLabelCurrentUser setCaption: buff];
}

/**/
- (void) onDeActivateForm
{
}

@end

