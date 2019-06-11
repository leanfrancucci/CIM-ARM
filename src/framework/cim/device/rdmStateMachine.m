
#include "rdm100.h"
#include "system/util/all.h"


#define RDM_NORMAL_CMD                  0x40
#define RDM_RESET_CMD                   0x30
#define RDM_INIT_CMD                    0x31
#define RDM_DEPOSIT_COUNT_CMD           0x41
#define RDM_DEPOSIT_COUNT_RESULT_CMD    0x42
#define RDM_REQ_CURRENCY_TABLE_CMD      0x51
#define RDM_REQ_LAST_DEPOSIT_CMD        0x45

//ActualState
#define RDM_POWERON  0x00
#define RDM_IDLING   0x01
#define RDM_INITIAL   0x02
#define RDM_WAIT_FOR_BANKNOTE_REMOVED_AFTER_INIT   0x03
#define RDM_WAIT_FOR_BANKNOTE_REMOVED_INLET_SLOT   0x06
#define RDM_WAIT_FOR_BANKNOTE_REMOVED_AFTER_DEPOSIT   0x07
#define RDM_RESET   0x11
#define RDM_ERROR   0x1F

typedef struct {
  unsigned short  noteId;
  unsigned short qty;
} CurrencyInfo;


void waitForEot(JcmBillAcceptData *jcmBillAcceptor )
{
    unsigned char *buff;
   
    buff = rdmReadCtrlSignal( jcmBillAcceptor->communicationHandle, jcmBillAcceptor->devId, 1000 );
   
}

unsigned char getValStatusRDM(JcmBillAcceptData *jcmBillAcceptor, CurrencyInfo * acceptedCurrencyInfo )
{
    unsigned char status, i;

    fseek( jcmBillAcceptor->fpValStat, 0, SEEK_SET );
    fread(&status, 1, 1,jcmBillAcceptor->fpValStat);
	if (!fread(acceptedCurrencyInfo, sizeof(CurrencyInfo),24,jcmBillAcceptor->fpValStat)){
		aTempValInfo.status = 0;
        memset(acceptedCurrencyInfo, 0, (sizeof(CurrencyInfo)*24));
        printf("GetValStatus Val: %d FAILED\n", jcmBillAcceptor->devId);//fflush(stdout);
	}
	
	printf("GetValStatus Val: %d Status: %d\n", jcmBillAcceptor->devId, status);//fflush(stdout);
    for (i = 0 ; i < 24; i++){
        printf("GETVALSTATUS!!! Currency Accepted[%d]: noteId %d, qty %d\n", i, acceptedCurrencyInfo->noteId, acceptedCurrencyInfo->qty);
        acceptedCurrencyInfo++;
    }
	return status;
}

void setValStatusRDM(JcmBillAcceptData *jcmBillAcceptor, unsigned char newStatus, CurrencyInfo * acceptedCurrencyInfo)
{
    int i;
    
    printf("***************************** setValStatussssssssssssssssssssssssssssss RDM %d\n", newStatus);

    fseek( jcmBillAcceptor->fpValStat, 0, SEEK_SET );
	fwrite( &newStatus, 1, 1, jcmBillAcceptor->fpValStat );
	fwrite( acceptedCurrencyInfo, sizeof(CurrencyInfo), jcmBillAcceptor->denominationQty, jcmBillAcceptor->fpValStat );
	fflush(jcmBillAcceptor->fpValStat);
    
    printf( "SetValStatus Val: %d Status: %d \n", jcmBillAcceptor->devId, newStatus);
    for (i = 0 ; i < jcmBillAcceptor->denominationQty; i++){
        printf("sETVALSTATUS!!! Currency Accepted[%d]: noteId %d, qty %d\n", i, acceptedCurrencyInfo->noteId, acceptedCurrencyInfo->qty);
        acceptedCurrencyInfo++;
    }
    
    if (fsync(fileno(jcmBillAcceptor->fpValStat))!= 0)
        printf( "SetValStatusRDM Val: %d Status: %d fsyn failed!\n", jcmBillAcceptor->devId, newStatus);

}

void rdmResetFileStatus(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
    CurrencyInfo aCurTable[24];

    //reseteo el status pero no los datos del ultimo deposito...
    
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
    getValStatusRDM(jcmBillAcceptor, &aCurTable );
	//aca tengo que resetear la cantidad de billetes almacenados>
	printf("resetFileStatusRDM  Val: %d \n", jcmBillAcceptor->devId);//fflush(stdout);
	jcmBillAcceptor->billDepositQty = 0;
	setValStatusRDM(jcmBillAcceptor, 0, aCurTable);
}





unsigned char getNextBlockNo(unsigned char blockN)
{
    if (blockN == 0x39)
        return 0x30;
    else 
        return (blockN + 1);
}

BOOL rdmSendFrameProcess(JcmBillAcceptData *jcmBillAcceptor, unsigned char * dataCmd, int dataLen)
{
        rdmWriteFrame(jcmBillAcceptor->communicationHandle, jcmBillAcceptor->devId,dataCmd, dataLen);
        jcmBillAcceptor->dataEvPtr = rdmReadCtrlSignal(jcmBillAcceptor->communicationHandle, jcmBillAcceptor->devId, 1000 );
        if ( jcmBillAcceptor->dataEvPtr != NULL ){
           if ( !memcmp(jcmBillAcceptor->dataEvPtr, eotCmd, 2 )) {
                jcmBillAcceptor->dataEvPtr = rdmReadCtrlSignal( jcmBillAcceptor->communicationHandle, jcmBillAcceptor->devId, 1000 );
                if (( jcmBillAcceptor->dataEvPtr != NULL ) && ( !memcmp(jcmBillAcceptor->dataEvPtr, ackCmd, 2 ))){
                    rdmWriteCtrlSignal(jcmBillAcceptor->communicationHandle, jcmBillAcceptor->devId,eotCmd,2);
                    return 1;
                } 
           } else {
                if ( !memcmp(jcmBillAcceptor->dataEvPtr, ackCmd, 2 )){
                       rdmWriteCtrlSignal(jcmBillAcceptor->communicationHandle, jcmBillAcceptor->devId,eotCmd,2);
                    return 1;
                } 
           }     
        }     
    //    doLog(1, "hay que reenviar la ultima trama, IMPLEMENTAR! \n" ); 
        return 0;
}

