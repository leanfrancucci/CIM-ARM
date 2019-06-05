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
#include "DepositController.h"
#include "AsyncMsgThread.h"
#include "ReportController.h"
#include "ZCloseManager.h"
#include "TelesupController.h"
#include "SafeBoxHAL.h"
#include "BoxModel.h"
#include "TelesupScheduler.h"
#include "TelesupervisionManager.h"
#include "CommercialState.h"
#include "CommercialStateMgr.h"

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
    
    [[AsyncMsgThread getInstance] setSystemOpRequest: self];

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
        else printf("myEventsProxy not null\n");
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
		printf("myEventsProxy sendPackage --> %s", msg);
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
    USER userL = NULL;
    
    userL = [[UserManager getInstance] getUserLoggedIn];
    if (userL != NULL) {
        
        printf("userLogout\n");
        
        buffer[0] = '\0';
        sprintf(buffer, "%s-%s",[user getLoginName], [userL getFullName]);
        [Audit auditEventCurrentUser: Event_LOGOUT_USER additional: buffer station: 0 logRemoteSystem: FALSE];
  	  
        [[UserManager getInstance] logOffUser: [userL getUserId]];
        
    }

    [myRemoteProxy sendAckMessage];
}


/**/
- (int) getTotalStackerSize: (id) anAcceptorSetting
{
	id cimCash;
	COLLECTION acceptors;
	int i;
	int sSize = 0;

	cimCash = [[[CimManager getInstance] getCim] getCimCashByAcceptorId: [anAcceptorSetting getAcceptorId]];
	acceptors = [cimCash getAcceptorSettingsList];
	for (i=0; i<[acceptors size]; ++i)  {
		sSize+= [[acceptors at: i] getStackerSize];
	}
	
	return sSize;

}

/**/
- (int) getTotalStackerWarningSize: (id) anAcceptorSetting
{
	id cimCash;
	COLLECTION acceptors;
	int i;
	int sWarningSize = 0;

	cimCash = [[[CimManager getInstance] getCim] getCimCashByAcceptorId: [anAcceptorSetting getAcceptorId]];
	acceptors = [cimCash getAcceptorSettingsList];
	
	for (i=0; i<[acceptors size]; ++i) {
		sWarningSize+= [[acceptors at: i] getStackerWarningSize];
	}
	
	return sWarningSize;

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
	id acceptors;
    int i;
    int stackerQty;
    int stackerSize;
    int stackerWarningSize;
    
        
    
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
    
        if ([myPackage isValidParam: "CashReferenceId"])
            referenceId = [myPackage getParamAsInteger: "CashReferenceId"];
    

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

        
      	acceptors = [cimCash getAcceptorSettingsList];  
        
        
        // recorro los validadores para mostrar el cartel de deshabilidao cuando corresponda
        for (i = 0; i < [acceptors size]; ++i) {

            // Si es FLEX debe tomar la configuracion de algun lado
            if (strstr([[[[CimManager getInstance] getCim] getBoxById: 1] getBoxModel], "FLEX")) {

                stackerQty = [[[ExtractionManager getInstance] getCurrentExtraction: [[acceptors at: i] getDoor]] getQty: NULL];
                // debo tomar el total del tamano que es la sumatoria de los montos de los stackers de cada aceptador
                stackerSize = [self getTotalStackerSize: [acceptors at: i]];
                stackerWarningSize = [self getTotalStackerWarningSize: [acceptors at: i]];
                printf("stacker size = %d\n", stackerSize);
                printf("stacker warning size = %d\n", stackerWarningSize);
                printf("stacker qty = %d\n", stackerQty);

            } else {

                // si es stacker full no le habilito el validador
                stackerQty = [[[ExtractionManager getInstance] getCurrentExtraction: [[acceptors at: i] getDoor]] getQtyByAcceptor: [acceptors at: i]];

                stackerSize = [[acceptors at: i] getStackerSize];
                stackerWarningSize = [[acceptors at: i] getStackerWarningSize];
            }


            if ((stackerSize != 0) && (stackerSize <= stackerQty)){

                if (strstr([[[[CimManager getInstance] getCim] getBoxById: 1] getBoxModel], "FLEX")) {
                    THROW(RESID_ACCEPTORS_DISABLED);
                    //sprintf(buff, "%s", getResourceStringDef(RESID_ACCEPTORS_DISABLED, "Validadores deshabilitados. Stacker Lleno!"));
                } else {
                    THROW(RESID_STACKER_FULL_VALIDATED_DROP);
                    //sprintf(buff, "%-20s %s", [[acceptors at: i] getAcceptorName], getResourceStringDef(RESID_STACKER_FULL_VALIDATED_DROP, "Sera deshabilitado. Stacker esta Lleno!"));
                }
            }
        }        
        
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
    printf("finaliza el deposito\n");
    [[CimManager getInstance] endDeposit];
 	[[CimManager getInstance] removeObserver: self];

	myDeposit = NULL;
    
 //   msleep(5000);
    [myRemoteProxy sendAckMessage];
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
    char additional[100];
    
    printf(">>>>>>>>>>>>>>>>>>>> SystemOpRequest  onBillRejected\n");
	sprintf(additional, "%d ", aCause);
			
    switch (aCause)
    {
        case 113: strcat(additional, getResourceStringDef(RESID_INSERTION_ERROR, "Error al Insertar")); break;
        case 114: strcat(additional, getResourceStringDef(RESID_MAGNETIC_PATTERN_ERROR, "Magnetic Pattern Error")); break;
        case 115: strcat(additional, getResourceStringDef(RESID_IDLE_SENSOR_DETECTED, "Sensor Inactivo detectado")); break;
        case 116: strcat(additional, getResourceStringDef(RESID_DATA_AMPLITUDE_ERROR, "Error en Amplitud de datos")); break;
        case 117: strcat(additional, getResourceStringDef(RESID_FEED_ERROR, "Error en Alimentacion")); break;
        case 118: strcat(additional, getResourceStringDef(RESID_DENOMINATION_ASSESSING_ERROR, "Error al Evaluar denominacion")); break;
        case 119: strcat(additional, getResourceStringDef(RESID_PHOTO_PATTERN_ERROR, "Error en Patron de foto")); break;
        case 120: strcat(additional, getResourceStringDef(RESID_PHOTO_LEVEL_ERROR, "Error en Nivel de foto")); break;
        case 121: strcat(additional, getResourceStringDef(RESID_BILL_DISABLED, "Billete Disabilitado")); break;
        case 122: strcat(additional, getResourceStringDef(RESID_RESERVER, "Reservado")); break;
        case 123: strcat(additional, getResourceStringDef(RESID_OPERATION_ERROR, "Error de Operacion")); break;
        case 124: strcat(additional, getResourceStringDef(RESID_WRONG_TIME, "Tiempo Erroneo")); break;
        case 125: strcat(additional, getResourceStringDef(RESID_LENGHT_ERROR, "Longitud Erronea")); break;
        case 126: strcat(additional, getResourceStringDef(RESID_COLOR_PATTERN_ERROR, "Patron de Color erroneo")); break;
        case 999: strcat(additional, getResourceStringDef(RESID_UNDEFINE, "Undefined")); break;
    }    
    
    [[AsyncMsgThread getInstance] addAsyncMsgBillRejected: [[anAcceptor getAcceptorSettings] getAcceptorId] 
                                                        cause: additional
                                                        qty: aQty];
        
	
}
/**/
- (void) onBillAccepted: (ABSTRACT_ACCEPTOR) anAcceptor currency: (CURRENCY) aCurrency amount: (money_t) anAmount  qty: (int) aQty
{

    //char amountstr[50];
	//GENERIC_PACKAGE pkg;

    printf( ">>>>>>>>>>>>>>>>>>>> SystemOpRequest  onBillAccepted\n");
    //if (myDeposit == NULL) return;

    [[AsyncMsgThread getInstance] addAsyncMsgBillAccepted: [[anAcceptor getAcceptorSettings] getAcceptorId] 
                                                        state: getResourceStringDef(RESID_BILL_VERIFIED, "Bill Accepted!")
                                                        currencyCode: [aCurrency getCurrencyCode]
                                                        amount: anAmount 
                                                        deviceName: [[anAcceptor getAcceptorSettings] str]
                                                        qty: aQty];
    
    
/*
    pkg = myCommandPackage;
	[pkg clear];
	[pkg setName: "BillAccepted"];
    [pkg addParamAsInteger: "AcceptorId" value: ];
	[pkg addParamAsString: "State" value: ];
	[pkg addParamAsString: "CurrencyCode" value: ];
	formatMoney(amountstr, "", anAmount * aQty, 2, 20);
    [pkg addParamAsString: "Amount" value: amountstr];
	[pkg addParamAsString: "DeviceName" value: [[anAcceptor getAcceptorSettings] str]];
    [pkg addParamAsInteger: "Qty" value: aQty];
    // la denominacion seria el amount dividido ADD_VEND_ITEM_BY_QTY_REQ
    [self sendPackage];    
    */
}

