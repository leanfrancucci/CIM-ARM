#include <unistd.h>
#include <assert.h>
#include "UserInterfaceExcepts.h"
#include "UserInterfaceDefs.h"
#include "JMainMenuForm.h"
#include "JSplashForm.h"
#include "JUserLoginForm.h"
#include "JDateTimeForm.h"
#include "Printer.h"
#include "system/printer/all.h"
#include "JMessageDialog.h"
#include "TelesupScheduler.h"
#include "LCDTelesupViewer.h"
#include "CtSystem.h"
#include "JExceptionForm.h"
#include "SystemTime.h"
#include "InputKeyboardManager.h"
#include "JSystem.h"
#include "MessageHandler.h"
#include "JInstaDropForm.h"
#include "JUserChangePinEditForm.h"
#include "CimGeneralSettings.h"
#include "system/util/all.h"
#include "Audit.h"
#include "Event.h"
#include "CimManager.h"
#include "AlarmThread.h"
#include "RegionalSettings.h"
#include "PrinterSpooler.h"
#include "CommercialState.h"
#include "TelesupervisionManager.h"
#include "JIncomingTelTimerForm.h"
#include "Acceptor.h"
#include "UICimUtils.h"
#include "Buzzer.h"
#include "CommercialStateMgr.h"
#include "JBoxModelChangeEditForm.h"
#include "POSAcceptor.h"


#include "CimEventDispatcher.h"
#include "Door.h"
#include "BillAcceptor.h"

#include "AsyncMsgThread.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

/**
 *
 *
 */

typedef struct {
	int hardwareId;
	int deviceType;
	id  object;
} DeviceStruct;

@implementation  JSystem

static id singleInstance = NULL;

- (void) communicationError: (int) aCause { }

/***
 * Metodos Publicos
 */

 /**/
+ new
{
	if (!singleInstance) singleInstance = [super new] ;
	return singleInstance;
}

/**/
+ getInstance
{
	return [self new];
}

/**/
- (void) initComponent
{
    printf("jSystem-initComponent...\n");
        
 	[super initComponent];

	[[JVirtualScreen getInstance] initScreenWithHeight: 24];
  
	myInputManager = [InputKeyboardManager new];
	assert(myInputManager != NULL);

	// Seteo la prioridad del hilo a la menor posible 
	[myInputManager setPriority: 5];

	/* 
     Se registra al spooler para la notificacion de mensajes de la impresora.
		 Cuando se detecte algo en la impresora, se llamara al metodo notifyPrinterState
		 de este objecto.
	 */
	[[PrinterSpooler getInstance] setPrinterStateListener: self];

  myLoggedUser = NULL;
  myApplicationsList = [Collection new];
  myCurrentApplication = NULL;
  myLastApplication = NULL;
  myLastKeyPressedTime = 0;	
}

/**/
- free
{
	if (myMainMenuForm != NULL)
		[myMainMenuForm free];
	    
	[myInputManager free];    
	return self;
}

