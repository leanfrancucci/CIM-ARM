#include "JSimpleSelectionForm.h"
#include "system/printer/all.h"
#include "MessageHandler.h"
#include "system/util/all.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation  JSimpleSelectionForm

/**/
- (void) initComponent
{
	[super initComponent];
	*myTitle = '\0';
	myAutoRefreshTime = 0;
	myIsClosingForm = FALSE;
	myShowItemNumber = FALSE;
	mySelectedItem = NULL;
}

/**/
- (void) setShowItemNumber: (BOOL) aValue
{
	myShowItemNumber = aValue;
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
- (void) setInitialSelectedItem: (id) anItem
{
	mySelectedItem = anItem;
}

/**/
- (void) doOpenForm
{
	int height = 3;

	[super doOpenForm];
	
	if (*myTitle != '\0') {
		myLabelTitle = [self addLabel: myTitle];
		height = 2;
	}

	/* La lista de instancias */
	myObjectsList = [JGrid new];
	assert(myObjectsList != NULL);
	
	[myObjectsList setOwnObjects: FALSE];
	[myObjectsList setHeight: height];
	[myObjectsList setShowItemNumber: myShowItemNumber];


	[self addFormComponent: myObjectsList];	
	
	/**/
	[self addItemsFromCollection: myCollection];

	if (mySelectedItem != NULL) {
		TRY
			[myObjectsList setSelectedItem: mySelectedItem];
		CATCH
		END_TRY
	}

	
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
	return getResourceStringDef(RESID_BACK_KEY, "atras");
}

/**/
- (char*) getCaption2
{
	return getResourceStringDef(RESID_ENTER, "entrar");
}

/**/
- (void) onMenu1ButtonClick
{	
	myIsClosingForm = TRUE;
	myModalResult = JFormModalResult_CANCEL;
	if (myAutoRefreshTime > 0) [myUpdateTimer stop];
	[self closeForm];
}

/**/
- (void) onMenu2ButtonClick
{
	myIsClosingForm = TRUE;
	myModalResult = JFormModalResult_OK;
	if (myAutoRefreshTime > 0) [myUpdateTimer stop];
	[self closeForm];
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

/**
 * Metodos delegados a la lista
 **/
 
/**/
- (void) addItem: (id) anItem
{
	assert(myObjectsList != NULL);
	[myObjectsList addItem: anItem];
}

/**/
- (void) addItemsFromCollection: (id) aCollection
{
	assert(myObjectsList != NULL);
	[myObjectsList addItemsFromCollection: aCollection];
}

/**/
- (void) setSelectedIndex: (int) anIndex
{
	assert(myObjectsList != NULL);
	[myObjectsList setSelectedIndex: anIndex];
}

/**/
- (int) getSelectedIndex
{
	assert(myObjectsList != NULL);
	return [myObjectsList getSelectedIndex];
}

/**/
- (void) setSelectedItem: (id) anObject
{
	assert(myObjectsList != NULL);
	[myObjectsList setSelectedItem: anObject];
}

/**/
- (id) getSelectedItem
{
	assert(myObjectsList != NULL);
	return [myObjectsList getSelectedItem];
}

/**/
- (void) clearItems
{
  int i;
  int itemsSize;
  
  COLLECTION items = [myObjectsList getItemsCollection];  
	assert(myObjectsList != NULL);
  
  itemsSize = [items size] - 1;
  
  for (i = itemsSize; i > 0 ; i--) 
    //No los libera porque pertenecen a otra entidad.
    [self removeIndex: i];
    
  [myObjectsList setItemIndex: 0];
}


/**/
- (void) removeIndex: (int) anIndex
{
	assert(myObjectsList != NULL);
	[myObjectsList removeIndex: anIndex];
}


/**/
- (void) removeItem: (id) anObject
{
	assert(myObjectsList != NULL);
	[myObjectsList removeItem: anObject];
}

@end