/**/
- (void) onInactivityWarning: (OTIMER) aTimer { 
    
    doLog(0, ">>>>>>>>>>>>>>>>>>>>>>>>>> onInactivityWarning\n");
    [[CimManager getInstance] needMoreTime];
}

/**/
- (void) onDoorStateChange: (int) aState period: (long) aPeriod
{
    [[AsyncMsgThread getInstance] addAsyncMsgDoorState: aState period: aPeriod];
    
    /*GENERIC_PACKAGE pkg;
    char seconds[30];

    printf("SystemOpRequest onDoorStateChange\n");
	pkg = myCommandPackage;
	[pkg clear];
	[pkg setName: "DoorStateChange"];
	[pkg addParamAsInteger: "State" value: aState];
    [pkg addParamAsInteger: "Period" value: aPeriod];
	[self sendPackage];
    */
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
    
    
    if ([myPackage isValidParam: "UserName"]) {
        stringcpy(userName, [myPackage getParamAsString: "UserName"]);
    }  else {/* TIRAR ERROR*/}

    if ([myPackage isValidParam: "UserPassword"]) {
        stringcpy(userPassword, [myPackage getParamAsString: "UserPassword"]);
    } else {/**/}

    [[ExtractionController getInstance] userLoginForDoorAccess: userName userPassword: userPassword];

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
    //[[ExtractionController getInstance] free];
    
    
    printf("Manda ack de closeExtraction \n");
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
/*DEPOSITO MANUAL*/
/*********************************************************************/
/**/
- (void) startManualDrop
{
	int cashId = 0;
    int referenceId = 0;
    unsigned long userId = 0;
	char envelopeNumber[50];
	char applyTo[50];
    int excode = 0;
    char exceptionDescription[512];
    CIM_CASH cimCash; 
   	*envelopeNumber = '\0';
	*applyTo = '\0';    
    
    printf("SystemOpRequest->startManualDrop\n");


    if ([myPackage isValidParam: "UserId"]) 
        userId = [myPackage getParamAsInteger: "UserId"];

    if ([myPackage isValidParam: "ApplyTo"])
        stringcpy(applyTo, [myPackage getParamAsString: "ApplyTo"]);

    if ([myPackage isValidParam: "EnvelopeNumber"])
        stringcpy(envelopeNumber, [myPackage getParamAsString: "EnvelopeNumber"]);

    if ([myPackage isValidParam: "CashId"])
        cashId = [myPackage getParamAsInteger: "CashId"];

    if ([myPackage isValidParam: "CashReferenceId"])
        referenceId = [myPackage getParamAsInteger: "CashReferenceId"];    

    //[[DepositController getInstance] setObserver: self];
    [[DepositController getInstance] initManualDrop: userId cashId: cashId referenceId: referenceId applyTo: applyTo envelopeNumber: envelopeNumber];
    
    [myRemoteProxy sendAckMessage];
}

/**/
- (void) addManualDropDetail
{
    int acceptorId = 0;
    int currencyId = 0; 
    int qty = 0;
    money_t amount = 0;
    int valueType = 0;
    
    
    if ([myPackage isValidParam: "AcceptorId"]) 
        acceptorId = [myPackage getParamAsInteger: "AcceptorId"];
    
    if ([myPackage isValidParam: "ValueType"]) 
        valueType = [myPackage getParamAsInteger: "ValueType"];
        
    if ([myPackage isValidParam: "CurrencyId"])
        currencyId = [myPackage getParamAsInteger: "CurrencyId"];
        
    if ([myPackage isValidParam: "Qty"])
        qty = [myPackage getParamAsInteger: "Qty"];

    if ([myPackage isValidParam: "Amount"])
        amount = [myPackage getParamAsCurrency: "Amount"];
    
    
    [[DepositController getInstance] addDropDetail: (int) acceptorId depositValueType: valueType currencyId: currencyId qty: qty amount: amount];

    [myRemoteProxy sendAckMessage];   

}

/**/
- (void) printManualDropReceipt
{
    [[DepositController getInstance] printDropReceipt];
    [myRemoteProxy sendAckMessage];       
}

/**/
- (void) cancelManualDrop
{
    [[DepositController getInstance] cancelDrop];

    [myRemoteProxy sendAckMessage];       
}

/**/
- (void) finishManualDrop
{
    [[DepositController getInstance] finishDrop];

    [myRemoteProxy sendAckMessage];       
    
}

/**/
- (void) enableMailbox
{
    int excode;
    char exceptionDescription[100];

    TRY
        // Debería habilitar la cerradura electrónica.
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
    
    [myRemoteProxy sendAckMessage];       
    
}

/**/
- (void) disableMailbox
{
    int excode;
    char exceptionDescription[100];

    TRY
        // Debería deshabilitar la cerradura electrónica.
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

    [myRemoteProxy sendAckMessage];       
    
}

/*********************************************************************/
/*VALIDACION DE BILLETES*/
/*********************************************************************/

/**/
- (void) startValidationMode
{
    [[CimManager getInstance] startValidationMode];
	// audito el inicio de la validacion de billetes
	[Audit auditEventCurrentUser: Event_START_BILL_VALIDATION additional: "" station: 0 logRemoteSystem: FALSE];
	[[CimManager getInstance] addObserver: self];
    
    [myRemoteProxy sendAckMessage];       
    
}


/**/
- (void) stopValidationMode
{
 	[[CimManager getInstance] removeObserver: self];
	[[CimManager getInstance] stopValidationMode];

	// audito el fin de la validacion de billetes
	[Audit auditEventCurrentUser: Event_END_BILL_VALIDATION additional: "" station: 0 logRemoteSystem: FALSE];
    
    [myRemoteProxy sendAckMessage];       

}

/*********************************************************************/
/*REPORTES*/
/*********************************************************************/

/**/
- (void) generateOperatorReport
{
    int userId;
    BOOL detailed;
    
    if ([myPackage isValidParam: "UserId"]) 
        userId = [myPackage getParamAsInteger: "UserId"];
    
    if ([myPackage isValidParam: "Detailed"])
        detailed = [myPackage getParamAsBoolean: "Detailed"];    

    
    [[ReportController getInstance] genOperatorReport: userId detailed: detailed];
    
    [myRemoteProxy sendAckMessage];    
}

/**/
- (void) hasAlreadyPrintEndDay
{
    BOOL alreadyPrint;
    
    alreadyPrint = [[ZCloseManager getInstance] hasAlreadyPrintZClose];
        
    [myRemoteProxy newMessage: "OK"];
    [myRemoteProxy addParamAsInteger: "AlreadyPrint" value: alreadyPrint];
    [myRemoteProxy appendTimestamp];
    [myRemoteProxy sendMessage];        
    
}

/**/
-(void) generateEndDay
{
    BOOL printOperatorReport;
    
    if ([myPackage isValidParam: "PrintOperatorReport"])
        printOperatorReport = [myPackage getParamAsBoolean: "PrintOperatorReport"];    

    [[ReportController getInstance] genEndDay: printOperatorReport];
    
    [myRemoteProxy sendAckMessage];       
}

- (void) isValidationModeAvailable
{
    int acceptorId;
    BOOL validationAvailable = FALSE;
   	id acceptorSettings = NULL;

    
    if ([myPackage isValidParam: "AcceptorId"]) 
        acceptorId = [myPackage getParamAsInteger: "AcceptorId"];

	acceptorSettings = [[[CimManager getInstance] getCim] getAcceptorSettingsById: acceptorId];
	if ([acceptorSettings getAcceptorType] == AcceptorType_VALIDATOR) {
        if (([acceptorSettings getAcceptorProtocol] == ProtocolType_ID0003 ) || 
        ([acceptorSettings getAcceptorProtocol] == ProtocolType_CCNET ) || 
        ([acceptorSettings getAcceptorProtocol] == ProtocolType_EBDS )) 
            validationAvailable = TRUE;
    } 
    
        
    [myRemoteProxy newMessage: "OK"];
    [myRemoteProxy addParamAsBoolean: "Available" value: validationAvailable ];
    [myRemoteProxy appendTimestamp];
    [myRemoteProxy sendMessage];        
    
}

/**/
- (void) generateEnrolledUsersReport
{
    int status;
    BOOL detailed;
    
    if ([myPackage isValidParam: "Status"]) 
        status = [myPackage getParamAsInteger: "Status"];
    
    if ([myPackage isValidParam: "Detailed"])
        detailed = [myPackage getParamAsBoolean: "Detailed"];    

    [[ReportController getInstance] genEnrolledUsersReport: status detailed: detailed];
    
    [myRemoteProxy sendAckMessage];    
    
}


/**/ 
- (void) generateAuditReport
{
    datetime_t dateFrom;
    datetime_t dateTo;
    int cashId;
    int userId;
    int eventCategory;
    BOOL detailed;
    
    if ([myPackage isValidParam: "DateFrom"]) 
        dateFrom = [myPackage getParamAsDateTime: "DateFrom"];

    if ([myPackage isValidParam: "DateTo"]) 
        dateTo = [myPackage getParamAsDateTime: "DateTo"];

    if ([myPackage isValidParam: "UserId"]) 
        userId = [myPackage getParamAsInteger: "UserId"];

    if ([myPackage isValidParam: "CashId"]) 
        cashId = [myPackage getParamAsInteger: "CashId"];    

    if ([myPackage isValidParam: "EventCategoryId"]) 
        eventCategory = [myPackage getParamAsInteger: "EventCategoryId"];    
    
    if ([myPackage isValidParam: "Detailed"])
        detailed = [myPackage getParamAsBoolean: "Detailed"];    

    [[ReportController getInstance] genAuditReport: dateFrom dateTo: dateTo userId: userId cashId: cashId eventCategoryId: eventCategory detailed: detailed];
    
    [myRemoteProxy sendAckMessage];        
}

/**/
- (void) generateCashReport
{
    int doorId;
    int cashId;
    BOOL detailed;
    
    if ([myPackage isValidParam: "DoorId"]) 
        doorId = [myPackage getParamAsInteger: "DoorId"];

    if ([myPackage isValidParam: "CashId"]) 
        cashId = [myPackage getParamAsInteger: "CashId"];
    
    if ([myPackage isValidParam: "Detailed"])
        detailed = [myPackage getParamAsBoolean: "Detailed"];    

    [[ReportController getInstance] genCashReport: doorId cashId: cashId detailed: detailed];
    
    [myRemoteProxy sendAckMessage];    
        
}

/**/
- (void) generateXCloseReport
{
    [[ReportController getInstance] genXCloseReport];
    
    [myRemoteProxy sendAckMessage];        
}

/**/
- (void) generateReferenceReport
{
    int cashReferenceId;
    BOOL detailed;
    
    if ([myPackage isValidParam: "CashReferenceId"]) 
        cashReferenceId = [myPackage getParamAsInteger: "CashReferenceId"];

    if ([myPackage isValidParam: "Detailed"])
        detailed = [myPackage getParamAsBoolean: "Detailed"];     
    
    [[ReportController getInstance] genCashReferenceReport: cashReferenceId detailed: detailed];

    [myRemoteProxy sendAckMessage];        
}
            
/**/
- (void) generateSystemInfoReport
{
    BOOL detailed; 
    
    if ([myPackage isValidParam: "Detailed"])
        detailed = [myPackage getParamAsBoolean: "Detailed"];     
    
    [[ReportController getInstance] genSystemInfoReport: detailed];

    [myRemoteProxy sendAckMessage];        

}
            

/**/
- (void) generateTelesupReport
{
    [[ReportController getInstance] genTelesupReport];
    [myRemoteProxy sendAckMessage];    
}
 
/**/
- (void) reprintDeposit
{
    
    BOOL last; 
    long fromId;
    long toId;
    
    if ([myPackage isValidParam: "Last"])
        last = [myPackage getParamAsBoolean: "Last"];     

    if ([myPackage isValidParam: "FromId"]) 
        fromId = [myPackage getParamAsInteger: "FromId"];
    
    if ([myPackage isValidParam: "ToId"]) 
        toId = [myPackage getParamAsInteger: "ToId"];

    [[ReportController getInstance] reprintDep: last fromId: fromId toId: toId];

    [myRemoteProxy sendAckMessage];       

}
            
/**/
- (void) reprintExtraction
{
    BOOL last; 
    long fromId;
    long toId;
    
    if ([myPackage isValidParam: "Last"])
        last = [myPackage getParamAsBoolean: "Last"];     

    if ([myPackage isValidParam: "FromId"]) 
        fromId = [myPackage getParamAsInteger: "FromId"];
    
    if ([myPackage isValidParam: "ToId"]) 
        toId = [myPackage getParamAsInteger: "ToId"];

    [[ReportController getInstance] reprintExt: last fromId: fromId toId: toId];

    [myRemoteProxy sendAckMessage];       
    
}

/**/
- (void) reprintEndDay
{
    BOOL last; 
    long fromId;
    long toId;
    
    if ([myPackage isValidParam: "Last"])
        last = [myPackage getParamAsBoolean: "Last"];     

    if ([myPackage isValidParam: "FromId"]) 
        fromId = [myPackage getParamAsInteger: "FromId"];
    
    if ([myPackage isValidParam: "ToId"]) 
        toId = [myPackage getParamAsInteger: "ToId"];

    [[ReportController getInstance] reprintEndD: last fromId: fromId toId: toId];

    [myRemoteProxy sendAckMessage];       
    
}

/**/
-(void) reprintPartialDay
{
    BOOL last; 
    long fromId;
    long toId;
    
    if ([myPackage isValidParam: "Last"])
        last = [myPackage getParamAsBoolean: "Last"];     

    if ([myPackage isValidParam: "FromId"]) 
        fromId = [myPackage getParamAsInteger: "FromId"];
    
    if ([myPackage isValidParam: "ToId"]) 
        toId = [myPackage getParamAsInteger: "ToId"];

    [[ReportController getInstance] reprintPartialD: last fromId: fromId toId: toId];

    [myRemoteProxy sendAckMessage];       

}


/*********************************************************************/
/*TELESUPERVISION*/
/*********************************************************************/
- (void) startManualTelesup
{
    int excode = 0;
    
    TRY
        [[TelesupController getInstance] startManualTelesup];
        [myRemoteProxy sendAckMessage];
    CATCH
    
        ex_printfmt();
        excode = ex_get_code();
        
        [myRemoteProxy newMessage: "Error"];
        [myRemoteProxy addParamAsInteger: "Code" value: excode];
        [myRemoteProxy addParamAsString: "Description" value: "No es posible ejecutar la supervision"];
        [myRemoteProxy appendTimestamp];
        [myRemoteProxy sendMessage];
    
    END_TRY
    
}


- (void) acceptIncomingSupervision
{
    BOOL value;
    
    if ([myPackage isValidParam: "Value"])
        value = [myPackage getParamAsBoolean: "Value"];     
    
    [[TelesupController getInstance] acceptCMPSupervision: value];
    
    [myRemoteProxy sendAckMessage];
    
}


/**/
- (void) sendDateTime
{

    [myRemoteProxy newMessage: "DateTime"];
    [myRemoteProxy appendTimestamp];
    [myRemoteProxy sendMessage];

}


/**********************************************************************/
/*MODELO DE CAJA*/
/**********************************************************************/
- (void) hasModelSet
{
    BOOL verfifyBoxModelChange = [[[CimManager getInstance] getCim] verifyBoxModelChange];
    
    [myRemoteProxy newResponseMessage];

    if (verfifyBoxModelChange == TRUE)
        [myRemoteProxy addParamAsBoolean: "Result" value: FALSE];
    else
        [myRemoteProxy addParamAsBoolean: "Result" value: TRUE];
    
    [myRemoteProxy sendMessage];
    
}

- (void) getBoxModel
{
    id cim;
    id box;
    id boxModel;
    int boxModelId = -1;
    int val1ModelId = -1;
    int val2ModelId = -1;
    
    BOOL verfifyBoxModelChange = [[[CimManager getInstance] getCim] verifyBoxModelChange];
    
    [myRemoteProxy newResponseMessage];

    
    if (verfifyBoxModelChange == FALSE) { 
    
        cim = [[CimManager getInstance] getCim];
        box = [cim getBoxById: 1];
    
        if (box == NULL) exit;
        
        boxModelId = [box getModel];                                                        
        val1ModelId = [box getValModel: 1];
        val2ModelId = [box getValModel: 2]; 
    
    } 
    
    [myRemoteProxy addParamAsInteger: "ModelId" value: boxModelId];
    [myRemoteProxy addParamAsInteger: "Val1ModelId" value: val1ModelId];
    [myRemoteProxy addParamAsInteger: "Val2ModelId" value: val2ModelId];
    
    [myRemoteProxy sendMessage];
    
}

/**/
- (void) hasMovements
{
    BOOL hasMovements = [[[CimManager getInstance] getCim] hasMovements];
    
    [myRemoteProxy newResponseMessage];

    [myRemoteProxy addParamAsBoolean: "Result" value: hasMovements];
    
    [myRemoteProxy sendMessage];

}

/**/
- (void) setBoxModel
{
    int modelId = 0;
    int val1ModelId = 0;
    int val2ModelId = 0;
    
    id boxModel = [BoxModel new];
    
    if ([myPackage isValidParam: "ModelId"]) 
        modelId = [myPackage getParamAsInteger: "ModelId"];
    
    if ([myPackage isValidParam: "Val1ModelId"]) 
        val1ModelId = [myPackage getParamAsInteger: "Val1ModelId"];
    
    if ([myPackage isValidParam: "Val2ModelId"]) 
        val2ModelId = [myPackage getParamAsInteger: "Val2ModelId"];

    [boxModel setPhisicalModel: modelId];
    [boxModel setVal1Model: val1ModelId];
    [boxModel setVal2Model: val2ModelId];

    TRY
        [boxModel save]; 
    FINALLY
        [boxModel free];
    END_TRY
    
    [myRemoteProxy sendAckMessage];
        
}

/**/ 
- (void) getAvailableBoxModels
{
    [myRemoteProxy newResponseMessage];
    [self beginEntity];
    [myRemoteProxy addParamAsInteger: "ModelId" value: 0];
    [myRemoteProxy addParamAsString: "Description" value: "Box2ED2V1M"];
    [myRemoteProxy addParamAsInteger: "ValQty" value: 2];
    [self endEntity];

    [self beginEntity];
    [myRemoteProxy addParamAsInteger: "ModelId" value: 1];
    [myRemoteProxy addParamAsString: "Description" value: "Box2ED1V1M"];
    [myRemoteProxy addParamAsInteger: "ValQty" value: 1];
    [self endEntity];

    [self beginEntity];
    [myRemoteProxy addParamAsInteger: "ModelId" value: 2];
    [myRemoteProxy addParamAsString: "Description" value: "Box2EDI2V1M"];
    [myRemoteProxy addParamAsInteger: "ValQty" value: 2];    
    [self endEntity];

    [self beginEntity];
    [myRemoteProxy addParamAsInteger: "ModelId" value: 3];
    [myRemoteProxy addParamAsString: "Description" value: "Box2EDI1V1M"];
    [myRemoteProxy addParamAsInteger: "ValQty" value: 1];    
    [self endEntity];

    [self beginEntity];
    [myRemoteProxy addParamAsInteger: "ModelId" value: 4];
    [myRemoteProxy addParamAsString: "Description" value: "Box1ED2V1M"];
    [myRemoteProxy addParamAsInteger: "ValQty" value: 2];    
    [self endEntity];

    [self beginEntity];
    [myRemoteProxy addParamAsInteger: "ModelId" value: 5];
    [myRemoteProxy addParamAsString: "Description" value: "Box1ED1V1M"];
    [myRemoteProxy addParamAsInteger: "ValQty" value: 1];    
    [self endEntity];

    [self beginEntity];
    [myRemoteProxy addParamAsInteger: "ModelId" value: 6];
    [myRemoteProxy addParamAsString: "Description" value: "Box1ED1M"];
    [myRemoteProxy addParamAsInteger: "ValQty" value: 0];    
    [self endEntity];

    [self beginEntity];
    [myRemoteProxy addParamAsInteger: "ModelId" value: 7];
    [myRemoteProxy addParamAsString: "Description" value: "Box1D2V1M"];
    [myRemoteProxy addParamAsInteger: "ValQty" value: 2];    
    [self endEntity];

    [self beginEntity];
    [myRemoteProxy addParamAsInteger: "ModelId" value: 8];
    [myRemoteProxy addParamAsString: "Description" value: "Box1D1V1M"];
    [myRemoteProxy addParamAsInteger: "ValQty" value: 1];    
    [self endEntity];

    [self beginEntity];
    [myRemoteProxy addParamAsInteger: "ModelId" value: 9];
    [myRemoteProxy addParamAsString: "Description" value: "Box1D1M"];
    [myRemoteProxy addParamAsInteger: "ValQty" value: 0];    
    [self endEntity];

    [self beginEntity];
    [myRemoteProxy addParamAsInteger: "ModelId" value: 10];
    [myRemoteProxy addParamAsString: "Description" value: "Flex"];
    [myRemoteProxy addParamAsInteger: "ValQty" value: 2];    
    [self endEntity];
    
    
    [myRemoteProxy sendMessage];

}


/**/
- (void) getAvailableValModels
{
    
    [myRemoteProxy newResponseMessage];
    
    [self beginEntity];
    [myRemoteProxy addParamAsInteger: "ValId" value: 0];
    [myRemoteProxy addParamAsString: "Description" value: "JCM_PUB11_BAG"];
    [self endEntity];

    [self beginEntity];
    [myRemoteProxy addParamAsInteger: "ValId" value: 1];
    [myRemoteProxy addParamAsString: "Description" value: "JCM_WBA_Stacker"];
    [self endEntity];

    [self beginEntity];
    [myRemoteProxy addParamAsInteger: "ValId" value: 2];
    [myRemoteProxy addParamAsString: "Description" value: "JCM_BNF_Stacker"];
    [self endEntity];

    [self beginEntity];
    [myRemoteProxy addParamAsInteger: "ValId" value: 3];
    [myRemoteProxy addParamAsString: "Description" value: "JCM_BNF_BAG"];
    [self endEntity];

    [self beginEntity];
    [myRemoteProxy addParamAsInteger: "ValId" value: 4];
    [myRemoteProxy addParamAsString: "Description" value: "CC_CS_Stacker"];
    [self endEntity];

    [self beginEntity];
    [myRemoteProxy addParamAsInteger: "ValId" value: 5];
    [myRemoteProxy addParamAsString: "Description" value: "CC_CCB_BAG"];
    [self endEntity];

    [self beginEntity];
    [myRemoteProxy addParamAsInteger: "ValId" value: 6];
    [myRemoteProxy addParamAsString: "Description" value: "MEI_S66_Stacker"];
    [self endEntity];
    
    [self beginEntity];
    [myRemoteProxy addParamAsInteger: "ValId" value: 7];
    [myRemoteProxy addParamAsString: "Description" value: "RDM"];
    [self endEntity];
    
    
    [myRemoteProxy sendMessage];    
	
}


/**********************************************************************/
/*ESTADO COMERCIAL*/
/**********************************************************************/
/**/
- (void) getCurrentCommercialState
{
 	id currentState = [[CommercialStateMgr getInstance] getCurrentCommercialState];
    
    [myRemoteProxy newResponseMessage];

    [myRemoteProxy addParamAsInteger: "State" value: [currentState getCommState]];
    
    [myRemoteProxy sendMessage];    
    
}

/**/
- (void) changeCommercialState
{
    // se asume que el cambio de estado comercial es de TEST_STAND_ALONE A PRODUCTION_PIMS
    id commercialState;
    id telesup;
    id telesupScheduler;
    int excode;
    char exceptionDescription[100];
    id commercialStateMgr = [CommercialStateMgr getInstance];
    char msg[35];
    

   	commercialState = [CommercialState new];
	[commercialState setCommState: [[[CommercialStateMgr getInstance] getCurrentCommercialState] getCommState]];
    [commercialState setNextCommState: SYSTEM_PRODUCTION_PIMS];
    
    TRY 
        if (![commercialStateMgr canChangeState: [commercialState getNextCommState] msg: msg]) 
            THROW(RESID_CANNOT_CHANGE_STATE_VERIFY_SYSTEM);

        // comienza el cambio de estado
        telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];

        if (!telesup) 
            THROW(TSUP_PIMS_SUPERVISION_NOT_DEFINED);
        
        telesupScheduler = [TelesupScheduler getInstance];

        if ([telesupScheduler inTelesup]) 
            THROW(RESID_TELESUP_IN_PROGRESS);

        [[CommercialStateMgr getInstance] setPendingCommercialStateChange: commercialState];
        [telesupScheduler setCommunicationIntention: CommunicationIntention_CHANGE_STATE_REQUEST];
        // auditoria intento de supervision por pims
        [Audit auditEventCurrentUser: Event_PIMS_STATE_CHANGE_INTENTION additional: "" station: 0 logRemoteSystem: FALSE]; 			

        [telesupScheduler startTelesup: telesup];

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
    
    [myRemoteProxy sendAckMessage];
}



