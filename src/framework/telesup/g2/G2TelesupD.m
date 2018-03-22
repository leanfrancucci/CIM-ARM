#include <string.h>
#include <ctype.h>
#include "MessageHandler.h"
#include "system/io/all.h"
#include "system/net/all.h"
#include "system/util/all.h"
#include "TelesupFacade.h"
#include "settings/SettingsExcepts.h"
#include "G2TelesupD.h"
#include "G2RemoteProxy.h"
#include "G2TelesupParser.h"
#include "Audit.h"
#include "Event.h"
#include "CimGeneralSettings.h"

//#define printd(args...) //doLog(0,args)
#define printd(args...) 

   
    
/**/
@implementation G2TelesupD

/**/
- initialize
{	

	[super initialize];	
	myCurrentMsg = malloc(TELESUP_MSG_SIZE+1);
	assert(myCurrentMsg);

	myIamInAJob = FALSE;
	
	myExecutePICProtocol = TRUE;
	
  myDmodemProto = [DModemProto new];
	return self;
}

/**/
- free
{
	if (myCurrentJob != NULL)
		[myCurrentJob free];
	
	if (myActivePIC != NULL)
		[myActivePIC free];		 

	if (myCurrentMsg != NULL)
		free(myCurrentMsg);
		
  if (myDmodemProto != NULL)	
	 free(myDmodemProto);
	return [super free];
}

/**/
- (void) setActivePIC: (G2_ACTIVE_PIC) anActivePIC { myActivePIC = anActivePIC; }
- (G2_ACTIVE_PIC) getActivePIC { return myActivePIC; }

/**/
- (void) setExecutePICProtocol: (BOOL) aValue { myExecutePICProtocol = aValue; }
- (BOOL) isExecutePICProtocol { return myExecutePICProtocol; }

/**/
- (int) getSupervisionErrorCode: (char*) aMessage
{
	return [myTelesupParser getParamAsInteger: aMessage paramName: "Code"];
}

