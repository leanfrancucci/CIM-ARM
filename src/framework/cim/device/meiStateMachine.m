//Funciones nuevas de inicializaion del archivo del control de billstacked>

static char moneyStr[50];

void cleanLastBillFileStatus(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	int billQty, amount, status, currencyId;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;

	status = getValStatus(jcmBillAcceptor, &billQty, &amount, &currencyId );
	if (status == ID003_ESCROW){
	//	printf("Clean Last Escrow Bill MEI Val: %d STATUS %d \n", jcmBillAcceptor->devId, jcmBillAcceptor->actualState);//fflush(stdout);
		setValStatus(jcmBillAcceptor, 0, jcmBillAcceptor->billDepositQty, 0, 0);
	} 
	
}

void resetFileStatusMei(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//aca tengo que resetear la cantidad de billetes almacenados>
	printf("resetFileStatusMei MEI Val: %d \n", jcmBillAcceptor->devId);//fflush(stdout);
	jcmBillAcceptor->billDepositQty = 0;
	setValStatus(jcmBillAcceptor, 0, 0, 0, 0);
	jcmBillAcceptor->statusFiledReseted = 1;
}



//retorna la cantidad de billetes stackeados en el ultimo deposito (si habia uno en curso..), y el importe y currencyId del ultomo billete stackeado:
unsigned short getLastStackedQtyMEI( JcmBillAcceptData *jcmBillAcceptor, long long *billAmount, int *currencyId )
{
	int billQty, amount, status;

	status = getValStatus(jcmBillAcceptor, &billQty, &amount, currencyId );
	*billAmount = (long long) amount * MultipApp;
//	printf("GetLastStackedQtyMEIII  Val: %d, status %d billqty %d amount %d curid %d \n", jcmBillAcceptor->devId, status, billQty, amount, *currencyId);//fflush(stdout);
	jcmBillAcceptor->fileInfoRequested = 1;
	resetFileStatusMei(jcmBillAcceptor->billValidStateMachine );
	
	if (status == ID003_ESCROW){
		//TENGO QUE LEVANTAR UNA AUDITORIA, PORQUE NO ME LLEGO NUNCA UN STACKED NI RETURNED
		formatMoney(moneyStr, [[[CurrencyManager getInstance] getCurrencyById: *currencyId] getCurrencyCode], *billAmount, 2, 40);
		[Audit auditEventCurrentUser: Event_POWER_UP_WITH_ESCROW_STATUS additional: moneyStr station: jcmBillAcceptor->devId logRemoteSystem: FALSE];
//		printf("GENERE AUDITORIAAAA ESCROW VAL %d %s \n", jcmBillAcceptor->devId, moneyStr);//fflush(stdout);
	}
	

	return billQty;
}


enum {
	EVT_VERSION = 0X88, EVT_CURRENCY, EVT_POLLSTATUS, EVT_PROCESSBILL, EVT_COMM_ERROR 
};

//unsigned char inhibitAllDenominations[]= 
unsigned char requestCurrencyIdx0[4]= { 0x02, 0x00, 0x1C, 0x10 };
unsigned char stackCmd[4]= { 0x7F, 0x3C, 0x10 };
unsigned char returnCmd[4]= { 0x00, 0x5C, 0x10 };

void processStatus(JcmBillAcceptData *jcmBillAcceptor, unsigned char * stat, unsigned char cmd);

void meiAcceptWriteRead( JcmBillAcceptData *jcmBillAcceptor, unsigned char cmd, unsigned char cmdHeader, unsigned char * data, int dataLen )
{
	unsigned char msjTypeAnsw;
	unsigned char devRead; 

	//saco lo del ack al principio 	//tengo que mezclar el cmd con el ackval para ir alternando:
	//jcmBillAcceptor->ackVal = ( ~jcmBillAcceptor->ackVal & 1);

	cmdHeader = ((cmdHeader & 0xF0) | jcmBillAcceptor->ackVal);
	jcmWrite(jcmBillAcceptor->devId, jcmBillAcceptor->protocol, cmdHeader, data, dataLen);
	jcmBillAcceptor->dataEvPtr = jcmRead( &devRead, jcmBillAcceptor->protocol, &jcmBillAcceptor->dataLenEvt );

	if ( jcmBillAcceptor->dataEvPtr != NULL ) {

        msjTypeAnsw = (*jcmBillAcceptor->dataEvPtr) & 0xF0;
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
	}
}

unsigned short getBlockNo(unsigned char *data)
{
	unsigned char aux;
	unsigned short blockNo;

	aux = ((( data[0] << 4 ) & 0xF0 ) | ( data[1] & 0x0F ));
	blockNo = ((( data[2] << 4 ) & 0xF0 ) | ( data[3] & 0x0F ));
	blockNo = ( aux << 8 ) | blockNo;
	return blockNo;
}

int writeReadDownload (StateMachine *sm, unsigned char * data, int dataLen )
{
	unsigned char cmdH;
	unsigned char devRead; 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;

	//tengo que mezclar el cmd con el ackval para ir alternando:
	jcmBillAcceptor->ackVal = ( ~jcmBillAcceptor->ackVal & 1);
	cmdH = ( 0x50 | jcmBillAcceptor->ackVal);

	jcmWrite(jcmBillAcceptor->devId, jcmBillAcceptor->protocol, cmdH, data, dataLen);
	jcmBillAcceptor->dataEvPtr = jcmRead( &devRead, jcmBillAcceptor->protocol, &jcmBillAcceptor->dataLenEvt );

	if ( jcmBillAcceptor->dataEvPtr != NULL ){
		if ( jcmBillAcceptor->ackVal == (*jcmBillAcceptor->dataEvPtr & 1 )) {
			//aca tendria q evaluar ademas que no sea un nack en e l contenido de la trama
			if ( getBlockNo(&jcmBillAcceptor->dataEvPtr[1]) != 0xFFFF ){
				jcmBillAcceptor->commErrQty = 0;
				return 1;
			} else		
				printf("MEI %d ACK pero block No == FFFF \n", jcmBillAcceptor->devId);
		} else {
			//tengo q obtener el nro de bloq de la respuesta<!
			jcmBillAcceptor->blockNo = getBlockNo(&jcmBillAcceptor->dataEvPtr[1]);
			++jcmBillAcceptor->blockNo;
			printf("RESYNC finalBlockNo +1  %d\n", jcmBillAcceptor->blockNo);fflush(stdout);
		}
	}  
	jcmBillAcceptor->commErrQty++;
	return 0;
}

