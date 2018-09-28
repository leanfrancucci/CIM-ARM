#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <ctype.h>

//#define printd(args...) doLog(0,args)
#define printd(args...)

#include "system/lang/all.h"
#include "system/util/all.h"
#include "ctapp.h"
#include "G2TelesupParser.h"
#include "Request.h"
#include "Audit.h"
#include "Event.h"


#include "StartJobRequest.h"
#include "CommitJobRequest.h"
#include "RollbackJobRequest.h"

#include "GetAppliedMessagesRequest.h"

#include "GetDateTimeRequest.h"

/* Transferencias de archivos */
#include "GetFileRequest.h"
#include "PutFileRequest.h"
#include "GetDepositsRequest.h"
#include "PimsRequest.h"
#include "GetExtractionsRequest.h"
#include "GetAuditsRequest.h"
#include "PutTextMessagesRequest.h"
#include "CleanDataRequest.h"
#include "RestartSystemRequest.h"
#include "GetZCloseRequest.h"
#include "GetXCloseRequest.h"
#include "GetLogRequest.h"
#include "GetSettingsDumpRequest.h"
#include "TelesupScheduler.h"
#include "Acceptor.h"
#include "GetGenericFileRequest.h"
#include "GetUserRequest.h"
#include "CommercialStateMgr.h"
#include "DepositManager.h"
#include "ExtractionManager.h"

#include "SystemOpRequest.h"


unsigned int _fileCount = 0;

/* Mapeo entre un mensaje y su correspondiente identificador de request */
typedef struct
{
	char				*msg;			/* El nombre del mensaje */
	int		 			reqType;		/* El identificador del tipo de mensaje */
	ENTITY_REQUEST_OPS	action;			/* El subtipo de mensaje */
	BOOL				jobable;		/* 1 si el mensaje puede ser recibido dentro de un Job */

} MapRequestMsg;

/**/
typedef struct {
	char *category;
	char *path;
} PutFileCategory;


/**
	Esto mapea el nombre de la categoria a un PATH especifico.
	*/
/*static PutFileCategory categories[] =
{
	{"UNKNOWN", ""},
	{"LOCATIONS", "data/"},
	{"MODEM_INIT", "../etc/"},
	{"UPDATE", "telesup/app/"}
};LM*/
#ifdef __WIN32

static PutFileCategory categories[] =
{
	{"UNKNOWN", ""},
	{"LOCATIONS", "data/"},
	{"MODEM_INIT", ""},
	{"UPDATE", "imas/updates/"}
};	

#else

static PutFileCategory categories[] =
{
	{"UNKNOWN", ""},
	{"LOCATIONS", BASE_APP_PATH "/data/"},
	{"MODEM_INIT", BASE_PATH "/etc/"},
	{"UPDATE", BASE_TELESUP_PATH "/"},
	{"FIRM_UPDATE", BASE_TELESUP_PATH "/"},
	{"FIRM_INNERBOARD_UPDATE", BASE_TELESUP_PATH "/"}
};	

#endif

/**
 *	Tabla de mapeos entre mensajes e identififcadores de Request 
 *  y su accion correspondiente
 * Un mensaje define uno y solo un Request, ademas de define que 
 * acciones debera realizar ese Request 
 */