/**/
- (BOOL) doLoginApplication
{
  USER user;
  int userId;
  int pinLife = 0;
	id form;
	BOOL sendLogout = FALSE;
	SecurityLevel secLevel;


    assert(myUserLoginForm != NULL);
	
    printf("jSystem-doLoginApplication\n");
    
	myLoggedUser = NULL;
  
  // detengo el timer del main manu
    [myMainMenuForm stopTimer];
    
	/* Se queda en el form de login clavado hasta que se loguee pero por las dudas ... */
    TRY
	
		[SystemTime checkCurrentTime];

	CATCH
		[JMessageDialog askOKMessageFrom: NULL
		   withMessage: getResourceStringDef(RESID_SYSTEM_TIME_ERROR, "La fecha/hora actual del sistema es incorrecta.") ];
	
	END_TRY

  
 
  // llamo a la pantalla de login
    while (1) {
		[myUserLoginForm showModalForm];
		myLoggedUser = [myUserLoginForm getLoggedUser];
        
        assert(myLoggedUser);
        
		if (myLoggedUser != NULL) 
			break;
        
        printf("el usuario es nulo\n");
    }
  
    
	secLevel = [[[UserManager getInstance] getProfile: [myLoggedUser getUProfileId]] getSecurityLevel];

	// verifico si debe cambiar el PIN de usuario
	//puede haber 3 motivos: 1. si su clave es temporal.
	//                       2. si expiro el pinLife
	//                       3. si su clave no tiene la longitud minima especificada (esto solo se verifica si el nivel de seguridad es != de 0)
	// este control solo se aplica si el nivel de seguridad del usuario logueado es != 0

	if (secLevel != SecurityLevel_0) {

		pinLife = [[CimGeneralSettings getInstance] getPinLife];
		if ( [myLoggedUser isPinRequired] && 
				([myLoggedUser isTemporaryPassword]
				|| (pinLife > 0) 
				|| (strlen([myLoggedUser getRealPassword]) < [[CimGeneralSettings getInstance] getPinLenght]) ) ){
			//traigo la fecha de ultimo login del usuario       
			if ( ([myLoggedUser isTemporaryPassword]) 
					|| ( ([SystemTime getLocalTime] - [myLoggedUser getLastChangePasswordDateTime]) >= (pinLife * 86400) )
					|| (strlen([myLoggedUser getRealPassword]) < [[CimGeneralSettings getInstance] getPinLenght]) ){
				
				if ( ([myLoggedUser isTemporaryPassword]) || ( ([SystemTime getLocalTime] - [myLoggedUser getLastChangePasswordDateTime]) >= (pinLife * 86400) ) )
					[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_MSG_CHANGE_PIN, "Su clave ha vencido. Debe cambiar su clave ahora.")];         
				else
					[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_INVALID_PASSWORD_EX, "Longitud de clave incorrecta. Debe cambiar su clave.")];
				
				myUserChangePinForm = [JUserChangePinEditForm createForm: self];
				//[myUserChangePinForm setShowCancel: FALSE];
				[myUserChangePinForm showFormToEdit: myLoggedUser];
	
				if ([myUserChangePinForm wasCanceledLogin])
					sendLogout = TRUE;
	
				[myUserChangePinForm free];
			}
		}

	}
	
	// si cancelo el cambio de pin entonces lo deslogueo
	if (sendLogout) {

		[self sendLogoutApplicationMessage];
		return FALSE;

	} else {

		user = myLoggedUser;
		userId = [user getUserId];
	
		// solo controlo si se debe seleccionar modelo si el modelo almacenado en la tabla
		// de backup es vacio. En cuyo caso nunca se selecciono modelo fisico.
		if ([[[CimManager getInstance] getCim] verifyBoxModelInbackup]) {
			// si el box model esta vacio y no hay movimientos es porque aun no se ha 
			// seleccionado un modelo fisico
			if ([[[CimManager getInstance] getCim] verifyBoxModelChange]) {
		
				[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_MUST_SELECT_BOX_MODEL, "Debe seleccionar un modelo de caja!")];
				// abro la pantalla de seleccion de modelos.
				form = [JBoxModelChangeEditForm createForm: self];
				[form setShowCancel: FALSE];
				[form setIsViewMode: FALSE];
				[form showModalForm];
				[form free];
			}
		}

		// MainMenuForm
		[myMainMenuForm activateMainMenu: [myLoggedUser getUserId]];
		[myMainMenuForm setLoguedUser: myLoggedUser];
	
		// Esto lo hace solo si se cerro la sesion, al iniciar no se ejecuta  
		if ( myCurrentApplication != NULL ) {
			myCurrentApplication = dateTimeApp;
			myLastApplication = NULL;
			[myCurrentApplication activateApplicationForm: myDateTimeForm];
			[myCurrentApplication activateCurrentView];
		}

		// verifico si cambiaron los modelos de los validadores
		[[[CimManager getInstance] getCim] verifyAcceptorsSerialNumbers];

		return TRUE;
	}
	 
}

