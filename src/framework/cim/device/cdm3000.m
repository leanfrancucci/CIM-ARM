/* ========================================================================== */
/*                                                                            */
/*   Filename.c                                                               */
/*   (c) 2001 Author                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */


#include "logComm.h"
#include "cdm3000.h"
#include "log.h"
#include "system/dev/all.h"

#define MultipEntero  10000000L 
#define MultipDecimal  100000L 

/*
	Calcula la suma de los campos [1] a n y le setea el bit 7 en cero
*/
unsigned char calcBCC( unsigned char *data, int n )
{
  int i;
  unsigned char sum;
  
  sum = 0;
  // no sumo el inicio de trama:
  for  ( i = 1; i < n; ++ i){
    sum += data[i];
  }
  sum = (sum & 0x7F);	 
  return sum;
}

/*
	Abre el puerto pasado por parametro, inicializando la comunicacion con la placa.
	Retorna 1 si la apertura de puerto fue exitosa y 0 en caso contrario
*/
OS_HANDLE cdmCommOpen( char portNumber )
{
    ComPortConfig config;
    
 	config.baudRate = BR_9600;
  	config.readTimeout = 1000;
  	config.writeTimeout = 1000;
  	config.parity = CT_PARITY_NONE;
  	config.dataBits = 8;
  	config.stopBits = 1;
	openConfigFile();
    
    return com_open(portNumber, &config);
}

/*
	Cierre del puerto
*/
void cdmCommClose( Cdm3000Data *cdm )
{
    com_close( cdm->osHandle );
}

int lastlenCMD;
/*
	Realiza el entramado de los datos pasados por parametro y envia los datos por el puerto
	que se haya inicializado..
*/
void cdmCommWrite( Cdm3000Data *cdm, unsigned char cmd, unsigned char * data, unsigned char datalen )
{
	int idx;
	unsigned char len;

    cdm->writeBuf[0] = 0x02;
    cdm->writeBuf[1] = cdm->devId;
    cdm->writeBuf[2] = cmd;
	//el datalen lo convierto a ascii, de 3 char.. rarito
	memset(&cdm->writeBuf[3], 0x30, 3);
	idx = 5;
	len = datalen;
	while ( len != 0 )	{
		cdm->writeBuf[idx] = ( len % 10 ) + '0';
		len = len / 10;
		idx--;
	}
	memcpy(&cdm->writeBuf[6], data, datalen);
	cdm->writeBuf[6 + datalen] = 0x03;
	cdm->writeBuf[7 + datalen] = calcBCC( cdm->writeBuf, 7 + datalen );

    com_write( cdm->osHandle, cdm->writeBuf, datalen + 8 );

	//para loguear lo agrego:
	lastlenCMD = datalen + 8;
}

/*
	Intenta leer una trama valida, verificando su checksum.
	En caso de encontrarla retorna un puntero a los datos leidos a partir de la posicion
	[1], descarta la marca de inicio de trama.
	En caso contrario ( datos leidos == 0, inicio de trama no encontrado, checksum invalido )retorna NULL. 
*/

