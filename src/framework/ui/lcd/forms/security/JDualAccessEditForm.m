#include "JDualAccessEditForm.h"
#include "UserManager.h"
#include "util.h"
#include "MessageHandler.h"
#include "system/util/all.h"
#include "JMessageDialog.h"
#include "DAOExcepts.h"
#include "JExceptionForm.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation  JDualAccessEditForm


/**/
- (void) onCreateForm
{
	[super onCreateForm];
	printd("JDualAccessEditForm:onCreateForm\n");

	// Profile 1
	myLabelProfile1 = [JLabel new];
	[myLabelProfile1 setCaption: getResourceStringDef(RESID_PROFILE_1, "Perfil 1:")];
	[self addFormComponent: myLabelProfile1];
	
	myComboProfile1 = [JCombo new];

	[self addFormComponent: myComboProfile1];
	
	[self addFormNewPage];
	
	// Profile 2
	myLabelProfile2 = [JLabel new];
	[myLabelProfile2 setCaption: getResourceStringDef(RESID_PROFILE_2, "Perfil 2:")];
	[self addFormComponent: myLabelProfile2];
	
	myComboProfile2 = [JCombo new];

	[self addFormComponent: myComboProfile2];

	[self setConfirmAcceptOperation: TRUE];
	
}

/**/
- (void) onCancelForm: (id) anInstance
{
}

/**/
- (void) onMenu1ButtonClick {
  [self setModalResult: JFormModalResult_CANCEL];
  [self closeForm];
}

/**/
- (void) onModelToView: (id) anInstance
{
  int i;
  id user;
  COLLECTION myVisibleProfilesList;
  COLLECTION myAuxVisibleProfilesList;
	id profile = NULL;

	printd("JDualAccessEditForm:onModelToView\n");
	
  assert(anInstance != NULL);
  
  if ([self getFormMode] != JEditFormMode_VIEW) {

  		myVisibleProfilesList = [Collection new];
  		myAuxVisibleProfilesList = [Collection new];

      // traigo al usuario logueado para obtener el perfil que tiene
      user = [[UserManager getInstance] getUserLoggedIn];
      if ([user getUProfileId] != 1) { // si el perfil es diferente a ADMIN lo agrego a la lista
        profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
        if ([profile hasPermission: OPEN_DOOR_OP])
          [myAuxVisibleProfilesList add: profile];
      }
              
	     // traigo los hijos de este perfil
      [[UserManager getInstance] getChildProfiles: [user getUProfileId] childs: myVisibleProfilesList];
      // recorro los hijos
      for (i=0; i<[myVisibleProfilesList size]; ++i) {
          profile = [myVisibleProfilesList at: i];
          if ([profile hasPermission: OPEN_DOOR_OP])
            [myAuxVisibleProfilesList add: profile];
      }
			[myVisibleProfilesList free];
  } else {
      myAuxVisibleProfilesList = [[UserManager getInstance] getProfiles];
  }

  [myComboProfile1 clearAllItems];
  [myComboProfile2 clearAllItems];
	[myComboProfile1 addItemsFromCollection: myAuxVisibleProfilesList];
	[myComboProfile2 addItemsFromCollection: myAuxVisibleProfilesList];

	if ([self getFormMode] != JEditFormMode_VIEW) [myAuxVisibleProfilesList free];

  // Profile 1
	if ([anInstance getProfile1Id] > 0) {
    profile = [[UserManager getInstance] getProfile: [anInstance getProfile1Id]];
		[myComboProfile1 setSelectedItem: profile];
	}

  // Profile 2
	if ([anInstance getProfile2Id] > 0) {
		profile = [[UserManager getInstance] getProfile: [anInstance getProfile2Id]];
		[myComboProfile2 setSelectedItem: profile];
	}
}

/**/
- (void) onViewToModel: (id) anInstance
{
	printd("JDualAccessEditForm:onViewToModel\n");

	assert(anInstance != NULL);
	
  // Profile 1 id
  [anInstance setProfile1Id: [[myComboProfile1 getSelectedItem] getProfileId]];

  // Profile 2 id
  [anInstance setProfile2Id: [[myComboProfile2 getSelectedItem] getProfileId]];
}

/**/
- (void) onAcceptForm: (id) anInstance
{
  JFORM processForm = NULL;
  BOOL dualOk;
  
	printd("JDualAccessEditForm:onAcceptForm\n");

	assert(anInstance != NULL);
  
  dualOk = [[UserManager getInstance] verifiedDualAccess: [anInstance getProfile1Id] profile2Id: [anInstance getProfile2Id]];
  
  if (dualOk)
    processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];
      
  // Agrega el DualAccess
  [[UserManager getInstance] activateDualAccess: [anInstance getProfile1Id] profile2Id: [anInstance getProfile2Id]];
  // lo agrego en la lista de memoria
  [[UserManager getInstance] addDualAccessToCollection: anInstance];
  
  if (dualOk){
    [processForm closeProcessForm];
    [processForm free];
  }  
}

/**/
- (BOOL) doAcceptForm
{
	char *msg;
	char lngMsg[255];
	int except = 0;
	char ex_name[255];
	
	[self validateFormControls];

	if (myConfirmAcceptOperation) {
		msg = getResourceStringDef(RESID_SAVE_DUAL_ACCESS_MSSG, "Grabar dupla?");
		if (msg != NULL)
			if ([JMessageDialog askYesNoMessageFrom: self withMessage: msg]  == JDialogResult_NO)
				return FALSE;			
	}

	/** @todo: esto deberia hacerlo directamente el JWindow, pero por alguna razon
	    no funciona. Arreglar en algun momento */
	TRY

  	[self doViewToModel];
		[self onAcceptForm: myInstance];
		
	CATCH

		except = TRUE;
		
    TRY
		 	strcpy(ex_name, ex_get_name() );
			ex_printfmt();
			snprintf(lngMsg, JComponent_MAX_LEN, "%s", [[MessageHandler getInstance] processMessage: myBufferCustomForm messageNumber: ex_get_code()]);
			
    CATCH
		
		  snprintf(lngMsg, JComponent_MAX_LEN, "Exception: %d! %s",
							 ex_get_code(), ex_name);

		END_TRY
		
			[JMessageDialog askOKMessageFrom: self withMessage: lngMsg];
		
	END_TRY

	if (except) return FALSE;
	
	[self setModalResult: JFormModalResult_OK];		
	//[self doModelToView];	
	[self doChangeStatusBarCaptions];

	/* Si entro directo a editar y acepta sale del formulario */
	[self closeForm];
				
	return TRUE;
}

/**/
- (char *) getCaption2
{	
	if ([self getFormMode] == JEditFormMode_VIEW)
		return "";
	else
		return getResourceStringDef(RESID_SAVE_KEY, "grabar");
}

- (void) onMenu2ButtonClick
{
	BOOL mustPaint;
	
	mustPaint = FALSE;
		
	[self lockWindowsUpdate];
	
	TRY

			/* Paso a modo edicion ... */
			if (myFormMode == JEditFormMode_VIEW && myIsEditable) {
          // no hago nada								
			} else { 	/* Valida, acepta y pasa a modo view */
			
				if (myFormMode == JEditFormMode_EDIT) {
 					[self doAcceptForm];
						//[self doChangeFormMode: JEditFormMode_VIEW];
				}				
			}
		
	FINALLY
		
      [self unlockWindowsUpdate];
			[self sendPaintMessage];
		
	END_TRY;
}

@end