void loadDisableRdm(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	printf("RDM %d loadDisable\n", jcmBillAcceptor->devId);//fflush(stdout);
	jcmBillAcceptor->canChangeStatus = 1;

}

static unsigned char startdeposit[3]= { 0x33, 0x41, 0x30};

void loadEnableRdm(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	printf("RDM %d loadES\n", jcmBillAcceptor->devId);
	jcmBillAcceptor->canChangeStatus = 1;
    
}

BOOL isPreparedforDepositing(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	
	if ((jcmBillAcceptor->actualState == RDM_IDLING ) && (( jcmBillAcceptor->sst[3] & 0x04 ) || ( jcmBillAcceptor->sst[6] & 0x04 )) && !( jcmBillAcceptor->sst[0] & 0x02 ))
		return 1;
	return 0;
}

void sendStartDepositingRdm(StateMachine *sm) 
{
	JcmBillAcceptData *jcmBillAcceptor;
    CurrencyInfo aCurTable[24];

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	printf("RDM %d SendStartDepositing \n", jcmBillAcceptor->devId);
	jcmBillAcceptor->canChangeStatus = 0;
    jcmBillAcceptor->sndBlockNo = getNextBlockNo(jcmBillAcceptor->sndBlockNo);
    startdeposit[0]= jcmBillAcceptor->sndBlockNo;
	rdmSendFrameProcess(jcmBillAcceptor, startdeposit, 3 );
    memset(aCurTable, 0, (sizeof(CurrencyInfo)*24));
	setValStatusRDM(jcmBillAcceptor, ID003_ESCROW, aCurTable);

}

static unsigned char reqLastdeposit[3]= { 0x33, 0x45};

void sendReqLastDepositCountRdm(StateMachine *sm) 
{
	JcmBillAcceptData *jcmBillAcceptor;
    unsigned char aux, cmd;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	printf("RDM %d RquestLastDepositCount \n", jcmBillAcceptor->devId);
    jcmBillAcceptor->sndBlockNo = getNextBlockNo(jcmBillAcceptor->sndBlockNo);
    reqLastdeposit[0]= jcmBillAcceptor->sndBlockNo;
	rdmSendFrameProcess(jcmBillAcceptor, reqLastdeposit, 2 );
}

void loadFirstStateRdm(StateMachine *sm) 
{ 
	int amountAux, curIdAux, billQty, i;
	unsigned char valSt;
	JcmBillAcceptData *jcmBillAcceptor;    
    CurrencyInfo aCurTable[24];
    
//	int amountAux, curIdAux;
	

    jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
    jcmBillAcceptor->communicationHandle =  rdmInit( jcmBillAcceptor->devId + 1 );

    printf("RDM %d LoadFirstState con handle ok\n", jcmBillAcceptor->devId);//fflush(stdout);
    jcmBillAcceptor->actualState = 255;
    jcmBillAcceptor->billTableLoaded = 0;
    jcmBillAcceptor->statusWaitingDepositInfo = 0;
    jcmBillAcceptor->initalizationAlarmSent = 0;
    jcmBillAcceptor->recBlockNo = 0x30;
    jcmBillAcceptor->sndBlockNo = 0x30;

    openValStatusFile(jcmBillAcceptor);


	jcmBillAcceptor->statusWaitingDepositInfo = getValStatusRDM(jcmBillAcceptor, &aCurTable);
        //para debug!! sacar depuesyt!

    if (( jcmBillAcceptor->statusWaitingDepositInfo == ID003_ESCROW ) || (jcmBillAcceptor->statusWaitingDepositInfo == ID003_STACKED ))  {
        //HABIA MANDADO A QUE EMPIECE A CONTAR BILLETES, AUDITO ESTO! 
        //DESPUES ACA DEBERIA ENCUESTAR AL VAL ACERCA DE LA CANTIDAD
		//formatMoney(moneyStr, [[[CurrencyManager getInstance] getCurrencyById: *currencyId] getCurrencyCode], *billAmount, 2, 40);
        printf("]]]]]]]]]]]]]]]]] RDM get val Status en ESCROW OR STACKED******************************************\n");
		[Audit auditEvent: NULL eventId: Event_POWER_UP_WITH_ESCROW_STATUS 	additional: "" station: 0 logRemoteSystem: FALSE];
        
     //   sendReqLastDepositCountRdm(sm);
        
	} /*else  {
        jcmBillAcceptor->statusWaitingDepositInfo = 0;
        rdmResetFileStatus(sm);
    }*/
}

void loadInitializingRdm(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;
//	int amountAux, curIdAux;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	printf("RDM %d LoadIS\n", jcmBillAcceptor->devId);fflush(stdout);
    jcmBillAcceptor->resetSent = 0;
	jcmBillAcceptor->canChangeStatus = 1;
   	jcmBillAcceptor->notifyInitApp = 0;

    
}

void loadReceivingBillRdm(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	printf( "RDM %d loadRBill\n", jcmBillAcceptor->devId);
	jcmBillAcceptor->canChangeStatus = 0;
}

