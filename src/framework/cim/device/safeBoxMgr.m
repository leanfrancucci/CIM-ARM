/* ========================================================================== */
/*                                                                            */
/*   safeBoxMgr.c                                                               */
/*   (c) 2007 Soledad Oliva                                                   */
/*                                                                            */
/*                                                                            */
/* ========================================================================== */

#include "safeBoxMgr.h"
#include "safeBoxComm.h"
#include "system/util/endian.h"
#include "JcmThread.h"
#include "log.h"

typedef void( *processCmdRta )( unsigned char cmd, unsigned char * rta );


/*
  Aca deberia abrir el puerto, inicializar los dispositivos que correspondan en base al modelo de hardware, etc
*/

#define UPD_FRAME_SIZE 248

// timeouts por comandos:

int timeoutsCmd[]= {  //este tiempo esta expresado en segundos!
	0, 		//	NO_CMD 
	10, 	//	UNLOCK_CMD
	10,    	// 	LOCK_CMD
	10,     //	ACTRL_CMD
	10,		//	ADDUSR_CMD
	10,     //	DELUSR_CMD
	20,  	//	EDITUSRPASS_CMD
	20,		//	GETUSRDEV_CMD
	20,		// 	SETUSRDEV_CMD
	10,  	// 	VALUSR_CMD
	10, 	//	GETUSRINFO_CMD
	25, 	//	USRFMT_CMD  
	10,     // 	VERSION_CMD
	10,		// 	MODEL_CMD
	10,		//	SHUTDOWN_CMD
	10,		//  GR1_CMD
	480,	//	BLANKFS_CMD  8 minutos
	70,	//	CREATEFILE_CMD	3  minutos y pico
	10,		// 	STATUSFILE_CMD
	10,		// 	READFILE_CMD
	10,		//	WRITEFILE_CMD 
	10,		//	SEEKFILE_CMD  
	2,		//	REOPENFILE_CMD
	2,		//	CLOSEFILE_CMD
	70,	//	REINITFILE_CMD 3 minutos y pico
	10,	//	GETFSINFO_CMD inst		
	10,		//  TLOCK_CMD
	10,		//  TUNLOCKENABLE_CMD
	10,		//  failure
	10,		//  success
	10,		//  nack
	10,		//  valconfig
	10, 	//  forceuserpass
	10,		//  syncframes
	10,		//hostpower
	10,		//resetmcu
	10,		//TUNLOCKENABLELOCKS_CMD
	10		//VAL_PWR_CMD
};

/*
typedef struct {
	unsigned char baudRate; //B300 = 0, B600, B1200..
	unsigned char wordBits; //bit8 = 0, BIT9
	unsigned char parity; //NO_PAR = 0, EVEN_PAR, ODD_PAR
	unsigned char stopBits; //one_bit = 0, two_bit
	unsigned char dataLenPos; //1..255
	unsigned char sync;	//0xFC, 0x02
} ValProtocolConfig;

ValProtocolConfig supportedProtocols[ PROTQTY ]={
	 { 5, 0, 1, 0, 1, 0xFC }  	//ID003
	,{ 5, 0, 0, 0, 2, 0x02 }	//ccnet
};
*/

enum {
	NOT_INITIALIZED = 0, INITIALIZED, COMM_ERROR
};

typedef struct {
	unsigned char dev;
	unsigned char cmd;
	unsigned char nData;
	unsigned char *data;
} QueueElement;


SafeBox mySafeBox;
static int delayRequired;

void safeBoxUnLockRta( unsigned char cmd, unsigned char *rta )
{
	unsigned char rtacmd, devId;
	
//	doLog(0,"unlock!!\n"); fflush(stdout);
	if ( rta != NULL ){
		devId = (unsigned char)* rta;
		//dev id es != a safebox.. pero podria adapatarla  
		rtacmd = (unsigned char)*( rta + 1 ); 
		if ( rtacmd == SBOX_NACK_CMD ){
			rtacmd = SBOX_FAILURE_CMD;
			//(unsigned char)*( rta + 4 ) = ERR_COMMUNICATION_ERROR; 
			*( rta + 4 ) = ERR_COMMUNICATION_ERROR; 
		}
		(*mySafeBox.actionResultFcn)( devId, cmd, rtacmd, (unsigned char*)( rta + 4 ) );
	}
}

void safeBoxSyncFramesRta( unsigned char cmd, unsigned char *rta )
{
	if ( rta != NULL && (unsigned char)*( rta + 1 ) == SBOX_SUCCESS_CMD )
		framesQty = 0;
}

static char resetMcuCmdRta;
void resetMcuRta( unsigned char cmd, unsigned char *rta )
{
	if ( rta != NULL && (unsigned char)*( rta + 1 ) == SBOX_SUCCESS_CMD )
		resetMcuCmdRta = 1;
	else
		resetMcuCmdRta = 0;
}

void safeBoxCommonRta( unsigned char cmd, unsigned char *rta )
{
	unsigned char rtaNull = ERR_COMMUNICATION_ERROR;
	
	if ( rta != NULL ){
		if ( (unsigned char)*( rta + 1 ) == SBOX_NACK_CMD ){
			//(unsigned char)*( rta + 1 ) = SBOX_FAILURE_CMD;
			*( rta + 1 ) = SBOX_FAILURE_CMD;
			//(unsigned char)*( rta + 4 ) = ERR_COMMUNICATION_ERROR; 
			*( rta + 4 ) = ERR_COMMUNICATION_ERROR; 
		}
		(*mySafeBox.actionResultFcn)( SAFEBOX, cmd, (unsigned char)*( rta + 1 ), (unsigned char*)( rta + 4 ) );
	} else 
		(*mySafeBox.actionResultFcn)( SAFEBOX, cmd, SBOX_FAILURE_CMD, &rtaNull );
}

