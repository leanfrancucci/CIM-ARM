#ifndef ASYNC_MSG_THREAD_H
#define ASYNC_MSG_THREAD_H

#define ASYNC_MSG_THREAD id

#include <Object.h>
#include "system/os/all.h"
#include "JExceptionForm.h"
#include "system/util/all.h"
#include "ctapp.h"

typedef enum {
	AsyncMsgType_DoorState,
	AsyncMsgType_AsyncMsg,
    AsyncMsgType_BillAccepted,
    AsyncMsgType_BillRejected
} AsyncMsgType; 

typedef enum {
	AsyncMsgCode_StartIncomingSupervision,
	AsyncMsgCode_FinishIncomingSupervision,
} AsyncMsgCode; 


typedef struct {
    AsyncMsgType msgType;
    char messageName[200];
    int state;
    int period;
    int acceptorId;
    char stateDsc[30];
    char currencyCode[10];
    char amount[30];
    char deviceName[50];
    int qty;
    char code[20];
    char aDescription[60];
    BOOL isBlocking;
    char rejectedCause[100];
} AsyncMsg;



/**
 *	doc template
 */
@interface AsyncMsgThread : OThread
{
	SYNC_QUEUE mySyncQueue;
	BOOL myWait;
    id mySystemOpRequest;
    id myEventsProxy;
    id myErrorSystemOpRequest;
}

+ getInstance;

/**/
- (void) addAsyncMsgDoorState: (int) aState period: (int) aPeriod;
- (void) addAsyncMsgBillAccepted: (int) anAcceptorId state: (char*) aState
                                                        currencyCode: (char*) aCurrencyCode
                                                        amount: (money_t) anAmount 
                                                        deviceName: (char*) aDeviceName
                                                        qty: (int) aQty;
- (void) addAsyncMsgBillRejected: (int) anAcceptorId cause: (char*) aCause qty: (int) aQty;
- (void) addAsyncMsg: (char*) aCode description: (char*) aDescription isBlocking: (BOOL) anIsBlocking; 
- (void) setSystemOpRequest: (id) anObject;
- (void) setEventsProxy: (id) anEventsProxy;

@end

#endif
