#include "JTelesupervisionEditForm.h"
#include "TelesupervisionManager.h"
#include "TelesupDefs.h"
#include "util.h"
#include "MessageHandler.h"
#include "RegionalSettings.h"
#include "JExceptionForm.h"
#include "JMessageDialog.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

static int ModemSpeed[] = { 300, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200 };

#define CONNECTION_PPP_INDEX			99
#define CONNECTION_DMODEM_INDEX		99
#define CONNECTION_LAN_INDEX			0
#define CONNECTION_GPRS_INDEX			1

/*
 *	Devuelve el indice del arreglo ModemSpeed a partir de la velocidad.
 */
static int
findModemSpeed( int speed )
{
	int i;
	
	for (i = 0; i < sizeOfArray(ModemSpeed); i++)
		if (ModemSpeed[i] == speed) return i;
		
	return sizeOfArray(ModemSpeed) - 1;
}

/**/
static int getConnectionType(int connectionTypeIndex)
{
	if (connectionTypeIndex == CONNECTION_PPP_INDEX) return ConnectionType_PPP;
	if (connectionTypeIndex == CONNECTION_LAN_INDEX) return ConnectionType_LAN;
	if (connectionTypeIndex == CONNECTION_DMODEM_INDEX) return ConnectionType_MODEM;
	if (connectionTypeIndex == CONNECTION_GPRS_INDEX) return ConnectionType_GPRS;
	return ConnectionType_LAN;
}

/**/
static int getConnectionTypeIndex(ConnectionType connectionType)
{
	if (connectionType == ConnectionType_PPP) return CONNECTION_PPP_INDEX;
	if (connectionType == ConnectionType_LAN) return CONNECTION_LAN_INDEX;
	if (connectionType == ConnectionType_MODEM) return CONNECTION_DMODEM_INDEX;
	if (connectionType == ConnectionType_GPRS) return CONNECTION_GPRS_INDEX;
	return CONNECTION_LAN_INDEX;
}


@implementation  JTelesupervisionEditForm


