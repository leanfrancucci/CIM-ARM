#include <assert.h>
#include "util.h"
#include "UserInterfaceDefs.h"
#include "JMessageDialog.h"
#include "JListForm.h"
#include "MessageHandler.h"


//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation  JListForm

static char myBackMessageString[] 		= "atras";			
static char myDeleteString[] 					= "eliminar";	
static char myNewMessageString[] 			= "nuevo";				
static char myViewMessageString[] 		= "ver";
		
/**/
- (void) initComponent
{
	[super initComponent];

	*myTitle = '\0';
	myAllowNewInstances = TRUE;
	myAllowDeleteInstances = TRUE;
	myConfirmDeleteInstances = TRUE;
	myReturnToFirstItem = FALSE;
	myNewInstancesItemCaption = [String str: getResourceStringDef(RESID_NEW, myNewMessageString)];
	myDeleteMessage[0] = '\0';
}
	
/**/
- free
{
	[myNewInstancesItemCaption free];
	
	return [super free];
}

/**/
- (void) setTitle: (char *) aTitle
{
	stringcpy(myTitle, aTitle);
}

/**
 * Metodos protegidos
 */

/**/
- (void) doOpenForm
{
	int height = 3;

	[super doOpenForm];

	if (*myTitle != '\0') {
		height = 2;
		myLabelTitle = [self addLabel: myTitle];
	}
		
	/* La lista de instancias */
	myObjectsList = [JGrid new];
	assert(myObjectsList != NULL);
	
	[myObjectsList setOwnObjects: FALSE];
	[myObjectsList setHeight: height];
	
	[self addFormComponent: myObjectsList];	

	
	[myObjectsList addItem: myNewInstancesItemCaption];	
	[self onConfigureForm];	
	
	if (!myAllowNewInstances)
		[myObjectsList removeIndex: 0];
		
	[self doChangeStatusBarCaptions];
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


/**/
- (void) doMenuXButtonClick
{
	[self onMenuXButtonClick];
}


/**/
- (void) doMenu2ButtonClick
{
	[self onMenu2ButtonClick];
}

/**
 * Metodos protegidos
 */

/**/
- (void) onMenuXButtonClick
{
	[self doDeleteInstance];
}

/**/
- (void) onMenu1ButtonClick
{	
	[super onMenu1ButtonClick];
}


/**/
- (void) onMenu2ButtonClick
{
	[self doSelectInstance];
}

/**/
- (void) addNewItem
{
	id instance;

	instance = [self onNewInstance];
	if (instance != NULL) {
		[self addItem: instance];			
		if (myReturnToFirstItem) [self setSelectedIndex: 0];
		else [self setSelectedItem: instance];
	} else {
		if (myReturnToFirstItem && [[myObjectsList getItemsCollection] size] > 0) [self setSelectedIndex: 0];
	}

}

/**/
- (void) editItem
{
	id instance;

	instance = [myObjectsList getSelectedItem];
	if (instance == NULL) return;
	[self onSelectInstance: instance];		
	if (myReturnToFirstItem) [self setSelectedIndex: 0];
}

/**/
- (void) doSelectInstance
{
	
	assert(myObjectsList != NULL);
	
	/* Si es el primer item y permite agregar nuevos items lo hace */
	if (myAllowNewInstances && [myObjectsList getSelectedIndex] == 0) {
		
		[self addNewItem];

	} else  { /* Lo manda al formulario para que haga lo que quiera (en gral. visualizar) */ 

		[self editItem];

	}		
  
  [self doChangeStatusBarCaptions];
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
	[self removeItem: instance]; 
  
  [self doChangeStatusBarCaptions];
}

/**
 * Metodos protegidos
 **/

/**/
- (id) onNewInstance
{
	return NULL;
}

/**/
- (void) onSelectInstance: (id) anInstance
{
	anInstance = anInstance;
}

/**/
- (void) onDeleteInstance: (id) anInstance
{
	anInstance = anInstance;
}

/**/
- (void) onConfigureForm
{
}

/**/
- (void) setAllowNewInstances: (BOOL) aValue { myAllowNewInstances = aValue; }
- (BOOL) getAllowNewInstances { return myAllowNewInstances; }

/**/
- (void) setNewInstancesItemCaption: (char *) aString
{
	THROW_NULL(aString);
	
	[myNewInstancesItemCaption assignSTR: aString];
}

/**/
- (void) setAllowDeleteInstances: (BOOL) aValue { myAllowDeleteInstances = aValue; }
- (BOOL) getAllowDeleteInstances { return myAllowDeleteInstances; }

/**/
- (void) setConfirmDeleteInstances: (BOOL) aValue { myConfirmDeleteInstances = aValue; }
- (BOOL) getConfirmDeleteInstances { return myConfirmDeleteInstances; }

/**/
- (char *) getDeleteInstanceMessage: (char *) aMessage toSave: (id) anInstance
{
	assert(anInstance != NULL);	
	snprintf(myDeleteMessage, JCustomForm_MAX_MESSAGE_SIZE, 
            getResourceStringDef(RESID_DELETE_MSSG, "Eliminar %s"), [anInstance str]);
	return myDeleteMessage;
}

/**/
- (BOOL) canInsertNewInstanceOnSelection
{
	return myAllowNewInstances && [self getSelectedIndex] == 0;
}

/**/
- (BOOL) canDeleteInstanceOnSelection
{
	int index = [self getSelectedIndex];
	
	return myAllowDeleteInstances && 
					((index >= 0 && !myAllowNewInstances) ||
					 (index  > 0 &&  myAllowNewInstances) );
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
  if (myObjectsList == NULL) return -1;
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
    [self removeIndex: 0];
    
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

/**/
- (char *) getCaption1
{
	return getResourceStringDef(RESID_BACK_KEY, myBackMessageString);
}

/**/
- (char *) getCaptionX
{
	if ([self canDeleteInstanceOnSelection])
		return getResourceStringDef(RESID_DELETE, myDeleteString);	
	else
		return [super getCaptionX];
}

/**/
- (char *) getCaption2
{
	if ([self canInsertNewInstanceOnSelection])			
		return getResourceStringDef(RESID_NEW, myNewMessageString);
	else
		return getResourceStringDef(RESID_VIEW, myViewMessageString);
}

/**/
- (BOOL) listHasItems
{
  return [[myObjectsList getItemsCollection] size] > 0; 
} 

/**/
- (int) getItemsQty
{
  return [[myObjectsList getItemsCollection] size];
}

/**/
- (void) addStringItem: (char*) aStringItem
{
	assert(myObjectsList != NULL);
	[myObjectsList addStringItem: aStringItem];  
}

/**/
- (void) setPaintObjectString: (BOOL) aValue
{
	assert(myObjectsList != NULL);
	[myObjectsList setPaintObjectString: aValue];  
}

/**/
- (void) clearStringItems
{
	[myObjectsList removeStringItems]; 
}
 
/**/
- (void) setReturnToFirstItem: (BOOL) aValue { myReturnToFirstItem = aValue; }
@end