/*********************************************************************/
/*MENSAJES ASINCRONICOS*/
/*********************************************************************/
- (void) onAsyncMsgDoorState: (char*) aMessageName state: (int) aState period: (int) aPeriod
{
 	GENERIC_PACKAGE pkg;
    char seconds[30];

	pkg = myCommandPackage;
	[pkg clear];
	//[pkg setName: "AsyncMsg"];
    [pkg setName: aMessageName];
	[pkg addParamAsInteger: "State" value: aState];
    [pkg addParamAsInteger: "Period" value: aPeriod];    
	[self sendPackage];

}    


/**/
- (void) onAsyncMsgBillAccepted: (char*) aMessageName acceptorId: (int) anAcceptorId state: (char*) aState currencyCode: (char*) aCurrencyCode 
                    amount: (char*) anAmount deviceName: (char*) aDeviceName qty: (int) aQty
{
 	GENERIC_PACKAGE pkg;
    char seconds[30];

	pkg = myCommandPackage;
	[pkg clear];
	//[pkg setName: "AsyncMsg"];
    [pkg setName: aMessageName];
    [pkg addParamAsInteger: "AcceptorId" value: anAcceptorId];
	[pkg addParamAsString: "State" value: aState];
	[pkg addParamAsString: "CurrencyCode" value: aCurrencyCode];
    [pkg addParamAsString: "Amount" value: anAmount];
	[pkg addParamAsString: "DeviceName" value: aDeviceName];
    [pkg addParamAsInteger: "Qty" value: aQty];

    [self sendPackage];        
}    

