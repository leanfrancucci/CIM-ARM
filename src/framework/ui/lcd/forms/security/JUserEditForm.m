#include "JUserEditForm.h"
#include "UserManager.h"
#include "util.h"
#include "MessageHandler.h"
#include "system/util/all.h"
#include "JMessageDialog.h"
#include "DAOExcepts.h"
#include "JExceptionForm.h"
#include "CimGeneralSettings.h"
#include "DallasDevThread.h"
#include "SwipeReaderThread.h"
#include "PrinterSpooler.h"
#include "JSystem.h"

#define printd(args...)// doLog(0,args)
//#define printd(args...)

@implementation  JUserEditForm

static char clearMessage[] = "clear";

/**/
- (void) onCreateForm
{
	char msgLang[20];

	[super onCreateForm];
	printd("JUserEditForm:onCreateForm\n");

	// User ID
	[self addLabelFromResource: RESID_USER_ID default: "ID Usuario:"];
	myTextUserId = [JText new];
  [myTextUserId setReadOnly: TRUE];
  [myTextUserId setEnabled: FALSE];

	[self addFormComponent: myTextUserId];

	[self addFormNewPage];

	// Name
	[self addLabelFromResource: RESID_NAME default: "Nombre:"];
	myTextName = [JText new];
	[myTextName setWidth: 20];
	[myTextName setMaxLen: 20];
	[myTextName setHeight: 1];

	[self addFormComponent: myTextName];

	[self addFormNewPage];

	// Surname
	[self addLabelFromResource: RESID_SURNAME default: "Apellido:"];
	myTextSurname = [JText new];
	[myTextSurname setWidth: 20];
	[myTextSurname setMaxLen: 20];
	[myTextSurname setHeight: 1];	

	[self addFormComponent: myTextSurname];

	[self addFormNewPage];

	// Profile
	[self addLabelFromResource: RESID_PROFILE default: "Perfil:"];
	myComboProfile = [JCombo new];
	[myComboProfile addItemsFromCollection: [[UserManager getInstance] getVisibleProfiles]];
	[myComboProfile setOnSelectAction: self action: "profile_onSelect"];
	[myComboProfile setSelectedIndex: 0];

	[self addFormComponent: myComboProfile];
	
	[self addFormNewPage];

	// Personal ID
	[self addLabelFromResource: RESID_USERNAME default: "Id Personal:"];
	myTextUserName = [JText new];
	[myTextUserName setWidth: 9];
	[myTextUserName setMaxLen: 9];	
	[myTextUserName setHeight: 1];
	// refresco el tipo de edit del login dependiendo del seteo actual
	if ([[CimGeneralSettings getInstance] getLoginOpMode] == KeyPadOperationMode_NUMERIC) {
		[myTextUserName setNumericMode: TRUE];
	} else {
		[myTextUserName setAlphaNumericLoginMode: TRUE];
  }

	[self addFormComponent: myTextUserName];

	[self addFormNewPage];

	// Password
	[self addLabelFromResource: RESID_PASSWORD default: "Clave:"];
	myTextPassword = [JText new];
	[myTextPassword setWidth: 8];
	[myTextPassword setPasswordMode: TRUE];
  [myTextPassword setNumericMode: TRUE];
  [myTextPassword setMaxLen: 8];

	[self addFormComponent: myTextPassword];

	[self addFormNewPage];

	// Confirm Password
	[self addLabelFromResource: RESID_CONFIRM_PASSWORD default: "Confirmacion Clave:"];
	myTextConfirmPassword = [JText new];
	[myTextConfirmPassword setWidth: 8];
	[myTextConfirmPassword setPasswordMode: TRUE];
  [myTextConfirmPassword setNumericMode: TRUE];
  [myTextConfirmPassword setMaxLen: 8];

	[self addFormComponent: myTextConfirmPassword];

	[self addFormNewPage];

	// Duress Password
	myLabelDuressPassword = [self addLabelFromResource: RESID_DURESS_PASSWORD default: "Clave de robo:"];
	myTextDuressPassword = [JText new];
	[myTextDuressPassword setWidth: 8];
	[myTextDuressPassword setPasswordMode: TRUE];
  [myTextDuressPassword setNumericMode: TRUE];
  [myTextDuressPassword setMaxLen: 8];

	[self addFormComponent: myTextDuressPassword];

	[self addFormNewPage];

	// Confirm Duress Password
	myLabelConfirmDuressPassword = [self addLabelFromResource: RESID_CONFIRM_DURESS_PASSWORD default: "Confirm Clave Robo:"];
	myTextConfirmDuressPassword = [JText new];
	[myTextConfirmDuressPassword setWidth: 8];
	[myTextConfirmDuressPassword setPasswordMode: TRUE];
  [myTextConfirmDuressPassword setNumericMode: TRUE];
  [myTextConfirmDuressPassword setMaxLen: 8];

	[self addFormComponent: myTextConfirmDuressPassword];

	[self addFormNewPage];

	// Bank account number
	[self addLabelFromResource: RESID_BANK_ACCOUNT_NUMBER default: "Nro cuenta bancaria:"];
	myTextBankAccountNumber = [JText new];
	[myTextBankAccountNumber setWidth: 20];  
  [myTextBankAccountNumber setMaxLen: 20];
  [myTextBankAccountNumber setHeight: 1];

	[self addFormComponent: myTextBankAccountNumber];
	
	[self addFormNewPage];
	
	// Login method
	[self addLabelFromResource: RESID_LOGIN_METHOD default: "Tipo login:"];
	myComboLoginMethod = [JCombo new];
  [myComboLoginMethod addString: getResourceStringDef(RESID_PERSONAL_ID_NUMBER, "ID PERSONAL")]; 
  [myComboLoginMethod addString: getResourceStringDef(RESID_DALLAS_KEY, "LLAVE DALLAS")]; 
	[myComboLoginMethod addString: getResourceStringDef(RESID_SWIPE_CARD_READER, "LECTOR TARJETA M")];
  //[myComboLoginMethod addString: getResourceStringDef(RESID_FINGER_PRINT, "DETECTOR HUELLA")];
  
	[self addFormComponent: myComboLoginMethod];

  [self addFormNewPage];

	// Idioma
	[self addLabelFromResource: RESID_LANGUAGE default: "Idioma:"];
	myComboLanguage = [JCombo new];
	sprintf(msgLang,"Espa%col",'\xF1');
	[myComboLanguage addString: msgLang];
	[myComboLanguage addString: "English"];
	sprintf(msgLang,"Fran%cais",'\xC7');
	[myComboLanguage addString: msgLang];

	[self addFormComponent: myComboLanguage];

	[self addFormNewPage];

	// Status
	[self addLabelFromResource: RESID_STATUS default: "Estado:"];
	myComboStatus = [JCombo new];
  [myComboStatus addString: getResourceStringDef(RESID_INACTIVE_STATUS, "INACTIVO")];
  [myComboStatus addString: getResourceStringDef(RESID_ACTIVE_STATUS, "ACTIVO")];
  [myComboStatus setSelectedIndex: 1];
  
	[self addFormComponent: myComboStatus];
  [self addFormNewPage];

	// PIN DINAMICO Modificacion SOLE
	/* Comentado lo de pines dinamicos por ahora
	[self addLabelFromResource: RESID_DYNAMIC_PIN default: "PIN Dinamico:"];
	myComboDynamicPin = [JCombo new];
  [myComboDynamicPin addString: getResourceStringDef(RESID_INACTIVE_STATUS, "INACTIVO")];
  [myComboDynamicPin addString: getResourceStringDef(RESID_ACTIVE_STATUS, "ACTIVO")];
  [myComboDynamicPin setSelectedIndex: 1];

	[self addFormComponent: myComboDynamicPin];
  [self addFormNewPage];
	*/

  // Dallas Key o Swipe Card Reader
	myLabelDallasKey = [JLabel new];
	if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_DALLAS_KEY) {
		if (strlen(getResourceStringDef(RESID_DALLAS_KEY_CAPTION, "Llave Dallas:")) > JComponent_MAX_WIDTH) {
			[myLabelDallasKey setHeight: 2];
			[myLabelDallasKey setWidth: 20];
			[myLabelDallasKey setWordWrap: TRUE];
		}
		[myLabelDallasKey setCaption: getResourceStringDef(RESID_DALLAS_KEY_CAPTION, "Llave Dallas:")];
	} else {
		if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_SWIPE_CARD_READER) {
			if (strlen(getResourceStringDef(RESID_SWIPE_CARD_KEY_CAPTION, "Tarjeta Magnetica:")) > JComponent_MAX_WIDTH) {
				[myLabelDallasKey setHeight: 2];
				[myLabelDallasKey setWidth: 20];
				[myLabelDallasKey setWordWrap: TRUE];
			}
			[myLabelDallasKey setCaption: getResourceStringDef(RESID_SWIPE_CARD_KEY_CAPTION, "Tarjeta Magnetica:")];
		}
	}

	if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_NONE)
		[myLabelDallasKey setVisible: FALSE];

	[self addFormComponent: myLabelDallasKey];
	
	myTextDallasKey = [JText new];
	[myTextDallasKey setWidth: 20];  
  [myTextDallasKey setMaxLen: 20];
  [myTextDallasKey setHeight: 1];
  [myTextDallasKey setReadOnly: TRUE];
	[myTextDallasKey setPasswordMode: TRUE];
	if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_NONE)
		[myTextDallasKey setVisible: FALSE];

	[self addFormComponent: myTextDallasKey];

	[self setConfirmAcceptOperation: TRUE];

	[self profile_onSelect];

}

