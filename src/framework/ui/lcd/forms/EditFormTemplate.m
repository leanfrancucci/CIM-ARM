#include "JTemplateEditForm.h"
#include "MessageHandler.h"

#define printd(args...) //doLog(0,args)
//#define printd(args...)

@implementation  JTemplateEditForm


/**/
- (void) onCreateForm
{
	[super onCreateForm];
	printd("JTemplateEditForm:onCreateForm\n");

	//Crear controles

	[self setConfirmAcceptOperation: FALSE];
}


/**/
- (void) onCancelForm: (id) anInstance;
{
	printd("JTemplateEditForm:onAcceptForm\n");

	assert(anInstance != NULL);
	
	if ([anInstance getTemplateId] > 0)
		[anInstance restore];
}

/**/
- (void) onModelToView: (id) anInstance;
{
	printd("JTemplateEditForm:onModelToView\n");
	
	assert(anInstance != NULL);
	
	//Setear los valores a los controles
}

/**/
- (void) onViewToModel: (id) anInstance;
{
	printd("JTemplateEditForm:onViewToModel\n");
	
	assert(anInstance != NULL);
	
	// Setear los valores a la instancia
}

/**/
- (void) onAcceptForm: (id) anInstance;
{
	printd("JTemplateEditForm:onAcceptForm\n");

	assert(anInstance != NULL);
	
	/* Graba el template */
	[anInstance applyChanges];
}

/**/
- (char *) getConfirmAcceptMessage: (id) anInstance
{
	snprintf(myConfirmMessage, sizeof(myConfirmMessage) - 1, "%s: %s", 
            getResourceStringDef(RESID_YOU_SURE, "Estas seguro ?"), [anInstance str]);
	return myConfirmMessage;
}

@end

