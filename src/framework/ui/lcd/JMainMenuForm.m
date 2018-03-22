#include "JSystem.h"
#include "JMainMenuForm.h"
#include "JGeneralEditForm.h"
#include "JHeaderEditForm.h"
#include "JFooterEditForm.h"
#include "JPrintingEditForm.h"
#include "JAmountEditForm.h"
#include "JGeneralEditForm.h"
#include "JRegionalSettingsEditForm.h"
#include "JProfilesListForm.h"
#include "JUsersListForm.h"
#include "JUserEditForm.h"
#include "JUserChangePinEditForm.h"
#include "User.h"
#include "UserManager.h"
#include "CtSystem.h"
#include "JTelesupervisionsListForm.h"
#include "ExtractionDAO.h"
#include "ZCloseDAO.h"
#include "dynamicPin.h"

#include "BillSettings.h"
#include "PrintingSettings.h"
#include "AmountSettings.h"
#include "RegionalSettings.h"
#include "JMessageDialog.h"
#include "JSystemInfoForm.h"

#include "JManualTelesupListForm.h"
#include "TelesupervisionManager.h"
#include "JSystemConfigForm.h"
#include "system/printer/all.h"
#include "JExceptionForm.h"
#include "JProgressBarForm.h"
#include "JInfoViewerForm.h"

#include "JAutomaticDepositForm.h"
#include "ctapp.h"
#include "JTelesupervisionsListForm.h"
#include "JInstaDropSettingsForm.h"
#include "JVerifyBillForm.h"
#include "doorover.h"
#include "CimBackup.h"
#include "JRepairOrderForm.h"

#include "BillAcceptor.h"
#include "ExtractionWorkflow.h"
#include "JDoorStateForm.h"
#include "SafeBoxHAL.h"

#include "Persistence.h"
#include "DepositDAO.h"
#include "ReportXMLConstructor.h"
#include "ExtractionManager.h"
#include "ZCloseManager.h"
#include "CimManager.h"
#include "JSimpleSelectionForm.h"
#include "Cim.h"
#include "UICimUtils.h"
#include "JManualDepositListForm.h"
#include "InstaDropManager.h"
#include "JDoorDelaysForm.h"
#include "Event.h"
#include "Audit.h"
#include "CashReference.h"
#include "CashReferenceManager.h"
#include "cttypes.h"
#include "CimGeneralSettings.h"
#include "JCashReferenceListForm.h"
#include "EventCategory.h"
#include "JAuditReportDateEditForm.h"
#include "JCimCashListForm.h"
#include "JDoorsListForm.h"
#include "JUpdateFirmwareForm.h"
#include "JUserLoginForm.h"
#include "Acceptor.h"
#include "CurrencyManager.h"
#include "JDoorOverrideForm.h"
#include "JSelectRangeEditForm.h"
#include "Profile.h"
#include "JDoorsByUserListForm.h"
#include "JDualAccessListForm.h"
#include "TelesupScheduler.h"
#include "JActivateDeactivateUserEditForm.h"
#include "AuditDAO.h"
#include "JIncomingTelTimerForm.h"
#include "JExtendedDropDetailForm.h"
#include "RepairOrderManager.h"
#include "JCommercialStateChangeForm.h"
#include "Buzzer.h"
#include "JCimGeneralSettingsEditForm.h"
#include "SimCardValidator.h"
#include "CommercialStateMgr.h"
#include "UpdateFirmwareThread.h"
#include "TelesupTest.h"
#include "JDeviceSelectionEditForm.h"
#include "JNumbersEntryForm.h"
#include "DepositDetailReport.h"
#include "JCimDeviceLoginSettingsEditForm.h"
#include "JBoxModelChangeEditForm.h"
#include "JSplashBackupForm.h"
#include "JCimBackupSettingsEditForm.h"

#define printd(args...) //doLog(0,args)
//#define printd(args...)

//#define _TEST_SUB_MENU
#undef  _TEST_SUB_MENU

@implementation  JMainMenuForm

static char myCaption1Msg[] = "atras";
static char myTimeDelayMsg[] = "retardo";

- (void) openMultipleDoors;
- (void) openDoor: (DOOR) aDoor;
- (BOOL) canReboot;
- (void) informMultipleDoors;
- (int) getBagTrackingMode: (id) aDoor;

/**/
- (void) onCreateForm
{
  [super onCreateForm];

	myLoguedUserId = 0;
	
	// inicio el timer para hacer el autodeslogueo por inactividad
	myTimer = [OTimer new];
  [myTimer initTimer: ONE_SHOT period: ([[CimGeneralSettings getInstance] getMaxUserInactivityTime] * 1000) object: self callback: "timerExpired"];

	myMainMenu = [JMainMenu new];

	// Se setea al menu para el display de 4 x 20, la ultima linea es reservada para las   
	// acciones que se pueden llevar a cabo en cada uno de los contextos.
	[myMainMenu  setWidth: 20];
	[myMainMenu  setHeight: 3];
		
	// Se agrega el menu creado, al formulario.
	[self addFormComponent: myMainMenu];

}

/**/
- free
{
	//doLog(0,"Liberando JMainMenuForm...\n");
	return [super free];
}

/**/
- (void) onViewButtonClick
{
  [[JSystem getInstance] sendActivateNextApplicationFormMessage];
}

/**/
- (USER) loginUser: (int) aPermission
{
	USER myLoggedUser = NULL;
	PROFILE p;
	JFORM myUserLoginForm, myUserChangePinForm;
  int pinLife = 0;
	SecurityLevel secLevel;

	/* UserLoginForm */
	myUserLoginForm = [JUserLoginForm createForm: self];

  while (1) {

		myLoggedUser = NULL;

		[myUserLoginForm setCanGoBack: TRUE];

		if ([myUserLoginForm showModalForm] == JFormModalResult_CANCEL) {
			myLoggedUser = NULL;
			break;
		}

		myLoggedUser = [myUserLoginForm getLoggedUser];
		p = [[UserManager getInstance] getProfile: [myLoggedUser getUProfileId]];

		if (myLoggedUser != NULL && ![p hasPermission: aPermission]) {
			[JMessageDialog askOKMessageFrom: self 
				withMessage: getResourceStringDef(RESID_USER_NOT_HAVE_PERMISSION, "El usuario no tiene permiso!")];
		} else break;


	}

	[myUserLoginForm free];
	
	if (myLoggedUser == NULL) 
		return NULL;

	secLevel = [[[UserManager getInstance] getProfile: [myLoggedUser getUProfileId]] getSecurityLevel];

	// verifico si debe cambiar el PIN de usuario
	//puede haber 3 motivos: 1. si su clave es temporal.
	//                       2. si expiro el pinLife
	//                       3. si su clave no tiene la longitud minima especificada
	// este control solo se aplica si el nivel de seguridad del usuario logueado es != 0

	if (secLevel != SecurityLevel_0) {

		pinLife = [[CimGeneralSettings getInstance] getPinLife];
		if ( [myLoggedUser isPinRequired] && 
				([myLoggedUser isTemporaryPassword]
				|| (pinLife > 0) 
				|| (strlen([myLoggedUser getRealPassword]) < [[CimGeneralSettings getInstance] getPinLenght])) ){
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
				[myUserChangePinForm free];
			}
		}

	}

	return myLoggedUser;

}

/**/
- (void) logoutUser
{
}

/**/
- (void) configureGeneralSettingsSubMenu
{
	JACTION_MENU jHeadersMenu, jFootersMenu, jTelesupConfigMenu, jRegionalSettingsMenu, jPrinterMenu;
	JMENU_ITEM userSubMenu;
	JMENU_ITEM userMenu;
	JMENU_ITEM userEnrollMenu;
	JMENU_ITEM userChangePinMenu;
  JMENU_ITEM doorByUserMenu;
	JMENU_ITEM jNetworkSettingsMenu;
	JMENU_ITEM jCashReferenceMenu;
	JMENU_ITEM jCashesMenu;
	JMENU_ITEM jDoorsMenu;
	JMENU_ITEM profileMenu;
	JMENU_ITEM dualAccessMenu;
	JMENU_ITEM forcePinChangeMenu;
	JMENU_ITEM resetPinMenu;
	//JMENU_ITEM reprintClosingCodeMenu;
	//JMENU_ITEM resetDynamicPinMenu;
	JMENU_ITEM securitySubMenu;
	JMENU_ITEM printingSubMenu;
	JMENU_ITEM jCimGeneralSettingsMenu;
	JMENU_ITEM jCimDeviceSettingsMenu;
	JMENU_ITEM jCimDeviceLoginSettingsMenu;
	JMENU_ITEM jCimModelSettingsMenu;
	JMENU_ITEM jCimBackupSettingsMenu;
	PROFILE profile;
            
	// si esta funcionando con hardware secundario no creo los menues  
  if ([UICimUtils canMakeDeposits]){
      
    USER user = [[UserManager getInstance] getUserLoggedIn];
		if (!user) return;
    profile = [[UserManager getInstance] getProfile: [user getUProfileId]];      
      
    generalSettingsSubMenu = [JSubMenu new];
          
    // Agrega el submenu al MainMenu
    [myMainMenu addMenuItem: generalSettingsSubMenu]; 
    [generalSettingsSubMenu setCaption: getResourceStringDef(RESID_GENERAL_SETT_MENU, "Seteos Generales")];           
        
    	
    	if ([profile hasPermission: GENERAL_PRINT_SETTINGS_OP]){

    	// Configuracion de impresion
    	printingSubMenu = [JSubMenu new];
    	[printingSubMenu setCaption: getResourceStringDef(RESID_PRINTING_MENU, "Config Impresion")];
    	[generalSettingsSubMenu addMenuItem: printingSubMenu];

        // Encabezados
      	jHeadersMenu = [JActionMenu new];
      	[jHeadersMenu initActionMenu: getResourceStringDef(RESID_HEADER_MENU, "Encabezados") object: self action: "jHeadersMenu_Click"];
      	[printingSubMenu addMenuItem: jHeadersMenu];
      
      	// Pies
      	jFootersMenu = [JActionMenu new];
      	[jFootersMenu initActionMenu: getResourceStringDef(RESID_FOOTER_MENU, "Pies") object: self action: "jFootersMenu_Click"];
      	[printingSubMenu addMenuItem: jFootersMenu];

      	// Tipo de Impresora
      	jPrinterMenu = [JActionMenu new];
      	[jPrinterMenu initActionMenu: getResourceStringDef(RESID_PRINTER_TYPE_MENU, "Tipo Impresora") object: self action: "jPrimterMenu_Click"];
      	[printingSubMenu addMenuItem: jPrinterMenu];
    	}
    
    	// Seguridad
    	securitySubMenu = [JSubMenu new];
    	[securitySubMenu setCaption: getResourceStringDef(RESID_SECURITY_MENU, "Seguridad")];	
    	[generalSettingsSubMenu addMenuItem: securitySubMenu];
    
        // Profiles
    		if ([profile hasPermission: PROFILES_ADMINISTRATION_OP]){
      		profileMenu = [JActionMenu new];
      		[profileMenu initActionMenu: getResourceStringDef(RESID_PROFILES_MENU, "Perfiles") object: self action: "jProfilesMenu_Click"];
      		[securitySubMenu addMenuItem: profileMenu];
    		}
    		
        // Duplas
    		if ([profile hasPermission: DUAL_ACCESS_OP]){
      		dualAccessMenu = [JActionMenu new];
      		[dualAccessMenu initActionMenu: getResourceStringDef(RESID_DUAL_ACCESS_MENU, "Acceso por duplas") object: self action: "jDualAccessMenu_Click"]; 
      		[securitySubMenu addMenuItem: dualAccessMenu];
    		}		
      
      	// Usuarios
      	userSubMenu = [JSubMenu new];
      	[userSubMenu setCaption: getResourceStringDef(RESID_USER_MENU, "Usuarios")];	
      	[securitySubMenu addMenuItem: userSubMenu];
      		
      		if ([profile hasPermission: USERS_ADMINISTRATION_OP]){
            // Enroll user
        		userEnrollMenu = [JActionMenu new];    
        		[userEnrollMenu initActionMenu: getResourceStringDef(RESID_NEW_USER_MENU, "Nuevo Usuario") object: self action: "jEnrollUsersMenu_Click"]; 
        		[userSubMenu addMenuItem: userEnrollMenu];
        		
        		// Edit user
        		userMenu = [JActionMenu new];    
        		[userMenu initActionMenu: getResourceStringDef(RESID_EDIT_USER_MENU, "Editar Usuario") object: self action: "jUsersMenu_Click"]; 
        		[userSubMenu addMenuItem: userMenu];
      		}
    
          if ([profile hasPermission: DELETE_USER_OP]){
        		// Delete user
        		userMenu = [JActionMenu new];    
        		[userMenu initActionMenu: getResourceStringDef(RESID_DELETE_USER_MENU, "Eliminar Usuario") object: self action: "jDeleteUsersMenu_Click"]; 
        		[userSubMenu addMenuItem: userMenu];
      		}
      		
        	// Puertas por usuario
          if ([profile hasPermission: DOORS_BY_USER_OP]){
            doorByUserMenu = [JActionMenu new];    
          	[doorByUserMenu initActionMenu: getResourceStringDef(RESID_DOORS_USER_MENU, "Puertas por Usu.") object: self action: "jDoorsByUsersMenu_Click"];
          	[userSubMenu addMenuItem: doorByUserMenu];
        	}
      		
      		// cambiar estado de usuarios
          if ([profile hasPermission: USER_STATE_OP]){
            // Activate User
            resetPinMenu = [JActionMenu new];    
          	[resetPinMenu initActionMenu: getResourceStringDef(RESID_ACTIVATE_USER_MENU, "Activar Usuarios") object: self action: "jActivateUserMenu_Click"];
          	[userSubMenu addMenuItem: resetPinMenu];
          
            // Deactivate User
            resetPinMenu = [JActionMenu new];    
          	[resetPinMenu initActionMenu: getResourceStringDef(RESID_DEACTIVATE_USER_MENU, "Inact. Usuarios") object: self action: "jDeactivateUserMenu_Click"];
          	[userSubMenu addMenuItem: resetPinMenu];
        	}          	
          
          // Forzar cambio de PIN
          if ([profile hasPermission: FORCE_PIN_CHANGE_OP]){
            forcePinChangeMenu = [JActionMenu new];    
          	[forcePinChangeMenu initActionMenu: getResourceStringDef(RESID_FORCE_PIN_CHANGE_MENU, "Forzar Cam Clave") object: self action: "jForcePinChangeMenu_Click"];
          	[userSubMenu addMenuItem: forcePinChangeMenu];
        	}  		
      		
		  if (![user getUsesDynamicPin]){	
			// Si el usuario tiene configurado PIN DINAMICO no dejo que modifique su PIN
      		userChangePinMenu = [JActionMenu new];    
      		[userChangePinMenu initActionMenu: getResourceStringDef(RESID_CHANGE_USER_PIN_MENU, "Cambiar Clave") object: self action: "jChangeUserPinMenu_Click"]; 
      		[userSubMenu addMenuItem: userChangePinMenu];
    	  }
      		// Reimpresion de Codigo de Cierre (Posee permiso! CAMBIAR)
	/*		Comentado pines dinamicos
          if ([profile hasPermission: PRINT_CLOSE_CODE_OP]){
      		reprintClosingCodeMenu = [JActionMenu new];    
      		[reprintClosingCodeMenu initActionMenu: getResourceStringDef(RESID_REPRINT_CLOSING_CODE_MENU, "Impresion Codigo Cierre") object: self action: "jReprintClosingCodeMenu_Click"]; 
      		[userSubMenu addMenuItem: reprintClosingCodeMenu];
    		}

          if ([profile hasPermission: RESET_DYNAMIC_PIN_OP]){
      		resetDynamicPinMenu = [JActionMenu new];    
      		[resetDynamicPinMenu initActionMenu: getResourceStringDef(RESID_RESET_DYNAMIC_PIN_MENU, "Reinicio PIN Dinamico") object: self action: "jResetDynamicPinMenu_Click"]; 
      		[userSubMenu addMenuItem: resetDynamicPinMenu];
    		}
*/
    	if ([profile hasPermission: SUPERVISION_SETTINGS_OP]){
        // Configurar supervision
      	jTelesupConfigMenu = [JActionMenu new];
      	[jTelesupConfigMenu initActionMenu: getResourceStringDef(RESID_SUPERVISION_MENU, "Supervisiones") object: self action: "jTelesupConfigMenu_Click"];
      	[generalSettingsSubMenu addMenuItem: jTelesupConfigMenu];
    	}
  
      if ([profile hasPermission: SET_CASH_OP]){
    		// Cashes
    		jCashesMenu = [JActionMenu new];
      	[jCashesMenu initActionMenu: getResourceStringDef(RESID_CASHES_MENU, "Cashes") object: self action: "jCashesMenu_Click"];
      	[generalSettingsSubMenu addMenuItem: jCashesMenu];
      }

      if ([profile hasPermission: SET_DOORS_OP]){
    		// Doors
    		jDoorsMenu = [JActionMenu new];
      	[jDoorsMenu initActionMenu: getResourceStringDef(RESID_DOORS_MENU, "Doors") object: self action: "jDoorsMenu_Click"];
      	[generalSettingsSubMenu addMenuItem: jDoorsMenu];
      }

    	if ([[CimGeneralSettings getInstance] getUseCashReference]) {
        if ([profile hasPermission: SET_REFERENCE_OP]){
        	// Cash references
      		jCashReferenceMenu = [JActionMenu new];
        	[jCashReferenceMenu initActionMenu: getResourceStringDef(RESID_REFERENCES_MENU, "References") object: self action: "jCashReferenceMenu_Click"];
        	[generalSettingsSubMenu addMenuItem: jCashReferenceMenu];
      	}
    	}
  
      if ([profile hasPermission: REGIONAL_SETTINGS_OP]){
      	// Configuracion regional
      	jRegionalSettingsMenu = [JActionMenu new];
      	[jRegionalSettingsMenu initActionMenu: getResourceStringDef(RESID_REGIONAL_MENU, "Regional") object: self action: "jRegionalSettingsMenu_Click"];
      	[generalSettingsSubMenu addMenuItem: jRegionalSettingsMenu];
    	}
  
      if ([profile hasPermission: NETWORK_SETTINGS_OP]){
      	// Configuracion de red
      	jNetworkSettingsMenu = [JActionMenu new];
      	[jNetworkSettingsMenu initActionMenu: getResourceStringDef(RESID_LOCAL_NET_MENU, "Red local") object: self action: "jNetworkSettingsMenu_Click"];
      	[generalSettingsSubMenu addMenuItem: jNetworkSettingsMenu];
    	}

			if ([profile hasPermission: GENERAL_SETTINGS_OP]){
      	// Configuracion general
      	jCimGeneralSettingsMenu = [JActionMenu new];
      	[jCimGeneralSettingsMenu initActionMenu: getResourceStringDef(RESID_GENERAL_MENU, "General") object: self action: "jCimGeneralSettingsMenu_Click"];
      	[generalSettingsSubMenu addMenuItem: jCimGeneralSettingsMenu];

      	// Configuracion dispositivo de login
      	jCimDeviceLoginSettingsMenu = [JActionMenu new];
      	[jCimDeviceLoginSettingsMenu initActionMenu: getResourceStringDef(RESID_LOGIN_DEVICE_MENU, "Disp. login") object: self action: "jCimDeviceLoginSettingsMenu_Click"];
      	[generalSettingsSubMenu addMenuItem: jCimDeviceLoginSettingsMenu];

			}

      // Dispositivos	
			if ([profile hasPermission: DEVICE_COMMUNICATION_OP]){
				jCimDeviceSettingsMenu = [JActionMenu new];
				[jCimDeviceSettingsMenu initActionMenu: getResourceStringDef(RESID_DEVICE_SETTINGS_MENU, "Dispositivos") object: self action: "jCimDeviceSettingsMenu_Click"];
				[generalSettingsSubMenu addMenuItem: jCimDeviceSettingsMenu];
			}

			if ([profile hasPermission: DEVICE_CONFIG_OP]){
				// Configuracion Modelo de caja
				jCimModelSettingsMenu = [JActionMenu new];
				[jCimModelSettingsMenu initActionMenu: getResourceStringDef(RESID_BOX_MODEL_MENU, "Modelo de Caja") object: self action: "jCimBoxModelSettingsMenu_Click"];
				[generalSettingsSubMenu addMenuItem: jCimModelSettingsMenu];
			}

			if ([profile hasPermission: GENERAL_SETTINGS_OP]){
				// Configuracion de backup automatico
				jCimBackupSettingsMenu = [JActionMenu new];
				[jCimBackupSettingsMenu initActionMenu: getResourceStringDef(RESID_BACKUP_MENU, "Backup") object: self action: "jCimBackupSettingsMenu_Click"];
				[generalSettingsSubMenu addMenuItem: jCimBackupSettingsMenu];
			}

  }
}

/***********************************
*
***********************************/


/**/
- (void) setLoguedUser: (USER) anUser
{
	if (anUser == NULL)
		myLoguedUserId = 0;
	else {	
		myLoguedUserId = [anUser getUserId];
		
	}	
	[self configureMainMenu];

}

