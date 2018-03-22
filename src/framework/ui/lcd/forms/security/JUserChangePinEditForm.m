#include "JUserChangePinEditForm.h"
#include "UserManager.h"
#include "util.h"
#include "MessageHandler.h"
#include "JMessageDialog.h"
#include "system/util/all.h"
#include "Audit.h"
#include "Event.h"
#include "DAOExcepts.h"
#include "JExceptionForm.h"


//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation  JUserChangePinEditForm


/**/
- (void) onCreateForm
{
	[super onCreateForm];
	printd("JUserChangePinEditForm:onCreateForm\n");

	myShowCancel = TRUE;
	myWasCanceledLogin = FALSE;

  // Password Actual
	[self addLabelFromResource: RESID_ACTUAL_PASSWORD default: "Clave Actual:"];
	myTextActualPassword = [JText new];

	[myTextActualPassword setWidth: 8];
	[myTextActualPassword setPasswordMode: TRUE];
  [myTextActualPassword setNumericMode: TRUE];
  [myTextActualPassword setMaxLen: 8];

	[self addFormComponent: myTextActualPassword];

	[self addFormNewPage];
  
  // Password
	[self addLabelFromResource: RESID_NEW_PASSWORD default: "Nueva Clave:"];
	myTextPassword = [JText new];

	[myTextPassword setWidth: 8];
	[myTextPassword setPasswordMode: TRUE];
  [myTextPassword setNumericMode: TRUE];
  [myTextPassword setMaxLen: 8];

	[self addFormComponent: myTextPassword];

	[self addFormNewPage];

	// Confirm Password
	[self addLabelFromResource: RESID_CONFIRM_PASSWORD default: "Confirmacion Clave:"];
	myTextConfirmPassword = [JText new];

	[myTextConfirmPassword setWidth: 8];
	[myTextConfirmPassword setPasswordMode: TRUE];
  [myTextConfirmPassword setNumericMode: TRUE];
  [myTextConfirmPassword setMaxLen: 8];

	[self addFormComponent: myTextConfirmPassword];

	[self addFormNewPage];

	// Duress Password
	myLabelDuressPassword = [self addLabelFromResource: RESID_NEW_DURESS_PASSWORD default: "Nueva Clave de robo:"];
	myTextDuressPassword = [JText new];

	[myTextDuressPassword setWidth: 8];
	[myTextDuressPassword setPasswordMode: TRUE];
  [myTextDuressPassword setNumericMode: TRUE];
  [myTextDuressPassword setMaxLen: 8];

	[self addFormComponent: myTextDuressPassword];

	[self addFormNewPage];

	// Confirm Duress Password
	myLabelConfirmDuressPassword = [self addLabelFromResource: RESID_CONFIRM_DURESS_PASSWORD default: "Confirm Clave Robo:"];
	myTextConfirmDuressPassword = [JText new];
	[myTextConfirmDuressPassword setWidth: 8];
	[myTextConfirmDuressPassword setPasswordMode: TRUE];
  [myTextConfirmDuressPassword setNumericMode: TRUE];
  [myTextConfirmDuressPassword setMaxLen: 8];

	[self addFormComponent: myTextConfirmDuressPassword];

	[self setConfirmAcceptOperation: TRUE];

	[[UserManager getInstance] setLoginInProgress: TRUE];
}

/**/
- (void) onCancelForm: (id) anInstance
{
	printd("JUserChangePinEditForm:onCancelForm\n");

	assert(anInstance != NULL);

	myWasCanceledLogin = TRUE;

	if ([anInstance getUserId] > 0)
		[anInstance restore];

	[[UserManager getInstance] setLoginInProgress: FALSE];

	[self doChangeFormMode: JEditFormMode_VIEW];
}