void prepareBlockNumber(StateMachine *sm) 
{
	JcmBillAcceptData *jcmBillAcceptor;
	unsigned char aux; 

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//high byte:	
	aux = ( jcmBillAcceptor->blockNo >> 8 )  & 0xFF;
	//doLog("highByte %d ", aux); 
	jcmBillAcceptor->firmwFrame[0] = ( aux >> 4 ) & 0x0F;
	jcmBillAcceptor->firmwFrame[1] = ( aux & 0x0F );
	//lowByte:
	aux = jcmBillAcceptor->blockNo & 0xFF;
	//doLog("lowByte %d\n", aux);fflush(stdout);
	jcmBillAcceptor->firmwFrame[2] = ( aux >> 4 ) & 0x0F;
	jcmBillAcceptor->firmwFrame[3] = ( aux & 0x0F );
}

BOOL transferFailed(StateMachine *sm) 
{
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	if ((jcmBillAcceptor->commErrQty != 0 ) && ( jcmBillAcceptor->commErrQty < 10))
		return 1;
	else
		return 0;
}

void doTransferSameFrameMei(StateMachine *sm) 
{
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;

	//doLog(0, "MEI %d doTransferSameFrame\n", jcmBillAcceptor->devId); fflush(stdout);
	prepareBlockNumber(sm);
	//doLog(0, "MEI %d Vuelvo a invertir el ack para q mande el mismo en la retransmision\n", jcmBillAcceptor->devId); fflush(stdout);
	jcmBillAcceptor->ackVal = ( ~jcmBillAcceptor->ackVal & 1);

	if ( writeReadDownload( sm, jcmBillAcceptor->firmwFrame, 68)){
		jcmBillAcceptor->framesQty++;
		//faltaria notificar el progreso...
		if ((( jcmBillAcceptor->framesQty % ( jcmBillAcceptor->framesQtyRefreshProgress + 1 ) )== jcmBillAcceptor->framesQtyRefreshProgress ) &&
			( jcmBillAcceptor->firmwareUpdateProgress != NULL ))
			( *jcmBillAcceptor->firmwareUpdateProgress )( jcmBillAcceptor->devId, jcmBillAcceptor->framesQty / jcmBillAcceptor->framesQtyRefreshProgress);
	
		jcmBillAcceptor->blockNo++;
	}		
}

void doTransferNextFrameMei(StateMachine *sm) 
{
	JcmBillAcceptData *jcmBillAcceptor;
	int i;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	if ( jcmBillAcceptor->commErrQty < 10 ) { //cuando llega el ack se limpia el ult frame enviado
		if ( jcmBillAcceptor->offsetTransfer < jcmBillAcceptor->fileSize )	{
			//tengo que preparar el blockNo
			prepareBlockNumber(sm);
		
			jcmBillAcceptor->frameSize = fread( jcmBillAcceptor->tempData, 1, 32, jcmBillAcceptor->firmImage );
			//doLog(0, "MEI %d frameSizeREAD %d\n", jcmBillAcceptor->devId, jcmBillAcceptor->frameSize); fflush(stdout);
			for ( i = 0; i < jcmBillAcceptor->frameSize; ++i) {
				jcmBillAcceptor->firmwFrame[4 + (i*2)] = ( jcmBillAcceptor->tempData[i] >> 4 ) & 0x0F;				
				jcmBillAcceptor->firmwFrame[(i*2)+5] = jcmBillAcceptor->tempData[i] & 0x0F;				
			} 
			//[logMan logAllFrame: firmwFrame len: 68 dir: READ_LOG ];
			jcmBillAcceptor->offsetTransfer += jcmBillAcceptor->frameSize;
			if ( writeReadDownload( sm, jcmBillAcceptor->firmwFrame, 68)){
				jcmBillAcceptor->framesQty++;
				//faltaria notificar el progreso...
				if ((( jcmBillAcceptor->framesQty % ( jcmBillAcceptor->framesQtyRefreshProgress + 1 ) )== jcmBillAcceptor->framesQtyRefreshProgress ) &&
					( jcmBillAcceptor->firmwareUpdateProgress != NULL ))
					( *jcmBillAcceptor->firmwareUpdateProgress )( jcmBillAcceptor->devId, jcmBillAcceptor->framesQty / jcmBillAcceptor->framesQtyRefreshProgress);
			
				jcmBillAcceptor->blockNo++;
			}		
		} else {
			//termino la actualizacion de firmware
				notifyFirmwareUpdate( sm, 100 );
				executeStateMachine(jcmBillAcceptor->billValidStateMachine, 0x00);
			//	[ owner resetSerialDevice: devId msecsDown: 5000 ];
		}

	} else {
		//hago un reset porque fallo la actualizacion
		doLog(0, "MEI %d updProcessFailed!\n", jcmBillAcceptor->devId); fflush(stdout);
		notifyFirmwareUpdate( sm, -1 );
		executeStateMachine(jcmBillAcceptor->billValidStateMachine, 0x00);
//		[ owner resetSerialDevice: devId msecsDown: 30000 ];
		
	}
	
}

void loadFistStateMei(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;
	

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;

    openValStatusFile(jcmBillAcceptor);

	printf("MEI %d LoadFIRSTSTATE  statusFile \n", jcmBillAcceptor->devId);//fflush(stdout);
  	jcmBillAcceptor->fileInfoRequested = 0;	
	jcmBillAcceptor->statusFiledReseted = 0;
	jcmBillAcceptor->notifyInitApp = 0;
	jcmBillAcceptor->downloadMode = 0;	
	jcmBillAcceptor->onPowerUp = 0;
	
	jcmBillAcceptor->pollCmd[0]= 0;
	jcmBillAcceptor->pollCmd[1]= 0x1C;
	jcmBillAcceptor->pollCmd[2]= 0x10;

}
//

void loadDisableMei(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	printf("MEI %d loadDisable\n", jcmBillAcceptor->devId);//fflush(stdout);
	jcmBillAcceptor->canChangeStatus = 1;
	jcmBillAcceptor->pollCmd[0]= 0;
	jcmBillAcceptor->pollCmd[1]= 0x1C;
	jcmBillAcceptor->pollCmd[2]= 0x10;
	//resetFileStatusMei( jcmBillAcceptor );

}

