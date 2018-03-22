#ifndef SAFE_BOX_MGR_H
#define SAFE_BOX_MGR_H

#include "system/util/all.h"
#include "system/os/comportapi.h"
#include "jcmBillAcceptorMgr.h"
#include "queue.h"


enum {
	VAL0 = 0, VAL1, LOCKER0, PLUNGER0, LOCKER1, PLUNGER1, ALARM0, ALARM1, SAFEBOX, STACKER0, STACKER1,
	LOCKER2, LOCKER3, PLUNGER2, PLUNGER3 , KEY_SWITCH, /*16*/ POWER_ST, SYSTEM_ST, BATT_ST, 
	LOCKER0_ERR, LOCKER1_ERR, LOCKER2_ERR, LOCKER3_ERR 
}; 

//safeBoxCommands:
enum {
	NO_CMD = 0,    UNLOCK_CMD,    LOCK_CMD,     ACTRL_CMD,      ADDUSR_CMD,     DELUSR_CMD,  EDITUSRPASS_CMD,
	GETUSRDEV_CMD, SETUSRDEV_CMD, VALUSR_CMD,   GETUSRINFO_CMD, USRFMT_CMD,     VERSION_CMD, MODEL_CMD, 
	SHUTDOWN_CMD,  GR1_CMD,   	  BLANKFS_CMD,  CREATEFILE_CMD, STATUSFILE_CMD, READFILE_CMD,WRITEFILE_CMD, 
	SEEKFILE_CMD,  REOPENFILE_CMD,CLOSEFILE_CMD,REINITFILE_CMD,	GETFSINFO_CMD,  TLOCK_CMD,   TUNLOCKENABLE_CMD,
	SBOX_FAILURE_CMD,SBOX_SUCCESS_CMD, SBOX_NACK_CMD, VALCONFIG_CMD, FORCEUSER_CMD, SYNCFRAMEQTY, HOSTPOWER_CMD,
	RESET_MCU, TUNLOCKENABLELOCKS_CMD, VALPWR_CMD, COMMANDS_QTY

}; 

enum {
	PRIMARY_MEM = 0, SECONDARY_MEM 
};

//errorCodes:
enum {
	ERR_USR_NOT_EXISTS = 1, ERR_USR_BAD_PASSWORD, ERR_USER_NUM_EXCEEDED, ERR_USER_EXISTS, 
	ERR_USER_DEVID_NOT_ALLOWED, ERR_USER_COMM_NOT_IN_EMER ,ERR_FLASH_NOT_REACHABLE, 
	ERR_FLASH_BAD_PROGRAM, ERR_LP_INVALID_CONTENT, ERR_DFILE_INVALID_DF, ERR_DFILE_BAD_ACCESS, 
	ERR_DFILE_NOT_ENOUGH, ERR_DFILE_NOT_ALLOWED, ERR_DFILE_BAD_WHENCE, ERR_DFILE_BAD_SEEK, 
	ERR_DFILE_BAD_FDESC, ERR_DFILE_EXISTS_FDESC,ERR_DFILE_NOT_EXISTS, ERR_DFILE_BAD_ORIGIN, 
	ERR_DFILE_SECTOR_ERROR, ERR_DFILE_BAD_OFFSET, ERR_DFILE_BAD_UNITSIZE, 
	ERR_DFILE_BAD_NUMUNITS, ERR_COMMUNICATION_ERROR, ERR_INCOMPATIBLE_FIRMWARE, ERR_UNKNOWN_ERROR = 128
};  


enum {
	ID003 = 0, CCNET, CCTALK, MAXVEND, EBDS, FUJITSU, CDM3000, RDM100, PROTQTY
};

typedef void( *actionResponseNotif )( unsigned char devId, unsigned char cmd, unsigned char rta, unsigned char *aditData );

