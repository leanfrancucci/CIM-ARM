#if 0
extern State ccnetInitializingState;
extern State ccnetEnabledState;
extern State ccnetDisabledState;
extern State ccnetReceivingBillState;
extern State ccnetErrorState;
extern State ccnetStartFirmwareUpd;
extern State ccnetFirmwareUpd; 
#else
static State ccnetInitializingState;
static State ccnetEnabledState;
static State ccnetDisabledState;
static State ccnetReceivingBillState;
static State ccnetErrorState;
State ccnetStartFirmwareUpd;
State ccnetFirmwareUpd; 
#endif

BOOL unExpectedPowerUpCcnet(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;	
	if ( jcmBillAcceptor->event >= CCNET_POWER_UP && jcmBillAcceptor->event <= CCNET_POWER_UP_BILL_STACKER ) { 
    //************************* logcoment
//		doLog(0,"ccnet Unexpected Power Up\n");fflush(stdout);
		jcmBillAcceptor->errorCause = ID003_COMM_ERROR;
		return 1;
	}
	return 0;
}


void loadInitializingCcnet(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	//doLog(0,"CCNET loadInitializing\n");fflush(stdout);
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//jcmBillAcceptor->canChangeStatus = 1;
	jcmBillAcceptor->errorResetQty 	= 21; ///para q mande el reset de toque

	if ( jcmBillAcceptor->firmImage != NULL )
		executeStateMachine(jcmBillAcceptor->billValidStateMachine, ID003_UPDATE_FIRM);
}

void loadCcnetErrorState(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	int cause;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;	
	//doLog(0,"CCNET loadErrorState cause: %d \n", jcmBillAcceptor->errorCause);fflush(stdout);
	jcmBillAcceptor->appNotifPowerUpBill = jcmBillAcceptor->errorResetQty = 0;
	jcmBillAcceptor->canChangeStatus = 0;
	cause = jcmBillAcceptor->errorCause;
	if ( cause == ID003_FAILURE )
		cause = jcmBillAcceptor->errorAditInfo;
	if ( jcmBillAcceptor->commErrorNotificationFcn != NULL && jcmBillAcceptor->errorCause != ID003_REJECTING ){
		( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, cause );
	} 
//	billAcceptorSetStatus( jcmBillAcceptor, JCM_DISABLE );
}

BOOL errorDetectedCCnet(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	//doLog(0,"JCMBillAcceptorMgr - Error detected ccnet? .. " ); 
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//si esta en estado initializing me quedo en estado de error para q si no se soluciona
	//no se vuelva a notificar
	if (( jcmBillAcceptor->event >= CCNET_STACKER_FULL && jcmBillAcceptor->event <= CCNET_COMM_ERROR ) ||
		( jcmBillAcceptor->event == CCNET_REJECTING )){

//		doLog(0,"errorDetectedCCnet -> Evento %d\n", jcmBillAcceptor->event);

		jcmBillAcceptor->errorCause = mapStatus( jcmBillAcceptor->protocol, jcmBillAcceptor->event);
		if ( jcmBillAcceptor->errorCause == ID003_FAILURE ) {
			jcmBillAcceptor->errorAditInfo = mapFailureCode( CCNET, *jcmBillAcceptor->dataEvPtr);
    //************************* logcoment
//			doLog(0,"CCNET errorDetected!! Failure: %d\n", jcmBillAcceptor->errorAditInfo ); fflush(stdout);
		}

//		doLog(0,"errorDetectedCCnet -> Mapped %d\n", jcmBillAcceptor->errorCause);
		//doLog(0,"[yes]\n" ); fflush(stdout);
		return 1;
	}		
	//doLog(0,"[NO]\n" ); fflush(stdout);
	return 0;
}

