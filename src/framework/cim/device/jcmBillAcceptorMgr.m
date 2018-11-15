#include <math.h>
#include <string.h>
#include "system/util/all.h"
#include "jcmBillAcceptorComm.h"
#include "jcmBillAcceptorMgr.h"
#include "CimManager.h"
#include "safeBoxMgr.h"
#include "system/util/endian.h"
#include "id0003Mapping.h"

#define FIRM_UPD_DATA_SIZE		246


typedef struct {
	unsigned char status;
	int billStackedQty;
	int amount;
	int currencyId;
} TempValInfo;

TempValInfo aTempValInfo;

void openValStatusFile(JcmBillAcceptData *jcmBillAcceptor)
{
    char * valStatusFile[15]; 

    sprintf(valStatusFile, "%s%d", "valStatus",  jcmBillAcceptor->devId);
	jcmBillAcceptor->fpValStat  = openCreateFile( valStatusFile);
}

unsigned char getValStatus(JcmBillAcceptData *jcmBillAcceptor, int* billQty, int * amount, int * curId )
{

    fseek( jcmBillAcceptor->fpValStat, 0, SEEK_SET );
	if (!fread(&aTempValInfo, sizeof(TempValInfo),1,jcmBillAcceptor->fpValStat)){
		aTempValInfo.status = 0;
		*amount = 0;
		*billQty = 0;
		*curId =0;
	}else{
		*amount = aTempValInfo.amount;
		*billQty = aTempValInfo.billStackedQty;
		*curId =aTempValInfo.currencyId;
	} 
	
	//printf("GetValStatus Val: %d Status: %d  amount %d curId %d billQty %d\n", jcmBillAcceptor->devId, aTempValInfo.status, *amount, *curId, *billQty );//fflush(stdout);

	return aTempValInfo.status;
}

void setValStatus(JcmBillAcceptData *jcmBillAcceptor, unsigned char newStatus, int billQty, int amount, int currencyId)
{
    printf("***************************** setValStatussssssssssssssssssssssssssssss  %d\n", newStatus);
	aTempValInfo.status = newStatus;
	aTempValInfo.billStackedQty = billQty;
	aTempValInfo.amount = amount;
	aTempValInfo.currencyId = currencyId;

	//printf( "SetValStatus Val: %d Status: %d billQty %d amount %d curId %d\n", jcmBillAcceptor->devId, newStatus, billQty, amount, currencyId);
    fseek( jcmBillAcceptor->fpValStat, 0, SEEK_SET );
	fwrite( &aTempValInfo, sizeof(aTempValInfo), 1, jcmBillAcceptor->fpValStat );
	fflush(jcmBillAcceptor->fpValStat);
    if (fsync(fileno(jcmBillAcceptor->fpValStat))!= 0)
        printf( "SetValStatus Val: %d Status: %d fsyn failed!\n", jcmBillAcceptor->devId, newStatus);

}


/* Eventos - se corresponden con los estados obtenidos del validador */


void billAcceptWriteRead( JcmBillAcceptData *jcmBillAcceptor, unsigned char cmd, unsigned char * data, int dataLen )
{
	unsigned char devRead; 
	
	jcmWrite(jcmBillAcceptor->devId, jcmBillAcceptor->protocol, cmd, data, dataLen);

	if ( jcmBillAcceptor->protocol == CCNET &&  cmd == 0x50 && *data == 0x02 ) {
		//doLog(0,"Wait1\n");
		msleep(400);
	}

	jcmBillAcceptor->dataEvPtr = jcmRead( &devRead, jcmBillAcceptor->protocol, &jcmBillAcceptor->dataLenEvt );
	
	if (( jcmBillAcceptor->dataEvPtr!= NULL ) && ( devRead == jcmBillAcceptor->devId )){
		if ( jcmBillAcceptor->protocol == ID003 ){
			jcmBillAcceptor->event = *jcmBillAcceptor->dataEvPtr;
			++jcmBillAcceptor->dataEvPtr;
		} else {
			switch (cmd) {
				case 0x33:
					jcmBillAcceptor->event = *jcmBillAcceptor->dataEvPtr;
					++jcmBillAcceptor->dataEvPtr;
					break;
				case 0x37: 
					jcmBillAcceptor->event = 0x88;
					break;
				case 0x41:
					jcmBillAcceptor->event = 0x8A;	
					break;
				case 0x50:
					jcmBillAcceptor->event = 0x50;
					if ( dataLen ){
						if ( *data != 0x30 ) jcmBillAcceptor->event += *data;	
						else jcmBillAcceptor->event = 0x30; //invalida cmd	
					}
					break;
				default:
					jcmBillAcceptor->event = cmd;
			}

		}
		
		jcmBillAcceptor->commErrQty = 0;
		executeStateMachine(jcmBillAcceptor->billValidStateMachine, jcmBillAcceptor->event);
		return;
	} 
	
	doLog(1,"Error W/R Val: %d \n", jcmBillAcceptor->devId); fflush(stdout);

	jcmBillAcceptor->commErrQty++;
	if ( jcmBillAcceptor->commErrQty > 3 ) {
		if ( jcmBillAcceptor->protocol == ID003 ){
			jcmBillAcceptor->event = ID003_COMM_ERROR;
		} else
			jcmBillAcceptor->event = CCNET_COMM_ERROR;
		executeStateMachine( jcmBillAcceptor->billValidStateMachine, jcmBillAcceptor->event );
	}
}