/**/
MapRequestMsg 	mapReqMsg[] =
{

/*  { "Message"					      REQUEST							      ACTION 			JOBABLE }*/

	 {"TestSetParam",				   SET_TEST_PARAM_REQ,			   		NO_REQ_OP,			  0}
	,{"StartJob",					     START_JOB_REQ,					     		NO_REQ_OP,			  0}
	,{"CommitJob",					   COMMIT_JOB_REQ,					   		NO_REQ_OP,			  0}
	,{"RollbackJob",				   ROLLBACK_JOB_REQ,				   		NO_REQ_OP,			  0}
	
	,{"GetAppliedMessages",		 GET_APPLIED_MESSAGES_REQ,   		NO_REQ_OP,			  0}
	 
	,{"SetDateTime", 				   SET_DATETIME_REQ,				   		SETTINGS_REQ_OP,  0}
	,{"GetDateTime", 				   GET_DATETIME_REQ,				   		NO_REQ_OP,			  0}

	,{"SetGeneralBill", 			 SET_GENERAL_BILL_REQ,			   	SETTINGS_REQ_OP,	1}
	,{"GetGeneralBill", 			 GET_GENERAL_BILL_REQ,			   	NO_REQ_OP,				0}

	,{"SetCimGeneralSettings", SET_CIM_GENERAL_SETTINGS_REQ,  SETTINGS_REQ_OP,	1}
	,{"GetCimGeneralSettings", GET_CIM_GENERAL_SETTINGS_REQ,	NO_REQ_OP,				0}

	,{"SetDoor", 			     		 SET_DOOR_REQ,				     			SETTINGS_REQ_OP,1}
	,{"GetDoor", 				   		 GET_DOOR_REQ,				     			NO_REQ_OP,			 0}
	,{"GetDoors", 				 		 GET_DOOR_REQ,				     			LIST_REQ_OP,		 0}
	,{"AddDoor", 					 		 SET_DOOR_REQ,						  		ADD_REQ_OP,		 0}
	,{"RemoveDoor",			 			 SET_DOOR_REQ,									REMOVE_REQ_OP,	 1}

	,{"SetAcceptor",  				 SET_ACCEPTOR_REQ,							SETTINGS_REQ_OP,		 0}
	,{"GetAcceptor", 					 GET_ACCEPTOR_REQ,							NO_REQ_OP,		 0}
	,{"GetAcceptors", 				 GET_ACCEPTOR_REQ,							LIST_REQ_OP,		 0}
	,{"AddAcceptor", 					 SET_ACCEPTOR_REQ,						  ADD_REQ_OP,		 0}
	,{"RemoveAccceptor",			 SET_ACCEPTOR_REQ,							REMOVE_REQ_OP,	 1}

	,{"SetCurrencyDenomination",  SET_CURRENCY_DENOMINATION_REQ,		SETTINGS_REQ_OP,1}
	,{"GetCurrencyDenominations", GET_CURRENCY_DENOMINATION_REQ,		LIST_REQ_OP,		0}
	,{"GetDenominationList", GET_DENOMINATION_LIST_REQ,		LIST_REQ_OP,		0}

	,{"GetDepositValueTypes",  	 GET_DEPOSIT_VALUE_TYPE_REQ,	  LIST_REQ_OP,		 0}
	,{"AddDepositValueType", 	 	 SET_DEPOSIT_VALUE_TYPE_REQ,	  ADD_REQ_OP,		   0}
	,{"RemoveDepositValueType", SET_DEPOSIT_VALUE_TYPE_REQ,  	REMOVE_REQ_OP,	 1}

	,{"GetDepositValueTypeCurrencies",  GET_DEPOSIT_VALUE_TYPE_CURRENCY_REQ,	  LIST_REQ_OP,	 0}
	,{"AddDepositValueTypeCurrency", 	  SET_DEPOSIT_VALUE_TYPE_CURRENCY_REQ,	  ADD_REQ_OP,		 0}
	,{"RemoveDepositValueTypeCurrency", SET_DEPOSIT_VALUE_TYPE_CURRENCY_REQ,  REMOVE_REQ_OP,	 1}

	,{"GetCurrencies", 									GET_CURRENCY_REQ,	  LIST_REQ_OP,		0}
	,{"GetCurrenciesByAcceptor", 				GET_CURRENCY_BY_ACCEPTOR_REQ,	  LIST_REQ_OP,		0}

	,{"SetCashBox", 										SET_CASH_BOX_REQ,							SETTINGS_REQ_OP,		 0}
	,{"GetCashBox", 										GET_CASH_BOX_REQ,							NO_REQ_OP,		 0}
	,{"GetCashBoxes", 									GET_CASH_BOX_REQ,							LIST_REQ_OP,		 0}
	,{"AddCashBox", 										SET_CASH_BOX_REQ,							ADD_REQ_OP,		 0}
	,{"RemoveCashBox",									SET_CASH_BOX_REQ,							REMOVE_REQ_OP,	 1}
	,{"GetAcceptorsByCash",							GET_ACCEPTORS_BY_CASH_REQ,	  LIST_REQ_OP,	 0}
	,{"AddAcceptorByCash",							SET_ACCEPTORS_BY_CASH_REQ,	  ADD_REQ_OP,	 0}
	,{"RemoveAcceptorByCash",						SET_ACCEPTORS_BY_CASH_REQ,	  REMOVE_REQ_OP,	 0}

	,{"SetCashReference", 							SET_CASH_REFERENCE_REQ,		  	SETTINGS_REQ_OP,		 0}
	,{"GetCashReferences", 							GET_CASH_REFERENCE_REQ,				LIST_REQ_OP,		 0}
	,{"AddCashReference", 							SET_CASH_REFERENCE_REQ,				ADD_REQ_OP,		 0}
	,{"RemoveCashReference",						SET_CASH_REFERENCE_REQ,				REMOVE_REQ_OP,	 1}

	,{"SetBox", 										SET_BOX_REQ,											SETTINGS_REQ_OP,		 0}
	,{"GetBox", 										GET_BOX_REQ,											NO_REQ_OP,		 0}
	,{"GetBoxes", 									GET_BOX_REQ,											LIST_REQ_OP,		 0}
	,{"AddBox", 										SET_BOX_REQ,											ADD_REQ_OP,		 0}
	,{"RemoveBox",									SET_BOX_REQ,											REMOVE_REQ_OP,	 1}
	,{"GetAcceptorsByBox",					GET_ACCEPTORS_BY_BOX_REQ,	  			LIST_REQ_OP,	 0}
	,{"AddAcceptorByBox",						SET_ACCEPTORS_BY_BOX_REQ,	  			ADD_REQ_OP,	 0}
	,{"RemoveAcceptorByBox",				SET_ACCEPTORS_BY_BOX_REQ,	  			REMOVE_REQ_OP,	 0}
	,{"GetDoorsByBox",							GET_DOORS_BY_BOX_REQ,	  					LIST_REQ_OP,	 0}
	,{"AddDoorByBox",								SET_DOORS_BY_BOX_REQ,	  					ADD_REQ_OP,	 0}
	,{"RemoveDoorByBox",						SET_DOORS_BY_BOX_REQ,	  					REMOVE_REQ_OP,	 0}

	,{"SetCommercialState", 	 SET_COMMERCIAL_STATE_REQ,		SETTINGS_REQ_OP,1}
	,{"GetCommercialState", 	 GET_COMMERCIAL_STATE_REQ,		NO_REQ_OP,	   	0}

	,{"SetRegionalSettings", 	 SET_REGIONAL_SETTINGS_REQ,	   SETTINGS_REQ_OP,1}
	,{"GetRegionalSettings", 	 GET_REGIONAL_SETTINGS_REQ,	   NO_REQ_OP,		  0}

	,{"SetPrintSystem", 		   SET_PRINT_SYSTEM_REQ,				 SETTINGS_REQ_OP,1}
	,{"GetPrintSystem", 			 GET_PRINT_SYSTEM_REQ,				 NO_REQ_OP,			0}

	,{"SetAmountMoney", 			 SET_AMOUNT_MONEY_REQ,			   SETTINGS_REQ_OP,1}
	,{"GetAmountMoney", 			 GET_AMOUNT_MONEY_REQ,			   NO_REQ_OP,			 0}

	,{"SetUser", 					                  SET_USER_REQ,					              SETTINGS_REQ_OP,	  1}
  ,{"GetUser", 					                  GET_USER_REQ,					              NO_REQ_OP,			    0}
	,{"GetUsers", 				                  GET_USER_REQ,					              LIST_REQ_OP,			  0}
	,{"GetUsersWithChildren", 				      GET_USER_WITH_CHILDREN_REQ,					LIST_REQ_OP,			  0}
	,{"AddUser", 					                  SET_USER_REQ,					              ADD_REQ_OP,			    0}
	,{"RemoveUser", 				                SET_USER_REQ,					              REMOVE_REQ_OP,		  1}	

	,{"ActivateDoorByUser", 	  SET_DOOR_BY_USER_REQ,	   ACTIVATE_REQ_OP,	  1}
	,{"DeactivateDoorByUser", 	SET_DOOR_BY_USER_REQ,	   DEACTIVATE_REQ_OP,	1}
  ,{"GetDoorsByUserId",       GET_DOORS_BY_USER_REQ,   LIST_REQ_OP,       0}
  ,{"GetDoorsByUsers",        GET_DOORS_BY_USERS_REQ,  LIST_REQ_OP,       0}

	,{"AddDualAccess", 	        SET_DUAL_ACCESS_REQ,	   ADD_REQ_OP,	    1}
	,{"RemoveDualAccess", 	    SET_DUAL_ACCESS_REQ,	   REMOVE_REQ_OP,	  1}
  ,{"GetDualAccess",          GET_DUAL_ACCESS_REQ,     LIST_REQ_OP,     0}

  ,{"SetForcePinChange", 			SET_FORCE_PIN_CHANGE_REQ,		SETTINGS_REQ_OP,	 1}

	,{"SetTelesup", 		    SET_TELESUP_SETTINGS_REQ,		SETTINGS_REQ_OP,	1}
	,{"AddTelesup", 	      SET_TELESUP_SETTINGS_REQ,		ADD_REQ_OP,	      1}
	,{"RemoveTelesup", 	    SET_TELESUP_SETTINGS_REQ,		REMOVE_REQ_OP,	  1}
	,{"GetTelesup", 		    GET_TELESUP_SETTINGS_REQ,		NO_REQ_OP,			  0}
	,{"GetTelesups", 		    GET_TELESUP_SETTINGS_REQ,		LIST_REQ_OP,			0}
  ,{"AddTelesupWithConnectionName", SET_TELESUP_SETTINGS_REQ,		ADD_REQ_OP,	      1}

	,{"SetConnection", 		  SET_CONNECTION_REQ,		      SETTINGS_REQ_OP,  0}
	,{"RemoveConnection", 	SET_CONNECTION_REQ,		      REMOVE_REQ_OP,    0}
	,{"AddConnection", 		  SET_CONNECTION_REQ,		      ADD_REQ_OP, 	    0}
	,{"GetConnection", 		  GET_CONNECTION_REQ,		      NO_REQ_OP,        0}
	,{"GetConnections", 		GET_CONNECTION_REQ,		      LIST_REQ_OP,      0}

	,{"SetUserProfile", 		            SET_USER_PROFILE_REQ,			          SETTINGS_REQ_OP,	1}
	,{"GetUserProfile", 		            GET_USER_PROFILE_REQ,			          NO_REQ_OP,			  0}
  ,{"GetUserProfiles", 		            GET_USER_PROFILE_REQ,			          LIST_REQ_OP,			0}	
  ,{"GetUserProfilesWithChildren", 		GET_USER_PROFILE_CHILDREN_REQ,			LIST_REQ_OP,			0}
	,{"AddUserProfile", 		            SET_USER_PROFILE_REQ,			          ADD_REQ_OP,			  0}
	,{"RemoveUserProfile", 	            SET_USER_PROFILE_REQ,			          REMOVE_REQ_OP,		1}

  ,{"GetOperations", 		  GET_OPERATION_REQ,			    LIST_REQ_OP,			0}

	,{"GetVersion", 				GET_VERSION_REQ,					  NO_REQ_OP,			  0}
  ,{"GetSystemInfo",      GET_SYSTEM_INFO_REQ,        NO_REQ_OP,				0}
  
  ,{"GenerateWorkOrder", 	  SET_WORK_ORDER_REQ,			   SETTINGS_REQ_OP,	 1}	
	
	,{"SetRepairOrderItem", 			SET_REPAIR_ORDER_REQ,					 SETTINGS_REQ_OP,	  1}
	,{"GetRepairOrderItems", 			GET_REPAIR_ORDER_REQ,					 LIST_REQ_OP,			  0}
	,{"AddRepairOrderItem", 			SET_REPAIR_ORDER_REQ,					 ADD_REQ_OP,			    0}
	,{"RemoveRepairOrderItem", 		SET_REPAIR_ORDER_REQ,					 REMOVE_REQ_OP,		  1}
	
/* Transferencias de archivos */
	,{"GetDeposits", 				  GET_DEPOSITS_REQ,				  NO_REQ_OP,			0}
	,{"GetExtractions", 			GET_EXTRACTIONS_REQ,			NO_REQ_OP,			0}
	,{"GetFile", 					    GET_FILE_REQ,					    NO_REQ_OP,			0}
	,{"PutFile", 					    PUT_FILE_REQ,					    NO_REQ_OP,			0}
	,{"PutTextMessages",      PUT_TEXT_MESSAGES_REQ, 		NO_REQ_OP, 	    0}
	,{"GetAudits", 					  GET_AUDITS_REQ,					  NO_REQ_OP,			0}
	,{"CleanData",					  CLEAN_DATA_REQ,					  NO_REQ_OP,			0}
	,{"RestartSystem",			  RESTART_SYSTEM_REQ,				NO_REQ_OP,			0}

  ,{"GetConnectionIntention",        GET_CONNECTION_INTENTION_REQ,				NO_REQ_OP,	0}
  ,{"InformRepairOrderData", 				 INFORM_REPAIR_ORDER_DATA_REQ,				NO_REQ_OP,	0}	
  ,{"KeepAlive",        						 KEEP_ALIVE_REQ,											NO_REQ_OP,	0}
	,{"GetCurrentBalance",        		 GET_CURRENT_BALANCE_REQ,							NO_REQ_OP,	0}
	,{"LoginRemoteUser",        		 	 LOGIN_REMOTE_USER_REQ,								NO_REQ_OP,	0}
	,{"GetZCloses", 				           GET_ZCLOSE_REQ,				              NO_REQ_OP,	0}
	,{"GetXCloses", 				           GET_XCLOSE_REQ,				              NO_REQ_OP,	0}
	,{"GetLog", 				             	 GET_LOG_REQ,				              		NO_REQ_OP,	0}
	,{"GetSettingsDump",             	 GET_SETTINGS_DUMP_REQ,				        NO_REQ_OP,	0}
	,{"InformStateChangeResult",       INFORM_STATE_CHANGE_RESULT_REQ,			NO_REQ_OP,	0}
	,{"GetStateChangeConfirmation",    GET_STATE_CHANGE_CONFIRMATION_REQ,		NO_REQ_OP,	0}
	,{"InformStateChangeConfirmationResult",    INFORM_STATE_CHANGE_CONFIRMATION_RESULT_REQ,		NO_REQ_OP,	0}
	,{"SetModule",                     SET_MODULE_REQ,		                  NO_REQ_OP,	0}
	,{"GetGenericFile", 				     	 GET_GENERIC_FILE_REQ,	           		NO_REQ_OP,	0}
	,{"GetAllUsers", 				           GET_ALL_USER_REQ,				            NO_REQ_OP,	0}

	,{"GetUserToLogin", 				       GET_USER_TO_LOGIN_REQ,				        NO_REQ_OP,	0}
	,{"SetUserToLoginResponse", 			 SET_USER_TO_LOGIN_RESPONSE_REQ,      NO_REQ_OP,	0}
	,{"SetInsertDepositResult", 			 SET_INSERT_DEPOSIT_RESULT_REQ,       NO_REQ_OP,	0}
	,{"GetInternalUserId",			 			 GET_INTERNAL_USER_ID_REQ,      			NO_REQ_OP,	0}

      /*REMOTE CONSOLE*/  
	,{"UserLogin", 				       USER_LOGIN_REQ,				        NO_REQ_OP,	0}
	,{"HasUserChangePin", 			 USER_HAS_CHANGE_PIN_REQ,      NO_REQ_OP,	0}
	,{"UserChangePassword", 			 USER_CHANGE_PIN_REQ,       NO_REQ_OP,	0}
	,{"UserLogout",			 			 USER_LOGOUT_REQ,      			NO_REQ_OP,	0}
	
	,{"StartValidatedDrop", 			 START_VALIDATED_DROP_REQ,       NO_REQ_OP,	0}
	,{"EndValidatedDrop",			 	END_VALIDATED_DROP_REQ,      			NO_REQ_OP,	0}
	
    ,{"InitExtractionProcess",          INIT_EXTRACTION_PROCESS_REQ,      			NO_REQ_OP,	0}
    ,{"GetDoorCurrentState",		 	GET_DOOR_STATE_REQ,      			NO_REQ_OP,	0}
    ,{"SetRemoveCash",		 			SET_REMOVE_CASH_REQ,      			NO_REQ_OP,	0}	        
    ,{"UserLoginForDoorAccess",		 	USER_LOGIN_FOR_DOOR_ACCESS_REQ, NO_REQ_OP,	0}	
    ,{"StartDoorAccess",		 		START_DOOR_ACCESS_REQ, NO_REQ_OP,	0}	    
    ,{"CloseExtraction",                CLOSE_EXTRACTION_REQ,      			NO_REQ_OP,	0}
    ,{"CancelDoorAccess",			 	CANCEL_DOOR_ACCESS_REQ,      			NO_REQ_OP,	0}    
    ,{"CancelTimeDelay",			 	CANCEL_TIME_DELAY_REQ,      			NO_REQ_OP,	0}    
    ,{"StartExtraction",			 	START_EXTRACTION_REQ,      			NO_REQ_OP,	0}

    ,{"StartManualDrop",			 	START_MANUAL_DROP_REQ,      			NO_REQ_OP,	0}
    ,{"AddManualDropDetail",			ADD_MANUAL_DROP_DETAIL_REQ,      		NO_REQ_OP,	0}
    ,{"PrintManualDropReceipt",			PRINT_MANUAL_DROP_RECEIPT_REQ,      	NO_REQ_OP,	0}
    ,{"CancelManualDrop",			    CANCEL_MANUAL_DROP_REQ,      	NO_REQ_OP,	0}
    ,{"FinishManualDrop",			    FINISH_MANUAL_DROP_REQ,      	NO_REQ_OP,	0}
    
    ,{"StartValidationMode",			START_VALIDATION_MODE_REQ,      	NO_REQ_OP,	0}    
    ,{"StopValidationMode",			    STOP_VALIDATION_MODE_REQ,      	NO_REQ_OP,	0}    

    ,{"GenerateOperatorReport",			GENERATE_OPERATOR_REPORT_REQ,      	NO_REQ_OP,	0}    
    ,{"HasAlreadyPrintEndDay",			HAS_ALREADY_PRINT_END_DAY_REQ,      	NO_REQ_OP,	0}        
    ,{"GenerateEndDay",			        GENERATE_END_DAY_REQ,      	NO_REQ_OP,	0}        
    ,{"GenerateEnrolledUsersReport",	GENERATE_ENROLLED_USERS_REPORT_REQ,      	NO_REQ_OP,	0}
    ,{"GetEventCategories",	GET_EVENTS_CATEGORIES_REQ,      	NO_REQ_OP,	0}        
    ,{"GenerateAuditReport",	GENERATE_AUDIT_REPORT_REQ,      	NO_REQ_OP,	0}            
    ,{"GenerateCashReport",	GENERATE_CASH_REPORT_REQ,      	NO_REQ_OP,	0}        
    ,{"GenerateXClose",	GENERATE_X_CLOSE_REPORT_REQ,      	NO_REQ_OP,	0}            
    ,{"GenerateReferenceReport",	GENERATE_REFERENCE_REPORT_REQ,      	NO_REQ_OP,	0}        
    ,{"GenerateSystemInfoReport",	GENERATE_SYSTEM_INFO_REPORT_REQ,      	NO_REQ_OP,	0}            
    ,{"GenerateTelesupReport",	GENERATE_TELESUP_REPORT_REQ,      	NO_REQ_OP,	0}        
    ,{"ReprintDeposit",	REPRINT_DEPOSIT_REQ,      	NO_REQ_OP,	0}            
    ,{"ReprintExtraction",	REPRINT_EXTRACTION_REQ,      	NO_REQ_OP,	0}        
    ,{"ReprintEndDay",	REPRINT_END_DAY_REQ,      	NO_REQ_OP,	0}            
    ,{"ReprintXClose",	REPRINT_PARTIAL_DAY_REQ,      	NO_REQ_OP,	0}            
    
    ,{"StartManualTelesup",	START_MANUAL_TELESUP_REQ,      	NO_REQ_OP,	0}       
    ,{"AcceptIncomingSupervision",	ACCEPT_INCOMING_SUP_REQ,      	NO_REQ_OP,	0}       
    
    
};