/**/
- (void) doLogoutApplication
{
  char buffer[200];
   	
	if (myLoggedUser != NULL){
  	//Audita el deslogueo del usuario
    buffer[0] = '\0';
    sprintf(buffer, "%s-%s",[myLoggedUser getLoginName], [myLoggedUser getFullName]);
  	[Audit auditEventCurrentUser: Event_LOGOUT_USER additional: buffer station: 0 logRemoteSystem: FALSE];
  	  
		[[UserManager getInstance] logOffUser: [myLoggedUser getUserId]];
	}
	
	if (myCurrentApplication == dateTimeApp) [myCurrentApplication deactivateCurrentView];
	
	myLoggedUser = NULL;
	
	/* Elimina todos los mensajes de la acola de eventos */
	[self deleteAllApplicationMessages];

	/* Loguea de nuevo (enviando un mensaje) */			
	[self sendLoginApplicationMessage];

	[[MessageHandler getInstance] setCurrentLanguage: [[RegionalSettings getInstance] getLanguage]];
	[[InputKeyboardManager getInstance] setCurrentLanguage: [[RegionalSettings getInstance] getLanguage]];
  // seteo la ruta para ir a buscar los archivos de formato de los reportes segun el idioma
  [[PrinterSpooler getInstance] setReportPathByLanguage: [[RegionalSettings getInstance] getLanguage]];

}

/**/
- (void) showSplashForm
{

  JFORM 	splashForm;

  printf("jSystem-showSplashForm\n");
  
	splashForm = [JSplashForm createForm: NULL];
	TRY
		[splashForm showModalForm];		
	FINALLY		
		[splashForm free];		
	END_TRY;

}

/**/
- (void) activateTelesupScheduler
{
	TELESUP_SCHEDULER telesupScheduler = [TelesupScheduler new];
	TELESUP_VIEWER telesupViewer = [LCDTelesupViewer new];

	[telesupScheduler setTelesupViewer: telesupViewer]; 
	[telesupScheduler start];
	
}

/**/
- (void) activateTelesupPOS
{
	POS_ACCEPTOR POSacceptor = [POSAcceptor new];
	TELESUP_VIEWER telesupViewer = [LCDTelesupViewer new];

	// Inicializando supervision entrante
//	doLog(0,"Init sup. POS...\n");
	[POSacceptor setTelesupViewer: telesupViewer];
	[POSacceptor start];
//	doLog(0,"OK\n");
}

/**/
- (void) CMPStartUp
{
  FILE *f;
  COLLECTION allTelesups;
  id form;
  int i;
  id telesup;
  int userId;
  COLLECTION dallasKeys = [Collection new];
  
	// Habilito la supervision al CMP para que pueda continuar con la inicializacion
	// esto se hace solo la primera vez cuando se encuentra el archivo cmpStartUp
	f = fopen(BASE_APP_PATH "/cmpStartUp", "r");
	if (f) {
		// primero borro el archivo
    fclose(f);
		unlink(BASE_APP_PATH "/cmpStartUp");		
    
		// Inhabilita el buzzer (generalmente la puerta esta abierta y molesta)
		[[Buzzer getInstance] disableBuzzer];

    // logueo al usuario admin
    userId = [[UserManager getInstance] logInUser: "1111" password: "5231" dallasKeys: dallasKeys];
    [dallasKeys freePointers];
    [dallasKeys free];
    
    // busco la supervision y me quedo esperando a que conecte
    allTelesups = [[TelesupervisionManager getInstance] getTelesups];
		for (i=0; i < [allTelesups size]; ++i) {
		  telesup = [allTelesups at: i];
		  if ([telesup getTelcoType] == CMP_TSUP_ID){
        [[Acceptor getInstance] acceptIncomingSupervision: TRUE];
  			form = [JIncomingTelTimerForm createForm: self];
  			[form setTimeout: [[Configuration getDefaultInstance] getParamAsInteger: "INCOMING_SUPERVISION_TIMEOUT"]];
  
  			[form setTitle: getResourceStringDef(RESID_WAITING_INCOMING_SUPERV_MSG, "Esperando supervision entrante...")];
  
  			[form setCanCancel: FALSE];
  			[form setShowTimer: TRUE];
  			[[Acceptor getInstance] setFormObserver: form];
  			[form showModalForm];
  			[form free];
                
      }
		}
		// deslogueo al usuario admin
		[self sendLogoutApplicationMessage];
		[[UserManager getInstance] logOffUser: userId];

		// Vuelve a habilitar el buzzer
		[[Buzzer getInstance] enableBuzzer];

	}
    
}


