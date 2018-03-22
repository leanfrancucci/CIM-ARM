#include "JUserLoginForm.h"
#include "util.h"
#include "UserManager.h"
#include "JMessageDialog.h"
#include "MessageHandler.h"
#include "JSimpleTimerLockForm.h"
#include "CimGeneralSettings.h"
#include "Audit.h"
#include "Event.h"
#include "JSystem.h"
#include "JInstaDropForm.h"
#include "SettingsExcepts.h"
#include "CimManager.h"
#include "UICimUtils.h"
#include "JExceptionForm.h"
#include "JForceAdminPasswForm.h"
#include "CommercialStateMgr.h" 
#include "ReportXMLConstructor.h"
#include "PrinterSpooler.h"
#include "DallasDevThread.h"
#include "SwipeReaderThread.h"
#include "JReadDallasKeyForm.h"
#include "TelesupervisionManager.h"
#include "TelesupDefs.h"
#include "TelesupScheduler.h"

#define printd(args...) //doLog(0,args)
//#define printd(args...)

#define JUserMessage_DALLAS_KEY_READ    999888

#define DALLAS_KEY_TIMEOUT							(15 * 1000)

@implementation  JUserLoginForm


/**/
- (void) onCreateForm
{

	[super onCreateForm];

	processForm = NULL;
	myDallasKeyForm = NULL;
  myDallasKeys = [Collection new];
  myMutex = [OMutex new];
  
	myTimer = [OTimer new];
	[myTimer initTimer: ONE_SHOT period: DALLAS_KEY_TIMEOUT object: self callback: "clearDallasKey"];
	myValidateLogin = TRUE;
	myPersonalId[0] = '\0';
    myPassword[0] = '\0';
	myUser = NULL;
    myCantLoginFails = 0;
	forcePasswKey = 0;
	
	// Label Nombre usuario
	myLabelUserName = [JLabel new];
	[myLabelUserName setCaption: getResourceStringDef(RESID_USER, "ID Personal:")];
	[myLabelUserName setAutoSize: FALSE];

	[myLabelUserName setWidth: 15];
	[self addFormComponent: myLabelUserName];
	
	[self addFormEol];

	myTextUserName = [JText new];
	[myTextUserName setWidth: 9];
	[myTextUserName setHeight: 1];	
	[myTextUserName setMaxLen: 9];
	[myTextUserName setPasswordMode: FALSE];
    
	if ([[CimGeneralSettings getInstance] getLoginOpMode] == KeyPadOperationMode_NUMERIC) {
		[myTextUserName setNumericMode: TRUE];
		[myTextUserName setAlphaNumericLoginMode: FALSE];
	} else {
		[myTextUserName setNumericMode: FALSE];
		[myTextUserName setAlphaNumericLoginMode: TRUE];
  }
	[self addFormComponent: myTextUserName];	
				
	[self addFormEol];			
				
	// Label Contrasena
	myLabelUserPassword = [JLabel new];
	[myLabelUserPassword setCaption: getResourceStringDef(RESID_PIN, "Clave:")];
	[myLabelUserPassword setAutoSize: FALSE];
	[myLabelUserPassword setWidth: strlen(getResourceStringDef(RESID_PIN, "Clave:"))];
    
	[self addFormComponent: myLabelUserPassword];
				
	//Text Contrasena
	myTextUserPassword = [JText new];
	[myTextUserPassword setWidth: 8];
	[myTextUserPassword setHeight: 1];	
	[myTextUserPassword setMaxLen: 8];
	[myTextUserPassword setPasswordMode: TRUE];
	[myTextUserPassword setNumericMode: TRUE];
    
	[self addFormComponent: myTextUserPassword];
	
	// por defecto loguea al usuario
	myDoLog = TRUE;
	myCanGoBack = FALSE;  
    

}

/**/
- (void) onActivateForm
{
	myUser = NULL;
	
	// por defecto loguea al usuario
	myDoLog = TRUE;
  
}

/**/
- (void) onCloseForm
{
  [super onCloseForm];
	
	if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_DALLAS_KEY) {
		[[DallasDevThread getInstance] setObserver: NULL];
		[[DallasDevThread getInstance] disable];
	} else
			if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_SWIPE_CARD_READER) {
				[[SwipeReaderThread getInstance] setObserver: NULL];
				[[SwipeReaderThread getInstance] disable];
			}

  if (processForm) {
  	[processForm closeProcessForm];
		[processForm free];
		processForm = NULL;
  }
}