void loadErrorStateRdm(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	printf("RDM %d loadErrorS\n", jcmBillAcceptor->devId);fflush(stdout);
	jcmBillAcceptor->resetSentQty = 0;
	jcmBillAcceptor->canChangeStatus = 1;

	if ( jcmBillAcceptor->commErrorNotificationFcn != NULL )
		( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, jcmBillAcceptor->errorCause );
//	printf("RDM %d LLLloadErrorS\n", jcmBillAcceptor->devId);//fflush(stdout);
}

/*
typedef struct  {
  unsigned char idx;      
  unsigned short  noteId;
  unsigned char countryCode[3];
  unsigned short denomination;
  unsigned char emission;
  unsigned char enabled;
  unsigned char mode;
} CurrencyTableRec;
*/


void processCurrencyTable(StateMachine *sm)
{    
       	JcmBillAcceptData *jcmBillAcceptor;
        unsigned short result;
        int i, tabsize;
        unsigned char idx = 0;
        unsigned short noteId, multip;
        unsigned char exponente;
        unsigned short  denomination; 
        jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
        
       	memset( jcmBillAcceptor->convertionTable, 0, sizeof(jcmBillAcceptor->convertionTable));
        result = SHORT_TO_L_ENDIAN((unsigned short) *(jcmBillAcceptor->dataEvPtr+9));
    
        printf("PROCESS CURRENCY TABLE !!! \n"); 

        if (result == 0){
            for (i = 0; i < 24; i++){
                noteId = (unsigned short)*(jcmBillAcceptor->dataEvPtr+12+(i*11));
                if ((idx > (unsigned char)*(jcmBillAcceptor->dataEvPtr+11+(i*11))) && (noteId == 0x03))
                    break;
                idx = (unsigned char)*(jcmBillAcceptor->dataEvPtr+11+(i*11));
                denomination = (unsigned short)*(jcmBillAcceptor->dataEvPtr+17+(i*11));
                exponente = (unsigned char)*(jcmBillAcceptor->dataEvPtr+18+(i*11));
                multip = pow(10, exponente);
                jcmBillAcceptor->convertionTable[idx].amount =  (denomination * multip);
                jcmBillAcceptor->convertionTable[idx].noteId =  noteId;
                memcpy(jcmBillAcceptor->convertionTable[idx].countryStr, (jcmBillAcceptor->dataEvPtr+14+(i*11)), 3);
                jcmBillAcceptor->convertionTable[idx].countryStr[3]= 0;
                jcmBillAcceptor->convertionTable[idx].currencyId = getCurrencyIdFromISOStr( jcmBillAcceptor->convertionTable[idx].countryStr );
                jcmBillAcceptor->convertionTable[idx].disabled = !(jcmBillAcceptor->dataEvPtr+20+(i*11));
                printf("currency table idx %d noteId %d denomination %d amount %d multip %d countrstr %s curid %d \n", idx , noteId, denomination, jcmBillAcceptor->convertionTable[idx].amount,multip, jcmBillAcceptor->convertionTable[idx].countryStr, jcmBillAcceptor->convertionTable[idx].currencyId);
            }
      	    if ( jcmBillAcceptor->countryCode == 0  )
                jcmBillAcceptor->countryCode = jcmBillAcceptor->convertionTable[0].currencyId ;

            jcmBillAcceptor->billTableLoaded = 1;
            jcmBillAcceptor->denominationQty = i;
            printf("currency table denomination qty %d \n", jcmBillAcceptor->denominationQty);
        } else{
            printf( "currency table process execution result <> 0 %d!\n", result); 
        }
}

void startDepositCount(StateMachine *sm)
{    
       	JcmBillAcceptData *jcmBillAcceptor;

        jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
        doLog(1, "satart deposit count!\n" ); 
      //  jcmBillAcceptor->status = JCM_DISABLE ;
        jcmBillAcceptor->sndBlockNo = getNextBlockNo(jcmBillAcceptor->sndBlockNo);
        startdeposit[0]= jcmBillAcceptor->sndBlockNo;
        rdmSendFrameProcess(jcmBillAcceptor, startdeposit, 3 );
}


static unsigned char initComand[2]= { 0x31, 0x31};
    
void sendInitializationCmd(StateMachine *sm)
{
       	JcmBillAcceptData *jcmBillAcceptor;

        jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//doProcessStatusRdm(jcmBillAcceptor, jcmBillAcceptor->dataEvPtr+2);
	doLog(1,"RDM sewn initiliazation comd actual state %d \n", jcmBillAcceptor->actualState);
    jcmBillAcceptor->sndBlockNo = getNextBlockNo(jcmBillAcceptor->sndBlockNo);
    initComand[0]= jcmBillAcceptor->sndBlockNo;
    rdmSendFrameProcess(jcmBillAcceptor, initComand, 2 );
    jcmBillAcceptor->initalizationAlarmSent = 0;

}

BOOL verifyCmdExecResult(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;
    int result;
    
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	
    result = SHORT_TO_L_ENDIAN(*((unsigned short*)(jcmBillAcceptor->dataEvPtr+9)));
    printf("Verificar resultado de la ejecucion de comando en RDM >>>>>>>>>>>>> %d!\n", result); 
	 if (result != 0){
         printf("Notificar un error del validador codigo %d!\n", result); 
         if ( jcmBillAcceptor->commErrorNotificationFcn != NULL )
               ( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, result );
    //    sendResetRdm(sm);
		return 0;
     }	
	return 1;
}

static unsigned char reqCurComand[2]= { 0x32, 0x51};

void requestCurrencyRDM(StateMachine *sm)
{
       	JcmBillAcceptData *jcmBillAcceptor;

        jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
        
        doLog(1, "request currency table\n" ); 
        jcmBillAcceptor->sndBlockNo = getNextBlockNo(jcmBillAcceptor->sndBlockNo);
        reqCurComand[0]= jcmBillAcceptor->sndBlockNo;
        rdmSendFrameProcess(jcmBillAcceptor, reqCurComand, 2 );

}