void loadEnableMei(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	printf("MEI %d loadES\n", jcmBillAcceptor->devId);
	jcmBillAcceptor->canChangeStatus = 1;
	jcmBillAcceptor->appNotifPowerUpBill = 0;
	jcmBillAcceptor->statusFiledReseted = 0;

	jcmBillAcceptor->pollCmd[0]= 0x7F;
	jcmBillAcceptor->pollCmd[1]= 0x1C;
	jcmBillAcceptor->pollCmd[2]= 0x10;
}

void loadInitializingMei(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;
//	int amountAux, curIdAux;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	jcmBillAcceptor->downloadMode = 0;	
	printf("MEI %d LoadIS\n", jcmBillAcceptor->devId);//fflush(stdout);
	jcmBillAcceptor->pollCmd[0]= 0;
	jcmBillAcceptor->pollCmd[1]= 0x1C;
	jcmBillAcceptor->pollCmd[2]= 0x10;
}

void loadReceivingBillMei(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	printf("MEI %d loadRBill\n", jcmBillAcceptor->devId);fflush(stdout);
	jcmBillAcceptor->canChangeStatus = 0;
	jcmBillAcceptor->pollCmd[0]= 0x7F;
	jcmBillAcceptor->pollCmd[1]= 0x1C;
	jcmBillAcceptor->pollCmd[2]= 0x10;

}

void loadErrorStateMei(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	printf("MEI %d loadErrorS\n", jcmBillAcceptor->devId);//fflush(stdout);

	jcmBillAcceptor->appNotifPowerUpBill = 0;
	jcmBillAcceptor->canChangeStatus = 0;

	if ( jcmBillAcceptor->errorCause != ID003_COMM_ERROR )
		cleanLastBillFileStatus(sm);

	if ( jcmBillAcceptor->errorCause == ID003_REJECTING ){
		if ( jcmBillAcceptor->billRejectNotificationFcn != NULL )
			( *jcmBillAcceptor->billRejectNotificationFcn )( jcmBillAcceptor->devId, 0x7B );//mando siempre "Operation Error" porq no me lo discrimina mei
	} else {
		if 	( jcmBillAcceptor->errorCause == ID003_CHEATED ) {
			//deshabilito el validador, NUEVO:
			printf("MEI deshabilito el validadorrr!\n");
			billAcceptorSetStatus( jcmBillAcceptor, JCM_DISABLE);
		}

		if ( jcmBillAcceptor->commErrorNotificationFcn != NULL )
			( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, jcmBillAcceptor->errorCause );

	}
}
void sendDownloadStartMei(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	memset( jcmBillAcceptor->bufAux, 0, 3);
	//doLog(0,"MEI %d sendDownloadStart!\n", jcmBillAcceptor->devId ); //fflush(stdout);
	meiAcceptWriteRead( jcmBillAcceptor, 0x50, 0x50, jcmBillAcceptor->bufAux, 3);
}

void loadStartFirmUpdateMei(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	jcmBillAcceptor->status = JCM_DISABLE;
	jcmBillAcceptor->framesQtyRefreshProgress = ( jcmBillAcceptor->fileSize / 32 /100 ) + 1;
    *jcmBillAcceptor->jcmVersion = jcmBillAcceptor->billTableLoaded = 0; 

	//sendDownloadStartMei(sm);
	//doLog(0, "MEI %d loadStartFirmUpd\n", jcmBillAcceptor->devId);//fflush(stdout);

}

void loadFirmUpdateMei(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;

    *jcmBillAcceptor->jcmVersion = jcmBillAcceptor->billTableLoaded = 0; 
	jcmBillAcceptor->blockNo = 0;
	msleep(2000);
	doLog(0, "MEI %d loadFirmUpd\n", jcmBillAcceptor->devId);fflush(stdout);
	//FIRMUPDATE!comento esta linea para que no mande en esta vuelta el primer frame
	//doTransferNextFrameMei(sm);
}


BOOL notInDownloadModeMei(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//doLog(1,"MEI %d downlaodmode?? %d\n", jcmBillAcceptor->devId, jcmBillAcceptor->downloadMode ); fflush(stdout);
	return !jcmBillAcceptor->downloadMode;
}

BOOL inDownloadModeMei(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//doLog(1,"MEI %d Indownlaodmode?? %d\n", jcmBillAcceptor->devId, jcmBillAcceptor->downloadMode ); fflush(stdout);
	return jcmBillAcceptor->downloadMode;
}