- (void) myTimer1Handler
{
    printf("myTimer1Handler\n");
}

- (void) myTimer1Handler2
{
    printf("myTimer1Handler2\n");
}

- (void) myTimer1Handler3
{
    printf("myTimer1Handler3\n");
}

- (void) myTimer1Handler4
{
    printf("myTimer1Handler4\n");
}

/**/
- (void) startSystem
{
  int i;
	BOOL loginApplication;
  [myInputManager start];

  //Muestra el splashForm
  [self showSplashForm];  
  
  
  
  /* UserLoginForm */
  myUserLoginForm = [JUserLoginForm createForm: NULL];
    
  //Activa el scheduler de telesupervision
  [self activateTelesupScheduler];
  //Crea las aplicaciones
  [self createApplications];
  
 // doLog(0,"after createApplications ASOLEEEEE\n");
  
  myMainMenuForm = [JMainMenuForm createForm: NULL];

 // doLog(0,"after JMainMenuForm createForm ASOLEEEEE\n");

  // Inicia las aplicaciones
  for ( i=0; i<[myApplicationsList size]; ++i)  {
    // Agrega el menu
    [[myApplicationsList at: i] setMainApplicationForm: myMainMenuForm];	
    [[myApplicationsList at: i] startApplication];
  }    
  
  
  //  assert ([myApplicationsList size] > 0);    
  [dateTimeApp setMainApplicationForm: myMainMenuForm];	
  
	
  // hago el startUp con el CMP solo la primera vez si encuentra el archivo cmpStartUp
    [self CMPStartUp];
  

  //Activa el scheduler de supervision al POS
  //[self activateTelesupPOS];
  
	
    //Realiza el login de la aplicacion
    loginApplication = [self doLoginApplication];

  	// Siempre se activa el formulario de fecha y hora pero primero le asigna el menu ppal de configuracion
    [dateTimeApp setMainApplicationForm: myMainMenuForm];	
    [dateTimeApp startApplication];
  
	myCurrentApplication = dateTimeApp;
  

	// esto se hace por si se solicito cambio de password y el usuario cancelo la operacion
	// con lo cual no se activa la pantalla porque se manda a desloguear inmediatamente.
	if (loginApplication)
		[myCurrentApplication activateApplicationForm: myDateTimeForm];

 // doLog(0,"Iniciando hilo de alarmas...");
  [[AlarmThread getInstance] start];
  //doLog(0,"[ OK ]\n");fflush(stdout);

  /* Se queda clavado aca */
 // doLog(0,"Iniciando hilo de alarmas...");
  [self doProcessMessages];
}

/**/
- (void) addApplication: (id) anApplication
{
  [myApplicationsList add: anApplication];
}

/**/
- (void) switchApplication
{
  int i;
  id wichApplication = NULL;
  
	if ([myApplicationsList size] == 0) return;

  for (i = 0; i < [myApplicationsList size]; i++)
      if ([myApplicationsList at: i] == myCurrentApplication) 
        break;
    
  if (i >= [myApplicationsList size] - 1)
    wichApplication = [myApplicationsList at: 0];
  else
    wichApplication = [myApplicationsList at: i + 1];

	THROW_NULL( wichApplication );
  
	// @todo verificar que no se haya vencido el tiempo de prueba!!!!

	//doLog(0,"estado de la caja = %d\n", [[[CommercialStateMgr getInstance] getCurrentCommercialState] getCommState]);

	if (wichApplication == instaDropApp) {

	  [myCurrentApplication deactivateCurrentView];
  
  	// Activa la aplicacion
  	myCurrentApplication = wichApplication;
  
  	[myCurrentApplication activateCurrentView];
	}

}

