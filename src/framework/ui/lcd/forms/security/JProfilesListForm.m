#include "JProfilesListForm.h"
#include "MessageHandler.h"
#include "UserManager.h"
#include "ResourceStringDefs.h"
#include "Profile.h"
#include "JMessageDialog.h"
#include "SettingsExcepts.h"
#include "JProfilesEditForm.h"
#include "JExceptionForm.h"


//#define printd(args...) doLog(args)
#define printd(args...)

@implementation  JProfilesListForm

/**/
- (void) onConfigureForm
{
  COLLECTION myC;
  id user;
  id profile;
  
  /**/
  [self setAllowNewInstances: TRUE];
  [self setNewInstancesItemCaption: getResourceStringDef(RESID_NEW_USER, "Nuevo")];
	
  [self setAllowDeleteInstances: TRUE];
  [self setConfirmDeleteInstances: FALSE];
	
  myC = [Collection new];
  user = [[UserManager getInstance] getUserLoggedIn];
  profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
  // cargo el perfil del usuario actual
  [myC add: profile];
  // cargo los perfiles hijo
  [[UserManager getInstance] getChildProfiles: [user getUProfileId] childs: myC];
	
  [self addItemsFromCollection: myC];
}

/**/
- (id) onNewInstance
{
	JFORM form;
	volatile PROFILE profile;
	
	profile = NULL;
	form = [JProfilesEditForm createForm: self];

	TRY
	
		profile = [Profile new];
		[form showFormToEdit: profile];
    
		if ([form getModalResult] == JFormModalResult_OK) {
			// no hago nada porque ya almacene en el JProfilesSelectionOperationEditForm
		} else {
		  // esto se hace por si se guardaron los cambios y antes de salir de la pantalla
		  // se presiono update y cancelar. si profileId es 0 es porque no se llego a crear el profile
		  if ([profile getProfileId] == 0) {
				[profile free];
  			profile = NULL;
		  }
		}
	
	FINALLY

		[form free];

	END_TRY

	return profile;
}

/**/
- (void) onSelectInstance: (id) anInstance
{
	JFORM form;
	
	form = [JProfilesEditForm createForm: self];

	TRY
		
		[form showFormToView: anInstance];
		
	FINALLY

		[form free];

	END_TRY
}

/**/
- (void) onDeleteInstance: (id) anInstance
{
	PROFILE profile;
	COLLECTION myC;
	int i;
	BOOL deleteProfile;
	char aMessage[200];
	JFORM processForm = NULL;
	BOOL profOk;
	
	profile = anInstance;

  // 1) Si es perfil = 1 no permito eliminarlo porque es el perfil ADMIN.
  if ([profile getProfileId] == 1) THROW(NOT_DELETE_PROFILE_ADMIN_EX);

  // verifico si tiene hijos. En ese caso muestro un mensaje por pantalla
  myC = [Collection new];
  [[UserManager getInstance] getChildProfiles: [profile getProfileId] childs: myC];
  
  deleteProfile = TRUE;
  if ([myC size] > 0){
    if ([JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_REMOVE_PROFILE_CASCADE_MSG, "Las dependencias del perfil seran eliminadas. Confirma?")] == JDialogResult_NO)
      deleteProfile = FALSE;
  }else{
	     snprintf(aMessage, JCustomForm_MAX_MESSAGE_SIZE, getResourceStringDef(RESID_ASK_DELETE, "Eliminar: %s?"), [anInstance str]);  
    if ([JMessageDialog askYesNoMessageFrom: self withMessage: aMessage] == JDialogResult_NO)
      deleteProfile = FALSE;
  }

  if (deleteProfile){

    profOk = [[UserManager getInstance] canRemoveProfile: [profile getProfileId]];
    if (profOk)
      processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];
      
    // elimino el perfil padre
    [[UserManager getInstance] removeProfile: [profile getProfileId]];
    [self removeItem: anInstance];
  	
    // elimino los items hijos de lista
    for (i=0; i<[myC size]; ++i){
  	  [self removeItem: [myC at: i]];
    }
    
    if (profOk){
      [processForm closeProcessForm];
      [processForm free];
    }
  }
	[myC free];
}	


/**/
- (char *) getDeleteInstanceMessage: (char *) aMessage toSave: (id) anInstance
{
	snprintf(aMessage, JCustomForm_MAX_MESSAGE_SIZE, 
            getResourceStringDef(RESID_ASK_DELETE, "Eliminar: %s?"), [anInstance str]);
	return aMessage;
}

/**/
- (void) doDeleteInstance
{
	id instance;
	char *msg;

  assert(myObjectsList != NULL);
	
	instance = [myObjectsList getSelectedItem];
  
	/* Si permite agregar instancias no permite eliminar el primer item */
	if (!myAllowDeleteInstances || 
  	  (myAllowNewInstances && [myObjectsList getSelectedIndex] == 0) ||
			instance == NULL ) 
		return;
					
	if (myConfirmDeleteInstances) {
		msg = [self getDeleteInstanceMessage: myDeleteMessage toSave: instance];		
		if (msg != NULL)
			if ([JMessageDialog askYesNoMessageFrom: self withMessage: msg]  == JDialogResult_NO)
				return;
	}
	
	[self onDeleteInstance: instance];
  
  [self doChangeStatusBarCaptions];
}

@end