/**/
- (void) onAsyncMsgBillRejected: (char*) aMessageName acceptorId: (int) anAcceptorId cause: (char*) aCause qty: (int) aQty
{
 	GENERIC_PACKAGE pkg;
    char seconds[30];

	pkg = myCommandPackage;
	[pkg clear];
	//[pkg setName: "AsyncMsg"];
    [pkg setName: aMessageName];
    [pkg addParamAsInteger: "AcceptorId" value: anAcceptorId];
	[pkg addParamAsString: "Cause" value: aCause];
    [pkg addParamAsInteger: "Qty" value: aQty];

    [self sendPackage];        
    
}


/**/
- (void) onAsyncMsg: (char*) aMessageName code: (char*) aCode description: (char*) aDescription isBlocking: (BOOL) anIsBlocking
{
 	GENERIC_PACKAGE pkg;

	pkg = myCommandPackage;
	[pkg clear];
	//[pkg setName: "AsyncMsg"];
    [pkg setName: aMessageName];
	[pkg addParamAsString: "Code" value: aCode];
	[pkg addParamAsString: "Description" value: aDescription];
    [pkg addParamAsBoolean: "IsBlocking" value: anIsBlocking];

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
                printf(" >>>>>>>>>>>>>> 111\n");
                 [self onDoorStateChange: state period: timerPeriod];
				break;
	
			case OpenDoorStateType_ACCESS_TIME: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_ACCESS_TIME\n");
                timerPeriod = [anObject getPeriod];
                [self onDoorStateChange: state period: timerPeriod];
                printf("access time xxxx\n");
				//[self removeLoggedUsers];		
				break;
	
			case OpenDoorStateType_WAIT_OPEN_DOOR: 
				sprintf(notificationDsc, "%s", getResourceStringDef(RESID_UNDEFINED, "Abrir Puerta")); 
                
                printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>ABRIR PUERTA!!!!!!!!!!!!!!!!!!!!!!! \n");
                //[self onInformAlarm: notificationDsc timeLeft: 0 isBlocking: TRUE];
                timerPeriod = [anObject getPeriod];
                [self onDoorStateChange: state period: timerPeriod];
				break;
	
			case OpenDoorStateType_WAIT_CLOSE_DOOR: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_WAIT_CLOSE_DOOR\n");
                sprintf(notificationDsc, "%s", getResourceStringDef(RESID_UNDEFINED, "Cerrar Puerta"));
                timerPeriod = [anObject getPeriod];
                [self onDoorStateChange: state period: timerPeriod];
				break;

			case OpenDoorStateType_WAIT_CLOSE_DOOR_WARNING: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_WAIT_CLOSE_DOOR_WARNING\n");
				sprintf(notificationDsc, "%s %s ", getResourceStringDef(RESID_UNDEFINED, "Cerrar Puerta"), getResourceStringDef(RESID_UNDEFINED, "Alarma en: "));
                printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>CERRAR PUERTA 1!!!!!!!!!!!!!!!!!!!!!!! \n");
                timerPeriod = [anObject getPeriod];
                [self onDoorStateChange: state period: timerPeriod];
				break;
	
			case OpenDoorStateType_WAIT_CLOSE_DOOR_ERROR: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_WAIT_CLOSE_DOOR_ERROR\n");
				sprintf(notificationDsc, "%s %s", getResourceStringDef(RESID_UNDEFINED, "Cerrar Puerta"), getResourceStringDef(RESID_UNDEFINED, "Error"));
                printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>CERRAR PUERTA 2!!!!!!!!!!!!!!!!!!!!!!! \n");
                timerPeriod = [anObject getPeriod];
                [self onDoorStateChange: state period: timerPeriod];
                break;
	
			case OpenDoorStateType_LOCK_AND_OPEN_DOOR: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_LOCK_AND_OPEN_DOOR\n");
				sprintf(notificationDsc, "%s %s", getResourceStringDef(RESID_UNDEFINED, "Puerta abierta"), getResourceStringDef(RESID_UNDEFINED, "Error"));
                timerPeriod = [anObject getPeriod];
                [self onDoorStateChange: state period: timerPeriod];
				break;
	
			case OpenDoorStateType_WAIT_UNLOCK_WITH_OPEN_DOOR: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_WAIT_UNLOCK_WITH_OPEN_DOOR\n");
				sprintf(notificationDsc, "%s %s", getResourceStringDef(RESID_UNDEFINED, "Destrabar Puerta"), getResourceStringDef(RESID_UNDEFINED, "Error"));
                timerPeriod = [anObject getPeriod];
                [self onDoorStateChange: state period: timerPeriod];
				break;
	
/*			case OpenDoorStateType_WAIT_UNLOCK_ENABLE:
				strcpy(notificationDsc, getResourceStringDef(RESID_UNDEFINED, "Girar llave"));
*/				break;
	
			case OpenDoorStateType_WAIT_LOCK_DOOR: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_WAIT_LOCK_DOOR\n");
				sprintf(notificationDsc, "%s %s", getResourceStringDef(RESID_UNDEFINED, "Trabar Puerta"), getResourceStringDef(RESID_UNDEFINED, "Advertencia en: "));
                timerPeriod = [anObject getPeriod];
                [self onDoorStateChange: state period: timerPeriod];
				break;
	
/*			case OpenDoorStateType_WAIT_LOCK_DOOR_WARNING: 
				sprintf(notificationDsc, "%s %s", getResourceStringDef(RESID_UNDEFINED, "Trabar Puerta"), getResourceStringDef(RESID_UNDEFINED, "Alarma en: "));
				break;
 */
			case OpenDoorStateType_WAIT_LOCK_DOOR_ERROR: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_WAIT_LOCK_DOOR_ERROR\n");
				sprintf(notificationDsc, "%s %s", getResourceStringDef(RESID_UNDEFINED, "Trabar puerta"), getResourceStringDef(RESID_UNDEFINED, "Error"));
                timerPeriod = [anObject getPeriod];
                [self onDoorStateChange: state period: timerPeriod];
				break;

	
			case OpenDoorStateType_OPEN_DOOR_VIOLATION: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_OPEN_DOOR_VIOLATION\n");
				strcpy(notificationDsc, getResourceStringDef(RESID_UNDEFINED, "Violacion de Seguridad"));
                [self onDoorStateChange: state period: 0];
				break;

			case OpenDoorStateType_WAIT_OUTER_DOOR_OPEN: 
                printf(" >>>>>>>>>>>>>> OpenDoorStateType_WAIT_OUTER_DOOR_OPEN\n");
				strcpy(notificationDsc, getResourceStringDef(RESID_UNDEFINED, "Wait Outer Door Open"));
                [self onDoorStateChange: state period: 0];
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
    printf("execute request\n");
	switch (myReqType) {
        
		case USER_LOGIN_REQ:
			[self userLogin];
			return;

		case USER_HAS_CHANGE_PIN_REQ:
			[self hasUserChangePin];
			return;

		case USER_CHANGE_PIN_REQ:
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
            
        case START_MANUAL_DROP_REQ:
            [self startManualDrop];
            return;
            
        case ADD_MANUAL_DROP_DETAIL_REQ:
            [self addManualDropDetail];
            return;
            
        case PRINT_MANUAL_DROP_RECEIPT_REQ:
            [self printManualDropReceipt];
            return;
            
        case CANCEL_MANUAL_DROP_REQ:
            [self cancelManualDrop];
            return;
            
        case FINISH_MANUAL_DROP_REQ:              
            [self finishManualDrop];
            return;
            
        case START_VALIDATION_MODE_REQ:
            printf("start validation mode\n");
            [self startValidationMode];
            return;
            
        case STOP_VALIDATION_MODE_REQ:
            [self stopValidationMode];
            return;
           
        case GENERATE_OPERATOR_REPORT_REQ:
            [self generateOperatorReport];
            return;
            
        case HAS_ALREADY_PRINT_END_DAY_REQ:
            [self hasAlreadyPrintEndDay];
            return;
            
        case GENERATE_END_DAY_REQ:            
            [self generateEndDay];
            return;
            
        case GENERATE_ENROLLED_USERS_REPORT_REQ:
            [self generateEnrolledUsersReport];
            return;
            
        case GENERATE_AUDIT_REPORT_REQ:
            [self generateAuditReport];
            return;
            
        case GENERATE_CASH_REPORT_REQ:
            [self generateCashReport];
            return;
            
        case GENERATE_X_CLOSE_REPORT_REQ:
            [self generateXCloseReport];
            return;
            
        case GENERATE_REFERENCE_REPORT_REQ:
            [self generateReferenceReport];
            return;
            
        case GENERATE_SYSTEM_INFO_REPORT_REQ:
            [self generateSystemInfoReport];
            return;
            
        case GENERATE_TELESUP_REPORT_REQ:
            [self generateTelesupReport];
            return;
            
        case REPRINT_DEPOSIT_REQ:
            [self reprintDeposit];
            return;
            
        case REPRINT_EXTRACTION_REQ:
            [self reprintExtraction];
            return;
            
        case REPRINT_END_DAY_REQ:
            [self reprintEndDay];
            return;
            
        case REPRINT_PARTIAL_DAY_REQ:                   
            [self reprintPartialDay];
            return;
            
        case START_MANUAL_TELESUP_REQ:
            [self startManualTelesup];
            return;
            
        case ACCEPT_INCOMING_SUP_REQ:
            [self acceptIncomingSupervision];
            return;

        case GET_DATETIME_REQ:
            [self sendDateTime];
            return;            

        case IS_VALIDATION_MODE_AVAILABLE_REQ:
            [self isValidationModeAvailable];
            return;            
            
        case GET_BOX_MODEL_REQ:
            [self getBoxModel];
            return;
            
        case SET_BOX_MODEL_REQ:
            [self setBoxModel];
            return;
            
        case HAS_MOVEMENTS_REQ:
            [self hasMovements];
            return;
            
        case GET_AVAILABLE_BOX_MODELS_REQ:
            [self getAvailableBoxModels];
            return;
            
        case GET_AVAILABLE_VAL_MODELS_REQ:                
            [self getAvailableValModels];
            return;
            
        case GET_CURRENT_COMMERCIAL_STATE_REQ:
            [self getCurrentCommercialState];
            return;
            
        case CHANGE_COMMERCIAL_STATE_REQ:
            [self changeCommercialState];
            return;
            
        case ENABLE_MAILBOX_REQ:
            [self enableMailbox];
            return;
            
        case DISABLE_MAILBOX_REQ:
            [self disableMailbox];
            return;

		default: break;		

	}

	THROW_FMT(TSUP_INVALID_OPERATION_EX, "ReqType=%d", myReqType);
	printf("SystemOpRequest -> Unknown operation\n");

}

@end
