#ifndef CDM3000_COMM_H
#define CDM3000_COMM_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "JcmThread.h"

typedef struct {
	long long amount;
	int qty;
} DenominationCount;

typedef void( *cdmComunicationErrorNotif )( int devId, int cause );
typedef void( *changeCdmStatusNotif )( int devId, unsigned char newStatus );
typedef void( *coinsAcceptedNotif )( int devId, DenominationCount* coinsAccepted, int failureCount );

//pending status:
typedef enum {
	NO_ACTION = 0, START_PENDING, STOP_PENDING
} PendinStatus;

typedef enum {
	CDM_NOERROR = 0, CDM_COINJAM, CDM_BOXFULL, CDM_COINUNDERSENSOR, CDM_COVEROPEN, CDM_PRESSRAIL, CDM_CASEFULL,CDM_BATCHOK, CDM_COMMERROR 
} ErrorStatusCodes;

typedef struct {
	int devId;
	OS_HANDLE 	osHandle;
	unsigned char writeBuf[100];
	unsigned char readBuf[400];
	unsigned short framesQty;
	//datos de la ultima cuenta realizada:
	DenominationCount countingResult[9];
	int failureCount;
	int pendingStatus;
	int clearPending;
	cdmComunicationErrorNotif commErrorNotificationFcn;
	changeCdmStatusNotif changeCdmStatusFcn;
	coinsAcceptedNotif coinsAcceptedFcn;
  	unsigned char motorRunning; // enabled, disabled, UPDATING FIRMWARE ?
  	unsigned char errorStatus;
	unsigned char coinsAcceptedNotifMissing;
	int errorQty;
	int resetQty;
	JCM_THREAD cdmThread;
} Cdm3000Data;


Cdm3000Data *cdmNew( int portNumber, int devId, cdmComunicationErrorNotif commErrorNotifFcn, changeCdmStatusNotif changeCdmStatus, coinsAcceptedNotif coinsAccepted );
void cdmStartCounting( Cdm3000Data *cdmCounter );
void cdmStopCounting( Cdm3000Data *cdmCounter );
void cdmRun( Cdm3000Data *cdmCounter );
void cdmClearCounter( Cdm3000Data *cdmCounter );
//DenominationCount * cdmGetLastCount( Cdm3000Data *cdmCounter,  );
int cdmGetCountingStatus( Cdm3000Data *cdmCounter );

int TEST_CDM_COM( char portNumber );


#endif