/**/
- (BOOL) doProcessMessage: (JEvent *) anEvent
{

	if (anEvent->evtid == JUserMessage_DALLAS_KEY_READ) {

		[myTimer start];
  
        [self doLogFormUser];
    
		return TRUE;
  } else {
    return [super doProcessMessage: anEvent];
  }
}

/**/
- (void) clearDallasKey
{
  [myMutex lock];
  [myDallasKeys freePointers];
  [myMutex unLock];

  if (myDallasKeyForm) [myDallasKeyForm closeForm];
}

/**/
- (void) onExternalLoginKey: (char *) aKeyNumber
{
  JEvent evt;

//  doLog(0,"JUserLoginForm -> onExternalLoginKey\n");
  
  [myMutex lock];
  [myDallasKeys freePointers];
  [myDallasKeys add: strdup(aKeyNumber)];
  [myMutex unLock];

  if (myDallasKeyForm) {

    [myDallasKeyForm closeForm];

  } else {

    // Encolo un evento para que esto se no se ejecute con el hilo de la Dallas sino con el hilo de la interfaz
    
    evt.evtid = JUserMessage_DALLAS_KEY_READ;
    [myEventQueue putJEvent: &evt];

  }

}

/**/
- (void) doLogFormUser
{			        
  int userId;  
  char buf[100];
  volatile BOOL tryAgain = TRUE;
  int excode = 0;
	USER user = NULL;
	SecurityLevel secLevel;
 	id telesup;

  while (tryAgain) {

    TRY

      excode = 0;
      
      tryAgain = FALSE;

			// indico que se comenzo a realizar el proceso de login
			[[UserManager getInstance] setLoginInProgress: TRUE];

      processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];
      myIsActive = TRUE;
      // loguea al usuario si myDoLog esta en TRUE. En caso contrario lo valida pero no lo loguea.
      [myMutex lock];

      if (myDoLog) {
				telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: HOYTS_BRIDGE_TSUP_ID];
				if (telesup) {

					if ([[TelesupScheduler getInstance] inTelesup]) {		
						THROW(RESID_TELESUP_IN_PROGRESS);
					}

	        userId = [[UserManager getInstance] logInHoytsUser: [myTextUserName getText] password: [myTextUserPassword getText] telesup: telesup dallasKeys: myDallasKeys];
				} else {
	        userId = [[UserManager getInstance] logInUser: [myTextUserName getText] password: [myTextUserPassword getText] dallasKeys: myDallasKeys];
				}
				
				//doLog(0,"userId loggedIn = %d\n", userId);

				myUser = [[UserManager getInstance] getUser: userId];
				secLevel = [[[UserManager getInstance] getProfile: [myUser getUProfileId]] getSecurityLevel];

				// si aun no se han creado los usuarios PIMS y Override intento crearlo porque ya se logueo alguien
				// excepto que tenga nivel 0 el usuario actual
				if (userId != 0 && strcasecmp([[myUser getProfile] getProfileName], "HOYTS") != 0) {
					if (secLevel != SecurityLevel_0) {
						// si tiene nivel 0 no puedo crear los usuarios especiales ya que al no ingresar la 
						// password no puedo realizar operaciones contra la placa que requieran la utilizacion
						// de la misma
						[[UserManager getInstance] createSpecialUsers];
					}
				}
		
      } else {
        userId = [[UserManager getInstance] validateUser: [myTextUserName getText] password: [myTextUserPassword getText] dallasKeys: myDallasKeys];
				myUser = [[UserManager getInstance] getUser: userId];
			}

      [myMutex unLock];

			[myTimer stop];

      // como se logro loguear inicializo el contador de logueos fallidos
      myCantLoginFails = 0;
    
      // Limpio los edits y refresco los labels
      [myTextUserName setText: ""];
      [myTextUserPassword setText: ""];
      [self focusFormComponent: myTextUserName];
  
      [myMutex lock];
			[myDallasKeys freePointers];
      [myMutex unLock];

      [self closeForm];

    CATCH

        [myMutex unLock];
  
        excode = ex_get_code();

        ex_printfmt();
  
        if (processForm){
          [processForm closeProcessForm];
          [processForm free];
          processForm = NULL;
        }

				printf("Excepcion lanzada = %d\n", excode);
				  
				if (excode != DALLAS_KEY_REQUIRED_EX && excode != SWIPE_CARD_KEY_REQUIRED_EX && excode != PIN_REQUIRED_EX)
					myCantLoginFails++;