#define 	MAX_REQUEST_MAPPS 	(sizeof( mapReqMsg ) / sizeof( mapReqMsg[0] ))


@implementation G2TelesupParser

/******************************************************************************/


/* StartJob Request */
- (REQUEST) getNewStartJobRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;

/* CommitJob Request */
- (REQUEST) getNewCommitJobRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;

/* RollbackJob Request */
- (REQUEST) getNewRollbackJobRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;

/* GetAppliedMessages Request */
- (REQUEST) getNewGetAppliedMessagesRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;
            
/* GetDateTime */
- (REQUEST) getNewGetDateTimeRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;

/* Transferencia de informacion */

/* GetFileRequest */
- (REQUEST) getNewGetFileRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;

/* PutFileRequest */
- (REQUEST) getNewPutFileRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;

/* PutTextMessagesRequest */
- (REQUEST) getNewPutTextMessagesRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;

/* GetAudits */
- (REQUEST) getNewGetAuditsRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;

/* CleanData */
- (REQUEST) getNewCleanDataRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;

/* RestartSystemRequest */
- (REQUEST) getNewRestartSystemRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;

- (REQUEST) getNewG2Request: (ENTITY_REQUEST_OPS) aReqOp msg: (char*) aMessage reqType: (int) aReqType;

- (REQUEST) getNewGetDepositsRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;

- (REQUEST) getNewPimsRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;

- (REQUEST) getNewGetExtractionsRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;

- (REQUEST) getNewGetZCloseRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;

- (REQUEST) getNewGetXCloseRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;

- (REQUEST) getNewGetLogRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;

- (REQUEST) getNewGetUserRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;

- (REQUEST) getNewGetSettingsDumpRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;

- (REQUEST) getNewGetGenericFileRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;

- (REQUEST) getNewSystemOpRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage;


/*******************************************************************/

/**/
+ new
{
	printd("G2TelesupParser - new\n");
	return [[super new] initialize];
}


/**/
- initialize
{
	[super initialize];
	myTokenizer = [StringTokenizer new];
	[myTokenizer  setTrimMode: TRIM_NONE];
	[myTokenizer  setDelimiter: "\012"];
	myExecutionMode = 0;
	myEventsProxy = NULL;
    mySystemOpRequest = NULL;
	return self;
}


/**  Por razones de testing con el frontal los mensajes pueden venir con la palabra
 *  "Message" como inicio de mensaje o puede que venga directamente en la primer linea
 *  el nombre del mensjae (esto se define en tiempo de compilacion).
 */
- (char *) getRequestName: (char *) aMessage
{

	//doLog(0,"------------------------------------------\n%s\n-------------------------------\n", aMessage);

	/* La cadena viene sin espacios inciales */
	[myTokenizer setText: (char *) aMessage];

	/**/
	if (![myTokenizer hasMoreTokens])
		THROW( TSUP_INVALID_REQUEST_EX );
		
	/* La primera linea: el inicio de mensaje "Message\n" */
	
	/* El if porque agregamos y sacamos "Message" de los mensajes para testear */
	if (strlen(G2_TELESUP_MESSAGE_HEADER) > 0) {		
		[myTokenizer getNextToken: myTokenBuffer];
		if (strcasecmp(myTokenBuffer, G2_TELESUP_MESSAGE_HEADER) != 0) {
			//doLog(0,"MSG = |%s|\n", myTokenBuffer);
			THROW( TSUP_INVALID_REQUEST_EX );
		}
	}
	
	/**/
	if (![myTokenizer hasMoreTokens])
		THROW( TSUP_INVALID_REQUEST_EX );
	
	/* La segunda linea: el nombre del mensaje "MessageName\n" */			
	[myTokenizer getNextToken: myTokenBuffer];
	
	/* si el nombre es demasiado largo ... */	
	if (strlen(myTokenBuffer) > TELESUP_REQUEST_NAME_SIZE  ) 
		THROW(TSUP_NAME_TOO_LARGE_EX);

	/* Copia el nombre del Request */
	stringcpy(paramNameBuffer, myTokenBuffer);

	return paramNameBuffer;				
}


/**/
- (int) getRequestType: (char *) aRequestName
{
	MapRequestMsg  *mreq;

    printf(">>>>>>>>>>>>>>>>>>>>>>>>RequestName: %s\n", aRequestName);
    
	for (mreq = &mapReqMsg[0]; mreq < &mapReqMsg[MAX_REQUEST_MAPPS]; ++mreq)
	{
		if (strcasecmp(aRequestName, mreq->msg) == 0) return mreq->reqType;
    }
	//printf("Invalid Request: \"%s\"", aRequestName);
	THROW( TSUP_INVALID_REQUEST_EX );
	
	return 0;
}

/**/
- (ENTITY_REQUEST_OPS) getRequestOperation: (char *) aRequestName
{
	MapRequestMsg  *mreq;

	for (mreq = &mapReqMsg[0]; mreq < &mapReqMsg[MAX_REQUEST_MAPPS]; ++mreq)
		if (strcasecmp(aRequestName, mreq->msg) == 0) return mreq->action;

	THROW( TSUP_INVALID_REQUEST_EX );
	
	return NO_REQ_OP;
};

/**/
- (BOOL) isJobableRequest: (char *) aRequestName
{
	MapRequestMsg  *mreq;

	for (mreq = &mapReqMsg[0]; mreq < &mapReqMsg[MAX_REQUEST_MAPPS]; ++mreq)
		if (strcasecmp(aRequestName, mreq->msg) == 0) return mreq->jobable;

	THROW( TSUP_INVALID_REQUEST_EX );
	return FALSE;
};

