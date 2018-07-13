
#include "rdm100.h"


#define RDM_NORMAL_CMD                  0x40
#define RDM_RESET_CMD                   0x30
#define RDM_INIT_CMD                    0x31
#define RDM_DEPOSIT_COUNT_CMD           0x41
#define RDM_DEPOSIT_COUNT_RESULT_CMD    0x42
#define RDM_REQ_CURRENCY_TABLE_CMD      0x51

//ActualState
#define RDM_POWERON  0x00
#define RDM_IDLING   0x01
#define RDM_INITIAL   0x02
#define RDM_WAIT_FOR_BANKNOTE_REMOVED_AFTER_INIT   0x03
#define RDM_WAIT_FOR_BANKNOTE_REMOVED_INLET_SLOT   0x06
#define RDM_WAIT_FOR_BANKNOTE_REMOVED_AFTER_DEPOSIT   0x07
#define RDM_RESET   0x11
#define RDM_ERROR   0x1F


unsigned char getNextBlockNo(unsigned char blockN)
{
    if (blockN == 0x39)
        return 0x30;
    else 
        return (blockN + 1);
}

BOOL rdmSendFrameProcess(JcmBillAcceptData *jcmBillAcceptor, unsigned char * dataCmd, int dataLen)
{
        rdmWriteFrame(dataCmd, dataLen);
        jcmBillAcceptor->dataEvPtr = rdmReadCtrlSignal( 1000 );
        if ( jcmBillAcceptor->dataEvPtr != NULL ){
           if ( !memcmp(jcmBillAcceptor->dataEvPtr, eotCmd, 2 )) {
                jcmBillAcceptor->dataEvPtr = rdmReadCtrlSignal( 1000 );
                if (( jcmBillAcceptor->dataEvPtr != NULL ) && ( !memcmp(jcmBillAcceptor->dataEvPtr, ackCmd, 2 ))){
                    rdmWriteCtrlSignal(eotCmd,2);
                    return 1;
                } 
           } else {
                if ( !memcmp(jcmBillAcceptor->dataEvPtr, ackCmd, 2 )){
                    rdmWriteCtrlSignal(eotCmd,2);
                    return 1;
                } 
           }     
        }     
        doLog(1, "hay que reenviar la ultima trama, IMPLEMENTAR! \n" ); 
        return 0;
}

void loadDisableRdm(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	doLog(1, "RDM %d loadDisable\n", jcmBillAcceptor->devId);//fflush(stdout);
	jcmBillAcceptor->canChangeStatus = 1;

}

static unsigned char startdeposit[3]= { 0x33, 0x41, 0x30};

void loadEnableRdm(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	doLog(1, "RDM %d loadES\n", jcmBillAcceptor->devId);
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

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	doLog(1, "RDM %d SendStartDepositing \n", jcmBillAcceptor->devId);
	rdmSendFrameProcess(jcmBillAcceptor, startdeposit, 3 );
}

void loadInitializingRdm(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;
//	int amountAux, curIdAux;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	doLog(1, "RDM %d LoadIS\n", jcmBillAcceptor->devId);//fflush(stdout);
    jcmBillAcceptor->recBlockNo = 0x30;
    jcmBillAcceptor->sndBlockNo = 0x30;
    jcmBillAcceptor->resetSent = 0;
    jcmBillAcceptor->actualState = 255;
	jcmBillAcceptor->canChangeStatus = 1;
   	jcmBillAcceptor->notifyInitApp = 0;

    
}

void loadReceivingBillRdm(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	doLog(1, "RDM %d loadRBill\n", jcmBillAcceptor->devId);fflush(stdout);
	jcmBillAcceptor->canChangeStatus = 0;
}

