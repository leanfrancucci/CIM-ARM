#include "PimsRequest.h"
#include "system/util/all.h"
#include "system/os/all.h"
#include "Map.h"
#include "TelesupScheduler.h"
#include "RepairOrder.h"
#include "ResourceStringDefs.h"
#include "MessageHandler.h"
#include "CommercialStateMgr.h"
#include "CimGeneralSettings.h"
#include "TelesupervisionManager.h"
#include "Acceptor.h"
#include "Audit.h"
#include "UserManager.h"
#include "scew.h"
#include "XMLConstructor.h"
#include "PrinterSpooler.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)


@implementation PimsRequest

static PIMS_REQUEST mySingleInstance = nil;
static PIMS_REQUEST myRestoreSingleInstance = nil;

/**/
+ getSingleVarInstance
{
	 return mySingleInstance; 
};
+ (void) setSingleVarInstance: (id) aSingleVarInstance
{
	 mySingleInstance =  aSingleVarInstance;
};

/**/
+ getRestoreVarInstance
{
	 return myRestoreSingleInstance;
};
+ (void) setRestoreVarInstance: (id) aRestoreVarInstance
{
	 myRestoreSingleInstance = aRestoreVarInstance;
};

/**/
- initialize
{
	myPackage = [GenericPackage new];
	[super initialize];
	return self;
}

/**/
- free
{
	[myPackage free];
	return [super free];
}

/**/
- (void) clear
{
	[super clear];
	[myPackage clear];
}

/**/
- (void) setMessage: (char *)aMessage
{
	[myPackage loadPackage: aMessage];
}

/**/
- (void) beginEntity
{
	[myRemoteProxy addLine: BEGIN_ENTITY];
}

/**/
- (void) endEntity
{
	[myRemoteProxy addLine: END_ENTITY];
}

- (void) addParamsFromMap: (MAP) aMap
{
	int i;
	char *itemName;

	for (i = 0; i < [aMap getItemCount]; ++i) {
		itemName = [aMap getItemNameAt: i];
		[myRemoteProxy addParamAsString: itemName value: [aMap getParamAsString: itemName]];
	}

}

/**/
- (void) getConnectionIntentionReq
{
	id repairOrder = NULL;
	COLLECTION repairItems;
	int i;
	char aux[50];
	char buffer[50];
	id commercialState;
	char mac[50];
	id telesup = NULL;
	int intention = 0;
	BOOL hasExpiredModules = FALSE;
	char modules[50];

	[myRemoteProxy newResponseMessage];

	modules[0] = '\0';

	if ([[TelesupScheduler getInstance] inTelesup]) {
		hasExpiredModules = [[CommercialStateMgr getInstance] hasExpiredModules];
		intention = [[TelesupScheduler getInstance] getCommunicationIntention];
	} else if ([[Acceptor getInstance] isTelesupRunning]) {
		intention = [[Acceptor getInstance] getCommunicationIntention];
	}

	[myRemoteProxy addParamAsInteger: "Intention" value: intention];

	// si tiene modulos vencidos concatena todos los codigos de modulos
	if (hasExpiredModules) {
		[[CommercialStateMgr getInstance] getExpiredModulesStr: modules];
		[myRemoteProxy addParamAsString: "Modules" value: modules];
	}

	// si la intention es de orden de reparacion
	if (intention == CommunicationIntention_GENERATE_REPAIR_ORDER) {

		if (myViewer) [myViewer updateText: getResourceStringDef(RESID_SENDING_REPAIR_ORDER_DATA, "Enviando datos de orden.")];		

		repairOrder = [[TelesupScheduler getInstance] getRepairOrder];
		assert(repairOrder);

		repairItems = [repairOrder getRepairOrderItemList];
		assert(repairItems);

		strcpy(buffer, "");
		i=0;

		sprintf(aux, "%d", [[repairItems at: i] getItemId]);
		strcat(buffer, aux);

		for (i=1; i<[repairItems size]; ++i) {
			sprintf(aux, ",%d", [[repairItems at: i] getItemId]);
			strcat(buffer, aux);
		} 

		[myRemoteProxy addParamAsDateTime: "RepairOrderDateTime" value: [repairOrder getDateTime]];
		[myRemoteProxy addParamAsString: "RepairIdList" value: buffer];
		[myRemoteProxy addParamAsInteger: "Priority" value: [repairOrder getPriority]];
		[myRemoteProxy addParamAsString: "ContactTelephoneNumber" value: [repairOrder getTelephoneNumber]];
		[myRemoteProxy addParamAsInteger: "UserId" value: [repairOrder getUserId]];

	}

	// Cambio de estado
	if (intention == CommunicationIntention_CHANGE_STATE_REQUEST) {

		commercialState = [[CommercialStateMgr getInstance] getPendingCommercialStateChange];

		if (commercialState) {

		  if (myViewer) [myViewer updateText: getResourceStringDef(RESID_CHANGE_STATE_REQUEST, "Solicitando cambio de estado...")];		

			telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];
	
			stringcpy(aux, "0");

			if (telesup)
				stringcpy(aux, [telesup getRemoteSystemId]);

			[myRemoteProxy addParamAsString: "IdPims" value: aux];
			[myRemoteProxy addParamAsString: "MacAddress" value: [[CimGeneralSettings getInstance] getMacAddress: mac]];
			[myRemoteProxy addParamAsDateTime: "RequestDateTime" value: [commercialState getRequestDateTime]];
			[myRemoteProxy addParamAsInteger: "CurrentState" value: [commercialState getCommState]];
			[myRemoteProxy addParamAsInteger: "NextState" value: [commercialState getNextCommState]];
			[myRemoteProxy addParamAsString: "Signature" value: [[CommercialStateMgr getInstance] getCommercialStateSignature: commercialState]];
		}

	}

	[myRemoteProxy sendMessage];

}