void doProcessStatusRdm(JcmBillAcceptData *jcmBillAcceptor, unsigned char *statusNew)
{

        memcpy(&jcmBillAcceptor->sst, statusNew, 7 );


       

//        if ( statusNew[0] & 0x04 ) jcmBillAcceptor->errorCause = 1;
        
        //sst2
	/*
		Actual state puede ser>
			00 PowerOn
			01 Idling
			02 Initial
			03 Waiting for banknote to be removed after initialization
			05 Depositing
			06 Waiting for banknote to be removed from inlet slot
			07 Waiting for banknote to be removed after depositing
			11 Reset
			1F Error Ocurred

	*/
    jcmBillAcceptor->errorCause = 0;
	if (statusNew[1] == RDM_ERROR) 
        jcmBillAcceptor->errorCause = ID003_JAM_IN_ACCEPTOR;
        
	if ((statusNew[1] == RDM_WAIT_FOR_BANKNOTE_REMOVED_AFTER_INIT) ||(statusNew[1] == RDM_WAIT_FOR_BANKNOTE_REMOVED_INLET_SLOT) ||(statusNew[1] == RDM_WAIT_FOR_BANKNOTE_REMOVED_AFTER_DEPOSIT) )
       	jcmBillAcceptor->errorCause = 0xB4;
		
	jcmBillAcceptor->actualState = statusNew[1];

    
/*        if (( statusNew[3] & 0x04 ) || ( statusNew[6] & 0x04 ))
		jcmBillAcceptor->hasBankNotesWaiting = 1;
	else
		jcmBillAcceptor->hasBankNotesWaiting = 0;
*/	
       //sst3
     /*   if ((statusNew[3] != 0) || (statusNew[4] != 0) || (statusNew[6] != 0))
            jcmBillAcceptor->errorCause = ;*/
}



BOOL isOnCommunicationError(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	return ( jcmBillAcceptor->errorCause == ID003_COMM_ERROR );

}

BOOL errorDetectedRdm(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	return ( jcmBillAcceptor->errorCause > 0 );

}


BOOL endErrorDetectedRdm(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	if ( jcmBillAcceptor->errorCause == 0) {
    	printf("RDM %d endErrorDetected \n", jcmBillAcceptor->devId ); 
		if ( jcmBillAcceptor->commErrorNotificationFcn != NULL )
			( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, 0 );
    	printf("RDM %d EEEndErrorDetected \n", jcmBillAcceptor->devId ); 
        
		return 1;
	}
	return 0;

}

BOOL initializacionComplete(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

    jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
    // cuando evalue que termino la inicitalizacion entonces tengo que cambviar la condicion de este if
    if (1){
       	if  ((jcmBillAcceptor->commErrorNotificationFcn != NULL) && (!jcmBillAcceptor->notifyInitApp) ){
			printf("RDM %d NOTIFICA app initializing\n", jcmBillAcceptor->devId);
			( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, 0 );
             jcmBillAcceptor->notifyInitApp= 1;
			printf("RDM %d AFter NOTIFICA app initializing\n", jcmBillAcceptor->devId);
             
        }
    } 
    return 1;

}

BOOL isOnResetStatusRdm(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;
    unsigned char errorD;

    //Antes de la visita de Omar Jorge en febrero 2019, esperaba que el validador este en estado reset
    //para enviarle el cmd de inicializacion. En su visita acordamos que para enviar el comando inicializacion 
    //se tiene que dar que ciertos bits de los bytes de status deben estar apagados . Sino no se envian hasta tanto se
    //apaguen
    //printf("isOnResetStatus...");
    jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
    if (( jcmBillAcceptor->actualState == RDM_RESET ) || (jcmBillAcceptor->sst[0] & 0x01 ))	{//powerOn true 
        //printf("RDM is on RESET Status!\n");
        //si todos esos sensores estan apagados, mando a inicializar, sino espero
        if (((jcmBillAcceptor->sst[2] & 0xFD) == 0) && 
                ((jcmBillAcceptor->sst[3] & 0xDF) == 0) && 
                (jcmBillAcceptor->sst[4] == 0) && 
                (jcmBillAcceptor->sst[5] == 0) && 
                ((jcmBillAcceptor->sst[6] & 0x01) == 0)){ //powerOn true 
                    printf("INITIALIZE!...\n");
                    return 1;
        } else {
            //no puedo enviar a inicializar porque hay sensores activos, enviar alarma una sola vez>
            if ( !jcmBillAcceptor->initalizationAlarmSent ){
                if ((jcmBillAcceptor->sst[2] & 0xFD) != 0)
                    errorD = 0xB5;
                else 
                    errorD = ID003_JAM_IN_ACCEPTOR;
                
                if ( jcmBillAcceptor->commErrorNotificationFcn != NULL )
                        ( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, errorD );
                jcmBillAcceptor->initalizationAlarmSent = 1;
            }
        }
    }
  
    //printf("FALSE...\n");
    return 0;

}


BOOL isOnPowerUpStatusRdm(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

    jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
    if ( jcmBillAcceptor->actualState == RDM_POWERON ){ 	//powerOn true 
        printf("RDM is on PowerOn Status!\n");
        return 1;
    }
    return 0;

}

BOOL isRDMStatusBusy(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

    jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
    if ( jcmBillAcceptor->sst[0] & 0x02 ) {
        printf("RDM Status is BUSY.. WAITINGGGGG \n");        
        return 1;
    }
    return 0;

}

BOOL waitingForLastDeposit(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

    jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
    if (( jcmBillAcceptor->statusWaitingDepositInfo == ID003_ESCROW ) || (jcmBillAcceptor->statusWaitingDepositInfo == ID003_STACKED ))  {
        printf("RDM WAITINGGGGG for last desposit INfo!!\n");        
        return 1;
    }
    return 0;

}

