#include "ConnectionSettingsDAO.h"
#include "ConnectionSettings.h"
#include "SettingsExcepts.h"
#include "DAOExcepts.h"
#include "ordcltn.h"
#include "DataSearcher.h"
#include "util.h"
#include "system/db/all.h"
#include "SettingsExcepts.h"
#include "system/db/all.h"
#include "TelesupDefs.h"
#include "Audit.h"
#include "MessageHandler.h"
#include "Event.h"
#include "TelesupervisionManager.h" 

static id singleInstance = NULL;

@implementation ConnectionSettingsDAO

- (id) newConFromRecordSet: (id) aRecordSet; 

/**/
+ new
{
	if (!singleInstance) singleInstance = [super new];
	return singleInstance;
}

/**/
- initialize
{
	[super initialize];
	return self;
}

/**/
- free
{
	return [super free];
}

/**/
+ getInstance
{
	return [self new];
}

/*
 *	Devuelve las conexiones en base a la informacion del registro actual del recordset.
 */

- (id) newConFromRecordSet: (id) aRecordSet
{
	CONNECTION_SETTINGS obj;
	char buffer[61];
  
	obj = [ConnectionSettings new];

	[obj setConnectionId: [aRecordSet getShortValue: "CONNECTION_ID"]];
	[obj setConnectionDescription: [aRecordSet getStringValue: "DESCRIPTION" buffer: buffer]];
	[obj setModemPhoneNumber: [aRecordSet getStringValue: "MODEM_PHONE_NUMBER" buffer: buffer]];
  [obj setConnectionIP: [aRecordSet getStringValue: "IP" buffer: buffer]];  
	[obj setDomain: [aRecordSet getStringValue: "DOMAIN" buffer: buffer]];
  [obj setConnectionUserName: [aRecordSet getStringValue: "USER_NAME" buffer: buffer]];
  [obj setISPPhoneNumber: [aRecordSet getStringValue: "ISP_PHONE_NUMBER" buffer: buffer]];  
	[obj setConnectionPassword: [aRecordSet getStringValue: "PASSWORD" buffer: buffer]];
	[obj setConnectionType: [aRecordSet getCharValue: "TYPE"]];
	[obj setPortType: [aRecordSet getCharValue: "PORT_TYPE"]];
	[obj setPortId: [aRecordSet getCharValue: "PORT_ID"]];
	[obj setRingsQty: [aRecordSet getCharValue: "RINGS_QTY"]];
	[obj setTCPPortSource: [aRecordSet getShortValue: "TCP_PORT_SOURCE"]];
	[obj setTCPPortDestination: [aRecordSet getShortValue: "TCP_PORT_DESTINATION"]];
	[obj setPPPConnectionId: [aRecordSet getCharValue: "PPP_CONNECTION_ID"]];
/*  [obj setConnectionAttemptsQty: [aRecordSet getShortValue: "ATTEMPTS_QTY"]];
  [obj setConnectionTimeBetweenAttempts: [aRecordSet getShortValue: "TIME_BETWEEN_ATTEMPTS"]];*/
	[obj setConnectionSpeed: [aRecordSet getLongValue: "SPEED"]];
	[obj setDeleted: [aRecordSet getCharValue: "DELETED"]];
	[obj setDomainSup: [aRecordSet getStringValue: "DOMAIN_SUP" buffer: buffer]];
	[obj setConnectBy: [aRecordSet getCharValue: "CONNECT_BY"]];

	return obj;
}

/**/
- (id) loadById: (unsigned long) anId
{
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "connections" filter: "" orderFields: "CONNECTION_ID"];
	id obj = NULL;

	[myRecordSet open];
	[myRecordSet moveFirst];


	if ([myRecordSet findById: "CONNECTION_ID" value: anId]) {
		obj = [self newConFromRecordSet: myRecordSet];
		if (![obj isDeleted]) {
			[myRecordSet free];
			return obj;
		}
	}

	[myRecordSet free];
	THROW(REFERENCE_NOT_FOUND_EX);
	return NULL;
}

/**/
- (COLLECTION) loadAll
{
	COLLECTION collection = [OrdCltn new];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "connections" filter: "" orderFields: "CONNECTION_ID"];
	CONNECTION_SETTINGS obj;

	[myRecordSet open];

	while ([myRecordSet moveNext]) {
		obj = [self newConFromRecordSet: myRecordSet];
		// agrego la conexion a la coleccion solo si no se encuentra borrado logicamente
		if (![obj isDeleted]) [collection add: obj];
	}

	[myRecordSet free];

	return collection;
}