/**/
- (void) informTransactionState
{

}

/**/
- (void) informRepairOrderData
{
	id repairOrder;
	assert(myViewer);

	if (myViewer) [myViewer updateText: getResourceStringDef(RESID_RECEIVING_REPAIR_ORDER_DATA, "Receiving repair order data")];
	
	// HACER ALGO CON LOS DATOS - VISUALIZAR POR PANTALLA Y DAR LA POSIBILIDAD DE IMPRESION
	repairOrder = [[TelesupScheduler getInstance] getRepairOrder];
	[repairOrder setRepairOrderNumber: [myPackage getParamAsString: "RepairOrder"]];
	[myRemoteProxy sendAckMessage];
}

/**/
- (void) keepAlive
{
	char description[50];
	stringcpy(description, [myPackage getParamAsString: "Description"]);
	//if (strlen(description) > 0) [myViewer updateDisplay: description];
	[myRemoteProxy sendAckMessage];
}

/**/
- (void) informStateChangeResult 
{
	id commercialState = [[CommercialStateMgr getInstance] getPendingCommercialStateChange];

	assert(commercialState);

	[commercialState setRequestResult: [myPackage getParamAsInteger: "RequestResult"]];	

	// Ocurre un error
	if ([myPackage getParamAsInteger: "RequestResult"] != 1) {

		if (myViewer) [myViewer updateText: getResourceStringDef(RESID_AUTHORIZATION_ERROR, "Error en autorizacion.")];		

		[Audit auditEventCurrentUser: Event_STATE_CHANGE_AUT_ERROR additional: "" station: 0 logRemoteSystem: FALSE]; 			
	}

	if (myViewer) [myViewer updateText: getResourceStringDef(RESID_RECEIVING_STATE_CHANGE_AUT, "Autorizando cambio de estado.")];		

	[commercialState setAuthorizationId: [myPackage getParamAsInteger: "AuthorizationId"]];
	[commercialState setRequestDateTime: [myPackage getParamAsDateTime: "RequestDateTime"]];

	if ([myPackage isValidParam:"RemoteSignature"]) 
		[commercialState setEncodedRemoteSignature: [myPackage getParamAsString: "RemoteSignature"]];

	TRY
		[[CommercialStateMgr getInstance] doChangeCommercialState: commercialState];
		[myRemoteProxy sendAckMessage];
	CATCH

		if (myViewer) [myViewer updateText: getResourceStringDef(RESID_STATE_CHANGE_ERROR, "Error en la autorizacion de cambio de estado.")];		

		RETHROW();

	END_TRY

}