char isReady = 0;

void safeBoxReady( unsigned char cmd, unsigned char *rta )
{
	isReady = 1;
}

void valConfigApplied( unsigned char cmd, unsigned char *rta )
{
	doLog(0,"valConfig " );

	if ( rta != NULL && (unsigned char)*( rta + 1 ) == SBOX_SUCCESS_CMD ){
		mySafeBox.valConfigPending = 0;
		doLog(0,"Applied\n" );fflush(stdout);
	} else {
		doLog(0,"Not Applied\n" );fflush(stdout);
	}	 
}

void safeBoxDoGetVersion( unsigned char cmd, unsigned char *versionRta )
{
	if ( versionRta != NULL ) 
		if ( *( versionRta + 1 ) == SBOX_SUCCESS_CMD )
			strcpy(mySafeBox.version, &versionRta[4]);
		
}

void generateResetDelay( unsigned char cmd, unsigned char *versionRta )
{
	if ( delayRequired ) {
		msleep(1500);
		delayRequired = 0;
	}
}

void safeBoxGr1GetStatus( unsigned char cmd, unsigned char *newStatus )
{
	char aux;
	Gr1Status *grStat;
	
	if (( newStatus != NULL ) && ( *( newStatus + 1 ) == SBOX_SUCCESS_CMD ) &&
		 ((SHORT_TO_B_ENDIAN(*((unsigned short*)( newStatus + 2 ))) == 16 ) || 
		  (SHORT_TO_B_ENDIAN(*((unsigned short*)( newStatus + 2 ))) == 9 ))){

		if ( mySafeBox.safeBoxCommErrorStatus ) {
			mySafeBox.safeBoxCommErrorStatus = 0;
			//notif app FIN ERROR
			if ( mySafeBox.commErrorNotificationFcn != NULL )
				( mySafeBox.commErrorNotificationFcn )( SAFEBOX, 0 );
		}
		
		grStat = (Gr1Status *) (newStatus + 4);
		if (( aux = ( grStat->safeBox >> 3 & 0x03 )) != mySafeBox.gr1Status.memory  ){
			mySafeBox.gr1Status.memory = aux;
			//mySafeBox.statusNotificationFcn( SYSTEM_ST, mySafeBox.gr1Status.system );
		}

		if (( aux = ( grStat->safeBox >> 2 & 0x01 )) != mySafeBox.gr1Status.system  ){
			mySafeBox.gr1Status.system = aux;
			mySafeBox.statusNotificationFcn( SYSTEM_ST, mySafeBox.gr1Status.system );
		}

		if ( mySafeBox.gr1Status.system == 0 ){

			if ( grStat->locker0 != mySafeBox.gr1Status.locker0 ){
				if (( grStat->locker0 == 0 ) && ( grStat->plunger0 != mySafeBox.gr1Status.plunger0 )){
						mySafeBox.gr1Status.plunger0 = grStat->plunger0;
						mySafeBox.statusNotificationFcn( PLUNGER0, grStat->plunger0);
				}
				mySafeBox.gr1Status.locker0 = grStat->locker0;
				mySafeBox.statusNotificationFcn( LOCKER0, grStat->locker0 );
			} 
			if ( grStat->plunger0 != mySafeBox.gr1Status.plunger0 ){
				mySafeBox.gr1Status.plunger0 = grStat->plunger0;
				mySafeBox.statusNotificationFcn( PLUNGER0, grStat->plunger0 );
			}
						
			if ( grStat->locker1 != mySafeBox.gr1Status.locker1 ){
				if (( grStat->locker1 == 0 ) && ( grStat->plunger1 != mySafeBox.gr1Status.plunger1 )){
						mySafeBox.gr1Status.plunger1 = grStat->plunger1;
						mySafeBox.statusNotificationFcn( PLUNGER1, grStat->plunger1);
				}
				mySafeBox.gr1Status.locker1 = grStat->locker1;
				mySafeBox.statusNotificationFcn( LOCKER1, grStat->locker1);
			}
			
			if ( grStat->plunger1 != mySafeBox.gr1Status.plunger1 ){
				mySafeBox.gr1Status.plunger1 = grStat->plunger1;
				mySafeBox.statusNotificationFcn( PLUNGER1, grStat->plunger1);
			}

			if ( (aux = ( grStat->safeBox >> 7 & 0x01 )) != mySafeBox.gr1Status.powerSupply ){
				mySafeBox.gr1Status.powerSupply = aux;
				mySafeBox.statusNotificationFcn( POWER_ST, mySafeBox.gr1Status.powerSupply );
			}
			if ( ( aux = ( grStat->safeBox & 0x03 )) != mySafeBox.gr1Status.battery  ){
				mySafeBox.gr1Status.battery = aux;
				mySafeBox.statusNotificationFcn( BATT_ST, mySafeBox.gr1Status.battery );
			}

			if ( grStat->stacker0 != mySafeBox.gr1Status.stacker0 ){
				mySafeBox.gr1Status.stacker0 = grStat->stacker0;
				mySafeBox.statusNotificationFcn( STACKER0, grStat->stacker0 );
			}

			if ( grStat->stacker1 != mySafeBox.gr1Status.stacker1 ){
				mySafeBox.gr1Status.stacker1 = grStat->stacker1;
				mySafeBox.statusNotificationFcn( STACKER1, grStat->stacker1 );
			}

			if ( grStat->locker0Error != mySafeBox.gr1Status.locker0Error ){
				mySafeBox.gr1Status.locker0Error = grStat->locker0Error;
				mySafeBox.statusNotificationFcn( LOCKER0_ERR, grStat->locker0Error );
			}

			if ( grStat->locker1Error != mySafeBox.gr1Status.locker1Error ){
				mySafeBox.gr1Status.locker1Error = grStat->locker1Error;
				mySafeBox.statusNotificationFcn( LOCKER1_ERR, grStat->locker1Error );
			}
		}
		//verifico data len para asegurarme q la respuesta esperada coincida al comando..
		if ( SHORT_TO_B_ENDIAN(*((unsigned short*)( newStatus + 2 ))) == 16 ){

			mySafeBox.oldFirmProtocol = 0;
	
			if ( grStat->locker2 != mySafeBox.gr1Status.locker2 ){
				if (( grStat->locker2 == 0 ) && ( grStat->plunger2 != mySafeBox.gr1Status.plunger2 )){
						mySafeBox.gr1Status.plunger2 = grStat->plunger2;
						mySafeBox.statusNotificationFcn( PLUNGER2, grStat->plunger2);
				}
				mySafeBox.gr1Status.locker2 = grStat->locker2;
				mySafeBox.statusNotificationFcn( LOCKER2, grStat->locker2 );
			} 
			if ( grStat->plunger2 != mySafeBox.gr1Status.plunger2 ){
				mySafeBox.gr1Status.plunger2 = grStat->plunger2;
				mySafeBox.statusNotificationFcn( PLUNGER2, grStat->plunger2 );
			}


			if ( grStat->locker3 != mySafeBox.gr1Status.locker3 ){
				if (( grStat->locker3 == 0 ) && ( grStat->plunger3 != mySafeBox.gr1Status.plunger3 )){
						mySafeBox.gr1Status.plunger3 = grStat->plunger3;
						mySafeBox.statusNotificationFcn( PLUNGER3, grStat->plunger3);
				}
				mySafeBox.gr1Status.locker3 = grStat->locker3;
				mySafeBox.statusNotificationFcn( LOCKER3, grStat->locker3);
			} 
			if ( grStat->plunger3 != mySafeBox.gr1Status.plunger3 ){
				mySafeBox.gr1Status.plunger3 = grStat->plunger3;
				mySafeBox.statusNotificationFcn( PLUNGER3, grStat->plunger3 );
			}
			

			if ( grStat->locker2Error != mySafeBox.gr1Status.locker2Error ){
				mySafeBox.gr1Status.locker2Error = grStat->locker2Error;
				mySafeBox.statusNotificationFcn( LOCKER2_ERR, grStat->locker2Error );
			}

			if ( grStat->locker3Error != mySafeBox.gr1Status.locker3Error ){
				mySafeBox.gr1Status.locker3Error = grStat->locker3Error;
				mySafeBox.statusNotificationFcn( LOCKER3_ERR, grStat->locker3Error );
			}
				
		}	else {
			mySafeBox.oldFirmProtocol = 1;
			if ( !mySafeBox.oldFirmProtocolNotified ) {
				mySafeBox.oldFirmProtocolNotified = 1;
				if ( mySafeBox.commErrorNotificationFcn != NULL ){
					( mySafeBox.commErrorNotificationFcn )( SAFEBOX, ERR_INCOMPATIBLE_FIRMWARE );
					doLog(0, "Notifique a app ERR_INCOMPATIBLE_FIRMWARE..");		
					( mySafeBox.commErrorNotificationFcn )( SAFEBOX, 0 );
				}
			
			}

		}
	
	} else {
		if ( newStatus != NULL ) 
			doLog(0, "rta GR1_CMD != NULL, rta: %d (29), rtaLen: %d (9)\n",*( newStatus + 1 ),SHORT_TO_B_ENDIAN(*((unsigned short*)( newStatus + 2 ))));
		else
			doLog(0, "rta GR1_CMD = NULL. Comm Err!\n ");

		if ( !mySafeBox.safeBoxCommErrorStatus ) {
			mySafeBox.safeBoxCommErrorStatus = 1;
			// Anoto como pendiente la configuracion de validadores por si se resetea
			// la placa, asi vuelve a configurarlos y no se pierde la comunicacion con 
			// dichos dispositivos
			mySafeBox.valConfigPending = 1;

			//notificar app
			if ( mySafeBox.commErrorNotificationFcn != NULL ){
				( mySafeBox.commErrorNotificationFcn )( SAFEBOX, ERR_COMMUNICATION_ERROR );
				doLog(0, "Notifique a app la perdida de conexion..");		
			}
		
		}
	}
}