void processStatus(JcmBillAcceptData *jcmBillAcceptor, unsigned char * stat, unsigned char cmd)
{
	unsigned char newState;

///	if (( stat[0] & 0x10 ) && (jcmBillAcceptor->dataLenEvt <= 8 ))
	//	doLog(0,"MEi %d , STACEKD CORTO ------------LO IGNORO! \n", jcmBillAcceptor->devId);
	
	
	//verificar flags:
	// cambio aca, primero analizo los flags mas importantes:
	if (( stat[0] & 0x10 ) && (jcmBillAcceptor->dataLenEvt > 8 ))newState = ID003_STACKED;//si es un stacked corto lo ignoro
	else if ( stat[0] & 0x04 ) newState = ID003_ESCROW;
	else if ( stat[0] & 0x02 ) newState = ID003_ACCEPTING;
	else if ( stat[0] & 0x08 ) newState = ID003_STACKING;
	else if ( stat[0] & 0x20 ) newState = ID003_RETURNING;
	else if ( stat[0] & 0x40 ) newState = ID003_RETURNED;
	else if ( stat[0] & 0x01 ) newState = ID003_IDLING;
	// si no es ninguno de estos estados, el validador se encuentra en Out of Service
	else newState = ID003_FAILURE;

	if ( stat[1] & 0x01 ) {
		jcmBillAcceptor->errorCause = ID003_CHEATED;
	} else if ( stat[1] & 0x02 ) jcmBillAcceptor->errorCause = ID003_REJECTING;
	else if ( stat[1] & 0x04 ) jcmBillAcceptor->errorCause = ID003_JAM_IN_ACCEPTOR;
	else if ( stat[1] & 0x08 ) jcmBillAcceptor->errorCause = ID003_STACKER_FULL;
	else if (!( stat[1] & 0x10 )) jcmBillAcceptor->errorCause = ID003_STACKER_OPEN;
	else if ( stat[1] & 0x20 ) jcmBillAcceptor->errorCause = ID003_PAUSE;
	//else if ( stat[1] & 0x40 ) jcmBillAcceptor->errorCause = ID003_FAILURE;
	else if ( stat[2] & 0x04 ) jcmBillAcceptor->errorCause = ID003_FAILURE;
	else jcmBillAcceptor->errorCause = 0;
	
	if ( stat[2] & 0x01 ){
		//flag de powerup del validador encendido:
		if (!jcmBillAcceptor->onPowerUp  ){
			//si no estaba encendido notifico a la app
			if ( jcmBillAcceptor->commErrorNotificationFcn != NULL ){
				( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, ID003_POWER_UP );
				doLog(1, "MEI %d Notifico aplicacion un powerup del validador\n", jcmBillAcceptor->devId);//fflush(stdout);
			}
			[Audit auditEventCurrentUser: Event_POWER_UP additional: "" station: jcmBillAcceptor->devId logRemoteSystem: FALSE];
		}
		jcmBillAcceptor->onPowerUp = 1;
		doLog(0,"xxxxxx MEi %d , Process status ONPOWERUPPPPP true , stat[0]= %d, stat[1]= %d, actualState %d xxxxxxxxxxxxxxx\n", jcmBillAcceptor->devId, stat[0],stat[1], jcmBillAcceptor->actualState);
	} else
		jcmBillAcceptor->onPowerUp = 0;

	//Si no se da que> el estado actual es igual al nuevo y dicho estado es escrow, hago correr la maquina de estados>
	if (!((jcmBillAcceptor->actualState == newState) && (newState == ID003_ESCROW) && (cmd == EVT_PROCESSBILL))){	
		jcmBillAcceptor->actualState = newState;
		executeStateMachine(jcmBillAcceptor->billValidStateMachine, jcmBillAcceptor->actualState);
	}

}

int isBillDisabled( JcmBillAcceptData *jcmBillAcceptor, int amount, int currencyId )
{
	int i;

	for ( i = 0; i < jcmBillAcceptor->denominationsQty; ++i ){
		if ( jcmBillAcceptor->convertionTable[i].amount == amount && jcmBillAcceptor->convertionTable[i].currencyId == currencyId )
			return jcmBillAcceptor->convertionTable[i].disabled;
	}
	return 0;	
}

void processMeiFirmwareVersion(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	if (*jcmBillAcceptor->jcmVersion == 0 ){
		memcpy( jcmBillAcceptor->jcmVersion, jcmBillAcceptor->dataEvPtr, jcmBillAcceptor->dataLenEvt);
		jcmBillAcceptor->jcmVersion[jcmBillAcceptor->dataLenEvt] = 0;
	} else {
		jcmBillAcceptor->jcmVersion[9] = ' ';
		memcpy( &jcmBillAcceptor->jcmVersion[10], jcmBillAcceptor->dataEvPtr, jcmBillAcceptor->dataLenEvt);
		jcmBillAcceptor->jcmVersion[19] = 0;

	}
	printf("MEI %d FirmwVersion %s\n",  jcmBillAcceptor->devId, jcmBillAcceptor->jcmVersion); //fflush(stdout);

}

unsigned char processCurrencyAssignmentMei( JcmBillAcceptData *jcmBillAcceptor, int * amount, int * currencyId)
{
	unsigned char lastIdx = 0;
	unsigned char countryAux[4];
	int multip;

	if ( jcmBillAcceptor->dataLenEvt > 8 ) {

		jcmBillAcceptor->dataEvPtr += 6;
		lastIdx = *jcmBillAcceptor->dataEvPtr;
		if ( jcmBillAcceptor->dataEvPtr[2] != 0 ){ //comparo el primer caracter del country para saber si el registro tiene datos
			//copio el country 
			memcpy(countryAux, &jcmBillAcceptor->dataEvPtr[1],  3 );
			jcmBillAcceptor->dataEvPtr[7]= jcmBillAcceptor->dataEvPtr[10]= 0;
			//obtengo el multiplicador ( 10 a la exponente)
			multip = pow(10, atoi(&jcmBillAcceptor->dataEvPtr[8]) );
			//obtengo el amount multiplicando la base y multiplicador
			*amount = atoi(&jcmBillAcceptor->dataEvPtr[4]) * multip;
			//obtengo el currencyId a partir del countryStr. ahora lo mapeo de cashcode.. ver si coincide!
			*currencyId = getCurrencyIdFromISOStr( countryAux );
		//	doLog(1,"MEI %d processCurrAssigmnt countryStr %s curId %d\n",  jcmBillAcceptor->devId, countryAux, *currencyId); fflush(stdout);
			if ( jcmBillAcceptor->countryCode == 0  )
				jcmBillAcceptor->countryCode = *currencyId;
	
		} else {
			*amount = 0;
			*currencyId = 0;
		}
	} else {
		*amount = 0;
		*currencyId = 0;
	}
	return lastIdx;
}