/**/
- (BOOL) hasAllModifier: (char *) aMessage
{		
	/* La cadena viene sin espacios inciales */
	[myTokenizer setText: (char *)aMessage];

	if (![myTokenizer hasMoreTokens]) 
		return FALSE;
	
	/* Se saltea la primera linea */
	[myTokenizer getNextToken: myTokenBuffer];

	/* Recorre las lineas del mensaje */
	while ([myTokenizer hasMoreTokens]) {

		/* Obtiene la siguiente linea del mensaje (mantiene un \0 al final  de la linea ) */
		[myTokenizer getNextToken: myTokenBuffer];

		/**/
		if (strcasecmp(myTokenBuffer, "All") == 0)
			return TRUE;
	}
	return FALSE;
}


/**/
- (BOOL) isEqualsParamName: (char *) aBuffer to: (char *) aParamName
{
	char *p;	
	int len;

	assert(aBuffer);
	assert(aParamName);	

	/* Si es parametro de seteo debe venir el igual despues del nombre del parametro */		
	p =	index(aBuffer, '=');
	if (p == NULL)
		return FALSE;

	len = p - aBuffer;
	return strncasecmp(aBuffer, aParamName, len) == 0 && (len == strlen(aParamName));	
}

/**/
- (BOOL) isValidParam: (char *) aMessage name: (char *) aParamName
{
	assert(aMessage);
	assert(aParamName);
	
	stringcpy(paramNameBuffer, aParamName);
	
	[myTokenizer setText: (char *)aMessage];

	/* Se saltea la primera linea "Message" */
	if (strlen(G2_TELESUP_MESSAGE_HEADER) > 0) {
		if (![myTokenizer hasMoreTokens]) 
			return FALSE;
			
		[myTokenizer getNextToken: myTokenBuffer];
	}
	
	/**/
	if (![myTokenizer hasMoreTokens]) return FALSE;
	
	/* Se saltea la linea del nombre del mensaje */
	[myTokenizer getNextToken: myTokenBuffer];

	/* Recorre las lineas del mensaje */
	while ([myTokenizer hasMoreTokens]) {

		/* Obtiene la siguiente linea del mensaje (mantiene un \0 al final 
		  de la linea  ) */
		[myTokenizer getNextToken: myTokenBuffer];
		
		/* Si encuentra el parametro seguido por un '=' */
		if ([self isEqualsParamName: myTokenBuffer to: paramNameBuffer])
			return TRUE;
	}

	return FALSE;
}


/**/
- (BOOL) isValidModif: (char *) aMessage name: (char *) aModifier
{
	assert(aMessage);
	assert(aModifier);
		
	[myTokenizer setText: (char *)aMessage];

	/* Se saltea la primera linea "Message" */
	if (strlen(G2_TELESUP_MESSAGE_HEADER) > 0) {
		if (![myTokenizer hasMoreTokens]) 
			return FALSE;
			
		[myTokenizer getNextToken: myTokenBuffer];
	}
	
	/**/
	if (![myTokenizer hasMoreTokens]) return FALSE;
	
	/* Se saltea la linea del nombre del mensaje */
	[myTokenizer getNextToken: myTokenBuffer];

	/* Recorre las lineas del mensaje */
	while ([myTokenizer hasMoreTokens]) {

		/* Obtiene la siguiente linea del mensaje (mantiene un \0 al final 
		  de la linea  ) */
		[myTokenizer getNextToken: myTokenBuffer];
		
		/* Si encuentra el modificador ... */
		if (strcasecmp(myTokenBuffer, aModifier) == 0)
			return TRUE;
	}

	return FALSE;
}

/**/
- (void) checkForAllParams: (char *) aMessage paramList: (char **) aParamList paramCount: (int) aParamCount
{
	while (aParamCount--)	
		if (![self isValidParam: aMessage name: *aParamList++])
			THROW( TSUP_PARAM_NOT_FOUND_EX );			
}

/**/
- (void) checkForAnyParams: (char *) aMessage paramList: (char **) aParamList paramCount: (int) aParamCount
{
	/**/
	while (aParamCount--)	
		if ([self isValidParam: aMessage name: *aParamList++])
			return;
	
	THROW( TSUP_PARAM_NOT_FOUND_EX );
}

/**/
- (void) checkForAllAndAnyModifs: (char *) aMessage paramList: (char **) aModifList 
																		paramCount: (int) aModifCount
										
{
	/**/
	while (aModifCount--)	
		if ([self isValidModif: aMessage name: *aModifList++])
			return;

	/**/
	if (![self hasAllModifier: aMessage])
		THROW( TSUP_PARAM_NOT_FOUND_EX );	
}

/**/
- (char *) getDefaultFileName: (char *) ext
{
	static char name[255];
	//char date[30] = "2000-01-01T00:00:00";
	struct tm brokenTime;
	datetime_t date;

	// "EquipmentId.ISO8106"
	/*strcpy(name, [self getSystemId]);
	strcat(name, ".");
	if (datetimeToISO8106(date, getDateTime()) != NULL)
		strcat(name, date);
	else
		strcat(name, "2000-01-01T00:00:00");
				
	strcat(name, ".dat");
	
	return name;*/
	
	date =getDateTime();
	localtime_r(&date, &brokenTime);
	
	sprintf(name,"%s%4d%0.2d%0.2d%0.2d%0.2d%0.2d%03d%s", [self getSystemId], brokenTime.tm_year + 1900, brokenTime.tm_mon + 1, brokenTime.tm_mday, brokenTime.tm_hour, brokenTime.tm_min, brokenTime.tm_sec,_fileCount, ext);

  //doLog (1,"Nombre del Archivo: %s\n",name);			
  
  _fileCount = (_fileCount + 1) % 1000;
	
	return name;
}

/**/
- (char *) getParamAsTrimString: (char *) aMessage paramName: (char *) aParamName
{
	[self getParamAsString: aMessage paramName: aParamName];	
	return trim(paramValueBuffer);
	
}

/**/
- (char *) getParamAsString: (char *) aMessage paramName: (char *) aParamName
{
	/* Le agrega un '=' al parametro para hacer mas facil el parsing  */
	stringcpy(paramNameBuffer, aParamName);
	
	[myTokenizer setText: (char *)aMessage];

	/**/
	if (![myTokenizer hasMoreTokens])
		THROW( TSUP_PARAM_NOT_FOUND_EX );
		
	/* Se salte la primera linea */
	[myTokenizer getNextToken: myTokenBuffer];

	/* Recorre las lineas del mensaje */
	while ( [myTokenizer hasMoreTokens] ) {

	 	/* Obtiene la siguiente linea del mensaje (mantiene un \n al 
		   final de la linea ) */
		[myTokenizer getNextToken: myTokenBuffer];
	
		/* Si encuentra el parametro entonces devuelve el valor despues del '='  */		
		if ([self isEqualsParamName: myTokenBuffer to: paramNameBuffer]) 
			return stringcpy(paramValueBuffer, strchr(myTokenBuffer, '=') + 1);
	}
	
	//doLog(0,"G2TelesupParser: getParamAsString(\"%s\")\n", aParamName);

	THROW( TSUP_PARAM_NOT_FOUND_EX );
	return NULL;
}
	

/**/
- (int) getParamAsInteger: (char *) aMessage paramName: (char *) aParamName
{
	char *p = [self getParamAsString: aMessage paramName: aParamName]; 
	
	if (!p) 	
		return 0;
	else
		return atoi( p );
};

/**/ 
- (int) getParamAsLong: (char *) aMessage paramName: (char *) aParamName
{
	char *p = [self getParamAsString: aMessage paramName: aParamName]; 

	if (!p) 
		return 0;
	else
		return atol( p );
};

/**/
- (BOOL) getParamAsBoolean: (char *) aMessage paramName: (char *) aParamName
{
	char *p;
	char *s;

	p = [self getParamAsString: aMessage paramName: aParamName];	
	if (!p) 
		THROW( TSUP_PARAM_NOT_FOUND_EX );
	
	/* le saco los espacios a izquierda y derecha */
	s = trim(p);
	
	return strcasecmp(s, "True") == 0;	
};

/**/
- (float) getParamAsFloat: (char *) aMessage paramName: (char *) aParamName
{
	char *p; 
	char **paux = (char **)(&myAuxBuffer); 

	if ((p = [self getParamAsString: aMessage paramName: aParamName]) == NULL) 
		return 0;	

	return strtof((char *)p, paux);
};


/**/
- (money_t) getParamAsCurrency: (char *) aMessage paramName: (char *) aParamName
{	
	char *p; 
	char **paux = (char **)(&myAuxBuffer); 
	double d;
	
	if ((p = [self getParamAsString: aMessage paramName: aParamName]) == NULL) 
		return 0;	

	d = strtod((char *)p, paux);
	return doubleToMoney(d);
};


/**/
- (datetime_t) getParamAsDateTime: (char *) aMessage paramName: (char *) aParamName
{
	/*
	 *	Formato (siempre en hora UTC): 	 2004-10-18T12:53:21
 	 *			 				2004-10-18T12:53:21
	 */
	char *datebuf;
	datetime_t dt;

	if (!(datebuf = [self getParamAsString: aMessage paramName: aParamName])) 
		return 0;
	
	dt = ISO8106ToDatetime(datebuf);

  return dt;
};


/**/
- (REQUEST) getRequest: (char *) aMessage
{	
	REQUEST request;
	int reqType;
	ENTITY_REQUEST_OPS reqOperation;
	BOOL jobableRequest;

	/* Obtiene el identificador interno correspondiente al request recibido */
	stringcpy(myRequestName, [self getRequestName: aMessage]);
	reqType = [self getRequestType: myRequestName];
	reqOperation = [self getRequestOperation: myRequestName];
	jobableRequest = [self isJobableRequest: myRequestName];
		
	/* Crea el request correspondiente */ 
	request = [self getRequestFromType: reqType operation: reqOperation msg: aMessage];

	/* Configuracion comun */
	[request setReqOperation: reqOperation];

	[request setReqType: reqType];	

	[request setJobable: jobableRequest];	


	/* El identificador optativo de mensaje */
	if ([self isValidParam: aMessage name: "MessageId"]) 
			[request setReqMessageId: [self getParamAsInteger: aMessage paramName:  "MessageId"]];

	return request;
}


