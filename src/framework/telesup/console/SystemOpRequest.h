#ifndef SYSTEM_OP_REQUEST_H
#define SYSTEM_OP_REQUEST_H

#define SYSTEM_OP_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "Request.h"
#include "cl_genericpkg.h"
#include "system/os/all.h"
#include "Request.h"
#include "system/os/all.h"
#include "CimCash.h"
#include "Currency.h"

#include "Deposit.h"


typedef enum {
	LoginModeType_UNDEFINED,
	LoginModeType_CANCEL_TIME,
	LoginModeType_LOGIN_FOR_DOOR_ACCESS
} LoginModeType;

/**
 *	
 */
@interface SystemOpRequest: Request
{
	GENERIC_PACKAGE myPackage;
	GENERIC_PACKAGE myResponsePackage;
	GENERIC_PACKAGE myCommandPackage;
	OMUTEX myMutex;
	REMOTE_PROXY myEventsProxy;
	char *myResponseBuffer;

    
    //
    DEPOSIT myDeposit;
    USER user;
}		

/**/
- (void) setEventsProxy: (REMOTE_PROXY) anEventsProxy;

/**/
- (void) sendPackage: (GENERIC_PACKAGE) aPkg;
- (void) sendPackage;

/**/
- (void) beginEntity;
- (void) endEntity;

/**/
- (void) addParamsFromMap: (MAP) aMap;

/**/
- (void) setEventsProxy: (id) anEventsProxy;



- (void) readResponse;


- (void) onBillAccepted: (id) anAcceptor currency: (CURRENCY) aCurrency amount: (money_t) anAmount;

- (void) onBillAccepted: (id) anAcceptor currency: (CURRENCY) aCurrency amount: (money_t) anAmount deviceDsc: (char*) aDeviceDsc currencyTotal: (money_t) aCurrencyTotal qty: (int) aQty currencyQty: (int) aCurrencyQty rejectedQty: (int) aRejectedQty ;

- (void) onBillRejected: (id) anAcceptor cause: (int) aCause deviceDsc: (char*) aDeviceDsc qty: (int) aQty rejectedQty: (int) aRejectedQty ;


- (void) onAsyncMsg: (char*) aDescription;

/*
- (void) onBillAccepting: (id) anAcceptor;

- (void) onOperationCompleted: (int) anErrorCode errorDescription: (char *) anErrorDescription;

- (void) onExtractionStateChange: (char*) aStateStr timeStr: (char*) aTimeStr state: (int) aState;

- (void) onFinishDrop: (CIM_CASH) aCash;

- (void) onCancelDrop: (CIM_CASH) aCash;

- (void) onInformAlarm: (datetime_t) aDateTime entityId: (int) anEntityId alarmType: (int) anAlarmType alarmDsc: (char*) anAlarmDsc expectedResponseType: (int) anExpectedResponseType isBlocking: (BOOL) anIsBlocking secondsTimerAlarm: (int) aSecondsTimerAlarm countDown: (BOOL) aCountDown additional: (char*) anAdditional;

- (void) onConnectGprs: (int) aModemSpeed apn: (char*) anApn phoneNumber: (char*) aPhoneNumber user: (char*) aUser password: (char*) aPassword;

- (BOOL) onIsConnectedGprs;

- (void) onDisconnectGprs;
*/
@end

#endif