BOOL endErrorDetectedCCnet(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//si esta en estado initializing me quedo en estado de error para q si no se soluciona
	//no se vuelva a notificar
	if (( jcmBillAcceptor->event >= CCNET_STACKER_FULL && jcmBillAcceptor->event <= CCNET_COMM_ERROR ) ||
		( jcmBillAcceptor->event == CCNET_REJECTING ) || ( jcmBillAcceptor->event == CCNET_INITIALIZING )
		|| ( jcmBillAcceptor->event == CCNET_BUSY ) ){
		return 0;
	}else {
		if ( jcmBillAcceptor->commErrorNotificationFcn != NULL )
			( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, 0 );
	    //doLog(0,"CCNET endErrorDetected %d\n", jcmBillAcceptor->event ); fflush(stdout);
		return 1;
	}
}

BOOL shouldReset(StateMachine *sm) 
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
//	doLog(0,"Ccnet - Should reset??: ");
	if (( jcmBillAcceptor->event >= CCNET_STACKER_FULL && jcmBillAcceptor->event <= CCNET_FAILURE ) || ( jcmBillAcceptor->event == CCNET_POWER_UP_ACCEPTOR )) {
//	    doLog(0,"[ YES ]\n"); fflush(stdout);
		return 1;
	}
 //   doLog(0,"[ NO ]\n"); fflush(stdout);
	return 0;
}

BOOL isReadyToTransferCcnet(StateMachine *sm) 
{ 
	return 1; //ojotaaaaaa

}

void doTransferNextFrameCcnet(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	if ( jcmBillAcceptor->frameSize != 0 && jcmBillAcceptor->qtySentWithAck > 10 ){ 
		//abortar la actualizacion
		notifyFirmwareUpdate(sm, 255);
		gotoState( jcmBillAcceptor->billValidStateMachine, &ccnetErrorState );	
	} else {
		if ( jcmBillAcceptor->frameSize == 0 ){ //cuando llega el ack se limpia el ult frame enviado
			jcmBillAcceptor->firmwFrame[0] = 0x02; //write memory subcmd
			jcmBillAcceptor->frameSize = fread( &jcmBillAcceptor->firmwFrame[6], 1, jcmBillAcceptor->blockSize, jcmBillAcceptor->firmImage );
			jcmBillAcceptor->firmwFrame[1] = ((jcmBillAcceptor->frameSize + 12) & 0xFF00 ) >> 8; 
			jcmBillAcceptor->firmwFrame[2] = (jcmBillAcceptor->frameSize + 12) & 0x00FF; 
			jcmBillAcceptor->firmwFrame[3] = 0;//falta completar el offset en estos campos
			jcmBillAcceptor->firmwFrame[4] = (jcmBillAcceptor->fileOffset & 0xFF00 ) >> 8; 
			jcmBillAcceptor->firmwFrame[5] = jcmBillAcceptor->fileOffset & 0x00FF; 
			jcmBillAcceptor->fileOffset += jcmBillAcceptor->frameSize;
			///[logMan logAllFrame: firmwFrame len: frameSize + 6 dir: 0];
			//doLog(0, "frameSize %d\n", jcmBillAcceptor->frameSize);

			if ( jcmBillAcceptor->frameSize == 0 ){
				jcmBillAcceptor->firmwFrame[0] = 0x03; //end download subcommand
				billAcceptWriteRead( jcmBillAcceptor, 0x50, jcmBillAcceptor->firmwFrame, 1 );
				return;	
			}
			jcmBillAcceptor->framesQty++;
			jcmBillAcceptor->qtySentWithAck = 0;
		} else 
			jcmBillAcceptor->qtySentWithAck++;
	//	LOG_INFO( LOG_DEVICES,"qty without ACK %d\n", jcmBillAcceptor->qtySentWithAck);
		billAcceptWriteRead( jcmBillAcceptor, 0x50, jcmBillAcceptor->firmwFrame, jcmBillAcceptor->frameSize + 6 );
	}

}

void verifyDownloadResultCcnet(StateMachine *sm) 
{
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
    //************************* logcoment
//	doLog(0, "CCNET DownlaodEndResult %d\n", *jcmBillAcceptor->dataEvPtr); fflush(stdout);
	if ( *jcmBillAcceptor->dataEvPtr != 0xE0 )
		notifyFirmwareUpdate(sm, 255);
	else 
		notifyFirmwareUpdate(sm, 100);

}