/**/
- (void) onCreateForm
{
	int i;
	char buf[20];

	[super onCreateForm];
	printd("JTelesupervisionEditForm:onCreateForm\n");

	// Tipo de supervision
	[self addLabelFromResource: RESID_TELESUP_TYPE default: "Tipo supervision:"];
	myComboTelesupType = [JCombo new];
	[myComboTelesupType setReadOnly: TRUE];
	[myComboTelesupType setEnabled: FALSE];
	[self addFormComponent: myComboTelesupType];
	
	[self addFormNewPage];
					
	// Description
	myLabelDescription = [self addLabelFromResource: RESID_DESCRIPTION default: "Descripcion:"];
	myTextDescription = [JText new];
	[myTextDescription setWidth: 20];
  [myTextDescription setHeight: 1];
	[self addFormComponent: myTextDescription];

	[self addFormNewPage];

	// Frecuencia
  myLabelFrequency = [self addLabelFromResource: RESID_RESTITUTION_FREQUENCY default: "Frec. restitucion:"];
  myTextFrequency = [JText new];
  [myTextFrequency setNumericMode: TRUE];
  [myTextFrequency setWidth: 2];
	[myTextFrequency setEnabled: FALSE];
  [self addFormComponent: myTextFrequency];

	[self addFormNewPage];

  // System Id
	myLabelSystemId = [self addLabelFromResource: RESID_EQUIPMENT_ID default: "Id. sistema:"];
	myTextSystemId = [JText new];
	[myTextSystemId setWidth: 15];
	[self addFormComponent: myTextSystemId];
	
	[self addFormNewPage];

	// User name
	[self addLabelFromResource: RESID_SUPERVITION_USER default: "Usuario telesup:"];
	myTextUserName = [JText new];
	[myTextUserName setWidth: 20];
	[myTextUserName setHeight: 1];
	[self addFormComponent: myTextUserName];

	[self addFormNewPage];

	// Password
	[self addLabelFromResource: RESID_SUPERVITION_PASSW default: "Clave telesup:"];
	myTextPassword = [JText new];
	[myTextPassword setWidth: 20];
	[myTextPassword setHeight: 1];
	[myTextPassword setMaxLen: 15];
	[self addFormComponent: myTextPassword];

	[self addFormNewPage];

	// Remote User name
	myLabelRemoteUserName = [self addLabelFromResource: RESID_REMOTE_USER default: "Usuario remoto:"];
	myTextRemoteUserName = [JText new];
	[myTextRemoteUserName setWidth: 20];
	[myTextRemoteUserName setHeight: 1];
	[self addFormComponent: myTextRemoteUserName];

	[self addFormNewPage];

	// Remote Password
	myLabelRemotePassword = [self addLabelFromResource: RESID_REMOTE_PASSW default: "Clave remota:"];
	myTextRemotePassword = [JText new];
	[myTextRemotePassword setWidth: 20];
	[myTextRemotePassword setHeight: 1];
	[myTextRemotePassword setMaxLen: 15];
	[self addFormComponent: myTextRemotePassword];

	[self addFormNewPage];
	
	// system id
	myLabelRemoteSistemId = [self addLabelFromResource: RESID_REMOTE_SYSTEM_ID default: "Id sistema remoto:"];
	myTextRemoteSistemId = [JText new];
	[myTextRemoteSistemId setWidth: 20];
	[myTextRemoteSistemId setHeight: 1];
	[myTextRemoteSistemId setMaxLen: 15];
	[self addFormComponent: myTextRemoteSistemId];

	[self addFormNewPage];

	// Connection Type
	myLabelConnectionType = [self addLabelFromResource: RESID_CONNECTION_TYPE default: "Conectar por:"];
	myComboConnectionType = [JCombo new];
	[myComboConnectionType setWidth: 17];
	[myComboConnectionType setHeight: 1];
	[myComboConnectionType addString: getResourceStringDef(RESID_CONNECTION_LAN, "LAN (Red)")];
	[myComboConnectionType addString: getResourceStringDef(RESID_CONNECTION_GPRS, "GPRS")];
	[myComboConnectionType setOnSelectAction: self 	action: "connectionType_onSelect"];
	[self addFormComponent: myComboConnectionType];

	[self addFormNewPage];

	// ISP Phone Number
	myLabelISPPhoneNumber = [self addLabelFromResource: RESID_ISP_PHONE_NUMBER default: "No. telefono ISP:"];
	myTextISPPhoneNumber = [JText new];
	[myTextISPPhoneNumber setNumericMode: TRUE];
	[myTextISPPhoneNumber setNumericMode: TRUE];
	[myTextISPPhoneNumber setNumericType: JTextNumericType_MODEM_PHONE];
	[myTextISPPhoneNumber setWidth: 20];
	[myTextISPPhoneNumber setHeight: 1];
	[self addFormComponent: myTextISPPhoneNumber];
	
	[self addFormNewPage];

	// ISP User name ------------------------------------------------------
	myLabelDomain = [self addLabelFromResource: RESID_APN default: "APN:"];
	myTextDomain = [JText new];
	[myTextDomain setWidth: 20];
	[myTextDomain setHeight: 2];
	[self addFormComponent: myTextDomain];

	[self addFormNewPage];

	// ISP User name ------------------------------------------------------
	myLabelISPUserName = [self addLabelFromResource: RESID_ISP_USER default: "Usuario ISP:"];
	myTextISPUserName = [JText new];
	[myTextISPUserName setWidth: 20];
	[myTextISPUserName setHeight: 1];
	[self addFormComponent: myTextISPUserName];

	[self addFormNewPage];

	// ISP Password ------------------------------------------------------
	myLabelISPPassword = [self addLabelFromResource: RESID_ISP_PASSW default: "Clave ISP:"];
	myTextISPPassword = [JText new];
	[myTextISPPassword setWidth: 20];
	[myTextISPPassword setHeight: 1];	
  [myTextISPPassword setMaxLen: 15];
	[self addFormComponent: myTextISPPassword];

	[self addFormNewPage];

	// Attempts ------------------------------------------------------
	myLabelAttemptsQty = [self addLabelFromResource: RESID_ATTEMPTS_QTY default: "No. reintentos:"];
	myTextAttemptsQty = [JText new];
	[myTextAttemptsQty setNumericMode: TRUE];
  [myTextAttemptsQty setWidth: 2];
	[self addFormComponent: myTextAttemptsQty];

	[self addFormNewPage];
	  
	// Time between attempts ------------------------------------------------------
	myLabelTimeBetweenAttempts = [self addLabelFromResource: RESID_ATTEMPTS_MINUTE default: "Minutos reint.:"];
	myTextATimeBetweenAttempts = [JText new];
	[myTextATimeBetweenAttempts setNumericMode: TRUE];
  [myTextATimeBetweenAttempts setWidth: 3];
	[myTextATimeBetweenAttempts setEnabled: FALSE];
	[self addFormComponent: myTextATimeBetweenAttempts];

	[self addFormNewPage];

	// Connect by
	myLabelConnectBy = [self addLabelFromResource: RESID_ConnectionSettings_CONNECT_BY default: "Tipo direccion:"];
	myComboConnectBy = [JCombo new];
	[myComboConnectBy addString: getResourceStringDef(RESID_ConnectionSettings_CONNECT_BY_Ip, "IP")];
	[myComboConnectBy addString: getResourceStringDef(RESID_ConnectionSettings_CONNECT_BY_Domain, "Dominio")];
	[myComboConnectBy setOnSelectAction: self 	action: "connectionBy_onSelect"];
	[self addFormComponent: myComboConnectBy];

	[self addFormNewPage];

	// Dominio
	myLabelDomainSup = [self addLabelFromResource: RESID_ConnectionSettings_CONNECT_BY_Domain default: "Dominio"];
	myTextDomainSup = [JText new];
	[myTextDomainSup setWidth: 10];
	[myTextDomainSup setHeight: 1];
	[self addFormComponent: myTextDomainSup];  

	[self addFormNewPage];

	// IP SAR II  ---------------------------------------------------------------
	myLabelIP = [self addLabelFromResource: RESID_SERVER_IP default: "IP Servidor:"];
	myTextIP = [JText new];
	[myTextIP setNumericMode: TRUE];
	[myTextIP setWidth: 16];
	[myTextIP setHeight: 1];
	[myTextIP setNumericType: JTextNumericType_IP];  
	[self addFormComponent: myTextIP];  

	[self addFormNewPage];

	//Puerto TCP
	myLabelTCPPort = [self addLabelFromResource: RESID_DESTINATION_PORT default: "Puerto Destino:"];
	myTextTCPPort = [JText new];
	[myTextTCPPort setNumericMode: TRUE];
	[myTextTCPPort setWidth: 6];
	[myTextTCPPort setHeight: 1];
	[self addFormComponent: myTextTCPPort];  

	[self addFormNewPage];
	
	// Puerto COM
	myLabelComPort = [self addLabelFromResource: RESID_COM_PORT default: "Puerto COM:"];
	myComboComPort = [JCombo new];
	[myComboComPort setWidth: 17];
	[myComboComPort setHeight: 1];
	[myComboComPort addString: getResourceStringDef(RESID_INTERNAL_MODEM, "MODEM INTERNO")];
	[myComboComPort addString: "COM 1"];
	[myComboComPort addString: "COM 2"];
	[self addFormComponent: myComboComPort];

	[self addFormNewPage];

	// Speed
	myLabelSpeed = [self addLabelFromResource: RESID_CONECTION_SPEED default: "Velocidad conexion:"];
	myComboSpeed = [JCombo new];
	[myComboSpeed setWidth: 10];
	[myComboSpeed setHeight: 1];

	// Agrego las velocidades permitidas
	for (i = 0; i < sizeOfArray(ModemSpeed); i++) {
		sprintf(buf, "%d", ModemSpeed[i]);
		[myComboSpeed addString: buf];
	}
	
	[self addFormComponent: myComboSpeed];

	[self addFormNewPage];

	// From hour ----------------------------------------------------------
	myLabelFromHour = [self addLabelFromResource: RESID_FROM_HOUR_BE default: "Hora desde B.E.:"];
	myTextFromHour = [JText new];
	[myTextFromHour setNumericMode: TRUE];
  [myTextFromHour setWidth: 2];
	[myTextFromHour setEnabled: FALSE];
	[self addFormComponent: myTextFromHour];
	
	[self addFormNewPage];
	
	// To hour ----------------------------------------------------------
	myLabelToHour = [self addLabelFromResource: RESID_TO_HOUR_BE default: "Hora hasta B.E.:"];
	myTextToHour = [JText new];
	[myTextToHour setNumericMode: TRUE];
	[myTextToHour setEnabled: FALSE];
  [myTextToHour setWidth: 2];
	[self addFormComponent: myTextToHour];

	[self addFormNewPage];

	// Conexion activa ?
	myLabelActive = [self addLabelFromResource: RESID_AUTO_SUPERV default: "Superv. programada:"];
	myComboActive = [JCombo new];
	[myComboActive setWidth: 10];
	[myComboActive setHeight: 1];
	[myComboActive addString: getResourceStringDef(RESID_YES_UPPER, "SI")];
	[myComboActive addString: getResourceStringDef(RESID_NO_UPPER, "NO")];
	[self addFormComponent: myComboActive];
	
	[self addFormNewPage];
		
	// Proxima fecha supervision
	myLabelNextTelDate = [self addLabelFromResource: RESID_SUPERV_DATE default: "Fecha superv.:"];
	myDateNextTelDate = [JDate new];
	[myDateNextTelDate setJDateFormat: [[RegionalSettings getInstance] getDateFormat]];
	[myDateNextTelDate setSystemTimeMode: FALSE];
	[myDateNextTelDate setEnabled: FALSE];
	[self addFormComponent: myDateNextTelDate];

	[self addFormNewPage];
	
	// Proxima hora supervision
	myLabelNextTelTime = [self addLabelFromResource: RESID_SUPERV_TIME default: "Hora superv.:"];
	myTimeNextTelTime = [JTime new];
	[myTimeNextTelTime setSystemTimeMode: FALSE];
	[myTimeNextTelTime setEnabled: FALSE];
	[self addFormComponent: myTimeNextTelTime];
	
	[self addFormNewPage];
		
	// Proxima fecha secundaria supervision
	myLabelNextSecTelDate = [self addLabelFromResource: RESID_SUPERV_SECONDARY_DATE default: "Fecha superv. sec.:"];
	myDateNextSecTelDate = [JDate new];
	[myDateNextSecTelDate setJDateFormat: [[RegionalSettings getInstance] getDateFormat]];
	[myDateNextSecTelDate setSystemTimeMode: FALSE];
	[myDateNextSecTelDate setEnabled: FALSE];
	[self addFormComponent: myDateNextSecTelDate];

	[self addFormNewPage];
	
	// Proxima hora secundaria supervision
	myLabelNextSecTelTime = [self addLabelFromResource: RESID_SUPERV_SECONDARY_TIME default: "Hora superv. sec.:"];
	myTimeNextSecTelTime = [JTime new];
	[myTimeNextSecTelTime setSystemTimeMode: FALSE];
	[myTimeNextSecTelTime setEnabled: FALSE];
	[self addFormComponent: myTimeNextSecTelTime];

	[self addFormNewPage];
		
	// Marco
	myLabelFrame = [self addLabelFromResource: RESID_FRAME default: "Marco:"];
	myTextFrame = [JText new];
	[myTextFrame setNumericMode: TRUE];
  [myTextFrame setWidth: 2];
	[myTextFrame setEnabled: FALSE];
	[self addFormComponent: myTextFrame];
	
	[self addFormNewPage];
		
	// Supervision por transaccion
	myLabelInformDeposits = [self addLabel: getResourceStringDef(RESID_INFORM_DEPOSITS, "Informar dep. inmediat.:")];
	myComboInformDeposits = [self createNoYesCombo];

	myLabelInformExtractions = [self addLabel: getResourceStringDef(RESID_INFORM_EXTRACTIONS, "Informar ext. inmediat.:")];
	myComboInformExtractions = [self createNoYesCombo];

	myLabelInformAlarms = [self addLabel: getResourceStringDef(RESID_INFORM_ALARMS, "Informar alarm. inmediat.:")];
	myComboInformAlarms = [self createNoYesCombo];

	myLabelInformZClose = [self addLabel: getResourceStringDef(RESID_UNDEFINED, "Informar cierre inmediat.:")];
	myComboInformZClose = [self createNoYesCombo];

  [self setConfirmAcceptOperation: TRUE];
	
}