processCmdRta commandsRtaFcn[] = {
	 NULL		//NO_CMD
	,safeBoxUnLockRta		//UNLOCK_CMD
	,NULL		//LOCK_CMD
	,NULL		//ACTRL_CMD
	,safeBoxCommonRta		//ADDUSR
	,safeBoxCommonRta		//DELUSR
	,safeBoxCommonRta		//EDITUSRPASS
	,safeBoxCommonRta		//Getuserdev
	,safeBoxCommonRta		//setuserdev
	,safeBoxCommonRta		//VALUSR
	,safeBoxCommonRta		//GETUSERINFO
	,safeBoxCommonRta		//USERFORMAT
	,safeBoxDoGetVersion		//VERSION
	,NULL //safeBoxDoGetModel		//MODEL 
	,NULL		//SHUTDONW
	,safeBoxGr1GetStatus		//GR1
	,safeBoxCommonRta		//BLANK
	,safeBoxCommonRta	//CREATE
	,safeBoxCommonRta		//STATUS
	,safeBoxCommonRta		//READmySafeBox.oldFirmProtocol
	,safeBoxCommonRta		//WRITE
	,safeBoxCommonRta		//SEEK
	,safeBoxCommonRta		//REOPEN
	,safeBoxCommonRta		//CLOSE
	,safeBoxCommonRta		//REINIT
	,safeBoxCommonRta		//GETFSINFO
	,NULL		//TLOCK
	,NULL		//TUNLOCKENABLE
	,NULL		//FAILURE
	,NULL		//SUCCESS
	,NULL		//NACK
	,valConfigApplied		//VALCONFIG
	,safeBoxCommonRta		//FORCEUSER
	,safeBoxSyncFramesRta		//SYNCFRAMES
	,NULL					//	hostpower
	,resetMcuRta			//resetMCU
	,NULL		//TUNLOCKENABLELOCKS
	,generateResetDelay		//VALPWR_CMD
};

