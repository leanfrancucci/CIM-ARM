#include "JDualAccessListForm.h"
#include "JDualAccessEditForm.h"
#include "UserManager.h"
#include "MessageHandler.h"
#include "JMessageDialog.h"
#include "JExceptionForm.h"

#define printd(args...) //doLog(0,args)
//#define printd(args...)

@implementation  JDualAccessListForm

/**/
- (void) onConfigureForm
{
  COLLECTION myDualAccesList;
  int profileId;
  
	/**/
	[self setAllowNewInstances: TRUE];
	[self setNewInstancesItemCaption: getResourceStringDef(RESID_NEW_USER, "Nuevo")];
	
	[self setAllowDeleteInstances: TRUE];
	[self setConfirmDeleteInstances: TRUE];
		
  // traigo las duplas
  profileId = [[[UserManager getInstance] getUserLoggedIn] getUProfileId];
  myDualAccesList = [[UserManager getInstance] getVisibleDualAccess: profileId];
    	
	[self addItemsFromCollection: myDualAccesList];
}

/**/
- (id) onNewInstance
{
	JFORM form;
	DUAL_ACCESS dual;
	
	dual = NULL;		
	form = [JDualAccessEditForm createForm: self];
	TRY
	
    dual = [DualAccess new];
    
		[form showFormToEdit: dual];
    
		if ([form getModalResult] == JFormModalResult_OK) {
			// no hago nada porque ya almacene en el JProfilesSelectionOperationEditForm
		} else {
			[dual free];
			dual = NULL;
		}
	
	FINALLY

		[form free];

	END_TRY

	return dual;
}

/**/
- (void) onSelectInstance: (id) anInstance
{
	JFORM form;
	id profile;
	
	// verifico que los perfiles posean permiso de Open Door.
	// si alguno de estos no lo posee no le permito pasar a la siguinete pantalla
  // perfil 1
  profile = [[UserManager getInstance] getProfile: [anInstance getProfile1Id]];
  if (![profile hasPermission: OPEN_DOOR_OP]){
    [JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_DONT_OPEN_DOOR_PROFILE1_MSG, "El perfil 1 no tiene permiso de ABRIR PUERTA!")];
    return;
  }
  // perfil 2  
  profile = [[UserManager getInstance] getProfile: [anInstance getProfile2Id]];
  if (![profile hasPermission: OPEN_DOOR_OP]){
    [JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_DONT_OPEN_DOOR_PROFILE2_MSG, "El perfil 2 no tiene permiso de ABRIR PUERTA!")];
    return;
  }
	
	form = [JDualAccessEditForm createForm: self];
	TRY
		
		[form showFormToView: anInstance];
		
	FINALLY

		[form free];

	END_TRY
}


/**/
/*- (void) onSelectInstance: (id) anInstance
{
  [self onNewInstance];
}*/

/**/
- (void) doDeleteInstance
{
	id instance;
	char *msg;
	JFORM processForm;

  assert(myObjectsList != NULL);
	
	instance = [myObjectsList getSelectedItem];
  
	/* Si permite agregar instancias no permite eliminar el primer item */
	if (!myAllowDeleteInstances || 
  	  (myAllowNewInstances && [myObjectsList getSelectedIndex] == 0) ||
			instance == NULL )
		return;
					
	if (myConfirmDeleteInstances) {
	
		msg = getResourceStringDef(RESID_DELETE_DUAL_ACCESS_MSSG, "Eliminar dupla?");
		if (msg != NULL)
			if ([JMessageDialog askYesNoMessageFrom: self withMessage: msg]  == JDialogResult_NO)
				return;
	}
	
	processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];
	
	[self onDeleteInstance: instance];
	[self removeItem: instance]; 

  [processForm closeProcessForm];
  [processForm free];
  
  [self doChangeStatusBarCaptions];
}

/**/
- (void) onDeleteInstance: (id) anInstance
{
	DUAL_ACCESS dual;

  dual = anInstance;

	// elimino el DualAccess seleccionado
  [[UserManager getInstance] deactivateDualAccess: [anInstance getProfile1Id] profile2Id: [anInstance getProfile2Id]];
  // lo quito en la lista de memoria
  [[UserManager getInstance] removeDualAccessFromCollection: anInstance];
}

/**/
/*- (char *) getCaption2
{			
	return getResourceStringDef(RESID_NEW, "nuevo");
}*/

@end