/*

	Funciones de notificacion a APP:
	
*/

void notifyBillAccepted(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;

	//doLog(0,"NOTIFY BILL ACCEPTED -------------- AMOUNT = %lld\n", jcmBillAcceptor->amountChar);

	if ( jcmBillAcceptor->billAcceptNotificationFcn != NULL &&  jcmBillAcceptor->amountChar != -1  ) {

		( *jcmBillAcceptor->billAcceptNotificationFcn )( jcmBillAcceptor->devId, jcmBillAcceptor->amountChar, jcmBillAcceptor->currencyId, 1 );
		
		//doLog(0,"NOTIFICA\n");

		jcmBillAcceptor->amountChar = -1;

	}
}

void sendRejectNotification(StateMachine *sm)
{
	unsigned char rejectCause;
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	rejectCause = mapRejectCause( jcmBillAcceptor->protocol, (unsigned char) *jcmBillAcceptor->dataEvPtr );
	if ( jcmBillAcceptor->billRejectNotificationFcn != NULL ){
		( *jcmBillAcceptor->billRejectNotificationFcn )( jcmBillAcceptor->devId, rejectCause );
		jcmBillAcceptor->lastRejectCause = rejectCause;  
		jcmBillAcceptor->errorCause = ID003_REJECTING;	
	} 
}

void notifyFirmwareUpdate( StateMachine *sm, unsigned char result )
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//doLog(0,"notify firmware update %d \n", result);fflush(stdout);
	jcmBillAcceptor->firmImage = NULL;
	jcmBillAcceptor->canResetVal = 1;
	if ( jcmBillAcceptor->firmwareUpdateProgress != NULL )
		( *jcmBillAcceptor->firmwareUpdateProgress )( jcmBillAcceptor->devId, result );
}

/*

	LOAD FUNCTIONS
	
*/

void loadNoComm(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//doLog(0,"JCM loadNoCOMM\n");fflush(stdout);
    *jcmBillAcceptor->jcmVersion = jcmBillAcceptor->billTableLoaded = 0; 
	jcmBillAcceptor->resetSentQty = 0;		//limpia el flag para q empiece nuevamente a enviar resets de ser necesario
}

void loadDisable(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	//doLog(0,"JCM loadDisable\n");fflush(stdout);
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	jcmBillAcceptor->canChangeStatus = 1;
}

void loadEnable(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	//doLog(0,"JCM loadEnable\n");fflush(stdout);
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	jcmBillAcceptor->canChangeStatus = 1;
	jcmBillAcceptor->appNotifPowerUpBill = 0;
}



void loadReceivingBill(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	jcmBillAcceptor->canChangeStatus = 0;
	if ( jcmBillAcceptor->acceptingNotificationFcn != NULL )
		( *jcmBillAcceptor->acceptingNotificationFcn )( jcmBillAcceptor->devId, ID003_ACCEPTING );

	//doLog(0,"JCM LoadReceivBill\n");fflush(stdout);
}




/*
	OTHER FUNCTIONS
*/