/**
 *	Estados del validador de dinero
 *	JCM_ENABLE : el validador esta censando el ingreso de dinero y almacena los billetes
 *	JCM_DISABLE : el validador no esta disponible para censar dinero, ya sea por indicacion de la aplicaci�n o bien por una perdida de comunicacion con el validador. 
 *  JCM_VALIDATE_ONLY: el validador toma los billetes, los valida y retorna al usuario
 */
typedef enum {
	JCM_NOT_INIT = 0
	,JCM_ENABLE 
	,JCM_DISABLE
	,JCM_VALIDATE_ONLY
} JcmStatus;

typedef struct {
	char locker0;
	char plunger0;
	char locker1;
	char plunger1;
	char safeBox;
	char stacker0;
	char stacker1;
	char locker0Error;
	char locker1Error;
	char locker2;
	char locker3;
	char plunger2;
	char plunger3;
	char keySwitch;
	char locker2Error;
	char locker3Error;
	char powerSupply;
	char system;
	char battery;	
	char memory;	
} Gr1Status;

typedef enum {	
	V_PARITY_NONE = 0,	
	V_PARITY_EVEN,
	V_PARITY_ODD,
	V_PARITY_HIGH,
	V_PARITY_LOW
} ParityT;

typedef enum {	
	V_STOPBITS_ONE = 0,	
	V_STOPBITS_TWO	
} StopBitsT;

typedef enum {	
	V_WORDBITS_8 = 0,	
	V_WORDBITS_7,	
	V_WORDBITS_6,	
	V_WORDBITS_5
} WordBitsT;

typedef enum {
	BRV_300 = 0,
	BRV_600,
	BRV_1200,
	BRV_2400,
	BRV_4800,
	BRV_9600,
	BRV_19200,
	BRV_38400,
	BRV_57600
} BaudRateT;

typedef struct {
	BaudRateT baudRate;
	ParityT parity;
	StopBitsT stopBits;
	WordBitsT wordBits;
	unsigned char startTimeout;
	char protocol; //-1 cuando aun no fue configurado
	char echoDisable;
} ValConfig;

typedef struct {
	JcmBillAcceptData *jcmBillAcceptors[4];
	Queue *queuedActions;
	changeAcceptorStatusNotif statusNotificationFcn;
	billRejectedNotif billRejectNotificationFcn;
	billAcceptedNotif billAcceptNotificationFcn;
	comunicationErrorNotif commErrorNotificationFcn;
	changeAcceptorStatusNotif acceptingNotificationFcn;
	actionResponseNotif actionResultFcn;	
	//int jcmValQty;
	char safeBoxCommErrorStatus;
	char oldFirmProtocol;
	char oldFirmProtocolNotified;
	char version[30];
	unsigned char valStatus[2]; //o parados, 1 activos
	char status;
	Gr1Status gr1Status;
	char valConfigPending;
	char allConfigured;
	ValConfig valConfig[2];
	FILE *firmImage;
} SafeBox;

extern SafeBox mySafeBox;


void safeBoxMgrUnInit( void );
//char safeBoxMgrGetModel( void );
char * safeBoxMgrGetVersion( void );

void safeBoxMgrUnLock( unsigned char devId, char *usrId1, char *usrId2, char * passUsr1, char * passUsr2 );
void safeBoxMgrLock( unsigned char devId );

void safeBoxMgrSetAlarm( unsigned char devId, unsigned char disable );
/*
	Se mapean en devList las dos nuevas cerraduras!!
	Agrega el usuario usrId con la configuracion de dispositivos permitidos en devList.
	El mapeo de los bits de devList es:
	
			15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0 			
														L4	L3	L2   L1
																
	Los codigos de errores posibles a este comando son:
	ERR_USER_EXISTS/ERR_USER_NUM_EXCEEDED/ERR_FLASH_BAD_PROGRAM/ERR_INVALID_CONTENT
																	
*/
void safeBoxMgrAddUsr( unsigned short devList, char *usrId, char *passPri, char *passSec, char *usrIdVal, char *passVal );