/*
  */

void safeBoxWriteRead( unsigned char dev, unsigned char cmd, unsigned char * data, unsigned short dataLen )
{
	char *temp;
	
	if ( dev == SAFEBOX && cmd == FORCEUSER_CMD )
		*((unsigned short *)&data[24]) = SHORT_TO_B_ENDIAN( framesQty );
	
	safeBoxCommWrite( dev, cmd, data, dataLen );
	
//	doLog(0,"dev : %d cmd : %d\n ", dev, cmd); fflush(stdout);
	temp = safeBoxCommRead( timeoutsCmd[cmd] * 1000 );
	if (( temp != NULL ) && (temp[0] != dev ) ) {
		temp = NULL;
	}
	
	if ( commandsRtaFcn[cmd] != NULL ){
		//si temp == null le aviso a la app de la falla en el comando			
		( *commandsRtaFcn[cmd] )( cmd, temp ); 
	}
}

JCM_THREAD jcmThread;


/*
  Retorna la version de firmware o NULL en caso q a�n no lo haya obtenido
*/
char * safeBoxMgrGetVersion( void )
{
	char tries;

	tries = 0;
  	//*mySafeBox.version ='\0';
  	
    while (( mySafeBox.version[0] == '\0') && (tries < 6)) {
		msleep(1000);
		++tries;
	}

  return mySafeBox.version;
}

QueueElement qElem, qGetElem;

unsigned char getCommConfig ( ValConfig *valConfig )
{
	unsigned char aux;
	
	aux = ( valConfig->wordBits << 6 ) & 0xC0;
	aux = aux | (( valConfig->parity << 3 ) & 0x38 );
	aux = aux | (( valConfig->stopBits << 2 ) & 0x04);
	aux = aux | (( valConfig->echoDisable << 1 ) & 0x02);
	doLog(0,"commconfig %d\n", aux ); fflush(stdout);
	return aux;
}

unsigned char data[6];
void safeBoxMgrGr1ReqStatus( void )
{
	
	if (( mySafeBox.status == NOT_INITIALIZED) || (mySafeBox.version[0]  == '\0' )) {
		//safeBoxWriteRead( SAFEBOX, MODEL_CMD, NULL, 0 );
		safeBoxWriteRead( SAFEBOX, VERSION_CMD, NULL, 0 );
		if ( mySafeBox.version[0]  != '\0' ) { 
			mySafeBox.status = INITIALIZED;
			//doLog(0,"safeboxMgr->VERSION %s\n", mySafeBox.version );fflush(stdout);
		}
	} else {
		if 	( mySafeBox.valConfigPending ) { 
			data[0] = getCommConfig( &mySafeBox.valConfig[0] );
			data[1] = mySafeBox.valConfig[0].baudRate;
			data[2] = mySafeBox.valConfig[0].startTimeout;
			data[3] = getCommConfig( &mySafeBox.valConfig[1] );
			data[4] = mySafeBox.valConfig[1].baudRate;
			data[5] = mySafeBox.valConfig[1].startTimeout;
			
			//doLog(0,"VAL CONFIGGG SEND COMMAND \n" );fflush(stdout);
			safeBoxWriteRead( SAFEBOX, VALCONFIG_CMD, data, 6);
		} else {
			if ( mySafeBox.valConfig[0].protocol != -1 && mySafeBox.valConfig[1].protocol != -1 && !mySafeBox.allConfigured ){
				data[0] = getCommConfig( &mySafeBox.valConfig[0] );
				data[1] = mySafeBox.valConfig[0].baudRate;
				data[2] = mySafeBox.valConfig[0].startTimeout;
				data[3] = getCommConfig( &mySafeBox.valConfig[1] );
				data[4] = mySafeBox.valConfig[1].baudRate;
				data[5] = mySafeBox.valConfig[1].startTimeout;
				mySafeBox.allConfigured = 1;	
				//doLog(0,"VAL CONFIGGG SEND COMMAND 2\n" );fflush(stdout);
				safeBoxWriteRead( SAFEBOX, VALCONFIG_CMD, data, 6);
			} else
				safeBoxWriteRead( SAFEBOX, GR1_CMD, NULL, 0 );
		}
	}
	
}

void safeBoxProcessQueuedElem( void )
{
	if (( !qIsEmpty ( mySafeBox.queuedActions ))&& ( qRemove( mySafeBox.queuedActions , &qGetElem ) != NULL )){
		safeBoxWriteRead( qGetElem.dev, qGetElem.cmd, qGetElem.data , qGetElem.nData );
		if ( qGetElem.nData )
			free(qGetElem.data);
	}
}