/**/
- (void) onCancelForm: (id) anInstance
{
	printd("JTelesupervisionEditForm:onCancelForm\n");

	assert(anInstance != NULL);

	if ([anInstance getTelesupId] > 0)
		[anInstance restore];
}

/**/
- (void) connectionBy_onSelect
{

	[myLabelIP setVisible: FALSE];
	[myTextIP setVisible: FALSE];

	[myLabelDomainSup setVisible: FALSE];
	[myTextDomainSup setVisible: FALSE];


	if (([myComboConnectBy getSelectedIndex]) == ConnectionByType_IP) {
	
		[myLabelIP setVisible: TRUE];
		[myTextIP setVisible: TRUE];
		[myTextIP setWidth: 20];
		[myTextIP setHeight: 2];

		[myTextDomainSup setText: ""];

	}

	if (([myComboConnectBy getSelectedIndex]) == ConnectionByType_DOMAIN) {

		[myLabelDomainSup setVisible: TRUE];
		[myTextDomainSup setVisible: TRUE];
		[myTextDomainSup setWidth: 20];
		[myTextDomainSup setHeight: 2];

		[myTextIP setText: ""];
	}

	[self paintComponent];

}

/**/
- (void) connectionType_onSelect
{
	
	[myLabelISPPhoneNumber setVisible: FALSE];
	[myTextISPPhoneNumber setVisible: FALSE];

	[myLabelISPUserName setVisible: FALSE];
	[myTextISPUserName setVisible: FALSE];

	[myLabelISPPassword setVisible: FALSE];
	[myTextISPPassword setVisible: FALSE];	
	
	[myLabelConnectBy setVisible: FALSE];
	[myComboConnectBy setVisible: FALSE];
	
	[myLabelComPort setVisible: FALSE];
	[myComboComPort setVisible: FALSE];
	
	[myLabelTCPPort setVisible: FALSE];
	[myTextTCPPort setVisible: FALSE];

	[myLabelSpeed setVisible: FALSE];
	[myComboSpeed setVisible: FALSE];

	[myLabelDomain setVisible: FALSE];
	[myTextDomain setVisible: FALSE];

	if ((getConnectionType([myComboConnectionType getSelectedIndex]) == ConnectionType_LAN)) {
	
		[myLabelConnectBy setVisible: TRUE];
		[myComboConnectBy setVisible: TRUE];

		[myLabelTCPPort setVisible: TRUE];
		[myTextTCPPort setVisible: TRUE];		
	
	}	else if (getConnectionType([myComboConnectionType getSelectedIndex]) == ConnectionType_GPRS) {
	
		[myLabelISPUserName setVisible: TRUE];
		[myTextISPUserName setVisible: TRUE];

		[myLabelISPPassword setVisible: TRUE];
		[myTextISPPassword setVisible: TRUE];

		[myLabelISPPhoneNumber setVisible: TRUE];
		[myTextISPPhoneNumber setVisible: TRUE];
		[myTextISPPhoneNumber setNumericMode: FALSE];

		[myLabelDomain setVisible: TRUE];
		[myTextDomain setVisible: TRUE];

		[myLabelComPort setVisible: TRUE];
		[myComboComPort setVisible: TRUE];		
		
		[myLabelSpeed setVisible: TRUE];
		[myComboSpeed setVisible: TRUE];		

		[myLabelConnectBy setVisible: TRUE];
		[myComboConnectBy setVisible: TRUE];

		[myLabelTCPPort setVisible: TRUE];
		[myTextTCPPort setVisible: TRUE];		

		
	}

	[self paintComponent];
}

