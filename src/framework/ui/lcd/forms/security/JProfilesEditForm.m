#include "JProfilesEditForm.h"
#include "UserManager.h"
#include "util.h"
#include "MessageHandler.h"
#include "system/util/all.h"
#include "JMessageDialog.h"
#include "DAOExcepts.h"
#include "JProfilesSelectOperationsEditForm.h"
#include "SettingsExcepts.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation  JProfilesEditForm


/**/
- (void) onCreateForm
{
  id checkBoxTDO;
	id checkBoxUDP;

	[super onCreateForm];
	printd("JProfilesEditForm:onCreateForm\n");

	// Name
	myLabelName = [JLabel new];
	[myLabelName setCaption: getResourceStringDef(RESID_NAME, "Nombre:")];
	[self addFormComponent: myLabelName];

	myTextName = [JText new];
	[myTextName setWidth: 20];
	[myTextName setHeight: 1];
	[myTextName setMaxLen: 20];
	[self addFormComponent: myTextName];

  [self addFormNewPage];

	// Security Level
	myLabelSecurityLevel = [JLabel new];
	[myLabelSecurityLevel setCaption: getResourceStringDef(RESID_SECURITY_LEVEL, "Nivel Seguridad:")];
	[self addFormComponent: myLabelSecurityLevel];

	myComboSecurityLevel = [JCombo new];
	[myComboSecurityLevel setWidth: 20];
	[myComboSecurityLevel addString: getResourceStringDef(RESID_Profile_SECURITY_LEVEL_0, "Nivel 0")];
  [myComboSecurityLevel addString: getResourceStringDef(RESID_Profile_SECURITY_LEVEL_1, "Nivel 1")];
  [myComboSecurityLevel addString: getResourceStringDef(RESID_Profile_SECURITY_LEVEL_2, "Nivel 2")];
  [myComboSecurityLevel addString: getResourceStringDef(RESID_Profile_SECURITY_LEVEL_3, "Nivel 3")];
	[self addFormComponent: myComboSecurityLevel];

  [self addFormNewPage];

	// Time Delay Override
	myTimeDelayCheckBoxCollection = [Collection new];
  myTimeDelayCheckBoxList = [JCheckBoxList new];
  [myTimeDelayCheckBoxList setHeight: 3];

  checkBoxTDO = [JCheckBox new];
  [checkBoxTDO setCaption: getResourceStringDef(RESID_TIME_DELAY_OVERRIDE, "T. retardo overr")];
  [checkBoxTDO setCheckItem: 0];
  [myTimeDelayCheckBoxCollection add: checkBoxTDO];
	[myTimeDelayCheckBoxList addCheckBoxFromCollection: myTimeDelayCheckBoxCollection];
  [self addFormComponent: myTimeDelayCheckBoxList];	

  [self addFormNewPage];

	// Use Duress Password
	myUseDuressCheckBoxCollection = [Collection new];
  myUseDuressCheckBoxList = [JCheckBoxList new];
  [myUseDuressCheckBoxList setHeight: 3];	
	
  checkBoxUDP = [JCheckBox new];
  [checkBoxUDP setCaption: getResourceStringDef(RESID_USE_DURESS_PASSWORD_CHECK, "Usa clave panico")];
  [checkBoxUDP setCheckItem: 0];
  [myUseDuressCheckBoxCollection add: checkBoxUDP];
	[myUseDuressCheckBoxList addCheckBoxFromCollection: myUseDuressCheckBoxCollection];
	[self addFormComponent: myUseDuressCheckBoxList];

  [self addFormNewPage];

	// Profile (Father)
	myLabelProfile = [JLabel new];
	[myLabelProfile setCaption: getResourceStringDef(RESID_FATHER_PROFILE, "Perfil padre:")];
	[self addFormComponent: myLabelProfile];
	
	myComboProfile = [JCombo new];
	[myComboProfile setOnSelectAction: self action: "fatherProfile_onSelect"];
	[self addFormComponent: myComboProfile];

	[self setConfirmAcceptOperation: TRUE];

  [self fatherProfile_onSelect];
  	
}

/**/
- (void) fatherProfile_onSelect
{
  unsigned char SelOperations[15];

  SelOperations[0] = '\0';
  strcpy(SelOperations,"empty");
	memset(mySelectedOperations, 0, 14);
  [self setSelectedOperations: SelOperations];
}

/**/
- (void) onCancelForm: (id) anInstance
{
	printd("JProfileEditForm:onAcceptForm\n");

	assert(anInstance != NULL);

	if ([anInstance getProfileId] > 0)
		[anInstance restore];
}

/**/
- (void) onModelToView: (id) anInstance
{
	id profile = NULL;
  COLLECTION myC;
  id user;

	printd("JProfileEditForm:onModelToView\n");
	assert(anInstance != NULL);

	// guardo el ID del perfil
	myProfileId = [anInstance getProfileId];
	// Name
	[myTextName setText: [anInstance getProfileName]];
	// security level		
  [myComboSecurityLevel setSelectedIndex: [anInstance getSecurityLevel]];
	// Time Delay Override
	[[myTimeDelayCheckBoxCollection at: 0] setChecked: [anInstance getTimeDelayOverride]];
	// Use Duress Password
	[[myUseDuressCheckBoxCollection at: 0] setChecked: [anInstance getUseDuressPassword]];

  // Cuando estoy dando de ALTA traigo los perfiles a los que tiene acceso el usuario logueado
  // osea su perfil y los hijos de este
	if ([[myComboProfile getItems] size] == 0) {
		myC = [Collection new];
		if ([anInstance getProfileId] == 0) {
				user = [[UserManager getInstance] getUserLoggedIn];
				profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
				
				// cargo el perfil del usuario actual
				[myC add: profile];
				
				// cargo los perfiles hijo
				[[UserManager getInstance] getChildProfiles: [user getUProfileId] childs: myC];
		} else {
				// cuando estor EDITANDO o VISUALIZANDO traigo todos los perfiles en el combo
				myC = [[UserManager getInstance] getProfiles];
		}
  
		[myComboProfile clearAllItems];
		[myComboProfile addItemsFromCollection: myC];
	}

  // Father Profile
	if ([anInstance getFatherId] > 0) {
		profile = [[UserManager getInstance] getProfile: [anInstance getFatherId]];
    [myComboProfile setSelectedItem: profile];
	}

}