unsigned char * cdmCommRead( Cdm3000Data *cdm, int timeout )
{
    int qty;
    unsigned char len, bcc;

   	qty = com_read( cdm->osHandle, cdm->readBuf, 8,  timeout );
    if (( qty == 8 ) && ( cdm->readBuf[0] == 0x02 )){
		//la rta tiene que ser distinta a invalid Command
		len = ((cdm->readBuf[3] - '0')*100 )+ ((cdm->readBuf[4] - '0')*10 ) + (cdm->readBuf[5] - '0' );
		qty += com_read( cdm->osHandle, &cdm->readBuf[8], len,  5000 );
    //************************* logcoment
/*		if ( qty < len ){
			doLog(0,"qty < len %d %d \n", qty, len);fflush(stdout);
		}
*/
		//logFrame( cdm->devId, cdm->writeBuf, lastlenCMD, 1 );
		//logFrame( cdm->readBuf[1], cdm->readBuf, qty, 0 );

		bcc = calcBCC( cdm->readBuf, len + 7 );
		if ( bcc == cdm->readBuf[len + 7 ]){
			//doLog(0,"Frame Ok!!\n");fflush(stdout);
			return &cdm->readBuf[1];                        
		} else {
    //************************* logcoment
//			doLog(0,"Error checksum %d %d!!\n", bcc, cdm->readBuf[len + 7 ]);fflush(stdout);
			logFrame( cdm->devId, cdm->writeBuf, lastlenCMD, 1 );
			logFrame( 253, cdm->readBuf, qty, 0 );
			//doLog(0,"checksum wrong %d %d \n", chkVal, bufPtr[len + 5 ]);fflush(stdout);
		}
    } else {
		logFrame( cdm->devId, cdm->writeBuf, lastlenCMD, 1 );
        logFrame( 255, cdm->readBuf, qty, 0 );
    //************************* logcoment
//		doLog(0,"qty es CERO %d \n", qty);fflush(stdout);
	}

	msleep(10);
	com_flush( cdm->osHandle );
    return NULL;
}

	
Cdm3000Data *cdmNew( int portNumber, int devId, cdmComunicationErrorNotif commErrorNotifFcn, changeCdmStatusNotif changeCdmStatus, coinsAcceptedNotif coinsAccepted )
{
    Cdm3000Data *cdm;
    
    cdm = (Cdm3000Data*) malloc( sizeof( Cdm3000Data ));
    cdm->devId = devId;
	cdm->commErrorNotificationFcn = commErrorNotifFcn;
	cdm->changeCdmStatusFcn = changeCdmStatus;
	cdm->coinsAcceptedFcn = coinsAccepted;
	cdm->errorQty = cdm->resetQty = 0;
    
	cdm->osHandle = cdmCommOpen( portNumber );
	if ( cdm->osHandle == -1){
		free(cdm);
		return NULL;
	}
    //************************* logcoment
//	doLog(0,"COMM OPENED OKKK!\n"); fflush(stdout);
	cdm->pendingStatus = NO_ACTION;
	cdm->clearPending = 1;
	cdm->coinsAcceptedNotifMissing = 0;
	cdm->cdmThread = [JcmThread new];
    //************************* logcoment
//	doLog(0,"CDMthread created!\n"); fflush(stdout);	
	[cdm->cdmThread setExecFun: cdmRun];
	[cdm->cdmThread setObjectPtr: cdm];
    //************************* logcoment
//	doLog(0,"cmd setted\n!"); fflush(stdout);

   	[cdm->cdmThread start];

	return ( cdm );
}


void cdmStartCounting( Cdm3000Data *cdmCounter )
{
	cdmCounter->clearPending = 1;
	cdmCounter->pendingStatus = START_PENDING;
}

void cdmStopCounting( Cdm3000Data *cdmCounter )
{	
	cdmCounter->pendingStatus = STOP_PENDING;
}

int asciitoint(unsigned char * dataP, int qty)
{
	int i, sum=0;
	
	for (i =0; i < qty; ++i ){
		sum = (sum *10) + (dataP[i] - 0x30);
	}
	return sum;

}

void cmdProcessQty( Cdm3000Data *cdmCounter, unsigned char * dataPtr )
{
	int i, index, len, amount;

    //************************* logcoment
//	doLog(0,"procesar cantidades!!!!!!!!\n");
	fflush(stdout);


	len = asciitoint(&dataPtr[2], 3);
	//en dataPtr[6] esta la primera denominacion. cada registro ocupa 11 bytes
	index = 6;
	for ( i = 0; i < 9; ++i, index += 11 ) {	
		cdmCounter->countingResult[i].qty = asciitoint(&dataPtr[index+5], 6);
		amount = (asciitoint(&dataPtr[index], 2) * 100 ) + asciitoint(&dataPtr[index+3], 2);
		cdmCounter->countingResult[i].amount = amount * MultipDecimal;
	}
	cdmCounter->failureCount = asciitoint(&dataPtr[index], 4);
	(*cdmCounter->coinsAcceptedFcn)(cdmCounter->devId, cdmCounter->countingResult, cdmCounter->failureCount );
	cdmCounter->coinsAcceptedNotifMissing = 0;
}