/**/
- (void) run
{
	REQUEST request;	
	BOOL telesupHaltError;
	BOOL sendTelesupError;
	char exceptionDescription[512];
	int excode;
	TELESUP_FACADE facade = [TelesupFacade getInstance];


	/**/
	assert(myTelesupErrorMgr);	
	assert(myActivePIC);	
	
	/**/
	[myActivePIC setTelcoType: [facade getTelesupParamAsInteger: "TelcoType" telesupRol: myTelesupRol]];
	[myActivePIC setReader: myRemoteReader];
	[myActivePIC setWriter: myRemoteWriter];	
	
	myIamInAJob = FALSE;
	
	/**/
	[self startTelesup];

	msleep(100);
	

	/**/
	TRY 		
		
		if ([myActivePIC getConnectionType] == 1){ /*DMODEM*/
		  [myDmodemProto open];
		  [myDmodemProto connect];		  
		}
		/* Ejecuta el PIC */
		if (myExecutePICProtocol) {
			//doLog(0,"G2TelesupD: Ejecutando PIC...\n");
			[myActivePIC executeProtocol];
		}
		/* Ejecuta el proceso de login */	
		if (myExecuteLoginProcess) {
			//doLog(0,"G2TelesupD: Ejecutando Login...\n");
			[self login];
		}
			
	CATCH
		
		ex_printfmt();
        myErrorCode = ex_get_code();    
		[self stopTelesup];		
		//	RETHROW();
		return;
			
	END_TRY;

	/**/
	telesupHaltError = 0;
	myJobError = FALSE;

	while (myIsRunning) {

		TRY

			/* Lee el mensaje  */
			[self readMessage: myCurrentMsg qty: TELESUP_MSG_SIZE - 1];

			//doLog(0,"Message \n %s \n", myCurrentMsg);

			/* Controla que sea o no un mensaje de fin de telesupervision */
			if ([self isLogoutMessage: myCurrentMsg]) 
				BREAK_TRY;
			
			/* Obtiene el Request correspondiente */			
			request = [self getRequestFrom: myCurrentMsg];

			/* Procesa el request */	
			[self processRequest: request];	

			/** @todo agregar un bloque finally */
			/*  Libera el Request creado */
			if ([request getFreeAfterExecute]) [request free];
			else [request clear];

		CATCH
		
			/* Imprime la excepcion */
			ex_printfmt();
			excode = ex_get_code();
			myErrorCode = excode;			
			/* Si estoy en un job y da error entonces debe quedarse en estado de recibir todos los request
			   del job y descartarlos hasta recibir el request que haga el Commit del Job*/
			if (myIamInAJob) 
				myJobError = TRUE;				
			sendTelesupError = TRUE;
			/* Si da un error la transferencia de archivos sigue con la telesupervision
			   Podria auditar la situacion nomas
			*/
			EXCEPTION				( FT_FILE_TRANSFER_ERROR )	sendTelesupError = FALSE;			
			else EXCEPTION_GROUP	( IO_EXCEPT ) 				telesupHaltError = TRUE;
			else EXCEPTION_GROUP	( NET_EXCEPT ) 				telesupHaltError = TRUE;
			else EXCEPTION			( TSUP_GENERAL_EX ) 		telesupHaltError = TRUE;

			/**/
			//doLog(0,"G2TelesupD: Ha ocurrido una excepcion en el hilo de la telesupervision (halt=%d)\n", telesupHaltError);
			/* Error grave */
			if (telesupHaltError) {	
				ex_printfmt();
				break;
			}

			/* Envia el mensaje de error */
			if (sendTelesupError) {
				// Traduzco el codigo de error a mensaje
				TRY
					[[MessageHandler getInstance] processMessage: exceptionDescription
																				messageNumber: excode];
				CATCH
					strcpy(exceptionDescription, "");
				END_TRY
                    
				[myRemoteProxy sendErrorRequestMessage: [myTelesupErrorMgr getErrorCode: excode] description: exceptionDescription];
			}
			myErrorCode	= 0;
				
		END_TRY

	}
	
	/**/
	if (!telesupHaltError)
		[self logout];
	
	/**/
	[self stopTelesup];

	printf("G2TelesupD: Saliendo de la telesupervision!\n");	

}


/**/
- (void) processRequest: (REQUEST) aRequest
{
	
	printd("G2TelesupD: processRequest()\n");

	/* Si es un Request de tipo Job o Request normales */
	switch ([aRequest getReqType]) {
	
		/**/
		case START_JOB_REQ:	
//			[self startTelesupJob: [aRequest getReqInitialVigencyDate]];
			
			break;
			
		/**/
		case COMMIT_JOB_REQ:				
//			[self commitTelesupJob];
			
			break;

		/**/
		case ROLLBACK_JOB_REQ:
			[self rollbackTelesupJob];			
			break;

		/**/
		default:				
			
			/* Si esta dentro de un Job pero el Request no puede ser 
			aceptado dentro de un Job lanza una excepcion*/		
			if (myIamInAJob && ![aRequest isJobable])
				THROW( TS_INVALID_JOB_REQUEST_EX );
		
			/**/	
//			[aRequest setReqInitialVigencyDate: [myCurrentJob getInitialVigencyDate]];

		
			/* Procesamiento diferido: Graba el mensaje y envia un mensaje de exito  */
			if (myIamInAJob) {

				/* si esta en un job que dio error descarta el request si no lo graba */
				if (!myJobError) {
					
					//doLog(0,"Agrega el Request al Job\n");
					//[myCurrentJob addRequest: aRequest];
					
				} else {
				
					// descarta el Request
					//doLog(0,"Descarta el Request\n");
					
				}
				
				/* Envia el mensaje de aceptacion */
				[myRemoteProxy sendAckMessage];
				
			} else { 
		
//				doLog(0,"Procesa el Request\n");
				/* no esta en un job asi que lo procesa directamente */
				[super processRequest: aRequest];
			}
			
			break;			
	}			
};