/**/
- (void) showAlarm: (char *) aMessage
{
	JEvent		evt;
		
  evt.evtid = JEventQueueMessage_SHOW_ALARM;
  evt.evtParam1 = strdup(aMessage);
  
	[myEventQueue putJEvent: &evt];	
}

/**/
/*
- (void) notifyPrinterState: (PrinterState) aPrinterState
{
	JEvent		evt;
	char additional[20];
	
  evt.evtid = JEventQueueMessage_PRINTER_STATE;
  evt.evtParam1 = aPrinterState;
  
	[myEventQueue putJEvent: &evt];	
	
  // obtengo el tipo de estado para poder auditar
  switch ( aPrinterState ) {
  
    case PrinterState_PAPER_OUT:
      strcpy(additional, getResourceStringDef(RESID_PRINT_ERROR_PAPER_OUT, "Falta de papel"));
      
      break;
      
    case PrinterState_OUT_OF_LINE:
      strcpy(additional, getResourceStringDef(RESID_PRINT_ERROR_OUT_OF_LINE, "Fuera de linea"));
      break;
      
    case PrinterState_PRINTER_INTERNAL_FATAL_ERROR:
      strcpy(additional, getResourceStringDef(RESID_PRINT_ERROR_INTERNAL_ERROR, "Error interno"));
      break;
       
    case PrinterState_PRINTER_FATAL_ERROR:
      strcpy(additional, getResourceStringDef(RESID_PRINT_ERROR_FATAL_ERROR, "Error fatal"));
      break;

    case PrinterState_PRINTER_NOT_RESPONDING_BERIGUEL:
      strcpy(additional, getResourceStringDef(RESID_PRINT_ERROR_NOT_RESPONDING, "Imp. no responde"));
      break;
    
    default:
      break;      
  }

	[Audit auditEventCurrentUser: Event_PRINTING_ERROR additional: additional station: 0 logRemoteSystem: FALSE];
}
*/
/**/
- (void) notifySerialNumberChange: (int) anAcceptorSettingsId
{
	/*JEvent		evt;
	char additional[20];
	
  evt.evtid = JEventQueueMessage_ACCEPTOR_SERIAL_NUMBER_CHANGE;
	evt.evtParam1 = anAcceptorSettingsId;
  
	[myEventQueue putJEvent: &evt];	
	sprintf(additional, "%d", anAcceptorSettingsId);
*/
	char additional[20];
	char buffer[50];

	//doLog(0,"**************************************\n");
	//doLog(0,"acceptorSerialNumberChangeNotification\n");

	sprintf(buffer, "%s%s%s", getResourceStringDef(RESID_DEVICE_CHANGE, "Cambio en el dispositivo:"), " ", [[[[CimManager getInstance] getCim] getAcceptorSettingsById: anAcceptorSettingsId] getAcceptorName]);

	[UICimUtils showAlarm: buffer];

	//@todo auditar que cambio el numero de serie
	sprintf(additional, "%d", anAcceptorSettingsId);
	//[Audit auditEventCurrentUser: Event_PRINTING_ERROR additional: additional station: 0 logRemoteSystem: FALSE];
}

