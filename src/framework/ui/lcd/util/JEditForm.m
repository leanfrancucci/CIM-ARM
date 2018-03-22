#include <assert.h>
#include "UserInterfaceDefs.h"
#include "JMessageDialog.h"
#include "JEditForm.h"
#include "MessageHandler.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation  JEditForm

static char myBackMessageString[] 		= "atras";
static char myCancelMessageString[] 	= "cancel";
static char myEditMessageString[] 		= "modif.";
static char mySaveMessageString[] 		= "grabar";
static char myAskSaveMessageFormat[]  = "Grabar %s?";
		
/**/
- (void) initComponent
{
	[super initComponent];

	myFormMode = JEditFormMode_VIEW;
	myCloseOnCancel = FALSE;
	myCloseOnAccept = FALSE;
	myIsEditable = TRUE;
	
	myInstance = NULL;

	myConfirmAcceptMessage[0] = '\0';	
	
	myEditFocusInFirstControlMode = FALSE;

}

/**/
- free
{
	return [super free];
}

/**/
- (void) setEditable: (BOOL) aValue { myIsEditable = aValue; }
- (BOOL) isEditable { return myIsEditable; }

/**/
- (void) setEditFocusInFirstControlMode: (BOOL) aValue { myEditFocusInFirstControlMode = aValue; }
- (BOOL) isEditFocusInFirstControlMode { return myEditFocusInFirstControlMode; }

/**/
- (void) setFormInstance: (id) anInstance { myInstance = anInstance; }

/**/
- (id) getFormInstance { return myInstance; }

/**/
- (JEditFormMode) getFormMode { return myFormMode; }

/**/
- (void) setCloseOnAccept: (BOOL) aValue { myCloseOnAccept = aValue; }
- (BOOL) getCloseOnAccept { return myCloseOnAccept; }

/**/
- (void) setCloseOnCancel: (BOOL) aValue { myCloseOnCancel= aValue; }
- (BOOL) getCloseOnCancel { return myCloseOnCancel; }

/**/
- (JFormModalResult) showFormToView: (id) anInstance
{
	[self setFormInstance: anInstance];
	
	myCloseOnCancel = FALSE;
	myFormMode = JEditFormMode_VIEW;	
	return [self showModalForm];
}

/**/
- (JFormModalResult) showFormToEdit: (id) anInstance
{
	[self setFormInstance: anInstance];
	
	myCloseOnCancel = TRUE;
	myFormMode = JEditFormMode_EDIT;	
	return [self showModalForm];
}

/**/
- (void) validateFormControls
{
	int i;

	for (i = 0; i < [self getFormComponentCount]; i++)
		[[self getFormComponentAt: i] validateComponent];
}


/**/
- (void) doCreateForm
{
	[super doCreateForm];
}


/**/
- (void) doDestroyForm
{
	[super doDestroyForm];
}

/**/
- (void) doOpenForm
{
	[super doOpenForm];
  
	[self doModelToView];
  
	[self doChangeFormMode: myFormMode];	
}

/**/
- (void) doCloseForm
{
	[super doCloseForm];
}


/**/
- (void) doChangeFormMode: (JEditFormMode) aNewFormMode
{
	int i;
			
	myFormMode = aNewFormMode;

	/* Pone todos los controles en ReadOnly asi se visualizan como para visualizar
	  o como para editar */
	for (i = 0; i < [self getFormComponentCount]; i++) {
        printf("6\n");
		[[self getFormComponentAt: i] setReadOnly: (myFormMode == JEditFormMode_VIEW) || (![[self getFormComponentAt: i] isEnabled])];
    }
  
	[self focusInFirstEditComponent];
	[self onChangeFormMode: myFormMode];
	[self doChangeStatusBarCaptions];	
}