BOOL errorNeedsReset(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

    jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
    if (( jcmBillAcceptor->errorCause != ID003_COMM_ERROR ) && (jcmBillAcceptor->resetSentQty < 20)) {
        printf("RDM ERROR NEEDS RESET !\n");
        jcmBillAcceptor->resetSentQty++;
        msleep(3000);
        return 1;
    }
    return 0;

}


BOOL currencyTableNotLoaded(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

    jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
    if (!jcmBillAcceptor->billTableLoaded)
        return 1;
    return 0;

}


static unsigned char resetComand[8]= { 0x30, 0x30, 0x14, 0x11, 0x03, 0x06, 0x0b, 0x3b};

void sendResetRdm(StateMachine *sm)
{
    JcmBillAcceptData *jcmBillAcceptor; 
	struct tm currentBrokenTime;

    

    jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
    printf("SEND RESET RDM \n" ); 
    jcmBillAcceptor->recBlockNo = 0x30;
    jcmBillAcceptor->sndBlockNo = 0x30;

	[SystemTime decodeTime: [SystemTime getLocalTime] brokenTime: &currentBrokenTime];

    resetComand[2]=  0x14; //aca le mando el 20
    resetComand[3]= (currentBrokenTime.tm_year - 100); //aca le mando el 18  year 2018
    resetComand[4] = (currentBrokenTime.tm_mon + 1);
    resetComand[5] = currentBrokenTime.tm_mday;
    resetComand[6] = currentBrokenTime.tm_hour;
    resetComand[7] = currentBrokenTime.tm_min;
    
    rdmSendFrameProcess(jcmBillAcceptor, resetComand, 8 );
    msleep(1000);
}


CurrencyInfo currencyAccepted[24];

void notifyBillsAccepted(StateMachine *sm)
{
    JcmBillAcceptData *jcmBillAcceptor; 
    unsigned short result, i, j,x;
    unsigned char qtyRejected;
    
    jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
    
    printf("Notify bilss accepted!\n" ); 
    result = SHORT_TO_L_ENDIAN(*((unsigned short*)(jcmBillAcceptor->dataEvPtr+9)));
    if ( result < 0xE000 ){  //si es 0 o error code hay que procesar los billetes igual, si es un codigo de warning entonces no se ejecuto el comando
         qtyRejected = (unsigned char)*(jcmBillAcceptor->dataEvPtr+11);
  		 if (( jcmBillAcceptor->billRejectNotificationFcn != NULL ) && (qtyRejected > 0)){ 
            printf("Qty rejected> %d!\n", qtyRejected ); 
			( *jcmBillAcceptor->billRejectNotificationFcn )( jcmBillAcceptor->devId, 0x7B, qtyRejected );//mando siempre "Operation Error" porq no me lo discrimina mei
         }
          if (result != 0){
	         printf("Notificar un error del validador codigo %d!\n", result); 
              if ( jcmBillAcceptor->commErrorNotificationFcn != NULL )
                ( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, result );
     }	
  //    printf("FALTA notificar bills rejected %d!\n", qtyRejected ); 
         memcpy(currencyAccepted,jcmBillAcceptor->dataEvPtr+12, 96);
      	setValStatusRDM(jcmBillAcceptor, ID003_STACKED, &currencyAccepted);

         for (i = 0; i < jcmBillAcceptor->denominationQty; i++){
             currencyAccepted[i].noteId = SHORT_TO_L_ENDIAN(currencyAccepted[i].noteId);
             currencyAccepted[i].qty = SHORT_TO_L_ENDIAN(currencyAccepted[i].qty);
             for (x =0; ((x < 24) && (jcmBillAcceptor->convertionTable[x].noteId != currencyAccepted[i].noteId)) ;x++)
               ; 
             if ((x < 24) && (jcmBillAcceptor->convertionTable[x].noteId == currencyAccepted[i].noteId)){
		if (currencyAccepted[i].qty > 0){
                    jcmBillAcceptor->amountChar = jcmBillAcceptor->convertionTable[x].amount;
                    jcmBillAcceptor->amountChar = (jcmBillAcceptor->amountChar* MultipApp);
                    
                    ( *jcmBillAcceptor->billAcceptNotificationFcn )( jcmBillAcceptor->devId,  jcmBillAcceptor->amountChar, jcmBillAcceptor->convertionTable[x].currencyId, currencyAccepted[i].qty );
                printf("NNotify bilss accepted %lld %d!\n",jcmBillAcceptor->amountChar, currencyAccepted[i].qty ); 
		}
             } else 
                printf("NOT FOUND noteB id %d  qty %d!\n", currencyAccepted[i].noteId, currencyAccepted[i].qty); 
             
        }
    } else
        printf("notify bilss accepted command execution result warning >  E000  %d!\n", result ); 

    rdmResetFileStatus(sm);
    jcmBillAcceptor->canChangeStatus = 1;
    
}

CurrencyInfo * tempAcceptedCurrencyInfo[24];

