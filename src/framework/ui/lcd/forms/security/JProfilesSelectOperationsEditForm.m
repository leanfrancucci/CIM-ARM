#include "JProfilesSelectOperationsEditForm.h"
#include "UserManager.h"
#include "util.h"
#include "Operation.h"
#include "MessageHandler.h"
#include "system/util/all.h"
#include "Operation.h"
#include "Collection.h"
#include "JExceptionForm.h"
#include "JCheckBox.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation  JProfilesSelectOperationsEditForm

/**/
- (void) onCreateForm
{  
  [super onCreateForm];
  
  mySelectAllCheckBoxCollection = [Collection new];
  myOperationsCheckBoxCollection = [Collection new];
	printd("JProfilesSelectOperationsEditForm:onCreateForm\n");
	
	[self setConfirmAcceptOperation: TRUE];

}

/**/
- (void) onOpenForm
{
  id operation;
  id profile;
  int i;
  int checkedCount;
  id checkBox;
  BOOL checked;
  BOOL hayDatos;
  unsigned char SelOperations[15];
  unsigned char myOperationsList[15];
	
  myCheckBoxList = [JCheckBoxList new];
  [myCheckBoxList setHeight: 3];	
	
  checkBox = [JCheckBox new];
  [checkBox setCaption: getResourceStringDef(RESID_ALL_OPERATIONS, "Todas")];
  [checkBox setCheckItem: 99];
  [mySelectAllCheckBoxCollection add: checkBox];
  [myCheckBoxList addCheckBoxFromCollection: mySelectAllCheckBoxCollection];
  
  // traigo el perfil padre
  profile = [[UserManager getInstance] getProfile: myFatherProfileId];
  memset(myOperationsList, 0, 14);
  // cargo las operaciones del padre
  memcpy(myOperationsList, [profile getOperationsList], 14);
  for (i=1; i <= OPERATION_COUNT; ++i) {
		// si la operacion esta activa
		if (getbit(myOperationsList, i) == 1) {

			operation = [[UserManager getInstance] getOperation: i];

			// si el perfil tiene nivel de seguridad 0 entonces debo ocultar ciertas operaciones:
			// door acces / door override / add-edit user / delete user / doors por usuario
			if ( (mySecurityLevel == SecurityLevel_0) && 
					 (([operation getOperationId] == OPEN_DOOR_OP) || 
					  ([operation getOperationId] == OVERRIDE_DOOR_OP) ||
						([operation getOperationId] == DOORS_BY_USER_OP) ||
						([operation getOperationId] == DELETE_USER_OP) ||
						([operation getOperationId] == USERS_ADMINISTRATION_OP)) ) continue;

			checkBox = [JCheckBox new];
			[checkBox setCaption: [operation str]];
			[checkBox setCheckItem: operation];
			[myOperationsCheckBoxCollection add: checkBox];
		}
  }
  
  [myCheckBoxList addCheckBoxFromCollection: myOperationsCheckBoxCollection];
  
  if ([self getFormMode] == JEditFormMode_VIEW)
    [myCheckBoxList setReadOnly: TRUE];
  else
    [myCheckBoxList setReadOnly: FALSE];
    
  [self addFormComponent: myCheckBoxList];

  // si es la primera vez que entra hay que limpiar la lista en memoria de operaciones
  hayDatos = TRUE;
  if (strcmp([self getSelectedOperations],"empty") == 0){
    memset(SelOperations, 0, 14);
    [self setSelectedOperations: SelOperations];
    hayDatos = FALSE;
  }

	//****** marco las opciones que estan chequeadas ********
	
  // traigo las operaciones del perfil que estoy editando
  memset(myOperationsList, 0, 14);
  // cargo las operaciones
  memcpy(myOperationsList, [[self getFormInstance] getOperationsList], 14);
	
  checkedCount = 0;
  for (i = 0; i < [myOperationsCheckBoxCollection size]; ++i) {
    checked = FALSE;
    
    operation = [[myOperationsCheckBoxCollection at: i] getCheckItem];
                      
    if (!hayDatos){ // si es la primera vez inicializo la variable en memoria con las operaciones
      if (getbit(myOperationsList, [operation getOperationId]) == 1){
          checked = TRUE;
          setbit([self getSelectedOperations], [operation getOperationId], 1);
          checkedCount++;
      }else
          setbit([self getSelectedOperations], [operation getOperationId], 0);
    }else{ // tilizo las operaciones que estan en memoria para no perder lo que se selecciono
      if (getbit([self getSelectedOperations], [operation getOperationId]) == 1){
        checkedCount++;
        checked = TRUE;
      }
    }
    
    [[myOperationsCheckBoxCollection at: i] setChecked: checked];
  }
  
  // si estan todas las opciones chequeadas marco la opcion ALL
  if (checkedCount == [myOperationsCheckBoxCollection size])
    [[mySelectAllCheckBoxCollection at: 0] setChecked: TRUE];
  else
    [[mySelectAllCheckBoxCollection at: 0] setChecked: FALSE];  
}