/**/
- (void) configureReportsSubMenu
{
	JACTION_MENU jMenu;
	JMENU_ITEM cashSubMenu;
	JMENU_ITEM byCashMenu;
	JMENU_ITEM byDoorMenu;
	PROFILE profile;
	BOOL primaryHardwareOK;
	USER user;
	
	// si esta funcionando con hardware secundario no creo los menues salvo door access
  primaryHardwareOK = [UICimUtils canMakeDeposits];

  // Agrega el submenu al MainMenu (Siempre y cuando este menu ontenga algun hijo)
  if (primaryHardwareOK) {
  
    user = [[UserManager getInstance] getUserLoggedIn];
		if (!user) return;
    profile = [[UserManager getInstance] getProfile: [user getUProfileId]];

		jReportsSubMenu = [JSubMenu new];

		[myMainMenu addMenuItem: jReportsSubMenu];
		[jReportsSubMenu setCaption: getResourceStringDef(RESID_REPORTS_MENU, "Reportes")];

		if ([profile hasPermission: OPERATOR_REPORT_OP]){
			// Operator Report
			jMenu = [JActionMenu new];
			[jMenu initActionMenu: getResourceStringDef(RESID_OPERATOR_MENU, "Operador") object: self action: "jOperatorReportMenu_Click"];
			[jReportsSubMenu addMenuItem: jMenu];
		}

		if ([profile hasPermission: GRAND_Z_REPORT_OP]){
			// Ver cierre Z actual
			jMenu = [JActionMenu new];
			[jMenu initActionMenu: getResourceStringDef(RESID_END_DAY_MENU, "Cierre Diario") object: self action: "jGenerateZCloseMenu_Click"];
			[jReportsSubMenu addMenuItem: jMenu];
		}

		if ([profile hasPermission: ENROLLED_USER_REPORT_OP]){
			// Enrolled Users
			jMenu = [JActionMenu new];
			[jMenu initActionMenu: getResourceStringDef(RESID_ENROLLED_USERS_MENU, "Usuarios Activos") object: self action: "jEnrolledUsersReportMenu_Click"];
			[jReportsSubMenu addMenuItem: jMenu];
		}

		if ([profile hasPermission: AUDIT_REPORT_OP]){
			// Audit Report
			jMenu = [JActionMenu new];
			[jMenu initActionMenu: getResourceStringDef(RESID_AUDIT_REPORT_MENU, "Rep. Auditoria") object: self action: "jAuditReportMenu_Click"];
			[jReportsSubMenu addMenuItem: jMenu];
		}

		if ([profile hasPermission: CASH_REPORT_OP]){
			// Cash Report
			cashSubMenu = [JSubMenu new];
			[cashSubMenu setCaption: getResourceStringDef(RESID_CASH_REPORT_MENU, "Reporte de Cash")];
			[jReportsSubMenu addMenuItem: cashSubMenu];
				
				// By Door
				byDoorMenu = [JActionMenu new];    
				[byDoorMenu initActionMenu: getResourceStringDef(RESID_CASH_REPORT_BY_DOOR_MENU, "Por Puerta") object: self action: "jCurrentExtractionByDoorMenu_Click"]; 
				[cashSubMenu addMenuItem: byDoorMenu];
				
				// By Cash
				byCashMenu = [JActionMenu new];    
				[byCashMenu initActionMenu: getResourceStringDef(RESID_CASH_REPORT_BY_CASH_MENU, "Por Cash") object: self action: "jCurrentExtractionByCashMenu_Click"];
				[cashSubMenu addMenuItem: byCashMenu];
		}


		if ([profile hasPermission: GRAND_X_REPORT_OP]){
			// Grand X
			jMenu = [JActionMenu new];
			[jMenu initActionMenu: getResourceStringDef(RESID_GRAND_X_MENU, "Cierre X") object: self action: "jViewZCloseMenu_Click"];
			[jReportsSubMenu addMenuItem: jMenu];
		}

		if ([profile hasPermission: REFERENCE_REPORT_OP]){
			// Cash Reference
			jMenu = [JActionMenu new];
			[jMenu initActionMenu: getResourceStringDef(RESID_REFERENCE_REPORT_MENU, "Rep. Reference") object: self action: "jCashReferenceReportMenu_Click"];
			[jReportsSubMenu addMenuItem: jMenu];
		}

		if ([profile hasPermission: SYSTEM_INFO_REPORT_OP]){
			// Info del sistema
			jMenu = [JActionMenu new];
			[jMenu initActionMenu: getResourceStringDef(RESID_SYSTEM_INFO_MENU, "Inf. de Sistema") object: self action: "jSystemInfoMenu_Click"];
			[jReportsSubMenu addMenuItem: jMenu];
		}

		if ([profile hasPermission: TELESUP_REPORT_OP]){
			// Reporte Configuracion de Supervision
			jMenu = [JActionMenu new];
			[jMenu initActionMenu: getResourceStringDef(RESID_CONFIG_TELESUP_REPORT_MENU, "Rep. Telesup.") object: self action: "jReportConfTelesupMenu_Click"];	
			[jReportsSubMenu addMenuItem: jMenu];
		}

		if ([profile hasPermission: REPRINT_DROP_OP]){
			// Reimpresion de deposito
			jMenu = [JActionMenu new];
			[jMenu initActionMenu: getResourceStringDef(RESID_REPRINT_DEP_MENU, "Reimp. Deposito") object: self action: "jReprintDepositMenu_Click"];
			[jReportsSubMenu addMenuItem: jMenu];
		}

		if ([profile hasPermission: REPRINT_DEPOSIT_OP]){
			// Reimpresion de extraccion
			jMenu = [JActionMenu new];
			[jMenu initActionMenu: getResourceStringDef(RESID_REPRINT_EXT_MENU, "Reimp. Retiro") object: self action: "jReprintExtractionMenu_Click"];
			[jReportsSubMenu addMenuItem: jMenu];
		}

		if ([profile hasPermission: REPRINT_END_DAY_OP]){
			// Reimpresion de Cierre Z
			jMenu = [JActionMenu new];
			[jMenu initActionMenu: getResourceStringDef(RESID_REPRINT_END_DAY, "Reimp. C. Diario") object: self action: "jReprintZCloseMenu_Click"];
			[jReportsSubMenu addMenuItem: jMenu];

			// Reimpresion de Cierre Parcial
			jMenu = [JActionMenu new];
			[jMenu initActionMenu: getResourceStringDef(RESID_REPRINT_PARTIAL_DAY, "Reimp. C Parcial") object: self action: "jReprintXCloseMenu_Click"];
			[jReportsSubMenu addMenuItem: jMenu];
		}

		// @TODO PONER PERMISOS DE REPORTE DE MODULOS
		// Module licence
		jMenu = [JActionMenu new];
		[jMenu initActionMenu: getResourceStringDef(RESID_MODULE_REPORT_MENU, "Modulos") object: self action: "jGenerateModuleLicenceMenu_Click"];
		[jReportsSubMenu addMenuItem: jMenu];

		// Backup
		jMenu = [JActionMenu new];
		[jMenu initActionMenu: getResourceStringDef(RESID_BACKUP_MENU, "BackUp") object: self action: "jGenerateBackupMenu_Click"];
		[jReportsSubMenu addMenuItem: jMenu];

	}

}

/**/
- (void) jRepairOrderMenu_Click
{
 	id form;

	if ([[[RepairOrderManager getInstance] getRepairOrderItems] size] == 0) {
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_NO_REPAIR_ITEMS, "No existen items de reparacion.")];
		return;
	}

	form = [JRepairOrderForm createForm: self];
	[form showModalForm];
	[form free];

}

/**/
- (void) jStateChangeMenu_Click
{
 	id form;

	form = [JCommercialStateChangeForm createForm: self];
	[form showModalForm];

	[form free];

}


/**/
- (void) restore: (char *) aTableName 
	recordset: (ABSTRACT_RECORDSET) aRecordSet
	message: (char *) aMessage
	
{
	/*JFORM progressForm;

	progressForm = [JProgressBarForm new];
	[progressForm setFilled: TRUE];
	[progressForm setTitle: getResourceStringDef(RESID_RESTORING_DATA_MSG, "Restoring...")];
	[progressForm setCallBack: [CimBackup getInstance] callBack: "restore"];
	[progressForm setCaption: aMessage];
	[progressForm setCaption2: ""];*/

	[aRecordSet open];
	[[CimBackup getInstance] setRestoreFile: aTableName destRS: aRecordSet];
	[[CimBackup getInstance] restore];
	//[progressForm showModalForm];
	//[progressForm free];
	[aRecordSet free];
}

- (void) jRestoreDataMenu_Click
{
	id infoViewer;
	RestoreType restoreType = RestoreType_UNDEFINED;
	BOOL endResore = TRUE;
	JFORM progressForm;

  // detengo el timer
  [myTimer stop];

	if ([[TelesupScheduler getInstance] inTelesup]) {
		[JMessageDialog askOKMessageFrom: self 
			withMessage: getResourceStringDef(RESID_TELESUP_IN_PROGRESS, "Existe una supervision en progreso!")];
		return;
	}

	// verifico que los datos a recuperar no esten daniados. Si lo estan le suguiero hacer
	// el backup correspondiente y no lo dejo avanzar hasta que todo este OK.
	if (![[CimBackup getInstance] isCheckTablesOk]) {

		if (![[CimBackup getInstance] isBackupTransactionsFailure]) {
			if ([[CimBackup getInstance] getSuggestedBackup] == BackupType_SETTINGS)
				[JMessageDialog askOKMessageFrom: NULL withMessage: getResourceStringDef(RESID_BACKUP_TABLE_SETTINGS_ERROR, "Backup incompleto. Se sugiere ejecutar Backup-Configuracion")];
	
			if ([[CimBackup getInstance] getSuggestedBackup] == BackupType_USERS)
				[JMessageDialog askOKMessageFrom: NULL withMessage: getResourceStringDef(RESID_BACKUP_TABLE_USERS_ERROR, "Backup incompleto. Se sugiere ejecutar Backup-Usuarios")];
			
			return;
		} else {
			[JMessageDialog askOKMessageFrom: NULL withMessage: getResourceStringDef(RESID_BACKUP_TABLE_ALL_ERROR, "Backup incompleto. Se sugiere ejecutar Backup-Completo")];
			return;
		}
	}

	// verifico que las tablas de transacciones esten ok
	if ([[CimBackup getInstance] isBackupTransactionsFailure]) {
		if (![[CimBackup getInstance] isBackupManualTransFailure]) {
			[JMessageDialog askOKMessageFrom: NULL withMessage: getResourceStringDef(RESID_BACKUP_TABLE_TRANSACTIONS_ERROR, "Backup incompleto. Se sugiere ejecutar Backup-Transacciones")];
		} else {
			[JMessageDialog askOKMessageFrom: NULL withMessage: getResourceStringDef(RESID_BACKUP_TABLE_MANUAL_TRANSACTIONS_ERROR, "Backup incompleto. Se sugiere ejecutar Backup-Manual")];
		}
		return;
	}

  // selecciono el tipo de RESTORE a realizar
  restoreType = [UICimUtils selectRestoreType: self title: getResourceStringDef(RESID_SELECT_BACKUP_OPTION_LABEL, "Seleccione Opcion:")];

	if (restoreType == RestoreType_UNDEFINED) return;

  if ([JMessageDialog askYesNoMessageFrom: self 
		withMessage: getResourceStringDef(RESID_RESTORE_DATA_QUIESTION, "Restaurar datos... Esta seguro?")]  != JDialogResult_YES) return;

	// detengo el timer nuevamente pues se activa luego del askYesNoMessageFrom
	[myTimer stop];

	TRY

		endResore = TRUE;
		progressForm = [JProgressBarForm new];
		[progressForm setFilled: TRUE];
		[progressForm setTitle: getResourceStringDef(RESID_RESTORING_DATA_MSG, "Restoring...")];
		[progressForm setCaption2: ""];

		[[CimBackup getInstance] beginRestore];
		// indico la cantidad de tablas a procesar para poder mostrar la barra de progreso
		[[CimBackup getInstance] setRestoreTableCount: restoreType];
		[[CimBackup getInstance] setObserver: progressForm];

		[progressForm showForm];

		// hago restore de transacciones
		if ((restoreType == RestoreType_ALL) || (restoreType == RestoreType_TRANSACTIONS)) {

			// elimino los datos de las tablas locales
			[[[Persistence getInstance] getAuditDAO] deleteAll];
			[[[Persistence getInstance] getDepositDAO] deleteAll];
			[[[Persistence getInstance] getExtractionDAO] deleteAll];
			[[[Persistence getInstance] getZCloseDAO] deleteAll];

			// AUDITORIAS --------------------------------------------
			[progressForm setCaption: "audits..."];
			[progressForm setCaption2: ""];
			[self restore: "audits" 
				recordset: [[[Persistence getInstance] getAuditDAO] getNewAuditsRecordSet]
				message: "audits..."];
	
			[progressForm setCaption: "audit details..."];
			[progressForm setCaption2: ""];
			[self restore: "change_log" 
				recordset: [[[Persistence getInstance] getAuditDAO] getNewChangeLogRecordSet]
				message: "audit details..."];
	
			// DEPOSITOS --------------------------------------------
			[progressForm setCaption: "drops..."];
			[progressForm setCaption2: ""];
			[self restore: "deposits" 
				recordset: [[[Persistence getInstance] getDepositDAO] getNewDepositRecordSet]
				message: "drops..."];

			[progressForm setCaption: "drop details..."];
			[progressForm setCaption2: ""];
			[self restore: "deposit_details" 
				recordset: [[[Persistence getInstance] getDepositDAO] getNewDepositDetailRecordSet]
				message: "drop details..."];
		
			// EXTRACCIONES --------------------------------------------
			[progressForm setCaption: "deposits..."];
			[progressForm setCaption2: ""];
			[self restore: "extractions" 
				recordset: [[[Persistence getInstance] getExtractionDAO] getNewExtractionRecordSet]
				message: "deposits..."];

			[progressForm setCaption: "deposit details..."];
			[progressForm setCaption2: ""];
			[self restore: "extraction_details" 
				recordset: [[[Persistence getInstance] getExtractionDAO] getNewExtractionDetailRecordSet]
				message: "deposit details..."];
	
			// CIERRES Z --------------------------------------------
			[progressForm setCaption: "zcloses..."];
			[progressForm setCaption2: ""];
			[self restore: "zclose" 
				recordset: [[[Persistence getInstance] getZCloseDAO] getNewZCloseRecordSet]
				message: "zcloses..."];
		}

		// hago restore de seteos y/o usuarios segun corresponda
		if ((restoreType == RestoreType_ALL) || (restoreType == RestoreType_SETTINGS) || (restoreType == RestoreType_USERS)) {

			// primero hago el dump de las tablas a /var/data
			[[CimBackup getInstance] dumpTablesToRestore: restoreType];

			// reemplazo cada una de las tablas en /rw/CT8016/data
			if ([[CimBackup getInstance] replaceRestoredTablesToDB: restoreType])
				//doLog(0,"restauracion de tablas OK ****\n");
                ;
			else {
				endResore = FALSE;
				//doLog(0,"restauracion de tablas ERROR ****\n");
			}
		}

		[progressForm advanceTo: 100];
		[progressForm setCaption: ""];
		[progressForm setCaption2: ""];

		[[CimBackup getInstance] setObserver: NULL];
		[progressForm closeForm];
		[progressForm free];

		// finalizo el restore
		if (endResore) [[CimBackup getInstance] endRestore];

	CATCH

		[[CimBackup getInstance] setObserver: NULL];
		[progressForm closeForm];
		[progressForm free];

		// muestro mensaje de error
		[JMessageDialog askOKMessageFrom: NULL withMessage: getResourceStringDef(RESID_RESTORE_DATA_ERROR, "Error al restaurar datos!. El equipo sera reiniciado.")];

	END_TRY

	// reinicio
  infoViewer = [JInfoViewerForm createForm: NULL];
	[infoViewer setCaption: getResourceStringDef(RESID_REBOOTING, "Reiniciando...")];
	[infoViewer showModalForm];
	
	exit(23);

}

/**/
- (void) jBackupManual_Click
{
  JFORM splashBackupForm;

  // detengo el timer
  [myTimer stop];

	if ([[TelesupScheduler getInstance] inTelesup]) {
		[JMessageDialog askOKMessageFrom: self 
			withMessage: getResourceStringDef(RESID_TELESUP_IN_PROGRESS, "Existe una supervision en progreso!")];
		return;
	}

	// si detecto que viene de un restore fallido no lo dejo hacer un backup
	if ([[CimBackup getInstance] isRestoreFailure]) {
		[JMessageDialog askOKMessageFrom: NULL 
			withMessage: getResourceStringDef(RESID_RESTORE_DATA_FAILURE, "Restauracion de datos incompleta. Restaure todo.")];
		return;
	}

	if ([JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_BACKUP_MANUAL_QUESTION, "The process can delay. Do you want to start it?")] == JDialogResult_YES) {

		// detengo el timer nuevamente pues se activa luego del askYesNoMessageFrom
		[myTimer stop];

		splashBackupForm = [JSplashBackupForm createForm: self];

		TRY

			[splashBackupForm refreshScreen];
			[splashBackupForm setReinitFiles: FALSE];
			[splashBackupForm setBackupType: BackupType_TRANSACTIONS];
			[splashBackupForm showModalForm];

		FINALLY

			[splashBackupForm free];		

		END_TRY;
	}

}

/**/
- (void) jBackupFull_Click
{
  JFORM splashBackupForm;
	BackupType backUpType = BackupType_UNDEFINED;

  // detengo el timer
  [myTimer stop];

	if ([[TelesupScheduler getInstance] inTelesup]) {
		[JMessageDialog askOKMessageFrom: self 
			withMessage: getResourceStringDef(RESID_TELESUP_IN_PROGRESS, "Existe una supervision en progreso!")];
		return;
	}

	// si detecto que viene de un restore fallido no lo dejo hacer un backup
	if ([[CimBackup getInstance] isRestoreFailure]) {
		[JMessageDialog askOKMessageFrom: NULL 
			withMessage: getResourceStringDef(RESID_RESTORE_DATA_FAILURE, "Restauracion de datos incompleta. Restaure todo.")];
		return;
	}

  // selecciono el tipo de backups a realizar
  backUpType = [UICimUtils selectBackupType: self title: getResourceStringDef(RESID_SELECT_BACKUP_OPTION_LABEL, "Seleccione Opcion:")];

	if (backUpType == BackupType_UNDEFINED) return;

	if ([JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_BACKUP_MANUAL_QUESTION, "The process can delay. Do you want to start it?")] == JDialogResult_YES) {

		// detengo el timer nuevamente pues se activa luego del askYesNoMessageFrom
		[myTimer stop];

		splashBackupForm = [JSplashBackupForm createForm: self];

		TRY

			[splashBackupForm refreshScreen];

			switch (backUpType) {
				case BackupType_ALL:
								[splashBackupForm setBackupType: BackupType_ALL];
								break;
				case BackupType_TRANSACTIONS:
								[splashBackupForm setReinitFiles: TRUE];
								[splashBackupForm setBackupType: BackupType_TRANSACTIONS];
								break;
				case BackupType_SETTINGS:
								[splashBackupForm setBackupType: BackupType_SETTINGS];
								break;
				case BackupType_USERS:
								[splashBackupForm setBackupType: BackupType_USERS];
								break;
			}

			[splashBackupForm showModalForm];

		FINALLY

			[splashBackupForm free];		

		END_TRY;
	}
}

/** Inicializa el servicio inetd para poder aceptar conexion entrantes telnet y FTP */
- (void) jStartInetd_Click
{
	[Audit auditEventCurrentUser: Event_RESTART_INETD additional: "" station: 0 logRemoteSystem: FALSE];
	system("inetd &");
	[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_INETD_STARTED, "inetd started!")];
}

/** Escribe la configuracion de la placa a un data.tar para visualizarlo */
- (void) jDumpTables_Click
{
	JFORM processForm;

	[Audit auditEventCurrentUser: Event_DUMP_SETTINGS additional: "" station: 0 logRemoteSystem: FALSE];

  processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];

	TRY
		[[CimBackup getInstance] dumpTables];
	CATCH
		ex_printfmt();
	END_TRY

	[processForm closeProcessForm];
	[processForm free];

	[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_DUMP_SETTINGS_FINISH, "Dump finish!")];
}

/**/
- (void) configureAdminMenu
{
	JACTION_MENU jMenu;
	JSUB_MENU jAdminSubMenu;
	JSUB_MENU jrebootSubMenu;
	JSUB_MENU jSimCardSubMenu;
	JSUB_MENU jBackupSubMenu;
	USER user = NULL;
	PROFILE profile = NULL;

	// si esta funcionando con hardware secundario no creo los menues  
  if ([UICimUtils canMakeDeposits]){
      
    user = [[UserManager getInstance] getUserLoggedIn];
		if (!user) return;
    profile = [[UserManager getInstance] getProfile: [user getUProfileId]];      

		// Menu Admin 
		jAdminSubMenu = [JSubMenu new];
		[jAdminSubMenu setCaption: getResourceStringDef(RESID_SYSTEM_MENU, "System")];
	
		// Agrega el submenu al MainMenu
		[myMainMenu addMenuItem: jAdminSubMenu]; 	


		// Menu Admin: Backup
		jBackupSubMenu = [JSubMenu new];
		[jBackupSubMenu setCaption: getResourceStringDef(RESID_BACKUP_MENU, "BackUp")];
		[jAdminSubMenu addMenuItem: jBackupSubMenu];

			// Menu Admin : Backup : Manual
				jMenu = [[JActionMenu new] initActionMenu: getResourceStringDef(RESID_BACKUP_MANUAL_MENU, "Manual")
				object: self action: "jBackupManual_Click"];
			[jBackupSubMenu addMenuItem: jMenu];
			
			// Menu Admin : Backup : Full
			jMenu = [[JActionMenu new] initActionMenu: getResourceStringDef(RESID_BACKUP_FULL_MENU, "Full")
				object: self action: "jBackupFull_Click"];
			[jBackupSubMenu addMenuItem: jMenu];

		// Menu Admin : Restaurar datos
		if ([profile hasPermission: RESTORE_OP]){
			jMenu = [JActionMenu new];
			[jMenu initActionMenu: getResourceStringDef(RESID_RESTORE_DATA_MENU, "Restaurar Datos") 
				object: self action: "jRestoreDataMenu_Click"];
			[jAdminSubMenu addMenuItem: jMenu];
		}

		// Menu Admin : Reboot
		if ([profile hasPermission: REBOOT_OP]){

			jrebootSubMenu = [JSubMenu new];
			[jrebootSubMenu setCaption: getResourceStringDef(RESID_REBOOT_MENU, "Reiniciar")];
			[jAdminSubMenu addMenuItem: jrebootSubMenu];

			// Menu Admin : Reboot : Aplicacion
			jMenu = [[JActionMenu new] initActionMenu: getResourceStringDef(RESID_REBOOT_APPLICATION_MENU, "Aplicacion")
				object: self action: "onCloseApp_Click"];
			[jrebootSubMenu addMenuItem: jMenu];
			
			// Menu Admin : Reboot : Sistema operativo
			jMenu = [[JActionMenu new] initActionMenu: getResourceStringDef(RESID_REBOOT_OPERATING_SYSTEM_MENU, "Sist. Operativo")
				object: self action: "onCloseOperatingSystem_Click"];
			[jrebootSubMenu addMenuItem: jMenu];  	    

		}

		// Menu Admin: Shutdown
		if ([profile hasPermission: SHUTDOWN_OP]){
			jMenu = [[JActionMenu new] initActionMenu: getResourceStringDef(RESID_SHUTDOWN, "Apagar equipo")
				object: self action: "jShutdownMenu_Click"];
			[jAdminSubMenu addMenuItem: jMenu];
		}

		// Menu Admin: Apagado de buzzer
		jMenu = [[JActionMenu new] initActionMenu: getResourceStringDef(RESID_TURN_OFF_BUZZER_MENU, "Silenciar buzzer")
			object: self action: "jTurnOffBuzzerMenu_Click"];
		[jAdminSubMenu addMenuItem: jMenu];

		// Menu Admin: Dump tables
		if ([profile hasPermission: DUMP_SETTINGS_OP]) {
			jMenu = [[JActionMenu new] initActionMenu: getResourceStringDef(RESID_DUMP_SETTINGS_MENU, "Dump Settings") 
				object: self action: "jDumpTables_Click"];
			[jAdminSubMenu addMenuItem: jMenu];
		}
	
		// Menu Admin: Iniciar inetd
		if ([profile hasPermission: NETWORK_SETTINGS_OP]) {
			jMenu = [[JActionMenu new] initActionMenu: getResourceStringDef(RESID_RESTART_INETD_MENU, "Restart inetd") 
				object: self action: "jStartInetd_Click"];
			[jAdminSubMenu addMenuItem: jMenu];
		}

		// Menu Admin: Test de Hardware
		if ([profile hasPermission: RUN_HARDWARE_TEST_OP]) {
			jMenu = [[JActionMenu new] initActionMenu: getResourceStringDef(RESID_HARDWARE_TEST_MENU, "Hardware Test") 
				object: self action: "onHardwareTest_Click"];
			[jAdminSubMenu addMenuItem: jMenu];
		}

		// Menu Admin: Test de Hardware
		if ([profile hasPermission: SIM_CARD_CONFIG_OP]) {

			// Menu SIM Card
			jSimCardSubMenu = [JSubMenu new];
			[jSimCardSubMenu setCaption: getResourceStringDef(RESID_SIM_CARD_MENU, "SIM Card")];
		
			// Agrega el submenu al MainMenu
			[jAdminSubMenu addMenuItem: jSimCardSubMenu]; 	

			jMenu = [[JActionMenu new] initActionMenu: getResourceStringDef(RESID_CHANGE_SIM_CARD_PIN_MENU, "Change PIN") 
				object: self action: "onSimCardChangePin_Click"];
			[jSimCardSubMenu addMenuItem: jMenu];

			jMenu = [[JActionMenu new] initActionMenu: getResourceStringDef(RESID_PIN_LOCK_UNLOCK_MENU, "PIN Lock/Unlock") 
				object: self action: "onSimCardPinRequest_Click"];
			[jSimCardSubMenu addMenuItem: jMenu];

		}

		// Menu Admin: Test de Supervision
		jMenu = [[JActionMenu new] initActionMenu: getResourceStringDef(RESID_SUPERVISION_TEST_MENU, "Probar Superv.")
			object: self action: "onSupervisionTestMenu_Click"];
		[jAdminSubMenu addMenuItem: jMenu];

/*
		// Menu Admin: Test de Supervision
		jMenu = [[JActionMenu new] initActionMenu: "Test 1"
			object: self action: "onTestMenu_Click"];
		[jAdminSubMenu addMenuItem: jMenu];


		// Menu Admin: Test de Supervision
		jMenu = [[JActionMenu new] initActionMenu: "Test 2"
			object: self action: "onTest2Menu_Click"];
		[jAdminSubMenu addMenuItem: jMenu];
*/
	}

}