/**/
#if 0
- (void) startTelesupJob: (DATETIME) anInitialVigencyDate
{
	assert(myCurrentJob != NULL);

	if (myIamInAJob)
		THROW( TS_JOB_RUNNING_EX );	

	myJobError = FALSE;
	myIamInAJob = TRUE;
	
	[myCurrentJob setTelesupId: myTelesupId];
	[myCurrentJob setTelesupRol: myTelesupRol];
		
	[myCurrentJob startTelesupJobAt: anInitialVigencyDate];
	
	/**/
	[myRemoteProxy sendAckMessage];
}

/**/
- (void) commitTelesupJob
{
	assert(myCurrentJob != NULL);
	
	if (!myIamInAJob)
		THROW( TS_JOB_NOT_RUNNING_EX );	
	
	/**/
	TRY
	
		/**/
		if (!myJobError) {
		
			/* El commit almacena los request y solo los ejecuta si no tiene fecha de vigencia */
			[myCurrentJob commitTelesupJob];	
	
			/* Recibio el job con exito*/	
			[myRemoteProxy sendAckMessage];

			/* Si el job no trae fecha de vigencia inicial entonces lo ejecuta */
			if ([myCurrentJob hasToExecute])
				[self executeTelesupJob];
				
		} else {
					
			/**/
			[myRemoteProxy sendErrorRequestMessage: [myTelesupErrorMgr getErrorCode: TS_INVALID_JOB_REQUEST_EX] description: ""];
			[myCurrentJob rollbackTelesupJob];
		}		
		
	FINALLY

		/**/
		myJobError = FALSE;
		myIamInAJob = FALSE;			
		[myCurrentJob clear];
		
	END_TRY;		

}

/**/
- (void) rollbackTelesupJob
{
	assert(myCurrentJob != NULL);

	if (!myIamInAJob)
		THROW( TS_JOB_NOT_RUNNING_EX );	

	[myCurrentJob rollbackTelesupJob];	
	
	myJobError = FALSE;
	myIamInAJob = FALSE;	
	[myCurrentJob clear];
	
	[myRemoteProxy sendAckMessage];
}

/**/
- (void) executeTelesupJob
{
	assert(myCurrentJob != NULL);

	[myCurrentJob executeTelesupJob];
}

#endif

/**/
- (void) login
{
	if (myIsActiveLogger) { 
		
		[self loginMe];			
		[self loginHim];		
			
	} else {

		[self loginHim];
		[self loginMe];	

	}

	/* Configura el parser */	
	[myTelesupParser setSystemId: [self getSystemId]];
	[myTelesupParser setTelesupRol: [self getTelesupRol]];
}

		
/**/
- (void) logout
{
	[myRemoteProxy sendAckMessage];
};

/**/
- (void) loginMe
{
	char buffer[50];
	/*
		Login 		---->
		Ok			<---- 
	*/
	TELESUP_FACADE facade = [TelesupFacade getInstance];
	int supErrorCode;
	char additional[20];

	assert(myRemoteProxy);

	/**/
	if (myTelesupRol == 0)
		THROW( TSUP_BAD_LOGIN_EX );
		
	/* Envia el mensaje de login */
	[myRemoteProxy newMessage: "Login"];		
	
	/**/
	[self setSystemId:  [facade getTelesupParamAsString: "SystemId" telesupRol: myTelesupRol]];
	
	[myRemoteProxy addParamAsString: "SystemId" value: mySystemId];	
	[myRemoteProxy addParamAsString: "Username" 
			value: [facade getTelesupParamAsString: "Username" telesupRol: myTelesupRol]];
	[myRemoteProxy addParamAsString: "Password" 
			value: [facade getTelesupParamAsString: "Password" telesupRol: myTelesupRol]];
	[myRemoteProxy addParamAsString: "MacAddress" value: [[CimGeneralSettings getInstance] getMacAddress: buffer]];
	
	[myRemoteProxy sendMessage];
	
	/* espera el ok o error */
	[self readMessage: myCurrentMsg qty: TELESUP_MSG_SIZE - 1];
	
	/* Si recibe OK el sistema remoto nos identifico y autentico  */
	if (![myRemoteProxy isOkMessage: myCurrentMsg]) {
		
		//doLog(0,"G2TelesupD: myCurrentMsg = |%s|\n", myCurrentMsg);
		supErrorCode = [self getSupervisionErrorCode: myCurrentMsg];
		sprintf(additional, "%d", supErrorCode);
		[Audit auditEvent: TELESUP_LOGIN_ME_ERROR additional: "" station: 0 logRemoteSystem: FALSE];
	
		switch (supErrorCode) {
			
			case MAC_ADDRESS_ERROR: THROW( TSUP_MAC_ADDRESS_ERROR_EX );
			case DUPLICATED_MAC_ADDRESS: THROW( TSUP_DUPLICATED_MAC_ADDRESS_EX );
			case NOT_REGISTERED_EQ: THROW( TSUP_NOT_REGISTERED_EQ_EX );
			case LOGIN_INFO_ERROR: THROW( TSUP_LOGIN_INFO_ERROR_EX );
			case REMOTE_LOGIN_INFO_ERROR: THROW( TSUP_REMOTE_LOGIN_INFO_ERROR_EX );
			case EQ_TYPE_ERROR: THROW( TSUP_EQ_TYPE_ERROR_EX );
			case INACTIVE_EQ: THROW( TSUP_INACTIVE_EQ_EX );

			default: 	THROW( TSUP_BAD_LOGIN_EX );

		}

	}
}

