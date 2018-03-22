#include <unistd.h>
#include "system/util/all.h"
#include "system/os/all.h"
#include "ReqTypes.h"
#include "SystemOpRequest.h"
#include "ResourceStringDefs.h"
#include "MessageHandler.h"
#include "G2RemoteProxy.h"
#include "CimExcepts.h" 
#include "SettingsExcepts.h"
#include "CimManager.h"
#include "UserManager.h"
#include "CtSystem.h"

#include "CimManager.h"
#include "UserManager.h"
#include "CashReferenceManager.h"
#include "UICimUtils.h"
#include "CimGeneralSettings.h"
#include "ExtractionController.h"
#include "AsyncMsgThread.h"


// Maximo tamanio de documento
/** @todo: ver si alcanza este tamnaio de archivo de preview en todos los casos */
#define PREVIEW_DOC_SIZE	65535

@implementation SystemOpRequest

static SYSTEM_OP_REQUEST mySingleInstance = nil;
static  SYSTEM_OP_REQUEST myRestoreSingleInstance = nil;

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
	myResponsePackage = [GenericPackage new];
	myCommandPackage = [GenericPackage new];
	myEventsProxy = NULL;
	myResponseBuffer = malloc(MSG_SIZE + 1);
    myMutex = [OMutex new];
    
    //[[AsyncMsgThread getInstance] setSystemOpRequest: self];

    return self;
}

/**/
- free
{
    [myPackage free];
	return [super free];
   	[myResponsePackage free]; 
    /*
	// Esta objeto observa a otro, remuevo las dependencias
	[self removeObserverFromControllers];

	// Finaliza la operacion actual de la consola (si es que existe una)
	//[[CimManager getInstance] finishCurrentConsoleOperation];

	// Libero el buffer que se utiliza para el preview
	if (myPreviewDoc != NULL) free(myPreviewDoc);
*/
    [myMutex lock];
	
	[myResponsePackage free];
	[myCommandPackage free];
	free(myResponseBuffer);
	[myMutex unLock];
	[myMutex free];

 
}