/**/
- (void) setModule
{
  int moduleCode;
  datetime_t baseDateTime;
  datetime_t expireDateTime;
  int hoursQty;
	BOOL online;
	BOOL enable;
	BOOL forceDisable;
  BOOL signResult = FALSE;
	int authorizationId;
  id commercialStateMgr = [CommercialStateMgr getInstance];
	char signatureBuffer[200];

  if (myViewer) [myViewer updateText: getResourceStringDef(RESID_UPDATING_MODULES, "Actualizando modulos...")];

  moduleCode = [myPackage getParamAsInteger: "ModuleCode"];
  baseDateTime = [myPackage getParamAsDateTime: "BaseDateTime"];
  expireDateTime = [myPackage getParamAsDateTime: "ExpireDateTime"];
  hoursQty = [myPackage getParamAsInteger: "HoursQty"];
	online = [myPackage getParamAsInteger: "Online"];
	enable = [myPackage getParamAsInteger: "Enable"];
	forceDisable = [myPackage getParamAsInteger: "ForceDisable"];
	authorizationId = [myPackage getParamAsInteger: "AuthorizationId"];

	//doLog(0,"ForceDisable = %d\n", [myPackage getParamAsInteger: "ForceDisable"]);

  signResult = [commercialStateMgr verifyModuleSignature: moduleCode 
                                                baseDateTime: baseDateTime
                                                expireDateTime: expireDateTime
                                                hoursQty: hoursQty
																								online: online
																								enable: enable
																								authorizationId: authorizationId
                                                encodeRemoteSignature: [myPackage getParamAsString: "RemoteSignature"]];

  if (!signResult) THROW(SIGN_AUTHORIZATION_ERROR_EX);

	if (myViewer) [myViewer updateText: getResourceStringDef(RESID_UPDATING_MODULES, "Actualizando modulos...")];

	// si inhabilita quiere decir que solo va a funcionar hasta el vencimiento
	if (!enable) 
		[commercialStateMgr disableModule: moduleCode]; 
  else 
  	[commercialStateMgr applyModuleLicence: moduleCode 
                                          baseDateTime: baseDateTime
                                          expireDateTime: expireDateTime
                                          hoursQty: hoursQty
																					online: online
																					enable: enable
																					authorizationId: authorizationId
                                          encodeRemoteSignature: [myPackage getParamAsString: "RemoteSignature"]]; 

  if (!forceDisable) [myRemoteProxy sendAckMessage];
	else {
	
		[commercialStateMgr forceDisable: moduleCode expireDateTime: expireDateTime];

		[myRemoteProxy newResponseMessage];

		[myRemoteProxy addParamAsInteger: "ModuleCode" value: moduleCode];
		[myRemoteProxy addParamAsDateTime: "BaseDateTime" value: baseDateTime];
  	[myRemoteProxy addParamAsDateTime: "ExpireDateTime" value: expireDateTime];
		[myRemoteProxy addParamAsInteger: "HoursQty" value: hoursQty];
		[myRemoteProxy addParamAsInteger: "Online" value: online];
		[myRemoteProxy addParamAsInteger: "Enable" value: enable];
		[myRemoteProxy addParamAsInteger: "AuthorizationId" value: authorizationId];
		[myRemoteProxy addParamAsString: "Signature" value: 
																		[commercialStateMgr getModuleApplySignature: moduleCode 
                                          baseDateTime: baseDateTime
                                          expireDateTime: expireDateTime
                                          hoursQty: hoursQty
																					online: online
																					enable: enable
																					authorizationId: authorizationId
                                          signatureBuffer: signatureBuffer]];

		[myRemoteProxy sendMessage];

	}

}

/**/
- (void) sendUserToLogin
{

	[myRemoteProxy newResponseMessage];

	[myRemoteProxy addParamAsString: "Login" value: [[UserManager getInstance] getUserToLogin]];
	[myRemoteProxy addParamAsString: "Password" value: [[UserManager getInstance] getPasswordToLogin]];

	[myRemoteProxy sendMessage];

}

/**/
- (void) setUserToLoginResponse
{
	char response[10];
	char profileName[30];
	char userName[22];
	char userSurname[22];

	stringcpy(response, [myPackage getParamAsString: "Response"]);

	if (strcmp(response, "ERROR") == 0) {
		[[UserManager getInstance] setUserToLoginResponse: FALSE];
	}	else {
		stringcpy(profileName, [myPackage getParamAsString: "ProfileName"]);
		stringcpy(userName, [myPackage getParamAsString: "Name"]);
		stringcpy(userSurname, [myPackage getParamAsString: "Surname"]);

		[[UserManager getInstance] setUserToLoginResponse: TRUE];
		[[UserManager getInstance] setUserToLoginProfileName: profileName];
		[[UserManager getInstance] setUserToLoginName: userName];
		[[UserManager getInstance] setUserToLoginSurname: userSurname];

		[[UserManager getInstance] addHoytsUser: userName surname: userSurname loginName: [[UserManager getInstance] getUserToLogin] password: [[UserManager getInstance] getPasswordToLogin] duressPassword: "0000" profileName: profileName];

	}

	[myRemoteProxy sendAckMessage];

}