/*
	Solicita la eliminaci�n del usuario usrId
	
	Errores posibles:
	ERR_USER_NOT_EXISTS / ERR_FLASH_BAD_PROGRAM/ ERR_INVALID_CONTENT
 
*/
void safeBoxMgrDelUsr( char *usrId, char *usrIdVal, char *passVal );

/*
	Edita el registro que coincide con oldPass-usrId cambiando su clave (primario o durest dependiendo de 
	passType, 0 � 1 respectivamente)por newPass.
	
	Errores posibles:
	ERR_USER_NOT_EXISTS/ERR_USER_BAD_PASSWORD/ERR_FLASH_BAD_PROGRAM/ERR_INVALID_CONTENT

*/
void safeBoxMgrEditUsrPass( char *usrId, char *newPass, char *oldPass, char passType );

/*
	Valida la contrase�a especificada en pass para el usrId.
	Retorna en caso que la validaci�n sea exitosa:
	
	Campo		Longitud		Descripci�n
	--------------------------------------------------------------------------------------
	DEVLIST			2			 Configuraci�n de dispositivos
	PWD_MATCH		1			 Valor 0/1, coincidencia con la primer o segunda clave

	Errores posibles:
 	 ERR_USER_NOT_EXISTS / ERR_USER_BAD_PASSWORD / ERR_FLASH_BAD_PROGRAM / ERR_INVALID_CONTENT
*/
void safeBoxMgrValUsr( char *usrId, char *pass );

void safeBoxMgrSetUsrDev( char *usrId, unsigned short devList, char *usrIdVal, char *passVal );
void safeBoxMgrGetUsrDev( char *usrId );

/*
	Solicita la m�xima cantidad de usuarios y la cantidad de usuarios disponibles.
	
	Campo	Longitud	Descripci�n
	---------------------------------------------------------------
	MAX_USERS	2	M�xima cantidad de usuarios
	FREE_USERS	2	Cantidad de usuarios disponibles

*/
void safeBoxMgrGetUsrsInfo( void );

/*
	Solicita el borrado y destrucci�n de todos los usuarios que han sido creados.
*/
void safeBoxMgrFormatUsrs( void );

/*
	Solicita la destrucci�n completa del sistema de archivos. Elimina todos los archivos
*/
void safeBoxMgrFsBlank( void );

/*
	Solicita la creaci�n de un nuevo archivo dentro del sistema de archivos. 
	Existen dos tipos de archivo a crear, los tipos RANDOM y los tipos QUEUE. Ambos se refieren 
	al acceso a la informaci�n que ellos contienen. Los tipos RANDOM pueden accederse de manera 
	aleatoria, mientras que los tipos QUEUE funcionan de manera semejante a la estructura de datos 
	tipo cola, por lo tanto su acceso es del tipo FIFO. A estos �ltimos puede cambiarse moment�neamente 
	su acceso al tipo aleatorio. De esta manera, pueden utilizarse las mismas operaciones que los 
	archivos tipo RANDOM, la �nica restricci�n es la escritura.
	La asignaci�n de archivos mediante descriptores de archivos la establece el master de la comunicaci�n.
	El m�ximo n�mero permitido para los descriptores de archivos es 9, siendo el rango [0 - 9].
	Par�metros:
		* filed: descriptor del archivo a crear
		* unitSize: tama�o del registro
		* type: 0 random
				1 queue
		* numUnits: determinar� el tama�o del archivo. El archivo se crea del tama�o especificado no pudiendo
		variar a lo largo del tiempo.
	Errores:
	ERR_DFILE_NOT_ALLOWED/ERR_INVALID_CONTENT/ERR_DFILE_NOT_ENOUGH/ERR_DFILE_INVALID_DF/ERR_DFILE_EXIST_FDESC		
	
	En caso de retornar ERR_DFILE_NOT_ENOUGH, a continuacion se retorna un long con la cantidad de unidades que 
	hay disponibles para la creacion del mismo.
*/
void safeBoxMgrFSCreateFile( unsigned char filed, unsigned char unitSize, unsigned char type, unsigned long numUnits );