/**/
- (void) setMessage: (char *)aMessage
{
    doLog(0,"SET MESSAGE LOAD PACKAGE = %s\n", aMessage);
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

/**/
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
- (void) sendPackage
{
  
	char *msg = [myCommandPackage toString];

	[myMutex lock];
	TRY
        printf("systemoprequest message--> %s", msg);
        if (myEventsProxy == NULL) printf("myEventsProxy null");
        else printf("myEventsProxy not null");
 		[myEventsProxy sendMessage: msg qty: strlen(msg)];
		[self readResponse];

	FINALLY
		[myMutex unLock];
	//	[myCommandPackage unLock];
	END_TRY

}

/**/
- (void) sendPackage: (GENERIC_PACKAGE) aPkg
{
 	char *msg = [aPkg toString];

	[myMutex lock];

	TRY
//		LOG_DEBUG( LOG_TELESUP, "--> %s", msg);
 		[myEventsProxy sendMessage: msg qty: strlen(msg)];
		[self readResponse];
	//	LOG_DEBUG( LOG_TELESUP, "<-- %s", [myResponsePackage toString]);

	FINALLY
		[myMutex unLock];
	END_TRY
	
	[aPkg free];
    
}

/**/
- (void) setEventsProxy: (id) anEventsProxy
{
	myEventsProxy = anEventsProxy;
}

/**/
- (void) readResponse
{
    TRY
        [myEventsProxy readTelesupMessage: myResponseBuffer qty: MSG_SIZE];
        [myResponsePackage loadPackage: myResponseBuffer];
    CATCH
        
        doLog(0,"[ ERROR ]\n");fflush(stdout);
		ex_printfmt();
    END_TRY
    
}

- (void) userChangePin
{
    int userId;
    char oldPass[16];
    char newPass[16];
    char newDuress[16];
    USER aUser;
    int excode = 0;
    char exceptionDescription[512];

    printf("userChangePin executed \n");
    
	if ([myPackage isValidParam: "UserId"]) {
        userId = [myPackage getParamAsInteger: "UserId"];

        if ([myPackage isValidParam: "OldPassword"]) 
              stringcpy(oldPass, [myPackage getParamAsString: "OldPassword"]);
        if ([myPackage isValidParam: "NewPassword"]) 
              stringcpy(newPass, [myPackage getParamAsString: "NewPassword"]);
        if ([myPackage isValidParam: "NewDuressPassword"]) 
              stringcpy(newDuress, [myPackage getParamAsString: "NewDuressPassword"]);
        
    }
    
    printf("userChangePin oldPass %s newPass %s duressPass %s\n", oldPass, newPass, newDuress);
    
    TRY
    
        aUser = [[UserManager getInstance] getUser: userId];
        printf("userChangePin after getting user \n");

        assert(aUser != NULL);

    // valido que la password no sea vacia
        if (strlen(newPass) == 0) 
            THROW(DAO_NULL_PIN_EX);
    

        // el control de duress password lo hago solo si el perfil del usuario usa duress
        if ([[aUser getProfile] getUseDuressPassword]) {

            // valido que la duress password no sea vacia
            if (strlen(newDuress) == 0) 
                THROW(DAO_NULL_DURESS_PIN_EX);


            // valido que la nueva password sea distinta a la nueva clave de robo
            if (strcmp(newPass, newDuress) == 0) 
                THROW(RESID_EQUALS_PASSWORDS);  
        }
  
        // valido que la nueva password sea distinta a la anterior
        if (strcmp(newPass, oldPass) == 0) 
            THROW(RESID_EQUAL_PASSWORD);
  

        // Password
        [aUser setPassword: newPass];

        // DuressPassword
        [aUser setDuressPassword: newDuress];

        // Actualizo la fecha de cambio de password
        [aUser setLastChangePasswordDateTime: [SystemTime getLocalTime]];
	
        // Actualizo la clave temporaria
        [aUser setIsTemporaryPassword: FALSE];
        
        
        // Graba el usuario
        [aUser applyPinChanges: oldPass];
        
        printf("userChangePin after applychanges\n");
        [myRemoteProxy sendAckMessage];
        printf("userChangePin after senackmessage \n");
       
        
    CATCH

        ex_printfmt();
        excode = ex_get_code();

    
        TRY
                [[MessageHandler getInstance] processMessage: exceptionDescription messageNumber: excode];
        CATCH
                 strcpy(exceptionDescription, "");
        END_TRY
        
       printf("userChangePin inside catch excode %d\n",excode);

        if (excode != 0) {

            [myRemoteProxy newMessage: "Error"];
            [myRemoteProxy addParamAsInteger: "Code" value: excode];
            [myRemoteProxy addParamAsString: "Description" value: exceptionDescription];
            [myRemoteProxy appendTimestamp];
            [myRemoteProxy sendMessage];
        
        }

    END_TRY
}

static int loginFailQty = 0;


/**/
- (void) userLogin
{
	char userName[50];
	char userPassword[50];
	volatile unsigned long userId = 0;
	COLLECTION dallasKeys = [Collection new];
    BOOL mustChangePin = FALSE;
    int excode = 0;
    char exceptionDescription[512];
    int blockTime = 0;
    int pinLife = 0;
	SecurityLevel secLevel;


	if ([myPackage isValidParam: "UserName"]) {
		stringcpy(userName, [myPackage getParamAsString: "UserName"]);
    } 

	if ([myPackage isValidParam: "UserPassword"])
		stringcpy(userPassword, [myPackage getParamAsString: "UserPassword"]);
		
	TRY
		userId = [[UserManager getInstance] logInUser: userName password: userPassword dallasKeys: dallasKeys];
        
        // analisis de expiracion de password
        
        user = [[UserManager getInstance] getUser: userId];

        
        secLevel = [[[UserManager getInstance] getProfile: [user getUProfileId]] getSecurityLevel];

        // verifico si debe cambiar el PIN de usuario
        //puede haber 3 motivos: 1. si su clave es temporal.
        //                       2. si expiro el pinLife
        //                       3. si su clave no tiene la longitud minima especificada (esto solo se verifica si el nivel de seguridad es != de 0)
        // este control solo se aplica si el nivel de seguridad del usuario logueado es != 0

        if (secLevel != SecurityLevel_0) {

            pinLife = [[CimGeneralSettings getInstance] getPinLife];
            
            if ( [user isPinRequired] && ([user isTemporaryPassword] || (pinLife > 0) || (strlen([user getRealPassword]) < [[CimGeneralSettings getInstance] getPinLenght]))) {
                
                    //traigo la fecha de ultimo login del usuario       
                if ( ([user isTemporaryPassword]) || ( ([SystemTime getLocalTime] - [user getLastChangePasswordDateTime]) >= (pinLife * 86400)) || (strlen([user getRealPassword]) < [[CimGeneralSettings getInstance] getPinLenght]) ) {
				
                    mustChangePin = TRUE;
                    [[UserManager getInstance] logOffUser: [user getUserId]];
			}
          }
        
        }
        
        
        [myRemoteProxy newResponseMessage];
        [myRemoteProxy addParamAsInteger: "UserId" value: userId];
        [myRemoteProxy addParamAsBoolean: "Expired" value: mustChangePin];
        [myRemoteProxy addParamAsBoolean: "UseDuressPassword" value: [[user getProfile] getUseDuressPassword]];
        [myRemoteProxy sendMessage];
        
        
        
	CATCH
	
        
        ex_printfmt();
        excode = ex_get_code();

		[dallasKeys freeContents];		
		[dallasKeys free];		
        
        ++loginFailQty;
        
        if (loginFailQty > 2) {
            blockTime = [[CimGeneralSettings getInstance] getLockLoginTime];
            excode = 390075;
            stringcpy(exceptionDescription, "Maxima cantidad de login fails!"); 
            loginFailQty = 0;
        } else {
        
            TRY
                        [[MessageHandler getInstance] processMessage: exceptionDescription messageNumber: excode];
            CATCH
                        strcpy(exceptionDescription, "");
            END_TRY
        }
        
        
        if (excode != 0) {

            [myRemoteProxy newMessage: "Error"];
            [myRemoteProxy addParamAsInteger: "Code" value: excode];
            [myRemoteProxy addParamAsString: "Description" value: exceptionDescription];
            [myRemoteProxy addParamAsInteger: "BlockTime" value: blockTime];
            [myRemoteProxy appendTimestamp];
            [myRemoteProxy sendMessage];
        
        }
        
	END_TRY

}

/**/
- (void) userLogout
{
    char buffer[200 ];
    id user = NULL;
    
    user = [[UserManager getInstance] getUserLoggedIn];
    if (user != NULL) {
        
        printf("userLogout\n");
        
        buffer[0] = '\0';
        sprintf(buffer, "%s-%s",[user getLoginName], [user getFullName]);
        [Audit auditEventCurrentUser: Event_LOGOUT_USER additional: buffer station: 0 logRemoteSystem: FALSE];
  	  
        [[UserManager getInstance] logOffUser: [user getUserId]];
        
    }

    [myRemoteProxy sendAckMessage];
}

/**/
- (void) startValidatedDrop
{
    //id user;
    // esto deberia ir en otra clase
    
	int cashId = 0;
    int referenceId = 0;
    volatile unsigned long userId = 0;
	char envelopeNumber[50];
	char applyTo[50];
    int excode = 0;
    char exceptionDescription[512];
    CIM_CASH cimCash; 
    CASH_REFERENCE cashReference; 
   	*envelopeNumber = '\0';
	*applyTo = '\0';

    printf("StartValidatedDrop\n");    

    TRY

        if ([SafeBoxHAL getHardwareSystemStatus] == HardwareSystemStatus_SECONDARY) 
            THROW(RESID_ERROR_PRIMARY_HARD);
	

        if ([SafeBoxHAL getPowerStatus] == PowerStatus_BACKUP) 
             THROW(RESID_ERROR_POWER_DOWN);

        printf("StartValidatedDrop1\n");    

        if ([myPackage isValidParam: "UserId"]) 
            userId = [myPackage getParamAsInteger: "UserId"];
         
        if ([myPackage isValidParam: "ApplyTo"])
            stringcpy(applyTo, [myPackage getParamAsString: "ApplyTo"]);

        if ([myPackage isValidParam: "CashId"])
            cashId = [myPackage getParamAsInteger: "CashId"];
    
        if ([myPackage isValidParam: "ReferenceId"])
            referenceId = [myPackage getParamAsInteger: "ReferenceId"];
    

        printf("StartValidatedDrop UserId> %d\n", userId);    
		
        // analisis de expiracion de password
        
        user = [[UserManager getInstance] getUser: userId];

        // se asume que hay un cash validado creado
        cimCash = [[CimManager getInstance] getCimCashById: cashId];

        // controlo que la puerta este habilitada
        if ([[cimCash getDoor] isDeleted]) 
            THROW(RESID_DISABLE_DOOR);    

        // controlo que la puerta este cerrada
        if ([[cimCash getDoor] getDoorState] == DoorState_OPEN) 
             THROW(RESID_YOU_MUST_CLOSE_VALIDATED_DOOR);    

        // El Cash ya se esta utilizando para un Extended Drop
        if ([[CimManager getInstance] getExtendedDrop: cimCash] != NULL) 
            THROW(RESID_CASH_ALREADY_USE_EXTENDED);

        [[CimManager getInstance] checkCimCashState: cimCash];
        
        if (referenceId != 0)
            cashReference = [[CashReferenceManager getInstance] getCashReferenceById: referenceId];
        else cashReference = NULL;

    
        printf("SETEA EL OBSERVER\n");
        // Inicia el deposito
        [[CimManager getInstance] addObserver: self]; 
        printf("ARRANCA EL DEPOSITO\n");   
        
        /*
            Falta validar stacker full
         
         */
        myDeposit = [[CimManager getInstance] startDeposit: user cimCash: cimCash depositType: DepositType_AUTO];

        [myDeposit setCashReference: cashReference];
        [myDeposit setEnvelopeNumber: envelopeNumber];
        [myDeposit setApplyTo: applyTo];


        // audito el inicio del deposito validado
        [Audit auditEvent: [myDeposit getUser] eventId: Event_START_VALIDATED_DROP additional: "" station: 0 logRemoteSystem: FALSE];
    
        printf("SEND ACK MESSAGE\n");    
        
        
         [myRemoteProxy sendAckMessage];

        
	CATCH
	
        
        ex_printfmt();
        excode = ex_get_code();

            TRY
                        [[MessageHandler getInstance] processMessage: exceptionDescription messageNumber: excode];
            CATCH
                        strcpy(exceptionDescription, "");
            END_TRY
        
        
        if (excode != 0) {

            [myRemoteProxy newMessage: "Error"];
            [myRemoteProxy addParamAsInteger: "Code" value: excode];
            [myRemoteProxy addParamAsString: "Description" value: exceptionDescription];
            [myRemoteProxy appendTimestamp];
            [myRemoteProxy sendMessage];

            
        }

        
	END_TRY

    

}

- (void) endValidatedDrop
{
    doLog(0, "endValidatedDrop 1\n");
    [[CimManager getInstance] endDeposit];
    doLog(0, "endValidatedDrop 2\n");
 	[[CimManager getInstance] removeObserver: self];
    doLog(0, "endValidatedDrop 3\n");

	myDeposit = NULL;
    doLog(0, "endValidatedDrop 4\n");
    [myRemoteProxy sendAckMessage];
    doLog(0, "endValidatedDrop 5\n");
}

/**/
- (void) onOpenDeposit
{

}

/**/
- (void) onCloseDeposit
{

}

/**/
- (void) onBillAccepting: (ABSTRACT_ACCEPTOR) anAcceptor
{
    doLog(0, ">>>>>>>>>>>>>>>>>>>> SystemOpRequest  4\n");
}

/**/
- (void) onAcceptorError: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause
{
    doLog(0, ">>>>>>>>>>>>>>>>>>>> SystemOpRequest  3\n");
}


/**/
- (void) onBillRejected: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause  qty: (int) aQty
{
    doLog(0, ">>>>>>>>>>>>>>>>>>>> SystemOpRequest  1\n");
	
}
/**/
- (void) onBillAccepted: (ABSTRACT_ACCEPTOR) anAcceptor currency: (CURRENCY) aCurrency amount: (money_t) anAmount  qty: (int) aQty
{

    char amountstr[50];
	GENERIC_PACKAGE pkg;

    
    printf( ">>>>>>>>>>>>>>>>>>>> SystemOpRequest  onBillAccepted\n");
    
   	if (myDeposit == NULL) return;

    pkg = myCommandPackage;
	[pkg clear];
	[pkg setName: "BillAccepted"];
    [pkg addParamAsInteger: "AcceptorId" value: [[anAcceptor getAcceptorSettings] getAcceptorId]];
	[pkg addParamAsString: "State" value: getResourceStringDef(RESID_BILL_VERIFIED, "Bill Accepted!")];
	[pkg addParamAsString: "CurrencyCode" value: [aCurrency getCurrencyCode]];
	formatMoney(amountstr, "", anAmount * aQty, 2, 20);
    [pkg addParamAsString: "Amount" value: amountstr];
	[pkg addParamAsString: "DeviceName" value: [[anAcceptor getAcceptorSettings] str]];
    [pkg addParamAsInteger: "Qty" value: aQty];
    // la denominacion seria el amount dividido ADD_VEND_ITEM_BY_QTY_REQ
    [self sendPackage];    
}

/**/
- (void) onInactivityWarning: (OTIMER) aTimer { 
    
    doLog(0, ">>>>>>>>>>>>>>>>>>>>>>>>>> onInactivityWarning\n");
    [[CimManager getInstance] needMoreTime];
}

/**/
- (void) onDoorStateChange: (int) aState period: (long) aPeriod
{
	GENERIC_PACKAGE pkg;
    char seconds[30];

    
	pkg = myCommandPackage;
	[pkg clear];
	[pkg setName: "DoorStateChange"];
	[pkg addParamAsInteger: "State" value: aState];
    [pkg addParamAsLong: "Period" value: aPeriod];
/*    if (aTimeLeft > 0) {
        sprintf(seconds, "%d", aTimeLeft); 
        [pkg addParamAsString: "TimeLeft" value: seconds];
    }
    */
/*    
    if (anIsBlocking == TRUE)
        [pkg addParamAsString: "Blocking" value: "True"];
    else
        [pkg addParamAsString: "Blocking" value: "False"];
    
*/
	[self sendPackage];
}


/*********************************************************************/
/*EXTRACTION*/
/*********************************************************************/

- (void) initExtractionProcess
{
    int doorId;
    id door;
    
    printf("SystemOpRequest->initExtractionProcess\n");
    
    if ([myPackage isValidParam: "DoorId"]) {
        doorId = [myPackage getParamAsInteger: "DoorId"];
        [[ExtractionController getInstance] setObserver: self];
        [[ExtractionController getInstance] initExtraction: doorId];
        [myRemoteProxy sendAckMessage];
    } else {/* TIRAR ERROR*/
 
        
    }
    
}

- (void) getDoorState
{
    int doorId;
    id door;
    int state;
    
    printf("SystemOpRequest->getDoorState\n");    
    
    if ([myPackage isValidParam: "DoorId"]) {
        doorId = [myPackage getParamAsInteger: "DoorId"];
        state = [[ExtractionController getInstance] getDoorState: doorId];
        
        [myRemoteProxy newMessage: "OK"];
        [myRemoteProxy addParamAsInteger: "State" value: state];
        [myRemoteProxy appendTimestamp];
        [myRemoteProxy sendMessage];        
        
    } else {/* TIRAR ERROR*/
 
        
    }    
}

/**/
- (void) setRemoveCash
{
    int doorId;
    BOOL removeCash;
    
    
    printf("SystemOpRequest->setRemoveCash\n");
    
     if ([myPackage isValidParam: "DoorId"]) {
        doorId = [myPackage getParamAsInteger: "DoorId"];
     }  else {/* TIRAR ERROR*/}

     
     if ([myPackage isValidParam: "RemoveCash"]) {
        removeCash = [myPackage getParamAsBoolean: "RemoveCash"];
        [[ExtractionController getInstance] setRemoveCash: removeCash];        
        [myRemoteProxy sendAckMessage];
     } else {/**/}
     
     

}

/**/
- (void) userLoginForDoorAcccess
{
    char userName[50];
    char userPassword[50];
    
    printf("SystemOpRequest->userLoginForDoorAcccess\n");    
    
    
    printf("1\n");
    if ([myPackage isValidParam: "UserName"]) {
        stringcpy(userName, [myPackage getParamAsString: "UserName"]);
    }  else {/* TIRAR ERROR*/}

    
    printf("2\n");
    if ([myPackage isValidParam: "UserPassword"]) {
        stringcpy(userPassword, [myPackage getParamAsString: "UserPassword"]);
    } else {/**/}

    printf("3\n");
    [[ExtractionController getInstance] userLoginForDoorAccess: userName userPassword: userPassword];
    printf("4\n");
    [myRemoteProxy sendAckMessage];

}

/**/
- (void) startDoorAccess
{
    int doorId;
    
     if ([myPackage isValidParam: "DoorId"]) {
        doorId = [myPackage getParamAsInteger: "DoorId"];
     }  else {/* TIRAR ERROR*/}


    [[ExtractionController getInstance] startDoorAccess: doorId];
    [myRemoteProxy sendAckMessage];

    
}

/**/
- (void) closeExtraction
{
    int doorId;
    
    
    printf("SystemOpRequest->closeDoor\n");    
    
     if ([myPackage isValidParam: "DoorId"]) {
        doorId = [myPackage getParamAsInteger: "DoorId"];
     }  else {/* TIRAR ERROR*/}

    [[ExtractionController getInstance] closeExtraction: doorId];
    [[ExtractionController getInstance] free];
    [myRemoteProxy sendAckMessage];

}

/**/
- (void) cancelDoorAccess
{
    int doorId;
    
     if ([myPackage isValidParam: "DoorId"]) {
        doorId = [myPackage getParamAsInteger: "DoorId"];
     }  else {/* TIRAR ERROR*/}


    [[ExtractionController getInstance] cancelDoorAccess: doorId];
    [myRemoteProxy sendAckMessage];

}

/**/
- (void) cancelTimeDelay
{
    int doorId;
    char usrName[50];
    char usrPassword[50];
    
     if ([myPackage isValidParam: "DoorId"]) {
        doorId = [myPackage getParamAsInteger: "DoorId"];
     }  else {/* TIRAR ERROR*/}

     if ([myPackage isValidParam: "UserName"]) {
         stringcpy(usrName, [myPackage getParamAsString: "UserName"]);
     }  else {/* TIRAR ERROR*/}

     if ([myPackage isValidParam: "UserPassword"]) {
        stringcpy(usrPassword, [myPackage getParamAsString: "UserPassword"]);
     }  else {/* TIRAR ERROR*/}

    [[ExtractionController getInstance] cancelTimeDelay: doorId userName: usrName userPassword: usrPassword];
    [myRemoteProxy sendAckMessage];

}




/*********************************************************************/
/*MENSAJES ASINCRONICOS*/
/*********************************************************************/
- (void) onAsyncMsg: (char*) aDescription
{
 	GENERIC_PACKAGE pkg;
    char seconds[30];

	pkg = myCommandPackage;
	[pkg clear];
	[pkg setName: "AsyncMsg"];
	[pkg addParamAsString: "Description" value: aDescription];
    
    /*if (aTimeLeft > 0) {
        sprintf(seconds, "%d", aTimeLeft); 
        [pkg addParamAsString: "TimeLeft" value: seconds];
    }
    
    if (anIsBlocking == TRUE)
        [pkg addParamAsString: "Blocking" value: "True"];
    else
        [pkg addParamAsString: "Blocking" value: "False"];
    
    */
	[self sendPackage];   
    
}    




/**/
- (void) onDoorStateIdle
{
	GENERIC_PACKAGE pkg;

    
	pkg = myCommandPackage;
	[pkg clear];
	[pkg setName: "DoorClosed"];

	[self sendPackage];
}    





- (void) openDoor
{
    
    EXTRACTION_WORKFLOW extractionWorkflow = NULL;
	EXTRACTION_WORKFLOW innerExtractionWorkflow = NULL;
    COLLECTION doorAcceptors;
	BagTrackingMode bagTrackingMode = BagTrackingMode_NONE;
	BOOL removeCash = TRUE;
	USER userL;
    BOOL hasOpened = FALSE;
	id lastExtraction;


	COLLECTION acceptorsAutoList;
	
	unsigned long lastExtractionNumber = 0;
	int i;
	COLLECTION manualCimCashs;
	id manualDoor;
    id cimManager = [CimManager getInstance];
    id door = [[[cimManager getCim] getDoors] at: 0];
    
    doLog(0, ">>>>> openDoor 1\n");
 	// seteo los tiempos por defecto por las dudas que se hayan pisado al abrir puerta inerna
	[[CimManager getInstance] setDoorTimes];
    doLog(0, ">>>>> openDoor 2\n");
	if (![door getOuterDoor]) {
		extractionWorkflow = [[CimManager getInstance] getExtractionWorkflowForDoor: door];
		[extractionWorkflow setInnerDoorWorkflow: NULL];
		[extractionWorkflow setGeneratedOuterDoorExtr: FALSE];
		[extractionWorkflow setHasOpened: FALSE];
	} else {
		extractionWorkflow = [[CimManager getInstance] getExtractionWorkflowForDoor: [door getOuterDoor]];
		innerExtractionWorkflow = [[CimManager getInstance] getExtractionWorkflowForDoor: door];
		[innerExtractionWorkflow setHasOpened: FALSE];
        [extractionWorkflow setInnerDoorWorkflow: innerExtractionWorkflow];
		[extractionWorkflow setGeneratedOuterDoorExtr: FALSE];
		[extractionWorkflow setHasOpened: FALSE];
	}
    doLog(0, ">>>>> openDoor 3\n");
	doorAcceptors = [door getAcceptorSettingsList];
    doLog(0, ">>>>> openDoor 4\n");
	//doLog(0, "doorAcceptors size = %d\n", [doorAcceptors size]);
	//bagTrackingMode = [self getBagTrackingMode: aDoor];

	// Controlo si puede abrir la puerta dado el Time Lock correspondiente
	if ([extractionWorkflow getCurrentState] == OpenDoorStateType_IDLE) {
    doLog(0, ">>>>> openDoor 5\n");
	// Error: no puede abrir la puerta en este momento
/*		if (![aDoor canOpenDoor]) {

			[JMessageDialog askOKMessageFrom: self 
				withMessage: getResourceStringDef(RESID_DOOR_TIME_LOCK_ACTIVE, "La puerta tiene el tiempo de bloqueo activo")];

      myLoggedUser = [[UserManager getInstance] getUserLoggedIn];
      profile = [[UserManager getInstance] getProfile: [myLoggedUser getUProfileId]];
		
			if ([profile hasPermission: OVERRIDE_DOOR_OP]){
        if (![UICimUtils overrideDoor: self door: aDoor]) return;
      }else
        return;

		}

	}*/
    doLog(0, ">>>>> openDoor 6\n");
	// Pregunta si desea remover el dinero
	if ( ([extractionWorkflow getCurrentState] == OpenDoorStateType_IDLE ||
			[extractionWorkflow getCurrentState] == OpenDoorStateType_ACCESS_TIME)) {
    doLog(0, ">>>>> openDoor 7\n");
	/*	if ([doorAcceptors size] > 0)
			removeCash = [UICimUtils askRemoveCash: self door: aDoor];
    */
		if ([extractionWorkflow getInnerDoorWorkflow]) {
    doLog(0, ">>>>> openDoor 8\n");
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
    doLog(0, ">>>>> openDoor 9\n");
	// si remueve el cash y por configuracion debe preguntar por el id de bolsa
	if ([extractionWorkflow getCurrentState] == OpenDoorStateType_IDLE) {
		if ([extractionWorkflow getInnerDoorWorkflow]) {
    doLog(0, ">>>>> openDoor 10\n");
			[[extractionWorkflow getInnerDoorWorkflow] setBagTrackingMode: bagTrackingMode];

	/*		if (removeCash && bagTrackingMode != BagTrackingMode_NONE) {

				if ([[CimGeneralSettings getInstance] getAskBagCode]) {
					stringcpy(bagBarCode, [UICimUtils askBagBarCode: self barCode: bagBarCode]);
					[[extractionWorkflow getInnerDoorWorkflow] setBagBarCode: bagBarCode];
				}
*/
				[[extractionWorkflow getInnerDoorWorkflow] setBagTrackingMode: bagTrackingMode];
			}
    
		} else {
			[extractionWorkflow setBagTrackingMode: bagTrackingMode];
	
			if (removeCash && bagTrackingMode != BagTrackingMode_NONE) {
/*
				if ([[CimGeneralSettings getInstance] getAskBagCode]) {
					stringcpy(bagBarCode, [UICimUtils askBagBarCode: self barCode: bagBarCode]);
					[extractionWorkflow setBagBarCode: bagBarCode];
				}
*/
				[extractionWorkflow setBagTrackingMode: bagTrackingMode];
			}
		}

	}

    doLog(0, ">>>>> openDoor 12\n");
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

	[extractionWorkflow addObserver: self];
    doLog(0, ">>>>> openDoor 13\n");
	[extractionWorkflow removeLoggedUsers];
    userL = [[UserManager getInstance] getUserLoggedIn];
    [userL setWasPinGenerated: 0];
    [extractionWorkflow onLoginUser: userL];
    doLog(0, ">>>>> openDoor 14\n");
/*
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
*/
    doLog(0, ">>>>> openDoor 15\n");

        doLog(0, ">>>>> openDoor 16\n");
    /*
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
*/
        doLog(0, ">>>>> openDoor 18\n");
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

	    doLog(0, ">>>>> openDoor 19\n");
    [myRemoteProxy sendAckMessage];
  
}

/**/
- (void) onExtractionWorkflowStateChange: (id) anObject
{
	char notificationDsc[100];
    int state = [anObject getCurrentState];
    long timerPeriod = 0;

		printf(">>>>>>>>>>>>>>>>>>ON EXTRACTIO NWORKFLOW CHANGE %s\n", [[anObject getDoor] getDoorName]);
	//[myMutex lock];

	TRY

		*notificationDsc = '\0';

		printf("Cambio el estado de la puerta %s\n", [[anObject getDoor] getDoorName]);

		switch (state) {
	
			case OpenDoorStateType_UNDEFINED: 
				strcpy(notificationDsc, getResourceStringDef(RESID_UNDEFINED, "INDEFINIDO"));
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_UNDEFINED\n");
                
				break;
	
			case OpenDoorStateType_IDLE: 
                strcpy(notificationDsc, getResourceStringDef(RESID_UNDEFINED, "Puerta Inactiva"));
                printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>INACTIVO!!!!!!!!!!!!!!!!!!!!!!! \n");
                //[self onDoorStateIdle];
                //[self onInformAlarm: notificationDsc timeLeft: 300 isBlocking: FALSE];
                [self onDoorStateChange: state period: 0];
                [anObject removeObserver];
				break;
	
			case OpenDoorStateType_TIME_DELAY: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_TIME_DELAY\n");
                timerPeriod = [anObject getPeriod];
                 [self onDoorStateChange: state period: timerPeriod];
				break;
	
			case OpenDoorStateType_ACCESS_TIME: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_ACCESS_TIME\n");
                timerPeriod = [anObject getPeriod];
                [self onDoorStateChange: state period: timerPeriod];
				[self removeLoggedUsers];		
				break;
	
			case OpenDoorStateType_WAIT_OPEN_DOOR: 
				sprintf(notificationDsc, "%s", getResourceStringDef(RESID_UNDEFINED, "Abrir Puerta")); 
                
                printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>ABRIR PUERTA!!!!!!!!!!!!!!!!!!!!!!! \n");
                //[self onInformAlarm: notificationDsc timeLeft: 0 isBlocking: TRUE];
                [self onDoorStateChange: state period: 0];
				break;
	
			case OpenDoorStateType_WAIT_CLOSE_DOOR: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_WAIT_CLOSE_DOOR\n");
                sprintf(notificationDsc, "%s", getResourceStringDef(RESID_UNDEFINED, "Cerrar Puerta"));
                [self onDoorStateChange: state period: 0];
				break;

			case OpenDoorStateType_WAIT_CLOSE_DOOR_WARNING: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_WAIT_CLOSE_DOOR_WARNING\n");
				sprintf(notificationDsc, "%s %s ", getResourceStringDef(RESID_UNDEFINED, "Cerrar Puerta"), getResourceStringDef(RESID_UNDEFINED, "Alarma en: "));
                printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>CERRAR PUERTA 1!!!!!!!!!!!!!!!!!!!!!!! \n");
				break;
	
			case OpenDoorStateType_WAIT_CLOSE_DOOR_ERROR: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_WAIT_CLOSE_DOOR_ERROR\n");
				sprintf(notificationDsc, "%s %s", getResourceStringDef(RESID_UNDEFINED, "Cerrar Puerta"), getResourceStringDef(RESID_UNDEFINED, "Error"));
                printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>CERRAR PUERTA 2!!!!!!!!!!!!!!!!!!!!!!! \n");
                break;
	
			case OpenDoorStateType_LOCK_AND_OPEN_DOOR: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_LOCK_AND_OPEN_DOOR\n");
				sprintf(notificationDsc, "%s %s", getResourceStringDef(RESID_UNDEFINED, "Puerta abierta"), getResourceStringDef(RESID_UNDEFINED, "Error"));
				break;
	
			case OpenDoorStateType_WAIT_UNLOCK_WITH_OPEN_DOOR: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_WAIT_UNLOCK_WITH_OPEN_DOOR\n");
				sprintf(notificationDsc, "%s %s", getResourceStringDef(RESID_UNDEFINED, "Destrabar Puerta"), getResourceStringDef(RESID_UNDEFINED, "Error"));
				break;
	
/*			case OpenDoorStateType_WAIT_UNLOCK_ENABLE:
				strcpy(notificationDsc, getResourceStringDef(RESID_UNDEFINED, "Girar llave"));
*/				break;
	
			case OpenDoorStateType_WAIT_LOCK_DOOR: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_WAIT_LOCK_DOOR\n");
				sprintf(notificationDsc, "%s %s", getResourceStringDef(RESID_UNDEFINED, "Trabar Puerta"), getResourceStringDef(RESID_UNDEFINED, "Advertencia en: "));
				break;
	
/*			case OpenDoorStateType_WAIT_LOCK_DOOR_WARNING: 
				sprintf(notificationDsc, "%s %s", getResourceStringDef(RESID_UNDEFINED, "Trabar Puerta"), getResourceStringDef(RESID_UNDEFINED, "Alarma en: "));
				break;
 */
			case OpenDoorStateType_WAIT_LOCK_DOOR_ERROR: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_WAIT_LOCK_DOOR_ERROR\n");
				sprintf(notificationDsc, "%s %s", getResourceStringDef(RESID_UNDEFINED, "Trabar puerta"), getResourceStringDef(RESID_UNDEFINED, "Error"));
				break;

	
			case OpenDoorStateType_OPEN_DOOR_VIOLATION: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_OPEN_DOOR_VIOLATION\n");
				strcpy(notificationDsc, getResourceStringDef(RESID_UNDEFINED, "Violacion de Seguridad"));
				break;

			case OpenDoorStateType_WAIT_OUTER_DOOR_OPEN: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_WAIT_OUTER_DOOR_OPEN\n");
				strcpy(notificationDsc, getResourceStringDef(RESID_UNDEFINED, "Wait Outer Door Open"));
				break;

	
		}
	
//		LOG_DEBUG(LOG_TELESUP, "Door State: %s, %s, %d", notificationDsc, timeStr, [anExtractionWorkflow getCurrentState]);
	
//		[self informDoorAccessNotification: anExtractionWorkflow alarmType: entityType	notification: notificationDsc secondsTimerAlarm: secondsCount countDown: cDown];


	FINALLY

		//[myMutex unLock];

	END_TRY    
}

/**/
- (void) executeRequest
{
	switch (myReqType) {
        
		case USER_LOGIN_REQ:
            doLog(0, "userLoginReq\n");
			[self userLogin];
			return;

		case USER_HAS_CHANGE_PIN_REQ:
			[self hasUserChangePin];
			return;

		case USER_CHANGE_PIN_REQ:
            doLog(0, "userChangePinReq\n");
			[self userChangePin];
			return;

		case USER_LOGOUT_REQ:
			[self userLogout];
			return;
            
		case START_VALIDATED_DROP_REQ:
			[self startValidatedDrop];
			return;

		case END_VALIDATED_DROP_REQ:
			[self endValidatedDrop];
			return;
            
        case INIT_EXTRACTION_PROCESS_REQ:
            [self initExtractionProcess];
            return;

        case GET_DOOR_STATE_REQ:
            [self getDoorState];
            return;
            
        case SET_REMOVE_CASH_REQ:
            [self setRemoveCash];
            return;
            
        case START_EXTRACTION_REQ:
            [self openDoor];
            return;
            
        case USER_LOGIN_FOR_DOOR_ACCESS_REQ:
            [self userLoginForDoorAcccess];
            return;
        
        case START_DOOR_ACCESS_REQ:
            [self startDoorAccess];
            return;
            
        case CLOSE_EXTRACTION_REQ:
            [self closeExtraction];
            return;

        case CANCEL_TIME_DELAY_REQ:
            [self cancelTimeDelay];
            return;            
            
        case CANCEL_DOOR_ACCESS_REQ:
            [self cancelDoorAccess];
            return;

		default: break;		

	}

	THROW_FMT(TSUP_INVALID_OPERATION_EX, "ReqType=%d", myReqType);
	printf("SystemOpRequest -> Unknown operation\n");

}

@end