/**/
- (void) onModelToView: (id) anInstance
{
	CONNECTION_SETTINGS connection = [anInstance getConnection1];
	int comPort;
	
	printd("JTelesupervisionEditForm:onModelToView\n");
	assert(anInstance != NULL);
	assert(connection);

	if ([anInstance getTelcoType] == CMP_TSUP_ID) {

		[myLabelDescription setVisible: FALSE];
		[myTextDescription setVisible: FALSE];

		[myLabelFrequency setVisible: FALSE];
		[myTextFrequency setVisible: FALSE];

		[myLabelAttemptsQty setVisible: FALSE];
		[myTextAttemptsQty setVisible: FALSE];

		[myLabelTimeBetweenAttempts setVisible: FALSE];
		[myTextATimeBetweenAttempts setVisible: FALSE];
		
		[myLabelISPPhoneNumber setVisible: FALSE];
		[myTextISPPhoneNumber setVisible: FALSE];

		[myLabelISPUserName setVisible: FALSE];
		[myTextISPUserName setVisible: FALSE];

		[myLabelISPPassword setVisible: FALSE];
		[myTextISPPassword setVisible: FALSE];

		[myLabelConnectionType setVisible: FALSE];
		[myComboConnectionType setVisible: FALSE];
	
		[myLabelConnectBy setVisible: FALSE];
		[myComboConnectBy setVisible: FALSE];

		[myLabelDomainSup setVisible: FALSE];
		[myTextDomainSup setVisible: FALSE]; 	
	
		[myLabelIP setVisible: FALSE];
		[myTextIP setVisible: FALSE];
		
		[myLabelTCPPort setVisible: FALSE];
		[myTextTCPPort setVisible: FALSE];

		[myLabelDomain setVisible: FALSE];
		[myTextDomain setVisible: FALSE];

		[myLabelFromHour setVisible: FALSE];
		[myTextFromHour setVisible: FALSE];
		
		[myLabelToHour setVisible: FALSE];
		[myTextToHour setVisible: FALSE];

		[myLabelActive setVisible: FALSE];
		[myComboActive setVisible: FALSE];
		[myComboActive setSelectedIndex: 0];
		
		[myLabelNextTelDate setVisible: FALSE];
		[myDateNextTelDate setVisible: FALSE];
	
		[myLabelNextTelTime setVisible: FALSE];
		[myTimeNextTelTime setVisible: FALSE];
	
		[myLabelNextSecTelDate setVisible: FALSE]; 
		[myDateNextSecTelDate setVisible: FALSE];
	
		[myLabelNextSecTelTime setVisible: FALSE];
		[myTimeNextSecTelTime setVisible: FALSE];
	
		[myLabelFrame setVisible: FALSE];
		[myTextFrame setVisible: FALSE];

		[myComboTelesupType addString: "CMP"];

		[myLabelInformDeposits setVisible: FALSE];
		[myComboInformDeposits setVisible: FALSE];

		[myLabelInformExtractions setVisible: FALSE];
		[myComboInformExtractions setVisible: FALSE];

		[myLabelInformAlarms setVisible: FALSE];
		[myComboInformAlarms setVisible: FALSE];

		[myLabelInformZClose setVisible: FALSE];
		[myComboInformZClose setVisible: FALSE];

			
	} else if (([anInstance getTelcoType] == G2_TSUP_ID) || 
						 ([anInstance getTelcoType] == SARII_PTSD_TSUP_ID) || 
						 ([anInstance getTelcoType] == PIMS_TSUP_ID)) {

		if ([anInstance getTelcoType] == G2_TSUP_ID) [myComboTelesupType addString: "G2"];
		else 	if ([anInstance getTelcoType] == PIMS_TSUP_ID) [myComboTelesupType addString: "PIMS"];
		else 	if ([anInstance getTelcoType] == CMP_OUT_TSUP_ID) [myComboTelesupType addString: getResourceStringDef(RESID_CMP_OUT_CONNECTION, "CMP Remoto")];
		else if ([anInstance getTelcoType] == SARII_PTSD_TSUP_ID) [myComboTelesupType addString: "SARII-PTSD"];
				
		[myLabelAttemptsQty setVisible: FALSE];
		[myTextAttemptsQty setVisible: FALSE];

		[myComboActive setSelectedIndex: 0];

		// Tipo de conexion
		[myComboConnectionType setSelectedIndex: getConnectionTypeIndex([connection getConnectionType])];
    [self connectionType_onSelect];

	} else if ([anInstance getTelcoType] == HOYTS_BRIDGE_TSUP_ID) {

		[myComboTelesupType addString: "HOYTS BRIDGE"];

		[myLabelInformExtractions setVisible: FALSE];
		[myComboInformExtractions setVisible: FALSE];

		[myLabelInformAlarms setVisible: FALSE];
		[myComboInformAlarms setVisible: FALSE];

		[myLabelInformZClose setVisible: FALSE];
		[myComboInformZClose setVisible: FALSE];

		[myLabelAttemptsQty setVisible: FALSE];
		[myTextAttemptsQty setVisible: FALSE];

		[myComboActive setSelectedIndex: 0];

		// Tipo de conexion
		[myComboConnectionType setSelectedIndex: getConnectionTypeIndex([connection getConnectionType])];
    [self connectionType_onSelect];

	}	else if ([anInstance getTelcoType] == BRIDGE_TSUP_ID) {

		[myComboTelesupType addString: "BRIDGE"];

		[myLabelInformExtractions setVisible: FALSE];
		[myComboInformExtractions setVisible: FALSE];

		[myLabelInformAlarms setVisible: FALSE];
		[myComboInformAlarms setVisible: FALSE];

		[myLabelAttemptsQty setVisible: FALSE];
		[myTextAttemptsQty setVisible: FALSE];

		[myComboActive setSelectedIndex: 0];

		// Tipo de conexion
		[myComboConnectionType setSelectedIndex: getConnectionTypeIndex([connection getConnectionType])];
    [self connectionType_onSelect];

	} else if ([anInstance getTelcoType] == FTP_SERVER_TSUP_ID) {
		[myComboTelesupType addString: "FTP Server"];
	
		[myLabelSystemId setVisible: FALSE];
		[myTextSystemId setVisible: FALSE];

		[myLabelRemoteUserName setVisible: FALSE];
		[myTextRemoteUserName setVisible: FALSE];

		[myLabelRemotePassword setVisible: FALSE];
		[myTextRemotePassword setVisible: FALSE];

		[myLabelRemoteSistemId setVisible: FALSE];
		[myTextRemoteSistemId setVisible: FALSE];

		[myLabelAttemptsQty setVisible: FALSE];
		[myTextAttemptsQty setVisible: FALSE];

		[myComboActive setSelectedIndex: 0];

		// Tipo de conexion
		[myComboConnectionType setSelectedIndex: getConnectionTypeIndex([connection getConnectionType])];
    [self connectionType_onSelect];


	} else if ([anInstance getTelcoType] == POS_TSUP_ID) {
		[myComboTelesupType addString: "POS"];
	
		[myLabelFrequency setVisible: FALSE];
		[myTextFrequency setVisible: FALSE];

		[myLabelSystemId setVisible: FALSE];
		[myTextSystemId setVisible: FALSE];

		[myLabelTimeBetweenAttempts setVisible: FALSE];
		[myTextATimeBetweenAttempts setVisible: FALSE];

		[myLabelConnectBy setVisible: FALSE];
		[myComboConnectBy setVisible: FALSE];
		[myComboConnectBy setSelectedIndex: 0];

		[myLabelISPPhoneNumber setVisible: FALSE];
		[myTextISPPhoneNumber setVisible: FALSE];

		[myLabelISPUserName setVisible: FALSE];
		[myTextISPUserName setVisible: FALSE];

		[myLabelISPPassword setVisible: FALSE];
		[myTextISPPassword setVisible: FALSE];

		[myLabelRemoteUserName setVisible: FALSE];
		[myTextRemoteUserName setVisible: FALSE];

		[myLabelRemotePassword setVisible: FALSE];
		[myTextRemotePassword setVisible: FALSE];

		[myLabelRemoteSistemId setVisible: FALSE];
		[myTextRemoteSistemId setVisible: FALSE];

		[myLabelAttemptsQty setVisible: FALSE];
		[myTextAttemptsQty setVisible: FALSE];

		[myLabelInformDeposits setVisible: FALSE];
		[myComboInformDeposits setVisible: FALSE];

		[myLabelInformExtractions setVisible: FALSE];
		[myComboInformExtractions setVisible: FALSE];

		[myLabelInformAlarms setVisible: FALSE];
		[myComboInformAlarms setVisible: FALSE];

		[myLabelInformZClose setVisible: FALSE];
		[myComboInformZClose setVisible: FALSE];


		[myLabelConnectionType setVisible: FALSE];
		[myComboConnectionType setVisible: FALSE];
		[myComboConnectionType setSelectedIndex: 0];

		[myLabelIP setVisible: FALSE];
		[myTextIP setVisible: FALSE];

		[myLabelDomainSup setVisible: FALSE];
		[myTextDomainSup setVisible: FALSE];

		[myLabelDomain setVisible: FALSE];
		[myTextDomain setVisible: FALSE];

		[myLabelFromHour setVisible: FALSE];
		[myTextFromHour setVisible: FALSE];
		
		[myLabelToHour setVisible: FALSE];
		[myTextToHour setVisible: FALSE];

		[myLabelNextTelDate setVisible: FALSE];
		[myDateNextTelDate setVisible: FALSE];
	
		[myLabelNextTelTime setVisible: FALSE];
		[myTimeNextTelTime setVisible: FALSE];
	
		[myLabelNextSecTelDate setVisible: FALSE]; 
		[myDateNextSecTelDate setVisible: FALSE];
	
		[myLabelNextSecTelTime setVisible: FALSE];
		[myTimeNextSecTelTime setVisible: FALSE];
	
		[myLabelFrame setVisible: FALSE];
		[myTextFrame setVisible: FALSE];
		
		[myLabelComPort setVisible: FALSE];
		[myComboComPort setVisible: FALSE];
	
		[myLabelSpeed setVisible: FALSE];
		[myComboSpeed setVisible: FALSE];

		[myLabelActive setVisible: FALSE];
		[myComboActive setVisible: FALSE];
		[myComboActive setSelectedIndex: 0];

		// Tipo de conexion
		//[myComboConnectionType setSelectedIndex: getConnectionTypeIndex([connection getConnectionType])];
    //[self connectionType_onSelect];

	}
		else if ([anInstance getTelcoType] == IMAS_TSUP_ID) {
	
		[myComboTelesupType addString: "IMAS"];
						
		[myLabelAttemptsQty setVisible: FALSE];
		[myTextAttemptsQty setVisible: FALSE];

		[myLabelRemoteUserName setVisible: FALSE];
		[myTextRemoteUserName setVisible: FALSE];
	
		[myLabelRemotePassword setVisible: FALSE];
		[myTextRemotePassword setVisible: FALSE];
		
		[myLabelRemoteSistemId setVisible: FALSE];
		[myTextRemoteSistemId setVisible: FALSE];		

		[myLabelNextTelDate setVisible: FALSE];
		[myDateNextTelDate setVisible: FALSE];
	
		[myLabelNextTelTime setVisible: FALSE];
		[myTimeNextTelTime setVisible: FALSE];
	
		[myLabelNextSecTelDate setVisible: FALSE]; 
		[myDateNextSecTelDate setVisible: FALSE];
	
		[myLabelNextSecTelTime setVisible: FALSE];
		[myTimeNextSecTelTime setVisible: FALSE];
	
		[myLabelFrame setVisible: FALSE];
		[myTextFrame setVisible: FALSE];
		
		[myComboActive setSelectedIndex: 0];
		
		// Tipo de conexion
		[myComboConnectionType setSelectedIndex: getConnectionTypeIndex([connection getConnectionType])];
		[self connectionType_onSelect];		

	}

	else if ([anInstance getTelcoType] == CMP_OUT_TSUP_ID) {

		[myLabelFrequency setVisible: FALSE];
		[myTextFrequency setVisible: FALSE];

		[myLabelAttemptsQty setVisible: FALSE];
		[myTextAttemptsQty setVisible: FALSE];

		[myLabelTimeBetweenAttempts setVisible: FALSE];
		[myTextATimeBetweenAttempts setVisible: FALSE];

		[myLabelFromHour setVisible: FALSE];
		[myTextFromHour setVisible: FALSE];
		
		[myLabelToHour setVisible: FALSE];
		[myTextToHour setVisible: FALSE];

		[myLabelActive setVisible: FALSE];
		[myComboActive setVisible: FALSE];
		[myComboActive setSelectedIndex: 0];
		
		[myLabelNextTelDate setVisible: FALSE];
		[myDateNextTelDate setVisible: FALSE];
	
		[myLabelNextTelTime setVisible: FALSE];
		[myTimeNextTelTime setVisible: FALSE];
	
		[myLabelNextSecTelDate setVisible: FALSE]; 
		[myDateNextSecTelDate setVisible: FALSE];
	
		[myLabelNextSecTelTime setVisible: FALSE];
		[myTimeNextSecTelTime setVisible: FALSE];
	
		[myLabelFrame setVisible: FALSE];
		[myTextFrame setVisible: FALSE];
	
		[myComboTelesupType addString: getResourceStringDef(RESID_CMP_OUT_CONNECTION, "CMP Remoto")];

		[myLabelInformDeposits setVisible: FALSE];
		[myComboInformDeposits setVisible: FALSE];

		[myLabelInformExtractions setVisible: FALSE];
		[myComboInformExtractions setVisible: FALSE];

		[myLabelInformAlarms setVisible: FALSE];
		[myComboInformAlarms setVisible: FALSE];

		[myLabelInformZClose setVisible: FALSE];
		[myComboInformZClose setVisible: FALSE];
		
		[myComboConnectionType setSelectedIndex: getConnectionTypeIndex([connection getConnectionType])];
		[self connectionType_onSelect];		
}

else {
	
		[myLabelRemoteUserName setVisible: FALSE];
		[myTextRemoteUserName setVisible: FALSE];
	
		[myLabelRemotePassword setVisible: FALSE];
		[myTextRemotePassword setVisible: FALSE];
		
		[myLabelRemoteSistemId setVisible: FALSE];
		[myTextRemoteSistemId setVisible: FALSE];		
	
			// Tipo de conexion
		[myComboConnectionType setSelectedIndex: getConnectionTypeIndex([connection getConnectionType])];

		[myLabelNextTelDate setVisible: FALSE];
		[myDateNextTelDate setVisible: FALSE];
	
		[myLabelNextTelTime setVisible: FALSE];
		[myTimeNextTelTime setVisible: FALSE];
	
		[myLabelNextSecTelDate setVisible: FALSE]; 
		[myDateNextSecTelDate setVisible: FALSE];
	
		[myLabelNextSecTelTime setVisible: FALSE];
		[myTimeNextSecTelTime setVisible: FALSE];
	
		[myLabelFrame setVisible: FALSE];
		[myTextFrame setVisible: FALSE];
	
		[myComboTelesupType addString: "SAR II"];
		[self connectionType_onSelect];
		
	}

  // Description
  [myTextDescription setText: [anInstance getTelesupDescription]];
  
  // Frecuency
  [myTextFrequency setLongValue: [anInstance getTelesupFrequency]];  
  
  //System Id
  [myTextSystemId setText: [anInstance getSystemId]];

	// User name
  [myTextUserName setText: [anInstance getTelesupUserName]];

	// Password
  [myTextPassword setText: [anInstance getTelesupPassword]];

	// Remote User Name
	[myTextRemoteUserName setText: [anInstance getRemoteUserName]];

	// Remote Password
	[myTextRemotePassword setText: [anInstance getRemotePassword]];
	
	//systen id
	[myTextRemoteSistemId setText: [anInstance getRemoteSystemId]];

  // Attempts qty
	[myTextAttemptsQty setLongValue: [anInstance getAttemptsQty]];
  
  // Time between attempts
	[myTextATimeBetweenAttempts setLongValue: [anInstance getTimeBetweenAttempts]];

	// ISP Phone Number
	[myTextISPPhoneNumber setText: [connection getISPPhoneNumber]];
	
	// ISP User name
  [myTextISPUserName setText: [connection getConnectionUserName]];

	// ISP Password
  [myTextISPPassword setText: [connection getConnectionPassword]];

	// Tipo de direccion
	[myComboConnectBy setSelectedIndex: [connection getConnectBy]];

	if ([anInstance getTelcoType] != POS_TSUP_ID) {
		[self connectionBy_onSelect];
	}

	// dominio
	[myTextDomainSup setText: [connection getDomainSup]];

  // IP
	[myTextIP setText: [connection getIP]];

	if ([anInstance getTelcoType] == POS_TSUP_ID)
		[myTextIP setText: "127.0.0.1"];
	
	//tcp port
	[myTextTCPPort setLongValue: [connection getConnectionTCPPortDestination]];

	// COM PORT
	comPort = [connection getConnectionPortId];
	if (comPort > 2 || comPort == 4) comPort = 0;
	[myComboComPort setSelectedIndex: comPort];
	
	// SPEED
	[myComboSpeed setSelectedIndex: findModemSpeed([connection getConnectionSpeed])];

  // FromHour
	[myTextFromHour setLongValue: [anInstance getFromHour]];

	// ToHour
	[myTextToHour setLongValue: [anInstance getToHour]];

	// Active
	if ([anInstance isActive]) [myComboActive setSelectedIndex: 0];
	else [myComboActive setSelectedIndex: 1];
	
	// Frame
	[myTextFrame setLongValue: [anInstance getTelesupFrame]];
	
	// Proxima fecha supervision
	[myDateNextTelDate setDateValue: [anInstance getNextTelesupDateTime]];
	
	// Proxima hora supervision
	[myTimeNextTelTime setDateTimeValue: [anInstance getNextTelesupDateTime]];
	
	// Proxima fecha supervision secundaria
	[myDateNextSecTelDate setDateValue: [anInstance getNextSecondaryTelesupDateTime]];	
	
	// Proxima hora supervision secundaria
	[myTimeNextSecTelTime setDateTimeValue: [anInstance getNextSecondaryTelesupDateTime]];
	
	// DOMINIO / APN
	[myTextDomain setText: [connection getDomain]];

	// Supervisar por transaccion
	[myComboInformDeposits setSelectedIndex: [anInstance getInformDepositsByTransaction]];

	[myComboInformExtractions setSelectedIndex: [anInstance getInformExtractionsByTransaction]];

	[myComboInformAlarms setSelectedIndex: [anInstance getInformAlarmsByTransaction]];

	[myComboInformZClose setSelectedIndex: [anInstance getInformZCloseByTransaction]];

	myOldConnectionType = [connection getConnectionType];

}