void doDisable(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	unsigned char val;
	unsigned char enableBillTypes[6];
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//doLog(0,"JCM doDisable! %d\n", jcmBillAcceptor->devId ); fflush(stdout);
	if ( jcmBillAcceptor->protocol == ID003 ) {
		val = 1;
		billAcceptWriteRead( jcmBillAcceptor, getCommandCode(jcmBillAcceptor->protocol,DISABLE_CMD), &val, 1 );
	} else {
		memset(enableBillTypes, 0, 6);
		billAcceptWriteRead( jcmBillAcceptor, getCommandCode(jcmBillAcceptor->protocol,DISABLE_CMD), enableBillTypes, 6 );
	}
}

void doEnable(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	unsigned char val;
	unsigned char enableBillTypes[6];
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//doLog(0,"JCM doEnable!! %d\n", jcmBillAcceptor->devId ); fflush(stdout);
	if ( jcmBillAcceptor->protocol == ID003) {

		val = 0;
		billAcceptWriteRead( jcmBillAcceptor, getCommandCode(jcmBillAcceptor->protocol,DISABLE_CMD), &val, 1 );

	} else {
		memset(enableBillTypes, 0xFF, 6);	// Con Scrow
		billAcceptWriteRead( jcmBillAcceptor, getCommandCode(jcmBillAcceptor->protocol,DISABLE_CMD), enableBillTypes, 6 );
	}
}

void sendAckNotification(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	jcmWrite( jcmBillAcceptor->devId, jcmBillAcceptor->protocol, getCommandCode(jcmBillAcceptor->protocol,ACK_CMD), NULL, 0 );
//	doLog(0,"Wait2\n");

	// @todo: ver este codigo, inicialmente habia un msleep(500) para todos los casos, pero para cash code
	// habia un delay importante para el BULK, por ahora lo puse con un mseep mas chico para este caso, pero
	// seria recomentable ver en que casos se necesita hacer un msleep tan grande

	if (jcmBillAcceptor->protocol == CCNET) msleep(40);
	else msleep(500);
}

void sendVendValidNotification(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	char billDisabled;
	unsigned char index;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;

	// Solo para CCNET analizo los montos en este momento para los demas ya los tengo del SCROW
	if (jcmBillAcceptor->protocol == CCNET) {
		index = (unsigned char) *jcmBillAcceptor->dataEvPtr;
		jcmBillAcceptor->amountChar = (long long)jcmBillAcceptor->convertionTable[index ].amount * MultipApp;
		jcmBillAcceptor->currencyId = jcmBillAcceptor->convertionTable[index ].currencyId;
		billDisabled = jcmBillAcceptor->convertionTable[index].disabled;
	//	doLog(0, "JCM disabled %d, $ %d %d\n", billDisabled, jcmBillAcceptor->convertionTable[index ].amount, jcmBillAcceptor->currencyId );fflush(stdout);
	}

	//doLog(0,"* Vend Valid *\n");

	sendAckNotification(sm);
	notifyBillAccepted( sm );
	//para que si tiene q resetear el validador se limpie este flag. En ccnet sino no se limpia cuando stackea directo..
	jcmBillAcceptor->resetSentQty = 0;

}


void printAny(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//doLog(0,"Any event %d\n", jcmBillAcceptor->event);fflush(stdout);
}

void processFirmwareVersion(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	memcpy( jcmBillAcceptor->jcmVersion, jcmBillAcceptor->dataEvPtr, jcmBillAcceptor->dataLenEvt);
	jcmBillAcceptor->jcmVersion[jcmBillAcceptor->dataLenEvt] = 0;

	if ( jcmBillAcceptor->protocol == CCNET){
		jcmBillAcceptor->jcmVersion[27] = 0;	// 15 Version + 12 Serial
	}
	
	doLog(0,"FirmwVersion %s\n",  jcmBillAcceptor->jcmVersion); fflush(stdout);

}

typedef struct {
	unsigned char val;
	char country[3];
	unsigned char tzeros;
} CCNET_CUR;

typedef struct {
	unsigned char escrowCode;
	unsigned char countryCode;
	unsigned char val;
	unsigned char tzeros;
} JCM_CUR;