void sendDownloadStartCcnet(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
}

void processBlockSizeCcnet(StateMachine *sm) 
{
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	if ( *jcmBillAcceptor->dataEvPtr >= 0 && *jcmBillAcceptor->dataEvPtr <= 9 )
		jcmBillAcceptor->blockSize = (int) pow(2, (unsigned char)*jcmBillAcceptor->dataEvPtr);
	else
		jcmBillAcceptor->blockSize = 512;

    //************************* logcoment
//	doLog(0,"CCNET blockSize %ld\n", jcmBillAcceptor->blockSize);fflush(stdout);
	jcmBillAcceptor->framesQtyRefreshProgress = ( jcmBillAcceptor->fileSize / jcmBillAcceptor->blockSize /100 ) + 1;
}

void requestBlockSizeCcnet(StateMachine *sm) 
{
	JcmBillAcceptData *jcmBillAcceptor;
	unsigned char dat;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	dat = 1;
	billAcceptWriteRead( jcmBillAcceptor, 0x50, &dat, 1 );

}

void loadFirmUpdateCcnet(StateMachine *sm) 
{
//	doLog(0,"CCNET loadFirmwareUpd\n");fflush(stdout);
}

void loadStartFirmUpdateCcnet(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	jcmBillAcceptor->status = JCM_DISABLE;
    //************************* logcoment
//	doLog(0,"CCNET loadStartFirmUpdate\n");fflush(stdout);
    *jcmBillAcceptor->jcmVersion = jcmBillAcceptor->billTableLoaded = 0; 
	jcmBillAcceptor->qtySentWithAck	 = 0;
	jcmBillAcceptor->qtyInvalidCmd = 0;
}

BOOL blockSizeUnknownCcnet(StateMachine *sm)
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	return ( jcmBillAcceptor->blockSize == 0);
}

void printAnyCcnet(StateMachine *sm) { 
}

void sendResetCcnet(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
    //************************* logcoment
//	doLog(0,"Send Reset CCnet Power up.. \n");
	billAcceptWriteRead( jcmBillAcceptor, getCommandCode(jcmBillAcceptor->protocol,RESET_CMD), NULL, 0 );
}

void verifySendResetCcnet(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//doLog(0,"verify Send Reset CCnet???.. %d %d\n", jcmBillAcceptor->errorResetQty, jcmBillAcceptor->resetSentQty );
	if ( jcmBillAcceptor->canResetVal && jcmBillAcceptor->resetSentQty < 10 ){
		if ( jcmBillAcceptor->errorResetQty >= 20 ){
			billAcceptWriteRead( jcmBillAcceptor, getCommandCode(jcmBillAcceptor->protocol,RESET_CMD), NULL, 0 );
			jcmBillAcceptor->errorResetQty = 0;
			jcmBillAcceptor->resetSentQty++;
    //************************* logcoment
//			doLog(0,"Send Reset CCnet.. %d %d\n", jcmBillAcceptor->errorResetQty, jcmBillAcceptor->resetSentQty );
		} else
			jcmBillAcceptor->errorResetQty++;
		return;
	}
	if ( jcmBillAcceptor->resetSentQty == 10 ){
		jcmBillAcceptor->resetSentQty++;
    //************************* logcoment
//		doLog(0,"Sending Hard Reset CCnet.. %d %d\n", jcmBillAcceptor->errorResetQty, jcmBillAcceptor->resetSentQty );
		safeBoxMgrResetDev( jcmBillAcceptor->devId );
	}

}

/*
	Esto es sin Escrow!
*/
#if 0
void sendStackCcnet(StateMachine *sm)
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
	doLog(0, "CCNET disabled %d, $ %d %d\n", billDisabled, jcmBillAcceptor->convertionTable[index ].amount, jcmBillAcceptor->currencyId );fflush(stdout);

	notifyBillAccepted( sm );
	billAcceptWriteRead( jcmBillAcceptor, getCommandCode(jcmBillAcceptor->protocol,RETURN_CMD), NULL, 0 );
	jcmBillAcceptor->resetSentQty = 0;

}