/**/
- (void) onViewToModel: (id) anInstance
{
	CONNECTION_SETTINGS connection = [anInstance getConnection1];
	int comPort;
	int connectionType = ConnectionType_LAN;
	char buff[30];
	char lastIdStr[5];
	
	printd("JConnectionEditForm:onViewToModel\n");

	assert(anInstance != NULL);
	assert(connection != NULL);
	
  //Description
  [anInstance setTelesupDescription: [myTextDescription getText]];
  
  //Frecuency
  [anInstance setTelesupFrequency: [myTextFrequency getLongValue]];

  // System id
  [anInstance setSystemId: [myTextSystemId getText]];
  
	// User name
  [anInstance setTelesupUserName: [myTextUserName getText]];

	// Password
  [anInstance setTelesupPassword: [myTextPassword getText]];

	// Remote User name
	[anInstance setRemoteUserName: [myTextRemoteUserName getText]];

	// Remote Password
	[anInstance setRemotePassword: [myTextRemotePassword getText]];
	
	//system id
	[anInstance setRemoteSystemId: [myTextRemoteSistemId getText]];
	
  // Attempts qty
  [anInstance setAttemptsQty: [myTextAttemptsQty getLongValue]];
  
  // Time between attempts
  [anInstance setTimeBetweenAttempts: [myTextATimeBetweenAttempts getLongValue]];

	// Description
	// le pongo un description a mano cuando se da de alta
	if (strlen([connection getConnectionDescription]) == 0) {
    lastIdStr[0] = '\0';
	  buff[0] = '\0';
    sprintf(lastIdStr, "%d", [[TelesupervisionManager getInstance] getLastConnectionId]+1);
    strcpy(buff,getResourceStringDef(RESID_CONNECTION_, "Conexion_"));
    strcat(buff,lastIdStr);
    [connection setConnectionDescription: buff];
  }
	
	// Modem Phone Number
//  [connection setModemPhoneNumber: [myTextModemPhoneNumber getText]];
	
	//ISP Phone Number
  [connection setISPPhoneNumber: [myTextISPPhoneNumber getText]];
	
	// ISP User name
  [connection setConnectionUserName: [myTextISPUserName getText]];

	// ISP Password
  [connection setConnectionPassword: [myTextISPPassword getText]];

	// tipo de direccion
	[connection setConnectBy: [myComboConnectBy getSelectedIndex]];

	if (([myComboConnectBy getSelectedIndex]) == ConnectionByType_IP) {
  	[connection setConnectionIP: [myTextIP getText]];
		[connection setDomainSup: ""];
	}

	if (([myComboConnectBy getSelectedIndex]) == ConnectionByType_DOMAIN) {
		// dominio
		[connection setDomainSup: [myTextDomainSup getText]];	
  	[connection setConnectionIP: ""];
	}

	
	// COM PORT
	comPort = [myComboComPort getSelectedIndex];
	if (comPort == 0) comPort = 4;
	[connection setPortId: comPort];
	
	// SPEED
	[connection setConnectionSpeed: ModemSpeed[ [myComboSpeed getSelectedIndex]  ]];

  // From hour
  [anInstance setFromHour: [myTextFromHour getLongValue]];

  // To hour
  [anInstance setToHour: [myTextToHour getLongValue]];

	// ConnectionType
	// Para SARII se selecciona, para SARI es siempre PPP y para el resto MODEM
	if ([anInstance getTelcoType] == SARII_TSUP_ID) {
		connectionType = getConnectionType([myComboConnectionType getSelectedIndex]);
	} else if ( ([anInstance getTelcoType] == CMP_TSUP_ID) || 
							([anInstance getTelcoType] == POS_TSUP_ID) ) {
		connectionType = ConnectionType_LAN;
	} else if (([anInstance getTelcoType] == G2_TSUP_ID) || 
						 ([anInstance getTelcoType] == SARII_PTSD_TSUP_ID) || 
						 ([anInstance getTelcoType] == PIMS_TSUP_ID) || 	
						 ([anInstance getTelcoType] == CMP_OUT_TSUP_ID) ||
						 ([anInstance getTelcoType] == HOYTS_BRIDGE_TSUP_ID) ||
						 ([anInstance getTelcoType] == BRIDGE_TSUP_ID) ||
						 ([anInstance getTelcoType] == FTP_SERVER_TSUP_ID)) {
		connectionType = getConnectionType([myComboConnectionType getSelectedIndex]);
	} else if ([anInstance getTelcoType] == IMAS_TSUP_ID) {
		connectionType = getConnectionType([myComboConnectionType getSelectedIndex]);
	}	else {
		connectionType = ConnectionType_LAN;
	}
		
	[connection setConnectionType: connectionType];
	
	// TCP Puerto en este caso siempre va en cero
	[connection setTCPPortDestination: [myTextTCPPort getLongValue]];
	
	// Active
	if ([myComboActive getSelectedIndex] == 0) [anInstance setActive: TRUE];
	else [anInstance setActive: FALSE];
	
	// DOMAIN / APN
	[connection setDomain: [myTextDomain getText]];

	// Supervisar por transaccion

	[anInstance setInformDepositsByTransaction: [myComboInformDeposits getSelectedIndex]];
	[anInstance setInformExtractionsByTransaction: [myComboInformExtractions getSelectedIndex]];
	[anInstance setInformAlarmsByTransaction: [myComboInformAlarms getSelectedIndex]];
	[anInstance setInformZCloseByTransaction: [myComboInformZClose getSelectedIndex]];


}