/**/
- (void) hangupGprsConnection
{
	TELESUP_SETTINGS telesup;
	int i=0;
	char sys[30];
	int status;

	telesup = [[TelesupScheduler getInstance] getMainTelesup];
	if (telesup == NULL) return;
	if ([[telesup getConnection1] getConnectionType] != ConnectionType_GPRS) return;

	// Si el COM esta tomado lo desconecto
  status = system(BASE_PATH "/bin/ppptest");
  //doLog(0,"Valor retornado %d\n",status);

  if (status) {

		sprintf(sys, BASE_PATH "/bin/colgar %s", "gprs");
   	system(sys);

		for (i = 0; i < 10; ++i) {
    	msleep(1);
      status = system(BASE_PATH "/bin/ppptest");
			if (status == 0) break;
    }
  }

}

- (SIM_CARD_VALIDATOR) getSimCardValidator
{
	int portNumber;
	int connectionSpeed;
	TELESUP_SETTINGS telesup;
	SIM_CARD_VALIDATOR simCardValidator;

	if ([[TelesupScheduler getInstance] inTelesup]) {
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_CANNOT_CHANGE_PIN_WITH_SUPERVISION, "Cannot change PIN, supervision in progress!")];
		return NULL;
	}

	telesup = [[TelesupScheduler getInstance] getMainTelesup];
	if (telesup == NULL || [[telesup getConnection1] getConnectionType] != ConnectionType_GPRS) {
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_INEXISTENT_GPRS_TELESUP, "Debe exitir una supervision GPRS dada de alta!")];
		return NULL;
	}

	portNumber = [[telesup getConnection1] getConnectionPortId];
	connectionSpeed = [[telesup getConnection1] getConnectionSpeed];
	simCardValidator = [SimCardValidator getInstance];
	[simCardValidator setPortNumber: portNumber];
	[simCardValidator setConnectionSpeed: connectionSpeed];

	return simCardValidator;
}

/**/
- (void) onSimCardChangePin_Click
{
	char oldPin[20];
	char newPin[20];
	char confirmPin[20];
	SIM_CARD_VALIDATOR simCardValidator;
	JFORM processForm;
	BOOL result;

	simCardValidator = [self getSimCardValidator];
	if (simCardValidator == NULL) return;

  processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];
	[self hangupGprsConnection];

	result = [simCardValidator openSimCard];

	[processForm closeProcessForm];
	[processForm free];

	if (!result) {
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_GPRS_MODEM_ERROR, "Error querying GPRS Modem")];
		return;
	}

	if (![simCardValidator isSimCardLocked]) {
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_SIM_CARD_IS_UNLOCKED, "SIM Card is currently unlocked!")];
		return;
	}

	if ([UICimUtils askForPassword: self
		result: oldPin
		title: getResourceStringDef(RESID_CHANGE_SIM_CARD_PIN, "Change PIN")
		message: getResourceStringDef(RESID_SIM_CARD_OLD_PIN, "Old PIN:")]) {

		if ([UICimUtils askForPassword: self
			result: newPin
			title: getResourceStringDef(RESID_CHANGE_SIM_CARD_PIN, "Change PIN")
			message: getResourceStringDef(RESID_SIM_CARD_NEW_PIN, "New PIN:")]) {

			if ([UICimUtils askForPassword: self
				result: confirmPin
				title: getResourceStringDef(RESID_CHANGE_SIM_CARD_PIN, "Change PIN")
				message: getResourceStringDef(RESID_SIM_CARD_CONFIRM_PIN, "Confirm PIN:")]) {

				if (strcmp(confirmPin, newPin) != 0) {

					[JMessageDialog askOKMessageFrom: self 
						withMessage: getResourceStringDef(RESID_SIM_PIN_NOT_MATCH, "New PIN does not match Confirm PIN!")];

				} else {
					if ([simCardValidator changeSimCardPin: oldPin newPin: newPin]) {
						[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_SIM_CARD_PIN_CHANGE_OK, "PIN changed successfully!")];
						[Audit auditEventCurrentUser: Event_SIM_CARD_CHANGE_PIN additional: "" station: 0 logRemoteSystem: FALSE];
		
					} else {
						[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_SIM_CARD_PIN_CHANGE_ERROR, "Error changing PIN!")];
					}
				}
			}
		}
	}

	[simCardValidator close];

}

/**/
- (void) onSimCardPinRequest_Click
{
	SIM_CARD_VALIDATOR simCardValidator;
	BOOL lock = FALSE;
	BOOL unLock = FALSE;
	BOOL result;
	JFORM processForm;
	char pin[20];

	simCardValidator = [self getSimCardValidator];
	if (simCardValidator == NULL) return;

  processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];
	[self hangupGprsConnection];

	result = [simCardValidator openSimCard];

	[processForm closeProcessForm];
	[processForm free];

	if (!result) {
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_GPRS_MODEM_ERROR, "Error querying GPRS Modem")];
		return;
	}

	if ([simCardValidator isSimCardLocked]) {
		unLock = [JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_SIM_CARD_LOCKED, "SIM Card is locked. Do you want to unlock it?")] == JDialogResult_YES;
	} else {
		lock = [JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_SIM_CARD_UNLOCKED, "SIM Card is unlocked. Do you want to lock it?")] == JDialogResult_YES;
	}

	if (lock || unLock) {

		if ([UICimUtils askForPassword: self
					result: pin
					title: getResourceStringDef(RESID_PIN_REQUIRED, "PIN Required")
					message: getResourceStringDef(RESID_ENTER_PIN, "Enter PIN:")]) {
			
			/**/
			if (lock) {
		
				result = [simCardValidator lockSimCard: TRUE pin: pin];
		
				if (result) {
					[JMessageDialog askOKMessageFrom: self 
						withMessage: getResourceStringDef(RESID_SIM_CARD_LOCK_OK, "SIM Card lock successfully!")];
					[Audit auditEventCurrentUser: Event_SIM_CARD_LOCKED additional: "" station: 0 logRemoteSystem: FALSE];
		
				} else {
					[JMessageDialog askOKMessageFrom: self 
						withMessage: getResourceStringDef(RESID_SIM_CARD_LOCK_ERROR, "SIM Card lock error!")];
				}
		
			} else if (unLock) {
		
				result = [simCardValidator lockSimCard: FALSE pin: pin];
				if (result) {
					[JMessageDialog askOKMessageFrom: self 
						withMessage: getResourceStringDef(RESID_SIM_CARD_UNLOCK_OK, "SIM Card unlock successfully!")];
					[Audit auditEventCurrentUser: Event_SIM_CARD_LOCKED additional: "" station: 0 logRemoteSystem: FALSE];
		
				} else {
					[JMessageDialog askOKMessageFrom: self 
						withMessage: getResourceStringDef(RESID_SIM_CARD_UNLOCK_ERROR, "SIM Card unlock error!")];
				}
			}
		}
	}

	[simCardValidator close];
}

/**/
- (void) configureMainMenu
{	
	JACTION_MENU jValidateBillMenu, jManualTelesupMenu, jUserLogOffMenu, jInstaDropMenu,
		jExtendedDropMenu, jRepairOrderMenu, jStateChangeMenu, jInformExtrMenu;

  volatile PROFILE profile = NULL;
  BOOL primaryHardwareOK;
  USER user = NULL;

	// si esta funcionando con hardware secundario no creo los menues salvo door access
  primaryHardwareOK = [UICimUtils canMakeDeposits];
	
  // obtengo el usuario logueado para ver los permisos que tiene y asi habilitar las opciones de menu
  if (primaryHardwareOK){
    user = [[UserManager getInstance] getUserLoggedIn];
		if (!user) return;
    profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
  }
  
   TRY
		
	/* Esto porque no me anda bien el tema de los visible invisible */
	[myMainMenu hastaNuncaMalditosItems];

	/*
	* Creacion de los submenues que conforman la rama principal del arbol. 
	*/

	// Validacion de billetes
	if (primaryHardwareOK){
      	jValidateBillMenu = [JActionMenu new];
  			[jValidateBillMenu initActionMenu: getResourceStringDef(RESID_VALIDATE_BILL_MENU, "Valid de billete") object: self action: "jValidateBillMenu_Click"];
      	[myMainMenu addMenuItem: jValidateBillMenu];
    	}

		if ((primaryHardwareOK) && ([profile hasPermission: VALIDATED_DROP_OP])) {

      // Validated Drop
      jDepositMenu = [JActionMenu new];
      [jDepositMenu initActionMenu: getResourceStringDef(RESID_DEPOSIT, "Deposito Valid") object: self action: "jDepositMenu_Click"];
      [myMainMenu addMenuItem: jDepositMenu];
    }
        
    if ((primaryHardwareOK) && ([profile hasPermission: MANUAL_DROP_OP])) {

  		// Manual Drop
      jManualDepositMenu = [JActionMenu new];
      [jManualDepositMenu initActionMenu: getResourceStringDef(RESID_MANUAL_DROP_MENU, "Deposito Manual") object: self action: "jManualDepositMenu_Click"];
      [myMainMenu addMenuItem: jManualDepositMenu];
    }
		
		if ((primaryHardwareOK) && ([profile hasPermission: INSTADROP_CONFIG_OP])) {
      // Insta Drop
      jInstaDropMenu = [JActionMenu new];
      [jInstaDropMenu initActionMenu: getResourceStringDef(RESID_INSTA_DROP_MENU, "Deposito Rapido") object: self action: "jInstaDropMenu_Click"];
      [myMainMenu addMenuItem: jInstaDropMenu];
    }

		if ((primaryHardwareOK) && ([profile hasPermission: EXTENDED_DROP_CONFIG_OP])) { 
      // Extended Drop
      jExtendedDropMenu = [JActionMenu new];
      [jExtendedDropMenu initActionMenu: getResourceStringDef(RESID_EXTENDED_DROP_MENU, "Dep. Extendido") object: self action: "jExtendedDropMenu_Click"];
      [myMainMenu addMenuItem: jExtendedDropMenu];
    }

	// Acceso a puertas
	if ((!(primaryHardwareOK) || ([profile hasPermission: OPEN_DOOR_OP])) && (![[[CimManager getInstance] getCim] isTransferenceBoxMode])){
				//doLog(0,"\nModo -> Door Acces\n");
  			jDoorAccessMenu = [JActionMenu new];
  			[jDoorAccessMenu initActionMenu: getResourceStringDef(RESID_DOOR_ACCESS_MENU, "Acceso a Puertas") object: self action: "jDoorAccessMenu_Click"];
  			[myMainMenu addMenuItem: jDoorAccessMenu];
	}
				
	//Informar Retiro
	if ((!(primaryHardwareOK) || ([profile hasPermission: OPEN_DOOR_OP])) && ([[[CimManager getInstance] getCim] isTransferenceBoxMode])){
				//doLog(0,"\nModo -> Caja de Transferencia\n");
  			jInformExtrMenu = [JActionMenu new];
  			[jInformExtrMenu initActionMenu: getResourceStringDef(RESID_INFORM_EXTRACTION, "Informar Retiro") object: self action: "jInformExtrMenu_Click"];
  			[myMainMenu addMenuItem: jInformExtrMenu];
	}


	// Submenu de reportes
	[self configureReportsSubMenu];
		
	// Supervisiones
	if ((primaryHardwareOK) && (([profile hasPermission: SUPERVISION_OP]) || ([profile hasPermission: CMP_TELESUP_OP]))) {
      	jManualTelesupMenu = [JActionMenu new];
      	[jManualTelesupMenu initActionMenu: getResourceStringDef(RESID_SUPERVISION_MENU, "Supervision") object: self action: "jManualTelesupMenu_Click"];	
      	[myMainMenu addMenuItem: jManualTelesupMenu];
    	}

	// Creacion del submenu Configuracion general
	[self configureGeneralSettingsSubMenu];

	// Orden de Reparacion
  if ((primaryHardwareOK) && ([profile hasPermission: REPAIR_ORDER_OP])){
   	  	jRepairOrderMenu = [JActionMenu new];
   	  	[jRepairOrderMenu initActionMenu: getResourceStringDef(RESID_REPAIR_ORDER_MENU, "Orden reparacion") object: self action: "jRepairOrderMenu_Click"];
   	  	[myMainMenu addMenuItem: jRepairOrderMenu];
  	}

	// Cambio de estado
	if ((primaryHardwareOK) && ([profile hasPermission: STATE_CHANGE_OP])) {
	  	jStateChangeMenu = [JActionMenu new];
	  	[jStateChangeMenu initActionMenu: getResourceStringDef(RESID_COMMERCIAL_STATE_MENU, "Estado Comercial") object: self action: "jStateChangeMenu_Click"];
   		[myMainMenu addMenuItem: jStateChangeMenu];
	}

	// Cierre de sesion
	jUserLogOffMenu = [[JActionMenu new] initActionMenu: getResourceStringDef(RESID_CLOSE_SESSION_MENU, "Cerrar Sesion")object: self action: "onMenuItem_Logout_Click"];
	[myMainMenu addMenuItem: jUserLogOffMenu];

	// Submenu de administrador
	[self configureAdminMenu];

#ifdef _TEST_SUB_MENU
	[self configureTestSubMenu];
#endif

  FINALLY
	
	//	[self activateWindow];
	
	END_TRY;	
}


/**/
- (void) doNothing
{
}

/**/
- (void) jHeadersMenu_Click
{
	JFORM form;
  
  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];
     
 	form = [JHeaderEditForm createForm: self];
	[form showFormToView: [BillSettings getInstance]];
	[form free];	
}

/**/
- (void) jFootersMenu_Click
{
	JFORM form;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];
  	
 	form = [JFooterEditForm createForm: self];
	[form showFormToView: [BillSettings getInstance]];
	[form free];
}

/**/
- (void) jPrimterMenu_Click
{
	JFORM form;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];
  	
 	form = [JPrintingEditForm createForm: self];
	[form showFormToView: [PrintingSettings getInstance]];
	[form free];
}

/**/
- (void) jInstaDropMenu_Click
{
	JFORM form;
  
  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;
   
  // detengo el timer
  [myTimer stop];
   
 	form = [JInstaDropSettingsForm createForm: self];
	[form showModalForm];
	[form free];	
}

/**/
- (void) jNetworkSettingsMenu_Click
{
	JFORM form;
	
  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];
  	
	form = [JSystemConfigForm createForm: self];

	/** @todo: mejorar esto. es una chanchada */
	// Le paso un objeto cualquiera para evitarme el problema de los assert
	// que se estan controlando en el JEditForm
	[form showFormToView: [CimGeneralSettings getInstance]];
	[form free];
}

/**/
- (void) jRegionalSettingsMenu_Click
{
	JFORM form;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];
  	
 	form = [JRegionalSettingsEditForm createForm: self];
	[form showFormToView: [RegionalSettings getInstance]];
	[form free];	
}

/**/
- (void) jValidateBillMenu_Click
{
	JFORM form; 

	if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];

 	form = [JVerifyBillForm createForm: self];
	[form showModalForm];
	[form free];
}

/**/
- (void) jEnrolledUsersReportMenu_Click
{
	scew_tree *tree;
	int userStatus;
	EnrollOperatorReportParam userStatusParam;
	unsigned long auditNumber = 0;
  datetime_t auditDateTime = 0;
  int printType;
  JFORM processForm;
  
  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;
  
  // detengo el timer
  [myTimer stop];  
  
	userStatus = [UICimUtils selectCollectorUserStatus: self];
	if (userStatus == 0) return;

  // selecciono el tipo de impresion (detallado o resumido)
  printType = [UICimUtils selectPrintType: self title: getResourceStringDef(RESID_PRINT_TYPE_LABEL, "Tipo de impresion:")];
	switch (printType) {
		case ITEM_BACK_PRT_TYPE: return;
		case ITEM_SUMMARY_PRT_TYPE:
						userStatusParam.detailReport = FALSE;
						break;
		case ITEM_DETAILED_PRT_TYPE:
		        userStatusParam.detailReport = TRUE;
						break;
	}

	// Audito el evento
	auditDateTime = [SystemTime getLocalTime];
	auditNumber = [Audit auditEventCurrentUserWithDate: Event_ENROLLED_USER_REPORT additional: "" station: 0 datetime: auditDateTime logRemoteSystem: FALSE];

	userStatusParam.auditNumber = auditNumber;
	userStatusParam.auditDateTime = auditDateTime;
  //All 1 - Actives 2 - Inactives 3
	userStatusParam.userStatus = userStatus;

  processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_GENERATING_ENROLL_USER_REPORT, "Generando Reporte de Usuarios...")];
	
  TRY    
    tree = [[ReportXMLConstructor getInstance] buildXML: [UserManager getInstance] entityType: ENROLLED_USER_PRT isReprint: FALSE varEntity: &userStatusParam];
  	
  	[[PrinterSpooler getInstance] addPrintingJob: ENROLLED_USER_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
	FINALLY	  
		[processForm closeProcessForm];
		[processForm free];
	END_TRY
	
}

/**/
- (void) jAuditReportMenu_Click
{
  id form;
  
  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];
    
  form = [JAuditReportDateEditForm createForm: self];
  [form showModalForm];
  [form free];
}


/**/
- (void) jExtendedDropMenu_Click
{
	CIM_CASH cimCash;
	DEPOSIT extendedDrop;
	INSTA_DROP instaDrop;
	USER user = NULL;
	CASH_REFERENCE reference = NULL;
	char envelopeNumber[50];
	char applyTo[50];
	int edAction;
	JFORM form;	
	int usr;

	*envelopeNumber = '\0';
	*applyTo = '\0';	

  // si esta funcionando con hardware sevundario no lo dejo abanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];
	
	//Aca elige de la lista el cash:
	cimCash = [UICimUtils selectAutoCimCash: self];
	if (cimCash == NULL) return;

	extendedDrop = [[CimManager getInstance] getExtendedDrop: cimCash];

	// Ya existe el extendedDrop, doy la opcion de finalizarlo
	// sino lo abro
	if (extendedDrop) {

		edAction = [UICimUtils selectExtendedDropAction: self title: getResourceStringDef(RESID_SELECT_ACTION_LABEL, "Seleccione accion:")];
    
    switch (edAction)
    {
  		case ITEM_VEIW_DETAIL_EXT_DROP_ACTION:
        form = [JExtendedDropDetailForm createForm: self];
      	[form setDeposit: extendedDrop];
        [form showModalForm];
        [form free];        
        break;
      case ITEM_FINISH_EXT_DROP_ACTION: 
        if ([JMessageDialog askYesNoMessageFrom: self 
    				withMessage: getResourceStringDef(RESID_EXTENDED_DROP_IN_USE, "Confirma la eliminacion del Deposito Extendido?")] == JDialogResult_YES) {
    
    			[[CimManager getInstance] endExtendedDrop: cimCash];
    
    		}
    		break;
    }
    
    return;
	}

	// Verifico si ya esta asignado a un Insta Drop el cash seleccionado
	instaDrop = [[InstaDropManager getInstance] getInstaDropForCash: cimCash];

	if (instaDrop != NULL) {
		[JMessageDialog askOKMessageFrom: self 
				withMessage: getResourceStringDef(RESID_CASH_ALREADY_USE_INSTA, "El Cash ya se encuentra en uso por un Deposito Instantaneo.")];
		return;

	}

	//if (![UICimUtils canMakeDeposits: self]) return;
	[[CimManager getInstance] checkCimCashState: cimCash];

	//Agregado SOLEEE		
  	// Selecciono el Usuario
  	usr = [UICimUtils selectCurrentUserSelection: self title: getResourceStringDef(RESID_USERS_LABEL, "Operator:")];
  	
  	switch (usr) {
  		case ITEM_BACK: return;
  		case ITEM_ALL:		//Current User
              user = [[UserManager getInstance] getUserLoggedIn]; 
  						break;
  								
  		case ITEM_SELECT:  //Other user
				// Selecciona el Usuario
			user = [UICimUtils selectUserWithDropPermission: self];
			if (user == NULL) return;
  			break;
  	}   

	//FIN Agregado SOLEEE		

	// Solicito la referencia (si es que las utiliza)
	if ([[CimGeneralSettings getInstance] getUseCashReference]) {
		reference = [UICimUtils selectCashReference: self];
		if (reference == NULL) return;
	}

	// Solicito el APPLY TO (si corresponde)
	if ([[CimGeneralSettings getInstance] getAskApplyTo]) {

		if (![UICimUtils askApplyTo: self
			applyTo: applyTo
			title: getResourceStringDef(RESID_EXTENDED_DROP, "Deposito Extendido")
			description: getResourceStringDef(RESID_APPLIED_TO, "Aplicar a:")]) return;
	}

	// Se dan todas las condiciones, lo inicio
	[[CimManager getInstance] startExtendedDrop: user cimCash: cimCash cashReference: reference envelopeNumber: envelopeNumber applyTo: applyTo];
	
}