/*
	Lee la cantidad de registros especificada en numUnits desde un archivo especificado en filed, 
	de acuerdo a su tipo. Si es tipo RANDOM, lee a partir de la posici�n actual, 
	de lo contrario lee desde el �ndice de salida actual.
	La lectura de archivos de tipo QUEUE (que no esten reabiertos como RANDOM) ocasiona que se 
	eliminen los registros leidos de la cola.
	IMPORTANTE: LA SUMA DE BYTES A LEER NO PUEDE SUPERAR LOS 254 BYTES!
	
	En la funcion de callback se retorna la informacion de la siguiente manera:
	
	Alias		Longitud	Descripci�n
	NUM_UNITS		2		N�mero de unidades le�das. Dependiendo del tipo de archivo, si esta 
							cantidad es menor a la solicitada puede que ocurra lo siguiente:
								Tipo  de archivo	Situaci�n
								RAMDOM				Final de archivo alcanzado.
								QUEUE				La cola est� vac�a o ha sido vaciada en esta llamada.
	BUFF		1 - 254			Datos de las unidades le�das.

	Errores posibles:
	
	C�digo de error				Descripci�n
	 ERR_DFILE_INVALID_DF		 Descriptor fuera de rango o archivo no creado.
  	 ERR_INVALID_CONTENT		 El contenido de la trama recibida es inv�lido.
	 ERR_DFILE_NOT_ALLOWED		 Error en par�metro.
	 ERR_DFILE_SECTOR_ERROR		 Hubo un error de lectura. El campo BUFF contiene los datos solicitados sin 
	 							 embargo no se asegura su consistencia.
 	 BUFF						 Datos de las unidades le�das, �nicamente junto al error ERR_DFILE_SECTOR_ERROR.

*/
void safeBoxMgrFSRead( unsigned char filed, unsigned char numUnits );

/*
	Solicita la escritura de una determinada cantidad de unidades l�gicas en un archivo particular. 
	Para el caso de archivos re-abiertos como RANDOM esta operaci�n es denegada.
	IMPORTANTE: LA SUMA DE BYTES A ESCRIBIR NO PUEDE SUPERAR LOS 254 BYTES!
	
	En la funcion de callback se retorna la informacion de la siguiente manera:
	
	Alias		Longitud	Descripci�n
	NUM_UNITS		2		N�mero de unidades escritas. Dependiendo del tipo de archivo, si esta 
							cantidad es menor a la solicitada puede que ocurra lo siguiente:
								Tipo  de archivo	Situaci�n
								RAMDOM				Final de archivo alcanzado.
	
*/
void safeBoxMgrFSWrite( unsigned char filed, unsigned char numUnits, unsigned char unitSize, unsigned char *buf );

/*
	Posiciona un archivo de tipo RANDOM o reabierto como RANDOM seg�n indica OFFSET. El valor de WHENCE debe 
	ser FDF_SEEK_SET, FDF_SEEK_CUR o FDF_SEEK_END, indicando si OFFSET es relativo al comienzo del archivo, 
	a la posici�n actual o al final del archivo, respectivamente.
	
	Parametros:
	* filed: Descriptor de archivo.
	* offset: Posici�n del archivo seg�n origen WHENCE, de acuerdo con la unidad del archivo. 
	* whence: Indica si OFFSET es relativo al comienzo, a la posici�n actual o al final del archivo.
			  FDF_SEEK_SET	= 0	, FDF_SEEK_CUR	= 1, FDF_SEEK_END = 2

	Errores Posibles: 	
	ERR_DFILE_INVALID_DF / ERR_INVALID_CONTENT/ERR_DFILE_NOT_ALLOWED/ERR_FDF_BAD_SEEK
			  
*/
void safeBoxMgrFSSeek( unsigned char filed, long offset, unsigned char whence );

