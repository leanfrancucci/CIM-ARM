#include "AsyncMsgThread.h"
struct printf;

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

/**/
- (void) addAsynMsg:  (char*) aDescription/*(int) anAlarmType isBlocking: (BOOL) anIsBlocking*/
{
	AsyncMsg *aMsg;

	// solo agrego la alarma si NO hay una supervison al POS
	aMsg = malloc(sizeof(AsyncMsg));

    stringcpy(aMsg->description, aDescription);
    //aMsg->isBlocking = anIsBlocking;
    //aMsg->dateTime = [SystemTime getLocalTime];
    
	[mySyncQueue pushElement: aMsg];	
}


/**/
- (void) processAlarm: (AsyncMsg*) aMsg
{
    id request;
  //  id remoteConsole = [RemoteConsole getInstance];
    

    if (mySystemOpRequest) {
        [mySystemOpRequest onAsyncMsg: aMsg->description];
        
    }
}


/**/
- (void) run 
{
	AsyncMsg *aMsg;

	printf("Iniciando hilo de mensajes asinc....");


	while (TRUE) {

       printf("RUN 1\n");
		TRY
printf("RUN 2\n");
		
			aMsg = [mySyncQueue popElement];
        printf("RUN 1\n");
		
            if (aMsg == NULL) BREAK_TRY;
printf("RUN 3\n");
		
			[self processAlarm: aMsg];

printf("RUN 4\n");
		
		CATCH

			printf("Excepcion en el hilo de alarmas...");
			//LOG_EXCEPTION(LOG_TELESUP);

		END_TRY
printf("RUN 5\n");
		
		
	}
  

    printf( "Saliendo del hilo de alarmas");
    //myTerminated = TRUE;
  
}



@end