void notifyBillAcceptedMei(StateMachine *sm)
{
	int amountAux, curIdAux, billQty;
	unsigned char valSt;

	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;


	processCurrencyAssignmentMei( jcmBillAcceptor, &amountAux, &curIdAux);
	jcmBillAcceptor->amountChar = (long long) amountAux * MultipApp;
	jcmBillAcceptor->currencyId = curIdAux;
	//doLog(1,"MEI %d Notify Bill accepted Amountchar %lld dataLen %d?\n", jcmBillAcceptor->devId, jcmBillAcceptor->amountChar, jcmBillAcceptor->dataLenEvt);

	if ( jcmBillAcceptor->amountChar > 0 ){
	/*
		//Si el validador estaba deshabilitado no tengo q informar el billaccepted porq la app se rompe, no sabe a que deposito asignarselo:	
		if( jcmBillAcceptor->status == JCM_DISABLE ) { 
			if ( jcmBillAcceptor->commErrorNotificationFcn != NULL)
				( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, ID003_POWER_UP_BILL_STACKER );
			doLog(1,"MEI %d NOTIFICA! POWERUPBILLSTACKER amount %lld validador disabled \n", jcmBillAcceptor->devId, jcmBillAcceptor->amountChar);
		}else{*/
			jcmBillAcceptor->billDepositQty++;
			setValStatus(jcmBillAcceptor, ID003_STACKED, jcmBillAcceptor->billDepositQty, amountAux, jcmBillAcceptor->currencyId);
			if ( jcmBillAcceptor->billAcceptNotificationFcn != NULL ) {
				( *jcmBillAcceptor->billAcceptNotificationFcn )( jcmBillAcceptor->devId, jcmBillAcceptor->amountChar, jcmBillAcceptor->currencyId, 1 );
				doLog(1,"Mei %d NOTIFICA! %lld\n", jcmBillAcceptor->devId,jcmBillAcceptor->amountChar );
				//setValStatus(jcmBillAcceptor, 0, jcmBillAcceptor->billDepositQty, amountAux, jcmBillAcceptor->currencyId);
			}
	//F	}
		jcmBillAcceptor->amountChar = 0;
	} else {
		//doLog(1,"NOTIFICA//// POWERUPBILLSTACKER %d\n", jcmBillAcceptor->onPowerUp);
			valSt = getValStatus(jcmBillAcceptor, &billQty, &amountAux, &curIdAux);
			jcmBillAcceptor->amountChar = amountAux * MultipApp;
			if ( valSt == ID003_ESCROW ) {
				if (( jcmBillAcceptor->billAcceptNotificationFcn != NULL ) && (amountAux > 0)) {
					jcmBillAcceptor->billDepositQty++;
					setValStatus(jcmBillAcceptor, ID003_STACKED, jcmBillAcceptor->billDepositQty, amountAux, curIdAux);
					( *jcmBillAcceptor->billAcceptNotificationFcn )( jcmBillAcceptor->devId, jcmBillAcceptor->amountChar, curIdAux,1 );
					doLog(1,"Mei %d NOTIFICA BILL ACCEPTED VALOR ESCROW! %d\n", jcmBillAcceptor->devId,amountAux );
				}
		//		setValStatus(jcmBillAcceptor, 0, jcmBillAcceptor->billDepositQty, amountAux, curIdAux);
			} else {
				if ( jcmBillAcceptor->onPowerUp  ){
					if  (jcmBillAcceptor->commErrorNotificationFcn != NULL)
						( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, ID003_POWER_UP_BILL_STACKER );
					doLog(1,"MEI %d NOTIFICA! POWERUPBILLSTACKER sin valor\n", jcmBillAcceptor->devId);
		
				}
			}
	}
}

BOOL shouldResetStatusFile(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
  //  printf("MEI ShoulDResetStatusFIle %d\n", (jcmBillAcceptor->fileInfoRequested && (!jcmBillAcceptor->statusFiledReseted)));
	return (jcmBillAcceptor->fileInfoRequested && (!jcmBillAcceptor->statusFiledReseted));
}

BOOL didNotNotifyApp(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	return (!jcmBillAcceptor->notifyInitApp);

}

BOOL appRequestedFileInfo(StateMachine *sm) 
{
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	return jcmBillAcceptor->fileInfoRequested;
}

void notifyAppInitalizationFinished(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;

	if  ((jcmBillAcceptor->commErrorNotificationFcn != NULL) && (!jcmBillAcceptor->notifyInitApp) ){
			//printf("MEI %d NOTIFICA app initializing\n", jcmBillAcceptor->devId);
			( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, 0 );
	}
	jcmBillAcceptor->notifyInitApp= 1;
}

void notifyAppInitalizationFinishedWithError(StateMachine *sm)
{
	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;

	if  ((jcmBillAcceptor->commErrorNotificationFcn != NULL) && (!jcmBillAcceptor->notifyInitApp) ){
		//	printf("MEI %d NOTIFICA app initializing with communication error\n", jcmBillAcceptor->devId);
			( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, ID003_COMM_ERROR );
	}
	jcmBillAcceptor->notifyInitApp= 1;
}


void powerUpBillAcceptedMei(StateMachine *sm)
{
	int amountAux, curIdAux, billQty;
	unsigned char valSt;

	JcmBillAcceptData *jcmBillAcceptor;
	
	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;


	//printf("STACKED CON EL POWERUP VALIDADOR %d\n", jcmBillAcceptor->devId); //fflush(stdout);

	valSt = getValStatus(jcmBillAcceptor, &billQty, &amountAux, &curIdAux);
	jcmBillAcceptor->amountChar = amountAux * MultipApp;
	jcmBillAcceptor->currencyId = curIdAux;
	if ( valSt == ID003_ESCROW ) {
			billQty++;
			setValStatus(jcmBillAcceptor, ID003_STACKED, billQty, amountAux, curIdAux);
	} else {
		//o deberia levantar una se;al de alarma?
			if  (jcmBillAcceptor->commErrorNotificationFcn != NULL)
				( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, ID003_POWER_UP_BILL_STACKER );
		//	printf("MEI %d NOTIFICA! POWERUPBILLSTACKER sin valor\n", jcmBillAcceptor->devId);
	}
}