/*
	Public Functions
*/
void safeBoxMgrUnLock( unsigned char devId, char *usrId1, char *usrId2, char * passUsr1, char * passUsr2 )
{
	qElem.dev = devId;		
	qElem.cmd = UNLOCK_CMD;		
	
	if ( usrId2 == NULL ){
		qElem.nData = 25;		
		qElem.data = malloc(qElem.nData);
		qElem.data[0] = 0;
	} else {
		qElem.nData = 49;		
		qElem.data = malloc(qElem.nData);
		qElem.data[0] = 1; //dual
	}
	memset(&qElem.data[1], 0, qElem.nData - 1);

	strcpy( &qElem.data[1], usrId1 );
	memcpy( &qElem.data[17], passUsr1, 8 );
	if ( qElem.data[0] == 1  ){ //es dual!
		strcpy( &qElem.data[25], usrId2 );
		memcpy( &qElem.data[41], passUsr2, 8 );
	}
	
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrLock( unsigned char devId )
{
	qElem.dev = devId;		
	qElem.cmd = LOCK_CMD;		
	qElem.nData = 0;		
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrSetAlarm( unsigned char devId, unsigned char disable )
{
	qElem.dev = devId;		
	qElem.cmd = ACTRL_CMD;		
	qElem.nData = 1;		
	qElem.data = malloc(1);
	*qElem.data = disable;
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrAddUsr( unsigned short devList, char *usrId, char *passPri, char * passSec, char *usrIdVal, char *passVal )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = ADDUSR_CMD;		
	qElem.nData = 58;		
	qElem.data = (unsigned char *) malloc(qElem.nData);
	memset( qElem.data, 0, qElem.nData );
	strcpy( &qElem.data[0], usrId );
	*((unsigned short *)&qElem.data[16]) = SHORT_TO_B_ENDIAN( devList );
	memcpy( &qElem.data[18], passPri, 8 );
	memcpy( &qElem.data[26], passSec, 8 );
	strcpy( &qElem.data[34], usrIdVal );
	memcpy( &qElem.data[50], passVal, 8 );
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrEditUsrPass( char *usrId, char *newPass, char *oldPass, char passType )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = EDITUSRPASS_CMD;		
	qElem.nData = 33;		
	qElem.data = (unsigned char *) malloc(qElem.nData);
	memset( qElem.data, 0, qElem.nData );
	strcpy( &qElem.data[0], usrId );
	memcpy( &qElem.data[16], oldPass, 8 );
	memcpy( &qElem.data[24], newPass, 8 );
	qElem.data[32] = passType;
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrDelUsr( char *usrId, char *usrIdVal, char *passVal )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = DELUSR_CMD;		
	qElem.nData = 40;		
	qElem.data = (unsigned char *) malloc(qElem.nData);
	memset( qElem.data, 0, qElem.nData );
	strcpy( &qElem.data[0], usrId );
	strcpy( &qElem.data[16], usrIdVal );
	memcpy( &qElem.data[32], passVal, 8 );
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrValUsr( char *usrId, char *pass )
{
	
	qElem.dev = SAFEBOX;		
	qElem.cmd = VALUSR_CMD;		
	qElem.nData = 24;	
	
	qElem.data = (unsigned char *) malloc( qElem.nData );
	memset( qElem.data, 0, qElem.nData );
	strcpy( &qElem.data[0], usrId );
	memcpy( &qElem.data[16], pass, 8 );
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrSetUsrDev( char *usrId, unsigned short devList, char *usrIdVal, char *passVal )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = SETUSRDEV_CMD;		
	qElem.nData = 42;		
	qElem.data = (unsigned char *) malloc( qElem.nData );
	memset( qElem.data, 0, qElem.nData );
	strcpy( &qElem.data[0], usrId );
	*((unsigned short *)&qElem.data[16]) = SHORT_TO_B_ENDIAN( devList );
	strcpy( &qElem.data[18], usrIdVal );
	memcpy( &qElem.data[34], passVal, 8 );
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrGetUsrDev( char *usrId )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = GETUSRDEV_CMD;		
	qElem.nData = 16;		
	qElem.data = (unsigned char *) malloc( qElem.nData );
	memset( qElem.data, 0, qElem.nData );
	strcpy( &qElem.data[0], usrId );
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrFsBlank( void )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = BLANKFS_CMD;		
	qElem.nData = 0;		
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrFSStatusFile( unsigned char filed )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = STATUSFILE_CMD;		
	qElem.nData = 1;		
	qElem.data = (unsigned char *) malloc( qElem.nData );
	qElem.data[0] = filed;
	qAdd( mySafeBox.queuedActions, &qElem );
}


void safeBoxMgrFSCreateFile( unsigned char filed, unsigned char unitSize, unsigned char type, unsigned long numUnits )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = CREATEFILE_CMD;		
	qElem.nData = 7;		
	qElem.data = (unsigned char *) malloc( qElem.nData );
	qElem.data[0] = filed;
	qElem.data[1] = unitSize;
	qElem.data[2] = type;
	*((unsigned long *)&qElem.data[3]) = LONG_TO_B_ENDIAN( numUnits );
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrFSRead( unsigned char filed, unsigned char numUnits )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = READFILE_CMD;		
	qElem.nData = 2;		
	qElem.data = (unsigned char *) malloc( qElem.nData );
	qElem.data[0] = filed;
	qElem.data[1] = numUnits;
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrFSWrite( unsigned char filed, unsigned char numUnits, unsigned char unitSize, unsigned char *buf )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = WRITEFILE_CMD;		
	qElem.nData = 2 + ( numUnits * unitSize );		
	qElem.data = (unsigned char *) malloc( qElem.nData );
	qElem.data[0] = filed;
	qElem.data[1] = numUnits;
	memcpy( &qElem.data[2], buf, numUnits * unitSize );
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrFSSeek( unsigned char filed, long offset, unsigned char whence )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = SEEKFILE_CMD;		
	qElem.nData = 6;		
	qElem.data = (unsigned char *) malloc( qElem.nData );
//	doLog(0,"filed %d offset %d whence %d\n", filed, offset, whence ); fflush(stdout);
	qElem.data[0] = filed;
	*((unsigned long *)&qElem.data[1]) = LONG_TO_B_ENDIAN( offset );
	qElem.data[5] = whence;
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrFSStatus( void )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = GETFSINFO_CMD;		
	qElem.nData = 0;		
	qAdd( mySafeBox.queuedActions, &qElem );
}


void safeBoxMgrSyncFramesQty( void )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = SYNCFRAMEQTY;		
	qElem.nData = 0;		
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrForceUserPass( char *userId, char *newPass )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = FORCEUSER_CMD;		
	qElem.nData = 26;		
	qElem.data = (unsigned char *) malloc( qElem.nData );
	memset( qElem.data, 0, qElem.nData );
	strcpy( &qElem.data[0], userId );
	memcpy( &qElem.data[16], newPass, 8 );
	//la cantidad de frames la asigno al momenot de mandar el comando por el puerto! sino no coincide la cantidad
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrFSReInitFile( unsigned char filed )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = REINITFILE_CMD;		
	qElem.nData = 1;		
	qElem.data = (unsigned char *) malloc( qElem.nData );
	qElem.data[0] = filed;
	qAdd( mySafeBox.queuedActions, &qElem );
}


void safeBoxMgrSetTimeLock( unsigned char tLock0, unsigned char tLock1, unsigned char tLock2, unsigned char tLock3 )
{
	
	qElem.dev = SAFEBOX;		
	qElem.cmd = TLOCK_CMD;		
	qElem.data = (unsigned char *) malloc(4);
	qElem.data[0] = tLock0;
	qElem.data[1] = tLock1;
	qElem.data[2] = tLock2;
	qElem.data[3] = tLock3;
	if ( mySafeBox.oldFirmProtocol)
		// si es protocolo viejo solo configuro las dos primeras cerraduras
		qElem.nData = 2;		
	else 
		qElem.nData = 4;		

	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrSetTimeUnLockEnable( unsigned char tUnLockEnable0, unsigned char tUnLockEnable1 , unsigned char tUnLockEnable2 , unsigned char tUnLockEnable3 )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = TUNLOCKENABLELOCKS_CMD;		
	qElem.data = (unsigned char *) malloc(4);
	qElem.data[0] = tUnLockEnable0;
	qElem.data[1] = tUnLockEnable1;
	qElem.data[2] = tUnLockEnable2;
	qElem.data[3] = tUnLockEnable3;
	if ( mySafeBox.oldFirmProtocol)
		// si es protocolo viejo solo configuro las dos primeras cerraduras
		qElem.nData = 2;		
	else 
		qElem.nData = 4;		

	qAdd( mySafeBox.queuedActions, &qElem );

}

void safeBoxMgrShutdown( void )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = SHUTDOWN_CMD;		
	qElem.nData = 0;		
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxResetMcu( void )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = RESET_MCU;		
	qElem.nData = 0;		
	resetMcuCmdRta = -1; //para esperar a q se ejecute
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrGetUsrsInfo( void )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = GETUSRINFO_CMD;		
	qElem.nData = 0;		
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrSetDevStatus( char devId, char energyStatus )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = VALPWR_CMD;		
	qElem.nData = 2;		
	qElem.data = (unsigned char *) malloc(qElem.nData);
	qElem.data[0] = devId;
	qElem.data[1] = energyStatus;
	qAdd( mySafeBox.queuedActions, &qElem );
}