/**/
- (void) onModelToView: (id) anInstance
{
	int i;
  BOOL checked;
  unsigned char myOperationsList[15];
  id operation;
  
  printd("JProfilesSelectOperationsEditForm:onModelToView\n");

	assert(anInstance != NULL);

  // traigo las opedaciones del perfil que estoy editando
  memset(myOperationsList, 0, 14);
  // cargo las operaciones
  memcpy(myOperationsList, [anInstance getOperationsList], 14);

  for (i = 0; i < [myOperationsCheckBoxCollection size]; ++i) {
    checked = FALSE;
        
    operation = [[myOperationsCheckBoxCollection at: i] getCheckItem];
    
    if (getbit(myOperationsList, [operation getOperationId]) == 1)
      checked = TRUE;
              
    [[myOperationsCheckBoxCollection at: i] setChecked: checked];
  }
}


/**/
- (void) onAcceptForm: (id) anInstance
{
  int i;
  OPERATION op;
  int count;
  unsigned char myOperationsList[15];
  JFORM processForm;
	int lastProfileId;
  
  printd("JProfilesSelectOperationsEditForm:onAcceptForm\n");
	assert(anInstance != NULL);

  memset(myOperationsList, 0, 14);
  count = 0;
  for (i = 0; i < [myOperationsCheckBoxCollection size]; ++i) {
    
    op = [[myOperationsCheckBoxCollection at: i] getCheckItem];
    
    if ([[myOperationsCheckBoxCollection at: i] isChecked]){
      setbit(myOperationsList, [op getOperationId], 1);
      count++;
    }else{
      setbit(myOperationsList, [op getOperationId], 0);
    }
	}
	
	// valido que almenos se haya seleccionado un permiso
  if (count == 0)
    THROW(RESID_OPERATION_NULL);
  
  TRY
    processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];

		lastProfileId = [anInstance getProfileId];
    // seteo los valores
    [anInstance setProfileName: myProfileName];
		[anInstance setSecurityLevel: mySecurityLevel];
    [anInstance setFatherId: myFatherProfileId];
    [anInstance setTimeDelayOverride: myTimeDelayOverride];
		[anInstance setUseDuressPassword: myUseDuressPassword];
    [anInstance setOperationsList: myOperationsList];

    // aplico los cambios
    [anInstance applyChanges];

		myProfileId = [anInstance getProfileId];

    // agrego el profile a la lista (solo si fue dado de alta)
		if (lastProfileId == 0) {
    	[[UserManager getInstance] addProfileToCollection: anInstance];
		} else {
    	// elimino de sus hijos las operaciones eliminadas (solo en la edision)
    	[[UserManager getInstance] deactivateOpByChildrenProfile: [anInstance getProfileId] operationsList: myOperationsList];
		}
  
    // limpio la variable
    memset([self getSelectedOperations], 0, 14);
	
    // tildo o destildo la opcion ALL
    if ([myOperationsCheckBoxCollection size] == count)
      [[mySelectAllCheckBoxCollection at: 0] setChecked: TRUE];
    else
      [[mySelectAllCheckBoxCollection at: 0] setChecked: FALSE];	
	
    [self setModalResult: JFormModalResult_OK];

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
	snprintf(aMessage, JCustomForm_MAX_MESSAGE_SIZE, getResourceStringDef(RESID_SAVE_PROFILE_QUESTION, "Grabar configuracion del perfil?"));
	return aMessage;
}

/**/
- (char *) getCaptionX
{
 id user;
 id profile;

 if ([[self getFormInstance] getProfileId] != 1){
  user = [[UserManager getInstance] getUserLoggedIn];
  profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
  if ([[self getFormInstance] getProfileId] != [profile getProfileId]){
 	  if ([self getFormMode] == JEditFormMode_VIEW)
      return getResourceStringDef(RESID_UPDATE_KEY, "modif.");
    else
      return getResourceStringDef(RESID_CHECK_OPTION, "marcar");
  }
 }

	return NULL; 
}


/**/
- (char*) getCaption1
{
    return getResourceStringDef(RESID_BACK_KEY, "atras");
}

/**
 * Si esta en modo VIEW cierra el form.
 */
- (void) onMenu1ButtonClick
{	
	int i;
	id operation;
	
  [self lockWindowsUpdate];
			
	TRY
	
		// almaceno en memoria las operaciones para no perderlas
		memset([self getSelectedOperations], 0, 14);
		for (i = 0; i < [myOperationsCheckBoxCollection size]; ++i) {
			
			operation = [[myOperationsCheckBoxCollection at: i] getCheckItem];
			
			if ([[myOperationsCheckBoxCollection at: i] isChecked]){
				setbit([self getSelectedOperations], [operation getOperationId], 1);
			}
		}
		
		if ([self getFormMode] == JEditFormMode_VIEW)
			[self setModalResult: JFormModalResult_OK];
			
		[self closeForm];

	FINALLY

		[self unlockWindowsUpdate];

	END_TRY;
}