void verifyNotifyBillsAccepted(StateMachine *sm)
{
    JcmBillAcceptData *jcmBillAcceptor; 
    unsigned short result, i, j,x;
    unsigned char qtyRejected;
    unsigned char notificarPendiente = 0;
    
    jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
    
    printf("VERIFY  Notify bilss accepted!\n" ); 
    //vuelvo a verificar por si sigue waiting porque capaz que me llego el stacked del validador solo
    if (waitingForLastDeposit(sm)) {
        
        result = SHORT_TO_L_ENDIAN(*((unsigned short*)(jcmBillAcceptor->dataEvPtr+9)));
        if ( result < 0xE000 ){  //si es 0 o error code hay que procesar los billetes igual, si es un codigo de warning entonces no se ejecuto el comando
            qtyRejected = (unsigned char)*(jcmBillAcceptor->dataEvPtr+11);
            printf("Qty rejected> %d!\n", qtyRejected ); 
            if (result != 0)
                printf("Notificar un error del validador codigo %d!\n", result); 
                	
            getValStatusRDM(jcmBillAcceptor, &tempAcceptedCurrencyInfo );
            memcpy(currencyAccepted,jcmBillAcceptor->dataEvPtr+12, 96);
            //pendiente sole
            //if el estado es escrow directamente le mando la notificacion a la app de cada una de las denominaciones
            //si el estado era stacked verifico si es la misma tabla de currencies accpeted o es una nueva y si es nueva lo mando
            if ( jcmBillAcceptor->statusWaitingDepositInfo == ID003_STACKED ) {
                if (memcmp(currencyAccepted, tempAcceptedCurrencyInfo, sizeof(tempAcceptedCurrencyInfo))){
                    printf("las currencies almacenadas en el archivo NO COINCIDEN con las devueltas del ultimo deposito, notificar app!!! \n");
                    notificarPendiente = 1;

                }
            }
            if (( jcmBillAcceptor->statusWaitingDepositInfo == ID003_ESCROW ) || (notificarPendiente)) {
                printf("VERIFY  Notify bilss accepted! ES  NECESARIO NOTIFICAR A LA APLICACION!!! \n");
                  	setValStatusRDM(jcmBillAcceptor, ID003_STACKED, &currencyAccepted);
                for (i = 0; i < jcmBillAcceptor->denominationQty; i++){
                    currencyAccepted[i].noteId = SHORT_TO_L_ENDIAN(currencyAccepted[i].noteId);
                    currencyAccepted[i].qty = SHORT_TO_L_ENDIAN(currencyAccepted[i].qty);
                    for (x =0; ((x < 24) && (jcmBillAcceptor->convertionTable[x].noteId != currencyAccepted[i].noteId)) ;x++)
                        ; 
                    if ((x < 24) && (jcmBillAcceptor->convertionTable[x].noteId == currencyAccepted[i].noteId)){
                        if (currencyAccepted[i].qty > 0){
                            jcmBillAcceptor->amountChar = jcmBillAcceptor->convertionTable[x].amount;
                            jcmBillAcceptor->amountChar = (jcmBillAcceptor->amountChar* MultipApp);
                                
                        //       ( *jcmBillAcceptor->billAcceptNotificationFcn )( jcmBillAcceptor->devId,  jcmBillAcceptor->amountChar, jcmBillAcceptor->convertionTable[x].currencyId, currencyAccepted[i].qty );
                            printf("NNotify bilss accepted %lld %d!\n",jcmBillAcceptor->amountChar, currencyAccepted[i].qty ); 
                        }
                    } else 
                        printf("NOT FOUND noteB id %d  qty %d!\n", currencyAccepted[i].noteId, currencyAccepted[i].qty); 
                }
            }
        } else
            printf("notify bilss accepted command execution result warning >  E000  %d!\n", result ); 
        
        jcmBillAcceptor->statusWaitingDepositInfo = 0;
        rdmResetFileStatus(sm);
    }
}

////// Estados de la maquina de estados //////////////////////////////////

extern State rdmFirstState;
extern State rdmInitializingState;
extern State rdmEnabledState;
extern State rdmDisabledState;
extern State rdmReceivingBillState;
extern State rdmErrorState;

/*
#define RDM_NORMAL_CMD                  0x40;
#define RDM_RESET_CMD                   0x30;
#define RDM_INIT_CMD                    0x31;
#define RDM_DEPOSIT_COUNT_CMD           0x41;
#define RDM_DEPOSIT_COUNT_RESULT_CMD    0x42;
#define RDM_REQ_CURRENCY_TABLE_CMD      0x51;
*/
/**
 *  Estado jcmInitializingState
 */
static Transition rdmFirstStateTransitions[] =
{	
	{ SM_ANY, NULL, NULL, &rdmInitializingState }
};

State rdmFirstState = 
{
  	loadFirstStateRdm,  // entry
  	NULL,                // exit
	rdmFirstStateTransitions
};

static Transition rdmInitStateTransitions[] =
{	
	 { RDM_DEPOSIT_COUNT_RESULT_CMD, NULL, notifyBillsAccepted, &rdmInitializingState }
	,{ RDM_REQ_LAST_DEPOSIT_CMD, NULL, verifyNotifyBillsAccepted, &rdmInitializingState }
//	,{ RDM_NORMAL_CMD, NULL, processStatusRdm, &rdmInitializingState }
	,{ SM_ANY, errorDetectedRdm, NULL, &rdmErrorState }
	,{ SM_ANY, isRDMStatusBusy, NULL, &rdmInitializingState }
	,{ RDM_RESET_CMD, verifyCmdExecResult, NULL, &rdmInitializingState }
	,{ RDM_INIT_CMD, verifyCmdExecResult, requestCurrencyRDM, &rdmInitializingState }
	,{ RDM_REQ_CURRENCY_TABLE_CMD, verifyCmdExecResult, processCurrencyTable, &rdmInitializingState }
	,{ SM_ANY, isOnPowerUpStatusRdm, sendResetRdm, &rdmInitializingState }
	,{ SM_ANY, isOnResetStatusRdm, sendInitializationCmd, &rdmInitializingState }
	,{ SM_ANY, currencyTableNotLoaded, requestCurrencyRDM, &rdmInitializingState }
//	,{ SM_ANY, waitingForLastDeposit, sendReqLastDepositCountRdm, &rdmInitializingState }
	,{ SM_ANY, initializacionComplete, NULL, &rdmDisabledState }
	,{ SM_ANY, NULL, NULL, &rdmInitializingState }
};