/**/
- (void) profile_onSelect
{

	// habilito o deshabilito los campos de duress dependiendo del perfil seleccionado
	[myLabelDuressPassword setVisible: FALSE];
	[myTextDuressPassword setVisible: FALSE];
	[myLabelConfirmDuressPassword setVisible: FALSE];
	[myTextConfirmDuressPassword setVisible: FALSE];

	if ([[myComboProfile getSelectedItem] getUseDuressPassword]) {
		[myLabelDuressPassword setVisible: TRUE];
		[myTextDuressPassword setVisible: TRUE];
		[myLabelConfirmDuressPassword setVisible: TRUE];
		[myTextConfirmDuressPassword setVisible: TRUE];

		// si el perfil que tiene actualmente el usuario no usa duress entonces 
		// limpio los edits del duress para obligarlo a introducir nuevos valores
		if ( ([self getFormInstance]) && ([[self getFormInstance] getUserId] > 0) ) {
			if ( ([[self getFormInstance] getProfile]) && (![[[self getFormInstance] getProfile] getUseDuressPassword]) ) {
				[myTextDuressPassword setText: ""];
				[myTextConfirmDuressPassword setText: ""];
			}
		}
	}

	[self paintComponent];
}

/**/
- (void) onChangeFormMode: (JEditFormMode) aNewMode
{
  [super onChangeFormMode: aNewMode];
  if (aNewMode == JEditFormMode_VIEW) {
	
		if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_DALLAS_KEY) {
			[[DallasDevThread getInstance] setObserver: NULL];
			[[DallasDevThread getInstance] disable];
		} else
				if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_SWIPE_CARD_READER) {
					[[SwipeReaderThread getInstance] setObserver: NULL];
					[[SwipeReaderThread getInstance] disable];
				}
  
  } else {

		if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_DALLAS_KEY) {
			[[DallasDevThread getInstance] setObserver: self];
			[[DallasDevThread getInstance] enable];
		} else
				if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_SWIPE_CARD_READER) {
					[[SwipeReaderThread getInstance] setObserver: self];
					[[SwipeReaderThread getInstance] enable];
				}
  }
	
  [myTextDallasKey setReadOnly: TRUE];
  
}