/**/
- (BOOL) doProcessMessage: (JEvent *) anEvent
{

	switch (anEvent->evtid) {
	
		/* Key Pressed Event */
		case JEventQueueMessage_KEY_PRESSED:

						/* Si la aplicacion puede procesar la tecla retorna TRUE.
							como esta la cosa la aplicacion nunca maneja la tecla.  */					
						if (![self processKey: anEvent->event.keyEvt.keyPressed 
																					isKeyPressed: anEvent->event.keyEvt.isPressed])
							break;
							
						return TRUE;
	
		// ejecuta un logout de la aplicacion 
		case JEventQueueMessage_LOGOUT_APPLICATION:
						[self doLogoutApplication];
						return TRUE;							

		// ejecuta un login de la aplicacion 
		case JEventQueueMessage_LOGIN_APPLICATION:
						[self doLoginApplication];
						return TRUE;																		

		default:
						break;
	}
	
  if (myCurrentApplication != NULL)
		[myCurrentApplication doProcessMessage: anEvent];				
	
  return TRUE;
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) anIsPressed
{	
	unsigned long ticks;
	
	ticks = getTicks();
	
	// Despues de cada tecla llega una loca y hay que descartarla
	if ((aKey-'0') == 14) return TRUE;

	if (isdigit(aKey) && myLastKeyPressedTime > 0) {
		myLastKeyPressedTime = 0;				
		return FALSE;
	}		
	
	if (aKey == JComponent_KEY_PLUS_10) {
		myLastKeyPressedTime = getTicks();
		return FALSE;
	}
	
	myLastKeyPressedTime = 0;

  // Si se presiona la tecla 0 se pasa a la vista de fecha/hora manteniendo la ultima aplicacion activa
  if ( (aKey - '0') == 0 ) {

    // detengo el timer del main manu
    [myMainMenuForm stopTimer];

		// El formulario de Insta Drop maneja la tecla por si solo
		if ( myCurrentApplication == instaDropApp && [myCurrentApplication getActiveApplicationForm] == myInstaDropForm) return FALSE;

    if ( myCurrentApplication != dateTimeApp ) myLastApplication = myCurrentApplication;
    
    
    [myCurrentApplication deactivateCurrentView];
    myCurrentApplication = dateTimeApp;
    [myCurrentApplication activateCurrentView];
            
    return TRUE;
  }
  
  if ( aKey == UserInterfaceDefs_KEY_FNC ) {
  
    // detengo el timer del main menu
    [myMainMenuForm stopTimer];
      
    // Si se presion la tecla funcion y la aplicacion activa es la de fecha/hora se pasa a la ultima aplicacion (en el caso que ya
    // se haya activado alguna, en otro caso pasa a la primera aplicacion.
    if ( myCurrentApplication == dateTimeApp && [myApplicationsList size] > 0) {
      
      if ( myLastApplication ) {
      	[myCurrentApplication deactivateCurrentView];
				myCurrentApplication = myLastApplication;
	      [myCurrentApplication activateCurrentView];
  	    myLastApplication = NULL;

      } else {
				if ([myApplicationsList at: 0] == instaDropApp) {
			
			  	[myCurrentApplication deactivateCurrentView];      	
					myCurrentApplication = [myApplicationsList at: 0];
		      [myCurrentApplication activateCurrentView];
      		myLastApplication = NULL;

				}
			}
      
   } else 
      // De otra manera se switchea entre aplicaciones.
      [self switchApplication];
    
    return TRUE;
  }
  
  if ( aKey == UserInterfaceDefs_KEY_LEFT ) {
    // Si se presiona la tecla de vista y la aplicacion activa es la de fecha/hora se pasa a la ultima aplicacion (en el caso que ya
    // se haya activado alguna, en otro caso pasa a la primera aplicacion.
    if ( myCurrentApplication == dateTimeApp ) {
////////// CIM: DESCOMENTAR /////////////////////////    

  /*[myCurrentApplication deactivateCurrentView];
      
      if ( myLastApplication ) myCurrentApplication = myLastApplication;
      else myCurrentApplication = [myApplicationsList at: 0];
      
      [myCurrentApplication activateCurrentView];
      myLastApplication = NULL;
*/
      return TRUE;

    }  
  }
  
  /*AGREGO LAS NUEVAS TECLAS DEL TECLADO*/
  if ( aKey == UserInterfaceDefs_KEY_FNC_2 ) {
    return TRUE;
  }
    
  if ( aKey == UserInterfaceDefs_KEY_MANUAL_DROP ) {
    if ([myMainMenuForm canExecuteMenu: MANUAL_DROP_OP]){

      // Se hace activate y deactivate porque fue la unica forma que se encontro
      // para poder darle el foco al main menu. Esto produce un refresco en el visor
      // que queda feo. Ver de que forma se puede solucionar
      [myCurrentApplication activateCurrentView];
      [myCurrentApplication deactivateCurrentView];
      [self sendActivateMainApplicationFormMessage];
      // ejecuto el menu de manual drop
      [myMainMenuForm executeManualDropMenu];
      [self sendActivateMainApplicationFormMessage];
      return TRUE;
    }
  }
  
  if ( aKey == UserInterfaceDefs_KEY_DEPOSIT ) {
    if (([myMainMenuForm canExecuteMenu: OPEN_DOOR_OP])&& (![[[CimManager getInstance] getCim] isTransferenceBoxMode])) {

        // Se hace activate y deactivate porque fue la unica forma que se encontro
        // para poder darle el foco al main menu. Esto produce un refresco en el visor
        // que queda feo. Ver de que forma se puede solucionar
        [myCurrentApplication activateCurrentView];
        [myCurrentApplication deactivateCurrentView];
        [self sendActivateMainApplicationFormMessage];
        // ejecuto el menu de door access
        [myMainMenuForm executeDoorAccessMenu];
        [self sendActivateMainApplicationFormMessage];
        return TRUE;
    }
  }
  
  if ( aKey == UserInterfaceDefs_KEY_REPORTS ) {
    if ([myMainMenuForm canExecuteReportMenu]){

      // Se hace activate y deactivate porque fue la unica forma que se encontro
      // para poder darle el foco al main menu. Esto produce un refresco en el visor
      // que queda feo. Ver de que forma se puede solucionar
      [myCurrentApplication activateCurrentView];
      [myCurrentApplication deactivateCurrentView]; 
      [self sendActivateMainApplicationFormMessage];
      // ejecuto el menu de report
      [myMainMenuForm executeReportMenu];
      [self sendActivateMainApplicationFormMessage];
      return TRUE;
    }
  }
  
  if ( aKey == UserInterfaceDefs_KEY_VALIDATED_DROP ) {
    if ([myMainMenuForm canExecuteMenu: VALIDATED_DROP_OP]){

      // Se hace activate y deactivate porque fue la unica forma que se encontro
      // para poder darle el foco al main menu. Esto produce un refresco en el visor
      // que queda feo. Ver de que forma se puede solucionar
      [myCurrentApplication activateCurrentView];
      [myCurrentApplication deactivateCurrentView]; 
      [self sendActivateMainApplicationFormMessage];
      // ejecuto el menu de validated drop
      [myMainMenuForm executeValidatedDropMenu];
      [self sendActivateMainApplicationFormMessage];
      return TRUE;
    }
  }  
  
	return FALSE;	
}