void processCurrencyAssignment(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	int i, multip;
	CCNET_CUR *ccnetBillTable;
	JCM_CUR *jcmBillTable;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//doLog(0,"len currency %d\n", jcmBillAcceptor->dataLenEvt); fflush(stdout);
	memset( jcmBillAcceptor->convertionTable, 0, sizeof(jcmBillAcceptor->convertionTable));

	if ( jcmBillAcceptor->protocol == ID003 ){
		jcmBillTable = (JCM_CUR *)jcmBillAcceptor->dataEvPtr;
		for ( i = 0	; i < 8; i++  ){
			if ( jcmBillTable->countryCode != 0 ){
				jcmBillAcceptor->countryCode = getCurrencyIdFromJcm ( jcmBillTable->countryCode );
				jcmBillAcceptor->convertionTable[jcmBillTable->escrowCode - 0x61].countryCode = jcmBillTable->countryCode; 				
				multip = pow(10, jcmBillTable->tzeros );
				jcmBillAcceptor->convertionTable[jcmBillTable->escrowCode - 0x61].amount = ( jcmBillTable->val * multip );
				jcmBillAcceptor->convertionTable[jcmBillTable->escrowCode - 0x61].currencyId = getCurrencyIdFromJcm ( jcmBillTable->countryCode );
			    doLog(0,"JCM $ %d Country %d\n", jcmBillAcceptor->convertionTable[jcmBillTable->escrowCode - 0x61].amount, jcmBillAcceptor->convertionTable[jcmBillTable->escrowCode - 0x61].countryCode ); fflush(stdout);
			}	
		    jcmBillTable++;
		}
		//doLog(0,"country code %d\n", jcmBillAcceptor->countryCode ); fflush(stdout);
	} else {
		if ( *jcmBillAcceptor->dataEvPtr != 0x30 ) {
			jcmBillAcceptor->countryCode = 0;
			ccnetBillTable = (CCNET_CUR *)jcmBillAcceptor->dataEvPtr;
			for ( i = 0	; i < 24; ++i ){
				multip = pow(10, ccnetBillTable->tzeros );
				jcmBillAcceptor->convertionTable[i].amount = ( ccnetBillTable->val * multip );
				memcpy(jcmBillAcceptor->convertionTable[i].countryStr, ccnetBillTable->country,  3 );
				jcmBillAcceptor->convertionTable[i].countryStr[3] = 0;
				jcmBillAcceptor->convertionTable[i].currencyId = getCurrencyIdFromCashCode( jcmBillAcceptor->convertionTable[i].countryStr );
				if ( jcmBillAcceptor->countryCode == 0  ){
					jcmBillAcceptor->countryCode = jcmBillAcceptor->convertionTable[i].currencyId;
				    //doLog(0,"JCMBillAcceptorMgr - Currency Id Assignment: index %d country %s currency %d\n", i, jcmBillAcceptor->convertionTable[i].countryStr, jcmBillAcceptor->convertionTable[i].currencyId ); fflush(stdout);
				} 

			    //doLog(0,"CCNET $ %d country %s curId %d\n", jcmBillAcceptor->convertionTable[i].amount, jcmBillAcceptor->convertionTable[i].countryStr, jcmBillAcceptor->convertionTable[i].currencyId ); fflush(stdout);
			    ccnetBillTable++;
			}
		} else return;
	}
	jcmBillAcceptor->billTableLoaded = 1;
    doLog(0,"jcmBillAcceptor->billTableLoaded\n"); fflush(stdout);

}

BOOL initDataMissing(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	
	if ( jcmBillAcceptor->protocol == CCNET ) {
		if ( jcmBillAcceptor->event == CCNET_IDLING && ( !jcmBillAcceptor->billTableLoaded || *jcmBillAcceptor->jcmVersion == 0)){
			doDisable(sm);
			return 1;
		}
	}
	
	if ( !jcmBillAcceptor->billTableLoaded ) {
		//doLog(0,"JCM requestCurrency! \n" ); fflush(stdout);
		billAcceptWriteRead( jcmBillAcceptor, getCommandCode(jcmBillAcceptor->protocol,CURRENCY_CMD), NULL, 0 );
		return 1;
	}
	if ( *jcmBillAcceptor->jcmVersion == 0 ){
		//doLog(0,"JCM requestVersion! \n" ); fflush(stdout);
		billAcceptWriteRead( jcmBillAcceptor, getCommandCode(jcmBillAcceptor->protocol,IDENTIF_CMD), NULL, 0 );
		return 1;
	}

	return 0;
}