#else
/*
	Opcion con Escrow
*/
void sendStackCcnet(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	char billDisabled;
	unsigned char index;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;

	index = (unsigned char) *jcmBillAcceptor->dataEvPtr;
		
	jcmBillAcceptor->amountChar = (long long)jcmBillAcceptor->convertionTable[index ].amount * MultipApp;
	jcmBillAcceptor->currencyId = jcmBillAcceptor->convertionTable[index ].currencyId;
	billDisabled = jcmBillAcceptor->convertionTable[index].disabled;
	//printf( "Prueba con esceow JCMBillAcceptorMgr - index %d, disabled %d, amount %d currencyId %d\n", index, billDisabled, jcmBillAcceptor->convertionTable[index ].amount, jcmBillAcceptor->currencyId );fflush(stdout);

	if (( jcmBillAcceptor->status == JCM_ENABLE ) && ( !billDisabled ) && jcmBillAcceptor->amountChar > 0){
		billAcceptWriteRead( jcmBillAcceptor, getCommandCode(jcmBillAcceptor->protocol,STACK_CMD), NULL, 0 );
	} else {
		if ( jcmBillAcceptor->status == JCM_ENABLE  && billDisabled )		
			jcmBillAcceptor->amountChar	= -1; //para q no se notifiq si esta deshabilitado
		
		notifyBillAccepted( sm );
		billAcceptWriteRead( jcmBillAcceptor, getCommandCode(jcmBillAcceptor->protocol,RETURN_CMD), NULL, 0 );
	}
}


#endif

// Estados CCNET

/**
 *  Estado jcmInitializingState
 */
static Transition ccnetInitStateTransitions[] =
{
	 { ID003_UPDATE_FIRM, NULL, NULL, &ccnetStartFirmwareUpd }
	,{ SM_ANY, errorDetectedCCnet, NULL, &ccnetErrorState}
	,{ 0x8A, NULL, processCurrencyAssignment, &ccnetInitializingState } //currencyCmd ID003
	,{ 0x88, NULL, processFirmwareVersion, &ccnetInitializingState }		//versionCmd ID003
	,{ CCNET_RETURNED, NULL, sendAckNotification, &ccnetInitializingState }
	,{ CCNET_STACKED, NULL, sendVendValidNotification, &ccnetInitializingState }
	,{ CCNET_ESCROW, NULL, NULL, &ccnetReceivingBillState }
	,{ SM_ANY, isOnPowerUpStatus, sendResetCcnet, &ccnetInitializingState } //esto cambiarlo para bulk
	,{ SM_ANY, initDataMissing, NULL, &ccnetInitializingState }
	,{ CCNET_DISABLED, NULL, NULL, &ccnetDisabledState }
	,{ CCNET_IDLING, NULL, NULL, &ccnetEnabledState }
	,{ SM_ANY, NULL, printAny, &ccnetInitializingState }
};

static State ccnetInitializingState = 
{
  	loadInitializingCcnet,  // entry
  	NULL,                // exit
	ccnetInitStateTransitions
};

/**
 *  Estado Disabled
 */
 
static Transition ccnetDisabledStateTransitions[] =
{
	 { ID003_UPDATE_FIRM, NULL, NULL, &ccnetStartFirmwareUpd }
	,{ SM_ANY, errorDetectedCCnet, NULL, &ccnetErrorState }
	,{ SM_ANY, isNotJCMDisable, NULL, &ccnetEnabledState}
	,{ CCNET_RETURNED, NULL, sendAckNotification, &ccnetDisabledState }
	,{ SM_ANY, unExpectedPowerUpCcnet, NULL, &ccnetErrorState}
    ,{ CCNET_IDLING, NULL, doDisable, &ccnetDisabledState }
	,{ SM_ANY, NULL, NULL, &ccnetDisabledState }
};