State rdmInitializingState = 
{
  	loadInitializingRdm,  // entry
  	NULL,                // exit
	rdmInitStateTransitions
};

/**
 *  Estado Disabled
 */
 
static Transition rdmDisabledStateTransitions[] =
{
	{ RDM_DEPOSIT_COUNT_RESULT_CMD, NULL, notifyBillsAccepted, &rdmDisabledState }
	,{ SM_ANY, isRDMStatusBusy, NULL, &rdmDisabledState }
	,{ SM_ANY, errorDetectedRdm, NULL, &rdmErrorState }
	,{ SM_ANY, isOnPowerUpStatusRdm, sendResetRdm, &rdmInitializingState }
	,{ SM_ANY, isOnResetStatusRdm, sendInitializationCmd, &rdmInitializingState }
	,{ SM_ANY, isNotJCMDisable, NULL, &rdmEnabledState }
	,{ SM_ANY, NULL, NULL, &rdmDisabledState }
};

State rdmDisabledState = 
{
  	loadDisableRdm,  // entry
  	NULL,                // exit
	rdmDisabledStateTransitions
};


/**
 *  Estado Enabled
 */
 
static Transition rdmEnabledStateTransitions[] =
{
	{ RDM_DEPOSIT_COUNT_RESULT_CMD, NULL, notifyBillsAccepted, &rdmEnabledState }
	 ,{ SM_ANY, isJCMDisable, NULL, &rdmDisabledState }
	,{ SM_ANY, isRDMStatusBusy, NULL, &rdmEnabledState }
	,{ SM_ANY, isPreparedforDepositing, sendStartDepositingRdm, &rdmEnabledState }
	,{ SM_ANY, errorDetectedRdm, NULL, &rdmErrorState }
	,{ SM_ANY, isOnPowerUpStatusRdm, sendResetRdm, &rdmInitializingState }
	,{ SM_ANY, isOnResetStatusRdm, sendInitializationCmd, &rdmInitializingState }
//	 { RDM_NORMAL_CMD, NULL, processStatusRdm, &rdmEnabledState }
	,{ SM_ANY, NULL, NULL, &rdmEnabledState }
};

State rdmEnabledState = 
{
  	loadEnableRdm,  // entry
  	NULL,                // exit
	rdmEnabledStateTransitions
};

/**
 *  Estado ReceivingBillState
 */

static Transition rdmReceivingBillStateTransitions[] =
{
	{ SM_ANY, errorDetectedRdm, NULL, &rdmErrorState}
	,{ SM_ANY, isJCMDisable, NULL, &rdmDisabledState}
	,{ SM_ANY, NULL, NULL, &rdmReceivingBillState }
};

State rdmReceivingBillState = 
{
  	loadReceivingBillRdm,  // entry
  	NULL,                // exit
	rdmReceivingBillStateTransitions
};

/**
 *  Estado ErrorState
 */

static Transition rdmErrorStateTransitions[] =
{
	{ RDM_DEPOSIT_COUNT_RESULT_CMD, NULL, notifyBillsAccepted, &rdmDisabledState }
	,{ SM_ANY, endErrorDetectedRdm, NULL, &rdmInitializingState }
	,{ SM_ANY, isOnCommunicationError, NULL, &rdmErrorState }
	,{ SM_ANY, isRDMStatusBusy, NULL, &rdmErrorState }
	,{ RDM_RESET_CMD, verifyCmdExecResult, NULL, &rdmErrorState }
	,{ RDM_INIT_CMD, verifyCmdExecResult, requestCurrencyRDM, &rdmInitializingState }
	,{ SM_ANY, isOnPowerUpStatusRdm, sendResetRdm, &rdmErrorState }
	,{ SM_ANY, isOnResetStatusRdm, sendInitializationCmd, &rdmErrorState }
    //el nuevo envio de reset lo dejo para el final de las evaluaciones en el estado error 
	,{ SM_ANY, errorNeedsReset, sendResetRdm, &rdmErrorState }
	 ,{ SM_ANY, NULL, NULL, &rdmErrorState }
};

State rdmErrorState = 
{      
  	loadErrorStateRdm,  // entry
  	NULL,                // exit
	rdmErrorStateTransitions
};