void requestStackMei(StateMachine *sm) 
{ 
	int amountAux, curIdAux;
	JcmBillAcceptData *jcmBillAcceptor;
	char billDisabled = 0;
	//int status, billQty;


	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;


	//Verifco que hay en el archivo temporal para levantar una alarma en caso que hubiese un escrow de antes>
	/*status = getValStatus(jcmBillAcceptor, &billQty, &amountAux, &curIdAux );
	if (status == ID003_ESCROW){
		//Lewvantar alarmaaaaaaaaaaa
		jcmBillAcceptor->amountChar = (long long) amountAux * MultipApp;
		formatMoney(moneyStr, [[[CurrencyManager getInstance] getCurrencyById: curIdAux] getCurrencyCode], jcmBillAcceptor->amountChar, 2, 40);
		[Audit auditEventCurrentUser: Event_ESCROW_STATUS_DUPLICATED additional: moneyStr station: jcmBillAcceptor->devId logRemoteSystem: FALSE];
		doLog(0, "GENERE AUDITORIAAAA ESCROW VAL %d %s \n", jcmBillAcceptor->devId, moneyStr);//fflush(stdout);

	}
*/
	processCurrencyAssignmentMei( jcmBillAcceptor, &amountAux, &curIdAux);

	jcmBillAcceptor->amountChar = (long long) amountAux * MultipApp;
	jcmBillAcceptor->currencyId = curIdAux;

	doLog(1, "MEI %d ESCROW: $ %d %d\n", jcmBillAcceptor->devId, amountAux, curIdAux );
	billDisabled = isBillDisabled( jcmBillAcceptor, amountAux, curIdAux );
	
	if ( amountAux > 0 ){
		
		if (( jcmBillAcceptor->status == JCM_ENABLE ) && ( !billDisabled ) ){
			setValStatus(jcmBillAcceptor, ID003_ESCROW, jcmBillAcceptor->billDepositQty, amountAux, jcmBillAcceptor->currencyId);
			//aca le indico q lo almacene:
			memcpy( jcmBillAcceptor->bufAux, stackCmd, 3);
			meiAcceptWriteRead( jcmBillAcceptor, EVT_PROCESSBILL, 0x10, jcmBillAcceptor->bufAux, 3);

		} else {
			//doLog(1,"req stat1 %ld\n", jcmBillAcceptor->amountChar );
			if ( jcmBillAcceptor->status == JCM_VALIDATE_ONLY )		{
				if ( jcmBillAcceptor->billAcceptNotificationFcn != NULL ) 
					( *jcmBillAcceptor->billAcceptNotificationFcn )( jcmBillAcceptor->devId, jcmBillAcceptor->amountChar, jcmBillAcceptor->currencyId, 1 );

			}
		
			memcpy( jcmBillAcceptor->bufAux, returnCmd, 3);
			meiAcceptWriteRead( jcmBillAcceptor, EVT_PROCESSBILL, 0x10, jcmBillAcceptor->bufAux, 3);
		}

	} else {
		//como no lo puedo identificar lo retorno y listo!	
		memcpy( jcmBillAcceptor->bufAux, returnCmd, 3);
		meiAcceptWriteRead( jcmBillAcceptor, EVT_PROCESSBILL, 0x10, jcmBillAcceptor->bufAux, 3);
	}
	jcmBillAcceptor->resetSentQty = 0; //reseteo la cantidad de resets, asi si hay error pueda seguir enviando resets fisicos
}

void returnBillMei(StateMachine *sm) 
{
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	memcpy( jcmBillAcceptor->bufAux, returnCmd, 3);
	meiAcceptWriteRead( jcmBillAcceptor, EVT_PROCESSBILL, 0x10, jcmBillAcceptor->bufAux, 3);
}

BOOL initDataMissingMei(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;

	// falta cargar la tabla de denominaciones:

	if ( !jcmBillAcceptor->billTableLoaded ) {
		memcpy(jcmBillAcceptor->bufAux, requestCurrencyIdx0, 4);
		jcmBillAcceptor->bufAux[4] = 1;//first currency idx
		jcmBillAcceptor->denominationsQty = 0;
		//LOG_INFO( LOG_DEVICES,"JCMBillAcceptor Mgr -> - request currency/return!" ); 
		memset( jcmBillAcceptor->convertionTable, 0, sizeof(jcmBillAcceptor->convertionTable));
		meiAcceptWriteRead( jcmBillAcceptor, EVT_CURRENCY, 0x70, jcmBillAcceptor->bufAux, 5);
		return 1;
	}
	
	if ( *jcmBillAcceptor->jcmVersion == 0 ){
		memset(jcmBillAcceptor->bufAux, 0, 2);
		jcmBillAcceptor->bufAux[2] = 9;
		meiAcceptWriteRead( jcmBillAcceptor, EVT_VERSION, 0x60, jcmBillAcceptor->bufAux, 3);
		return 1;
	}

	if ( strlen(jcmBillAcceptor->jcmVersion) <= 9 ){
		memset(jcmBillAcceptor->bufAux, 0, 2);
		jcmBillAcceptor->bufAux[2] = 7;
		meiAcceptWriteRead( jcmBillAcceptor, EVT_VERSION, 0x60, jcmBillAcceptor->bufAux, 3);
		return 1;
	}

	return 0;
}

BOOL errorDetectedMei(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	return ( jcmBillAcceptor->errorCause > 0 );

}

BOOL meiErrorComunication(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	return ( jcmBillAcceptor->errorCause == ID003_COMM_ERROR );

}

BOOL endErrorDetectedMei(StateMachine *sm) 
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	if ( jcmBillAcceptor->errorCause == 0) {
		if ( jcmBillAcceptor->commErrorNotificationFcn != NULL )
			( *jcmBillAcceptor->commErrorNotificationFcn )( jcmBillAcceptor->devId, 0 );
    	printf( "MEI %d endErrorDetected \n", jcmBillAcceptor->devId ); 
		return 1;
	}
	return 0;

}

BOOL isOnPowerUpStatusMei(StateMachine *sm)
{ 
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	return jcmBillAcceptor->onPowerUp;
}

void addCurrencyToList( JcmBillAcceptData *jcmBillAcceptor, int amount, int currencyId)
{
	int i;

	/*
		Solo agrego el detalle de la moneda si se refiere a una moneda nueva..
		Los validadores MEI no se porque entregan en su lista de monedas,
		varias repetidas con algun campo distinto (q a mi no me sirve para nada.. )
	*/	
	for ( i = 0; i < jcmBillAcceptor->denominationsQty; ++i ){
		if ( jcmBillAcceptor->convertionTable[i].amount == amount && jcmBillAcceptor->convertionTable[i].currencyId == currencyId )
			break;
	}
	
	if ( i == jcmBillAcceptor->denominationsQty ) {
		printf("MEI CurrItem: $ %d %d\n", amount, currencyId );// fflush(stdout);
		jcmBillAcceptor->convertionTable[i].amount = amount;
		jcmBillAcceptor->convertionTable[i].currencyId = currencyId;
		++jcmBillAcceptor->denominationsQty;
	} 

}


void requestNextCurrencyItemMei(StateMachine *sm) 
{ 
	unsigned char lastIdx;
	int amountAux, curIdAux;
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	lastIdx = processCurrencyAssignmentMei( jcmBillAcceptor, &amountAux, &curIdAux);
	if ( amountAux > 0 ){
		//para no insertar mas de una vez una moneda
		addCurrencyToList( jcmBillAcceptor, amountAux, curIdAux );

		//doLog( "Mei - amount %d curId %d\n", jcmBillAcceptor->convertionTable[lastIdx].amount, jcmBillAcceptor->convertionTable[lastIdx].currencyId ); fflush(stdout);

		//pidio el siguiente elemento de la tabla
		memcpy(jcmBillAcceptor->bufAux, requestCurrencyIdx0, 4);
		jcmBillAcceptor->bufAux[4] = lastIdx + 1;//first currency idx
		meiAcceptWriteRead( jcmBillAcceptor, EVT_CURRENCY, 0x70, jcmBillAcceptor->bufAux, 5);

	} else {
		jcmBillAcceptor->billTableLoaded = 1;
	}
}