/**/
- (void) jViewZCloseMenu_Click
{
	JFORM processForm;

	if (![[CimGeneralSettings getInstance] getUseEndDay]) {
		[JMessageDialog askOKMessageFrom: self 
				withMessage: getResourceStringDef(RESID_USE_END_DAY_DISABLE, "Debe habilitar el parametro Use End Day")];
		return;
	}

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];

	processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_GENERATING_X_REPORT, "Generando Cierre X...")];

	TRY

		[[ZCloseManager getInstance] generateCurrentZClose];

	FINALLY

		[processForm closeProcessForm];
		[processForm free];

	END_TRY
}

/**/
- (void) jCashReferenceReportMenu_Click
{
	JFORM processForm;
	volatile BOOL detailReport = FALSE;
	int cRef;
	volatile CASH_REFERENCE reference = NULL;
	int printType;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];

	// Selecciono el Cash
	cRef = [UICimUtils selectCollectorSelection: self title: getResourceStringDef(RESID_SELECT_REFERENCE, "Selec Reference:")];
	
	switch (cRef) {
		case ITEM_BACK: return;
		case ITEM_ALL:
            reference = NULL; // lo pongo en NULL cuando selecciona ALL
						break;
								
		case ITEM_SELECT:
            reference = [UICimUtils selectCashReference: self];
            if (reference == NULL) return;
						break;
	}

  // selecciono el tipo de impresion (detallado o resumido)
  printType = [UICimUtils selectPrintType: self title: getResourceStringDef(RESID_PRINT_TYPE_LABEL, "Tipo de impresion:")];
	switch (printType) {
		case ITEM_BACK_PRT_TYPE: return;
		case ITEM_SUMMARY_PRT_TYPE:
						detailReport = FALSE;
						break;
		case ITEM_DETAILED_PRT_TYPE:
		        detailReport = TRUE;
						break;
	}

	processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_GENERATING_CASH_REFERENCE_REPORT, "Generando Cash Reference...")];

	TRY

		[[ZCloseManager getInstance] generateCashReferenceSummary: detailReport reference: reference];

	FINALLY

		[processForm closeProcessForm];
		[processForm free];

	END_TRY
}



/**/
- (void) jOperatorReportMenu_Click
{
	volatile JFORM processForm;
	volatile USER user = NULL;
	volatile BOOL detail = FALSE;
	int usr;
	PROFILE profile = NULL;
	int printType;
	BOOL hasMovements = TRUE;

	if (![[CimGeneralSettings getInstance] getUseEndDay]) {
		[JMessageDialog askOKMessageFrom: self 
				withMessage: getResourceStringDef(RESID_USE_END_DAY_DISABLE, "Debe habilitar el parametro Use End Day")];
		return;
		
	}

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];

	user = [[UserManager getInstance] getUserLoggedIn];
	profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
	// Si tiene el permiso de generar todos le doy la posibiliad de seleccionar uno o todos los operadores
	// en caso contrario solo podra genear su propio reporte de operador
	if ([profile hasPermission: OPERATORS_REPORT_OP]){
  	// Selecciono el Usuario
  	usr = [UICimUtils selectCollectorSelection: self title: getResourceStringDef(RESID_USERS_LABEL, "Operator:")];
  	
  	switch (usr) {
  		case ITEM_BACK: return;
  		case ITEM_ALL:
              user = NULL; // lo pongo en NULL cuando selecciona ALL
  						break;
  								
  		case ITEM_SELECT:
              user = [UICimUtils selectVisibleUser: self];
              if (user == NULL) return;
  						break;
  	}   
	}	

  // selecciono el tipo de impresion (detallado o resumido)
  printType = [UICimUtils selectPrintType: self title: getResourceStringDef(RESID_PRINT_TYPE_LABEL, "Tipo de impresion:")];
	switch (printType) {
		case ITEM_BACK_PRT_TYPE: return;
		case ITEM_SUMMARY_PRT_TYPE:
						detail = FALSE;
						break;
		case ITEM_DETAILED_PRT_TYPE:
		        detail = TRUE;
						break;
	}

	processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_GENERATING_OPERATOR_REPORT, "Generando Reporte de Operador...")];

	TRY
    if (user == NULL){
			hasMovements = [[ZCloseManager getInstance] generateUserReports: detail];
		}else{
      if (![[ZCloseManager getInstance] hasUserMovements: user]){
        [processForm closeProcessForm];
        if ([JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_MOVEMENTS_IN_PERIOD_QUESTION_PRINT, "No hay movimientos! Desea igualmente imprimirlo?")] == JDialogResult_NO){
          [processForm free];
          EXIT_TRY;
					return;
        }
        processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_GENERATING_OPERATOR_REPORT, "Generando Reporte de Operador...")];
      }
      [[ZCloseManager getInstance] generateUserReport: user includeDetail: detail];
    }
		  
	FINALLY
		[processForm closeProcessForm];
		[processForm free];
	END_TRY

	if (!hasMovements) {
		[JMessageDialog askOKMessageFrom: self 
				withMessage: getResourceStringDef(RESID_MOVEMENTS_IN_PERIOD, "No hay movimientos para el periodo!")];
	}


}

/**/
- (void) jGenerateZCloseMenu_Click
{
	JFORM processForm;
	volatile BOOL printOperatorReport = FALSE;

	if (![[CimGeneralSettings getInstance] getUseEndDay]) {
		[JMessageDialog askOKMessageFrom: self 
				withMessage: getResourceStringDef(RESID_USE_END_DAY_DISABLE, "Debe habilitar el parametro Use End Day")];
		return;
	}

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];

	if ([[ZCloseManager getInstance] hasAlreadyPrintZClose]) {

		if ([JMessageDialog askYesNoMessageFrom: self 
				 withMessage: getResourceStringDef(RESID_GENERATE_END_DAY_QUESTION, "Ya se genero el cierre diario para hoy. Generar otro?")] == JDialogResult_NO) return;
	}

	// Imprime los reportes de operador
	if ([[CimGeneralSettings getInstance] getPrintOperatorReport] == PrintOperatorReport_ALWAYS)
		printOperatorReport = TRUE;
	else if ([[CimGeneralSettings getInstance] getPrintOperatorReport] == PrintOperatorReport_ASK) {
		if ([JMessageDialog askYesNoMessageFrom: self 
				 withMessage: getResourceStringDef(RESID_PRINT_OPERATOR_REPORTS, "Imprime reportes de Operador?")] == JDialogResult_YES) printOperatorReport = TRUE;
	}
		
	processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_GENERATING_END_DAY_REPORT, "Generando Cierre Diario...")];

	TRY
		[[ZCloseManager getInstance] generateZClose: printOperatorReport];
	FINALLY
		[processForm closeProcessForm];
		[processForm free];
	END_TRY

}

- (void) jCimGeneralSettingsMenu_Click
{
	JFORM form;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];

	form = [JCimGeneralSettingsEditForm createForm: self];
	[form showFormToView: [CimGeneralSettings getInstance]];
	[form free];
}

- (void) jCimDeviceLoginSettingsMenu_Click
{
	JFORM form;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];

	form = [JCimDeviceLoginSettingsEditForm createForm: self];
	[form showFormToView: [CimGeneralSettings getInstance]];
	[form free];
}

/**/
- (void) jCimDeviceSettingsMenu_Click
{
	JFORM form;
	BOOL enable = FALSE;
  int i;
	COLLECTION list = NULL;
	id acceptorSetting;  

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];


	// si algun validador esta detras de una puerta habilitada lo dejo pasar
	list = [[[CimManager getInstance] getCim] getAcceptorSettings];
	for (i=0; i<[list size]; ++i) {
	acceptorSetting = [list at: i];
  if ([acceptorSetting getAcceptorType] == AcceptorType_VALIDATOR && 
			![acceptorSetting isDeleted] && 
			![[acceptorSetting getDoor] isDeleted] && 
			([acceptorSetting getAcceptorProtocol] != ProtocolType_CDM3000) ) {
				enable = TRUE;
		}
	}

	if (!enable) {
 		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(DAO_CANOT_ENABLE_DEVICE_EX, "No puede habilitar dispositivos con la puerta deshabilitada")];
		return;
	}

	form = [JDeviceSelectionEditForm createForm: self];
	[form showFormToView: [CimGeneralSettings getInstance]];
	[form free];
}

/**/
- (void) jCimBoxModelSettingsMenu_Click
{
	id form;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];

	// abro la pantalla de seleccion de modelos.
	form = [JBoxModelChangeEditForm createForm: self];
	[form setShowCancel: TRUE];
	[form setIsViewMode: TRUE];
	[form showModalForm];
	[form free];
}

/**/
- (void) jCimBackupSettingsMenu_Click
{
	JFORM form;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];

	// abro la pantalla de configuracion de backup automatico.
	form = [JCimBackupSettingsEditForm createForm: self];
	[form showFormToView: [CimGeneralSettings getInstance]];
	[form free];

}

/**/
- (void) jTestDepositMenu_Click
{
	int i;
	DEPOSIT deposit;
	ABSTRACT_ACCEPTOR acceptor;
	CIM_CASH cimCash;
	ACCEPTOR_SETTINGS acceptorSettings;
	int count;
	CURRENCY currency;

	static money_t bills[] = 
	{
		 10000000,
     20000000,
     50000000,
    100000000,
		500000000,
	 1000000000
  };

	cimCash = [UICimUtils selectAutoCimCash: self];
	if (cimCash == NULL) return;

	//doLog(0,"Generando 100 depositos...");

TEST_SPEED_START
	acceptorSettings = [[cimCash getAcceptorSettingsList] at: 0];
	acceptor = [[[CimManager getInstance] getCim] getAcceptorById: [acceptorSettings getAcceptorId]];
	
	if ([acceptorSettings getAcceptorId] == 1) currency = [[CurrencyManager getInstance] getCurrencyById: 840];
	else currency = [[CurrencyManager getInstance] getCurrencyById: 978];

	sysRandomize();

	count = sysRandom(1, 20);

	deposit = [[CimManager getInstance] startDeposit: cimCash depositType: DepositType_AUTO];
	[deposit addRejectedQty: sysRandom(0,3)];

	for (i = 0; i < count; ++i) {


		[deposit addDepositDetail: acceptorSettings
			depositValueType: DepositValueType_VALIDATED_CASH
			currency: currency
			qty: 1
			amount: bills[sysRandom(0,5)]];


	}

	[[CimManager getInstance] endDeposit];

TEST_SPEED_END

}

/**/
- (void) jDepositAndSaveMenu_Click
{
	DEPOSIT deposit;
	ABSTRACT_ACCEPTOR acceptor1 = NULL;
	ABSTRACT_ACCEPTOR acceptor2 = NULL;
	CIM_CASH cimCash;
	COLLECTION acceptorSettingsList;

	cimCash = [UICimUtils selectCimCash: self];
	if (cimCash == NULL) return;

	//doLog(0,"Generando 1 depositos...");
	acceptorSettingsList = [cimCash getAcceptorSettingsList];
	
	acceptor1 = [[[CimManager getInstance] getCim] getAcceptorById: [[acceptorSettingsList at: 0] getAcceptorId]];
	if ([acceptorSettingsList size] > 1)
		acceptor2 = [[[CimManager getInstance] getCim] getAcceptorById: [[acceptorSettingsList at: 1] getAcceptorId]];

	deposit = [[CimManager getInstance] startDeposit: cimCash depositType: DepositType_AUTO];

	/*_billAccepted(50000000, acceptor1);
	_billAccepted(50000000, acceptor1);
	_billAccepted(100000000, acceptor1);
	_billAccepted(100000000, acceptor1);
	_billAccepted(100000000, acceptor1);
	_billRejected(79, acceptor1);
	_billAccepted(100000000, acceptor1);
	_billAccepted(2000000000, acceptor1);
	_billRejected(78, acceptor1);

*/
	if (acceptor2) {
/*		_billAccepted(50000000, acceptor2);
		_billAccepted(50000000, acceptor2);
		_billAccepted(50000000, acceptor2);
		_billAccepted(100000000, acceptor2);*/
	}

	// Grabo el deposito
	[[CimManager getInstance] endDeposit];
}

/**/
- (void) jDepositAndAbortMenu_Click
{
	DEPOSIT deposit;
	ABSTRACT_ACCEPTOR acceptor;
	CIM_CASH cimCash;

	cimCash = [UICimUtils selectCimCash: self];
	if (cimCash == NULL) return;


	//doLog(0,"Generando 1 depositos...");

	acceptor = [[[CimManager getInstance] getCim] getAcceptorById: 1];

	deposit = [[CimManager getInstance] startDeposit: cimCash depositType: DepositType_AUTO];

	/*_billAccepted(50000000, acceptor);
	_billAccepted(50000000, acceptor);
	_billAccepted(100000000, acceptor);
	_billAccepted(100000000, acceptor);
	_billAccepted(100000000, acceptor);
	_billRejected(79, acceptor);
	_billAccepted(100000000, acceptor);
	_billAccepted(2000000000, acceptor);
	_billRejected(78, acceptor);
*/
	exit(1);
}

- (void) jExtractionMenu_Click
{
	DOOR door;

	door = [UICimUtils selectCollectorDoor: self];
	if (door == NULL) return;

	[[ExtractionManager getInstance] generateExtraction: door user1: NULL user2: NULL bagNumber: "" bagTrackingMode: 0];
}

- (void) jReprintDepositMenu_Click
{
	scew_tree *tree;
	DEPOSIT deposit = NULL;
  int option;
	id form;
	unsigned long lastNumber, iBegin, iEnd, i;
	DepositReportParam depositParam;
	char additional[21];

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;
  
  // detengo el timer
  [myTimer stop];  
  
	option = [UICimUtils selectReprintSelection: self];
	
	switch (option) {
		case ITEM_REPRINT_BACK: return;
		case ITEM_REPRINT_LAST:
            deposit = [[[Persistence getInstance] getDepositDAO] loadLast];
	          if (!deposit) return;

					  depositParam.auditDateTime = [SystemTime getLocalTime];
						sprintf(additional, "%s %ld", getResourceStringDef(RESID_DROP_DESC, "Deposito"), [deposit getNumber]);
          	depositParam.auditNumber = [Audit auditEventCurrentUserWithDate: Event_DROP_RECEIPT_REPRINT 
						  additional: additional station: 0  datetime: depositParam.auditDateTime logRemoteSystem: FALSE];	 
    	
            tree = [[ReportXMLConstructor getInstance] buildXML: deposit 
							entityType: DEPOSIT_PRT isReprint: TRUE varEntity: &depositParam];
          	[[PrinterSpooler getInstance] addPrintingJob: DEPOSIT_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];

						[deposit free];

						break;
		case ITEM_REPRINT_BY_RANGE:
            form = [JSelectRangeEditForm createForm: self];
            lastNumber = [[[Persistence getInstance] getDepositDAO] getLastDepositNumber];
            [form setFromRange: lastNumber];
            [form setToRange: lastNumber];
            [form showModalForm];

            iBegin = [form getFromRange];
            iEnd = [form getToRange];

            // recorro los deposit y los mando a imprimir
            for (i = iBegin; i<= iEnd; i++) {
              deposit = [[[Persistence getInstance] getDepositDAO] loadById: i];
  	          if (deposit) {
								depositParam.auditDateTime = [SystemTime getLocalTime];
								sprintf(additional, "%s %ld", getResourceStringDef(RESID_DROP_DESC, "Deposito"), [deposit getNumber]);
								depositParam.auditNumber = [Audit auditEventCurrentUserWithDate: Event_DROP_RECEIPT_REPRINT 
									additional: additional station: 0  datetime: depositParam.auditDateTime logRemoteSystem: FALSE];

								tree = [[ReportXMLConstructor getInstance] buildXML: deposit 
									entityType: DEPOSIT_PRT isReprint: TRUE varEntity: &depositParam];
              	[[PrinterSpooler getInstance] addPrintingJob: DEPOSIT_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];

								[deposit free];
              }
            }
            [form free];
						break;						
	}
}

/**/
- (void) jTelesupConfigMenu_Click
{
	JFORM form; 
	
  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];

 	form = [JTelesupervisionsListForm createForm: self];

	[form showModalForm];
	[form free];	
}

- (void) jReprintExtractionMenu_Click
{
	scew_tree *tree;
	EXTRACTION extraction = NULL;
	char additional[20];
  int option;
	id form;
	unsigned long lastNumber, iBegin, iEnd, i;
  CashReportParam cashParam;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;
  
  // detengo el timer
  [myTimer stop];  
  
	cashParam.cash = NULL;
	cashParam.detailReport = FALSE;

	option = [UICimUtils selectReprintSelection: self];

	switch (option) {
		case ITEM_REPRINT_BACK: return;
		case ITEM_REPRINT_LAST:
          	extraction = [[ExtractionManager getInstance] loadLast];
          	if (!extraction) return;
          
						// levanto el bag tracking
						[[[Persistence getInstance] getExtractionDAO] loadBagTrackingByExtraction: extraction];

          	// Audito el evento
						cashParam.auditDateTime = [SystemTime getLocalTime];
          	sprintf(additional, "%s %ld", getResourceStringDef(RESID_REPRINT_DEPOSIT_DESC, "Retiro"), [extraction getNumber]);

          	cashParam.auditNumber = [Audit auditEventCurrentUserWithDate: Event_DEPOSIT_REPORT_REPRINT additional: additional station: [[extraction getDoor] getDoorId] datetime: cashParam.auditDateTime logRemoteSystem: FALSE];

						// si no hay bag tracking no muestro el campo BAG en el reporte
						cashParam.showBagNumber = [extraction hasBagTracking];

						if ([[[CimManager getInstance] getCim] isTransferenceBoxMode]) {
							tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: TRANS_BOX_MODE_EXTRACTION_PRT isReprint: TRUE  varEntity: &cashParam];
							[[PrinterSpooler getInstance] addPrintingJob: TRANS_BOX_MODE_EXTRACTION_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
						} else {
							tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: EXTRACTION_PRT isReprint: TRUE  varEntity: &cashParam];
							[[PrinterSpooler getInstance] addPrintingJob: EXTRACTION_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
						}

						// imprimo el bag tracking solo si corresponde
						if ([extraction hasBagTracking]) {

							if ([self getBagTrackingMode: [extraction getDoor]] == BagTrackingMode_AUTO || [self getBagTrackingMode: [extraction getDoor]] == BagTrackingMode_MIXED) {

								[extraction setBagTrackingMode: BagTrackingMode_AUTO];
								tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: BAG_TRACKING_PRT isReprint: TRUE varEntity: NULL];
								[[PrinterSpooler getInstance] addPrintingJob: BAG_TRACKING_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: ""];
							}

							if ([self getBagTrackingMode: [extraction getDoor]] == BagTrackingMode_MANUAL || [self getBagTrackingMode: [extraction getDoor]] == BagTrackingMode_MIXED) {
								[extraction setBagTrackingMode: BagTrackingMode_MANUAL];
								tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: BAG_TRACKING_PRT isReprint: TRUE varEntity: NULL];
								[[PrinterSpooler getInstance] addPrintingJob: BAG_TRACKING_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: ""];
							}

						}

						[extraction free];

						break;

		case ITEM_REPRINT_BY_RANGE:
            form = [JSelectRangeEditForm createForm: self];
            lastNumber = [[[Persistence getInstance] getExtractionDAO] getLastExtractionNumber];
            [form setFromRange: lastNumber];
            [form setToRange: lastNumber];
            [form showModalForm];
            
            iBegin = [form getFromRange];
            iEnd = [form getToRange];
                        
            // recorro los extraction y los mando a imprimir
            for (i = iBegin; i<= iEnd; i++) {
            	extraction = [[ExtractionManager getInstance] loadById: i];
            	if (extraction) {

								// levanto el bag tracking
								[[[Persistence getInstance] getExtractionDAO] loadBagTrackingByExtraction: extraction];

								// Audito el evento
								cashParam.auditDateTime = [SystemTime getLocalTime];
								sprintf(additional, "%s %ld", getResourceStringDef(RESID_REPRINT_DEPOSIT_DESC, "Retiro"), [extraction getNumber]);
								cashParam.auditNumber = [Audit auditEventCurrentUserWithDate: Event_DEPOSIT_REPORT_REPRINT additional: additional station: [[extraction getDoor] getDoorId] datetime: cashParam.auditDateTime logRemoteSystem: FALSE];

								// si no hay bag tracking no muestro el campo BAG en el reporte
								cashParam.showBagNumber = [extraction hasBagTracking];

								if ([[[CimManager getInstance] getCim] isTransferenceBoxMode]) {
									tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: TRANS_BOX_MODE_EXTRACTION_PRT isReprint: TRUE  varEntity: &cashParam];
									[[PrinterSpooler getInstance] addPrintingJob: TRANS_BOX_MODE_EXTRACTION_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
								} else {
									tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: EXTRACTION_PRT isReprint: TRUE  varEntity: &cashParam];
									[[PrinterSpooler getInstance] addPrintingJob: EXTRACTION_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
								}

								// imprimo el bag tracking solo si corresponde
								if ([extraction hasBagTracking]) {

									if ([self getBagTrackingMode: [extraction getDoor]] == BagTrackingMode_AUTO || [self getBagTrackingMode: [extraction getDoor]] == BagTrackingMode_MIXED) {
		
										[extraction setBagTrackingMode: BagTrackingMode_AUTO];
										tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: BAG_TRACKING_PRT isReprint: TRUE varEntity: NULL];
										[[PrinterSpooler getInstance] addPrintingJob: BAG_TRACKING_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: ""];
									}
		
									if ([self getBagTrackingMode: [extraction getDoor]] == BagTrackingMode_MANUAL || [self getBagTrackingMode: [extraction getDoor]] == BagTrackingMode_MIXED) {
										[extraction setBagTrackingMode: BagTrackingMode_MANUAL];
										tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: BAG_TRACKING_PRT isReprint: TRUE varEntity: NULL];
										[[PrinterSpooler getInstance] addPrintingJob: BAG_TRACKING_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: ""];
									}
								}

								[extraction free];
              } 
            }

            [form free];
						break;
	}
}