void pollRDM( JcmBillAcceptData *jcmBillAcceptor )
{
    unsigned char aux, cmd;
    
//	printf("<<<<<<<<<<<<<<<<<<<<<<<<<<<<< POLLRdmmmmmmm\n ");fflush(stdout);
    rdmWriteCtrlSignal( jcmBillAcceptor->communicationHandle, jcmBillAcceptor->devId,enqCmd, 4 );
    do {		
        jcmBillAcceptor->dataEvPtr = rdmReadFrame( jcmBillAcceptor->communicationHandle, jcmBillAcceptor->devId,1000 );
    	if ( jcmBillAcceptor->dataEvPtr != NULL ) {
             	aux = *(jcmBillAcceptor->dataEvPtr);
                if  (jcmBillAcceptor->recBlockNo == aux)     {
                    jcmBillAcceptor->commErrQty = 0;
                	jcmBillAcceptor->recBlockNo = getNextBlockNo(jcmBillAcceptor->recBlockNo);
                	cmd = *(jcmBillAcceptor->dataEvPtr+1);
                    if ( cmd == RDM_DEPOSIT_COUNT_RESULT_CMD){
                        //para que si no llego a procesarlo no mande el ack asi deps de un corte me lo reenvia
                        doProcessStatusRdm(jcmBillAcceptor, jcmBillAcceptor->dataEvPtr+2);
                        executeStateMachine(jcmBillAcceptor->billValidStateMachine, cmd);
                        rdmWriteCtrlSignal(jcmBillAcceptor->communicationHandle, jcmBillAcceptor->devId, ackCmd,2);
                        waitForEot(jcmBillAcceptor);
                    } else {
                        rdmWriteCtrlSignal(jcmBillAcceptor->communicationHandle, jcmBillAcceptor->devId,ackCmd,2);
                        waitForEot(jcmBillAcceptor);
                        doProcessStatusRdm(jcmBillAcceptor, jcmBillAcceptor->dataEvPtr+2);
                        executeStateMachine(jcmBillAcceptor->billValidStateMachine, cmd);
                     }
                } else {
                	doLog(1, "block no diferente esperado %d  %d!\n", jcmBillAcceptor->recBlockNo, jcmBillAcceptor->recBlockNo == aux); 
                	if  (jcmBillAcceptor->recBlockNo ==  getNextBlockNo(aux))     {
                       	//me reenvio la trama anterior, envio ack:
	                    rdmWriteCtrlSignal(jcmBillAcceptor->communicationHandle, jcmBillAcceptor->devId,ackCmd,2);
        	            waitForEot(jcmBillAcceptor);
                    
                	} else {
                        //si el block no no es el siguiente que se esperaba ni tampoco una retransmision, me tengo que resincronizar con el blockno y proceso la respuesta..
                        doLog(1, "block no totalmente diferente %d  %d!\n", jcmBillAcceptor->recBlockNo, getNextBlockNo(aux)); 
                        jcmBillAcceptor->recBlockNo = getNextBlockNo(aux);
                        rdmWriteCtrlSignal(jcmBillAcceptor->communicationHandle, jcmBillAcceptor->devId,ackCmd,2);
                        waitForEot(jcmBillAcceptor);
                        cmd = *(jcmBillAcceptor->dataEvPtr+1);
                        executeStateMachine(jcmBillAcceptor->billValidStateMachine, cmd);
	                } 
                }
        } else {
        	rdmWriteCtrlSignal(jcmBillAcceptor->communicationHandle, jcmBillAcceptor->devId,nakCmd,2);
           	doLog(1, "readframe retorna NULLLLL\n"); 
            jcmBillAcceptor->commErrQty++;
        }
    } while ((jcmBillAcceptor->dataEvPtr == NULL) && ( jcmBillAcceptor->commErrQty < 3 ));


    if ( jcmBillAcceptor->commErrQty > 3 ) {
	jcmBillAcceptor->errorCause = ID003_COMM_ERROR;
	executeStateMachine(jcmBillAcceptor->billValidStateMachine, ID003_COMM_ERROR);
	}
    
/*unsigned char msjTypeAnsw;
	unsigned char devRead; 

	//saco lo del ack al principio 	//tengo que mezclar el cmd con el ackval para ir alternando:
	//jcmBillAcceptor->ackVal = ( ~jcmBillAcceptor->ackVal & 1);

	cmdHeader = ((cmdHeader & 0xF0) | jcmBillAcceptor->ackVal);
	jcmWrite(jcmBillAcceptor->devId, jcmBillAcceptor->protocol, cmdHeader, data, dataLen);
	jcmBillAcceptor->dataEvPtr = jcmRead( &devRead, jcmBillAcceptor->protocol, &jcmBillAcceptor->dataLenEvt );
 	msjTypeAnsw = (*jcmBillAcceptor->dataEvPtr) & 0xF0;

	if ( jcmBillAcceptor->dataEvPtr != NULL ) {
		if ( jcmBillAcceptor->ackVal == (*jcmBillAcceptor->dataEvPtr & 1 )) {
			jcmBillAcceptor->ackVal = ( ~jcmBillAcceptor->ackVal & 1); //si esta bien la rta lo cambio para la prox trama q envie

			++jcmBillAcceptor->dataEvPtr;
		
			if ( msjTypeAnsw == 0x70 )
				++jcmBillAcceptor->dataEvPtr;
			jcmBillAcceptor->commErrQty = 0;
			//solo analizo la respuesta si le estoy mandando el comando para poner en modo downloadMode
			if ( msjTypeAnsw == 0x50 ){
				if ( cmd == 0x50 )
					jcmBillAcceptor->downloadMode = (( jcmBillAcceptor->dataEvPtr[3] & 0x02 ) >> 1 );
				else
					jcmBillAcceptor->downloadMode = 1;
				//doLog(0,"MEI %d settDownloadMode %d\n ", jcmBillAcceptor->devId, jcmBillAcceptor->downloadMode); fflush(stdout);
			}

			if (( cmd == EVT_POLLSTATUS) || (cmd == EVT_PROCESSBILL)) {   
				processStatus(jcmBillAcceptor, jcmBillAcceptor->dataEvPtr, cmd);
				//executeStateMachine(jcmBillAcceptor->billValidStateMachine, jcmBillAcceptor->actualState);
			} else 
				executeStateMachine(jcmBillAcceptor->billValidStateMachine, cmd);
	
			return;
		} else {
			//doLog(0,"MEI %d MsgTypeAnswer %d\n ", jcmBillAcceptor->devId, msjTypeAnsw); fflush(stdout);
			if ( msjTypeAnsw == 0x50) {  
				jcmBillAcceptor->downloadMode = 1;
				//doLog(0,"MEI setDownloadMode y executeError %d\n ", jcmBillAcceptor->downloadMode); fflush(stdout);
				executeStateMachine(jcmBillAcceptor->billValidStateMachine, ID003_COMM_ERROR);
			
			}
		}

	}  else {
		jcmBillAcceptor->commErrQty++;
		if ( jcmBillAcceptor->commErrQty > 3 ) {
			jcmBillAcceptor->errorCause = ID003_COMM_ERROR;
			executeStateMachine(jcmBillAcceptor->billValidStateMachine, ID003_COMM_ERROR);
		}
	}*/
}

