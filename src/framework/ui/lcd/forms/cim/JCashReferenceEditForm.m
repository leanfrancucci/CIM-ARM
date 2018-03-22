#include "JCashReferenceEditForm.h"
#include "CashReference.h"
#include "MessageHandler.h"
#include "JMessageDialog.h"
#include "JExceptionForm.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

static char mySaveMsg[] = "Save ?";

@implementation  JCashReferenceEditForm

/**/
- (void) onCreateForm
{
	[super onCreateForm];

	[self setCloseOnAccept: TRUE];
	[self setCloseOnCancel: TRUE];

	// Parent
	myLabelParent = [self addLabelFromResource: RESID_PARENT_ default: "Padre: --"];
	
	// Reference Name
	myLabelReference = [self addLabelFromResource: RESID_REFERENCE_NAME default: "Nombre de Ref.:"];

	myTextReference = [JText new];
	[myTextReference setWidth: 16];
	[self addFormComponent: myTextReference];

	[self setConfirmAcceptOperation: TRUE];
}

/**/
- (void) onModelToView: (id) anInstance
{
	char buf[50];

	assert(anInstance != NULL);
	strcpy(buf, getResourceStringDef(RESID_PARENT, "Padre: "));


	if ([anInstance getParent] == NULL) 
		strcat(buf, "--");
	else 
		strcat(buf, [[anInstance getParent] getName]);

	[myLabelParent setCaption: buf];
	[myTextReference setText: [anInstance getName]];
	
}

/**/
- (void) onViewToModel: (id) anInstance
{
	[anInstance setName: [myTextReference getText]];
}

/**/
- (void) onAcceptForm: (id) anInstance
{
  JFORM processForm = NULL;
  
  TRY
    processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];
      
	  [anInstance applyChanges];

    [processForm closeProcessForm];
    [processForm free];

  CATCH
  
    [processForm closeProcessForm];
    [processForm free];
    RETHROW();
        
  END_TRY    	  
}

/**/
- (char *) getConfirmAcceptMessage: (char *) aMessage toSave: (id) anInstance
{
	return getResourceStringDef(RESID_SAVE_WITH_QUESTION_MARK, mySaveMsg);
}


/**/
- (void) onCancelForm: (id) anInstance
{
	assert(anInstance != NULL);

	if ([anInstance getCashReferenceId] > 0)
		[anInstance restore];
}

@end