/**
 * Debe ser llamada cada vez que se crea un Request
 */
- (void) configureRequest: (REQUEST) aRequest type: (int) reqType operation: (ENTITY_REQUEST_OPS) aReqOp 
{ 
	[aRequest setReqOperation: aReqOp];

	if (reqType == SET_REQUEST_TYPE)
		[aRequest assignRestoreInfo];
}


/**
 *
 */
- (REQUEST) getRequestFromType: (int) aReqType operation: (ENTITY_REQUEST_OPS) aReqOp msg: (char *)aMessage
{	
	////doLog(0,"--------------> Mensaje - GetRequestFromType \n %s \n", aMessage);

	switch (aReqType) {

		case GET_GENERAL_BILL_REQ:
		case SET_GENERAL_BILL_REQ:

		case GET_CIM_GENERAL_SETTINGS_REQ:
		case SET_CIM_GENERAL_SETTINGS_REQ:

		case SET_DOOR_REQ:
		case GET_DOOR_REQ:

		case SET_ACCEPTOR_REQ:
		case GET_ACCEPTOR_REQ:

		case GET_CURRENCY_DENOMINATION_REQ:
		case SET_CURRENCY_DENOMINATION_REQ:
        case GET_DENOMINATION_LIST_REQ:

		case GET_DEPOSIT_VALUE_TYPE_REQ:
		case SET_DEPOSIT_VALUE_TYPE_REQ:

		case GET_DEPOSIT_VALUE_TYPE_CURRENCY_REQ:
		case SET_DEPOSIT_VALUE_TYPE_CURRENCY_REQ:

		case GET_CURRENCY_REQ:

		case GET_CURRENCY_BY_ACCEPTOR_REQ:

        case SET_CASH_BOX_REQ:
        case GET_CASH_BOX_REQ:

        case SET_CASH_REFERENCE_REQ:
        case GET_CASH_REFERENCE_REQ:

        case GET_ACCEPTORS_BY_CASH_REQ:
        case SET_ACCEPTORS_BY_CASH_REQ:

	 	case SET_BOX_REQ:
	 	case GET_BOX_REQ:

	 	case GET_ACCEPTORS_BY_BOX_REQ:
		case SET_ACCEPTORS_BY_BOX_REQ:
	 
		case GET_DOORS_BY_BOX_REQ:
        case SET_DOORS_BY_BOX_REQ:

		case GET_PRINT_SYSTEM_REQ:
		case SET_PRINT_SYSTEM_REQ:

		case GET_COMMERCIAL_STATE_REQ:
		case SET_COMMERCIAL_STATE_REQ:

		case GET_REGIONAL_SETTINGS_REQ:
		case SET_REGIONAL_SETTINGS_REQ:

		case GET_AMOUNT_MONEY_REQ:
		case SET_AMOUNT_MONEY_REQ:
		
		case GET_USER_REQ:
		case SET_USER_REQ:
		case GET_USER_WITH_CHILDREN_REQ:

		case GET_USER_PROFILE_REQ:
		case GET_USER_PROFILE_CHILDREN_REQ:
		case SET_USER_PROFILE_REQ:
		case GET_OPERATION_REQ:

		case GET_CURRENT_BALANCE_REQ:
		case LOGIN_REMOTE_USER_REQ:

		case GET_TELESUP_SETTINGS_REQ:
		case SET_TELESUP_SETTINGS_REQ:
		case GET_CONNECTION_REQ:
		case SET_CONNECTION_REQ:
		case GET_VERSION_REQ:
		case GET_SYSTEM_INFO_REQ:
        case SET_DATETIME_REQ:
        case GET_DOORS_BY_USER_REQ:
        case GET_DOORS_BY_USERS_REQ:
        case SET_DOOR_BY_USER_REQ:
        case GET_DUAL_ACCESS_REQ:
        case SET_DUAL_ACCESS_REQ:
        case SET_FORCE_PIN_CHANGE_REQ:
        case SET_WORK_ORDER_REQ:
        case SET_REPAIR_ORDER_REQ:
        case GET_REPAIR_ORDER_REQ:
            
        case GET_EVENTS_CATEGORIES_REQ:
            
			return [self getNewG2Request: aReqOp msg: aMessage reqType: aReqType];

/* Los Request reales */
		/* StartJob Request */
		case START_JOB_REQ:
			return [self getNewStartJobRequest: aReqOp msg: aMessage];

		/* CommitJob Request */
		case COMMIT_JOB_REQ:
			return [self getNewCommitJobRequest: aReqOp msg: aMessage];

		/* RollbackJob Request */
		case ROLLBACK_JOB_REQ:
			return [self getNewRollbackJobRequest: aReqOp msg: aMessage];

		/* RollbackJob Request */
		case GET_APPLIED_MESSAGES_REQ:
			return [self getNewGetAppliedMessagesRequest: aReqOp msg: aMessage];
			
		/* GetDateTime */		
/*		case GET_DATETIME_REQ:

			// Audito el evento
		  [Audit auditEvent: TELESUP_GET_DATE_TIME additional: "" station: 0 logRemoteSystem: TRUE]; 

			return [self getNewGetDateTimeRequest: aReqOp msg: aMessage];
*/
/* Transferencias de archivos */

		/* GetFileRequest */
		case GET_FILE_REQ:
			return [self getNewGetFileRequest: aReqOp msg: aMessage];

		/* PutFileRequest */
		case PUT_FILE_REQ:
			return [self getNewPutFileRequest: aReqOp msg: aMessage];

		/* GetAudits */
		case GET_AUDITS_REQ:

			if (![[CommercialStateMgr getInstance] canExecuteModule: ModuleCode_SEND_AUDITS executionMode: myExecutionMode]) THROW(MODULE_CANNOT_BE_EXECUTED_EX);

      [Audit auditEvent: TELESUP_GET_AUDITS additional: "" station: 0 logRemoteSystem: TRUE]; 		
			return [self getNewGetAuditsRequest: aReqOp msg: aMessage];

		/* GetDeposits */
		case GET_DEPOSITS_REQ:

			if (![[CommercialStateMgr getInstance] canExecuteModule: ModuleCode_SEND_DROPS executionMode: myExecutionMode]) THROW(MODULE_CANNOT_BE_EXECUTED_EX);

      [Audit auditEvent: Event_DROP_REQUEST additional: "" station: 0 logRemoteSystem: TRUE];
			return [self getNewGetDepositsRequest: aReqOp msg: aMessage];			

	/* GetExtractions*/
		case GET_EXTRACTIONS_REQ:

			if (![[CommercialStateMgr getInstance] canExecuteModule: ModuleCode_SEND_EXTRACTIONS executionMode: myExecutionMode]) THROW(MODULE_CANNOT_BE_EXECUTED_EX);

			[Audit auditEvent: Event_DEPOSIT_REQUEST additional: "" station: 0 logRemoteSystem: TRUE];
			return [self getNewGetExtractionsRequest: aReqOp msg: aMessage];			

	/* PutTextMessagesRequest */
		case PUT_TEXT_MESSAGES_REQ:
			return [self getNewPutTextMessagesRequest: aReqOp msg: aMessage];
			
		case CLEAN_DATA_REQ:
			return [self getNewCleanDataRequest: aReqOp msg: aMessage];

		case RESTART_SYSTEM_REQ:
			return [self getNewRestartSystemRequest: aReqOp msg: aMessage];

		/* GetZCloses */
		case GET_ZCLOSE_REQ:

			if (![[CommercialStateMgr getInstance] canExecuteModule: ModuleCode_SEND_END_OF_DAY executionMode: myExecutionMode]) THROW(MODULE_CANNOT_BE_EXECUTED_EX);

      //[Audit auditEvent: Event_DEPOSIT_REQUEST additional: "" station: 0 logRemoteSystem: TRUE]; 		
			return [self getNewGetZCloseRequest: aReqOp msg: aMessage];		

		/* GetXCloses */
		case GET_XCLOSE_REQ:

			if (![[CommercialStateMgr getInstance] canExecuteModule: ModuleCode_SEND_END_OF_DAY executionMode: myExecutionMode]) THROW(MODULE_CANNOT_BE_EXECUTED_EX);

      //[Audit auditEvent: Event_DEPOSIT_REQUEST additional: "" station: 0 logRemoteSystem: TRUE]; 		
			return [self getNewGetXCloseRequest: aReqOp msg: aMessage];

		/* GetAllUsers */
		case GET_ALL_USER_REQ:
			return [self getNewGetUserRequest: aReqOp msg: aMessage];

		case GET_LOG_REQ:
      //[Audit auditEvent: Event_DEPOSIT_REQUEST additional: "" station: 0 logRemoteSystem: TRUE]; 		
			return [self getNewGetLogRequest: aReqOp msg: aMessage];

		case GET_SETTINGS_DUMP_REQ:
      //[Audit auditEvent: Event_DEPOSIT_REQUEST additional: "" station: 0 logRemoteSystem: TRUE]; 		
			return [self getNewGetSettingsDumpRequest: aReqOp msg: aMessage];

		case GET_GENERIC_FILE_REQ:
			return [self getNewGetGenericFileRequest: aReqOp msg: aMessage];


	// PIMS
		case GET_CONNECTION_INTENTION_REQ:
        case KEEP_ALIVE_REQ:
		case INFORM_REPAIR_ORDER_DATA_REQ:
		case INFORM_STATE_CHANGE_RESULT_REQ:
		case GET_STATE_CHANGE_CONFIRMATION_REQ:
		case INFORM_STATE_CHANGE_CONFIRMATION_RESULT_REQ:
        case SET_MODULE_REQ:
		case GET_USER_TO_LOGIN_REQ:
		case SET_USER_TO_LOGIN_RESPONSE_REQ:
		case SET_INSERT_DEPOSIT_RESULT_REQ:
		case GET_INTERNAL_USER_ID_REQ:
			return [self getNewPimsRequest: aReqOp msg: aMessage];

   // REMOTE CONSOLE                
        case USER_LOGIN_REQ:
        case USER_HAS_CHANGE_PIN_REQ:
        case USER_CHANGE_PIN_REQ:
        case USER_LOGOUT_REQ:

        case START_VALIDATED_DROP_REQ:
        case END_VALIDATED_DROP_REQ: 
        case INIT_EXTRACTION_PROCESS_REQ:
        case GET_DOOR_STATE_REQ:
        case SET_REMOVE_CASH_REQ:
        case USER_LOGIN_FOR_DOOR_ACCESS_REQ:
        case CLOSE_EXTRACTION_REQ:
        case CANCEL_DOOR_ACCESS_REQ:
        case START_DOOR_ACCESS_REQ:
        case START_EXTRACTION_REQ:
        case CANCEL_TIME_DELAY_REQ:
        case START_MANUAL_DROP_REQ:
        case ADD_MANUAL_DROP_DETAIL_REQ:
        case PRINT_MANUAL_DROP_RECEIPT_REQ:
        case CANCEL_MANUAL_DROP_REQ:
        case FINISH_MANUAL_DROP_REQ:            
        case START_VALIDATION_MODE_REQ:
        case STOP_VALIDATION_MODE_REQ:
        case GENERATE_OPERATOR_REPORT_REQ:
        case HAS_ALREADY_PRINT_END_DAY_REQ:
        case GENERATE_END_DAY_REQ:
        case GENERATE_ENROLLED_USERS_REPORT_REQ:
        case GENERATE_AUDIT_REPORT_REQ:
        case GENERATE_CASH_REPORT_REQ:
        case GENERATE_X_CLOSE_REPORT_REQ:
        case GENERATE_REFERENCE_REPORT_REQ:
        case GENERATE_SYSTEM_INFO_REPORT_REQ:
        case GENERATE_TELESUP_REPORT_REQ:
        case REPRINT_DEPOSIT_REQ:
        case REPRINT_EXTRACTION_REQ:
        case REPRINT_END_DAY_REQ:
        case REPRINT_PARTIAL_DAY_REQ:     
        case START_MANUAL_TELESUP_REQ:
        case ACCEPT_INCOMING_SUP_REQ:
        case GET_DATETIME_REQ:
            printf(">>>>>>>>>>>>>>>>>>>>>>>>> getNewSystemOpRequest\n");
            return [self getNewSystemOpRequest: aReqOp msg: aMessage];

            

		case INVALID_REQ:
		default:
			break;
	}		

	THROW( TSUP_INVALID_REQUEST_EX );
	
	return NULL;
}