/**/
- (char*) getCaption2
{
	if ([self getFormMode] == JEditFormMode_VIEW)
    return "";
  else
    return getResourceStringDef(RESID_SAVE_KEY, "grabar");
}

- (void) onMenu2ButtonClick
{
	[self lockWindowsUpdate];
	
	TRY

		if (myFormMode == JEditFormMode_VIEW && myIsEditable) {
			// mo hago nada								
		} else { 	/* Valida, acepta y pasa a modo view */
			if (myFormMode == JEditFormMode_EDIT) {
				if ([self doAcceptForm])
					[self doChangeFormMode: JEditFormMode_VIEW];
			}				
		}

	FINALLY

		[self unlockWindowsUpdate];
		[self sendPaintMessage];

	END_TRY;
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) anIsPressed
{
	if (!anIsPressed)
			return FALSE;

	/* La envia la tecla al scroll panel para que la maneje a ver si la quiere procesar */
	if ([myScrollPanel processKey: aKey isKeyPressed: anIsPressed]) {
		
		if  (aKey == JComponent_TAB || aKey == JComponent_SHIFT_TAB || aKey == UserInterfaceDefs_KEY_MENU_1 ||
				 aKey == UserInterfaceDefs_KEY_MENU_X || aKey == JComponent_CTRL_TAB || aKey == UserInterfaceDefs_KEY_MENU_2)
			[self doChangeStatusBarCaptions];
		
		/* Esto lo hago porque si no el cursor se redibuja en cualquier lado */
		[myScrollPanel drawCursor];
	}

	switch (aKey) {
		case UserInterfaceDefs_KEY_MENU_1:
			[self doMenu1ButtonClick];
			return TRUE;

		case UserInterfaceDefs_KEY_MENU_X:
			[self doMenuXButtonClick];
			return TRUE;

		case UserInterfaceDefs_KEY_MENU_2:
			[self doMenu2ButtonClick];
			return TRUE;
			
		case JComponent_CTRL_TAB:				
			[self doViewButtonClick];
			return TRUE;								

		case UserInterfaceDefs_KEY_RIGHT:				
			[self advancePaper];
			return TRUE;				
	}
	
	return FALSE;
}

- (void) onMenuXButtonClick
{
  int i;
  BOOL checked;
  id user;
  id profile;
  id operation;
  
  if ([self getFormMode] == JEditFormMode_EDIT){

    if ([[myCheckBoxList getSelectedCheckBoxItem] getCheckItem] == 99){
      checked = ([[myCheckBoxList getSelectedCheckBoxItem] isChecked]);
        // limpio la variable
      memset([self getSelectedOperations], 0, 14); 
      for (i = 0; i < [myOperationsCheckBoxCollection size]; ++i) {
        if (checked){
          operation = [[myOperationsCheckBoxCollection at: i] getCheckItem];
          setbit([self getSelectedOperations], [operation getOperationId], 1);
        }
                            
        [[myOperationsCheckBoxCollection at: i] setChecked: checked];
      }
      [self sendPaintMessage];
    }
    
  }else{
    
    if ([[self getFormInstance] getProfileId] != 1){
      user = [[UserManager getInstance] getUserLoggedIn];
      profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
      if ([[self getFormInstance] getProfileId] != [profile getProfileId]){    		
      	[self lockWindowsUpdate];
      	
      	TRY
      			/* Paso a modo edicion ... */
      			if (myFormMode == JEditFormMode_VIEW && myIsEditable)
      				[self doChangeFormMode: JEditFormMode_EDIT];
      		
      	FINALLY
            [self unlockWindowsUpdate];
      			[self sendPaintMessage];
      	END_TRY;
    	}
     }
     
  }
}

- (void) setProfileName: (char*) aValue { strcpy(myProfileName, aValue); }
- (void) setFatherProfileId: (int) aValue { myFatherProfileId = aValue; }
- (void) setSelectedOperations: (unsigned char *) aValue { memcpy(mySelectedOperations, aValue, 14); }
- (unsigned char *) getSelectedOperations { return mySelectedOperations; }
- (void) setTimeDelayOverride: (BOOL) aValue { myTimeDelayOverride = aValue; }
- (void) setUseDuressPassword: (BOOL) aValue { myUseDuressPassword = aValue; }
- (void) setSecurityLevel: (int) aValue { mySecurityLevel = aValue; }
- (int) getProfileId { return myProfileId; }

@end