BOOL isOnPowerUpStatus(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	unsigned char powerUpStat = 0;
	unsigned char eventCallb;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
		
	if ( jcmBillAcceptor->protocol == ID003 ) {
		if ( jcmBillAcceptor->event >= ID003_POWER_UP && jcmBillAcceptor->event <= ID003_POWER_UP_BILL_STACKER ) { 
			eventCallb = jcmBillAcceptor->event;
			powerUpStat = 1;
		} else 
			eventCallb = ID003_POWER_UP;

	} else {
		if ( jcmBillAcceptor->event >= CCNET_POWER_UP && jcmBillAcceptor->event <= CCNET_POWER_UP_BILL_STACKER ) { 
			eventCallb = jcmBillAcceptor->event + 48;
			powerUpStat = 1;
		} else 
			eventCallb = ID003_POWER_UP;
	}

	if ( jcmBillAcceptor->commErrorNotificationFcn != NULL && !jcmBillAcceptor->appNotifPowerUpBill  )
		( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, eventCallb );
	jcmBillAcceptor->appNotifPowerUpBill = 1;

	//doLog(0,"On Power UP? %d\n", powerUpStat ); fflush(stdout);
	return powerUpStat;
}

BOOL isNotJCMDisable(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
//	doLog(0,"notJCMDisable %d\n", jcmBillAcceptor->status != JCM_DISABLE ); fflush(stdout);
	return ( jcmBillAcceptor->status != JCM_DISABLE );
}


BOOL isJCMDisable(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//doLog(0,"JCMDisable %d\n", jcmBillAcceptor->status == JCM_DISABLE ); fflush(stdout);
	return ( jcmBillAcceptor->status == JCM_DISABLE );
}

BOOL maxTriesReached(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	doLog(0,"maxTriesReached %d\n", jcmBillAcceptor->commErrQty ); fflush(stdout);
	if ( jcmBillAcceptor->commErrQty > 8 )
		return 1;
	return 0;
}

void abortUpdate(StateMachine *sm)
{
	notifyFirmwareUpdate( sm, 255 );
}


void resetBuffer(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	jcmBillAcceptor->frameSize = 0;
	if ((( jcmBillAcceptor->framesQty % ( jcmBillAcceptor->framesQtyRefreshProgress + 1 ) )== jcmBillAcceptor->framesQtyRefreshProgress ) &&
		( jcmBillAcceptor->firmwareUpdateProgress != NULL ))
		( *jcmBillAcceptor->firmwareUpdateProgress )( jcmBillAcceptor->devId, jcmBillAcceptor->framesQty / jcmBillAcceptor->framesQtyRefreshProgress);
}
    
////// Estados de la maquina de estados //////////////////////////////////
//extern State noCommState;
static State noCommState;

#include "id0003StateMachine.m"
#include "ccnetStateMachine.m"
#include "meiStateMachine.m"
#include "rdmStateMachine.m"

/**
 *  Estado jcmInitializingState
 */
static Transition noCommStateTransitions[] =
{
	{ SM_ANY, NULL, NULL, &noCommState }
};


static State noCommState = 
{
  loadNoComm,  // entry
  NULL,                // exit
	noCommStateTransitions
};



/*

    PUBLIC FUNCTIONS
    
*/

/*
  Inicializacion de la comunicacion con el validador y de la maquina de estados.          Es necesario pasar por parametro los punteros a las funciones de callback, las cuales:
  
  changeAcceptorStatusNotif: notifica cuando hay un cambio en el estado del validador de dinero
  billRejectedNotif: notifica cuando el validador rechaza un billete informando la causa de rechazo de acuerdo a lo codificado en la especificacion
  billAcceptedNotif: notifica cuando el validador identifica y almacena un billete, informando el importe de dicho billete. 
  
  Retorna >= 0 si se realiza la operacion en forma exitosa (nro de handle) o -1
  en caso de error
*/

