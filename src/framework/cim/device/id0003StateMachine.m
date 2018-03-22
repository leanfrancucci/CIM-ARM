#if 0
extern State jcmFirstState;
extern State jcmInitializingState;
extern State jcmEnabledState;
extern State jcmDisabledState;
extern State jcmReceivingBillState;
extern State jcmErrorState;
extern State jcmUpdateFirmware;
extern State jcmStartFirmwareUpd;
#else
static State jcmInitializingState;
static State jcmEnabledState;
static State jcmDisabledState;
static State jcmReceivingBillState;
static State jcmErrorState;
static State jcmUpdateFirmware;
static State jcmStartFirmwareUpd;
#endif

//retorna la cantidad de billetes stackeados en el ultimo deposito (si habia uno en curso..), y el importe y currencyId del ultomo billete stackeado:
unsigned short getLastStackedQtyJCM( JcmBillAcceptData *jcmBillAcceptor, long long *billAmount, int *currencyId )
{
	*billAmount = 0;
	*currencyId = 0;
	return 0;
}

BOOL unExpectedPowerUp(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;	
	if ( jcmBillAcceptor->event >= ID003_POWER_UP && jcmBillAcceptor->event <= ID003_POWER_UP_BILL_STACKER ) { 
    //************************* logcoment
//		doLog(0,"JCM Unexpected Power Up\n");fflush(stdout);
		jcmBillAcceptor->errorCause = ID003_COMM_ERROR;
		return 1;
	}
	return 0;
}


void loadFirstStateJCM(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;

    
    printf("JCM loadFirstStateJCM\n");
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;	
}

void loadErrorState(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	int cause;
	
    //************************* logcoment
//	doLog(0,"JCM loadErrorState\n");fflush(stdout);
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;	
	jcmBillAcceptor->appNotifPowerUpBill = jcmBillAcceptor->errorResetQty = 0;
	jcmBillAcceptor->canChangeStatus = 0;
	cause = jcmBillAcceptor->errorCause;
	if ( cause == ID003_FAILURE )
		cause = jcmBillAcceptor->errorAditInfo;

	if ( jcmBillAcceptor->commErrorNotificationFcn != NULL ){
		( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, cause );
	} 
//	billAcceptorSetStatus( jcmBillAcceptor, JCM_DISABLE );
}

void loadInitializing(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
    //************************* logcoment
//	doLog(0,"JCM loadInitializing \n");fflush(stdout);
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//jcmBillAcceptor->canChangeStatus = 1;
	jcmBillAcceptor->errorResetQty 	= 6; ///para q mande el reset de toque
	if ( jcmBillAcceptor->firmImage != NULL )
		executeStateMachine(jcmBillAcceptor->billValidStateMachine, ID003_UPDATE_FIRM);
}


void loadStartFirmUpdate(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//jcmBillAcceptor->canChangeStatus = 1;
	jcmBillAcceptor->qtySentWithAck	 = 0;
	jcmBillAcceptor->status = JCM_DISABLE;
	jcmBillAcceptor->framesQtyRefreshProgress = ( jcmBillAcceptor->fileSize / FIRM_UPD_DATA_SIZE /100 ) + 1;

	//doLog(0,"load firmware update\n");fflush(stdout);
    *jcmBillAcceptor->jcmVersion = jcmBillAcceptor->billTableLoaded = 0; 
}

void sendDownloadStart(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//doLog(0,"send download start %d\n", jcmBillAcceptor->qtySentWithAck );fflush(stdout);
	billAcceptWriteRead( jcmBillAcceptor, getCommandCode(jcmBillAcceptor->protocol, DOWNLOADSTART_CMD), NULL, 0 );
}

BOOL isReadyToTransfer(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	return ( *jcmBillAcceptor->dataEvPtr == 0 );
}

BOOL firmUpdatePending(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	return ( jcmBillAcceptor->firmImage != NULL );
}

