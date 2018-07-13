#include "AsyncMsgThread.h"
#include "SystemOpRequest.h"


@implementation AsyncMsgThread

static ASYNC_MSG_THREAD singleInstance = NULL; 

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}
 
/**/
- initialize
{
    printf("Inicializando AsyncMsgThread\n");
	mySyncQueue = [SyncQueue new];
    mySystemOpRequest = NULL;
    myEventsProxy = NULL;
    myErrorSystemOpRequest = NULL;
	return self;
}

/**/
+ getInstance
{
  return [self new];
}

/**/
- (void) setSystemOpRequest: (id) anObject
{
    mySystemOpRequest = anObject;
}    

- (void) setEventsProxy: (id) anEventsProxy
{
    myEventsProxy = anEventsProxy;
    if (myErrorSystemOpRequest == NULL) {
        myErrorSystemOpRequest = [SystemOpRequest new];
        [myErrorSystemOpRequest setEventsProxy: myEventsProxy];
    }

}    
    
/**/
- (void) addAsyncMsgDoorState: (int) aState period: (int) aPeriod
{
	AsyncMsg *aMsg;

	// solo agrego la alarma si NO hay una supervison al POS
	aMsg = malloc(sizeof(AsyncMsg));

    aMsg->msgType = AsyncMsgType_DoorState;
    stringcpy(aMsg->messageName, "DoorStateChange");
    aMsg->state = aState;
    aMsg->period = aPeriod;
    //aMsg->isBlocking = anIsBlocking;
    //aMsg->dateTime = [SystemTime getLocalTime];
    
    [mySyncQueue pushElement: aMsg];    
}    

/**/
- (void) addAsyncMsgBillAccepted: (int) anAcceptorId state: (char*) aState
                                                        currencyCode: (char*) aCurrencyCode
                                                        amount: (money_t) anAmount 
                                                        deviceName: (char*) aDeviceName
                                                        qty: (int) aQty
{
	AsyncMsg *aMsg;
    char amountstr[50];

	// solo agrego la alarma si NO hay una supervison al POS
	aMsg = malloc(sizeof(AsyncMsg));

    aMsg->msgType = AsyncMsgType_BillAccepted;
    stringcpy(aMsg->messageName, "BillAccepted");
    aMsg->acceptorId = anAcceptorId;
    stringcpy(aMsg->stateDsc, aState);
    stringcpy(aMsg->currencyCode, aCurrencyCode);
    formatMoney(amountstr, "", anAmount * aQty, 2, 20);
    stringcpy(aMsg->amount, amountstr);
    stringcpy(aMsg->deviceName, aDeviceName);
    aMsg->qty = aQty;

    //aMsg->isBlocking = anIsBlocking;
    //aMsg->dateTime = [SystemTime getLocalTime];
    
    [mySyncQueue pushElement: aMsg];    
    
}

/**/
- (void) addAsyncMsgBillRejected: (int) anAcceptorId cause: (char*) aCause qty: (int) aQty
{
	AsyncMsg *aMsg;

	// solo agrego la alarma si NO hay una supervison al POS
	aMsg = malloc(sizeof(AsyncMsg));

    aMsg->msgType = AsyncMsgType_BillRejected;
    stringcpy(aMsg->messageName, "BillRejected");
    aMsg->acceptorId = anAcceptorId;
    stringcpy(aMsg->rejectedCause, aCause);
    aMsg->qty = aQty;

    [mySyncQueue pushElement: aMsg];    
    
}

  
/**/

- (void) addAsyncMsg: (char*) aCode description: (char*) aDescription isBlocking: (BOOL) anIsBlocking 
{
	AsyncMsg *aMsg;

	// solo agrego la alarma si NO hay una supervison al POS
	aMsg = malloc(sizeof(AsyncMsg));

    aMsg->msgType = AsyncMsgType_AsyncMsg;
    stringcpy(aMsg->messageName, "OnAsyncMsg");
    stringcpy(aMsg->code, aCode);
    stringcpy(aMsg->aDescription, aDescription);
    aMsg->isBlocking = anIsBlocking;

    //aMsg->isBlocking = anIsBlocking;
    //aMsg->dateTime = [SystemTime getLocalTime];
    
    [mySyncQueue pushElement: aMsg];    

}

/**/
- (void) processAlarm: (AsyncMsg*) aMsg
{
  //  id remoteConsole = [RemoteConsole getInstance];
    
    printf("procesa un mensaje\n");
        
        
        switch(aMsg->msgType) {
            
            case AsyncMsgType_DoorState:
                if (mySystemOpRequest) 
                    [mySystemOpRequest onAsyncMsgDoorState: aMsg->messageName state: aMsg->state period: aMsg->period];
                else printf("NO EXISTE SYSTEM OP REQUEST\n");
                
                break;
            
        
            case AsyncMsgType_BillAccepted:
                if (mySystemOpRequest) 
                    [mySystemOpRequest onAsyncMsgBillAccepted: aMsg->messageName acceptorId: aMsg->acceptorId state: aMsg->stateDsc currencyCode: aMsg->currencyCode 
                                                                        amount: aMsg->amount deviceName: aMsg->deviceName qty: aMsg->qty];
                else printf("NO EXISTE SYSTEM OP REQUEST\n");                                                                        

                break;
                
            case AsyncMsgType_BillRejected:
                if (mySystemOpRequest) 
                    [mySystemOpRequest onAsyncMsgBillRejected: aMsg->messageName acceptorId: aMsg->acceptorId cause: aMsg->rejectedCause qty: aMsg->qty];
                else printf("NO EXISTE SYSTEM OP REQUEST\n");                                                                        

                break;                
                
            case AsyncMsgType_AsyncMsg:
                printf("AsyncMsgType_AsyncMsg\n");
                
                if (myErrorSystemOpRequest) 
                    [myErrorSystemOpRequest onAsyncMsg: aMsg->messageName code: aMsg->code description: aMsg->aDescription isBlocking: aMsg->isBlocking];
                else printf("NO EXISTE ERROR SYSTEM OP REQUEST\n");                                                                        
                
                break;
            
            default: 
                break;
            
        }
            
}


/**/
- (void) run 
{
	AsyncMsg *aMsg;

	printf("Iniciando hilo de mensajes asinc....\n");


	while (TRUE) {

		TRY
		
			aMsg = [mySyncQueue popElement];
		
            if (aMsg == NULL) BREAK_TRY;
		
			[self processAlarm: aMsg];

		
		CATCH

			printf("Excepcion en el hilo de alarmas...");
			//LOG_EXCEPTION(LOG_TELESUP);

		END_TRY

		
	}
  

    printf( "Saliendo del hilo de alarmas");
    //myTerminated = TRUE;
  
}



@end