/**/
- (void) jReprintZCloseMenu_Click
{
	scew_tree *tree;
	ZCLOSE zclose = NULL;
	char additional[20];
	ZCloseReportParam param;
	datetime_t auditDateTime;
	unsigned long auditNumber;
	volatile JFORM processForm = NULL;
  int option;
	id form;
	unsigned long lastNumber, iBegin, iEnd, i;
	BOOL printOperatorReport = FALSE;

	if (![[CimGeneralSettings getInstance] getUseEndDay]) {
		[JMessageDialog askOKMessageFrom: self 
				withMessage: getResourceStringDef(RESID_USE_END_DAY_DISABLE, "Debe habilitar el parametro Use End Day")];
		return;
	}

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];

	option = [UICimUtils selectReprintSelection: self];

	if ([JMessageDialog askYesNoMessageFrom: self 
				 withMessage: getResourceStringDef(RESID_PRINT_OPERATOR_REPORTS, "Imprime reportes de Operador?")] == JDialogResult_YES) printOperatorReport = TRUE;
		
	switch (option) {
		case ITEM_REPRINT_BACK: return;
		case ITEM_REPRINT_LAST:
	       	  processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_REPRINTING_END_DAY_REPORT, "Reimprimiendo Reporte de Cierre Diario...")];
            TRY
              zclose = [[ZCloseManager getInstance] loadLastZClose];
          		if (zclose!= NULL) {
          		
          			// Audito el evento
          			sprintf(additional, "%s %ld", getResourceStringDef(RESID_REPRINT_Z_DESC, "Z"), [zclose getNumber]);
          			auditDateTime = [SystemTime getLocalTime];
          			auditNumber = [Audit auditEventCurrentUserWithDate: Event_GRAND_Z_REPRINT additional: additional station: 0 datetime: auditDateTime logRemoteSystem: FALSE];
          		
          			// Imprimo el reporte X
          			param.user = NULL;
          			param.includeDetails = FALSE;
          			param.auditNumber = auditNumber;
          			param.auditDateTime = auditDateTime;
          		
								if (printOperatorReport)
									[[ZCloseManager getInstance] generateUserReports: zclose includeDetail: FALSE];

          			// Genero el reporte  
          			tree = [[ReportXMLConstructor getInstance] buildXML: zclose 
          				entityType: CIM_ZCLOSE_PRT isReprint: TRUE varEntity: &param];
          		
          			[[PrinterSpooler getInstance] addPrintingJob: CIM_ZCLOSE_PRT 
          				copiesQty: 1
          				ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
          		
          			[zclose free];
          		}
          
          	FINALLY
          		[processForm closeProcessForm];
          		[processForm free];
          	END_TRY
						break;
		case ITEM_REPRINT_BY_RANGE:
            form = [JSelectRangeEditForm createForm: self];
            lastNumber = [[[Persistence getInstance] getZCloseDAO] getLastZCloseNumber];
            [form setFromRange: lastNumber];
            [form setToRange: lastNumber];
            [form showModalForm];
            
            iBegin = [form getFromRange];
            iEnd = [form getToRange];
            
            if (iBegin > 0)
              processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_REPRINTING_END_DAY_REPORT, "Reimprimiendo Reporte de Cierre Diario...")];
              
            TRY                        
              // recorro los cierres Z y los mando a imprimir
              for (i = iBegin; i<= iEnd; i++){
              	zclose = [[ZCloseManager getInstance] loadZCloseById: i];
            		if (zclose!= NULL) {
            		
									if (printOperatorReport)
										[[ZCloseManager getInstance] generateUserReports: zclose includeDetail: FALSE];

            			// Audito el evento
            			sprintf(additional, "%s %ld", getResourceStringDef(RESID_REPRINT_Z_DESC, "Z"), [zclose getNumber]);
            			auditDateTime = [SystemTime getLocalTime];
            			auditNumber = [Audit auditEventCurrentUserWithDate: Event_GRAND_Z_REPRINT additional: additional station: 0 datetime: auditDateTime logRemoteSystem: FALSE];	
            		
            			// Imprimo el reporte Z
            			param.user = NULL;
            			param.includeDetails = FALSE;
            			param.auditNumber = auditNumber;
            			param.auditDateTime = auditDateTime;
            		
            			// Genero el reporte  
            			tree = [[ReportXMLConstructor getInstance] buildXML: zclose 
            				entityType: CIM_ZCLOSE_PRT isReprint: TRUE varEntity: &param];
            		
            			[[PrinterSpooler getInstance] addPrintingJob: CIM_ZCLOSE_PRT 
            				copiesQty: 1
            				ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
            		
            			[zclose free];
            		}             	 
              }
            FINALLY
            	if (iBegin > 0){
                [processForm closeProcessForm];
            	  [processForm free];
            	}
            END_TRY               
              
            
            [form free];
						break;						
	}
}

/**/
- (void) jReprintXCloseMenu_Click
{
	scew_tree *tree;
	ZCLOSE zclose = NULL;
	char additional[20];
	ZCloseReportParam param;
	datetime_t auditDateTime;
	unsigned long auditNumber;
	volatile JFORM processForm = NULL;
  int option;
	id form;
	unsigned long lastNumber, iBegin, iEnd, i;

	if (![[CimGeneralSettings getInstance] getUseEndDay]) {
		[JMessageDialog askOKMessageFrom: self 
				withMessage: getResourceStringDef(RESID_USE_END_DAY_DISABLE, "Debe habilitar el parametro Use End Day")];
		return;
	}

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];

	option = [UICimUtils selectReprintSelection: self];
	
	switch (option) {
		case ITEM_REPRINT_BACK: return;
		case ITEM_REPRINT_LAST:
	       	  processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_REPRINTING_PARTIAL_DAY_REPORT, "Reimprimiendo Reporte de Cierre Parcial...")];
            TRY
              zclose = [[ZCloseManager getInstance] loadLastCashClose];
          		if (zclose!= NULL) {
          		
          			// Audito el evento
          			sprintf(additional, "%s %ld", getResourceStringDef(RESID_REPRINT_PARTIAL_DESC, "Parcial"), [zclose getNumber]);
          			auditDateTime = [SystemTime getLocalTime];
          			auditNumber = [Audit auditEventCurrentUserWithDate: Event_GRAND_X_REPRINT additional: additional station: 0 datetime: auditDateTime logRemoteSystem: FALSE];	
          		
          			// Imprimo el reporte X
          			param.user = NULL;
          			param.includeDetails = FALSE;
          			param.auditNumber = auditNumber;
          			param.auditDateTime = auditDateTime;
          		
          			// Genero el reporte  
          			tree = [[ReportXMLConstructor getInstance] buildXML: zclose 
          				entityType: CIM_X_CASH_CLOSE_PRT isReprint: TRUE varEntity: &param];
          		
          			[[PrinterSpooler getInstance] addPrintingJob: CIM_X_CASH_CLOSE_PRT 
          				copiesQty: 1
          				ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
          		
          			[zclose free];
          		}
          
          	FINALLY
          		[processForm closeProcessForm];
          		[processForm free];
          	END_TRY
						break;
		case ITEM_REPRINT_BY_RANGE:
            form = [JSelectRangeEditForm createForm: self];
            lastNumber = [[[Persistence getInstance] getZCloseDAO] getLastCashCloseNumber];
            [form setFromRange: lastNumber];
            [form setToRange: lastNumber];
            [form showModalForm];
            
            iBegin = [form getFromRange];
            iEnd = [form getToRange];
            
            if (iBegin > 0)
              processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_REPRINTING_PARTIAL_DAY_REPORT, "Reimprimiendo Reporte de Cierre Parcial...")];
              
            TRY                        
              // recorro los cierres X y los mando a imprimir
              for (i = iBegin; i<= iEnd; i++) {
              	zclose = [[ZCloseManager getInstance] loadCashCloseById: i];
            		if (zclose!= NULL) {

            			// Audito el evento
            			sprintf(additional, "%s %ld", getResourceStringDef(RESID_REPRINT_PARTIAL_DESC, "Parcial"), [zclose getNumber]);
            			auditDateTime = [SystemTime getLocalTime];
            			auditNumber = [Audit auditEventCurrentUserWithDate: Event_GRAND_X_REPRINT additional: additional station: 0 datetime: auditDateTime logRemoteSystem: FALSE];
            		
            			// Imprimo el reporte X
            			param.user = NULL;
            			param.includeDetails = FALSE;
            			param.auditNumber = auditNumber;
            			param.auditDateTime = auditDateTime;
            		
            			// Genero el reporte  
            			tree = [[ReportXMLConstructor getInstance] buildXML: zclose 
            				entityType: CIM_X_CASH_CLOSE_PRT isReprint: TRUE varEntity: &param];
            		
            			[[PrinterSpooler getInstance] addPrintingJob: CIM_X_CASH_CLOSE_PRT 
            				copiesQty: 1
            				ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
            		
            			[zclose free];
            		}             	 
              }
            FINALLY
            	if (iBegin > 0){
                [processForm closeProcessForm];
            	  [processForm free];
            	}
            END_TRY               
              
            
            [form free];
						break;						
	}
}

/**/
- (void) jGenerateBackupMenu_Click
{
	scew_tree *tree;
  JFORM processForm;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;
  
  // detengo el timer
  [myTimer stop];  

	// Modulo reportes
  processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_GENERATING_BACKUP_REPORT, "Generando Reporte de Backup...")];
	
  TRY

    tree = [[ReportXMLConstructor getInstance] buildXML: [CimBackup getInstance] entityType: BACKUP_INFO_PRT isReprint: FALSE varEntity: NULL];
  	[[PrinterSpooler getInstance] addPrintingJob: BACKUP_INFO_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];

	FINALLY
		[processForm closeProcessForm];
		[processForm free];
	END_TRY

}

/**/
- (void) jGenerateModuleLicenceMenu_Click
{
	scew_tree *tree;
  JFORM processForm;
	EnrollOperatorReportParam param;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;
  
  // detengo el timer
  [myTimer stop];  

	// Modulo reportes
  processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_GENERATING_MODULES_REPORT, "Generando Reporte de Modulos...")];
	
  TRY    
    tree = [[ReportXMLConstructor getInstance] buildXML: [[CommercialStateMgr getInstance] getModules] entityType: MODULES_LICENCE_PRT isReprint: FALSE varEntity: &param];
  	
  	[[PrinterSpooler getInstance] addPrintingJob: MODULES_LICENCE_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
	FINALLY	  
		[processForm closeProcessForm];
		[processForm free];
	END_TRY

}

/**/
- (void) jCurrentExtractionByDoorMenu_Click
{
	scew_tree *tree;
	EXTRACTION extraction;
	DOOR door;
	CashReportParam param;
	unsigned long auditNumber;
  datetime_t auditDateTime;
  char additional[20];
  int printType;
		
	// si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;
  
  // detengo el timer
  [myTimer stop];  
  
	door = [UICimUtils selectCollectorDoor: self];
	if (door == NULL) return;

	extraction = [[ExtractionManager getInstance] getCurrentExtraction: door];
	if (!extraction) return;

  // selecciono el tipo de impresion (detallado o resumido)
  printType = [UICimUtils selectPrintType: self title: getResourceStringDef(RESID_PRINT_TYPE_LABEL, "Tipo de impresion:")];
	switch (printType) {
		case ITEM_BACK_PRT_TYPE: return;
		case ITEM_SUMMARY_PRT_TYPE:
						param.detailReport = FALSE;
						break;
		case ITEM_DETAILED_PRT_TYPE:
		        param.detailReport = TRUE;
						break;
	}

	// Audito el evento
	sprintf(additional, "%ld", [extraction getNumber]);
	auditDateTime = [SystemTime getLocalTime];
	auditNumber = [Audit auditEventCurrentUserWithDate: Event_CASH_REPORT additional: additional station: 0 datetime: auditDateTime logRemoteSystem: FALSE];	
	
  // Parametros del reporte
	param.cash = NULL;
	param.auditNumber = auditNumber;
  param.auditDateTime = auditDateTime;
	param.showBagNumber = FALSE;

	tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: CURRENT_VALUES_PRT isReprint: FALSE varEntity: &param];
	[[PrinterSpooler getInstance] addPrintingJob: CURRENT_VALUES_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];

}

- (void) jCurrentExtractionByCashMenu_Click
{
	scew_tree *tree;
	EXTRACTION extraction;
	CIM_CASH cash;
	DOOR door;
	CashReportParam param;
	unsigned long auditNumber;
  datetime_t auditDateTime;
  char additional[20];
  int printType;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;
  	
  // detengo el timer
  [myTimer stop];  	
  	
	cash = [UICimUtils selectCimCash: self];
	if (cash == NULL) return;
  
  // obtener la door del cash seleccionado
  door = [cash getDoor]; // este cash va a ser pasado al buildXML en la variable varEntity 
	extraction = [[ExtractionManager getInstance] getCurrentExtraction: door];
	if (!extraction) return;

  // selecciono el tipo de impresion (detallado o resumido)
  printType = [UICimUtils selectPrintType: self title: getResourceStringDef(RESID_PRINT_TYPE_LABEL, "Tipo de impresion:")];
	switch (printType) {
		case ITEM_BACK_PRT_TYPE: return;
		case ITEM_SUMMARY_PRT_TYPE:
						param.detailReport = FALSE;
						break;
		case ITEM_DETAILED_PRT_TYPE:
		        param.detailReport = TRUE;
						break;
	}

	// Audito el evento
	sprintf(additional, "%ld", [extraction getNumber]);
	auditDateTime = [SystemTime getLocalTime];
	auditNumber = [Audit auditEventCurrentUserWithDate: Event_CASH_REPORT additional: additional station: 0 datetime: auditDateTime logRemoteSystem: FALSE];	
	
  // Parametros del reporte
	param.cash = cash;
	param.auditNumber = auditNumber;
  param.auditDateTime = auditDateTime;
	param.showBagNumber = FALSE;

	tree = [[ReportXMLConstructor getInstance] buildXML: extraction entityType: CURRENT_VALUES_PRT isReprint: FALSE varEntity: &param];
	[[PrinterSpooler getInstance] addPrintingJob: CURRENT_VALUES_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];

}


/**/
- (void) jDepositMenu_Click
{
	CIM_CASH cimCash;
	CASH_REFERENCE reference = NULL;
	USER user;
	char envelopeNumber[50];
	char applyTo[50];
	JFormModalResult modalResult;
	JFormModalResult mResult;
	JFORM form;
	
	*envelopeNumber = '\0';
	*applyTo = '\0';


	if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];

	// selecciono el cash si es que hay mas de un cash creado
	if ([[[[CimManager getInstance] getCim] getAutoCimCashs] size] > 1) {
		cimCash = [UICimUtils selectAutoCimCash: self];
		if (cimCash == NULL) return;
	}else{
		if ([[[[CimManager getInstance] getCim] getAutoCimCashs] size] == 1)
			cimCash = [[[[CimManager getInstance] getCim] getAutoCimCashs] at: 0];
		else{
			[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_YOU_MUST_CREATE_CASH, "Primero debe crear un cash.")];
			return;
		}
	}

	// controlo que la puerta este habilitada
	if ([[cimCash getDoor] isDeleted]) {
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_DISABLE_DOOR, "La puerta se encuentra deshabilitada!")];
		return;
	}

	// controlo que la puerta este cerrada
	if ([[cimCash getDoor] getDoorState] == DoorState_OPEN) {
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_YOU_MUST_CLOSE_VALIDATED_DOOR, "Primero debe cerrar la puerta validada!")];
		return;
	}

	// El Cash ya se esta utilizando para un Extended Drop
	if ([[CimManager getInstance] getExtendedDrop: cimCash] != NULL) {
		[JMessageDialog askOKMessageFrom: self 
			withMessage: getResourceStringDef(RESID_CASH_ALREADY_USE_EXTENDED, "El Cash ya se encuentra en uso por un Deposito Extendido.")];
		return;
	}

	[[CimManager getInstance] checkCimCashState: cimCash];

	// Solicito la referencia (si es que las utiliza)
	if ([[CimGeneralSettings getInstance] getUseCashReference]) {
		reference = [UICimUtils selectCashReference: self];
		if (reference == NULL) return;
	}

	// Solicito el APPLY TO (si corresponde)
	if ([[CimGeneralSettings getInstance] getAskApplyTo]) {

		if (![UICimUtils askApplyTo: self
			applyTo: applyTo
			title: getResourceStringDef(RESID_VALIDATED_DROP_TITLE, "Deposito Validado")
			description: getResourceStringDef(RESID_APPLIED_TO, "Aplicar a:")]) return;
	}

	user = [[UserManager getInstance] getUserLoggedIn];

	// le digo al hilo de alarmas que no procese las alarmas para evitar solapamiento
	[[AlarmThread getInstance] setAlarmWait: TRUE];

	modalResult = [UICimUtils startDeposit: self 
								user: user 
								cimCash: cimCash
								cashReference: reference
								envelopeNumber: envelopeNumber
    						applyTo: applyTo];

	// pregunto si desea realizar otra operacion, si me dice que no o se cumple el
	// timer lo deslogueo
	if (modalResult == JFormModalResult_OK){

		form = [JSimpleTimerForm createForm: self];
		[form setTimeout: 30];
		[form setTitle: getResourceStringDef(RESID_DO_OTHER_OPERATION_QUESTION, "Desea realizar otra operacion?")];
		[form setShowButton1: TRUE]; // El button 2 se muestra por defecto
		[form setIgnoreActiveWindow: FALSE];
		[form setCaption1: getResourceStringDef(RESID_NO, "NO")];
		[form setCaption2: getResourceStringDef(RESID_YES, "SI")];
		mResult = [form showModalForm];
		[form free];

		if (mResult != JFormModalResult_YES)
    	[[JSystem getInstance] sendLogoutApplicationMessage];
	}

	// le digo al hilo de alarmas que siga procesando las alarmas
	[[AlarmThread getInstance] setAlarmWait: FALSE];

}

/**/
- (void) jManualDepositMenu_Click
{
	CIM_CASH cimCash;
	JFORM form;
	CASH_REFERENCE cashReference = NULL;
	JFormModalResult modalResult;
	JFormModalResult mResult;
	JFORM form2;

	if (![UICimUtils canMakeDeposits: self]) return;

	// detengo el timer
  [myTimer stop];

	// selecciono el cash si es que hay mas de un cash creado
	if ([[[[CimManager getInstance] getCim] getManualCimCashs] size] > 1) {
		cimCash = [UICimUtils selectManualCimCash: self];
		if (cimCash == NULL) return;
	} else {
		if ([[[[CimManager getInstance] getCim] getManualCimCashs] size] == 1)
			cimCash = [[[[CimManager getInstance] getCim] getManualCimCashs] at: 0];
		else{
			[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_YOU_MUST_CREATE_CASH, "Primero debe crear un cash!")];
			return;
		}
	}

	// controlo que la puerta este habilitada
	if ([[cimCash getDoor] isDeleted]) {
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_DISABLE_DOOR, "La puerta se encuentra deshabilitada!")];
		return;
	}	

	// controlo que la puerta este cerrada
	if ([[cimCash getDoor] getDoorState] == DoorState_OPEN) {
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_YOU_MUST_CLOSE_MANUAL_DOOR, "Primero debe cerrar la puerta manual!")];
		return;
	}

	[[CimManager getInstance] checkCimCashState: cimCash];

	// Solicito la referencia (si es que las utiliza)
	if ([[CimGeneralSettings getInstance] getUseCashReference]) {
		cashReference = [UICimUtils selectCashReference: self];
		if (cashReference == NULL) return;
	}

	// le digo al hilo de alarmas que no procese las alarmas para evitar solapamiento
	[[AlarmThread getInstance] setAlarmWait: TRUE];

	form = [JManualDepositListForm createForm: self];
	[form setCimCash: cimCash];
	[form setCashReference: cashReference];
  modalResult = [form showModalForm];
  [form free];	

	// pregunto si desea realizar otra operacion, si me dice que no o se cumple el
	// timer lo deslogueo
	if (modalResult == JFormModalResult_OK){

		form2 = [JSimpleTimerForm createForm: self];
		[form2 setTimeout: 30];
		[form2 setTitle: getResourceStringDef(RESID_DO_OTHER_OPERATION_QUESTION, "Desea realizar otra operacion?")];
		[form2 setShowButton1: TRUE]; // El button 2 se muestra por defecto
		[form2 setIgnoreActiveWindow: FALSE];
		[form2 setCaption1: getResourceStringDef(RESID_NO, "NO")];
		[form2 setCaption2: getResourceStringDef(RESID_YES, "SI")];
		mResult = [form2 showModalForm];
		[form2 free];

		if (mResult != JFormModalResult_YES)
    	[[JSystem getInstance] sendLogoutApplicationMessage];
	}

	// le digo al hilo de alarmas que siga procesando las alarmas
	[[AlarmThread getInstance] setAlarmWait: FALSE];

}