/**/
- (void) onCancelForm: (id) anInstance
{
  printd("JUserEditForm:onCancelForm\n");

	assert(anInstance != NULL);

	if ([anInstance getUserId] > 0)
		[anInstance restore];

}

/**/
- (void) onModelToView: (id) anInstance
{
	id profile = NULL;
	char userIdStr[10];
	id p;
	id user;

	printd("JUserEditForm:onModelToView\n");
	
  assert(anInstance != NULL);

	// User ID
  userIdStr[0] = '\0';
  sprintf(userIdStr,"%d",[anInstance getUserId]);		
	if ([self getFormMode] == JEditFormMode_VIEW)
    [myTextUserId setText: userIdStr];
  else {
    if ((strlen(userIdStr) == 0) || (strcmp(userIdStr,"0") == 0))
       [myTextUserId setText: getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE")];
    else
       [myTextUserId setText: userIdStr];
  }
  	
	// Name
	[myTextName setText: [anInstance getUName]];
	
	// Surname
	[myTextSurname setText: [anInstance getUSurname]];

	// User name
	[myTextUserName setText: [anInstance getLoginName]];

	// En el caso que el pin no sea requerido actualmente lo pongo en blanco por si despues
	// cambia
	if ([anInstance getUserId] > 0 && ![anInstance isPinRequired]) {

		[myTextPassword setText: ""];
		[myTextConfirmPassword setText: ""];	
		[myTextDuressPassword setText: ""];
		[myTextConfirmDuressPassword setText: ""];

	} else {
	
		[myTextPassword setText: [anInstance getPassword]];
		[myTextConfirmPassword setText: [anInstance getPassword]];	
		[myTextDuressPassword setText: [anInstance getDuressPassword]];
		[myTextConfirmDuressPassword setText: [anInstance getDuressPassword]];
	}

	// BankAccountNumber
	[myTextBankAccountNumber setText: [anInstance getBankAccountNumber]];	
	
  // Profile
	if ([anInstance getUProfileId] > 0) {
		profile = [[UserManager getInstance] getProfile: [anInstance getUProfileId]];
		[myComboProfile setSelectedItem: profile];
		[self profile_onSelect];
	}
	
  // Login Method
	[myComboLoginMethod setSelectedIndex: [anInstance getLoginMethod] - 1];

  // Status
  if([anInstance isActive])
	  [myComboStatus setSelectedIndex: 1];
	else
	  [myComboStatus setSelectedIndex: 0];

  // Dynamic PIN
/**
  if([anInstance getUsesDynamicPin])
	  [myComboDynamicPin setSelectedIndex: 1];
	else
	  [myComboDynamicPin setSelectedIndex: 0];
    */
	// Idioma
	[myComboLanguage setSelectedIndex: [anInstance getLanguage] - 1];
	myOriginalLanguage = [anInstance getLanguage];

	// el combo de estados se habilita solo si tiene el permiso de cambio de estado
  user = [[UserManager getInstance] getUserLoggedIn];
  p = [[UserManager getInstance] getProfile: [user getUProfileId]];      	
  [myComboStatus setEnabled: [p hasPermission: USER_STATE_OP]];

  // Dallas Key
  [myTextDallasKey setText: [anInstance getKey]];

	// si estoy parado en en duress o confirm del duress y cancelan la operacion
	// debo ver si los campos duress y confirm duress estan visibles o no (dependiendo del perfil)
	// en cuyo caso hago foco en el componente anterior (confirm password)
  if ( ([self getFormFocusedComponent] == myTextDuressPassword && ![myTextDuressPassword isVisible]) ||
			 ([self getFormFocusedComponent] == myTextConfirmDuressPassword  && ![myTextConfirmDuressPassword isVisible]) ) {
    [self focusFormComponent: myTextConfirmPassword];
  }

}

/**
 * Si esta en modo VIEW entra en modo EDIT.
 * Si esta en modo EDIT, acepta el formulario y entra en modo VIEW
 */
- (void) onMenu2ButtonClick
{
	id profile;
	id user;
	
	[self lockWindowsUpdate];
	
	TRY

			/* Paso a modo edicion ... */
			if (myFormMode == JEditFormMode_VIEW && myIsEditable) {
			
				[self doChangeFormMode: JEditFormMode_EDIT];
				
				if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_DALLAS_KEY) {
        	[[DallasDevThread getInstance] setObserver: self];
        	[[DallasDevThread getInstance] enable];
				} else
						if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_SWIPE_CARD_READER) {
							[[SwipeReaderThread getInstance] setObserver: self];
							[[SwipeReaderThread getInstance] enable];
						}

        // si es edicion deshabilito el edit de nombre y apellido
        // cuando estoy insertando los habilito
        if ( strcmp([myTextUserId getText], getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE")) == 0){
      	  [myTextName setReadOnly: FALSE];
      	  [myTextSurname setReadOnly: FALSE];
      	  [myTextUserName setReadOnly: FALSE];      	  
      	}else{
      	  [myTextName setReadOnly: TRUE];
      	  [myTextSurname setReadOnly: TRUE];
      	  [myTextUserName setReadOnly: TRUE];
      	}
      	
      	// el combo de estados se habilita solo si tiene el permiso de cambio de estado
        user = [[UserManager getInstance] getUserLoggedIn];
        profile = [[UserManager getInstance] getProfile: [user getUProfileId]];      	
        //[myComboStatus setReadOnly: (![profile hasPermission: USER_STATE_OP])];
        [myComboStatus setEnabled: [profile hasPermission: USER_STATE_OP]];      	
								
			} else { 	/* Valida, acepta y pasa a modo view */
			
				if (myFormMode == JEditFormMode_EDIT) {
 					if ([self doAcceptForm]) {
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
- (void) onViewToModel: (id) anInstance
{
	id userLoged = NULL;

	printd("JUserEditForm:onViewToModel\n");

	assert(anInstance != NULL);

	// Name
	[anInstance setUName: [myTextName getText]];

	// Surname
	[anInstance setUSurname: [myTextSurname getText]];

	// User name
	[anInstance setLoginName: [myTextUserName getText]];

	// Password
	[anInstance setPassword: [myTextPassword getText]];

	// DuressPassword
	[anInstance setDuressPassword: [myTextDuressPassword getText]];

	// BankAccountNumber
	[anInstance setBankAccountNumber: [myTextBankAccountNumber getText]];
	
  // Profile id
  [anInstance setUProfileId: [[myComboProfile getSelectedItem] getProfileId]];

  // Login Method
  [anInstance setLoginMethod: [myComboLoginMethod getSelectedIndex] + 1];
  
  // si el estado anterior era inactivo y luego lo activo debo actualizar la fecha de 
  // ultimo loguin para evitar que se desactive automaticamente por tener fecha vencida.
  if (![anInstance isActive])
    if ([myComboStatus getSelectedIndex] == 1) 
      [anInstance setLastLoginDateTime: [SystemTime getLocalTime]];
  
  // Status
  [anInstance setActive: ([myComboStatus getSelectedIndex] == 1)];

  // Dynamic PIN
//  [anInstance setUsesDynamicPin: ([myComboDynamicPin getSelectedIndex] == 1)];
  
	// si cambio el estado a inactivo, le activo el password temporal
  if ([myComboStatus getSelectedIndex] != 1)
    [anInstance setIsTemporaryPassword: TRUE];

	// si cambio el password de otro usuario, le activo el password temporal
	userLoged = [[UserManager getInstance] getUserLoggedIn];
	if ((userLoged) && ([userLoged getUserId] != [anInstance getUserId])) {
		if (strcmp([anInstance getPassword],FICTICIOUS_PASSWORD) != 0)
			[anInstance setIsTemporaryPassword: TRUE];
	}

	// Idioma	
	[anInstance setLanguage: [myComboLanguage getSelectedIndex] + 1];
  
  // Dallas Key
  [anInstance setKey: [myTextDallasKey getText]];
}


/**/
- (void) onAcceptForm: (id) anInstance
{
  volatile JFORM processForm;
	id userLoged = NULL;
	
	printd("JUserEditForm:onAcceptForm\n");

	assert(anInstance != NULL);

  if (strlen([anInstance getUName]) == 0) 
    THROW(DAO_USER_NAME_NULLED_EX);
         
	if (strlen([anInstance getUSurname]) == 0) 
    THROW(DAO_SURNAME_NULLED_EX);
			 
  if (strlen([anInstance getLoginName]) == 0) 
    THROW(DAO_LOGIN_NAME_NULLED_EX);

	// Valida los Datos del PIN y Duress
	if ([anInstance isPinRequired]) {
	
		// valido que la password no sea vacia
		if (strlen([anInstance getPassword]) == 0) 
			THROW(DAO_NULL_PIN_EX);
	
		if (strlen([anInstance getPassword]) < [[CimGeneralSettings getInstance] getPinLenght])
			THROW(DAO_INVALID_PASSWORD_EX);
	
		// valido la password con su confirmacion
		if (strcmp([anInstance getPassword], [myTextConfirmPassword getText]) != 0) 
			THROW(RESID_INVALID_CONFIRM_PASSWORD);
	
		// el control de duress password lo hago solo si el perfil del usuario usa duress
		if ([[anInstance getProfile] getUseDuressPassword]) {			

			// valido que la duress password no sea vacia
			if (strlen([anInstance getDuressPassword]) == 0) 
				THROW(DAO_NULL_DURESS_PIN_EX);
	
			// valido que el duress password tenga la longitud correcta
			if (strlen([anInstance getDuressPassword]) < [[CimGeneralSettings getInstance] getPinLenght])
				THROW(DAO_INVALID_DURESS_PASSWORD_EX);
		
			// valido que la duress password con su confirmacion sean iguales
			if (strcmp([anInstance getDuressPassword], [myTextConfirmDuressPassword getText]) != 0) 
				THROW(RESID_INVALID_CONFIRM_DURESS_PASSWORD);
			
			// valido que la nueva password sea distinta a la nueva clave de robo
			if (strcmp([myTextPassword getText], [myTextDuressPassword getText]) == 0) 
				THROW(RESID_EQUALS_PASSWORDS);
		
			// valido que si la password cambio, tambien haya cambiado el duress
			if (strcmp([anInstance getPassword],FICTICIOUS_PASSWORD) != 0) {
				if (strcmp([anInstance getDuressPassword],FICTICIOUS_DURESS_PASSWORD) == 0)
					THROW(RESID_MUST_CHANGE_DURESS_EX);
			}
		}

	}
    
	if (![anInstance isDallasKeyRequired]) {
		[anInstance setKey: ""];
	}
  
  TRY
    processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];
  
    // Graba el usuario
    [anInstance applyChanges];

		if ([anInstance getLanguage] != myOriginalLanguage) {
			// refresco el menu solo si el usuario logueado es el mismo que estoy actualizando
			// es decir que un usuario actualiza su propio idioma
			userLoged = [[UserManager getInstance] getUserLoggedIn];
			if ((userLoged) && ([userLoged getUserId] == [anInstance getUserId])) {
				[[MessageHandler getInstance] setCurrentLanguage: [anInstance getLanguage]];
				[[InputKeyboardManager getInstance] setCurrentLanguage: [anInstance getLanguage]];
				[[PrinterSpooler getInstance] setReportPathByLanguage: [anInstance getLanguage]];
				[[JSystem getInstance] onRefreshMenu];
			}
		}
	
    [processForm closeProcessForm];
    [processForm free];	

		if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_DALLAS_KEY) {
			[[DallasDevThread getInstance] setObserver: NULL];
			[[DallasDevThread getInstance] disable];
		} else
				if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_SWIPE_CARD_READER) {
					[[SwipeReaderThread getInstance] setObserver: NULL];
					[[SwipeReaderThread getInstance] disable];
				}
		
  
    [self closeForm];
  
  CATCH
  
    [processForm closeProcessForm];
    [processForm free];
    RETHROW();
        
  END_TRY
}

/**/
- (void) onExternalLoginKey: (char *) aKeyNumber
{
 // doLog(0,"JUserEditForm -> onExternalLoginKey\n");
  [myTextDallasKey setText: aKeyNumber];

	[self paintComponent];
}

/**/
- (void) onMenuXButtonClick
{
	if ([self getFormMode] == JEditFormMode_EDIT && [self getFormFocusedComponent] == myTextDallasKey) {
		[myTextDallasKey setPasswordMode: FALSE];
    [myTextDallasKey setText: "                    "];
    [myTextDallasKey paintComponent];
    [myTextDallasKey setText: ""];
		[myTextDallasKey setPasswordMode: TRUE];
  } else {
    [super onMenuXButtonClick];
  }
}

/**/
- (char *) getCaptionX
{
	if ([self getFormMode] == JEditFormMode_EDIT && [self getFormFocusedComponent] == myTextDallasKey) {
    return getResourceStringDef(RESID_CLEAR, clearMessage);
  }
  return [super getCaptionX];
}

@end