void loadErrorStateRdm(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	printf("RDM %d loadErrorS\n", jcmBillAcceptor->devId);//fflush(stdout);

	if ( jcmBillAcceptor->commErrorNotificationFcn != NULL )
		( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, jcmBillAcceptor->errorCause );
	printf("RDM %d LLLloadErrorS\n", jcmBillAcceptor->devId);//fflush(stdout);
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
        result = (unsigned short) *(jcmBillAcceptor->dataEvPtr+9);
    
        printf("PROCESS CURRENCY TABLE !!! \n"); 

        if (result == 0){
            for (i = 0; i < 24; i++){
                noteId = (unsigned short)*(jcmBillAcceptor->dataEvPtr+12+(i*11));
		if ((idx > (unsigned char)*(jcmBillAcceptor->dataEvPtr+11+(i*11))) && (noteId == 0x03))
			break;
                idx = (unsigned char)*(jcmBillAcceptor->dataEvPtr+11+(i*11));
                denomination = (unsigned char)*(jcmBillAcceptor->dataEvPtr+17+(i*11));
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
            jcmBillAcceptor->billTableLoaded = 1;
            jcmBillAcceptor->denominationQty = i;
            printf("currency table denomination qty %d \n", jcmBillAcceptor->denominationQty);
        } else{
            doLog(1, "currency table process execution result <> 0 %d!\n", result); 
        }
}

void startDepositCount(StateMachine *sm)
{    
       	JcmBillAcceptData *jcmBillAcceptor;

        jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
        doLog(1, "satart deposit count!\n" ); 
      //  jcmBillAcceptor->status = JCM_DISABLE ;
        rdmSendFrameProcess(jcmBillAcceptor, startdeposit, 3 );
}


static unsigned char initComand[2]= { 0x31, 0x31};
    
void sendInitializationCmd(StateMachine *sm)
{
       	JcmBillAcceptData *jcmBillAcceptor;

        jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	doProcessStatusRdm(jcmBillAcceptor, jcmBillAcceptor->dataEvPtr+2);
	doLog(1,"RDM sewn initiliazation comd actual state %d \n", jcmBillAcceptor->actualState);
	if (jcmBillAcceptor->actualState == 0x11 ) { //reset
	        doLog(1, "sending initialization\n" ); 
        	rdmSendFrameProcess(jcmBillAcceptor, initComand, 2 );
	}

}

void sendInitialCmd(StateMachine *sm)
{
       	JcmBillAcceptData *jcmBillAcceptor;

        jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	doLog(1,"RDM SEND initiliazation  \n");
       	rdmSendFrameProcess(jcmBillAcceptor, initComand, 2 );

}



static unsigned char reqCurComand[2]= { 0x32, 0x51};

void requestCurrencyRDM(StateMachine *sm)
{
       	JcmBillAcceptData *jcmBillAcceptor;

        jcmBillAcceptor = (JcmBillAcceptData *)sm->context;

        doLog(1, "request currency table\n" ); 
        rdmSendFrameProcess(jcmBillAcceptor, reqCurComand, 2 );

}


void doProcessStatusRdm(JcmBillAcceptData *jcmBillAcceptor, unsigned char *statusNew)
{
        jcmBillAcceptor->errorCause = 0;

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
	if (statusNew[1] == RDM_ERROR) 
        	jcmBillAcceptor->errorCause = statusNew[1];

       	if ( jcmBillAcceptor->actualState != statusNew[1]){
		if ((statusNew[1] == RDM_WAIT_FOR_BANKNOTE_REMOVED_AFTER_INIT) ||(statusNew[1] == RDM_WAIT_FOR_BANKNOTE_REMOVED_INLET_SLOT) ||(statusNew[1] == RDM_WAIT_FOR_BANKNOTE_REMOVED_AFTER_DEPOSIT) ){
			if ( jcmBillAcceptor->commErrorNotificationFcn != NULL )
				( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, 0xB4 );
		} else {
			//si el estado anterior era de error y ahora ya no lo es mas, debo notificar a la app el fin del error,,
			if ((jcmBillAcceptor->actualState == RDM_WAIT_FOR_BANKNOTE_REMOVED_AFTER_INIT) ||(jcmBillAcceptor->actualState == RDM_WAIT_FOR_BANKNOTE_REMOVED_INLET_SLOT) ||(jcmBillAcceptor->actualState == RDM_WAIT_FOR_BANKNOTE_REMOVED_AFTER_DEPOSIT) ){
				if ( jcmBillAcceptor->commErrorNotificationFcn != NULL )
					( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, 0 );
			}
		}
		
		jcmBillAcceptor->actualState = statusNew[1];
	}

/*        if (( statusNew[3] & 0x04 ) || ( statusNew[6] & 0x04 ))
		jcmBillAcceptor->hasBankNotesWaiting = 1;
	else
		jcmBillAcceptor->hasBankNotesWaiting = 0;
*/	
 /*       //sst3
        if (statusNew[2] != 0)
            jcmBillAcceptor->errorCause = statusNew[2];

        //sst4
        if (statusNew[3] != 0)
            jcmBillAcceptor->errorCause = statusNew[3];

        //sst5
        if (statusNew[4] != 0)
            jcmBillAcceptor->errorCause = statusNew[4];

        //sst6
        if (statusNew[5] != 0)
            jcmBillAcceptor->errorCause = statusNew[5];

        //sst7
        if (statusNew[6] != 0)
            jcmBillAcceptor->errorCause = statusNew[6];
        
*/
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

BOOL isOnPowerUpStatusRdm(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

    jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
    if (jcmBillAcceptor->actualState == 0)	//powerOn true 
        return 1;
    return 0;

}

BOOL isRDMStatusBusy(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

    jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
    if ( jcmBillAcceptor->sst[0] & 0x02 ) 
        return 1;
    return 0;

}

BOOL inOnInitStatusRDM(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

    jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//si el bit de reset esta en 

    if (jcmBillAcceptor->sst[0] & 0x01 ) 
        return 1;
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

    jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
    doLog(1, "SEND RESET RDM \n" ); 
    rdmSendFrameProcess(jcmBillAcceptor, resetComand, 8 );
}

typedef struct {
  unsigned short  noteId;
  unsigned short qty;
} CurrencyInfo;

CurrencyInfo currencyAccepted[24];

void notifyBillsAccepted(StateMachine *sm)
{
    JcmBillAcceptData *jcmBillAcceptor; 
    unsigned short result, i, j,x;
    unsigned char qtyRejected;
    
    jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
    
    printf("Notify bilss accepted!\n" ); 
    result = (unsigned short) *(jcmBillAcceptor->dataEvPtr+9);
    if ( result < 0xE000 ){  //si es 0 o error code hay que procesar los billetes igual, si es un codigo de warning entonces no se ejecuto el comando
         qtyRejected = (unsigned char)*(jcmBillAcceptor->dataEvPtr+11);
	 if (result != 0)
	         doLog(1, "FALTA notificar un error del validador codigo %d!\n", result); 
	
         doLog(1, "FALTA notificar bills rejected %d!\n", qtyRejected ); 
         memcpy(currencyAccepted,jcmBillAcceptor->dataEvPtr+12, 96);
         for (i = 0; i < jcmBillAcceptor->denominationQty; i++){
             currencyAccepted[i].noteId = SHORT_TO_L_ENDIAN(currencyAccepted[i].noteId);
             currencyAccepted[i].qty = SHORT_TO_L_ENDIAN(currencyAccepted[i].qty);
             for (x =0; ((x < 12) && (jcmBillAcceptor->convertionTable[x].noteId != currencyAccepted[i].noteId)) ;x++)
               ; 
             if ((x < 12) && (jcmBillAcceptor->convertionTable[x].noteId == currencyAccepted[i].noteId)){
                    if (currencyAccepted[i].qty > 0){
                        jcmBillAcceptor->amountChar = (long long) (jcmBillAcceptor->convertionTable[x].amount * MultipApp);
                        printf("rere Bills Accepted! amount %d qty %d \n", jcmBillAcceptor->convertionTable[x].amount, currencyAccepted[i].qty); 
                
                    ( *jcmBillAcceptor->billAcceptNotificationFcn )( jcmBillAcceptor->devId, jcmBillAcceptor->amountChar, jcmBillAcceptor->convertionTable[x].currencyId, currencyAccepted[i].qty );
		}
             } else 
                doLog(1, "NOT FOUND noteB id %d  qty %d!\n", currencyAccepted[i].noteId, currencyAccepted[i].qty); 
             
        }
    } else
        doLog(1, "notify bilss accepted command execution result warning >  E000  %d!\n", result ); 

    
}


////// Estados de la maquina de estados //////////////////////////////////

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
static Transition rdmInitStateTransitions[] =
{	
	 { RDM_DEPOSIT_COUNT_RESULT_CMD, NULL, notifyBillsAccepted, &rdmDisabledState }
	,{ SM_ANY, errorDetectedRdm, NULL, &rdmErrorState }
//	,{ RDM_NORMAL_CMD, NULL, processStatusRdm, &rdmInitializingState }
	,{ SM_ANY, isRDMStatusBusy, NULL, &rdmInitializingState }
	,{ RDM_RESET_CMD, NULL, sendInitializationCmd, &rdmInitializingState }
	,{ RDM_INIT_CMD, NULL, requestCurrencyRDM, &rdmInitializingState }
	,{ RDM_REQ_CURRENCY_TABLE_CMD, NULL, processCurrencyTable, &rdmInitializingState }
	,{ SM_ANY, isOnPowerUpStatusRdm, sendResetRdm, &rdmInitializingState }
	,{ SM_ANY, inOnInitStatusRDM, sendInitialCmd, &rdmInitializingState }
	,{ SM_ANY, currencyTableNotLoaded, requestCurrencyRDM, &rdmInitializingState }
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
	,{ SM_ANY, errorDetectedRdm, NULL, &rdmErrorState }
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
	,{ SM_ANY, isPreparedforDepositing, sendStartDepositingRdm, &rdmEnabledState }
	,{ SM_ANY, errorDetectedRdm, NULL, &rdmErrorState }
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
	 ,{ SM_ANY, NULL, NULL, &rdmErrorState }
};

State rdmErrorState = 
{      
  	loadErrorStateRdm,  // entry
  	NULL,                // exit
	rdmErrorStateTransitions
};

void waitForEot(JcmBillAcceptData *jcmBillAcceptor )
{
    unsigned char *buff;
   
    buff = rdmReadCtrlSignal( 1000 );
   
}

void pollRDM( JcmBillAcceptData *jcmBillAcceptor )
{
    unsigned char aux, cmd;
    
//	printf("<<<<<<<<<<<<<<<<<<<<<<<<<<<<< POLLRdmmmmmmm\n ");fflush(stdout);
    rdmWriteCtrlSignal( enqCmd, 4 );
//	printf("<<<<<<<<<<<<<<<<<<<<<<<<<<<<< POLLRdmmmmmmm 1\n ");fflush(stdout);
    jcmBillAcceptor->dataEvPtr = rdmReadFrame( 1000 );
//	printf("<<<<<<<<<<<<<<<<<<<<<<<<<<<<< POLLRdmmmmmmm 2 \n ");fflush(stdout);
    if ( jcmBillAcceptor->dataEvPtr != NULL ) {
            aux = *(jcmBillAcceptor->dataEvPtr);
    //    printf("<<<<<<<<<<<<<<<<<<<<<<<<<<<<< POLLRdmmmmmmm 3 \n ");fflush(stdout);
          if  (jcmBillAcceptor->recBlockNo == aux)     {
		jcmBillAcceptor->commErrQty = 0;
                jcmBillAcceptor->recBlockNo = getNextBlockNo(jcmBillAcceptor->recBlockNo);
                cmd = *(jcmBillAcceptor->dataEvPtr+1);
	//printf("<<<<<<<<<<<<<<<<<<<<<<<<<<<<< POLLRdmmmmmmm 4 \n ");fflush(stdout);
		if ( cmd == RDM_DEPOSIT_COUNT_RESULT_CMD){
			//para que si no llego a procesarlo no mande el ack asi deps de un corte me lo reenvia
			doProcessStatusRdm(jcmBillAcceptor, jcmBillAcceptor->dataEvPtr+2);
			executeStateMachine(jcmBillAcceptor->billValidStateMachine, cmd);
			rdmWriteCtrlSignal(ackCmd,2);
			waitForEot(jcmBillAcceptor);
		} else {
    //        	printf("<<<<<<<<<<<<<<<<<<<<<<<<<<<<< POLLRdmmmmmmm 5 \n ");fflush(stdout);

			rdmWriteCtrlSignal(ackCmd,2);
			waitForEot(jcmBillAcceptor);
			doProcessStatusRdm(jcmBillAcceptor, jcmBillAcceptor->dataEvPtr+2);
			executeStateMachine(jcmBillAcceptor->billValidStateMachine, cmd);
                }
          } else {
                doLog(1, "block no diferente esperado %d  %d!\n", jcmBillAcceptor->recBlockNo, jcmBillAcceptor->recBlockNo == aux); 
                if  (jcmBillAcceptor->recBlockNo ==  getNextBlockNo(aux))     {
                        //me reenvio la trama anterior, envio ack:
                    rdmWriteCtrlSignal(ackCmd,2);
                    waitForEot(jcmBillAcceptor);
                    
                }   else {
                    //si el block no no es el siguiente que se esperaba ni tampoco una retransmision, me tengo que resincronizar con el blockno y proceso la respuesta..
                    doLog(1, "block no totalmente diferente %d  %d!\n", jcmBillAcceptor->recBlockNo, getNextBlockNo(aux)); 
                    jcmBillAcceptor->recBlockNo = getNextBlockNo(aux);
                    rdmWriteCtrlSignal(ackCmd,2);
                    waitForEot(jcmBillAcceptor);
                    cmd = *(jcmBillAcceptor->dataEvPtr+1);
                    executeStateMachine(jcmBillAcceptor->billValidStateMachine, cmd);
                } 
          }
    } else {
           rdmWriteCtrlSignal(nakCmd,2);
      //     waitForEot(jcmBillAcceptor);
           doLog(1, "readframe retorna NULLLLL\n"); 
	jcmBillAcceptor->commErrQty++;
	if ( jcmBillAcceptor->commErrQty > 3 ) {
		jcmBillAcceptor->errorCause = ID003_COMM_ERROR;
		executeStateMachine(jcmBillAcceptor->billValidStateMachine, ID003_COMM_ERROR);
	}

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