/**/
- (void) jSystemInfoMenu_Click
{
	scew_tree *tree;
	EnrollOperatorReportParam param;
	unsigned long auditNumber;
  datetime_t auditDateTime;
  CIM cim;
  JFORM processForm;
  int printType;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];

  // selecciono el tipo de impresion (detallado o resumido)
  printType = [UICimUtils selectPrintType: self title: getResourceStringDef(RESID_PRINT_TYPE_LABEL, "Tipo de impresion:")];
	switch (printType) {
		case ITEM_BACK_PRT_TYPE: return;
		case ITEM_SUMMARY_PRT_TYPE:
						param.detailReport = FALSE;
						break;
		case ITEM_DETAILED_PRT_TYPE:
		        param.detailReport = TRUE;
						break;
	}

	// Audito el evento
	auditDateTime = [SystemTime getLocalTime];
	auditNumber = [Audit auditEventCurrentUserWithDate: Event_SYSTEM_INFO_REQUEST additional: "" station: 0 datetime: auditDateTime logRemoteSystem: FALSE];	
	
  // Parametros del reporte
	param.userStatus = 0; // no se usa
	param.auditNumber = auditNumber;
  param.auditDateTime = auditDateTime;

  cim = [[CimManager getInstance] getCim];
  
  processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_GENERATING_SYSTEM_INFO_REPORT, "Generando Reporte de Sistema...")];
  
  TRY
  	tree = [[ReportXMLConstructor getInstance] buildXML: cim entityType: SYSTEM_INFO_PRT isReprint: FALSE varEntity: &param];
  	[[PrinterSpooler getInstance] addPrintingJob: SYSTEM_INFO_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
	FINALLY
		[processForm closeProcessForm];
		[processForm free];
	END_TRY
}

/**/
- (void) jReportConfTelesupMenu_Click
{
	scew_tree *tree;
	EnrollOperatorReportParam param;
	unsigned long auditNumber;
  datetime_t auditDateTime;
  COLLECTION telesups;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;
  
  // detengo el timer
  [myTimer stop];  
  
	// Audito el evento
	auditDateTime = [SystemTime getLocalTime];
	auditNumber = [Audit auditEventCurrentUserWithDate: EVENT_SUPERVISION_REPORT additional: "" station: 0 datetime: auditDateTime logRemoteSystem: FALSE];
	
  // Parametros del reporte
	param.userStatus = 0; // no se usa
	param.auditNumber = auditNumber;
  param.auditDateTime = auditDateTime;

  telesups = [[TelesupervisionManager getInstance] getTelesups];

	tree = [[ReportXMLConstructor getInstance] buildXML: telesups entityType: CONFIG_TELESUP_PRT isReprint: FALSE varEntity: &param];
	[[PrinterSpooler getInstance] addPrintingJob: CONFIG_TELESUP_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
    
}


/**/
- (void) jCashesMenu_Click
{
  id form;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];
    
  form = [JCimCashListForm createForm: self];
  [form showModalForm];
  [form free];
}

/**/
- (void) jDoorsMenu_Click
{
  id form;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];
    
  form = [JDoorsListForm createForm: self];
  [form showModalForm];
  [form free];
}

/**/
- (void) jCashReferenceMenu_Click
{
  id form;
  
  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];
    
  form = [JCashReferenceListForm createForm: self];
  [form showModalForm];
  [form free];
}

/**/
- (void) jProfilesMenu_Click
{
  id form;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];
    
  form = [JProfilesListForm createForm: self];
  [form showModalForm];
  [form free];
}

/**/
- (void) jDualAccessMenu_Click
{
  id form;
  int i;
  PROFILE profile;
  USER user;
  COLLECTION myVisibleProfilesList;
  COLLECTION myAuxVisibleProfilesList;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];
    
  myVisibleProfilesList = [Collection new];
  myAuxVisibleProfilesList = [Collection new];
  
  // tarigo al usuario logueado para obtener el perfil que tiene  
  user = [[UserManager getInstance] getUserLoggedIn];
  if ([user getUProfileId] != 1) { // si el perfil es diferente a ADMIN lo agrego a la lista
    profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
    if ([profile hasPermission: OPEN_DOOR_OP])
      [myAuxVisibleProfilesList add: profile];
  }
  // traigo los hijos de este perfil
  [[UserManager getInstance] getChildProfiles: [user getUProfileId] childs: myVisibleProfilesList];
  // recorro los hijos
  for (i=0; i<[myVisibleProfilesList size]; ++i) {
      profile = [myVisibleProfilesList at: i];
      if ([profile hasPermission: OPEN_DOOR_OP])
        [myAuxVisibleProfilesList add: profile];
  }

	[myVisibleProfilesList free];
  
	// si no hay perfiles a listar con permiso de open door no le permito ingresar a la pantalla
  if ([myAuxVisibleProfilesList size] == 0) {
    [JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_DONT_OPEN_DOOR_PROFILES_MSG, "No hay perfiles con permiso de ABRIR PUERTA!")];
    return;
  }  

	[myAuxVisibleProfilesList free];
  
  form = [JDualAccessListForm createForm: self];
  [form showModalForm];
  [form free];
}

/**/
- (void) jUsersMenu_Click
{
  id form;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];
    
	// si no hay usuarios creados no le permito acceder
  if ([[[UserManager getInstance] getVisibleUsers] size] == 0){
    [JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_DONT_USER_CREATED2_MSG, "No hay usuarios para editar/ver!")];
    return;
  }
  
  form = [JUsersListForm createForm: self];
  [form setCanDelete: FALSE];
  [form setCanUpdate: TRUE];  
  [form showModalForm];
  [form free];
}

/**/
- (void) jDeleteUsersMenu_Click
{
  id form;
  int i;
  COLLECTION myUserList;
  COLLECTION myVisibleUsersList;
  int userLoguedId;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];
    
  userLoguedId = [[[UserManager getInstance] getUserLoggedIn] getUserId];
  myUserList = [Collection new];
  myVisibleUsersList = [[UserManager getInstance] getVisibleUsers];
  for (i=0; i<[myVisibleUsersList size];++i){ 
		if ([ [myVisibleUsersList at: i] getUserId] != userLoguedId){
		  [myUserList add: [myVisibleUsersList at: i]];
		}
  }
	
  // si no hay usuarios creados no le permito acceder
  if ([myUserList size] == 0){
    [JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_DONT_USER_CREATED_MSG, "No hay usuarios para eliminar!")];
    return;
  }
  
  form = [JUsersListForm createForm: self];
  [form setCanDelete: TRUE];
  [form setCanUpdate: FALSE];
  [form showModalForm];
  [form free];
}

/**/
- (void) jDoorsByUsersMenu_Click
{
  id form;
  int userLoguedId;
	int i = 0;
  id user;
  id profile;  
  COLLECTION myVisibleUsersList;
  COLLECTION myAuxVisibleUsersList;
	COLLECTION doorsByUser;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];
     
	// si el usuario logueado no posee puertas asignadas no le permito acceder
	userLoguedId = [[[UserManager getInstance] getUserLoggedIn] getUserId];

	doorsByUser = [[UserManager getInstance] getDoorsByUserList: userLoguedId];
  if ( (doorsByUser == NULL) || ([doorsByUser size] == 0) ) {
    [JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_CREATE_DOOR_ACCESS_1_MSG, "Usted no tiene puertas asignadas!")];
    return;
  }
    
	// si no hay usuarios creados o los que existen no tienen permiso de open door no le permito acceder	
	myAuxVisibleUsersList = [Collection new];
  myVisibleUsersList = [[UserManager getInstance] getVisibleUsers];
  for (i=0; i<[myVisibleUsersList size];++i) {
		if (![[myVisibleUsersList at: i] isSpecialUser]) {
      user = [myVisibleUsersList at: i];
      profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
      if ([profile hasPermission: OPEN_DOOR_OP])
        [myAuxVisibleUsersList add: user];
    }
  }
  
  if ([myAuxVisibleUsersList size] == 0) {
    [JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_CREATE_DOOR_ACCESS_MSG, "Primero debe crear usuarios con permiso de ABRIR PUERTA!")];
    return;
  }  
      
  form = [JDoorsByUserListForm createForm: self];
  [form showModalForm];
  [form free];
}

/**/
- (void) jActivateUserMenu_Click
{    
  id form;
  int userLoguedId;
  int i, count;
  id users;
  
  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];
    
	// si no hay usuarios creados no le permito acceder
  
  // traigo los usuarios excepto al super
  users = [[UserManager getInstance] getVisibleUsers];
  
  // traigo el id del usuario logueado para no incluirlo en la lista
  userLoguedId = [[[UserManager getInstance] getUserLoggedIn] getUserId];
  count = 0;
  for (i=0; i < [users size]; ++i) {
    if (userLoguedId != [[users at: i] getUserId]){
      if (![[users at: i] isActive])
        count++;
    }
  }	
	
  if (count == 0){
    [JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_NOT_INACTIVE_USERS_MSG, "No hay usuarios inactivos!")];
    return;
  }
      
  form = [JActivateDeactivateUserEditForm createForm: self];
  [form setViewActiveUsers: FALSE]; // muestro solo los inactivos
  [form showFormToEdit: NULL];
  [form free];  
}

/**/
- (void) jDeactivateUserMenu_Click
{    
  id form;
  int userLoguedId;
  int i, count;
  id users;
  
  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];
    
	// si no hay usuarios creados no le permito acceder
  
  // traigo los usuarios excepto al super
  users = [[UserManager getInstance] getVisibleUsers];
  
  // traigo el id del usuario logueado para no incluirlo en la lista
  userLoguedId = [[[UserManager getInstance] getUserLoggedIn] getUserId];
  count = 0;
  for (i=0; i < [users size]; ++i) {
    if (userLoguedId != [[users at: i] getUserId]){
      if ([[users at: i] isActive])
        count++;
    }
  }	
	
  if (count == 0){
    [JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_NOT_ACTIVE_USERS_MSG, "No hay usuarios activos!")];
    return;
  }
      
  form = [JActivateDeactivateUserEditForm createForm: self];
  [form setViewActiveUsers: TRUE]; // muestro solo los activos
  [form showFormToEdit: NULL];
  [form free];  
}

/**/
- (void) jForcePinChangeMenu_Click
{    
  JFORM processForm;
  
  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];
  
  if ([JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_FORCE_PIN_CHANGE_QUESTION, "Desea forzar el cambio de clave de todos los usuarios?")] == JDialogResult_YES){
	  
    processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];
  
    [[UserManager getInstance] ForcePinChange];

    [processForm closeProcessForm];
    [processForm free];
  
    [JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_FORCE_PIN_OK_MSG, "El forzado de cambio de clave fue exitoso!")];
        
	} 
}

/**/
- (void) jChangeUserPinMenu_Click
{
  id form;
	USER user;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];

  user = [[UserManager getInstance] getUserLoggedIn];

	if (![user isPinRequired]) {
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_CURRENT_USER_DOESNOT_USE_PIN, "Current user does not use PIN to login.")];
		return;
	}

  form = [JUserChangePinEditForm createForm: self];
	[form showFormToEdit: user];
	[form free];
	
}

- (void) jReprintClosingCodeMenu_Click
{
	volatile USER user = NULL;
	scew_tree *tree;

		// si esta funcionando con hardware secundario no lo dejo avanzar
	if (![UICimUtils canMakeDeposits: self]) return;
	
	user = [UICimUtils selectDynamicPinUser: self];
	if (user == NULL) return;

	// Imprimo el reporte de Operador
	tree = [[ReportXMLConstructor getInstance] buildXML: user entityType: CLOSING_CODE_PRT isReprint: TRUE];
	[[PrinterSpooler getInstance] addPrintingJob: CLOSING_CODE_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree];
	[Audit auditEventCurrentUser: Event_REPRINT_CODE_SEAL additional: [user str] station: 0 logRemoteSystem: FALSE];

}

- (void) jResetDynamicPinMenu_Click
{
	volatile JFORM processForm;
	volatile USER user = NULL;
	volatile USER userLogged = NULL;
	int failed = 0;
	char oldPin[9];
	char oldDuress[9];
	unsigned short devList;

		// si esta funcionando con hardware secundario no lo dejo avanzar
	if (![UICimUtils canMakeDeposits: self]) return;
	
	user = [UICimUtils selectDynamicPinUser: self];
	if (user == NULL) return;

	userLogged = [[UserManager getInstance] getUserLoggedIn];

	doGeneratePin([user getClosingCode], oldPin, oldDuress);

	processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_UNDEFINED, "Reseting User PIN...")];
	TRY
		devList = [user getDevListMask];
		[SafeBoxHAL sbDeleteUser: [user getLoginName]];
		[SafeBoxHAL sbAddUser: devList personalId: [user getLoginName] password: "12345678" duressPassword: "12345679"];

	    [Audit auditEventCurrentUser: Event_RESET_DYNAMIC_PIN additional: [user str] station: 0 logRemoteSystem: FALSE];
	CATCH
		failed = 1;
	END_TRY
	[processForm closeProcessForm];
	[processForm free];
	if (failed)
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_UNDEFINED, "Impossible to reset User PIN, Format Users")];


}

/**/
- (void) jEnrollUsersMenu_Click
{
  id form;
	USER user;

  // si esta funcionando con hardware secundario no lo dejo avanzar
  if (![UICimUtils canMakeDeposits: self]) return;

  // detengo el timer
  [myTimer stop];
	
	// si no hay perfiles creados no le permito crear usuarios
  if ([[[UserManager getInstance] getVisibleProfiles] size] == 0){
    [JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_CREATE_PROFILE_MSG, "Primero debe crear perfiles de usuario!")];
    return;
  }
	
	user = NULL;
  form = [JUserEditForm createForm: self];
  	
  user = [User new];
  
	[form showFormToEdit: user];
  
	if ([form getModalResult] == JFormModalResult_OK) {
  
		[[UserManager getInstance] addUserToCollection: user];
	} else {
		[user free];	
		user = NULL;
	}
}

/**/
- (void) jManualTelesupMenu_Click
{
  id form;
  unsigned char oldOpList[15];
  unsigned char actualOpList[15];
  USER user;
  PROFILE profile;

  // detengo el timer
  [myTimer stop];

  // guardo la lista de operaciones antes de la supervision
  user = [[UserManager getInstance] getUserLoggedIn];
  profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
  memset(oldOpList, 0, 14);
  memcpy(oldOpList, [profile getOperationsList], 14);

  // ejecuto la supervision
  form = [JManualTelesupListForm createForm: self];
  [form showModalForm];
  [form free];

  // traigo la lista de operaciones luego de la supervision	
  memset(actualOpList, 0, 14);
  memcpy(actualOpList, [profile getOperationsList], 14);

  // si las listas son diferentes es porque se actualizaron las operaciones.
  if (strcmp(oldOpList, actualOpList) != 0){
    // actualizo el menu
		[self configureMainMenu];
  }
}

/**/
- (BOOL) canAccessUserLogued: (int) anOperationId
{	
  if (myLoguedUserId > 0)
		return [[UserManager getInstance] hasUserPermission: myLoguedUserId operation: anOperationId];
	else
		return FALSE;
}

/**/
- (void) activateMainMenu: (int) aUserId
{
  myLoguedUserId = aUserId;
//	[self configureMainMenu];
}

/**/
- (char *) getCaptionX
{
  if ( [[CimManager getInstance] hasActiveTimeDelays] )
    return getResourceStringDef(RESID_DELAY, myTimeDelayMsg);
  
  return NULL;
}

/**/
- (void) onMenuXButtonClick
{
  if ([[CimManager getInstance] hasActiveTimeDelays]) {
    // detengo el timer
    [myTimer stop];
        
		[UICimUtils showTimeDelays: self];
		[self paintComponent];
	}
}

/**/
- (char *) getCaption1
{
  if ( [myMainMenu getCurrentMenuLevel] == 1 )
		return NULL;
  
  return getResourceStringDef(RESID_BACK_KEY, myCaption1Msg);
}

/**/
- (void) onMenu1ButtonClick
{
  //[[JSystem getInstance] sendActivateNextApplicationFormMessage];
}

- (void) onMenuItem_AcceptIncomingSupervision_Click
{
/*
	id form;
	int modalResult;

  if ([JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_ENABLED_INCOMING_SUP_QUESTION, "Habilitar supervision entrante?")]  == JDialogResult_YES) 

  [[Acceptor getInstance] acceptIncomingSupervision: TRUE];	 

	form = [JIncomingTelTimerForm createForm: self];
	[form setTimeout: [[Configuration getDefaultInstance] getParamAsInteger: "INCOMING_SUPERVISION_TIMEOUT"]];
	[form setTitle: getResourceStringDef(RESID_UNDEFINED, "Esperando supervision entrante.")];
	[form setCanCancel: TRUE];
	[form setShowTimer: TRUE];
	[[Acceptor getInstance] setFormObserver: form];
	modalResult = [form showModalForm];
	[form free];

	//if (modalResult == JFormModalResult_YES) break;
	if (modalResult == JFormModalResult_CANCEL) 
  	[[Acceptor getInstance] acceptIncomingSupervision: FALSE];	 		
*/
}

/**/
- (void) onMenuItem_Logout_Click
{
  // detengo el timer
  [myTimer stop];
  
  if ([JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_CLOSE_SESSION_QUESTION, "Esta seguro de cerrar la sesion?")]  == JDialogResult_YES)
    [[JSystem getInstance] sendLogoutApplicationMessage];

}

/**/
- (void) jTurnOffBuzzerMenu_Click
{
  // detengo el timer
  [myTimer stop];
  
  if ([JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_TURN_OFF_BUZZER_QUESTION, "Desea silenciar el buzzer?")] == JDialogResult_YES) {
    [[Buzzer getInstance] buzzerStop];
  }
  
}

/**/
- (void) jShutdownMenu_Click
{

  // detengo el timer
  [myTimer stop];

	if ([self canReboot]) {
		[[CtSystem getInstance] shutdownSystem];
		[SafeBoxHAL shutdown];
	}

}

/**/
- (BOOL) canReboot
{
  // detengo el timer
  [myTimer stop];

	//
	if ([[TelesupScheduler getInstance] inTelesup]) {
		[JMessageDialog askOKMessageFrom: self 
			withMessage: getResourceStringDef(RESID_TELESUP_IN_PROGRESS, "Existe una supervision en progreso!")];
		return FALSE;
	}

	// Antes de poder reiniciar debe cerrar todos los extended drops
	if ([[[CimManager getInstance] getExtendedDrops] size] > 0) {
		[JMessageDialog askOKMessageFrom: self 
			withMessage: getResourceStringDef(RESID_EXTENDED_DROPS_IN_PROGRESS, "Existen Depositos Extendidos en progreso!")];
		return FALSE;
	}

	if ([JMessageDialog askYesNoMessageFrom: self 
		withMessage: getResourceStringDef(RESID_SHUTDOWN_CONFIRMATION, "Esta seguro de apagar el sistema?")]  != JDialogResult_YES) 
		return FALSE;

	return TRUE;
}

- (void) onCloseOperatingSystem_Click
{
	id infoViewer;

  if (![self canReboot])
    return;

  if ([JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_REBOOT_SYSTEM_QUESTION, "Esta seguro de reiniciar el sistema operativo?")]  != JDialogResult_YES) return;

  infoViewer = [JInfoViewerForm createForm: NULL];
	[infoViewer setCaption: getResourceStringDef(RESID_REBOOTING, "Reiniciando...")];
	[infoViewer showModalForm];
					
	[[CtSystem getInstance] shutdownSystem];
  	
	// reinicio el sistema operativo
	system("reboot");
}

- (void) onCloseApp_Click
{
	id infoViewer;

  if (![self canReboot])
    return;

  if ([JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_REBOOT_APPLICATION_QUESTION, "Esta seguro de reiniciar la aplicacion?")]  != JDialogResult_YES) return;

  infoViewer = [JInfoViewerForm createForm: NULL];
	[infoViewer setCaption: getResourceStringDef(RESID_REBOOTING, "Reiniciando...")];
	[infoViewer showModalForm];
					
	[[CtSystem getInstance] shutdownSystem];
	
	exit(23);
}

- (void) onHardwareTest_Click
{
	id infoViewer;

  if (![self canReboot])
    return;

  if ([JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_ASK_RUN_HARDWARE_TEST, "Esta seguro que desea correr el Test?")]  != JDialogResult_YES) return;

  infoViewer = [JInfoViewerForm createForm: NULL];
	[infoViewer setCaption: getResourceStringDef(RESID_RUNNING_HARDWARE_TEST, "Ejecutando Test")];
	[infoViewer showModalForm];
					
	[[CtSystem getInstance] shutdownSystem];
	
	exit(25);
}

/**/
- (void) onSupervisionTestMenu_Click
{
	id telTest;
	int result;
	id pimsTelesup;
	long connectionId;
	id connectionSettings;
	char aux[100];

  if ([JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_ASK_RUN_SUPERVISION_TEST, "Esta seguro que desea correr el Test?")]  != JDialogResult_YES) return;

	
	// 1) tarigo la supervision principal **********************
	if ([[TelesupScheduler getInstance] inTelesup]){
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_TELESUP_IN_PROGRESS, "Error: Supervision en curso.")];
		return;
	}

	pimsTelesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];
	if (pimsTelesup == NULL){
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_CREATE_PIMS_SUPERVISION_MSG, "Error: Primero debe crear una supervision a la PIMS!")];
		return;
	}

	if ([[Acceptor getInstance] isTelesupRunning]) {
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_UNDEFINED, "Error: Se encuentra dentro de una supervision entrante!")];
		return;
	}

	/*if ((![[CimManager getInstance] isSystemIdleForTelesup]) && ([[TelesupScheduler getInstance] getCommunicationIntention] != CommunicationIntention_CHANGE_STATE_REQUEST)) {
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_UNDEFINED, "Error: El sistema no se encuentra ocioso!")];
		return;
	}*/

	// Si no tengo permiso porque esta mal la autorizacion, me voy
	/*if (([pimsTelesup getTelcoType] == PIMS_TSUP_ID) && ([[TelesupScheduler getInstance] getCommunicationIntention] != CommunicationIntention_CHANGE_STATE_REQUEST)) {
		if (![[CommercialStateMgr getInstance] canExecutePimsSupervision]) {
			[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_UNDEFINED, "Error: No posee autorizacion de supervision!")];
			return;
		}
	}*/

	// le digo al hilo de alarmas que no procese las alarmas para evitar solapamiento
	[[AlarmThread getInstance] setAlarmWait: TRUE];

	// creo el objeto de test de supervision
	telTest = [TelesupTest new];

	// verifico el tipo de conexion. Si es GPRS hago el test del modem
	connectionId = [pimsTelesup getConnectionId1];
	connectionSettings = [[TelesupervisionManager getInstance] getConnection: connectionId];
	result = 1;
	[telTest setUseModem: 0];
	if ([connectionSettings getConnectionType] == ConnectionType_GPRS) {
		// 2) pruebo el modem **********************
		[telTest setConnectionSettings: connectionSettings];
		[telTest setUseModem: 1];
		[telTest setBaudRate: [Modem getBaudRateFromSpeed: [connectionSettings getConnectionSpeed]]];
		//[telTest setResetModem: FALSE];
		result = [telTest testModem];
	}

	[telTest setSupervisionResult: "NOT RUN"];
	// 3) ejecuto la supervision *****************
  if (result) {
		[[TelesupScheduler getInstance] setCommunicationIntention: CommunicationIntention_TEST_TELESUP];
		[[TelesupScheduler getInstance] startTelesup: pimsTelesup];
		aux[0] = '\0';
		if (strlen([[TelesupScheduler getInstance] getErrorInTelesupMsg]) != 0){
			sprintf(aux, "Supervision Error\n %s\n", [[TelesupScheduler getInstance] getErrorInTelesupMsg]);
			[telTest setSupervisionResult: aux];
		}else
			[telTest setSupervisionResult: "Supervision OK"];
		
	}

	// 4) Imprimo el reporte
	[telTest printReport];
	[telTest free];

	// le digo al hilo de alarmas que siga procesando las alarmas
	[[AlarmThread getInstance] setAlarmWait: FALSE];
}