/*
	Solicita el estado de un archivo determinado. Esta operaci�n retorna informaci�n para archivos 
	tipo RANDOM y QUEUE, por lo tanto, dependiendo de este �ltimo es la informaci�n utilizable:
	
	Respuesta:
	Campos		Longitud	Descripci�n				V�lido para tipo de archivo
	---------------------------------------------------------------------------
	UNIT_SIZE		1		Tama�o de la unidad.		RANDOM, QUEUE
	FILE_TYPE		1		Tipo de acceso.				RANDOM, QUEUE
	NUM_UNITS		4		N�mero de unidades.			RANDOM, QUEUE
	OUT_INDEX		4		�ndice de salida.			QUEUE
	IN_INDEX		4		�ndice de entrada. 			QUEUE
	NUM_ELEMS		4		Numero de elementos.		QUEUE
	POSITION		4		Posici�n actual.			RANDOM

	Errores posibles:
	ERR_DFILE_INVALID_DF/ERR_INVALID_CONTENT/ERR_DFILE_NOT_ALLOWED

*/
void safeBoxMgrFSStatusFile( unsigned char filed );

void safeBoxMgrFSStatus( void );

void safeBoxMgrSyncFramesQty( void );
void safeBoxMgrForceUserPass( char *userId, char *newPass );


/*
	El archivo retorna a su condici�n de creaci�n. En archivos tipo RANDOM, todas sus unidades son puestos 
	a cero, y su posiciones actual es el comienzo del archivo. En archivos tipo QUEUE los �ndices son 
	iniciados al comienzo de la cola y la cantidad de elementos de la cola es puesta a cero

	Errores posibles:
	ERR_DFILE_INVALID_DF/ERR_INVALID_CONTENT
*/
void safeBoxMgrFSReInitFile( unsigned char filed );

void safeBoxMgrResetDev( char devId );
void safeBoxMgrSetDevStatus( char devId, char energyStatus );
void billAcceptorChangeStatus( char devId, char newStatus );
void billAcceptorSetDenomination( char devId, long long amount, int disable );
JCMDenomination *billAcceptorGetDenominationList( char devId, int *currencyId );
char safeBoxMgrUpdateFirmware( char devId, char *firmwarePath, changeAcceptorStatusNotif firmUpdProgress );
char *billAcceptorGetVersion( char devId );
void billAcceptorsEnableReset( void );
void billAcceptorCommunicatStat ( char devId, char enableComm );

void billAcceptorSetParams ( unsigned char device, ValConfig *valConfig );

 /*
	Setea el tiempo (en SEGUNDOS!) que la cerradura permanece energizada para que sea abierta por 
	el usuario
	
	tLock0: tiempo de la cerradura 0
	tLock1: tiempo de la cerradura 1
	
*/
void safeBoxMgrSetTimeLock( unsigned char tLock0, unsigned char tLock1, unsigned char tLock2, unsigned char tLock3 );



/*
	Solicita el cambio del tiempo de bloqueo (en MINUTOS!)
	Luego de recibir el comando UNLOCK, el Safe-Box espera durante TUNLOCKENABLE segundos la 
	habilitaci�n del desbloqueo de la cerradura. 
	Luego de detectar la habilitaci�n realiza el desbloqueo efectivo de la cerradura.
	Este comando lo env�a el CT8016 hacia el Safe-Box solicitando el cambio del tiempo de 
	habilitaci�n de desbloqueo de una cerradura. En caso que no se env�e dicho comando, 
	el Safe-Box lo anula.
	
	* tUnLockEnable:
	Valor	Descripci�n
	------------------------------------------------------------------------------------
		0	Si no se requiere esta caracter�stica se establece el valor '0' o nulo.
	1 - 20	Tiempo m�ximo de espera para la habilitaci�n del desbloqueo.
	
*/
void safeBoxMgrSetTimeUnLockEnable( unsigned char tUnLockEnable0, unsigned char tUnLockEnable1 , unsigned char tUnLockEnable2 , unsigned char tUnLockEnable3 );