/**/
- (void) onModelToView: (id) anInstance
{
	printd("JUserChangePinEditForm:onModelToView\n");
	
  assert(anInstance != NULL);

  //guardo la password
  myOldDuressPassword[0] = '\0';
  myOldPassword[0] = '\0';  
  strcpy(myOldDuressPassword, [anInstance getDuressPassword]);
  strcpy(myOldPassword, [anInstance getPassword]);
  
  if ([self getFormMode] == JEditFormMode_VIEW) {
  	// Password
  	[myTextPassword setText: [anInstance getPassword]];
  	
  	// Confirm Password
  	[myTextConfirmPassword setText: [anInstance getPassword]];
  
  	// DuressPassword
  	[myTextDuressPassword setText: [anInstance getDuressPassword]];
  
  	// Confirm DuressPassword
  	[myTextConfirmDuressPassword setText: [anInstance getDuressPassword]];  	
	} else {
  	// Password Actual
  	[myTextActualPassword setText: ""];
  	
  	// Password
  	[myTextPassword setText: ""];
  	
  	// Confirm Password	
  	[myTextConfirmPassword setText: ""];
  
  	// DuressPassword
  	[myTextDuressPassword setText: ""];
  
  	// Confirm DuressPassword
  	[myTextConfirmDuressPassword setText: ""];  
  }

	// deshabilito los campos de duress dependiendo del perfil del usuario que va a cambiar
	// su password
	if (![[anInstance getProfile] getUseDuressPassword]) {
		[myLabelDuressPassword setVisible: FALSE];
		[myTextDuressPassword setVisible: FALSE];
		[myLabelConfirmDuressPassword setVisible: FALSE];
		[myTextConfirmDuressPassword setVisible: FALSE];
	}

}

/**/
- (void) onViewToModel: (id) anInstance
{
	printf("JUserChangePinEditForm:onViewToModel\n");

	assert(anInstance != NULL);

	// Password
	[anInstance setPassword: [myTextPassword getText]];

	// DuressPassword
	[anInstance setDuressPassword: [myTextDuressPassword getText]];

	// Actualizo la fecha de cambio de password
	[anInstance setLastChangePasswordDateTime: [SystemTime getLocalTime]];
	
	// Actualizo la clave temporaria
	[anInstance setIsTemporaryPassword: FALSE];
}

/**/
- (void) onAcceptForm: (id) anInstance
{
  JFORM processForm = NULL;
  
	printd("JUserChangePinEditForm:onAcceptForm\n");

	assert(anInstance != NULL);
    
  // valido que la password no sea vacia
  if (strlen([anInstance getPassword]) == 0) 
    THROW(DAO_NULL_PIN_EX);
    
  // valido la password con su confirmacion
  if (strcmp([anInstance getPassword], [myTextConfirmPassword getText]) != 0) 
    THROW(RESID_INVALID_CONFIRM_PASSWORD);

	// el control de duress password lo hago solo si el perfil del usuario usa duress
	if ([[anInstance getProfile] getUseDuressPassword]) {

	  // valido que la duress password no sea vacia
  	if (strlen([anInstance getDuressPassword]) == 0) 
    	THROW(DAO_NULL_DURESS_PIN_EX);

  	// valido la duress password con su confirmacion
  	if (strcmp([anInstance getDuressPassword], [myTextConfirmDuressPassword getText]) != 0) 
    	THROW(RESID_INVALID_CONFIRM_DURESS_PASSWORD);
  
  	// valido que la nueva password sea distinta a la nueva clave de robo
  	if (strcmp([myTextPassword getText], [myTextDuressPassword getText]) == 0) 
    	THROW(RESID_EQUALS_PASSWORDS);  
	}
  
  // valido que la nueva password sea distinta a la anterior
  if (strcmp([myTextActualPassword getText], [myTextPassword getText]) == 0) 
    THROW(RESID_EQUAL_PASSWORD);
  
  TRY
      processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];
      
      printf("JUserChangePinEditForm ------------------------\n");
      
      printf("actual password = %s password = %s confirmPassword = %s  \n", [myTextActualPassword getText], [myTextPassword getText], [myTextConfirmPassword getText]);
      
        // Graba el usuario
      [anInstance applyPinChanges: [myTextActualPassword getText]];
	
      [processForm closeProcessForm];
	  [processForm free];
	  
	CATCH
	  
    [processForm closeProcessForm];
	  [processForm free];
	  RETHROW();
	  
	END_TRY
  	
  [JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_MSG_CHANGE_PIN_OK, "La clave ha sido modificada con exito.")];

	[[UserManager getInstance] setLoginInProgress: FALSE];

	// cierro el formulario
	[self closeForm];
}

/**/
- (char *) getCaption1
{
  if (myShowCancel) 
    return getResourceStringDef(RESID_CANCEL_KEY, "cancel");
  
  return NULL;
}

/**/
- (void) onMenu1ButtonClick
{
  if (!myShowCancel) return;
  
  [super onMenu1ButtonClick];
}

/**/
- (void) setShowCancel: (BOOL) aValue
{ 
   myShowCancel = aValue;
}

/**/
- (BOOL) getShowCancel
{
   return myShowCancel;
}

- (BOOL) wasCanceledLogin
{
	return myWasCanceledLogin;
}

@end