void safeBoxMgrResetDev( char devId )
{
	delayRequired = 1;
	safeBoxMgrSetDevStatus( devId, 0 );
	safeBoxMgrSetDevStatus( devId, 1 );
}


void safeBoxMgrFormatUsrs( void )
{
	qElem.dev = SAFEBOX;		
	qElem.cmd = USRFMT_CMD;		
	qElem.nData = 0;		
/*	qElem.data = (unsigned char *) malloc(qElem.nData);
	memset( qElem.data, 0, qElem.nData );
	strcpy( &qElem.data[0], usrIdVal );
	memcpy( &qElem.data[16], passVal, 8 );*/
	qAdd( mySafeBox.queuedActions, &qElem );
}

void billAcceptorSetParams ( unsigned char device, ValConfig *valConfig )
{
	//doLog(0,"VAL CONFIGGG \n");
	//doLog(0,"SET DEVICE %d \n", device );
	//doLog(0,"parity %d\n", valConfig->parity);
	fflush(stdout);
	memcpy(	&mySafeBox.valConfig[device], valConfig, sizeof(ValConfig));
	mySafeBox.jcmBillAcceptors[device]->protocol = mySafeBox.valConfig[device].protocol;
	//MOVI ESTO DE LUGAR POR UN ERROR QUE ENCONTRO NESTOR..
	// se estaba mandando la configuracin antes de copiarla a la estructura, por eso lo pase al final
	//faltaria probar el cambio
	mySafeBox.valConfigPending = 1;
}

char safeBoxMgrGetPowerStatus( void )
{
	return  mySafeBox.gr1Status.powerSupply;
}

char safeBoxMgrGetSystemStatus( void )
{
	return  mySafeBox.gr1Status.system;	
}

char safeBoxMgrGetBatteryStatus( void )
{
	return  mySafeBox.gr1Status.battery;
}

char safeBoxMgrGetMemStatus( char memId )
{
	if ( mySafeBox.gr1Status.memory == -1 )
		return -1; //dato no obtenido
		
	if ( memId == PRIMARY_MEM )
		return ( mySafeBox.gr1Status.memory >= 2 );	//es 2 o 3, both fail or main fail
	else
		return ( mySafeBox.gr1Status.memory == 1 || mySafeBox.gr1Status.memory == 3 );	//es 2 o 3, both fail or main fail
}