BOOL shouldResetMei(StateMachine *sm) 
{
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	//doLog(0,"Mei %d- Should reset mei? %d\n", jcmBillAcceptor->devId, jcmBillAcceptor->errorCause);fflush(stdout);
	if ( jcmBillAcceptor->errorCause >= ID003_JAM_IN_ACCEPTOR && jcmBillAcceptor->errorCause <= ID003_COMM_ERROR ) 
		return 1;
	return 0;
}

void sendResetMei(StateMachine *sm) 
{
	JcmBillAcceptData *jcmBillAcceptor;

	jcmBillAcceptor = (JcmBillAcceptData *)sm->context;
	printf("Mei %d - ErrorCause: %d SEnd Hard reset? resetSentQty: %d errorResetQty%d\n", jcmBillAcceptor->devId, jcmBillAcceptor->errorCause, jcmBillAcceptor->resetSentQty, jcmBillAcceptor->errorResetQty);fflush(stdout);
	if ( jcmBillAcceptor->resetSentQty < 3 ) {
		if ( jcmBillAcceptor->errorResetQty >= 10 )	{
			printf("Mei - SEnd Hard reset!!!!!!!!!!!!!! \n");fflush(stdout);
			safeBoxMgrResetDev( jcmBillAcceptor->devId );
			//mando un solo reeset fisico por estado de error al q se ingresa
			jcmBillAcceptor->resetSentQty++;
			jcmBillAcceptor->errorResetQty = 0; 

		} else 
			jcmBillAcceptor->errorResetQty++; 
	}
}

////// Estados de la maquina de estados //////////////////////////////////

extern State meiFirstState;
extern State meiInitializingState;
extern State meiEnabledState;
extern State meiDisabledState;
extern State meiReceivingBillState;
extern State meiErrorState;
extern State meiStartFirmwareUpd;
extern State meiUpdateFirmware;


/**
 *  Estado FirstState
 */

//tendria que identificar si el validador tambien se reincio o solo la consola???
static Transition meiFirstStateTransitions[] =
{
	{ ID003_STACKED, NULL, powerUpBillAcceptedMei, &meiFirstState }
	,{ ID003_ESCROW, NULL, returnBillMei, &meiFirstState }
	,{ ID003_RETURNING, NULL, NULL, &meiFirstState }
//	,{ ID003_RETURNED, NULL, resetFileStatusMei, &meiFirstState }
	,{ ID003_RETURNED, NULL, cleanLastBillFileStatus, &meiFirstState }
	,{ SM_ANY, meiErrorComunication, notifyAppInitalizationFinishedWithError, &meiFirstState}
	,{ ID003_UPDATE_FIRM, NULL, NULL, &meiStartFirmwareUpd }
	,{ SM_ANY, inDownloadModeMei, notifyAppInitalizationFinishedWithError, &meiFirstState} //cambiar notificacion!
	,{ SM_ANY, isOnPowerUpStatusMei, NULL, &meiFirstState }
	//,{ SM_ANY, isOnPowerUpStatusMei, verifySendResetMei, &meiInitializingState }
//	,{ SM_ANY, appRequestedFileInfo, NULL, &meiInitializingState }
	//,{ SM_ANY, didNotNotifyApp, notifyAppInitalizationFinished, &meiFirstState }
	,{ SM_ANY, NULL, notifyAppInitalizationFinished, &meiInitializingState }
};

State meiFirstState = 
{
  	loadFistStateMei,  // entry
  	NULL,                // exit
	meiFirstStateTransitions
};


/**
 *  Estado jcmInitializingState
 */
static Transition meiInitStateTransitions[] =
{
	 { ID003_UPDATE_FIRM, NULL, NULL, &meiStartFirmwareUpd }
	,{ ID003_STACKED, appRequestedFileInfo, notifyBillAcceptedMei, &meiInitializingState }
	,{ ID003_STACKED, NULL, powerUpBillAcceptedMei, &meiInitializingState }
	,{ ID003_RETURNED, NULL, cleanLastBillFileStatus, &meiInitializingState }
	,{ SM_ANY, errorDetectedMei, NULL, &meiErrorState}
	,{ EVT_CURRENCY, NULL, requestNextCurrencyItemMei, &meiInitializingState }
	,{ EVT_VERSION, NULL, processMeiFirmwareVersion, &meiInitializingState }
	,{ SM_ANY, initDataMissingMei, NULL, &meiInitializingState }
	,{ ID003_ACCEPTING, NULL, NULL, &meiReceivingBillState }
	,{ ID003_ESCROW, NULL, NULL, &meiReceivingBillState }
	//,{ SM_ANY, isOnPowerUpStatusMei, verifySendResetMei, &meiInitializingState }
	,{ SM_ANY, isNotJCMDisable, NULL, &meiEnabledState}
	,{ SM_ANY, isJCMDisable, NULL, &meiDisabledState}
//	,{ CCNET_RETURNED, NULL, sendAckNotificationCcnet, &ccnetInitializingState }
	//,{ CCNET_STACKED, NULL, sendVendValidNotificationCcnet, &ccnetReceivingBillState }
//	,{ CCNET_DISABLED, NULL, NULL, &ccnetDisabledState }
//	,{ CCNET_IDLING, NULL, NULL, &ccnetEnabledState }
	,{ SM_ANY, NULL, NULL, &meiInitializingState }
};

State meiInitializingState = 
{
  	loadInitializingMei,  // entry
  	NULL,                // exit
	meiInitStateTransitions
};

/**
 *  Estado Disabled
 */
 