static State ccnetDisabledState = 
{
  	loadDisable,  // entry
  	NULL,                // exit
	ccnetDisabledStateTransitions
};


/**
 *  Estado Enabled
 */
 
static Transition ccnetEnabledStateTransitions[] =
{
	 { ID003_UPDATE_FIRM, NULL, doDisable, &ccnetStartFirmwareUpd }
	,{ SM_ANY, errorDetectedCCnet, NULL, &ccnetErrorState}
	,{ SM_ANY, isJCMDisable, NULL, &ccnetDisabledState}
	,{ CCNET_RETURNED, NULL, sendAckNotification, &ccnetEnabledState }
	,{ SM_ANY, unExpectedPowerUpCcnet, NULL, &ccnetErrorState}
	,{ CCNET_DISABLED, NULL, doEnable, &ccnetEnabledState }
	,{ CCNET_ACCEPTING, NULL, NULL, &ccnetReceivingBillState }
	,{ CCNET_ESCROW, NULL, NULL, &ccnetReceivingBillState }
	,{ SM_ANY, NULL, NULL, &ccnetEnabledState }
};

static State ccnetEnabledState = 
{
  	loadEnable,  // entry
  	NULL,                // exit
	ccnetEnabledStateTransitions
};

/**
 *  Estado ReceivingBillState
 */

static Transition ccnetReceivingBillStateTransitions[] =
{
	// TODO: esto lo cambie de lugar para detectar primero un REJECTING e informarlo (Sole: Fijate si te parece...)
	// El evento REJECTING no se informa dentro de la funcion errorDetectedCCnet,
	 {CCNET_REJECTING, NULL, sendRejectNotification, &ccnetErrorState }
	,{ SM_ANY, errorDetectedCCnet, NULL, &ccnetErrorState}
	,{CCNET_ESCROW, NULL, sendStackCcnet, &ccnetReceivingBillState }
	,{CCNET_RETURNED, NULL, sendAckNotification, &ccnetReceivingBillState }
	,{CCNET_STACKED, NULL, sendVendValidNotification, &ccnetReceivingBillState }
	,{CCNET_IDLING, NULL, NULL, &ccnetEnabledState }
	,{CCNET_DISABLED, NULL, NULL, &ccnetDisabledState }
	,{SM_ANY, unExpectedPowerUpCcnet, NULL, &ccnetErrorState}
	,{SM_ANY, NULL, NULL, &ccnetReceivingBillState }
};

static State ccnetReceivingBillState = 
{
  	loadReceivingBill,  // entry
  	NULL,                // exit
	ccnetReceivingBillStateTransitions
};

/**
 *  Estado ErrorState
 */

static Transition ccnetErrorStateTransitions[] =
{
	  { ID003_UPDATE_FIRM, NULL, NULL, &ccnetStartFirmwareUpd }
	 ,{ 0x30, NULL, printAny, &ccnetErrorState }
	 ,{ SM_ANY, endErrorDetectedCCnet, NULL, &ccnetInitializingState }
	 ,{ SM_ANY, shouldReset, verifySendResetCcnet, &ccnetErrorState } //esto cambiarlo para bulk
	 ,{ SM_ANY, NULL, printAny, &ccnetErrorState }
};

static State ccnetErrorState = 
{      
  	loadCcnetErrorState,  // entry
  	NULL,                // exit
	ccnetErrorStateTransitions
};

static Transition ccnetStartFirmUpdateTransitions[] =
{
	  {CCNET_COMM_ERROR, maxTriesReached, abortUpdate, &ccnetErrorState }
	 ,{0x30, NULL, sendDownloadStartCcnet, &ccnetStartFirmwareUpd }
	 ,{0x51, NULL, processBlockSizeCcnet, &ccnetStartFirmwareUpd }
	 ,{SM_ANY, blockSizeUnknownCcnet, requestBlockSizeCcnet, &ccnetStartFirmwareUpd }
	 ,{0x50, NULL, NULL, &ccnetFirmwareUpd }
	 ,{SM_ANY, NULL, printAnyCcnet, &ccnetStartFirmwareUpd }

};