/*
				if (ex_get_code() == CANNOT_LOGIN_IN_TELESUP_EX) {

          [JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_TELESUP_IN_PROGRESS, "Existe una supervision en curso...")];

				}
 */   
        if (ex_get_code() == INACTIVE_USER_EX) { 

          [JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_NOT_ACTIVE_USER, "Usted no es un usuario activo.")];

        } else if (ex_get_code() == USER_HAS_NOT_GOT_DOOR_ACCESS_EX) {

          [JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_USER_HAS_NOT_GOT_DOOR_ACCESS_EX, "El usuario no tiene permiso de ABRIR PUERTA!")];

        } else if ((ex_get_code() == DALLAS_KEY_REQUIRED_EX) || (ex_get_code() == SWIPE_CARD_KEY_REQUIRED_EX)) { 

          [myMutex lock];
          [myDallasKeys freePointers];
          [myMutex unLock];

					[myTimer start];

          myDallasKeyForm = [JReadDallasKeyForm createForm: self];
          [myDallasKeyForm showModalForm];
          [myDallasKeyForm free];
          myDallasKeyForm = NULL;

					[myTimer stop];

          [myMutex lock];
          if ([myDallasKeys size] > 0) tryAgain = TRUE;
          [myMutex unLock];

        } else {
          [JMessageDialog askOKMessageFrom: self withMessage: getCurrentExceptionDescription(buf)];
        }
  
        if (!tryAgain) {
          // Limpio los edits
          [myTextUserName setText: ""];
          [myTextUserPassword setText: ""];
          [self focusFormComponent: myTextUserName];
        }
              
    END_TRY;

  }

  if (excode != PIN_REQUIRED_EX) {

		[myTimer stop];
    [myMutex lock];
		[myDallasKeys freePointers];
    [myMutex unLock];
 
 } else {

		// Si requiere PIN y es nivel de seguridad le completo el nombre de usuario ya que no es necesario
		// que lo ingrese el usuario
		[myMutex lock];
		user = [[UserManager getInstance] getUserByDallasKey: myDallasKeys];
		[myMutex unLock];

		if (user && [[user getProfile] getSecurityLevel] == SecurityLevel_2) {
			[myTextUserName setText: [user getLoginName]];
			[self focusFormComponent: myTextUserPassword];
		}
	}

	// indico que se finalizo el proceso de login
	[[UserManager getInstance] setLoginInProgress: FALSE];

}

- (void) lockSystem: (int) aSeconds {
   JFORM form;
   JFormModalResult modalResult;
	 
   [Audit auditEvent: Event_WRONG_PIN_BLOCK additional: "" station: 0 logRemoteSystem: FALSE];
	 
   form = [JSimpleTimerLockForm createForm: self];
   [form setTimeout: aSeconds];
   [form setTitle: getResourceStringDef(RESID_LOCK_LOGIN_MSG, "Equipo Bloqueado!")];
   [form setShowTimer: TRUE];
   modalResult = [form showModalForm];
   [form free];
}

/**/
- (USER) getLoggedUser
{
	return myUser;
}

/**/
- (char *) getCaption1
{
	if (myCanGoBack) return getResourceStringDef(RESID_BACK_KEY, "atras");
	else if ( [[CimManager getInstance] hasActiveTimeDelays] ) return getResourceStringDef(RESID_DELAY, "delay");
	return NULL;
}

/**/
- (void) onMenu1ButtonClick
{
	if (myCanGoBack) {
		myModalResult = JFormModalResult_CANCEL;
		[self closeForm];
	} else if ([[CimManager getInstance] hasActiveTimeDelays]) {
		[UICimUtils showTimeDelays: self];
	}

	[self doChangeStatusBarCaptions];
}

/**/
- (char *) getCaption2
{
	return "login";
}

/**/
- (void) onMenu2ButtonClick
{
  if (myValidateLogin){
    [self doLogFormUser];
    
    // inicializo la variable
    forcePasswKey = 0;
  
    if (myCantLoginFails == 3){
       // llamo a la pantalla de bloqueo del equipo si supero los tres intentos de login
       [self lockSystem: [[CimGeneralSettings getInstance] getLockLoginTime]];
       myCantLoginFails = 0;
    }
  }else{
    // seteo los valores ingresados
    strcpy(myPersonalId, [myTextUserName getText]);
    strcpy(myPassword, [myTextUserPassword getText]);
    [self closeForm];
  }
	
}