void doTransferNextFrame(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
//	doLog(0,"do transfer next\n");fflush(stdout);
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	
	if ( jcmBillAcceptor->frameSize != 0 && jcmBillAcceptor->qtySentWithAck > 10 ){ 
		//abortar la actualizacion
		notifyFirmwareUpdate(sm, 255);
		loadErrorState(sm);
	} else {
		if ( jcmBillAcceptor->frameSize == 0 ){ //cuando llega el ack se limpia el ult frame enviado
			*((long*)&jcmBillAcceptor->firmwFrame[0])= LONG_TO_L_ENDIAN(jcmBillAcceptor->offsetTransfer);
			jcmBillAcceptor->frameSize = fread( &jcmBillAcceptor->firmwFrame[4], 1, FIRM_UPD_DATA_SIZE, jcmBillAcceptor->firmImage );
    //************************* logcoment
//			doLog(0,"frame size READ %d\n", jcmBillAcceptor->frameSize);fflush(stdout);
			if ( jcmBillAcceptor->frameSize == 0 ){
				billAcceptWriteRead( jcmBillAcceptor, getCommandCode(jcmBillAcceptor->protocol, DOWNLOADEND_CMD), NULL, 0 );
				return;	
			}
			jcmBillAcceptor->imageCrc = calcCrc(jcmBillAcceptor->imageCrc,&jcmBillAcceptor->firmwFrame[4], jcmBillAcceptor->frameSize ); 	
			jcmBillAcceptor->offsetTransfer += jcmBillAcceptor->frameSize;
			jcmBillAcceptor->framesQty++;
			jcmBillAcceptor->qtySentWithAck = 0;
		} else 
			jcmBillAcceptor->qtySentWithAck++;
	//	doLog(0,"qty without ACK %d\n", jcmBillAcceptor->qtySentWithAck);fflush(stdout);
		billAcceptWriteRead( jcmBillAcceptor, getCommandCode(jcmBillAcceptor->protocol, DOWNLOADDATA_CMD ), jcmBillAcceptor->firmwFrame, jcmBillAcceptor->frameSize + 4 );
	}
}


void verifyChecksumACK(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//falta verificar q el checksum de bien
	if ( SHORT_TO_B_ENDIAN(jcmBillAcceptor->imageCrc) == *((unsigned short*) &jcmBillAcceptor->dataEvPtr[1] )){
		notifyFirmwareUpdate(sm, 100);
    //************************* logcoment
//		doLog(0,"crcs OK!!! \n"); fflush(stdout);
	} else {
		notifyFirmwareUpdate(sm, 255);
		loadErrorState(sm);
    //************************* logcoment
//		doLog(0,"crcs error!!! %d %d \n", SHORT_TO_B_ENDIAN(jcmBillAcceptor->imageCrc),*((unsigned short*) &jcmBillAcceptor->dataEvPtr[1] )); fflush(stdout);
	}
	sendAckNotification(sm);
}

BOOL errorDetected(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
//	doLog(0,"JCMBillAcceptorMgr - Error detected? .. " ); 
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	if (( jcmBillAcceptor->event >= ID003_STACKER_FULL && jcmBillAcceptor->event <= ID003_COMM_ERROR ) 
		|| (jcmBillAcceptor->event == ID003_REJECTING )) { 
		jcmBillAcceptor->errorCause = jcmBillAcceptor->event;
		if ( jcmBillAcceptor->event == ID003_FAILURE ) {
			jcmBillAcceptor->errorAditInfo = *jcmBillAcceptor->dataEvPtr;
    //************************* logcoment
//			doLog(0,"JCM errorDetected!!! Failure: %d\n", jcmBillAcceptor->errorAditInfo ); fflush(stdout);
		}
	//	doLog(0,"[yes]\n" ); fflush(stdout);
		return 1;
	}
	//doLog(0,"[no]\n" ); fflush(stdout);
	return 0;
}

BOOL shouldResetID003(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	if ( jcmBillAcceptor->event >= ID003_STACKER_FULL && jcmBillAcceptor->event < ID003_COMM_ERROR )  
		return 1;
	return 0;
}