/**
 * Definicion de metodos de creacion y configuracion de cada Request
 **/

/**
 * JOBS **
 **/

/*
 * StartJob Request *
 */ 
- (REQUEST) getNewStartJobRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage
{
	REQUEST request = NULL;
#if 0
	printd("G2TelesupParser - getNewStartJobRequest\n");

	/* Crea el Request */
	request = [StartJobRequest new];

	/* Asigna los valores a los atributos que estan actualmente seteados en el sistema */
	[self configureRequest: request type: GENERAL_REQUEST_TYPE operation: aReqOp]; 
	
	/* La fechas de vigencia */
	[request setReqInitialVigencyDate: 0];
	if ([self isValidParam: aMessage name: "InitialVigencyDate"]) 
		[request setReqInitialVigencyDate: [self getParamAsDateTime: aMessage paramName:  "InitialVigencyDate"]];
#endif

	return request;
};


/*
 * CommitJobRequest *
 */ 
- (REQUEST) getNewCommitJobRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage
{
	REQUEST request = NULL;
#if 0
	printd("G2TelesupParser - getNewCommitJobRequest\n");

	/* Crea el Request */
	request = [CommitJobRequest new];

	/* Asigna los valores a los atributos que estan actualmente seteados en el sistema */
	[self configureRequest: request type: GENERAL_REQUEST_TYPE operation: aReqOp]; 
#endif
	
	return request;
};


/*
 * RollbackJob Request *
 */ 
- (REQUEST) getNewRollbackJobRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage
{
	REQUEST request = NULL;
#if 0
	printd("G2TelesupParser - getNewRollbackJobRequest\n");

	/* Crea el Request */
	request = [RollbackJobRequest new];

	/* Asigna los valores a los atributos que estan actualmente seteados en el sistema */
	[self configureRequest: request type: GENERAL_REQUEST_TYPE operation: aReqOp]; 
#endif
	return request;
};

/*
 * AppliedMessages Request *
 */ 
- (REQUEST) getNewGetAppliedMessagesRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage
{
	REQUEST request = NULL;

	printd("G2TelesupParser - getNewGetAppliedMessagesRequest\n");

#if 0
	/* Crea el Request */
	request = [GetAppliedMessagesRequest new];

	/* Asigna los valores a los atributos que estan actualmente seteados en el sistema */
	[self configureRequest: request type: GET_REQUEST_TYPE operation: aReqOp]; 

	
	/* asigna los filtros */ 
	if ([self isValidParam: aMessage name: 									"FromId"]) {
		[request setFilterInfoType: ID_INFO_FILTER];
		[request setFromId: [self getParamAsLong: aMessage paramName: 		"FromId"]];
	}
		
	if ([self isValidParam: aMessage name: 									"ToId"])  {
		[request setFilterInfoType: ID_INFO_FILTER];
		[request setToId: [self getParamAsLong: aMessage paramName: 		"ToId"]];
	}
#endif	
	return request;
}


/*
 * GetDateTimeRequest
 */
- (REQUEST) getNewGetDateTimeRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage
{		
	REQUEST request;
	char *params[] = {"DateTime"};

	printd("G2TelesupParser - getNewGetDateTimeRequest\n");

	/* Crea el Request */
	request = [GetDateTimeRequest new];
	[request setFreeAfterExecute: TRUE];
	
	/*  */
	[self configureRequest: request type: GET_REQUEST_TYPE operation: aReqOp];		

	[self checkForAllAndAnyModifs: aMessage paramList: params paramCount: 1];
	
	return request;		
}; 


/**
 * TRANSFERENCIAS DE ARCHIVOS **
 **/

/*
 * GetFileRequest
 */
- (REQUEST) getNewGetFileRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char*) aMessage
{		
	REQUEST request;

	printd("G2TelesupParser - getNewGetFileRequest\n");

	request = [GetFileRequest new];
	[request setFreeAfterExecute: TRUE];

	[self configureRequest: request type: GET_FILE_REQUEST_TYPE operation: aReqOp];	

	/* El nombre del archivo destino */
	if ([self isValidParam: aMessage name: "SourceFileName"])
		[request setSourceFileName: 	[self getParamAsString: aMessage paramName:	"SourceFileName"]];
	else
		[request setSourceFileName: 	[self getDefaultFileName:""]];

	if ([self isValidParam: aMessage name: "TargetFileName"])
		[request setTargetFileName: [self getParamAsString: aMessage paramName: "TargetFileName"]];	
	else
		[request setTargetFileName: 	[self getDefaultFileName:""]];

	return request;		
}

/**/
- (char *) getPathFromCategory: (char *) aCategory
{
	int i;

	for (i = 0; i < sizeOfArray(categories); ++i)
		if (strcasecmp(categories[i].category, aCategory) == 0) return categories[i].path;

	// categoria por defecto
	return categories[0].path;
}

 /**
 * PutFileRequest
 */
- (REQUEST) getNewPutFileRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char*) aMessage
{		
	REQUEST request;
	char *category = NULL;
	char *targetFileName = NULL;
	char path[255];
	char onlyPath[255];

	printd("G2TelesupParser - getNewPutFileRequest\n");

	if ([self isValidParam: aMessage name: "Category"]) {

		category = [self getParamAsString: aMessage paramName: "Category"];

		if (strcmp(category, "FIRM_UPDATE") == 0) {
			if (![[CommercialStateMgr getInstance] canExecuteModule: ModuleCode_VALIDATORS_UPDATE executionMode: myExecutionMode]) THROW(MODULE_CANNOT_BE_EXECUTED_EX);
		}

		if (strcmp(category, "UPDATE") == 0) {
			if (![[CommercialStateMgr getInstance] canExecuteModule: ModuleCode_SOFTWARE_UPDATE executionMode: myExecutionMode]) THROW(MODULE_CANNOT_BE_EXECUTED_EX);
		}

	}	

	request = [PutFileRequest new];
	[request setFreeAfterExecute: TRUE];

	[self configureRequest: request type: PUT_FILE_REQUEST_TYPE operation: aReqOp];	

	/* El path completo al archivo destino se determina de la siguiente manera:

			Cada categoria tiene asociado un path adonde se debe enviar el archivo.
			El nombre de la categoria me determina el directorio y el campo FileName el nombre del archivo.
			Es decir path = Category directory / FileName

			Si la categoria no existe o es UNKNOWN, el path es igual al campo TargetFileName
  */



	strcpy(path, "");

	/* Nombre de archivo origen */
	if ([self isValidParam: aMessage name: "SourceFileName"])
		[request setSourceFileName: 	[self getParamAsString: aMessage paramName:	"SourceFileName"]];
	else
		[request setSourceFileName: 	[self getDefaultFileName:""]];

	/* Categoria del archivo */
	if ([self isValidParam: aMessage name: "Category"]) {
		category = [self getParamAsString: aMessage paramName: "Category"];
	
		// si se recibe un update de app indico que se debe reiniciar la app
		// al finalizar la supervision
		if (strcmp(category, "UPDATE") == 0){
			if ([[TelesupScheduler getInstance] inTelesup])
				[[TelesupScheduler getInstance] setShutdownApp: TRUE];
			else
				[[Acceptor getInstance] setShutdownApp: TRUE];
		}
			
		strcpy(path, [self getPathFromCategory: category]);
		strcpy(onlyPath, [self getPathFromCategory: category]);
	}

	/* Nombre del archivo */
	if ([self isValidParam: aMessage name: "FileName"]) {
 		targetFileName = [self getParamAsString: aMessage paramName: "FileName"];
	} else {
		/* Path completo al archivo destino */
		if ([self isValidParam: aMessage name: "TargetFileName"])
			targetFileName = [self getParamAsString: aMessage paramName: "TargetFileName"];
		else
			targetFileName = [self getDefaultFileName:""];
	}

	strcat(path, targetFileName);

	// carga el mensaje
	[request loadPackage: aMessage];

	//doLog(0,"Bajando archivo a |%s|\n", path);
	[request setTargetFileName: path];
	[request setPath: onlyPath];

	return request;		
};


