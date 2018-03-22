#include "system/util/all.h"
#include "ROPPersistence.h"
#include "RequestDAO.h"
#include "TelesupFacade.h"
#include "TelesupD.h"
#include "MessageHandler.h"

#ifdef _WIN32
#include <signal.h>
#else
#include <sys/signal.h>
#endif

//#define printd(args...) 	doLog(0,args)
#define printd(args...) 	

	 
/**/
@implementation TelesupD

/**/
+ new
{
	return [[super new] initialize];

}

/**/
- free
{

	if (myTelesupErrorMgr != NULL) [myTelesupErrorMgr free];
	if (myTelesupParser != NULL) [myTelesupParser free];
	if (myRemoteProxy != NULL) [myRemoteProxy free];
	if (myInfoFormatter != NULL) [myInfoFormatter free];
/*	if (myRemoteReader) [myRemoteReader free];
	if (myRemoteWriter) [myRemoteWriter free];*/

	return [super free];
}

/**/
- initialize
{
	[super initialize];
	
	myTelesupErrorMgr = NULL;
	myRemoteReader = NULL;
	myRemoteWriter = NULL;
	myTelesupParser = NULL;
	myRemoteProxy = NULL;
	myInfoFormatter = NULL;
	myTelesupViewer = NULL;

	myIsRunning = 0;
	myTelesupRol = 0;	
	myTelesupId	= 0;
	myExecuteLoginProcess = TRUE;
	[self setSystemId: "ABC-123"];
	return self;
}


/**/
- (void) setTelesupId: (int) aTelesupId { myTelesupId = aTelesupId;  };
- (int) getTelesupId { return myTelesupId; }

/**/
- (void) setExecuteLoginProcess: (BOOL) aValue { myExecuteLoginProcess = aValue; } 
- (BOOL) getExecuteLoginProcess { return myExecuteLoginProcess; } 

/**/
- (void) setTelesupErrorManager: (TELESUP_ERROR_MANAGER) aTelesupErrorMgr { myTelesupErrorMgr = aTelesupErrorMgr; }	
- (TELESUP_ERROR_MANAGER) getTelesupErrorManager { return myTelesupErrorMgr; }

/**/
- (void) setTelesupViewer: (TELESUP_VIEWER) aTelesupViewer { myTelesupViewer = aTelesupViewer;  }
- (TELESUP_VIEWER) getTelesupViewer { return myTelesupViewer; }

/**/
- (void) setSystemId: (char *) aSystemId { stringcpy(mySystemId, aSystemId); }
- (char *) getSystemId { return mySystemId; };

/**/
- (void) setTelesupRol: (int) aTelesupRol  { myTelesupRol = aTelesupRol; }
- (int) getTelesupRol { return myTelesupRol; }


/**/
- (void) setRemoteReader: (READER) aRemoteReader { 	myRemoteReader = aRemoteReader; }

/**/
- (void) setRemoteWriter: (WRITER) aRemoteWriter { 	myRemoteWriter = aRemoteWriter; }


/**/
- (void) setTelesupParser: (TELESUP_PARSER) aTelesupParser { myTelesupParser = aTelesupParser; }
- (TELESUP_PARSER) getTelesupParser { return myTelesupParser; }


/**/
- (void) setRemoteProxy: (REMOTE_PROXY) aRemoteProxy {	myRemoteProxy = aRemoteProxy; }
- (REMOTE_PROXY) getRemoteProxy { return myRemoteProxy; }

/**/
- (void) setInfoFormatter: (INFO_FORMATTER) anInfoFormatter { myInfoFormatter = anInfoFormatter; }
- (INFO_FORMATTER) getInfoFormatter { return myInfoFormatter; }

/**/
- (void) run
{
	THROW( ABSTRACT_METHOD_EX );
};

/**/
- (int) readMessage: (char *) aBuffer qty: (int) aQty
{
	assert(myRemoteProxy);
	assert(myTelesupParser);
	assert(aBuffer);	
	
	/**/
	if (aQty > TELESUP_MSG_SIZE)
		THROW( TSUP_MSG_TOO_LARGE_EX );
		
	/* lee el mensaje del proxy */
	return [myRemoteProxy readTelesupMessage: aBuffer qty: aQty];
}			
			
/**/
- (BOOL) isLogoutMessage: (char *) aMessage
{
	assert(myTelesupParser);
	
	return [myRemoteProxy isLogoutTelesupMessage: aMessage];
}
			
