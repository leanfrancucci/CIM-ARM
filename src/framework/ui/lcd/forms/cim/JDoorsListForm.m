#include "JDoorsListForm.h"
#include "SettingsExcepts.h"
#include "MessageHandler.h"

#include "JDoorsEditForm.h"
#include "JExceptionForm.h"
#include "CimManager.h"

#define printd(args...)// doLog(0,args)
//#define printd(args...)

@implementation  JDoorsListForm

/**/
- (void) onConfigureForm
{
	/**/
	[self setAllowNewInstances: FALSE];
	[self setAllowDeleteInstances: FALSE];
	
	[self addItemsFromCollection: [[[CimManager getInstance] getCim] getDoors]];	
}

/**/
- (void) onSelectInstance: (id) anInstance
{
	JFORM form;
	
	form = [JDoorsEditForm createForm: self];

	TRY
		
		[form showFormToView: anInstance];
		
	FINALLY

		[form free];

	END_TRY
}

/**/
- (char *) getCaption1
{
	return getResourceStringDef(RESID_BACK_KEY, "atras");
}

/**/
- (char *) getCaption2
{
	if (![self canInsertNewInstanceOnSelection])			
		return getResourceStringDef(RESID_UPDATE_KEY, "modif.");

	return [super getCaption2];
}

@end