/**/
- (void) validateFields
{
	
}

/**/
- (void) onAcceptForm: (id) anInstance
{
	volatile int error = 0;
	volatile JFORM processForm = NULL;
	CONNECTION_SETTINGS connection = [anInstance getConnection1];
	
	//doLog(0,"JConnectionEditForm:onAcceptForm\n");

	assert(anInstance != NULL);
	assert(connection != NULL);
	
	// Graba la conexion

	TRY
  	processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];

  	// Le paso el TelcoType asi puede validar los datos segun el tipo de supervision
  	[connection setTelcoType: [anInstance getTelcoType]];

  	[connection applyChanges];
  
  	[anInstance setConnectionId1: [connection getConnectionId]];
  	[anInstance applyChanges];

    [processForm closeProcessForm];
    [processForm free];
  CATCH
  
  	[processForm closeProcessForm];
  	[processForm free];
    RETHROW();
    
  END_TRY


	TRY
		if (![[TelesupervisionManager getInstance] writeTelesupsToFile])
			error = 1;

		[[TelesupervisionManager getInstance] updateGprsConnections: [anInstance getConnection1]];

	CATCH
		error = 1;
	END_TRY

	if (myOldConnectionType != [[anInstance getConnection1] getConnectionType] && 
			[[anInstance getConnection1] getConnectionType] == ConnectionType_GPRS) {

			[JMessageDialog askOKMessageFrom: self 
				withMessage: getResourceStringDef(RESID_SIM_CARD_RESTART_SYSTEM, "If the SIM Card needs PIN, you must restart the system!")];
	}

/*	if (error)
	{
		doLog(0,"ERROR writing supervision config to file\n");
	}*/
	
  [self closeForm];
		
}


@end