/**/
- (REQUEST) getRequestFrom: (char *) aMessage
{
	REQUEST request;
	 
	assert(myTelesupParser);
	assert(myTelesupViewer);
	
	/* Obtiene el request */
	request = [myTelesupParser getRequest: aMessage];
		
	/* Configura datos basicos */	
	[self configRequest: request];

	[myTelesupViewer updateText: getResourceStringDef(RESID_RECEIVING_REQUEST_WAIT, "Recibiendo solicitudes, aguarde....")];
	
	return request;		
}
			

/**/
- (void) configRequest: (REQUEST) aRequest
{
	assert(myRemoteProxy);
	assert(myInfoFormatter);
	
	[aRequest setReqTelesupId: myTelesupId];
	[aRequest setTelesupErrorManager: myTelesupErrorMgr];	
	[aRequest setReqTelesupRol: myTelesupRol];	
	[aRequest setReqRemoteProxy: myRemoteProxy];	
	[aRequest setReqInfoFormatter: myInfoFormatter];
}
			
/**/
- (void) processRequest: (REQUEST) aRequest
{	
	assert(myTelesupErrorMgr);
	
	printd("TelesupD.processRequest()\n");

	TRY	
		[self configRequest: aRequest];
		/* Procesa el Request */		
		[aRequest processRequest];	
		/* Se ejecuto con exito */
		[aRequest requestExecuted];
	CATCH

		/* Fallo la ejecucion */
		[aRequest requestFailedWithErrorCode: [myTelesupErrorMgr getErrorCode: ex_get_code()]];
		RETHROW();
		
	END_TRY;	
}
				
			
/**/
- (void) saveRequest: (REQUEST) aRequest
{
	assert(aRequest != NULL);
	[aRequest saveRequest];
};


/**/
- (BOOL) isRunning
{
	return myIsRunning;
}

/**/										
- (void) setIsActiveLogger: (BOOL) anIsActiveLogger { myIsActiveLogger = anIsActiveLogger; }
- (BOOL) isActiveLogger { return myIsActiveLogger; }


/**/
- (void) startTelesup
{
	assert(myTelesupViewer);
	assert(myTelesupErrorMgr);
	assert(myRemoteReader);
	assert(myRemoteWriter);
	assert(myTelesupParser);
	assert(myRemoteProxy);
	assert(myInfoFormatter);	

	/* Ignora estas senales */
#ifndef _WIN32
//	doLog(0,"Registrando: ignorar SIGPIPE y SIGCLD signals!\n");
	signal(SIGPIPE, SIG_IGN);
    signal(SIGCLD, SIG_IGN);
#endif

	if (myTelesupId == 0)		
		THROW( TSUP_INVALID_TELESUP_ID_EX );
			
	if (myTelesupRol == 0)	
		THROW( TSUP_INVALID_TELESUP_ROL_EX );
	
	/**/
	myIsRunning = 1;
	myErrorCode = 0;
	[myRemoteProxy setTelesupViewer: myTelesupViewer];	
}

/**/
- (void) stopTelesup
{
	assert(myTelesupViewer);
	
	myIsRunning = 0;
	
	/* Detiene el thread */
	
	/* esto no es necesario. De hecho, si hago un stop lanza un error */
//	[self stop];

//	[myTelesupViewer finish];
}

/**/
- (void) validateRemoteSystem
{
/*	
	doLog(0,"\nTelesupD:validateRemoteSystem() -> Le comente la validacion del sistema remoto!!!!\n");
	return;
*/	
	
	TELESUP_FACADE facade = [TelesupFacade getInstance];

	
	/*
	doLog(0,"myTelesupRol=%d, \"%s\"=\"%s\"? , \"%s\"=\"%s\"?  %d  %d\n\n ", 
				myTelesupRol, 
				myRemoteUserName, 
				[facade getTelesupParamAsString: "RemoteUserName" telesupRol: myTelesupRol],
				myRemotePassword,
				[facade getTelesupParamAsString: "RemotePassword" telesupRol: myTelesupRol]);
	*/			
	
	
	if (strcmp([facade getTelesupParamAsString: "RemoteUserName" telesupRol: myTelesupRol], myRemoteUserName) != 0 || 
		strcmp([facade getTelesupParamAsString: "RemotePassword" telesupRol: myTelesupRol], myRemotePassword) != 0 ||
    strcmp([facade getTelesupParamAsString: "RemoteSystemId" telesupRol: myTelesupRol], myRemoteSystemId) != 0)	
		THROW( TSUP_BAD_LOGIN_EX );
}
	
/**/
- (int) getErrorCode
{
	return myErrorCode;
}

/**/
- (void) setGetCurrentSettings: (BOOL) aValue
{
  myGetCurrentSettings = aValue;
}

@end