void sendResetID003(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;

	//solo para el powerup
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	if ( jcmBillAcceptor->canResetVal ) {
		billAcceptWriteRead( jcmBillAcceptor, getCommandCode(jcmBillAcceptor->protocol,RESET_CMD), NULL, 0 );
    //************************* logcoment
//		doLog(0,"Send Reset Power Up.. %d %d\n", jcmBillAcceptor->errorResetQty, jcmBillAcceptor->resetSentQty );
	}
}

void verifySendResetID003(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	if ( jcmBillAcceptor->canResetVal && jcmBillAcceptor->resetSentQty == 0 ){
		if ( jcmBillAcceptor->errorResetQty > 10 ){
    //************************* logcoment
		//	doLog(0,"Sending Hard Reset ID003.. %d %d\n", jcmBillAcceptor->errorResetQty, jcmBillAcceptor->resetSentQty );
			safeBoxMgrResetDev( jcmBillAcceptor->devId );
			jcmBillAcceptor->errorResetQty = 0;
			jcmBillAcceptor->resetSentQty++;
		} else
			jcmBillAcceptor->errorResetQty++;
		return;
	}
}

BOOL endErrorDetected(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//si esta en estado initializing me quedo en estado de error para q si no se soluciona
	//no se vuelva a notificar
	if ((( jcmBillAcceptor->event >= ID003_IDLING  && jcmBillAcceptor->event < ID003_INITIALIZING ) || 
		( jcmBillAcceptor->event >= ID003_POWER_UP && jcmBillAcceptor->event <= ID003_POWER_UP_BILL_STACKER )) &&
		( jcmBillAcceptor->event != ID003_REJECTING )){ 
		if ( jcmBillAcceptor->commErrorNotificationFcn != NULL )
			( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, 0 );
    //************************* logcoment
//	    doLog(0,"JCM endErrorDetected %d.. \n", jcmBillAcceptor->event ); fflush(stdout);
		return 1;
	}
	return 0;
}
	
void sendOptionalFunction(StateMachine *sm)
{
	unsigned char data[2];
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;

	//doLog(0,"************** ENVIANDO COMANDO OPTIONAL FUNCTION\n");
	data[0] = 2;
	data[1] = 0;
	billAcceptWriteRead( jcmBillAcceptor, 0xC5, data, 2 );

}


void sendStackID003(StateMachine *sm)
{
   JcmBillAcceptData *jcmBillAcceptor;
   char billDisabled;
   unsigned char index;
     jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
   if ( jcmBillAcceptor->protocol == ID003 )
       index = (unsigned char) *jcmBillAcceptor->dataEvPtr - 0x61;
   else
       index = (unsigned char) *jcmBillAcceptor->dataEvPtr;
         jcmBillAcceptor->amountChar = (long long)jcmBillAcceptor->convertionTable[index ].amount * MultipApp;
   jcmBillAcceptor->currencyId = jcmBillAcceptor->convertionTable[index ].currencyId;
   billDisabled = jcmBillAcceptor->convertionTable[index].disabled;
  // doLog(0, "JCM disabled %d, $ %d %d\n", billDisabled, jcmBillAcceptor->convertionTable[index ].amount, jcmBillAcceptor->currencyId );fflush(stdout);

   if (( jcmBillAcceptor->status == JCM_ENABLE ) && ( !billDisabled ) && jcmBillAcceptor->amountChar > 0){
       billAcceptWriteRead( jcmBillAcceptor, getCommandCode(jcmBillAcceptor->protocol,STACK_CMD), NULL, 0 );
   } else {
       if ( jcmBillAcceptor->status == JCM_ENABLE  && billDisabled )                 
			jcmBillAcceptor->amountChar    = -1; //para q no se notifiq si esta deshabilitado
       notifyBillAccepted( sm );
       //tanto por disabled o porque esta en modo validacion retorno el billete
       billAcceptWriteRead( jcmBillAcceptor, getCommandCode(jcmBillAcceptor->protocol,RETURN_CMD), NULL, 0 );
   }
	jcmBillAcceptor->resetSentQty = 0;
} 

