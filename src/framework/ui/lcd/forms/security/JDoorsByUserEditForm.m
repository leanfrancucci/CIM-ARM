#include "JDoorsByUserEditForm.h"
#include "UserManager.h"
#include "util.h"
#include "Door.h"
#include "MessageHandler.h"
#include "system/util/all.h"
#include "JExceptionForm.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation  JDoorsByUserEditForm
static char myCaptionX[] = "marcar";
static char myEditMessageString[] 		= "modif.";
static char mySaveMessageString[] 		= "grabar";

/**/
- (void) onCreateForm
{
	id doors;
	id user;
  int i;
  id checkBox;
  
  myDoorsCheckBoxCollection = [Collection new];
  
	[super onCreateForm];
	printd("JDoorsByUserEditForm:onCreateForm\n");

  myCheckBoxList = [JCheckBoxList new];
  [myCheckBoxList setHeight: 3];
  
  user = [[UserManager getInstance] getUserLoggedIn];

  // traigo las puertas del usuario
  doors = [user getDoors];

	printf("cantidad de puertas de usuario = %d\n", [doors size]);
  
  for (i=0; i < [doors size]; ++i) {
    checkBox = [JCheckBox new];
    [checkBox setCaption: [[doors at: i] getDoorName ]];
    [checkBox setCheckItem: [doors at: i]];
        
    [myDoorsCheckBoxCollection add: checkBox];
  }
  
  [myCheckBoxList addCheckBoxFromCollection: myDoorsCheckBoxCollection];
  [self addFormComponent: myCheckBoxList];

	[self setConfirmAcceptOperation: TRUE];

}

/**/
- (void) onModelToView: (id) anInstance
{
	int i;
  BOOL checked;
  
  printd("JDoorsByUserEditForm:onModelToView\n");

	assert(anInstance != NULL);

  for (i = 0; i < [myDoorsCheckBoxCollection size]; ++i) {
    checked = FALSE;
        
    if ([anInstance getUserDoor: [[[myDoorsCheckBoxCollection at: i] getCheckItem] getDoorId]] != NULL)
      checked = TRUE;
        
    [[myDoorsCheckBoxCollection at: i] setChecked: checked];
  }   	
}


/**/
- (void) onAcceptForm: (id) anInstance
{
  int i,j;
	COLLECTION oldDoors;
	COLLECTION newDoors;
	DOOR door;
	BOOL existsDoor;
	JFORM processForm;
  
  printd("JDoorsByUserEditForm:onAcceptForm\n");
	assert(anInstance != NULL);

  processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];

	newDoors = [Collection new];
  
  for (i = 0; i < [myDoorsCheckBoxCollection size]; ++i) {
		if ([[myDoorsCheckBoxCollection at: i] isChecked])
			[newDoors add: [[myDoorsCheckBoxCollection at: i] getCheckItem]];
	}

	oldDoors = [[anInstance getDoors] clone];

	// Debo comparar la lista anterior y la nueva para ver cuales debo
	// eliminar y cuales debo agregar
	// La politica es: 
	// 		- Si esta en la lista anterior pero no en la nueva lo debo eliminar.
	//		- Si esta en la lista nueva pero no en la anterior lo debo agregar

	for (i = 0; i < [oldDoors size]; ++i) {
		door = [oldDoors at: i];
		if (![newDoors contains: door]) {
      
      // me fijo si el door existe en la coleccion. Si existe la deshabilito.
      // este control se hace por si el que esta logueado no posee permiso para
      // todas las puertas. De esta manera se evita que deshabiliten puertas a las cuales no tiene permiso.
      existsDoor = FALSE;
      for (j = 0; j < [myDoorsCheckBoxCollection size]; ++j) {
    			if (door == [[myDoorsCheckBoxCollection at: j] getCheckItem])
    	     	existsDoor = TRUE;
    	}			
      
      if (existsDoor){
        [[UserManager getInstance] deactivateDoorByUser: [door getDoorId] userId: [anInstance getUserId]];
  			// quito la puerta de memoria
        [anInstance removeDoorByUserToCollection: [door getDoorId]];
      }
		}
	}

	for (i = 0; i < [newDoors size]; ++i) {
		door = [newDoors at: i];
		if (![oldDoors contains: door]) {
			[[UserManager getInstance] activateDoorByUserId: [door getDoorId] userId: [anInstance getUserId]];
			// agrego la puerta en memoria
      [anInstance addDoorByUserToCollection: [door getDoorId]];			
		}
	}

	[oldDoors free];
	[newDoors free];
	
	[processForm closeProcessForm];
  [processForm free];

}

/**/
- (char *) getConfirmAcceptMessage: (char *) aMessage toSave: (id) anInstance
{
	snprintf(aMessage, JCustomForm_MAX_MESSAGE_SIZE, getResourceStringDef(RESID_SAVE_DOOR_BY_USER_QUESTION, "Grabar configuracion de puertas por usuario?"));
	return aMessage;
}

/**/
- (char *) getCaptionX
{
  if ([self getFormMode] == JEditFormMode_EDIT)
    return getResourceStringDef(RESID_CHECK, myCaptionX);
    
  return NULL;    
}

/**
 * Si esta en modo VIEW entra en modo EDIT.
 * Si esta en modo EDIT, acepta el formulario y entra en modo VIEW
 */
- (void) onMenu2ButtonClick
{
	int userLoguedId;
	
	[self lockWindowsUpdate];
	
	userLoguedId = [[[UserManager getInstance] getUserLoggedIn] getUserId];
	
	TRY

		// si el usuario a modificar es el usuario logueado no lo dejo
		if (userLoguedId != [[self getFormInstance] getUserId]){
			/* Paso a modo edicion ... */
      if (myFormMode == JEditFormMode_VIEW && myIsEditable) {
			
				[self doChangeFormMode: JEditFormMode_EDIT];
								
			} else { 	/* Valida, acepta y pasa a modo view */
			
				if (myFormMode == JEditFormMode_EDIT) {
 					if ([self doAcceptForm])
						[self doChangeFormMode: JEditFormMode_VIEW];
				}				
			}
		}
		
	FINALLY
		
      [self unlockWindowsUpdate];
		
			[self sendPaintMessage];
		
	END_TRY;
}

/**/
- (char *) getCaption2
{
  int userLoguedId;
	
	userLoguedId = [[[UserManager getInstance] getUserLoggedIn] getUserId];
	
	// si el usuario a modificar es el usuario logueado no lo dejo
	if (userLoguedId != [[self getFormInstance] getUserId]){	
  	if ([self getFormMode] == JEditFormMode_VIEW) {
  		
  		if (!myIsEditable)
  			return NULL;
  		
  		return getResourceStringDef(RESID_UPDATE_KEY, myEditMessageString);
  	
  	} else // [self getFormMode] == JEditFormMode_EDIT
  		
  		return getResourceStringDef(RESID_SAVE_KEY, mySaveMessageString);
  }else
    return "";
  
}

@end

