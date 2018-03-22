#include "JCashReferenceListForm.h"
#include "JCashReferenceEditForm.h"
#include "CashReferenceManager.h"
#include "UICimUtils.h"
#include "Option.h"
#include "JMessageDialog.h"
#include "MessageHandler.h"
#include "JExceptionForm.h"

#define printd(args...)/// doLog(0,args)
//#define printd(args...)

#define OPTION_NEW 			1
#define OPTION_EDIT 		2
#define OPTION_DELETE	  3

@implementation  JCashReferenceListForm

/**/
- (void) showChilds: (CASH_REFERENCE) aParent;

/**/
- (void) onConfigureForm
{
  /**/
	[self setTitle: getResourceStringDef(RESID_SELECT_REFERENCE, "Selec reference:")];
	[self setAllowNewInstances: FALSE];
	[self setAllowDeleteInstances: TRUE];
	[self setConfirmDeleteInstances: TRUE];
	[self setReturnToFirstItem: TRUE];
	[myObjectsList setShowItemNumber: TRUE];
}

/**/
- (void) doOpenForm
{
	[self setTitle: getResourceStringDef(RESID_SELECT_REFERENCE, "Selec reference:")];
	myCurrentReference = NULL;
	[super doOpenForm];
	[self showChilds: NULL];
}

/**/
- (id) addCashReference
{
	JCASH_REFERENCE_EDIT_FORM form;
	CASH_REFERENCE reference = [CashReference new];

	[reference setParent: myCurrentReference];

	form = [JCashReferenceEditForm createForm: self]; 
	[form showFormToEdit: reference]; 

	if ([form getModalResult] != JFormModalResult_OK) {
		// esto se hace por si se guardaron los cambios y antes de salir de la pantalla
		// se presiono update y cancelar. si CashReferenceId es 0 es porque no se llego a crear el reference		
    if ([reference getCashReferenceId] == 0){
      [reference free];
  		reference = NULL;
		}else{
      [[CashReferenceManager getInstance] addCashReference: reference];
    }
	} else {
		[[CashReferenceManager getInstance] addCashReference: reference];
	}

	[form free];

	return reference;
}

/**/
- (void) editCashReference
{
	JCASH_REFERENCE_EDIT_FORM form;
	CASH_REFERENCE reference;
	
	reference = [myObjectsList getSelectedItem];

	form = [JCashReferenceEditForm createForm: self]; 
	[form showFormToEdit: reference]; 
	[form free];
}

/**/
- (void) removeCashReference
{
	CASH_REFERENCE reference;
	char buf[100];
	JFORM processForm = NULL;
	
	reference = [myObjectsList getSelectedItem];
	formatResourceStringDef(buf, RESID_REMOVE_FORMAT_QUESTION, "Elimina %s?", [reference getName]);
	if ([JMessageDialog askYesNoMessageFrom: self withMessage: buf] == JDialogResult_YES) {

    TRY
      processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];
            
		  [[CashReferenceManager getInstance] removeCashReference: reference];

      [processForm closeProcessForm];
      [processForm free];
  
    CATCH
    
      [processForm closeProcessForm];
      [processForm free];
      RETHROW();
          
    END_TRY		  

	}	
	
}

/**/
- (char *) getCaptionX
{
	return getResourceStringDef(RESID_MORE, "mas");
}

/**/
- (char *) getCaption1
{
	return getResourceStringDef(RESID_BACK_KEY, "atras");
}

/**/
- (char *) getCaption2
{
	return getResourceStringDef(RESID_SELECT_KEY, "selecc");
}

/**/
- (void) showChilds: (CASH_REFERENCE) aParent
{
	COLLECTION childs;

	childs = [Collection new];
	myCurrentReference = aParent;

	if (myCurrentReference == NULL) 
		[myLabelTitle setCaption: getResourceStringDef(RESID_SELECT_REFERENCE, "Selec reference:")];
	else 
		[myLabelTitle setCaption: [myCurrentReference getName]];

	[[CashReferenceManager getInstance] getCashReferenceChilds: childs cashReference: aParent];
	
	[myObjectsList clearItems];
	[self addItemsFromCollection: childs];

	[childs free];

	[self paintComponent];
	
}

/**/
- (void) onMenu2ButtonClick
{
	if ([myObjectsList getSelectedItem] != NULL)
		[self showChilds: [myObjectsList getSelectedItem]];
}

/**/
- (void) onMenuXButtonClick
{
	COLLECTION options = [Collection new];
	OPTION option;

	[options add: [Option newOption: OPTION_NEW value: getResourceStringDef(RESID_NEW_GENERAL_OP, "Nuevo")]];

	if ([myObjectsList getSelectedItem] != NULL) {
		[options add: [Option newOption: OPTION_EDIT value: getResourceStringDef(RESID_EDIT_GENERAL_OP, "Modif")]];
		[options add: [Option newOption: OPTION_DELETE value: getResourceStringDef(RESID_DELETE_GENERAL_OP, "Elimin")]];
	}

	option = [UICimUtils selectFromCollection: self
		collection: options
		title: ""
		showItemNumber: TRUE];

	if (option != NULL) {
	
		switch ([option getKeyOption]) {
			case OPTION_NEW: 
				[self addCashReference];
				[self showChilds: myCurrentReference];
				break;
	
			case OPTION_EDIT:
				[self editCashReference];
				[self showChilds: myCurrentReference];
				break;
	
			case OPTION_DELETE:                   
  				  [self removeCashReference];
  				  [self showChilds: myCurrentReference];
				break; 

		}	
	}

	[options freeContents];
	[options free];
}

/**/
- (void) onMenu1ButtonClick
{
	if (myCurrentReference == NULL) {
		[self closeForm];
		return;
	}

	[self showChilds: [myCurrentReference getParent]];
}

@end

