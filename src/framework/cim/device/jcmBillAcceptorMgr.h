#ifndef JCM_BILL_ACPT_H
#define JCM_BILL_ACPT_H

#include <stdio.h>
#include "system/util/state_machine.h"
#include "Audit.h"
#include "CurrencyManager.h"

#define MultipApp  10000000L 

/*
*/
typedef struct {
    long amount;
    int disabled;
    unsigned char countryCode;
    char countryStr[4];
	int currencyId;
    unsigned short noteId;
} JCMDenomination;

/*
	Mapear los cambios de estado
	to do:
	podria armar una unit aparte que me mapee todo no?     
*/
typedef void( *changeAcceptorStatusNotif )( unsigned char devId, unsigned char newStatus );

/*
	Causas de rechazo:
	0x71 : insertion error (crooked insertion)
	0x72 : magnetic pattern error
	0x73 : while idle, a sensor other than then entrance sensors detected something
	0x74: data amplitude error
	0x75 : feed error
	0x76 : denomination assesing error
	0x77 : photo pattern error
	0x78 : photo level error
	0x79 : bill disabled by dip swith or command
	0x7A : reserved
	0x7B : operation error
	0x7C : bill detected in transport assembly at wrong time
	0x7D : length error
	0x7E : color pattern error
*/
typedef void( *billRejectedNotif )( unsigned char devId, int cause, int qty );

/*
	Notificacion de error detectado en el validador. El parametro cause entrega
	el codigo del error, a saber:

	0x43: Stacker Full 
	0x44: Stacker Open
	0x45: JAM_IN_ACCEPTOR
	0x46: JAM_IN_STACKER
	0x47: PAUSE
	0x48: CHEATED
    0X4a: COMM_ERROR

  	0xA2: STACK_MOTOR_FAILURE 		
	0xA5: MOTOR_SPEED_FAILURE 		
	0xA6: MOTOR_FEED_FAILURE 			

	0xAB: CASHBOX_NOT_READY_FAILURE 	
	0xAF: HEAD_REMOVED_FAILURE 		
	0xB0: BOOT_ROM_FAILURE 			
	0xB1: EXTERNAL_ROM_FAILURE		
	0xB2: ROM_FAILURE			 		
	0xB3: EXT_ROM_WRITING_FAILURE 	
	0xB4: ALIGN_MOTOR_FAILURE 		
	0xB5: CASSETTE_STATUS_FAILURE		
	0xB6: OPTIC_CANAL_FAILURE			
	0xB7: MAGNETIC_CANAL_FAILURE 		
	0xB8: CAPACITANCE_CANAL_FAILURE 	 
	
*/
typedef void( *comunicationErrorNotif )( unsigned char devId, int cause );

/*
	Como se codificaba esto?
*/
typedef void( *billAcceptedNotif )( unsigned char devId, long long billAmount, int currencyId, int qty );

typedef struct {
  StateMachine *billValidStateMachine;
  changeAcceptorStatusNotif statusNotificationFcn; //cambio de estado definido een JcmStatus
  changeAcceptorStatusNotif acceptingNotificationFcn; //cambio de estados del validador. Se refiere a los estados definidos en el enum StatusResponse
  billRejectedNotif billRejectNotificationFcn;		
  billAcceptedNotif billAcceptNotificationFcn;
  comunicationErrorNotif commErrorNotificationFcn;
  changeAcceptorStatusNotif firmwareUpdateProgress;
  char status; // enabled, disabled, UPDATING FIRMWARE ?
  char pendingStatus;
  char canChangeStatus;
  char rejecting;
  char sst[7];
  unsigned char onPowerUp;
 // unsigned char hasBankNotesWaiting;
  unsigned char denominationQty;
  unsigned char actualState;
  unsigned char ackVal;
  unsigned char bufAux[10];
  unsigned char pollCmd[3];

  unsigned char event;
  unsigned int dataLenEvt;
  unsigned char *dataEvPtr;
  long long amountChar;
  int currencyId;	
  unsigned char lastRejectCause;
  unsigned int errorCause;
  int errorAditInfo;	
  JCMDenomination convertionTable[26]; 
  int denominationsQty;
  unsigned char billTableLoaded;
  int countryCode;
  char jcmVersion[50];
  char devId; 
  char errorResetQty;	// cantidad de polling de status que se realizan entre reset y reset ( para darle tiempo al reset y 
						//a q una vez inicilizado el validador se solucione el problema
  char resetSentQty; // cantidad de reset que se enviaron al validador, se limita para q no se queme
  char commErrQty;
  char canResetVal; //cuando arranco la maquina de estados, esta deshabilitado hasta q se indiq lo contrario	  
  char appNotifPowerUpBill;
  char protocol;
// variables para la actualizaacion de firmware
  FILE *firmImage;
  long offsetTransfer;
  int blockSize;
  int fileOffset;
  int qtyInvalidCmd;
  int frameSize;
  unsigned int framesQty;
  unsigned int framesQtyRefreshProgress;
  long fileSize;	
  unsigned char downloadMode;
  unsigned short blockNo;
  unsigned short imageCrc;
  unsigned char qtySentWithAck;
  unsigned char firmwFrame[600];
	//utilizado en mei como buffer lectura actual de firmware:
  unsigned char tempData[32];
  unsigned char cheatedLeaveApp;
	//para mei>
  FILE * fpValStat;
  int billDepositQty;	
  unsigned char notifyInitApp;	
  unsigned char fileInfoRequested;	
  unsigned char statusFiledReseted;
  unsigned char recBlockNo;
  unsigned char sndBlockNo;
  unsigned char resetSent;
  unsigned char initalizationAlarmSent;
} JcmBillAcceptData;

/*
  Inicializacion de la comunicacion con el validador y de la maquina de estados.          Es necesario pasar por parametro los punteros a las funciones de callback, las cuales:
  
  changeAcceptorStatusNotif: notifica cuando hay un cambio en el estado del validador de dinero
  billRejectedNotif: notifica cuando el validador rechaza un billete informando la causa de rechazo de acuerdo a lo codificado en la especificacion
  billAcceptedNotif: notifica cuando el validador identifica y almacena un billete, informando el importe de dicho billete. 
  
  Retorna 1 si el puerto se abre exitosamente y 0 en caso de error
  
*/
JcmBillAcceptData *billAcceptorNew( char devId, changeAcceptorStatusNotif statusNotifFcn, billRejectedNotif billRejectNotifFcn, billAcceptedNotif billAcceptNotifFcn, comunicationErrorNotif comunicationErrorNotifFcn, changeAcceptorStatusNotif acceptingNotifFcn );
void billAcceptorStart( JcmBillAcceptData *jcmBillAcceptor );
void billAcceptorStop( JcmBillAcceptData *jcmBillAcceptor );
void billAcceptorRun( JcmBillAcceptData *jcmBillAcceptor );
void billAcceptorSetStatus( JcmBillAcceptData *jcmBillAcceptor, char newStatus );
char billAcceptorUpdate( JcmBillAcceptData *jcmBillAcceptor, char *firmware, changeAcceptorStatusNotif firmUpdProgress );

//retorna la cantidad de billetes stackeados en el ultimo deposito (si habia uno en curso..), y el importe y currencyId del ultomo billete stackeado:
unsigned short getLastStackedQty( JcmBillAcceptData *jcmBillAcceptor, long long *billAmount, int *currencyId );

#endif