void safeBoxMgrShutdown( void );

char safeBoxMgrGetPowerStatus( void );
char safeBoxMgrGetSystemStatus( void );
char safeBoxMgrGetBatteryStatus( void );
/*
	*memId:
	PRIMARY_MEM = 0, SECONDARY_MEM 
	
	*returns:
	-1 status no obtenido aun
	0 ok
	1 error
*/
char safeBoxMgrGetMemStatus( char memId );
void safeBoxMgrRun( void * foo);

/*
	- portNumber: puerto de comunicacion
	- statusNotifFcn: funcion q notifica los siguientes cambios de estado:

		* devId: VAL0/VAL1
		* newStatus: JCM_ENABLE = 1 / JCM_DISABLE = 2

		* devId: LOCKER0/LOCKER1/LOCKER2/LOCKER3
		* newStatus: LOCKED = 0 / UNLOCKED = 1 

		* devId: PLUNGER0/PLUNGER1/PLUNGER2/PLUNGER3
		* newStatus: OPENED = 0 / CLOSED = 1 
	
		* devId: POWER_ST
		* newStatus: EXT = 0 / BACKUP = 1 

		* devId: SYSTEM_ST
		* newStatus: PRIMARY = 0 / SECONDARY = 1 

		* devId: BATT_ST	
		* newStatus: BATTLOW = 0 / BATTREM = 1 / BATTOOK = 2
		
		* devId: STACKER0/STACKER1	
		* newStatus: INSTALLED = 0 / REMOVED = 1 
		
		* devId: LOCKER0_ERR/LOCKER1_ERR/LOCKER2_ERR/LOCKER3_ERR

		* newStatus: OK = 0 / DRVA = 1 / DRVB = 2 / OPEN = 3 / FAIL = 4
			donde:
				- OK: el locker funciona correctamente
				- DRVA: el driver A del locker esta en cortocircuito. El locker puede seguir operando	
				- DRVB: el driver B del locker esta en cortocircuito. El locker puede seguir operando	
				- OPEN: el inductor del locker esta abierto. EL LOCKER NO PUEDE OPERAR!
				- FAIL: los drivers A y B estan en cortocircuito. EL LOCKER NO PUEDE OPERAR!
			
	- billRejectNotifFcn : funcion q notifica cuando un validador rechaza un billete
		
		* devId : VAL0/VAL1
		* cause : 71h .. 7eh, donde:
				71h insertion error
				72h magnetic pattern errror
				73h  iddle but sensor detected
				74h data amplitude error
				75h feed error
				76h denomination assesing error
				77h photo pattern error
				78h photo level error
				79h bill disabled
				7ah reserved
				7bh operation error
				7ch bill detected at wrong time
				7dh length error
				7eh color pattern error

	- billAcceptNotifFcn : funcion q notifica cuando un validador reconoce un billete. 
						   Si el validador esta en estado JCM_ENABLE, el billete fue almacenado, 
						   de lo contrario el billete es validado pero fue retornado al usuario.
		
		* devId : VAL0/VAL1
		* billAmount : importe del billete detectado, representado de acuerdo al multiplicador de la 
						aplicacion-

	- comunicationErrorNotifFcn: funcion q notifica un error en el validador:

		* devId : VAL0/VAL1
		* cause : 43h .. 4ah, donde:
				43h Stacker Full
				44h Stacker Open
				45h Jam In Acceptor
				46h Jam in Stacker
				47h Pause
				48h Cheated
				49h Failure
				4Ah Communication error
		* devId : SAFEBOX
		* cause : 0 Fin Error
			  ERR_COMMUNICATION_ERROR(24) Communication error
			  ERR_INCOMPATIBLE_FIRMWARE (25) Version de firmware de la innerboard incompatible con la aplicacion

	- acceptingNotifFcn: funcion q notifica a la aplicacion cuando un validador comienza
						 a detectar un billete nuevo, mas alla de q el mismo se encuentre en
						 estado JCM_ENABLE o JCM_DISABLE.

		* devId : VAL0/VAL1
		* status : 0x12
				devuelve el estado del validador. por el momento el unico estado q se esta reportando
				es el de accepting (0x12)	
				
	- actionResult: funcion q reporta el resultado de alguna accion solicitada por la aplicacion.
		
		* devId: SAFEBOX, LOCKER0, LOCKER2, LOCKER0, LOCKER3
		* cmd:	ver el enumerado con los safeBoxCommands:
		* resultType: SBOX_SUCCESS / SBOX_FAILURE / SBOX_NACK
		* aditData:	dependiente del comando.. a saber:
		
			- 	LOCKER0/LOCKER1/LOCKER2/LOCKER3 | UNLOCK_CMD | SBOX_SUCCESS_CMD | PWD0_MATCH(0)/PWD1_MATCH(1) | [ PWD0_MATCH(0)/PWD1_MATCH(1) ] 		
			- 	LOCKER0/LOCKER1/LOCKER2/LOCKER3  | UNLOCK_CMD | SBOX_FAILURE_CMD | ERR_USER_BAD_PASSWORD(2)/ERR_FLASH_NOT_RECHEABLE(6)/ERR_FLASH_BAD_PROGRAM(7)/ERR_LP_INVALID_CONTENT(8)
			
			- 	SAFEBOX | ADDUSR_CMD | SBOX_SUCCESS_CMD 
			- 	SAFEBOX | ADDUSR_CMD | SBOX_FAILURE_CMD | ERR_USER_DEVID_ALLREADY(4)/ERR_USER_DEVID_NOT_ALLOWED(5)/ERR_USER_NUM_EXCEED(3)/ERR_FLASH_NOT_RECHEABLE(6)/ERR_FLASH_BAD_PROGRAM(7)/ERR_LP_INVALID_CONTENT(8)
			
			- 	SAFEBOX | DELUSR_CMD | SBOX_SUCCESS_CMD 
			- 	SAFEBOX | DELUSR_CMD | SBOX_FAILURE_CMD | ERR_USER_DEVID_NOT_EXISTS(1)/ERR_FLASH_NOT_RECHEABLE(6)/ERR_FLASH_BAD_PROGRAM(7)/ERR_LP_INVALID_CONTENT(8)

			- 	SAFEBOX | VALUSR_CMD | SBOX_SUCCESS_CMD | PWD0_MATCH(0)/PWD1_MATCH(1)
			- 	SAFEBOX | VALUSR_CMD | SBOX_FAILURE_CMD | ERR_USER_BAD_PASSWORD(2)/ERR_FLASH_NOT_RECHEABLE(6)/ERR_FLASH_BAD_PROGRAM(7)/ERR_LP_INVALID_CONTENT(8)
		
*/
char safeBoxMgrInit( char portNumber, changeAcceptorStatusNotif statusNotifFcn, billRejectedNotif billRejectNotifFcn, billAcceptedNotif billAcceptNotifFcn, comunicationErrorNotif comunicationErrorNotifFcn, changeAcceptorStatusNotif acceptingNotifFcn, actionResponseNotif actionResult );

//Retorna la cantidad de billetes almacenados en el ultimo deposito (si hubiera deposito activo), y el importe y curId del ultimo billete stackeado
// Inicializa en cero estos valores luego de la llamada a la fcion..
unsigned short getBillAcceptorLastStackedQty( char devId, long long *billAmount, int *currencyId );

#endif