/**/
- (void) loginHim
{ 	
	/*
		Login	<----
		Ok		---->   o   Error   ---->
	*/
	TELESUP_FACADE facade = [TelesupFacade getInstance];
	
	/* espera el Login */
	[self readMessage: myCurrentMsg qty: TELESUP_MSG_SIZE-1];
	  
	/* Si recibe OK entonces envia el login del sistema */
	if (![myRemoteProxy isLoginTelesupMessage: myCurrentMsg])
		THROW( TSUP_BAD_LOGIN_EX );
  
	/**/	
	[self setSystemId:  [facade getTelesupParamAsString: "SystemId" telesupRol: myTelesupRol]];
	  
	/**/	
	if ([myTelesupParser getParamAsString: myCurrentMsg paramName: "SystemId"] != NULL)
		stringcpy(myRemoteSystemId, [myTelesupParser getParamAsTrimString: myCurrentMsg paramName: "SystemId"]);
  	
	if ([myTelesupParser getParamAsString: myCurrentMsg paramName: "UserName"] != NULL)
		stringcpy(myRemoteUserName, [myTelesupParser getParamAsTrimString: myCurrentMsg paramName: "Username"]);
	  
	if ([myTelesupParser getParamAsString: myCurrentMsg paramName: "Password"] != NULL)
		stringcpy(myRemotePassword, [myTelesupParser getParamAsTrimString: myCurrentMsg paramName: "Password"]);
	  		
	/* valida el login */
	TRY
	  
    /*Si los datos del server estan vacios debo setearlos con los valores del mensaje*/
	  if (strcmp([facade getTelesupParamAsString: "RemoteSystemId" telesupRol: myTelesupRol],"")== 0){
      [facade setTelesupParamAsString: "RemoteUserName" value: myRemoteUserName telesupRol: myTelesupRol];
      [facade setTelesupParamAsString: "RemotePassword" value: myRemotePassword telesupRol: myTelesupRol];
      [facade setTelesupParamAsString: "RemoteSystemId" value: myRemoteSystemId telesupRol: myTelesupRol];
      [facade telesupApplyChanges:myTelesupRol];
    }	else
  		[self validateRemoteSystem];
		
	CATCH
	  	
		/* envia el mensaje de error  si corresponde */
		[Audit auditEvent: TELESUP_LOGIN_HIM_ERROR additional: "" station: 0 logRemoteSystem: FALSE];
		[myRemoteProxy sendErrorRequestMessage: 0 description: ""];
		RETHROW();
		
	END_TRY;
	  
	[myRemoteProxy sendAckMessage];
}
			
/**/
- (id) getDmodemProto
{
  return myDmodemProto;
}

@end