/**/
- (void) store: (id) anObject
{
	short connectionId;
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSetWithFilter: "connections" filter: "" orderFields: "CONNECTION_ID"];
	ABSTRACT_RECORDSET myRecordSetBck;
	volatile BOOL updateRecord = FALSE;

	AUDIT audit;
  char buffer[512];
  volatile BOOL alwaysLog = FALSE;

  //Valida los campos correspondientes a las conexiones. En el caso que internamente se encuentre un error,
	//arroja una excepcion de otro modo, pasa.
	[self validateFields: anObject];

  TRY

		[myRecordSet open];

		if ([anObject getConnectionId] != 0) {

			updateRecord = TRUE;
			[myRecordSet findById: "CONNECTION_ID" value: [anObject getConnectionId]];

      if ([anObject isDeleted]) audit = [[Audit new] initAuditWithCurrentUser: CONNECTION_DELETED additional: [anObject getConnectionDescription] station: 0 logRemoteSystem: TRUE];
      else  audit = [[Audit new] initAuditWithCurrentUser: CONNECTION_UPDATED additional: [anObject getConnectionDescription] station: 0 logRemoteSystem: TRUE];

		}	else {
			[myRecordSet add];
      alwaysLog = TRUE;
      audit = [[Audit new] initAuditWithCurrentUser: CONNECTION_INSERTED additional: [anObject getConnectionDescription] station: 0 logRemoteSystem: TRUE];
		}
		
    if (![anObject isDeleted]) {

      // Log de cambios
      [audit logChangeAsString: alwaysLog resourceId: RESID_ConnectionSettings_DESCRIPTION oldValue: [myRecordSet getStringValue: "DESCRIPTION" buffer: buffer] newValue: [anObject getConnectionDescription]];

      [audit logChangeAsResourceString: alwaysLog 
				resourceId: RESID_ConnectionSettings_TYPE 
				resourceStringBase: RESID_ConnectionSettings_TYPE_Desc 
				oldValue: [myRecordSet getCharValue: "TYPE"] 
				newValue: [anObject getConnectionType]
				oldReference: [myRecordSet getCharValue: "TYPE"] 
				newReference: [anObject getConnectionType]]; 

      [audit logChangeAsInteger: alwaysLog resourceId: RESID_ConnectionSettings_PORT_ID oldValue: [myRecordSet getCharValue: "PORT_ID"] newValue: [anObject getConnectionPortId]];
			[audit logChangeAsInteger: alwaysLog resourceId: RESID_ConnectionSettings_RINGS_QTY oldValue: [myRecordSet getCharValue: "RINGS_QTY"] newValue: [anObject getRingsQty]];

      if (strlen(trim([anObject getDomain])) > 0)
        [audit logChangeAsString: alwaysLog resourceId: RESID_ConnectionSettings_DOMAIN oldValue: [myRecordSet getStringValue: "DOMAIN" buffer: buffer] newValue: [anObject getDomain]];

      [audit logChangeAsString: alwaysLog resourceId: RESID_ConnectionSettings_IP oldValue: [myRecordSet getStringValue: "IP" buffer: buffer] newValue: [anObject getIP]];
      [audit logChangeAsInteger: alwaysLog resourceId: RESID_ConnectionSettings_TCP_PORT_DESTINATION oldValue: [myRecordSet getShortValue: "TCP_PORT_DESTINATION"] newValue: [anObject getConnectionTCPPortDestination]];

      if (strlen(trim([anObject getISPPhoneNumber])) > 0)
        [audit logChangeAsString: alwaysLog resourceId: RESID_ConnectionSettings_ISP_PHONE_NUMBER oldValue: [myRecordSet getStringValue: "ISP_PHONE_NUMBER" buffer: buffer] newValue: [anObject getISPPhoneNumber]];

      if (strlen(trim([anObject getConnectionUserName])) > 0)
        [audit logChangeAsString: alwaysLog resourceId: RESID_ConnectionSettings_USER_NAME oldValue: [myRecordSet getStringValue: "USER_NAME" buffer: buffer] newValue: [anObject getConnectionUserName]];

      if (strlen(trim([anObject getConnectionPassword])) > 0)
        [audit logChangeAsPassword: alwaysLog resourceId: RESID_ConnectionSettings_PASSWORD oldValue: [myRecordSet getStringValue: "PASSWORD" buffer: buffer] newValue: [anObject getConnectionPassword]];

      [audit logChangeAsInteger: alwaysLog resourceId: RESID_ConnectionSettings_SPEED oldValue: [myRecordSet getLongValue: "SPEED"] newValue: [anObject getConnectionSpeed]];
      [audit logChangeAsString: alwaysLog resourceId: RESID_ConnectionSettings_DOMAIN_SUP oldValue: [myRecordSet getStringValue: "DOMAIN_SUP" buffer: buffer] newValue: [anObject getDomainSup]];

      [audit logChangeAsResourceString: alwaysLog 
				resourceId: RESID_ConnectionSettings_CONNECT_BY 
				resourceStringBase: RESID_ConnectionSettings_CONNECT_BY 
				oldValue: [myRecordSet getCharValue: "CONNECT_BY"] 
				newValue: [anObject getConnectBy]
				oldReference: [myRecordSet getCharValue: "CONNECT_BY"] 
				newReference: [anObject getConnectBy]]; 

    }

    // Configuro el recordset y grabo
		[myRecordSet setStringValue: "DESCRIPTION" value: [anObject getConnectionDescription]];
		[myRecordSet setCharValue: "TYPE" value: [anObject getConnectionType]];
		[myRecordSet setCharValue: "PORT_TYPE" value: [anObject getConnectionPortType]];
		[myRecordSet setCharValue: "PORT_ID" value: [anObject getConnectionPortId]];
		[myRecordSet setStringValue: "MODEM_PHONE_NUMBER" value: [anObject getModemPhoneNumber]];
		[myRecordSet setCharValue: "RINGS_QTY" value: [anObject getRingsQty]];
		[myRecordSet setStringValue: "DOMAIN" value: [anObject getDomain]];
		[myRecordSet setStringValue: "IP" value: [anObject getIP]];
		[myRecordSet setShortValue: "TCP_PORT_SOURCE" value: [anObject getTCPPortSource]];
		[myRecordSet setShortValue: "TCP_PORT_DESTINATION" value: [anObject getConnectionTCPPortDestination]];
		[myRecordSet setCharValue: "PPP_CONNECTION_ID" value: [anObject getPPPConnectionId]];
		[myRecordSet setStringValue: "ISP_PHONE_NUMBER" value: [anObject getISPPhoneNumber]];
		[myRecordSet setStringValue: "USER_NAME" value: [anObject getConnectionUserName]];
		[myRecordSet setStringValue: "PASSWORD" value: [anObject getConnectionPassword]];
		[myRecordSet setLongValue: "SPEED" value: [anObject getConnectionSpeed]];
		[myRecordSet setCharValue: "DELETED" value: [anObject isDeleted]];
		[myRecordSet setStringValue: "DOMAIN_SUP" value: [anObject getDomainSup]];
		[myRecordSet setCharValue: "CONNECT_BY" value: [anObject getConnectBy]];

		connectionId = [myRecordSet save];
		//doLog(0,"Grabando conexion con id = %d\n", connectionId);
		[anObject setConnectionId: connectionId];

		[audit setStation: connectionId];
    [audit saveAudit];  
    [audit free];
	
		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "connections_bck"]) {

			if (!updateRecord) { // doy de alta
				// verifico que la supervision no existe en placa. (este control se hace por si
				// se limpio el equipo para luego hacer un restore, en cuyo caso no debo crearla 
				// porque ya existe en placa)
				if (![self existConnectionInBackup: [anObject getConnectionId]]) {
					myRecordSetBck = [dbConnection createRecordSetWithFilter: "connections_bck" filter: "" orderFields: "CONNECTION_ID"];
					[self doAddBackup: myRecordSetBck currentRecordSet: myRecordSet tableName: "connections_bck"];
				}
			} else {
				myRecordSetBck = [dbConnection createRecordSetWithFilter: "connections_bck" filter: "" orderFields: "CONNECTION_ID"];
				[self doUpdateBackupById: "CONNECTION_ID" value: [anObject getConnectionId] backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "connections_bck"];
			}

		}

		[[TelesupervisionManager getInstance] loadDNSSettings];

	FINALLY

		[myRecordSet free];