/**/
- (void) onOpenWindow
{
 //doLog(0,"%s --> onOpenWindow\n", [self str]);

	if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_DALLAS_KEY) {
		[[DallasDevThread getInstance] setObserver: self];
		[[DallasDevThread getInstance] enable];
	} else
			if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_SWIPE_CARD_READER) {
				[[SwipeReaderThread getInstance] setObserver: self];
				[[SwipeReaderThread getInstance] enable];
			}

	[myLabelUserName setCaption: getResourceStringDef(RESID_USER, "ID Personal:")];
	[myLabelUserPassword setCaption: getResourceStringDef(RESID_PIN, "Clave:")];
	[myLabelUserPassword setWidth: strlen(getResourceStringDef(RESID_PIN, "Clave:"))];

	// refresco el tipo de edit del login dependiendo del seteo actual
	if ([[CimGeneralSettings getInstance] getLoginOpMode] == KeyPadOperationMode_NUMERIC) {
		[myTextUserName setNumericMode: TRUE];
		[myTextUserName setAlphaNumericLoginMode: FALSE];
	} else {
		[myTextUserName setNumericMode: FALSE];
		[myTextUserName setAlphaNumericLoginMode: TRUE];
  }
 	//doLog(0,"%s --> onOpenWindow33\n", [self str]);

	[self focusFormComponent: myTextUserName];
 	//doLog(0,"%s --> onOpenWindow44\n", [self str]);
}

/**/
- (void) onActivateWindow
{
 //   
}

/**/
- (void) setDoLog: (BOOL) aValue
{
  myDoLog = aValue;
}

/**/
- (void) setCanGoBack: (BOOL) aValue 
{
	myCanGoBack = aValue;
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) anIsPressed
{	
	id cim;
	scew_tree *tree;
  JFORM form;
	EnrollOperatorReportParam param;

  if ( aKey == UserInterfaceDefs_KEY_FNC ) {
		form = [JInstaDropForm createForm: self];
		[form setIsApplicationForm: FALSE];
		[form showModalForm];
		[form free];
	
		return TRUE;
  }

	//Si apreta el #(94) se imprime un reporte detallado de sistema
	//solo si el admin nunca fue modificado
  if ( aKey == 94 ) {
		if ([[UserManager getInstance] isAdminInInitialState]) {
		
	    param.detailReport = TRUE;	  
			param.userStatus = 0; // no se usa
			param.auditNumber = 0;
  		param.auditDateTime = 0;

			cim = [[CimManager getInstance] getCim]; 
  		tree = [[ReportXMLConstructor getInstance] buildXML: cim entityType: SYSTEM_INFO_PRT isReprint: FALSE varEntity: &param];
  		[[PrinterSpooler getInstance] addPrintingJob: SYSTEM_INFO_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];		

			return TRUE;
		}
  }

  // verifico el ingreso de combinacion de teclas para el acceso a la pantalla de forceAdminPassw
  // la combinacion de teclas a ingresar es: TECLA DEL OJO (aKey = 1) + # (aKey = 94)
  // En caso de acceder a la pantalla de login desde door access no se lo habilito. Solo en caso de logueo inicial.
  // QUEDA ANULADO HASTA QUE SE DEFINA COMO SE GENERARAN LOS CODIGOS DE OVERRIDE
  /*if ([self getCaption1] == NULL){
   if ( aKey == 1 ) {
    
    if (forcePasswKey == 0) forcePasswKey++;
    else forcePasswKey = 0;

   }else
    if ( aKey == 94 ) {

      if (forcePasswKey == 1) forcePasswKey++;
      else forcePasswKey = 0;

    }else
      forcePasswKey = 0;

   if (forcePasswKey == 2){
	forcePasswKey = 0;
	// llamo al formulario de forceAdminPassw
        form = [JForceAdminPasswForm createForm: self];
  	[form showModalForm];
  	[form free];
   }
  }*/


  return [super doKeyPressed: aKey isKeyPressed: anIsPressed];
}

/**/
- (void) setValidateLogin: (BOOL) aValue
{
  myValidateLogin = aValue;
}

/**/
- (char *) getPersonalId
{
  return myPersonalId;
}

/**/
- (char *) getPassword
{
  return myPassword;
}

@end