/**
 * PutTextMessagesRequest
 */
- (REQUEST) getNewPutTextMessagesRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char*) aMessage
{		
	REQUEST request;
	char path[255];
	char datetime[255];
	struct tm brokenTime;
	
	printd("G2TelesupParser - getNewPutTextMessagesRequest");

	request = [PutTextMessagesRequest new];
	[request setFreeAfterExecute: TRUE];

	[self configureRequest: request type: PUT_FILE_REQUEST_TYPE operation: aReqOp];	

	// Crea el directorio si no existe
	[File makeDir: [[Configuration getDefaultInstance] getParamAsString: "MESSAGES_PATH"
					default: BASE_APP_PATH "/messages"]];

	[SystemTime decodeTime: [SystemTime getLocalTime] brokenTime: &brokenTime];

	strftime(datetime, 50, "%s", &brokenTime);
	
	sprintf(path, "%s/%s_%ld.msg",
					[[Configuration getDefaultInstance] getParamAsString: "MESSAGES_PATH"
					default: BASE_APP_PATH "/messages"],
					datetime,
					(unsigned long) getTicks());
					
	// Configura el nombre del archivo destino
	[request setTargetFileName: path];
	
	return request;		
}

/*
 * GetAuditsRequest
 */
- (REQUEST) getNewGetAuditsRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage
{		
	REQUEST request;	

	//doLog(0,"G2TelesupParser - getNewGetAuditsRequest\n"); fflush(stdout);

	request = [GetAuditsRequest new];
	[request setFreeAfterExecute: TRUE];

	[self configureRequest: request type: GET_DATA_FILE_REQUEST_TYPE operation: aReqOp];	
	
	/* El nombre del archivo destino */
	if ([self isValidParam: aMessage name: "FileName"]) 	
		[request setTargetFileName: 	[self getParamAsString: aMessage paramName:	"FileName"]];
	else
		[request setTargetFileName: 	[self getDefaultFileName:".aud"]];

	/* le indico quien ejecuto el mensaje */
	[request setExecutionMode: myExecutionMode];

	/* El filtro de auditorias  */	
	if ([self isValidParam: aMessage name: "FromDate"] ||
		[self isValidParam: aMessage name: "ToDate"]) {

			[request setFilterInfoType: DATE_INFO_FILTER];
			if ([self isValidParam: aMessage name: "FromDate"])
				[request setFromDate: 	[self getParamAsDateTime: aMessage paramName: "FromDate"]];

			if ([self isValidParam: aMessage name: "ToDate"]) 
				[request setToDate: 	[self getParamAsDateTime: aMessage paramName: "ToDate"]];
	}	

	if ([self isValidParam: aMessage name: "FromAuditId"] ||
		[self isValidParam: aMessage name: "ToAuditId"]) {

			[request setFilterInfoType: ID_INFO_FILTER];
			if ([self isValidParam: aMessage name: "FromAuditId"]) 
				[request setFromId: 		[self getParamAsInteger: aMessage paramName: "FromAuditId"]];
			
			if ([self isValidParam: aMessage name: "ToAuditId"])
				[request setToId: 	[self getParamAsInteger: aMessage paramName: "ToAuditId"]];
	}

	/* Los modificadores */			
  if ([self isValidParam: aMessage name: "NotTransferedOnly"] && [self getParamAsBoolean: aMessage paramName: "NotTransferedOnly"]) { 		
		[request setFilterInfoType: NOT_TRANSFER_INFO_FILTER];
  }


  if ([self isValidParam: aMessage name: "OnlyCritical"]) { 		
		[request setTransferOnlyCritical: [self getParamAsBoolean: aMessage paramName: "OnlyCritical"]];
  }
	
	return request;	
}


/*
 * GetDepositsRequest
 */
- (REQUEST) getNewGetDepositsRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage
{		
	REQUEST request;	

	//doLog(0,"G2TelesupParser - getNewGetDepositsRequest\n"); fflush(stdout);

	request = [GetDepositsRequest new];
	[request setFreeAfterExecute: TRUE];

	[self configureRequest: request type: GET_DATA_FILE_REQUEST_TYPE operation: aReqOp];	
	
	/* El nombre del archivo destino */
	if ([self isValidParam: aMessage name: "FileName"]) 	
		[request setTargetFileName: 	[self getParamAsString: aMessage paramName:	"FileName"]];
	else
		[request setTargetFileName: 	[self getDefaultFileName:".dep"]];
		
	/* El filtro de depositos  */	
	if ([self isValidParam: aMessage name: "FromDate"] &&
	  	[self isValidParam: aMessage name: "ToDate"]) {

			[request setFilterInfoType: DATE_INFO_FILTER];
			[request setFromDate: 	[self getParamAsDateTime: aMessage paramName: "FromDate"]];
			[request setToDate: 	[self getParamAsDateTime: aMessage paramName: "ToDate"]];
	}	

	if ([self isValidParam: aMessage name: "FromNumber"] &&
  		[self isValidParam: aMessage name: "ToNumber"]) {

			[request setFilterInfoType: NUMBER_INFO_FILTER];
			[request setFromDepositNumber: 		[self getParamAsInteger: aMessage paramName: "FromNumber"]];
			[request setToDepositNumber: 	[self getParamAsInteger: aMessage paramName: "ToNumber"]];
	}

	/* Los modificadores */			
  if ([self isValidParam: aMessage name: "NotTransferedOnly"] && 
			[self getParamAsBoolean: aMessage paramName: "NotTransferedOnly"]) {
		[request setFilterInfoType: NOT_TRANSFER_INFO_FILTER];
		// le seteo el numero de deposito hasta para de esta manera asegurarme que el
		// ultimo deposito enviado ya haya finalizado y se haya almacenado de manera completa.
		// Este control se agrego porque ocurrio que se enviaran depositos con menos detalles
		// que los que realmente tenia. Este caso solo puede ocurrir cuando se generan
		// muchos depositos uno tras otro y se esta utilizando la supervision automatica.
		[request setToDepositNumber: [[DepositManager getInstance] getLastDepositNumber]];
  }
	
	return request;	
}

/*Extractions*/
- (REQUEST) getNewGetExtractionsRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage
{		
	REQUEST request;	

	//doLog(0,"G2TelesupParser - getNewGetExtractionsRequest\n"); fflush(stdout);

	request = [GetExtractionsRequest new];
	[request setFreeAfterExecute: TRUE];

	[self configureRequest: request type: GET_DATA_FILE_REQUEST_TYPE operation: aReqOp];	
	
	/* El nombre del archivo destino */
	if ([self isValidParam: aMessage name: "FileName"]) 	
		[request setTargetFileName: [self getParamAsString: aMessage paramName:	"FileName"]];
	else
		[request setTargetFileName: [self getDefaultFileName:".ext"]];
		
	/* El filtro de depositos  */	
	if ([self isValidParam: aMessage name: "FromDate"] &&
	  	[self isValidParam: aMessage name: "ToDate"]) {

			[request setFilterInfoType: DATE_INFO_FILTER];
			[request setFromDate: [self getParamAsDateTime: aMessage paramName: "FromDate"]];
			[request setToDate: [self getParamAsDateTime: aMessage paramName: "ToDate"]];

	}	

	if ([self isValidParam: aMessage name: "FromNumber"] &&
  		[self isValidParam: aMessage name: "ToNumber"]) {

			[request setFilterInfoType: NUMBER_INFO_FILTER];
			[request setFromExtractionNumber: [self getParamAsInteger: aMessage paramName: "FromNumber"]];
			[request setToExtractionNumber: [self getParamAsInteger: aMessage paramName: "ToNumber"]];

	}

	/* Los modificadores */			
  if ([self isValidParam: aMessage name: "NotTransferedOnly"] && 
			[self getParamAsBoolean: aMessage paramName: "NotTransferedOnly"]) {		
		[request setFilterInfoType: NOT_TRANSFER_INFO_FILTER];
		// le seteo el numero de extraccion hasta para de esta manera asegurarme que la
		// ultima extraccion enviada ya haya finalizado y se haya almacenado de manera completa.
		[request setToExtractionNumber: [[ExtractionManager getInstance] getLastExtractionNumber]];
  }
	
	return request;	
}

/*
 * GetZCloseRequest
 */
- (REQUEST) getNewGetZCloseRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage
{		
	REQUEST request;	

	//doLog(0,"G2TelesupParser - getNewGetZCloseRequest\n"); fflush(stdout);

	request = [GetZCloseRequest new];
	[request setFreeAfterExecute: TRUE];

	[self configureRequest: request type: GET_DATA_FILE_REQUEST_TYPE operation: aReqOp];	
	
	/* El nombre del archivo destino */
	if ([self isValidParam: aMessage name: "FileName"]) 	
		[request setTargetFileName: 	[self getParamAsString: aMessage paramName:	"FileName"]];
	else
		[request setTargetFileName: 	[self getDefaultFileName:".zcl"]];
		
	/* El filtro de depositos  */	
	if ([self isValidParam: aMessage name: "FromDate"] &&
	  	[self isValidParam: aMessage name: "ToDate"]) {

			[request setFilterInfoType: DATE_INFO_FILTER];
			[request setFromDate: 	[self getParamAsDateTime: aMessage paramName: "FromDate"]];
			[request setToDate: 	[self getParamAsDateTime: aMessage paramName: "ToDate"]];

	}	

	if ([self isValidParam: aMessage name: "FromNumber"] &&
  		[self isValidParam: aMessage name: "ToNumber"]) {

			[request setFilterInfoType: NUMBER_INFO_FILTER];
			[request setFromZCloseNumber: 		[self getParamAsInteger: aMessage paramName: "FromNumber"]];
			[request setToZCloseNumber: 	[self getParamAsInteger: aMessage paramName: "ToNumber"]];

	}

	/* Los modificadores */			
  if ([self isValidParam: aMessage name: "NotTransferedOnly"] && 
			[self getParamAsBoolean: aMessage paramName: "NotTransferedOnly"]) { 		
		[request setFilterInfoType: NOT_TRANSFER_INFO_FILTER];
  }
	
	return request;	
}