//		[myDataSearcher free];

	END_TRY;
}

/**/
- (void) validateFields: (id) anObject
{
	/* 
		Validacion de nulidad de campos en cuanto a sus valores que reflejan invalidez
		Type <= 0
		Amount <= 0
		name = vacio
	*/
  if ([anObject isDeleted]) return;

	// ( (strlen([anObject getConnectionDescription]) == 0) ) THROW(DAO_NULLED_VALUE_EX);
	
	/*
		Validacion de rangos en cuanto a los valores que presentan restricciones
	  ConnectionType = 1..4
		ConnectionPortType = 1..4
		RingsQty = 1..32
		TCPPortSource = 1..65535
		TCPPortDestination = 1..65535
		PPPConnectionId = 1..16
		Speed = 300..115200
	*/

  if ([anObject getConnectionType] == 0)
    THROW(DAO_CONNECTION_TYPE_NULL_EX);
  
  /*CONEXION PPP-MODEM*/
  if ([anObject getConnectionType] != ConnectionType_LAN) {
  
	  /*Puerto comunicacion*/    
    if ([anObject getConnectionPortId] == 0)
     THROW(DAO_PORT_NULLED_EX);
     
    /*Velocidad*/
    if (([anObject getConnectionSpeed] < 300) || ([anObject getConnectionSpeed] > 115200 ))
	   THROW(DAO_CONNECTION_SPEED_INCORRECT_EX);
      	      
  }
  
  /*CONEXION PPP-LAN*/
  if ([anObject getConnectionType] != ConnectionType_MODEM) {

		if (([anObject getConnectBy] == ConnectionByType_IP) && (strlen([anObject getIP]) == 0))
			THROW(DAO_DOMAIN_INCORRECT_EX); 
		
		if (([anObject getConnectBy] == ConnectionByType_DOMAIN) && (strlen([anObject getDomainSup]) == 0))
			THROW(DAO_DOMAIN_INCORRECT_EX); 

    //Puerto TCP
		/*lo comento por ahora porque tampoco se da de alta desde el wincab
    if ([anObject getConnectionTCPPortDestination] == 0) THROW(DAO_TCP_PORT_DESTINATION_NULL_EX); 
		*/
  }

  /*CONEXION PPP*/  
	if ([anObject getConnectionType] == ConnectionType_PPP) {
	  // Numero tel ISP
		if (strlen([anObject getISPPhoneNumber]) == 0) 	THROW(DAO_CONNECTION_PHONE_NUMBER_INCORRECT_EX);
		// Usuario conexion
		if (strlen([anObject getConnectionUserName]) == 0) THROW(DAO_CONNECTION_USER_NAME_INCORRECT_EX);
		// Password conexion
		if (strlen([anObject getConnectionPassword]) == 0) THROW(DAO_CONNECTION_PASSWORD_INCORRECT_EX);
	}

  /*CONEXION MODEM*/  
  if ([anObject getConnectionType] == ConnectionType_MODEM) {
  	//Cantidad de rings
  	if ([anObject getRingsQty] == 0) THROW(DAO_RINGS_QTY_NULL_EX); 

    //Numero telefono 
  	if (strlen([anObject getModemPhoneNumber]) == 0) THROW(DAO_CONNECTION_PHONE_NUMBER_INCORRECT_EX);
  }  	

  //Conexion GPRS
  if ([anObject getConnectionType] == ConnectionType_GPRS) {
  	//ISP Phone Number
  	if (strlen([anObject getISPPhoneNumber]) == 0) THROW(DAO_CONNECTION_PHONE_NUMBER_INCORRECT_EX);

    //APN 
  	if (strlen([anObject getDomain]) == 0) THROW(DAO_APN_INCORRECT_EX);
  }  	


/*  
	if ( [anObject getTelcoType] == TELEFONICA_TSUP_ID || [anObject getTelcoType] == TELECOM_TSUP_ID) {
		if (strlen([anObject getModemPhoneNumber]) == 0) THROW(DAO_CONNECTION_PHONE_NUMBER_INCORRECT_EX);
	}
*/
	// Validaciones especificas para el SAR 2
	//if ([anObject getTelcoType] == SARII_TSUP_ID){

 // if (strlen([anObject getIP]) == 0) THROW(DAO_CONNECTION_IP_INCORRECT_EX);


	//}

  //@todo descomentar esto, para tener en cuenta la validacion de campos
  /*
	if (  ( ([anObject getConnectionType] < 1) ||([anObject getConnectionType] > 4) ) ||
				( ([anObject getConnectionPortType] < 1) ||([anObject getConnectionPortType] > 3) ) ||
				(	([anObject getRingsQty] < 1) ||([anObject getRingsQty] > 32) ) ||
				(	([anObject getTCPPortSource] < 1) ||([anObject getTCPPortSource] > 65535) ) ||
				(	([anObject getConnectionTCPPortDestination] < 1) ||([anObject getConnectionTCPPortDestination] > 65535) ) ||
				(	([anObject getPPPConnectionId] < 1) ||([anObject getPPPConnectionId] > 16) ) 
		 )
			THROW(DAO_OUT_OF_RANGE_VALUE_EX);
  */      
}

/**/
- (BOOL) existConnectionInBackup: (int) anId
{
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET recordSetBck;
	BOOL exist = FALSE;

	if ([dbConnection tableHasBackup: "connections_bck"]) {
		recordSetBck = [dbConnection createRecordSetWithFilter: "connections_bck" filter: "" orderFields: "CONNECTION_ID"];

		[recordSetBck open];
		if ([recordSetBck findById: "CONNECTION_ID" value: anId]) {
			exist = TRUE;
		}

		[recordSetBck close];
		[recordSetBck free];
	}

	return exist;

}

@end