/**/
- (void) onTestMenu_Click
{
	id telTest;
	int result;
	id pimsTelesup;
	long connectionId;
	id connectionSettings;
	char aux[100];

	// creo el objeto de test de supervision
	telTest = [TelesupTest new];

	pimsTelesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];

	// verifico el tipo de conexion. Si es GPRS hago el test del modem
	connectionId = [pimsTelesup getConnectionId1];
	connectionSettings = [[TelesupervisionManager getInstance] getConnection: connectionId];
	result = 1;
	[telTest setUseModem: 0];
	if ([connectionSettings getConnectionType] == ConnectionType_GPRS){

		//doLog(0,"**************** TESTEA EL MODEM *******************\n");

		// 2) pruebo el modem **********************
		[telTest setConnectionSettings: connectionSettings];
		[telTest setUseModem: 1];
		[telTest setBaudRate: [Modem getBaudRateFromSpeed: [connectionSettings getConnectionSpeed]]];
		//[telTest setResetModem: FALSE];
		result = [telTest testModem];
	}

	[telTest setSupervisionResult: "NOT RUN"];
	// 3) ejecuto la supervision *****************

	//doLog(0,"**************** TESTEA LA SUPERVISION *******************\n");

	[[TelesupScheduler getInstance] setCommunicationIntention: CommunicationIntention_TEST_TELESUP];
	[[TelesupScheduler getInstance] startTelesup: pimsTelesup];
	aux[0] = '\0';
	if (strlen([[TelesupScheduler getInstance] getErrorInTelesupMsg]) != 0){
		sprintf(aux, "Supervision Error\n %s\n", [[TelesupScheduler getInstance] getErrorInTelesupMsg]);
		[telTest setSupervisionResult: aux];
	}else
		[telTest setSupervisionResult: "Supervision OK"];
		
}

/**/
- (void) onTest2Menu_Click
{
	id telTest;
	int result;
	id pimsTelesup;
	long connectionId;
	id connectionSettings;

	// creo el objeto de test de supervision
	telTest = [TelesupTest new];

	pimsTelesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];

	// verifico el tipo de conexion. Si es GPRS hago el test del modem
	connectionId = [pimsTelesup getConnectionId1];
	connectionSettings = [[TelesupervisionManager getInstance] getConnection: connectionId];
	result = 1;
	[telTest setUseModem: 0];
	if ([connectionSettings getConnectionType] == ConnectionType_GPRS){

		//doLog(0,"**************** PRIMERA VEZ TESTEA EL MODEM *******************\n");

		// 2) pruebo el modem **********************
		[telTest setConnectionSettings: connectionSettings];
		[telTest setUseModem: 1];
		[telTest setBaudRate: [Modem getBaudRateFromSpeed: [connectionSettings getConnectionSpeed]]];
		//[telTest setResetModem: FALSE];
		result = [telTest testModem];

	}

	[telTest free];

	// creo el objeto de test de supervision
	telTest = [TelesupTest new];

	// verifico el tipo de conexion. Si es GPRS hago el test del modem
	connectionId = [pimsTelesup getConnectionId1];
	connectionSettings = [[TelesupervisionManager getInstance] getConnection: connectionId];
	result = 1;
	[telTest setUseModem: 0];
	if ([connectionSettings getConnectionType] == ConnectionType_GPRS){

		//doLog(0,"**************** SEGUNDA VEZ TESTEA EL MODEM *******************\n");

		// 2) pruebo el modem **********************
		[telTest setConnectionSettings: connectionSettings];
		[telTest setUseModem: 1];
		[telTest setBaudRate: [Modem getBaudRateFromSpeed: [connectionSettings getConnectionSpeed]]];
		//[telTest setResetModem: FALSE];
		result = [telTest testModem];



	}





}


/**/
- (void) jDoorAccessMenu_Click
{
	DOOR door = NULL;
	BOOL allDoors;

	if (![UICimUtils canMakeExtractions: self]) return;

  // detengo el timer
  [myTimer stop];

	// Selecciono la puerta
	door = [UICimUtils selectDoorWithAllOption: self hasSelectAll: &allDoors];

	// Si eligio todas las puertas hago un manejo diferente
	if (allDoors) {
	
		if ([[[CimManager getInstance] getExtendedDrops] size] > 0) {
			[JMessageDialog askOKMessageFrom: self 
				withMessage: getResourceStringDef(RESID_CLOSE_ALL_EXTENDED_DROP, "Cierre todos los extended drop.")];
			return;
		}

		[self openMultipleDoors];
		return;
	}

	// Si no eligio ninguna puerta me voy
	if (door == NULL) return;

	if ([[CimManager getInstance] getExtendedDropByDoor: door]) {
			[JMessageDialog askOKMessageFrom: self 
				withMessage: getResourceStringDef(RESID_CLOSE_EXTENDED_DROP, "Cierre el extended drop correspondiente.")];
			return;
	}

	// Abrio una sola puerta, la proceso
	[self openDoor: door];
}

/**/
- (void) jInformExtrMenu_Click
{
	if (![UICimUtils canMakeExtractions: self]) return;

  // detengo el timer
  [myTimer stop];
	
	if ([[[CimManager getInstance] getExtendedDrops] size] > 0) {
	  [JMessageDialog askOKMessageFrom: self 
		withMessage: getResourceStringDef(RESID_CLOSE_ALL_EXTENDED_DROP, "Cierre todos los extended drop.")];
			return;
		}

	[self informMultipleDoors];
}

/**/
- (int) getBagTrackingMode: (id) aDoor
{
	id doorAcceptorSettings;
	id doorAcceptors = [aDoor getAcceptorSettingsList];
	int i;
	int bagTrackingMode = BagTrackingMode_NONE;

	//doLog(0, "cantidad de aceptadores =%d\n", [doorAcceptors size]);

	for (i=0; i<[doorAcceptors size]; ++i) {
		doorAcceptorSettings = [doorAcceptors at: i];		

		if (([doorAcceptorSettings getAcceptorType] == AcceptorType_MAILBOX) && ([[CimGeneralSettings getInstance] getRemoveBagVerification])) {
			if (bagTrackingMode == BagTrackingMode_AUTO) {
				bagTrackingMode = BagTrackingMode_MIXED;
			} else {
				bagTrackingMode = BagTrackingMode_MANUAL;
			}
		}


		if (([doorAcceptorSettings getAcceptorType] == DepositType_AUTO) && ([[CimGeneralSettings getInstance] getBagTracking])) {
			if (bagTrackingMode == BagTrackingMode_MANUAL) {
				bagTrackingMode = BagTrackingMode_MIXED;
			} else {
				bagTrackingMode = BagTrackingMode_AUTO;
			}
		}

	} // for

	return bagTrackingMode;
}

/**/
- (void) openDoor: (DOOR) aDoor
{
	EXTRACTION_WORKFLOW extractionWorkflow = NULL;
	EXTRACTION_WORKFLOW innerExtractionWorkflow = NULL;
	BOOL removeCash = FALSE;
	USER user;
	JFORM form;
	USER myLoggedUser;
	PROFILE profile;
	JFormModalResult mResult;
	JFORM form2;
	char bagBarCode[25];
	id lastExtraction;
	long qtyToRead = 0;
	BagTrackingMode bagTrackingMode = BagTrackingMode_NONE;
	COLLECTION doorAcceptors;
	COLLECTION acceptorsAutoList;
	BOOL hasOpened = FALSE;
	unsigned long lastExtractionNumber = 0;
	int i;
	COLLECTION manualCimCashs;
	id manualDoor;


	// seteo los tiempos por defecto por las dudas que se hayan pisado al abrir puerta inerna
	[[CimManager getInstance] setDoorTimes];

	if (![aDoor getOuterDoor]) {
		extractionWorkflow = [[CimManager getInstance] getExtractionWorkflowForDoor: aDoor];
		[extractionWorkflow setInnerDoorWorkflow: NULL];
		[extractionWorkflow setGeneratedOuterDoorExtr: FALSE];
		[extractionWorkflow setHasOpened: FALSE];
	} else {
		extractionWorkflow = [[CimManager getInstance] getExtractionWorkflowForDoor: [aDoor getOuterDoor]];
		innerExtractionWorkflow = [[CimManager getInstance] getExtractionWorkflowForDoor: aDoor];
		[innerExtractionWorkflow setHasOpened: FALSE];
	  [extractionWorkflow setInnerDoorWorkflow: innerExtractionWorkflow];
		[extractionWorkflow setGeneratedOuterDoorExtr: FALSE];
		[extractionWorkflow setHasOpened: FALSE];
	}

	doorAcceptors = [aDoor getAcceptorSettingsList];

	//doLog(0, "doorAcceptors size = %d\n", [doorAcceptors size]);
	bagTrackingMode = [self getBagTrackingMode: aDoor];

	// Controlo si puede abrir la puerta dado el Time Lock correspondiente
	if ([extractionWorkflow getCurrentState] == OpenDoorStateType_IDLE) {

		// Error: no puede abrir la puerta en este momento
		if (![aDoor canOpenDoor]) {

			[JMessageDialog askOKMessageFrom: self 
				withMessage: getResourceStringDef(RESID_DOOR_TIME_LOCK_ACTIVE, "La puerta tiene el tiempo de bloqueo activo")];

      myLoggedUser = [[UserManager getInstance] getUserLoggedIn];
      profile = [[UserManager getInstance] getProfile: [myLoggedUser getUProfileId]];
		
			if ([profile hasPermission: OVERRIDE_DOOR_OP]){
        if (![UICimUtils overrideDoor: self door: aDoor]) return;
      }else
        return;

		}

	}

	// Pregunta si desea remover el dinero
	if ( ([extractionWorkflow getCurrentState] == OpenDoorStateType_IDLE ||
			[extractionWorkflow getCurrentState] == OpenDoorStateType_ACCESS_TIME)) {

		if ([doorAcceptors size] > 0)
			removeCash = [UICimUtils askRemoveCash: self door: aDoor];

		if ([extractionWorkflow getInnerDoorWorkflow]) {

			// solo mando generar la extraccion de la puerta externa segun el seteo
			if ([[CimGeneralSettings getInstance] removeCashOuterDoor])
				[extractionWorkflow setGenerateExtraction: TRUE];
			else
				[extractionWorkflow setGenerateExtraction: FALSE];

			[[extractionWorkflow getInnerDoorWorkflow] setGenerateExtraction: removeCash];
		} else {
			[extractionWorkflow setGenerateExtraction: removeCash];
		}
	}

	// si remueve el cash y por configuracion debe preguntar por el id de bolsa
	if ([extractionWorkflow getCurrentState] == OpenDoorStateType_IDLE) {
		if ([extractionWorkflow getInnerDoorWorkflow]) {

			[[extractionWorkflow getInnerDoorWorkflow] setBagTrackingMode: bagTrackingMode];

			if (removeCash && bagTrackingMode != BagTrackingMode_NONE) {

				if ([[CimGeneralSettings getInstance] getAskBagCode]) {
					stringcpy(bagBarCode, [UICimUtils askBagBarCode: self barCode: bagBarCode]);
					[[extractionWorkflow getInnerDoorWorkflow] setBagBarCode: bagBarCode];
				}

				[[extractionWorkflow getInnerDoorWorkflow] setBagTrackingMode: bagTrackingMode];
			}

		} else {
			[extractionWorkflow setBagTrackingMode: bagTrackingMode];
	
			if (removeCash && bagTrackingMode != BagTrackingMode_NONE) {

				if ([[CimGeneralSettings getInstance] getAskBagCode]) {
					stringcpy(bagBarCode, [UICimUtils askBagBarCode: self barCode: bagBarCode]);
					[extractionWorkflow setBagBarCode: bagBarCode];
				}

				[extractionWorkflow setBagTrackingMode: bagTrackingMode];
			}
		}

	}


/*

 ,OpenDoorStateType_TIME_DELAY

 ,OpenDoorStateType_IDLE
 ,OpenDoorStateType_ACCESS_TIME
 ,OpenDoorStateType_WAIT_OPEN_DOOR
 ,OpenDoorStateType_WAIT_CLOSE_DOOR
 ,OpenDoorStateType_WAIT_CLOSE_DOOR_WARNING
 ,OpenDoorStateType_WAIT_CLOSE_DOOR_ERROR
 ,OpenDoorStateType_WAIT_LOCK_DOOR
 ,OpenDoorStateType_WAIT_LOCK_DOOR_ERROR
 ,OpenDoorStateType_OPEN_DOOR_VIOLATION
 ,OpenDoorStateType_LOCK_AND_OPEN_DOOR
 ,OpenDoorStateType_WAIT_UNLOCK_WITH_OPEN_DOOR
 ,OpenDoorStateType_WAIT_OUTER_DOOR_OPEN

*/
	[extractionWorkflow removeLoggedUsers];

	// Va a pedir el login de usuario tantas veces como haga falta
	// o hasta que el usuario presione el boton "back" con lo cual
	// cancela todo el proceso de login
	while ([extractionWorkflow getCurrentState] == OpenDoorStateType_IDLE ||
		[extractionWorkflow getCurrentState] == OpenDoorStateType_ACCESS_TIME ||
		[extractionWorkflow getCurrentState] == OpenDoorStateType_LOCK_AND_OPEN_DOOR ||
		[extractionWorkflow getCurrentState] == OpenDoorStateType_WAIT_CLOSE_DOOR ||
		[extractionWorkflow getCurrentState] == OpenDoorStateType_WAIT_CLOSE_DOOR_WARNING ||
		[extractionWorkflow getCurrentState] == OpenDoorStateType_WAIT_CLOSE_DOOR_ERROR ||
		[extractionWorkflow getCurrentState] == OpenDoorStateType_OPEN_DOOR_VIOLATION) {

		user = [UICimUtils validateUser: self];

		if (user == NULL) {
			[extractionWorkflow removeLoggedUsers];
			[extractionWorkflow setGenerateExtraction: FALSE];

			if ([extractionWorkflow getInnerDoorWorkflow])
				[[extractionWorkflow getInnerDoorWorkflow] setGenerateExtraction: FALSE];

			return;
		}

		TRY
			//tengo que setear inicialmente que no genero Pin para que la primera puerta lo genere
			[ user setWasPinGenerated: 0];
			[extractionWorkflow onLoginUser: user];
		CATCH
			[self showDefaultExceptionDialogWithExCode: ex_get_code()];
			[extractionWorkflow removeLoggedUsers];
			[extractionWorkflow setGenerateExtraction: FALSE];

			if ([extractionWorkflow getInnerDoorWorkflow])
				[[extractionWorkflow getInnerDoorWorkflow] setGenerateExtraction: FALSE];

			return;
		END_TRY

	}

	// Muestro el estado de la puerta
	form = [JDoorStateForm createForm: self];
	[form setExtractionWorkflow: extractionWorkflow];

	if (bagTrackingMode != BagTrackingMode_NONE)
		[form setBagVerification: TRUE];

	if (strstr([[[[CimManager getInstance] getCim] getBoxById: 1] getBoxModel], "FLEX")) {
		manualCimCashs = [[[CimManager getInstance] getCim] getManualCimCashs];
		manualDoor = [[manualCimCashs at: 0] getDoor]; 
		[extractionWorkflow setManualDoor: manualDoor];
	}

	[form showModalForm];
	[form free];

	// hago el manejo de bagTracking segun corresponda
	if (![extractionWorkflow getInnerDoorWorkflow]) {
		//doLog(0,"removeCash = %d    bagTrackingMode = %d    hasOpened = %d \n", removeCash, bagTrackingMode, [extractionWorkflow hasOpened]);
		hasOpened = [extractionWorkflow hasOpened];

		while ([[ExtractionManager getInstance] isGeneratingExtraction]) msleep(100);

		lastExtractionNumber = [extractionWorkflow getLastExtractionNumber];

		// resetea los valores en el extractionWorkflow
		[extractionWorkflow resetLastExtractionNumber];

	} else {
		//doLog(0,"removeCash = %d    bagTrackingMode = %d    hasOpened = %d \n", removeCash, bagTrackingMode, [[extractionWorkflow getInnerDoorWorkflow] hasOpened]);
		hasOpened = [[extractionWorkflow getInnerDoorWorkflow] hasOpened];

		while ([[ExtractionManager getInstance] isGeneratingExtraction]) msleep(100);

		lastExtractionNumber = [[extractionWorkflow getInnerDoorWorkflow] getLastExtractionNumber];

		// resetea los valores en el extractionWorkflow
		[[extractionWorkflow getInnerDoorWorkflow] resetLastExtractionNumber];
	}

	// si la puerta fue abierta comienza la carga de los sobres 
	if (bagTrackingMode != BagTrackingMode_NONE && hasOpened) {

		if (removeCash) {
			lastExtraction = [[[Persistence getInstance] getExtractionDAO] loadExtractionHeaderByNumber: lastExtractionNumber];

			// se quita el assert y se agrega un if para evitar cuelgue ante posible error
			//assert(lastExtraction);
			if (lastExtraction) {

				if (bagTrackingMode == BagTrackingMode_MANUAL || bagTrackingMode == BagTrackingMode_MIXED) {

					qtyToRead = [[DepositDetailReport getInstance] getTicketsCountByDepositType: [lastExtraction getFromDepositNumber] toDepositNumber: [lastExtraction getToDepositNumber] depositType: DepositType_MANUAL];

					form = [JNumbersEntryForm createForm: self];
					[form setTotalToRead: qtyToRead];
					[form setBagTrackingMode: BagTrackingMode_MANUAL];
					[form setCurrentExtraction: lastExtraction];
					[form showModalForm];
					[form free];
				}
	
				if (bagTrackingMode == BagTrackingMode_AUTO || bagTrackingMode == BagTrackingMode_MIXED) {

					acceptorsAutoList = [Collection new];
					for (i=0; i<[doorAcceptors size]; ++i) {
						if ([[doorAcceptors at: i] getAcceptorType] == DepositType_AUTO) {
							++qtyToRead;
							[acceptorsAutoList add: [doorAcceptors at: i]];
						}
					}
	
					form = [JNumbersEntryForm createForm: self];
					[form setAcceptorSettingsList: acceptorsAutoList];
					[form setTotalToRead: qtyToRead];
					[form setBagTrackingMode: BagTrackingMode_AUTO];
					[form setCurrentExtraction: lastExtraction];
					[form showModalForm];
					[form free];
				}
	

			} //else doLog(0,"**** ERROR: LastExtraction == NULL en DoorAccess ***");
		}

		if ([extractionWorkflow getCurrentState] != OpenDoorStateType_IDLE) {
			// Muestro el estado de la puerta nuevamente
			form = [JDoorStateForm createForm: self];
			[form setExtractionWorkflow: extractionWorkflow];
			[form showModalForm];
			[form free];
		}

	}

	// pregunto si desea realizar otra operacion, si me dice que no o se cumple el
	// timer lo deslogueo
	form2 = [JSimpleTimerForm createForm: self];
	[form2 setTimeout: 30];
	[form2 setTitle: getResourceStringDef(RESID_DO_OTHER_OPERATION_QUESTION, "Desea realizar otra operacion?")];
	[form2 setShowButton1: TRUE]; // El button 2 se muestra por defecto
	[form2 setIgnoreActiveWindow: FALSE];
	[form2 setCaption1: getResourceStringDef(RESID_NO, "NO")];
	[form2 setCaption2: getResourceStringDef(RESID_YES, "SI")];
	mResult = [form2 showModalForm];
	[form2 free];

	if (mResult != JFormModalResult_YES)
		[[JSystem getInstance] sendLogoutApplicationMessage];

}