void cdmRun( Cdm3000Data *cdmCounter )
{
	unsigned char mydata[2];
	unsigned char *dataPtr;
	unsigned char cmd;
	
	while (1) {
		if ( cdmCounter->coinsAcceptedNotifMissing  && !cdmCounter->motorRunning ){
			cmd = 0x08;
			mydata[0] = 0x30;
    //************************* logcoment
//			doLog(0,"motor stopped! qty not informed!\n");
			cdmCommWrite( cdmCounter, cmd, mydata, 1 );
		} else {
			if (cdmCounter->clearPending && !cdmCounter->motorRunning) {
				mydata[0] = 0x30;
				//aca hago un clear!
				cdmCommWrite( cdmCounter, 0x01, mydata, 1 );
			} else {
				if ( cdmCounter->resetQty >= 10 ){
					//send reset
					cmd = 0x07;
					cdmCounter->resetQty = 0;
    //************************* logcoment
//					doLog(0,"SEND RESET!"); fflush(stdout);
				} else {
					switch ( cdmCounter->pendingStatus ) {
						case START_PENDING: cmd = 0x04;
											break;
						case STOP_PENDING: cmd = 0x05;
											break;
						default: 	cmd = 0x06;
											break;
					}
				}			
				cdmCommWrite( cdmCounter, cmd, mydata, 0 );
			}
		}

		dataPtr = cdmCommRead( cdmCounter, 2000 );
		if ( dataPtr != NULL ){
			cdmCounter->errorQty = 0;
			switch ( dataPtr[1] ){
				case 0x11:
					cdmCounter->clearPending = 0;
					break;
				case 0x16:
					//aca notificar los cambios de estado y errores:
					if ( cdmCounter->motorRunning != (dataPtr[5] - 0x30) ){
						cdmCounter->motorRunning = dataPtr[5] - 0x30;
						(*cdmCounter->changeCdmStatusFcn)(cdmCounter->devId, cdmCounter->motorRunning);
						//doLog(0,"notificar cambio de estado de motor running"); fflush(stdout);
						if ( cdmCounter->motorRunning )
							cdmCounter->coinsAcceptedNotifMissing = 1;
					}
					if ( cdmCounter->errorStatus != (dataPtr[6] - 0x30)){
						cdmCounter->errorStatus = dataPtr[6] - 0x30;
						(*cdmCounter->commErrorNotificationFcn)(cdmCounter->devId, cdmCounter->errorStatus);
						//doLog(0,"notificar cambio de estado de error status"); fflush(stdout);
					}
					if ( cdmCounter->errorStatus >= CDM_COINJAM && cdmCounter->errorStatus <= CDM_CASEFULL )
						cdmCounter->resetQty++;
					break;
				case 0x14:
				case 0x15:
					cdmCounter->pendingStatus = NO_ACTION;
					break;
				case 0x18:
					//tengo que procesar las cantidades!
					cmdProcessQty( cdmCounter, dataPtr );
					break;
				case 0x1E:
					//tengo que procesar las cantidades!
    //************************* logcoment
//					doLog(0,"invalid Command %d\n", dataPtr[5]);
					fflush(stdout);
					break;
				default:
    //************************* logcoment
//					doLog(0,"CMD unknownnnnnn %d\n", dataPtr[1]);
					fflush(stdout);
				
			}	
		} else {
			cdmCounter->errorQty++;
			if ( cdmCounter->errorQty == 6 ){
				cdmCounter->errorStatus = 0x08;
				(*cdmCounter->commErrorNotificationFcn)(cdmCounter->devId, cdmCounter->errorStatus);
			}
		}
		msleep(1000);
	}
}

void cdmClearCounter( Cdm3000Data *cdmCounter )
{
	cdmCounter->clearPending = 1;
}

int cdmGetCountingStatus( Cdm3000Data *cdmCounter )
{
	return cdmCounter->motorRunning;
}


#if 0
int TEST_CDM_COM( char portNumber )
{
	Cdm3000Data *cdmtemp;

	cdmtemp = cdmNew( 2, 0x31 );
	if ( cdmtemp != NULL ) {
		doLog(0,"test ok\n");fflush(stdout);
		cdmRun( cdmtemp );
		msleep(1000);
		cdmRun( cdmtemp );
		msleep(1000);
		cdmRun( cdmtemp );
		msleep(1000);
		cdmClearCounter( cdmtemp );
		msleep(1000);
		cdmStartCounting( cdmtemp );
		msleep(5000);
		cdmStopCounting( cdmtemp );

		doLog(0,"leaving app!\n");fflush(stdout);
	} else {
		doLog(0,"Could not openned comm \n");fflush(stdout);
	}


	return 1;
}
#else

int TEST_CDM_COM( char portNumber )
{
	return 1;
}
#endif