static Transition meiDisabledStateTransitions[] =
{
	 { ID003_UPDATE_FIRM, NULL, NULL, &meiStartFirmwareUpd }
	,{ ID003_STACKED, NULL, notifyBillAcceptedMei, &meiDisabledState }
	,{ ID003_RETURNED, NULL, cleanLastBillFileStatus, &meiDisabledState }
	,{ SM_ANY, shouldResetStatusFile, resetFileStatusMei, &meiDisabledState }
	,{ SM_ANY, errorDetectedMei, NULL, &meiErrorState }
	,{ SM_ANY, isNotJCMDisable, NULL, &meiEnabledState }
	,{ ID003_ESCROW, NULL, returnBillMei, &meiDisabledState }
//	,{ CCNET_RETURNED, NULL, sendAckNotificationCcnet, &ccnetDisabledState }
//	,{ CCNET_POWER_UP, NULL, NULL, &ccnetInitializingState}
	,{ SM_ANY, NULL, NULL, &meiDisabledState }
};

State meiDisabledState = 
{
  	loadDisableMei,  // entry
  	NULL,                // exit
	meiDisabledStateTransitions
};


/**
 *  Estado Enabled
 */
 
static Transition meiEnabledStateTransitions[] =
{
	 { ID003_UPDATE_FIRM, NULL, NULL, &meiStartFirmwareUpd }
	,{ ID003_STACKED, NULL, notifyBillAcceptedMei, &meiEnabledState }
	,{ ID003_RETURNED, NULL, cleanLastBillFileStatus, &meiEnabledState }
	,{ SM_ANY, errorDetectedMei, NULL, &meiErrorState}
	,{ SM_ANY, isJCMDisable, NULL, &meiDisabledState}
	//,{ CCNET_RETURNED, NULL, sendAckNotificationCcnet, &ccnetEnabledState }
	//,{ CCNET_POWER_UP, NULL, NULL, &ccnetInitializingState}
	,{ ID003_ACCEPTING, NULL, NULL, &meiReceivingBillState }
	,{ ID003_ESCROW, NULL, NULL, &meiReceivingBillState }
	,{ SM_ANY, NULL, NULL, &meiEnabledState }
};

State meiEnabledState = 
{
  	loadEnableMei,  // entry
  	NULL,                // exit
	meiEnabledStateTransitions
};

/**
 *  Estado ReceivingBillState
 */

static Transition meiReceivingBillStateTransitions[] =
{
	 {ID003_STACKED, NULL, notifyBillAcceptedMei, &meiReceivingBillState }
	,{ ID003_RETURNED, NULL, cleanLastBillFileStatus, &meiReceivingBillState }
	,{ SM_ANY, errorDetectedMei, NULL, &meiErrorState}
	,{ SM_ANY, isJCMDisable, NULL, &meiDisabledState}
	,{ ID003_ESCROW, NULL, requestStackMei, &meiReceivingBillState }
//	,{CCNET_RETURNED, NULL, sendAckNotificationCcnet, &ccnetReceivingBillState }
	,{ ID003_IDLING, NULL, NULL, &meiEnabledState }
	,{ SM_ANY, NULL, NULL, &meiReceivingBillState }
};

State meiReceivingBillState = 
{
  	loadReceivingBillMei,  // entry
  	NULL,                // exit
	meiReceivingBillStateTransitions
};

/**
 *  Estado ErrorState
 */

static Transition meiErrorStateTransitions[] =
{
	  { ID003_STACKED, NULL, notifyBillAcceptedMei, &meiErrorState }
  	 ,{ ID003_RETURNED, NULL, cleanLastBillFileStatus, &meiErrorState }
	 ,{ SM_ANY, endErrorDetectedMei, NULL, &meiInitializingState }
	 ,{ ID003_UPDATE_FIRM, NULL, NULL, &meiStartFirmwareUpd }
	//Hice unas pruebas, porque cuando queda jammed no sale solo,
	//luego del reset el validador aparentemente no contesta mas, seguir investigando:
	// ,{ SM_ANY, shouldResetMei, sendResetMei, &meiErrorState } comento ahora pruebas con Anibal de Mei
	 ,{ SM_ANY, NULL, NULL, &meiErrorState }
};

State meiErrorState = 
{      
  	loadErrorStateMei,  // entry
  	NULL,                // exit
	meiErrorStateTransitions
};

static Transition meiStartFirmUpdateTransitions[] =
{
	 {SM_ANY, notInDownloadModeMei, sendDownloadStartMei, &meiStartFirmwareUpd }
	,{SM_ANY, NULL, NULL, &meiUpdateFirmware }
	 
};

State meiStartFirmwareUpd = 
{
  	loadStartFirmUpdateMei,  // entry
  	NULL,                // exit
	meiStartFirmUpdateTransitions
};


static Transition meiUpdateFirmwareTransitions[] =
{
	  { 0x00, NULL, NULL, &meiInitializingState} //fallo la actualizacion, me voy
	 ,{ SM_ANY, transferFailed, doTransferSameFrameMei, &meiUpdateFirmware }
	 ,{ 0x50, NULL, doTransferNextFrameMei, &meiUpdateFirmware }
	 ,{ SM_ANY, NULL, NULL, &meiInitializingState}
};

State meiUpdateFirmware = 
{
  	loadFirmUpdateMei,  // entry
  	NULL,                // exit
	meiUpdateFirmwareTransitions
};

void pollMei( JcmBillAcceptData *jcmBillAcceptor )
{
//	static long count=0;
	if (  jcmBillAcceptor->billValidStateMachine->currentState == &meiStartFirmwareUpd ){
		memset( jcmBillAcceptor->bufAux, 0, 3);
		meiAcceptWriteRead( jcmBillAcceptor, EVT_POLLSTATUS, 0x10, jcmBillAcceptor->bufAux, 3);
		msleep(200);
	} else {
		if (  jcmBillAcceptor->billValidStateMachine->currentState == &meiUpdateFirmware ){
			executeStateMachine(jcmBillAcceptor->billValidStateMachine, 0x50);
		} else {
		//	if ((jcmBillAcceptor->billValidStateMachine->currentState != &meiErrorState )){	
				meiAcceptWriteRead( jcmBillAcceptor, EVT_POLLSTATUS, 0x10, jcmBillAcceptor->pollCmd, 3);
			//} else {
			//	count++;
				//if ((count % 10)==0)
				//	meiAcceptWriteRead( jcmBillAcceptor, EVT_POLLSTATUS, 0x10, jcmBillAcceptor->pollCmd, 3);
		//	}
			//msleep(15);
		}
	}
}