State ccnetStartFirmwareUpd = 
{
  	loadStartFirmUpdateCcnet,  // entry
  	NULL,                // exit
	ccnetStartFirmUpdateTransitions
};

static Transition ccnetFirmwareUpdateTransitions[] =
{
	  {0x50, isReadyToTransferCcnet, doTransferNextFrameCcnet, &ccnetFirmwareUpd }
	 ,{0x52, NULL, resetBuffer, &ccnetFirmwareUpd }
	 ,{0x53, NULL, verifyDownloadResultCcnet, &ccnetInitializingState }
	 ,{CCNET_COMM_ERROR, NULL, abortUpdate, &ccnetErrorState }
	 ,{SM_ANY, NULL, printAnyCcnet, &ccnetFirmwareUpd }
//	  {SM_ANY, NULL, doTransferNextFrameCcnet, &ccnetFirmwareUpd }
};

State ccnetFirmwareUpd = 
{
  	loadFirmUpdateCcnet,  // entry
  	NULL,                // exit
	ccnetFirmwareUpdateTransitions
};


int aton(unsigned char ch)
{
   int n;
   
   if( ch < 0x3A )
      n = ch-0x30; // le resta el '0' porq es numero
   else 
      n = ch-0x37; //le resta la base
   return n;
}

int convertHexFileToBin(JcmBillAcceptData *jcmBillAcceptor, char * firmware )
{
	//Convierte el archivo hex a bin. Retorna EL OFFSET para comenzar a enviar
	// el archivos y el handler firmImage apunta al archivo bin
	//o -1 en caso de error
	FILE *fpHex;
	char fileName[50];
	int count=0,u,recSize, offset;

	offset = -1;
	if (!( fpHex = fopen( firmware, "rb" ))){
    //************************* logcoment
//	   doLog(0, "CCNET Error opening HEX file %s", firmware ); fflush(stdout);
		return -1; //error
	}
	
	sprintf(fileName, "%s.bin", firmware);
	//creo el archivo bin:
	if (!( jcmBillAcceptor->firmImage = fopen( fileName, "wb" ))){
    //************************* logcoment
//	    doLog(0, "CCNETError creating BIN file %s", fileName );fflush(stdout);
		return -1;
	}
	
   while(1) {
      while( fgetc(fpHex)!=':' )
		;
      //aca levanto el tama�o de registro de datos		
      if(( recSize = 16 * aton(fgetc(fpHex))+aton(fgetc(fpHex))) ==0 ) {
         break;
      }

      //aca levanto el address
      u=16*16*16*aton(fgetc(fpHex))+16*16*aton(fgetc(fpHex))+16*aton(fgetc(fpHex))+aton(fgetc(fpHex));
      //record type:
      fgetc(fpHex);
      fgetc(fpHex);
      	
	  if ( offset == -1 ){
		 offset = u;
	  }
      while( u > count ){
   	     fputc(0,jcmBillAcceptor->firmImage);
       	 count++;
      }
      while( recSize > 0 ){
        fputc(16*aton(fgetc(fpHex))+aton(fgetc(fpHex)),jcmBillAcceptor->firmImage);
		recSize--;
		count++;
      }
    }
    fclose(fpHex);
    fclose(jcmBillAcceptor->firmImage);
	jcmBillAcceptor->firmImage = fopen( fileName, "rb" );

	return offset;	
}

void pollCcnet( JcmBillAcceptData *jcmBillAcceptor )
{
	char myData = 0;

	if (  jcmBillAcceptor->billValidStateMachine->currentState != &ccnetStartFirmwareUpd && jcmBillAcceptor->billValidStateMachine->currentState != &ccnetFirmwareUpd )
		billAcceptWriteRead( jcmBillAcceptor, getCommandCode(jcmBillAcceptor->protocol,STATUS_CMD), NULL, 0 );
	else
		//poll status downlaod
		billAcceptWriteRead( jcmBillAcceptor, 0x50, &myData, 1 );
}