char safeBoxMgrInit( char portNumber, changeAcceptorStatusNotif statusNotifFcn, billRejectedNotif billRejectNotifFcn, billAcceptedNotif billAcceptNotifFcn, comunicationErrorNotif comunicationErrorNotifFcn, changeAcceptorStatusNotif acceptingNotifFcn, actionResponseNotif actionResultFcn )
{
	mySafeBox.status = NOT_INITIALIZED;
	mySafeBox.valConfigPending = mySafeBox.allConfigured = 0;
	memset(mySafeBox.valConfig, 0, sizeof(mySafeBox.valConfig));
	mySafeBox.valConfig[0].protocol = mySafeBox.valConfig[1].protocol = -1;
	mySafeBox.queuedActions = qNew( sizeof( QueueElement ), 150 );
    mySafeBox.statusNotificationFcn = statusNotifFcn;
    mySafeBox.billRejectNotificationFcn = billRejectNotifFcn;
    mySafeBox.billAcceptNotificationFcn = billAcceptNotifFcn;
    mySafeBox.commErrorNotificationFcn = comunicationErrorNotifFcn;
	mySafeBox.acceptingNotificationFcn = acceptingNotifFcn;
	mySafeBox.actionResultFcn = actionResultFcn;
	mySafeBox.oldFirmProtocolNotified = 0;
	memset(	&mySafeBox.gr1Status, -1, sizeof(Gr1Status));
	
	*mySafeBox.version = '\0';
	if ( safeBoxCommOpen( portNumber )) {

		mySafeBox.jcmBillAcceptors[0] = billAcceptorNew( VAL0 , mySafeBox.statusNotificationFcn, mySafeBox.billRejectNotificationFcn, mySafeBox.billAcceptNotificationFcn, mySafeBox.commErrorNotificationFcn, mySafeBox.acceptingNotificationFcn );
		mySafeBox.jcmBillAcceptors[1] = billAcceptorNew( VAL1 , mySafeBox.statusNotificationFcn, mySafeBox.billRejectNotificationFcn, mySafeBox.billAcceptNotificationFcn, mySafeBox.commErrorNotificationFcn, mySafeBox.acceptingNotificationFcn );
		
	//    doLog(0,"antes ejecutar thread \n");fflush(stdout);
		msleep(400);
	
    	jcmThread = [JcmThread new];
		[jcmThread setExecFun: safeBoxMgrRun];

    	[jcmThread start];
    	
		safeBoxMgrSetDevStatus(0,1);
		safeBoxMgrSetDevStatus(1,1);
        
        
        rdmInit( 1 );
        
    	return 1;  
  }
  return 0;
}

void safeBoxMgrUnInit( void )
{
	//tendria q mandarle el comando shutdown?
	if ( mySafeBox.status == INITIALIZED ){
		free( mySafeBox.jcmBillAcceptors[0]);
		free(mySafeBox.jcmBillAcceptors[1]);
	}
}       

/*
JcmBillAcceptData *getValidator( char devId )
{
  int i;
  for ( i = 0;  ( i < 2 ) && (mySafeBox.jcmBillAcceptors[i]->devId != devId); ++i )
    ;
  if ( i < 2 )
  	return mySafeBox.jcmBillAcceptors[i];
  	
  return NULL;	
}
*/

/*
  Inicia / Finaliza el censado del ingreso de billetes. Cuando el proceso se completa, se notifica a 
  traves de la funcion de callback registrada
*/
void billAcceptorChangeStatus( char devId, char newStatus )
{
 	if ( devId <= 1 ){
		doLog(0,"billAcceptorChangeStatus!!!!!!!!!!!!!!!! deviD %d %d\n", devId, newStatus);fflush(stdout);
   		mySafeBox.jcmBillAcceptors[devId]->pendingStatus = newStatus;
	}
}

/*
  Inicia / Finaliza el censado del ingreso de billetes. Cuando el proceso se completa, se notifica a 
  traves de la funcion de callback registrada
*/
unsigned short getBillAcceptorLastStackedQty( char devId, long long *billAmount, int *currencyId )
{
 	if ( devId <= 1 ){
		//doLog(0,"billAcceptorChangeStatus!!!!!!!!!!!!!!!! %d\n", newStatus);fflush(stdout);
   		return (getLastStackedQty(mySafeBox.jcmBillAcceptors[devId], billAmount, currencyId));
	} 
	return 0;
}


void billAcceptorSetDenomination( char devId, long long amount, int disable )
{
	int amountDen, i;
	
 	if ( devId <= 1 ){
		amountDen = ( amount / MultipApp );
		for ( i = 0; i < 8; ++i ){    
			if ( mySafeBox.jcmBillAcceptors[devId]->convertionTable[i].amount == amountDen ) {
		//		doLog(0,"amount den %d disabled %d\n", amountDen, disable); fflush(stdout);
				mySafeBox.jcmBillAcceptors[devId]->convertionTable[i].disabled = disable;
				return;
			} 
		} 
	}
} 


void billAcceptorCommunicatStat ( char devId, char enableComm )
{
 	if ( devId <= 1 ){
 		if ( enableComm )
            
			billAcceptorStart( mySafeBox.jcmBillAcceptors[devId] );
		else
			billAcceptorStop( mySafeBox.jcmBillAcceptors[devId] );
	} 
}


JCMDenomination *billAcceptorGetDenominationList( char devId, int *currencyId )
{
 	if ( devId <= 1 ) {
        printf("**********************************billAcceptorGetDenominationList\n");
 		*currencyId = mySafeBox.jcmBillAcceptors[devId]->countryCode;
		return mySafeBox.jcmBillAcceptors[devId]->convertionTable;
	} else
		return NULL;
}

static unsigned char bufRead[255];