/**/
- (void)setInsertDepositResult
{
	char line[500], datestr[50];
	time_t now;
	struct tm *brokenTime;
	scew_tree* tree;
	char response[10];
	char message[200];
	char finalText[200];
	char *s;
	char part[200];
	char l[200];

	stringcpy(response, [myPackage getParamAsString: "Response"]);
	stringcpy(message, [myPackage getParamAsString: "Message"]);

	if (strcmp(response, "ERROR") == 0) {

	 [Audit auditEvent: Event_INSERT_DEPOSIT_ERROR additional: "" station: 0 logRemoteSystem: FALSE];


		now = time(NULL);
		brokenTime = localtime(&now);

		sprintf(datestr, "%04d-%02d-%02d %02d:%02d:%02d", 
			brokenTime->tm_year + 1900, 
			brokenTime->tm_mon + 1,
			brokenTime->tm_mday,
			brokenTime->tm_hour,
			brokenTime->tm_min,
			brokenTime->tm_sec
		);

		sprintf(line, "f \n \n"
								 "-----------------------------\n"
								 "  %s\n"
								 "-----------------------------\n"
								 "  %s GMT\n"
								 "-----------------------------\n \n", getResourceStringDef(RESID_UNDEFINED, " ERROR"), datestr);


		s = message;
		strcpy(l, "");
		strcpy(finalText, "");		
		do {
			s = wordwrap(s, 25, 11, part);
			sprintf(l, "%s\n", part);
			strcat(finalText, l);
		} while ( *s!='\0' ); 

		strcat(line, finalText);

		strcat(line, "\n \n \n ");

		// Mando a imprimir el documento generado
		tree = [[XMLConstructor getInstance] buildXML: line];
		[[PrinterSpooler getInstance] addPrintingJob: TEXT_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree];

	}

	[myRemoteProxy sendAckMessage];

}

/**/
- (void) getInternalUserId
{
	id hoytsUser = NULL;

	hoytsUser = [[UserManager getInstance] getHoytsUser];

	[myRemoteProxy newResponseMessage];

	if (hoytsUser)
		[myRemoteProxy addParamAsInteger: "InternalId" value: [hoytsUser getUserId]];
	else 
	  [myRemoteProxy addParamAsInteger: "InternalId" value: 0];

	[myRemoteProxy sendMessage];
}


/**/
- (void) executeRequest
{
	//doLog(0,"executeRequest\n");

	switch (myReqType) {

		case GET_CONNECTION_INTENTION_REQ:
			//doLog(0,"PimsRequest->GetConnectionIntention\n");
			[self getConnectionIntentionReq];
			return;

		case KEEP_ALIVE_REQ:
			//doLog(0,"PimsRequest->KeepAlive\n");
			[self keepAlive];
			return;

		case INFORM_REPAIR_ORDER_DATA_REQ:
			[self informRepairOrderData];
			return;

		case INFORM_STATE_CHANGE_RESULT_REQ:
			[self informStateChangeResult];
			return;

    case SET_MODULE_REQ:
      [self setModule];
      return;

		case GET_USER_TO_LOGIN_REQ:
			[self sendUserToLogin];
			return;

		case SET_USER_TO_LOGIN_RESPONSE_REQ:
			[self setUserToLoginResponse];
			return;

		case SET_INSERT_DEPOSIT_RESULT_REQ:
			[self setInsertDepositResult];
			return;

		case GET_INTERNAL_USER_ID_REQ:
			[self getInternalUserId];
			return;


		default:
			return;
	}

	THROW_FMT(TSUP_INVALID_OPERATION_EX, "ReqType=%d", myReqType);
	//doLog(0,"PimsRequest -> Unknown operation\n");

}

/**/
- (void) endRequest
{
	[super endRequest];
}

/**/
- (void) setViewer: (id) aViewer
{
	myViewer = aViewer;
}

@end