void jcmNotifyAppInitalizationFinished(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;

	if  (jcmBillAcceptor->commErrorNotificationFcn != NULL) {
    //************************* logcoment
//			doLog(1,"JCM %d NOTIFICA app initializing\n", jcmBillAcceptor->devId);
			( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, 0 );
	}
}


/**
 *  Estado FirstState
 */

//tendria que identificar si el validador tambien se reincio o solo la consola???
static Transition jcmFirstStateTransitions[] =
{
	{ SM_ANY, NULL, jcmNotifyAppInitalizationFinished, &jcmInitializingState }
};

State jcmFirstState = 
{
  	loadFirstStateJCM,  // entry
  	NULL,                // exit
	jcmFirstStateTransitions
};

/**
 *  Estado jcmInitializingState
 */
static Transition jcmInitializingStateTransitions[] =
{
	 { ID003_UPDATE_FIRM, NULL, NULL, &jcmStartFirmwareUpd }
	,{ ID003_INITIALIZING, NULL, sendOptionalFunction, &jcmInitializingState}
	,{ SM_ANY, errorDetected, NULL, &jcmErrorState}
	,{ 0x8A, NULL, processCurrencyAssignment, &jcmInitializingState} //currencyCmd ID003
	,{ 0x88, NULL, processFirmwareVersion, &jcmInitializingState}		//versionCmd ID003
	,{ SM_ANY, initDataMissing, NULL, &jcmInitializingState }
	,{ SM_ANY, isOnPowerUpStatus, sendResetID003, &jcmInitializingState}
	,{ ID003_VEND_VALID, NULL, sendVendValidNotification, &jcmInitializingState }
	,{ ID003_DISABLED, NULL, NULL, &jcmDisabledState}
 	,{ID003_ACCEPTING, NULL, NULL, &jcmEnabledState }
	,{ID003_ESCROW, NULL, NULL, &jcmEnabledState }
	,{ ID003_IDLING, NULL, NULL, &jcmEnabledState }
	,{ SM_ANY, NULL, NULL, &jcmInitializingState }
};

static State jcmInitializingState = 
{
  loadInitializing,  // entry
  NULL,                // exit
	jcmInitializingStateTransitions
};

/**
 *  Estado Disabled
 */
 
static Transition jcmDisabledStateTransitions[] =
{
	 { ID003_UPDATE_FIRM, NULL, NULL, &jcmStartFirmwareUpd }
	,{ SM_ANY, errorDetected, NULL, &jcmErrorState}
	,{ SM_ANY, isNotJCMDisable, NULL, &jcmEnabledState}
	,{ SM_ANY, unExpectedPowerUp, NULL, &jcmErrorState}
    ,{ ID003_IDLING, NULL, doDisable, &jcmDisabledState }
	,{ SM_ANY, NULL, NULL, &jcmDisabledState }
};

static State jcmDisabledState = 
{
  loadDisable,  // entry
  NULL,                // exit
	jcmDisabledStateTransitions
};


/**
 *  Estado Enabled
 */
 
static Transition jcmEnabledStateTransitions[] =
{
	 { ID003_UPDATE_FIRM, NULL, NULL, &jcmStartFirmwareUpd }
	,{ ID003_REJECTING, NULL, sendRejectNotification, &jcmErrorState }
	,{ SM_ANY, errorDetected, NULL, &jcmErrorState}
	,{ SM_ANY, isJCMDisable, NULL, &jcmDisabledState}
	,{ SM_ANY, unExpectedPowerUp, NULL, &jcmErrorState}
	,{ ID003_DISABLED, NULL, doEnable, &jcmEnabledState }
	,{ ID003_ESCROW, NULL, NULL, &jcmReceivingBillState }
	,{ ID003_VEND_VALID, NULL, sendVendValidNotification, &jcmEnabledState }
	,{ ID003_ACCEPTING, NULL, NULL, &jcmReceivingBillState }
	,{ SM_ANY, NULL, NULL, &jcmEnabledState }
};