JcmBillAcceptData *billAcceptorNew( char devId, changeAcceptorStatusNotif statusNotifFcn, billRejectedNotif billRejectNotifFcn, billAcceptedNotif billAcceptNotifFcn, comunicationErrorNotif comunicationErrorNotifFcn, changeAcceptorStatusNotif acceptingNotifFcn )
{
    JcmBillAcceptData *jcmBillAcceptor;
    
    jcmBillAcceptor = (JcmBillAcceptData*) malloc( sizeof( JcmBillAcceptData ));

    jcmBillAcceptor->devId = devId;

    jcmBillAcceptor->statusNotificationFcn = statusNotifFcn;
    jcmBillAcceptor->billRejectNotificationFcn = billRejectNotifFcn;
    jcmBillAcceptor->billAcceptNotificationFcn = billAcceptNotifFcn;
    jcmBillAcceptor->commErrorNotificationFcn = comunicationErrorNotifFcn;
    jcmBillAcceptor->acceptingNotificationFcn = acceptingNotifFcn;
    
    *jcmBillAcceptor->jcmVersion = jcmBillAcceptor->billTableLoaded = 0; 
    jcmBillAcceptor->firmImage = NULL; 
    jcmBillAcceptor->canResetVal = jcmBillAcceptor->protocol = 
    jcmBillAcceptor->canChangeStatus = 
    jcmBillAcceptor->appNotifPowerUpBill = 0;
	jcmBillAcceptor->cheatedLeaveApp = 0;

	jcmBillAcceptor->amountChar = 0;

    jcmBillAcceptor->status = jcmBillAcceptor->pendingStatus = JCM_DISABLE;
    jcmBillAcceptor->billValidStateMachine = newStateMachine( &noCommState, jcmBillAcceptor );
    startStateMachine( jcmBillAcceptor->billValidStateMachine );
   	printf("JCMBillAcceptorStartStateMachine %d \n", jcmBillAcceptor->devId);//fflush(stdout);


    return ( jcmBillAcceptor );
}

void billAcceptorStart( JcmBillAcceptData *jcmBillAcceptor )
{

	if ( jcmBillAcceptor->protocol == ID003 ){
		printf("ID003 startStateMach first stateee %d! \n", jcmBillAcceptor->devId );
		gotoState( jcmBillAcceptor->billValidStateMachine, &jcmFirstState );
	} else {
		if ( jcmBillAcceptor->protocol == CCNET ){
			doLog(0,"CCNET startStateMach %d! \n", jcmBillAcceptor->devId );
			gotoState( jcmBillAcceptor->billValidStateMachine, &ccnetInitializingState );	
		} else {
            if ( jcmBillAcceptor->protocol == EBDS ){
                printf("MEI startStateMach id %d! \n", jcmBillAcceptor->devId );
                gotoState( jcmBillAcceptor->billValidStateMachine, &meiFirstState );
                printf("MEI after startStateMach id %d! \n", jcmBillAcceptor->devId );
            }else{ 
                printf("RDM startStateMach id %d! \n", jcmBillAcceptor->devId );
                gotoState( jcmBillAcceptor->billValidStateMachine, &rdmFirstState );
                
            }
		}
	}

}

void billAcceptorStop( JcmBillAcceptData *jcmBillAcceptor )
{
	doLog(0,"stopStateMach %d! \n ", jcmBillAcceptor->devId );fflush(stdout);
	gotoState(jcmBillAcceptor->billValidStateMachine, &noCommState);
	//una vez que deshabilito la comunicacion, limpio el flag
	jcmBillAcceptor->cheatedLeaveApp = 0;
}

void billAcceptorRun( JcmBillAcceptData *jcmBillAcceptor )
{
//	printf("bill acceptor run id %d! protocol %d %d\n ", jcmBillAcceptor->devId, jcmBillAcceptor->protocol, RDM100 );fflush(stdout);
	if ( jcmBillAcceptor->billValidStateMachine->currentState != &noCommState )  {

		switch (jcmBillAcceptor->protocol){
			case ID003: 
				billAcceptWriteRead( jcmBillAcceptor, getCommandCode(jcmBillAcceptor->protocol,STATUS_CMD), NULL, 0 );
				break;
			case CCNET:
				pollCcnet( jcmBillAcceptor );
				break;
			case EBDS:
				pollMei( jcmBillAcceptor );
				break;
			case RDM100:
				pollRDM( jcmBillAcceptor );
				break;
		}

	   // doLog(0, "Status %d | pending status %d \n",jcmBillAcceptor->status ,jcmBillAcceptor->pendingStatus); fflush(stdout);
		if ( jcmBillAcceptor->pendingStatus && jcmBillAcceptor->canChangeStatus ) {
		   billAcceptorSetStatus( jcmBillAcceptor, jcmBillAcceptor->pendingStatus );
		   jcmBillAcceptor->pendingStatus = 0;
		}
	} /*else    {
     //   printf("jcmBillAcceptormgr noCommState en el billAcceptorRun val> %d\n", jcmBillAcceptor->devId);
    }*/
	
}