/*
 * GetXCloseRequest
 */
- (REQUEST) getNewGetXCloseRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage
{		
	REQUEST request;	

	//doLog(0,"G2TelesupParser - getNewGetXCloseRequest\n"); fflush(stdout);

	request = [GetXCloseRequest new];
	[request setFreeAfterExecute: TRUE];

	[self configureRequest: request type: GET_DATA_FILE_REQUEST_TYPE operation: aReqOp];	
	
	/* El nombre del archivo destino */
	if ([self isValidParam: aMessage name: "FileName"]) 	
		[request setTargetFileName: 	[self getParamAsString: aMessage paramName:	"FileName"]];
	else
		[request setTargetFileName: 	[self getDefaultFileName:".xcl"]];
		
	/* El filtro de depositos  */	
	if ([self isValidParam: aMessage name: "FromDate"] &&
	  	[self isValidParam: aMessage name: "ToDate"]) {

			[request setFilterInfoType: DATE_INFO_FILTER];
			[request setFromDate: 	[self getParamAsDateTime: aMessage paramName: "FromDate"]];
			[request setToDate: 	[self getParamAsDateTime: aMessage paramName: "ToDate"]];

	}	

	if ([self isValidParam: aMessage name: "FromNumber"] &&
  		[self isValidParam: aMessage name: "ToNumber"]) {

			[request setFilterInfoType: NUMBER_INFO_FILTER];
			[request setFromXCloseNumber: 		[self getParamAsInteger: aMessage paramName: "FromNumber"]];
			[request setToXCloseNumber: 	[self getParamAsInteger: aMessage paramName: "ToNumber"]];

	}

	/* Los modificadores */			
  if ([self isValidParam: aMessage name: "NotTransferedOnly"] && 
			[self getParamAsBoolean: aMessage paramName: "NotTransferedOnly"]) { 		
		[request setFilterInfoType: NOT_TRANSFER_INFO_FILTER];
  }
	
	return request;	
}

/*
 * getNewGetUserRequest
 */
- (REQUEST) getNewGetUserRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage
{		
	REQUEST request;	

	//doLog(0,"G2TelesupParser - getNewGetUserRequest\n"); fflush(stdout);

	request = [GetUserRequest new];
	[request setFreeAfterExecute: TRUE];

	[self configureRequest: request type: GET_DATA_FILE_REQUEST_TYPE operation: aReqOp];	
	
	// El nombre del archivo destino
	if ([self isValidParam: aMessage name: "FileName"]) 	
		[request setTargetFileName: 	[self getParamAsString: aMessage paramName:	"FileName"]];
	else
		[request setTargetFileName: 	[self getDefaultFileName:".usr"]];
		
	// Solicita un usuario con los hijos de este
	if ([self isValidParam: aMessage name: "UserId"]) {
		[request setUserId: [self getParamAsInteger: aMessage paramName: "UserId"]];
	} else {
		[request setUserId: 0]; // todos los usuarios
	}
	
	return request;	
}

/*
 * GetLogRequest
 */
- (REQUEST) getNewGetLogRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage
{		
	REQUEST request;	

	//doLog(0,"G2TelesupParser - getNewGetLogRequest\n"); fflush(stdout);

	request = [GetLogRequest new];
	[request setFreeAfterExecute: TRUE];

	[self configureRequest: request type: GET_FILE_REQ operation: aReqOp];	
	
	if ([self isValidParam: aMessage name: "FileName"])
		[request setSourceFileName: [self getParamAsString: aMessage paramName:	"FileName"]];
	else
		[request setSourceFileName: [self getDefaultFileName:".log"]];

	if ([self isValidParam: aMessage name: "AllLogsCompressed"]) {
		[request sendAllLogsCompressed: [self getParamAsBoolean: aMessage paramName: "AllLogsCompressed"]];
	}

	return request;	
}
///////////////////////////////////////////////////////////////
- (REQUEST) getNewGetGenericFileRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage
{		
	REQUEST request;	

	//doLog(0,"G2TelesupParser - getNewGetGenericFileRequest\n"); fflush(stdout);

	request = [GetGenericFileRequest new];
	[request setFreeAfterExecute: TRUE];

	[self configureRequest: request type: GET_GENERIC_FILE_REQ operation: aReqOp];	
	
	if ([self isValidParam: aMessage name: "FileName"]) {
		[request setPathName: [self getParamAsString: aMessage paramName:	"FileName"]];
	}

	if ([self isValidParam: aMessage name: "AllLogsCompressed"]) {
		[request setCompressed: [self getParamAsBoolean: aMessage paramName: "AllLogsCompressed"]];
	}

	if ([self isValidParam: aMessage name: "DataNeeded"]) {
		[request setDataNeeded: [self getParamAsBoolean: aMessage paramName: "DataNeeded"]];
	}


	return request;	
}

///////////////////////////////////////////////////////////////


/*
 * GetSettingsDumpRequest
 */
- (REQUEST) getNewGetSettingsDumpRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage
{		
	REQUEST request;	

	//doLog(0,"G2TelesupParser - getNewGetSettingsDumpRequest\n"); fflush(stdout);

	request = [GetSettingsDumpRequest new];
	[request setFreeAfterExecute: TRUE];

	[self configureRequest: request type: GET_FILE_REQ operation: aReqOp];	
		
	return request;	
}

/*
 * getNewCleanDataRequest
 */
- (REQUEST) getNewCleanDataRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage
{		
	REQUEST request;

	printd("G2TelesupParser - getNewCleanDataRequest\n");

	request = [CleanDataRequest new];
	[request setFreeAfterExecute: TRUE];

	[self configureRequest: request type: GET_REQUEST_TYPE operation: aReqOp];
	
	/* Los modificadores */			
	if ([self isValidParam: aMessage name: "CleanAudits"])
		[request setCleanAudits: [self getParamAsBoolean: aMessage paramName: "CleanAudits"]];

	if ([self isValidParam: aMessage name: "CleanTickets"])
		[request setCleanTickets: [self getParamAsBoolean: aMessage paramName: "CleanTickets"]];

	if ([self isValidParam: aMessage name: "CleanCashRegister"])
		[request setCleanCashRegister: [self getParamAsBoolean: aMessage paramName: "CleanCashRegister"]];

									
	return request;
}

/*
 * getNewRestartSystemRequest
 */
- (REQUEST) getNewRestartSystemRequest:  (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage
{		
	REQUEST request;

	printd("G2TelesupParser - getNewRestartSystemRequest\n");

	request = [RestartSystemRequest new];
	[request setFreeAfterExecute: TRUE];

	[self configureRequest: request type: GET_REQUEST_TYPE operation: aReqOp];
	
	/* Los modificadores */			
	if ([self isValidParam: aMessage name: "Force"])
		[request setForceReboot: [self getParamAsBoolean: aMessage paramName: "Force"]];

	return request;
};

/**/
- (REQUEST) getNewG2Request: (ENTITY_REQUEST_OPS) aReqOp msg: (char*) aMessage reqType: (int) aReqType
{
  REQUEST request = NULL;

  //printd("G2TelesupParser - getNewG2Request\n");
  
  switch (aReqOp) {
  
    case NO_REQ_OP:
    case LIST_REQ_OP:
      request = [GenericGetRequest getInstance];
			[request setTelesupRol: myTelesupRol];
      break;
      
    case ACTIVATE_REQ_OP:
    case DEACTIVATE_REQ_OP:
    case ADD_REQ_OP:
    case REMOVE_REQ_OP:
    case SETTINGS_REQ_OP:

			if (aReqType == SET_USER_REQ) {
				if (![[CommercialStateMgr getInstance] canExecuteModule: ModuleCode_USER_SETTINGS executionMode: myExecutionMode]) 
					 THROW(MODULE_CANNOT_BE_EXECUTED_EX);
								
					
			} else {
				if ( (aReqType != SET_REGIONAL_SETTINGS_REQ) && (aReqType != SET_DATETIME_REQ)  && (![[CommercialStateMgr getInstance] canExecuteModule: ModuleCode_SETTINGS executionMode: myExecutionMode])) 
					THROW(MODULE_CANNOT_BE_EXECUTED_EX);
								
			}
		
      request = [GenericSetRequest getInstance];
			[request setTelesupRol: myTelesupRol];
      break;
  
    default:
      /* tirar una excepcion */
      request = NULL; 
  }
  
  assert(request);
    
  /************************/
  /*  aca deberia llamar a [self configureRequest: bla bla] para configurar el tipo y que si el tipo
   de request es de SET hace un asignRestoreInfo que no esta contemplado aun en el refactoring*/
  /************************/

  [request setReqOperation: aReqOp];
  [request loadPackage: aMessage];

  return request;
}

/**********************************************************************************************
	PIMS
 **********************************************************************************************/

/* PimsRequest */
- (REQUEST) getNewPimsRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage
{
	REQUEST request = NULL;

	/* Crea el Request */
	request = [PimsRequest getInstance];
	[request setMessage: aMessage];
  [request setReqOperation: aReqOp];
	[request setViewer: myViewer];

	return request;
}

/**/
- (REQUEST) getNewSystemOpRequest: (ENTITY_REQUEST_OPS) aReqOp msg: (char *) aMessage
{

    printf("Crea el systemOpRequest\n");
	// Crea el Request 
	
    if (mySystemOpRequest == NULL) 
        mySystemOpRequest = [SystemOpRequest new];
    
	[mySystemOpRequest setMessage: aMessage];
    [mySystemOpRequest setReqOperation: aReqOp];
	[mySystemOpRequest setEventsProxy: myEventsProxy];

	return mySystemOpRequest;
}


/**/
- (void) setViewer: (id) aViewer
{
	myViewer = aViewer;
}

/**/
- (void) setExecutionMode: (int) aValue
{
	myExecutionMode = aValue;
}

/**/
- (void) setEventsProxy: (id) anEventsProxy
{
	myEventsProxy = anEventsProxy;
}

/**/
- (id) getEventsProxy
{
	return myEventsProxy;
}

@end