/**/
- (BOOL) doAcceptForm
{
	char *msg;
	char lngMsg[255];
	volatile int except = 0;
	char ex_name[255];
	
	[self validateFormControls];

	if (myConfirmAcceptOperation) {
		msg = [self getConfirmAcceptMessage: myConfirmAcceptMessage toSave: myInstance];
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
	[self doModelToView];	
	[self doChangeStatusBarCaptions];
		
	myCloseOnCancel = FALSE;

	/* Si entro directo a editar y acepta sale del formulario */
	if (myCloseOnAccept)
		[self closeForm];
				
	return TRUE;
}

/**/
- (void) doCancelForm
{
	[self onCancelForm: myInstance];
	[self doModelToView];
	[self setModalResult: JFormModalResult_CANCEL];

	/* Si entro directo a editar y cancela sale del formulario */
	if (myCloseOnCancel)
		[self closeForm];
	
  [self doChangeStatusBarCaptions];
}

/**/
- (void) doModelToView
{
	[self onModelToView: myInstance];
}

/**/
- (void) doViewToModel
{
	[self onViewToModel: myInstance];
}

/**/
- (void) setConfirmAcceptOperation: (BOOL) aValue { myConfirmAcceptOperation = aValue; }

/**/
- (BOOL) getConfirmAcceptOperation { return myConfirmAcceptOperation; }

/**/
- (char *) getConfirmAcceptMessage: (char *) aMessage toSave: (id) anInstance
{
	assert(anInstance != NULL);
		
	snprintf(myConfirmAcceptMessage, sizeof(myConfirmAcceptMessage) - 1,
					  getResourceStringDef(RESID_ASK_SAVE_KEY, myAskSaveMessageFormat), [anInstance str]);
	return myConfirmAcceptMessage;
}

/**
 * Los eventos
 **/


/**/
- (void) onChangeFormMode: (JEditFormMode) aNewMode
{	
	aNewMode = aNewMode;
}

/**/
- (void) onAcceptForm: (id) anInstance
{
	anInstance = anInstance;
}


/**/
- (void) onCancelForm: (id) anInstance
{
	anInstance = anInstance;
}

/**/
- (void) onModelToView: (id) anInstance
{
	anInstance = anInstance;
}

/**/
- (void) onViewToModel: (id) anInstance
{
	anInstance = anInstance;
}


/**
 * Si esta en modo VIEW cierra el form.
 * Si esta en modo EDIT lo cancela y lo cambia a modo VIEW.
 */
- (void) onMenu1ButtonClick
{
	volatile BOOL mustPaint;
	
	mustPaint = FALSE;
	
	[self lockWindowsUpdate];
			
	TRY
		
		/* Paso a modo edicion ... */
		if (myFormMode == JEditFormMode_VIEW) {		
			[self closeForm];		
		} else {  	/* Cancela el modo EDIT */						
			if (myFormMode == JEditFormMode_EDIT) {			
				[self cancelForm];
				[self doChangeFormMode: JEditFormMode_VIEW];
				mustPaint = TRUE;				
			}				
		}
		
	FINALLY
	
		[self unlockWindowsUpdate];
		if (mustPaint) {
      [self sendPaintMessage];
    }      
	
	END_TRY;	
}

/**
 * Si esta en modo VIEW entra en modo EDIT.
 * Si esta en modo EDIT, acepta el formulario y entra en modo VIEW
 */
- (void) onMenu2ButtonClick
{
	BOOL mustPaint;
	
	mustPaint = FALSE;
		
	[self lockWindowsUpdate];
	
	TRY

			/* Paso a modo edicion ... */
			if (myFormMode == JEditFormMode_VIEW && myIsEditable) {
			
				[self doChangeFormMode: JEditFormMode_EDIT];
				mustPaint = TRUE;
								
			} else { 	/* Valida, acepta y pasa a modo view */
			
				if (myFormMode == JEditFormMode_EDIT) {
 					if ([self doAcceptForm])
						[self doChangeFormMode: JEditFormMode_VIEW];
				}				
			}
		
	FINALLY
		
      [self unlockWindowsUpdate];
		
//		if (mustPaint)
			[self sendPaintMessage];
		
	END_TRY;
}

/**/
- (void) acceptForm
{
	[self doAcceptForm];
}

/**/
- (void) cancelForm
{
	[self doCancelForm];
}

/**/
- (char *) getCaption1
{
	if ([self getFormMode] == JEditFormMode_VIEW)	
		return getResourceStringDef(RESID_BACK_KEY, myBackMessageString);
	else
		return getResourceStringDef(RESID_CANCEL_KEY, myCancelMessageString);
}

/**/
- (char *) getCaption2
{

	if ([self getFormMode] == JEditFormMode_VIEW) {
		
		if (!myIsEditable)
			return NULL;
		
		return getResourceStringDef(RESID_UPDATE_KEY, myEditMessageString);
	
	} else // [self getFormMode] == JEditFormMode_EDIT
		
		return getResourceStringDef(RESID_SAVE_KEY, mySaveMessageString);
}

/**/
- (void) focusInFirstEditComponent
{
	if (myEditFocusInFirstControlMode)
		[self focusFormFirstComponent];	
	else
		[self focusFormFirstComponentInCurrentPage];	
}


- (void) onChangedFocusedComponent
{
  [super onChangedFocusedComponent];
}

@end