void billAcceptorSetStatus( JcmBillAcceptData *jcmBillAcceptor, char newStatus )
{
	doLog(1,"billAcceptMgr - setStatus %d %d\n",jcmBillAcceptor->status, newStatus );fflush(stdout);
	if ( jcmBillAcceptor->status != newStatus ) {
		jcmBillAcceptor->status = newStatus;

		//para mei no lo hago!		
		if ( jcmBillAcceptor->protocol <= 2 ) {
			if (( newStatus == JCM_ENABLE ) || ( newStatus == JCM_VALIDATE_ONLY ))
				doEnable( jcmBillAcceptor->billValidStateMachine );
			else
				doDisable( jcmBillAcceptor->billValidStateMachine );
		} else {
            if ( jcmBillAcceptor->protocol == EBDS ) {
                if (( newStatus == JCM_ENABLE ) || ( newStatus == JCM_VALIDATE_ONLY ))
                    resetFileStatusMei(  jcmBillAcceptor->billValidStateMachine );
            }
		}

		if ( jcmBillAcceptor->statusNotificationFcn != NULL )
			( *jcmBillAcceptor->statusNotificationFcn )( jcmBillAcceptor->devId, newStatus );
	}
}

char billAcceptorUpdate( JcmBillAcceptData *jcmBillAcceptor, char *firmware, changeAcceptorStatusNotif firmUpdProgress )
{
	doLog(0,"billAcceptUpd!\n");fflush(stdout);

	if ( jcmBillAcceptor->protocol != CCNET ) {
		if (!( jcmBillAcceptor->firmImage = fopen( firmware, "rb" ))){
			doLog(0,"Error \n" );fflush(stdout);
			return 0; //error
		}
		jcmBillAcceptor->fileOffset = 0;
	} else {
		jcmBillAcceptor->fileOffset = convertHexFileToBin(jcmBillAcceptor, firmware);
		if ( jcmBillAcceptor->fileOffset == -1 )
			return -1;
	}

	jcmBillAcceptor->firmwareUpdateProgress = firmUpdProgress;

	fseek(jcmBillAcceptor->firmImage, 0, SEEK_END);
   	jcmBillAcceptor->fileSize = ftell ( jcmBillAcceptor->firmImage ) - jcmBillAcceptor->fileOffset;
	//ahora me posiciono en el offset para empezar a enviar el archivo desde el inicio real
	fseek(jcmBillAcceptor->firmImage, jcmBillAcceptor->fileOffset, SEEK_SET);

	jcmBillAcceptor->blockSize = 0;

	doLog(0,"fileSize %ld\n", jcmBillAcceptor->fileSize);fflush(stdout);
    
    if ( jcmBillAcceptor->fileSize > 0 ){
      	jcmBillAcceptor->framesQty = 0;
		jcmBillAcceptor->offsetTransfer = 0;
		jcmBillAcceptor->imageCrc = 0;
		executeStateMachine(jcmBillAcceptor->billValidStateMachine, ID003_UPDATE_FIRM);
		return 1;
	} 
	return 0;
}


unsigned short getLastStackedQty( JcmBillAcceptData *jcmBillAcceptor, long long *billAmount, int *currencyId )
{
	if ( jcmBillAcceptor->protocol == EBDS ) {
		return getLastStackedQtyMEI( jcmBillAcceptor, billAmount, currencyId );
	} else {
		doLog(0,"getlastStackedQty JCMBILLACCEPTOR, protocol distinto eebds\n");fflush(stdout);
		*billAmount = 0;
		*currencyId = 0;
		return 0;
	} 
}