/**/
- (void) onChangeFormMode: (JEditFormMode) aNewMode
{
  [super onChangeFormMode: aNewMode];

  if (aNewMode == JEditFormMode_VIEW) {
    [myComboSecurityLevel setReadOnly: TRUE];
		[myComboProfile setReadOnly: TRUE];
  } else {
    [myComboSecurityLevel setReadOnly: myProfileId > 0];
		[myComboProfile setReadOnly: myProfileId > 0];
  }
}

/**/
- (char*) getCaptionX
{
	id user;
	id profile;

	if ([[self getFormInstance] getProfileId] != 1) {
		user = [[UserManager getInstance] getUserLoggedIn];
		profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
		if ([[self getFormInstance] getProfileId] != [profile getProfileId]) { 
			if ([self getFormMode] == JEditFormMode_VIEW)
				return getResourceStringDef(RESID_UPDATE_KEY, "modif.");
			else {
	
				if ([self getFormFocusedComponent] == myTextName)
					return getResourceStringDef(RESID_DELETE_KEY, "borrar");
	
				if ( ([self getFormFocusedComponent] == myTimeDelayCheckBoxList) ||
						([self getFormFocusedComponent] == myUseDuressCheckBoxList) )
					return getResourceStringDef(RESID_CHECK_OPTION, "marcar");
			}
		}
	}

	return NULL;
}

/*
 * Utilizo este menu para cambiar al estado de edicion.
 */
- (void) onMenuXButtonClick
{
	id user;
	id profile;
  
	if ([[self getFormInstance] getProfileId] != 1) {
		user = [[UserManager getInstance] getUserLoggedIn];
		profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
		if ([[self getFormInstance] getProfileId] != [profile getProfileId]) {
				
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

/**/
- (char*) getCaption1
{
    return getResourceStringDef(RESID_BACK_KEY, "atras");
}

/**/
- (char*) getCaption2
{
    return  getResourceStringDef(RESID_NEXT_KEY, "sig.");
}

/**/
- (void) onMenu1ButtonClick
{

  if ([self getFormFocusedComponent] != myTextName) {
    [self focusFormPreviousComponent];
		[self doChangeStatusBarCaptions];
    return;
  }

  [super onMenu1ButtonClick];
}


/**/
- (void) onMenu2ButtonClick
{
  id form;

	// valido que se ingrese un nombre antes de seguir avanzando
  if (strlen(trim([myTextName getText])) == 0) 
    THROW(NULL_PROFILE_NAME_EX);
  
  if ([self getFormFocusedComponent] != myComboProfile) {
    [self focusFormNextComponent];
    [self doChangeStatusBarCaptions];
    return;
  }

	// abro la pantalla de operaciones por perfil  
  form = [JProfilesSelectOperationsEditForm createForm: self];

	// seteo los valores seleccionados en el formulario actual
  [form setProfileName: [myTextName getText]];
  [form setSecurityLevel: [myComboSecurityLevel getSelectedIndex]];
  [form setFatherProfileId: [[myComboProfile getSelectedItem] getProfileId]];
  [form setTimeDelayOverride: [[myTimeDelayCheckBoxList getSelectedCheckBoxItem] isChecked]];
  [form setUseDuressPassword: [[myUseDuressCheckBoxList getSelectedCheckBoxItem] isChecked]];
	[form setSelectedOperations: [self getSelectedOperations]];

	TRY

		// traspaso el estado del formulario actual al formulario de oepraciones por perfil
    if ([self getFormMode] == JEditFormMode_VIEW)
      [form showFormToView: [self getFormInstance]];      
		else [form showFormToEdit: [self getFormInstance]];

		// cambio el estado del formulario actual solo si cambio el estado del formulario de oepraciones por perfil
    if ([self getFormMode] != [form getFormMode])
      [self doChangeFormMode: [form getFormMode]];
            
    [self setModalResult: [form getModalResult]];

		// guardo en memoria la lista de operaciones que trajo
    [self setSelectedOperations: [form getSelectedOperations]];
		myProfileId = [form getProfileId];

	FINALLY

		[form free];

	END_TRY	
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) anIsPressed
{

	if (!anIsPressed)
			return FALSE;

	if ((aKey == UserInterfaceDefs_KEY_DOWN) || (aKey == UserInterfaceDefs_KEY_UP))
		 return FALSE;

	return [super doKeyPressed: aKey isKeyPressed: anIsPressed];

}

/**/
- (void) setSelectedOperations: (unsigned char *) aValue { memcpy(mySelectedOperations, aValue, 14); }
- (unsigned char *) getSelectedOperations { return mySelectedOperations; }

@end