/**/
- (void) sendActivateNextApplicationFormMessage
{
	JEvent		evt;

	evt.evtid = JEventQueueMessage_ACTIVATE_NEXT_APPLICATION_FORM;
	[myEventQueue putJEvent: &evt];
}

/**/
- (void) sendActivateMainApplicationFormMessage
{
	JEvent		evt;

	evt.evtid = JEventQueueMessage_ACTIVATE_MAIN_APPLICATION_FORM;
	[myEventQueue putJEvent: &evt];
}

/**/
- (void) sendCloseApplicationMessage
{
	JEvent		evt;

	evt.evtid = JEventQueueMessage_CLOSE_APPLICATION;
	[myEventQueue putJEvent: &evt];
}

/**/
- (void) sendLogoutApplicationMessage
{
	JEvent		evt;
    
 
    printf("LOGOUT \n");
	evt.evtid = JEventQueueMessage_LOGOUT_APPLICATION;
	[myEventQueue putJEvent: &evt];
}

/**/
- (void) sendLoginApplicationMessage
{
	JEvent		evt;

	evt.evtid = JEventQueueMessage_LOGIN_APPLICATION;
	[myEventQueue putJEvent: &evt];
}

/**/
- (void) deleteAllApplicationMessages
{
	JEvent		evt;

	while (TRUE) {
		
		if ([myEventQueue getMessageCount] == 0)
				return;
			
		evt.evtid = JEventQueueMessage_NONE;
		[myEventQueue getJEvent: &evt];
		
	}	
}

