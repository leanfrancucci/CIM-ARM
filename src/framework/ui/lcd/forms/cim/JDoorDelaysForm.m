#include "JDoorDelaysForm.h"
#include "MessageHandler.h"
#include "system/util/all.h"
#include "ExtractionWorkflow.h"
#include "JDoorStateForm.h"
#include "JMessageDialog.h"
#include "UICimUtils.h"

#define printd(args...) //doLog(0,args)
//#define printd(args...)

@implementation  JDoorDelaysForm

/**/
- (void) initComponent
{
	[super initComponent];
	*myTitle = '\0';
	myAutoRefreshTime = 0;
	myIsClosingForm = FALSE;
}
/**/
- (void) setAutoRefreshTime: (unsigned long) aValue
{
	myAutoRefreshTime = aValue;
}

/**/
- (void) setTitle: (char *) aTitle
{
	stringcpy(myTitle, aTitle);
}

/**/
- (void) doCreateForm
{
	[super doCreateForm];	
}	

/**/
- (void) setCollection: (COLLECTION) aCollection
{
	myCollection = aCollection;
}

/**/
- (void) doOpenForm
{
	int height;

	[super doOpenForm];
	
	if (*myTitle != '\0') {
		myLabelTitle = [self addLabel: myTitle];
		height = 2;
	}

	/* La lista de instancias */
	myObjectsList = [JGrid new];
	assert(myObjectsList != NULL);
	
	[myObjectsList setOwnObjects: FALSE];
	[myObjectsList setHeight: 2];
	[myObjectsList setShowItemNumber: TRUE];
	
	[self addFormComponent: myObjectsList];	
	
	/**/
	[myObjectsList addItemsFromCollection: myCollection];
	
	if (myAutoRefreshTime > 0) {

		myUpdateTimer = [OTimer new];
		[myUpdateTimer initTimer: PERIODIC period: myAutoRefreshTime object: self callback: "updateTimerHandler"];
		[myUpdateTimer start];

	}

	[self doChangeStatusBarCaptions];
}

/**/
- (char *) getCaption1
{
	return getResourceStringDef(RESID_CANCEL_KEY, "cancel");
}

/**/
- (char*) getCaptionX
{
	return getResourceStringDef(RESID_DONE, "listo");
}

/**/
- (char*) getCaption2
{
	return getResourceStringDef(RESID_VIEW, "ver");
}

/**/
- (void) onMenu1ButtonClick
{	
	myIsClosingForm = TRUE;
	if (myAutoRefreshTime > 0) [myUpdateTimer stop];
	
	[UICimUtils cancelTimeDelay: self extractionWorkflow: [myObjectsList getSelectedItem]];

	if (myAutoRefreshTime > 0) [myUpdateTimer start];
}

/**/
- (void) onMenuXButtonClick
{
	myIsClosingForm = TRUE;
	myModalResult = JFormModalResult_OK;
	if (myAutoRefreshTime > 0) [myUpdateTimer stop];
	[self closeForm];
}

/**/
- (void) onMenu2ButtonClick
{
	JFORM form;
	EXTRACTION_WORKFLOW extractionWorkflow;

	myIsClosingForm = TRUE;
	if (myAutoRefreshTime > 0) [myUpdateTimer stop];
	
	extractionWorkflow = [myObjectsList getSelectedItem];
	if (extractionWorkflow == NULL) return;

	form = [JDoorStateForm createForm: self];
	[form setExtractionWorkflow: extractionWorkflow];
	[form showModalForm];
	[form free];

	if (myAutoRefreshTime > 0) [myUpdateTimer start];

}

/**/
- (void) updateTimerHandler
{
	if (myIsClosingForm) return;

	[myObjectsList paintComponent];
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) anIsPressed
{
	if (!anIsPressed)
			return FALSE;

	/* La envia arriba a ver si la quieren procesar */
	if (![super doKeyPressed: aKey isKeyPressed: anIsPressed]) {
	
		switch (aKey) {

			case UserInterfaceDefs_KEY_MENU_X:
				[self doMenuXButtonClick];
				return TRUE;

			case UserInterfaceDefs_KEY_MENU_1:
				[self doMenu1ButtonClick];
				return TRUE;

			case UserInterfaceDefs_KEY_MENU_2:
				[self doMenu2ButtonClick];
				return TRUE;

		}
		
	}
	
	return FALSE;
}

@end