static State jcmEnabledState = 
{
  loadEnable,  // entry
  NULL,                // exit
	jcmEnabledStateTransitions
};

/**
 *  Estado ReceivingBillState
 */

static Transition jcmReceivingBillStateTransitions[] =
{
	 { ID003_ESCROW, NULL, sendStackID003, &jcmReceivingBillState }
	,{ ID003_VEND_VALID, NULL, sendVendValidNotification, &jcmReceivingBillState }
	,{ ID003_REJECTING, NULL, sendRejectNotification, &jcmErrorState }
	,{ ID003_STACKED, NULL, NULL, &jcmEnabledState }
	,{ ID003_IDLING, NULL, NULL, &jcmEnabledState }
	,{ SM_ANY, unExpectedPowerUp, NULL, &jcmErrorState}
	,{ SM_ANY, errorDetected, NULL, &jcmErrorState}
	,{ SM_ANY, NULL, NULL, &jcmReceivingBillState }
};

static State jcmReceivingBillState = 
{
  loadReceivingBill,  // entry
  NULL,                // exit
	jcmReceivingBillStateTransitions
};

/**
 *  Estado ErrorState
 */

static Transition jcmErrorStateTransitions[] =
{
	  {ID003_UPDATE_FIRM, NULL, NULL, &jcmStartFirmwareUpd }
	 ,{downloadStatusCmd, firmUpdatePending, NULL, &jcmStartFirmwareUpd }
	 ,{SM_ANY, endErrorDetected, NULL, &jcmInitializingState }
	 ,{SM_ANY, shouldResetID003, verifySendResetID003, &jcmErrorState }
	 ,{SM_ANY, NULL, printAny, &jcmErrorState }
};

static State jcmErrorState = 
{
  loadErrorState,  // entry
  NULL,                // exit
	jcmErrorStateTransitions
};

static Transition jcmStartFirmUpdateTransitions[] =
{
	  {ID003_COMM_ERROR, maxTriesReached, abortUpdate, &jcmErrorState }
	 ,{SM_ANY, errorDetected, sendDownloadStart, &jcmStartFirmwareUpd }
	 ,{ID003_DISABLED, NULL, sendDownloadStart, &jcmStartFirmwareUpd }
	 ,{ID003_IDLING, NULL, doDisable, &jcmStartFirmwareUpd }
	 ,{ID003_POWER_UP, NULL, sendDownloadStart, &jcmStartFirmwareUpd }
	 ,{0x50, NULL, NULL, &jcmUpdateFirmware }  
	 ,{downloadStatusCmd, NULL, NULL, &jcmUpdateFirmware }
	 ,{SM_ANY, NULL, printAny, &jcmStartFirmwareUpd }
	 
};

static State jcmStartFirmwareUpd = 
{
  	loadStartFirmUpdate,  // entry
  	NULL,                // exit
	jcmStartFirmUpdateTransitions
};


static Transition jcmUpdateFirmwareTransitions[] =
{
	 {0x50, NULL, resetBuffer, &jcmUpdateFirmware }
	 ,{downloadStatusCmd, isReadyToTransfer, doTransferNextFrame, &jcmUpdateFirmware }
	 ,{downloadEndStatusCmd, NULL, verifyChecksumACK, &jcmUpdateFirmware }
	 ,{ID003_POWER_UP, NULL, NULL, &jcmInitializingState }
	 ,{ID003_COMM_ERROR, maxTriesReached, abortUpdate, &jcmErrorState }
	 ,{SM_ANY, NULL, printAny, &jcmUpdateFirmware}
	 
};

static State jcmUpdateFirmware = 
{
  	NULL,  // entry
  	NULL,                // exit
  	
	jcmUpdateFirmwareTransitions
};