- (void) createApplications
{
  
  //  Crea la fecha y hora del sistema
  dateTimeApp = [JApplication new];
	myDateTimeForm = [JDateTimeForm createForm: NULL];
	[myDateTimeForm setCanClose: FALSE];
  [dateTimeApp addApplicationForm: myDateTimeForm];

	instaDropApp = [JApplication new];
	myInstaDropForm = [JInstaDropForm createForm: NULL];
	[myInstaDropForm setCanClose: FALSE];
	[instaDropApp addApplicationForm: myInstaDropForm];
	[self addApplication: instaDropApp];

  // La aplicacion de fehca/hora no se agrega a la lista de aplicaciones porque no interactuara con ellas.
  
  // Creara las aplicaciones correspondientes a la configuracion
/*  
  // Verifica la aplicacion de telefonia
  if (strcmp([[Configuration getDefaultInstance] getParamAsString: "CALL_CENTER_APPLICATION"], "yes") == 0) {
    callCenterApp = [JCallCenterApplication new];
    [self addApplication: callCenterApp];
  }    

  // Verifica la aplicacion de control de PC
  if (strcmp([[Configuration getDefaultInstance] getParamAsString: "WS_CONTROL_APPLICATION"], "yes") == 0) {
    wStationControlApp = [JWSControlApplication new];
    [self addApplication: wStationControlApp];
  } 

  // Verifica la aplicacion de venta de productos
  if (strcmp([[Configuration getDefaultInstance] getParamAsString: "PRODUCT_SALE_APPLICATION" default: "yes"], "yes") == 0) {
    productSaleApp = [JProductSaleApplication new];
    [self addApplication: productSaleApp];
  } 
   */
  //assert ( [myApplicationsList size] > 0 );    
}

/**/
- (id) getCurrentApplication
{
  return myCurrentApplication;
}

/**/
- (void) showDefaultExceptionDialogWithExCode: (int) anExceptionCode
{	
		char myExceptionMessage[ JComponent_MAX_LEN + 1 ];
		char msg[255];
		JWINDOW oldForm;

		//doLog(0,"JSystem -> showDefaultExceptionDialogWithExCode\n");

		oldForm = [JWindow getActiveWindow];
		if (oldForm) {
			//doLog(0,"Old form class Name = %s\n", [oldForm name]);
			[oldForm deactivateWindow];
		}

    TRY

			ex_printfmt();      
      snprintf(myExceptionMessage, JComponent_MAX_LEN, [[MessageHandler getInstance] processMessage: msg messageNumber: anExceptionCode]);
    
    CATCH
		  snprintf(myExceptionMessage, JComponent_MAX_LEN, "Exception: %d!", anExceptionCode);

    END_TRY
    
    
    [JMessageDialog askOKMessageFrom: self withMessage: myExceptionMessage];
	
		if (oldForm) [oldForm activateWindow];
}

/**/
- (void) onRefreshMenu
{
	if (myMainMenuForm)
		[myMainMenuForm configureMainMenu];
}

/**/
- (void) notifyPrinterState: (PrinterState) aPrinterState
{
    [[AsyncMsgThread getInstance] addAsyncMsg: "1000" description: "Falta de papel. Se cancela la impresion del documento." isBlocking: FALSE];
    [[PrinterSpooler getInstance] cancelLastJob];
}


@end