// si esta ok retorna el size del archivo, sino 0
unsigned short fileOk( char *firmwarePath )
{
	unsigned short size, cheks, calcChk, i, bytesWrite;

	if (!( mySafeBox.firmImage = fopen( firmwarePath, "rb" ))){
	    doLog(0,"error \n" );fflush(stdout);
		return 0; //error
	}
	
	fseek( mySafeBox.firmImage, 0, SEEK_END );
    size = ftell ( mySafeBox.firmImage );
    
    if ( size > 0 ){
    	fseek( mySafeBox.firmImage, 0, SEEK_SET );	

		fread( bufRead, 1, 2, mySafeBox.firmImage );
		cheks = SHORT_TO_B_ENDIAN(*((unsigned short*) bufRead));
		calcChk = 0;

		while (( bytesWrite = fread( bufRead, 1, UPD_FRAME_SIZE, mySafeBox.firmImage )) > 0 ) {
			  for  ( i = 0; i < bytesWrite; ++ i)
					calcChk += bufRead[i];
		}
		calcChk = 65535 - calcChk;
		if ( calcChk == cheks )
			return size;
	}
	return 0;
}

char * doGetInnerBoardVersion( void )
{
}


char innerBoardUpdate(char *firmwarePath, changeAcceptorStatusNotif firmUpdProgress)
{
	long size;
	unsigned short bytesWrite;
	unsigned char *rta;
	unsigned int framesQty, tries;
	unsigned int totalFrames;
	unsigned int lastProgressNotif, actualProgress;	
	
	doLog(0,"InnerBoardUpd: %s\n", firmwarePath);fflush(stdout);

	if (( size = fileOk( firmwarePath )) > 0 ){

		fseek( mySafeBox.firmImage, 0, SEEK_SET );	

      	framesQty = 1;
		lastProgressNotif = 0;		
  		totalFrames = ( size / UPD_FRAME_SIZE ) + 1;
		commandsRtaFcn[WRITEFILE_CMD] = commandsRtaFcn[REINITFILE_CMD] = safeBoxReady;
		
		isReady = 0;
		safeBoxMgrFSReInitFile( 10 );
		while ( !isReady ) 
			msleep(500);
		
		while (( bytesWrite = fread( bufRead, 1, UPD_FRAME_SIZE, mySafeBox.firmImage )) > 0 ) {
			isReady = 0;
			//doLog(0,"bytes write! %d\n", bytesWrite);fflush(stdout);
			safeBoxMgrFSWrite( 10, bytesWrite, 1, bufRead );
			while ( !isReady ) 
				msleep(500);

			actualProgress = ( framesQty * 100 / totalFrames );
			if (( actualProgress != lastProgressNotif ) && ( firmUpdProgress != NULL )) {
				( *firmUpdProgress )( SAFEBOX, actualProgress);
				lastProgressNotif = actualProgress;
			}
			framesQty++;
				
		}
		if ( firmUpdProgress != NULL && lastProgressNotif < 100 )
			( *firmUpdProgress )( SAFEBOX, 100 );

		
		tries = 0;
		do {
			safeBoxResetMcu();
			while (	resetMcuCmdRta == -1 )
				msleep(200);
			doLog(0,"resetMcuRta %d\n", resetMcuCmdRta);
			tries++;
		} while( resetMcuCmdRta != 1 && tries < 3 );

		commandsRtaFcn[WRITEFILE_CMD] = commandsRtaFcn[REINITFILE_CMD] = safeBoxCommonRta;
		fclose(mySafeBox.firmImage);
		mySafeBox.firmImage = NULL;
		mySafeBox.status = NOT_INITIALIZED;
		*mySafeBox.version = '\0';
		while ( *mySafeBox.version == '\0' )
			msleep(100);
		mySafeBox.valConfigPending = 1;

		return 1;
	} 
	return 0;

}
				
char safeBoxMgrUpdateFirmware( char devId, char *firmwarePath, changeAcceptorStatusNotif firmUpdProgress )
{
	
	if ( mySafeBox.status == INITIALIZED ){
	 	if ( devId <= 1 )
	 		return ( billAcceptorUpdate( mySafeBox.jcmBillAcceptors[devId], firmwarePath, firmUpdProgress));
		else {
			if ( devId == 8 )
			//actualizar el safebox
				return ( innerBoardUpdate(firmwarePath, firmUpdProgress));
		}
	} 
 	return 0;
 	
}

void billAcceptorsEnableReset( void )
{
	//doLog(0,"enable reset!\n"); fflush(stdout);
  	mySafeBox.jcmBillAcceptors[0]->canResetVal = 1;
  	mySafeBox.jcmBillAcceptors[1]->canResetVal = 1;
}

char *billAcceptorGetVersion( char devId )
{
 	if ( devId <= 1 )
 		return ( mySafeBox.jcmBillAcceptors[devId]->jcmVersion );
 	return NULL;
}

void runDevice( unsigned char devId )
{
	billAcceptorRun( mySafeBox.jcmBillAcceptors[devId] );
}

void safeBoxMgrRun( void * foo)
{

  	while (1) {
		if ( mySafeBox.firmImage == NULL ) {	
			safeBoxMgrGr1ReqStatus();
			
			if ( !mySafeBox.safeBoxCommErrorStatus ) {
			//si estoy en estado de error no encuesto el resto de las cosas
				runDevice( 0 ); //val0 o hoppers en su lugar

				runDevice( 1 ); //val1 o hoppers en su lugar

				safeBoxProcessQueuedElem();
			} else {
                printf("SafeboxRun safeboxCommErrorStatus == 1\n");
				msleep(100);
            }
		} else {
			safeBoxProcessQueuedElem();
			msleep(500);
		}
	}
}