/**/
- (void) openMultipleDoors
{
	DOOR door = NULL;
	volatile EXTRACTION_WORKFLOW extractionWorkflow = NULL;
	BOOL removeCash = FALSE;
	volatile USER user1 = NULL, user2 = NULL;
	volatile int i;
	COLLECTION doors;
	BOOL canOpenDoor = TRUE;
	int delayOpenTime = -1;
	int accessTime = -1;
	int keyCount = -1;
	OpenDoorStateType openDoorState = OpenDoorStateType_UNDEFINED;
	volatile int excode = 0;

	// Obtengo todas las puertas
	doors = [[[CimManager getInstance] getCim] getDoors];
	door = [doors at: 0];
	if (door == NULL) return;

	// seteo los tiempos por defecto por las dudas que se hayan pisado al abrir puerta inerna
	[[CimManager getInstance] setDoorTimes];

	// Obtengo los datos de la puerta 1, todos deben luego ser iguales a este
	extractionWorkflow = [[CimManager getInstance] getExtractionWorkflowForDoor: door];
	openDoorState = [extractionWorkflow getCurrentState];
	delayOpenTime = [door getDelayOpenTime];
	accessTime = [door getAccessTime];
	keyCount   = [door getKeyCount];
	canOpenDoor = [door canOpenDoor];

	// Controlo las demas puertas que esten en el mismo estado
	for (i = 1; i < [doors size]; ++i) {

		door = [doors at: i];
		extractionWorkflow = [[CimManager getInstance] getExtractionWorkflowForDoor: door];
		[extractionWorkflow setInnerDoorWorkflow: NULL];
		[extractionWorkflow setGeneratedOuterDoorExtr: FALSE];

		if (openDoorState != [extractionWorkflow getCurrentState]) {
			[JMessageDialog askOKMessageFrom: self 
				withMessage: getResourceStringDef(RESID_ALL_DOORS_IN_SAME_STATE, "Todas las puertas deben estar en el mismo estado.")];
			return;
		}

		if (delayOpenTime != [door getDelayOpenTime]) {
			[JMessageDialog askOKMessageFrom: self 
				withMessage: getResourceStringDef(RESID_ALL_DOORS_SAME_TIME_DELAY, "El Time Delay de las puertas debe ser el mismo.")];
			return;
		}

		if (accessTime != [door getAccessTime]) {
			[JMessageDialog askOKMessageFrom: self 
				withMessage: getResourceStringDef(RESID_ALL_DOORS_SAME_ACCESS_TIME, "El Access Time de las puertas debe ser el mismo.")];
			return;
		}

		if (keyCount != [door getKeyCount]) {
			[JMessageDialog askOKMessageFrom: self 
				withMessage: getResourceStringDef(RESID_ALL_DOORS_SAME_DUAL_KEY, "El Dual Key de las puertas debe ser el mismo.")];
			return;
		}

		if (![door canOpenDoor])
			canOpenDoor = FALSE;
		
	}

	// Controlo si puede abrir la puerta dado el Time Lock correspondiente
	if (openDoorState == OpenDoorStateType_IDLE && !canOpenDoor) {
		[JMessageDialog askOKMessageFrom: self 
			withMessage: getResourceStringDef(RESID_DOOR_TIME_LOCK_ACTIVE, "La puerta tiene el tiempo de bloqueo activo")];
		
		/** @todo: aca no deberia enviarle una puerta en particular */
		if (![UICimUtils overrideDoor: self door: door]) return;

	}

	// Pregunta si desea remover el dinero
	if (openDoorState == OpenDoorStateType_IDLE ||
			openDoorState == OpenDoorStateType_ACCESS_TIME) {
		removeCash = [UICimUtils askRemoveCash: self door: NULL];
		[extractionWorkflow setGenerateExtraction: removeCash];
	}

	// Solicito el Login del usuario
	if (openDoorState == OpenDoorStateType_IDLE ||
			openDoorState == OpenDoorStateType_ACCESS_TIME) {

		while (user1 == NULL) {
			user1 = [UICimUtils validateUser: self];
			if (user1 == NULL) {
				[extractionWorkflow setGenerateExtraction: FALSE];
				[extractionWorkflow removeLoggedUsers];
				return;
			}
		}

		if (keyCount == 2) {
			while (user2 == NULL) {
				user2 = [UICimUtils validateUser: self];
				if (user2 == NULL) {
					[extractionWorkflow setGenerateExtraction: FALSE];
					[extractionWorkflow removeLoggedUsers];
					return;
				}
			}
		}

		//tengo que setear inicialmente que no genero Pin para que la primera puerta lo genere
		//doLog(0,"Limpio el flag de generacion de PINSSS\n");
		[user1 setWasPinGenerated: 0];
		if (keyCount == 2) [user2 setWasPinGenerated: 0];

		for (i = 0; i < [doors size]; ++i) {
			door = [doors at: i];
			extractionWorkflow = [[CimManager getInstance] getExtractionWorkflowForDoor: door];
			/* Solo verifico si tengo q generar nuevos pines en la ultima puerta */


			TRY
				[extractionWorkflow setHasOpened: FALSE];
				[extractionWorkflow setGenerateExtraction: removeCash];
				[extractionWorkflow onLoginUser: user1];
				if (keyCount == 2) [extractionWorkflow onLoginUser: user2];
			CATCH
				excode = ex_get_code();
				[extractionWorkflow setGenerateExtraction: FALSE];
				[extractionWorkflow removeLoggedUsers];
			END_TRY

		}

		if (excode != 0)
			[self showDefaultExceptionDialogWithExCode: excode];

	}

}

/**/
- (void) informMultipleDoors
{
	DOOR door = NULL;
	EXTRACTION_WORKFLOW extractionWorkflow = NULL;
	BOOL removeCash = FALSE;
	USER user1 = NULL;
	int i;
	COLLECTION doors;
	BOOL canOpenDoor = TRUE;
	int delayOpenTime = -1;
	int accessTime = -1;
	int keyCount = -1;
	OpenDoorStateType openDoorState = OpenDoorStateType_UNDEFINED;

	// Obtengo todas las puertas
	doors = [[[CimManager getInstance] getCim] getDoors];
	door = [doors at: 0];
	if (door == NULL) return;

	// Obtengo los datos de la puerta 1, todos deben luego ser iguales a este
	extractionWorkflow = [[CimManager getInstance] getExtractionWorkflowForDoor: door];
	openDoorState = [extractionWorkflow getCurrentState];
	delayOpenTime = [door getDelayOpenTime];
	accessTime = [door getAccessTime];
	keyCount   = [door getKeyCount];
	canOpenDoor = [door canOpenDoor];

	// Controlo las demas puertas que esten en el mismo estado
	for (i = 1; i < [doors size]; ++i) {
		door = [doors at: i];
		extractionWorkflow = [[CimManager getInstance] getExtractionWorkflowForDoor: door];		
		if (openDoorState != [extractionWorkflow getCurrentState]) {
			[JMessageDialog askOKMessageFrom: self 
				withMessage: getResourceStringDef(RESID_ALL_DOORS_IN_SAME_STATE, "Todas las puertas deben estar en el mismo estado.")];
			return;
		}
	}

	// Pregunta si desea remover el dinero
	if (openDoorState == OpenDoorStateType_IDLE) {
		removeCash = [UICimUtils askRemoveCash: self door: NULL];
	}

	if (!removeCash) return;

	while (user1 == NULL) {
		user1 = [UICimUtils validateUser: self];
		if (user1 == NULL) {
			return;
		}
	}

	[Audit auditEventCurrentUser: Event_INFORM_DEPOSIT additional: "" station: 0 logRemoteSystem: FALSE];
	for (i = 0; i < [doors size]; ++i) {
		door = [doors at: i];
		if (![door isDeleted])
			[[ExtractionManager getInstance] generateExtraction: door user1: user1 user2: user1 bagNumber: "" bagTrackingMode: BagTrackingMode_NONE];
	}

}

/**/
- (void) jValidateUserMenu_Click
{

	TEST_SPEED_START

	[SafeBoxHAL sbAddUser: SAFEBOX personalId: "1111" password: "1234" duressPassword: "9999"];

	TEST_SPEED_END

	TEST_SPEED_START
	
	//doLog(0,"Validate User Password %s = %d\n,", "1234",	[SafeBoxHAL sbValidateUser: "1111" password: "1234"]);

	TEST_SPEED_END

	TEST_SPEED_START

	//doLog(0,"Validate User Password %s = %d\n,", "9999",	[SafeBoxHAL sbValidateUser: "1111" password: "9999"]);
	
	TEST_SPEED_END


}

/**/
- (void) jAddUsersToSafeBoxMenu_Click
{
	unsigned long ticks = 0;

	TRY
		[SafeBoxHAL sbAddUser: LOCKER0 personalId: "1111" password: "1111" duressPassword: "1112"];
		//doLog(0,"Usuario agregado, tiempo = %ld\n", getTicks() - ticks);
	CATCH
		ex_printfmt();
		//doLog(0,"No se pudo agregar el usuario\n");
	END_TRY

	TRY
		[SafeBoxHAL sbAddUser: LOCKER1 personalId: "1111" password: "1111" duressPassword: "1112"];
		//doLog(0,"Usuario agregado, tiempo = %ld\n", getTicks() - ticks);
	CATCH
		ex_printfmt();
		//doLog(0,"No se pudo agregar el usuario\n");
	END_TRY

	TRY
		[SafeBoxHAL sbAddUser: LOCKER0 personalId: "2222" password: "2222" duressPassword: "2223"];
		//doLog(0,"Usuario agregado, tiempo = %ld\n", getTicks() - ticks);
	CATCH
		ex_printfmt();
		//doLog(0,"No se pudo agregar el usuario\n");
	END_TRY

}

/**/
- (void) jCashReferenceTestMenu_Click
{
	CASH_REFERENCE refLev1, refLev2, refLev3;

	refLev1 = [CashReference new];
	[refLev1 setName: "Level 1"];
	[[CashReferenceManager getInstance] addCashReference: refLev1];

		refLev2 = [CashReference new];
		[refLev2 setName: "Level 1.1"];
		[refLev2 setParent: refLev1];
		[[CashReferenceManager getInstance] addCashReference: refLev2];

			refLev3 = [CashReference new];
			[refLev3 setName: "Level 1.1.1"];
			[refLev3 setParent: refLev2];
			[[CashReferenceManager getInstance] addCashReference: refLev3];

			refLev3 = [CashReference new];
			[refLev3 setName: "Level 1.1.2"];
			[refLev3 setParent: refLev2];
			[[CashReferenceManager getInstance] addCashReference: refLev3];

		refLev2 = [CashReference new];
		[refLev2 setName: "Level 1.2"];
		[refLev2 setParent: refLev1];
		[[CashReferenceManager getInstance] addCashReference: refLev2];

	refLev1 = [CashReference new];
	[refLev1 setName: "Level 2"];
	[[CashReferenceManager getInstance] addCashReference: refLev1];

		refLev2 = [CashReference new];
		[refLev2 setName: "Level 2.1"];
		[refLev2 setParent: refLev1];
		[[CashReferenceManager getInstance] addCashReference: refLev2];

	refLev1 = [CashReference new];
	[refLev1 setName: "Level 3"];
	[[CashReferenceManager getInstance] addCashReference: refLev1];

	[UICimUtils selectCashReference: self];

}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) anIsPressed
{
  BOOL r;
    
  r = [super doKeyPressed: aKey isKeyPressed: anIsPressed];
  
  [myTimer stop];
  [myTimer initTimer: ONE_SHOT period: ([[CimGeneralSettings getInstance] getMaxUserInactivityTime] * 1000) object: self callback: "timerExpired"];
	[myTimer start];
  
  return r;
}
	
/**/
- (void) stopTimer
{
  [myTimer stop];
}
	
/**/
- (void) timerExpired
{
	[myTimer stop];

  // llamo al logout
  if ([[CimGeneralSettings getInstance] getMaxUserInactivityTime] > 0) {
		// si no hay un upgrade en progreso hago el logout. Caso contrario reseteo el timer
    if (![[UpdateFirmwareThread getInstance] isUpgradeInProgress]) {

			// si hay una alarma en proceso reseteo el timer
			if ( ([JWindow getActiveWindow] != NULL && 
					  [[JWindow getActiveWindow] isKindOf: [JExceptionForm class]]) ||
					  [[TelesupScheduler getInstance] inTelesup] ||
					  [[Acceptor getInstance] isTelesupRunning] ) {

						[myTimer initTimer: ONE_SHOT period: ([[CimGeneralSettings getInstance] getMaxUserInactivityTime] * 1000) object: self callback: "timerExpired"];
						[myTimer start];
			} else {
				[[JSystem getInstance] sendLogoutApplicationMessage];
			}

		}else{
			[myTimer initTimer: ONE_SHOT period: ([[CimGeneralSettings getInstance] getMaxUserInactivityTime] * 1000) object: self callback: "timerExpired"];
			[myTimer start];
		}
	}
}

/**/
- (void) onActivateForm
{
	[super onActivateForm];

	// reseteo el timer
	[myTimer initTimer: ONE_SHOT period: ([[CimGeneralSettings getInstance] getMaxUserInactivityTime] * 1000) object: self callback: "timerExpired"];
	[myTimer start];
	
}

/**/
- (BOOL) canExecuteMenu: (int) op
{
  PROFILE profile;
  BOOL primaryHardwareOK;
  USER user;
  
	// si esta funcionando con hardware secundario no creo los menues salvo door access
  primaryHardwareOK = [UICimUtils canMakeDeposits];  
  
  // obtengo el usuario logueado para ver los permisos que tiene y asi habilitar las opciones de menu
  if (primaryHardwareOK){
    user = [[UserManager getInstance] getUserLoggedIn];
    profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
    
		if ([profile hasPermission: op]) {
      return TRUE;
		}
	}
  return FALSE;  
}


/**/
- (BOOL) canExecuteReportMenu
{
  PROFILE profile;
  BOOL primaryHardwareOK;
  USER user;
  
	// si esta funcionando con hardware secundario no creo los menues salvo door access
  primaryHardwareOK = [UICimUtils canMakeDeposits];

  // obtengo el usuario logueado para ver los permisos que tiene y asi habilitar las opciones de menu
  if (primaryHardwareOK){
    
    user = [[UserManager getInstance] getUserLoggedIn];
    profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
    
    if ( ([profile hasPermission: OPERATOR_REPORT_OP]) ||
         ([profile hasPermission: GRAND_Z_REPORT_OP]) ||
         ([profile hasPermission: ENROLLED_USER_REPORT_OP]) ||
         ([profile hasPermission: AUDIT_REPORT_OP]) ||
         ([profile hasPermission: CASH_REPORT_OP]) ||
         ([profile hasPermission: GRAND_X_REPORT_OP]) ||
         ([profile hasPermission: REFERENCE_REPORT_OP]) ||
         ([profile hasPermission: SYSTEM_INFO_REPORT_OP]) ||
         ([profile hasPermission: TELESUP_REPORT_OP]) ||
         ([profile hasPermission: REPRINT_DEPOSIT_OP]) ||
         ([profile hasPermission: REPRINT_DROP_OP]) ||
         ([profile hasPermission: REPRINT_END_DAY_OP]) ){
      
      return TRUE;
    }
  }
  return FALSE;  
}

/**/
- (void) executeCurrentMenu
{
	JEvent		evt;
	evt.evtid = JEventQueueMessage_KEY_PRESSED;
	evt.event.keyEvt.keyPressed = UserInterfaceDefs_KEY_MENU_2;
	evt.event.keyEvt.isPressed = TRUE;
	[myEventQueue putJEvent: &evt];
}
/**/
- (void) executeReportMenu
{
  [[myMainMenu getSubMenu] setSelectedMenuItem: jReportsSubMenu];
  //[[myMainMenu getSubMenu] doKeyPressed: JMenuItem_KEY_ENTER isKeyPressed: TRUE];
	[self executeCurrentMenu];
}

/**/
- (void) executeDoorAccessMenu
{
	
  [[myMainMenu getSubMenu] setSelectedMenuItem: jDoorAccessMenu];
  //[[myMainMenu getSubMenu] doKeyPressed: JMenuItem_KEY_ENTER isKeyPressed: TRUE];
	[self executeCurrentMenu];
}
/**/
- (void) executeManualDropMenu
{
  [[myMainMenu getSubMenu] setSelectedMenuItem: jManualDepositMenu];
  //[[myMainMenu getSubMenu] doKeyPressed: JMenuItem_KEY_ENTER isKeyPressed: TRUE];
	[self executeCurrentMenu];
}

/**/
- (void) executeValidatedDropMenu
{
  [[myMainMenu getSubMenu] setSelectedMenuItem: jDepositMenu];
  //[[myMainMenu getSubMenu] doKeyPressed: JMenuItem_KEY_ENTER isKeyPressed: TRUE];
	[self executeCurrentMenu];
}

#ifdef _TEST_SUB_MENU
///////// COMENTADO _ MENU PARA TESTEO _ ///////////////////////////////////

/**/
- (void) configureTestSubMenu
{
	JACTION_MENU jMenu;
	JACTION_MENU jTestSubMenu;
      
  jTestSubMenu = [JSubMenu new];

	// Restaurar datos
	jMenu = [JActionMenu new];
	[jMenu initActionMenu: getResourceStringDef(RESID_UNDEFINED, "inetd &") object: self 
		action: "jStartInetd_Click"];
	[jTestSubMenu addMenuItem: jMenu];

	// Restaurar datos
	jMenu = [JActionMenu new];
	[jMenu initActionMenu: getResourceStringDef(RESID_UNDEFINED, "Restore data") object: self 
		action: "jRestoreDataMenu_Click"];
	[jTestSubMenu addMenuItem: jMenu];

	// Formatear usuarios
	jMenu = [JActionMenu new];
	[jMenu initActionMenu: getResourceStringDef(RESID_UNDEFINED, "Format users") object: self 
		action: "jFormatUsersMenu_Click"];
	[jTestSubMenu addMenuItem: jMenu];

	// Reinit files
	jMenu = [JActionMenu new];
	[jMenu initActionMenu: getResourceStringDef(RESID_UNDEFINED, "Reinit files") object: self 
		action: "jReinitSomeFilesMenu_Click"];
	[jTestSubMenu addMenuItem: jMenu];

	// File system blank
	jMenu = [JActionMenu new];
	[jMenu initActionMenu: getResourceStringDef(RESID_UNDEFINED, "FS Blank") object: self 
		action: "jFSBlankMenu_Click"];
	[jTestSubMenu addMenuItem: jMenu];

	// Secondary hardware access
	jMenu = [JActionMenu new];
	[jMenu initActionMenu: getResourceStringDef(RESID_UNDEFINED, "Secondary") object: self 
		action: "jSecondaryHardwareAccessMenu_Click"];
	[jTestSubMenu addMenuItem: jMenu];

	// Generar 300 auditorias
	jMenu = [JActionMenu new];
	[jMenu initActionMenu: getResourceStringDef(RESID_UNDEFINED, "Generate audis") object: self 
		action: "jGenerateTestAuditsMenu_Click"];
	[jTestSubMenu addMenuItem: jMenu];


  // Agrega el submenu al MainMenu
  [myMainMenu addMenuItem: jTestSubMenu]; 
  [jTestSubMenu setCaption: "Test"];

	// Extraer
	jMenu = [JActionMenu new];
	[jMenu initActionMenu: getResourceStringDef(RESID_EXTRACTION_MENU, "Retiro") object: self action: "jExtractionMenu_Click"];
	[jTestSubMenu addMenuItem: jMenu];

	// Generar depositos
	jMenu = [JActionMenu new];
	[jMenu initActionMenu: "Generar depositos" object: self action: "jTestDepositMenu_Click"];
	[jTestSubMenu addMenuItem: jMenu];

	// Generar 1 deposito
	jMenu = [JActionMenu new];
	[jMenu initActionMenu: "DEPOSIT & SAVE" object: self action: "jDepositAndSaveMenu_Click"];
	[jTestSubMenu addMenuItem: jMenu];

	// Generar 1 deposito y aborar
	jMenu = [JActionMenu new];
	[jMenu initActionMenu: "DEPOSIT & ABORT" object: self action: "jDepositAndAbortMenu_Click"];
	[jTestSubMenu addMenuItem: jMenu];
      
	// Probar validateUser
	jMenu =  [JActionMenu new];
	[jMenu initActionMenu: "Validate User" object: self action: "jValidateUserMenu_Click"];
	[jTestSubMenu addMenuItem: jMenu];
      
	// Probar validateUser
	jMenu =  [JActionMenu new];
	[jMenu initActionMenu: "Add Users to Safe" object: self action: "jAddUsersToSafeBoxMenu_Click"];
	[jTestSubMenu addMenuItem: jMenu];

	// Probar Cash References
	jMenu =  [JActionMenu new];
	[jMenu initActionMenu: "Cash Reference" object: self action: "jCashReferenceTestMenu_Click"];
	[jTestSubMenu addMenuItem: jMenu];

	// Ver estado de puerta
	jMenu = [JActionMenu new];
	[jMenu initActionMenu: getResourceStringDef(RESID_VIEW_DOOR_STATE_MENU, "Ver Estado Puerta") object: self action: "jOpenDoorTestViewStateMenu_Click"];
	[jTestSubMenu addMenuItem: jMenu];

}

/**/
- (void) jOpenDoorTestLoginMenu_Click
{
	DOOR door = NULL;
	EXTRACTION_WORKFLOW extractionWorkflow = NULL;

	door = [UICimUtils selectDoor: self];
	if (door == NULL) return;

	extractionWorkflow = [[CimManager getInstance] getExtractionWorkflowForDoor: door];

	[extractionWorkflow onLoginUser: [[UserManager getInstance] getUserLoggedIn]];
}

/**/
- (void) jOpenDoorTestOpenMenu_Click
{
	DOOR door = NULL;
	EXTRACTION_WORKFLOW extractionWorkflow = NULL;

	door = [UICimUtils selectDoor: self];
	if (door == NULL) return;

	extractionWorkflow = [[CimManager getInstance] getExtractionWorkflowForDoor: door];
	[extractionWorkflow onDoorOpen: door];
}

/**/
- (void) jOpenDoorTestCloseMenu_Click
{
	DOOR door = NULL;
	EXTRACTION_WORKFLOW extractionWorkflow = NULL;

	door = [UICimUtils selectDoor: self];
	if (door == NULL) return;

	extractionWorkflow = [[CimManager getInstance] getExtractionWorkflowForDoor: door];
	[extractionWorkflow onDoorClose: door];
}

/**/
- (void) jOpenDoorTestViewStateMenu_Click
{
 	JDOOR_STATE_FORM form;
	DOOR door = NULL;
	EXTRACTION_WORKFLOW extractionWorkflow = NULL;

	door = [UICimUtils selectDoor: self];
	if (door == NULL) return;

	extractionWorkflow = [[CimManager getInstance] getExtractionWorkflowForDoor: door];

	form = [JDoorStateForm createForm: self];
	[form setExtractionWorkflow: extractionWorkflow];
	[form showModalForm];
	[form free];
}

/**/
- (void) jGenerateTestAuditsMenu_Click
{
	int i;

	// Audita el apagado del equipo
	for (i = 0; i < 300; ++i) {
		[Audit auditEventCurrentUser: Event_SYSTEM_SHUTDOWN additional: "" station: 0 logRemoteSystem: FALSE];
	}

}

/**/
- (void) jFormatUsersMenu_Click
{
	JFORM processForm;

	processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_UNDEFINED, "Formating users...")];
	[SafeBoxHAL sbFormatUsers];
	[processForm closeProcessForm];
	[processForm free];
}


/**/
- (void) jFSBlankMenu_Click
{
	JFORM processForm;

	processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_UNDEFINED, "Formating users...")];
	[SafeBoxHAL fsBlank];
	[processForm closeProcessForm];
	[processForm free];
}

/**/
- (void) jReinitSomeFilesMenu_Click
{
	int i;

	for (i = 1; i < 10; i++) {

		TRY
			[SafeBoxHAL fsReInitFile: i];
		CATCH
		END_TRY

	}
}

#endif

@end
