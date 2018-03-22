#ifndef __DMODEM_H__
#define __DMODEM_H__

#define DM_SOH					0x01
#define DM_CTRL_BYTE_0			0x00
#define DM_CTRL_BYTE_1			0x00

#define DM_MAX_FRAME_LEN		525
#define DM_HEADER_LEN			9
#define DM_TAIL_LEN				4
#define DM_MAX_DATA_LEN			DM_MAX_FRAME_LEN - DM_HEADER_LEN - DM_TAIL_LEN
#define DM_MAX_DATA_READ		1024


/* Definicion de errores dmodem */   
enum
{	
	 EDMODEM_NOERROR = 0
	,EDMODEM_FATAL
	,EDMODEM_TXUPLAYER_TO
	,EDMODEM_RXUPLAYER_TO
	,EDMODEM_MAXRETRIES
	,EDMODEM_CONNECTION_TO
	,EDMODEM_EOT
};

#define DM_ACK			 0x06
#define DM_ACK_COMP		~0x06
#define DM_NACK			 0x15
#define DM_NACK_COMP	~0x15
#define DM_EOT			 0x04
#define DM_EOTCOMP		~0x04
#define DM_SYN			 0x16
#define DM_SYNCOMP		~0x16

/* Valores por defecto de la configuracion del prtocolo dmodem */
/* max_data_size  */
#define DMODEM_MAX_DATA_SIZE_DEF		512
/* txframe_to  */
#define DMODEM_TXFRAME_TO_DEF			10000 /* (msegs) */
/* rxbyte_to  */
#define DMODEM_RXBYTE_TO_DEF			1000
/* Cantidad de retransmisiones */
#define DMODEM_MAX_RETIRES_DEF			15
/* txuplayer_to  */
#define DMODEM_TXUPLAYER_TO_DEF			60000 /* (msegs) */
/* rxuplayer_to  */
#define DMODEM_RXUPLAYER_TO_DEF			60000 /* (msegs) */
/* startconn_to */
#define DMODEM_STARTCONN_TO_DEF			60000 /* (msegs) */


/*cantidad maxima de conexiones permitidas*/
#define MAX_CONN_ACCEPTED 32
	
/**
 * Estructura que contiene la configuracion del protocolo dmodem.
 * Campos:
 *    max_data_size: tamaño maximo de la parte de datos de las tramas, 
 *    txframe_to   : timeout de trama (expresado en msegs), 
 *    rxbyte_to    : timeout entre bytes (expresado en msegs),   
 *    max_retries  : maxima cantidad de reintentos permitidos por trama,  
 *    txuplayer_to : timeout de transmicion de datos de capa superior (expresado en msegs), 
 *    rxuplayer_to : timeout de recepcion de datos de capa superior (expresado en msegs), 
 *    startconn_to : timeout de conexion (expresado en msegs),  
 *    flags        : modo del dmodem (0 no bloqueante y 1 bloqueante). 
 */
typedef struct 
{
	size_t 	max_data_size;
	unsigned long	txframe_to;
	unsigned long	rxbyte_to;
	int				max_retries;
	
	unsigned long	txuplayer_to;
	unsigned long	rxuplayer_to;
	unsigned long	startconn_to;
	
	int		flags;
} DModemConfig;


/*
  En el modo O_DMODEM_SPRD_BLOCK si se hace un read() de n bytes, el driver
  espera a que lleguenlas suficientes  tramas hasta completar la lectura de los n bytes.
  Si se dispara el rxuplayer timeout entonces sale del read devolviendo los
  datos leidos hasta el momento.
  Si en cambio esta en modo O_DMODEM_SPRD_NONBLOCK entonces el read() de n bytes
  se queda esperando hasta que llegue la primer trama de bytes, el driver
  devuelve los datos de la trama sin esperar a que lleguen los n bytes (por supuesto
  devuelve solo hasta n bytes). Si la trama recibida tiene mas de n bytes
  solo se devuelven n y los demas recibidos enla trama se devolveran en elseproximo read() realizado.
*/
#define 	O_DMODEM_SPRD_BLOCK 		0
#define 	O_DMODEM_SPRD_NONBLOCK  	1

/* 
 * El primer argumento es un valor arbitrario utilizado por las funciones de callback
 * Cada invocacion a las funciones de callback debe pasar este valor como primer argumento.
 * El modulo recibe el argumento en la funcion open()
 */
typedef int (SendBufHandler)(void *uplayer_data, char *, int);

/**
 * Retorna
 *	0 si no hay bytes y rcv_type = 0 se especifico en 0
 *	1 si hay un byte recibido
 *	2 si se vencio el timeout y rcv_type = 1
 */
typedef int (ReceiveByte)(void *uplayer_data, int rcv_type, int *pdata);

/* 
 * Esta funcion se encargara de verificar el estado del DCD del puerto utilizado para poder cancelar la
 * comunicacion y no esperar al timer de uplayer. 
 */
typedef int (GetDCDStatus)(void *uplayer_data);

/**
*	Inicializa el buffer de conexiones permitidas y carga lo necesario para controlar dichas conexiones , debera ser invocada cuando arranca el programa que use la dll
*/
void initDmodemController();

/**
 * Realiza la apertura de un handle de dmodem  
 * @param flags indica si el modo de apertura del dmodem es bloqueante o no para las operaciones de read
 * @param uplayer_data datos de callback adicionales utilizados por la aplicacion
 * @param sndbuf funcion de callback que se encarga de enviar un buffer de datos por el canal (Se le debe pasar el buffer y la cantidad de datos a enviar. Devuelve 1 en caso de operacion exitosa y 0 en caso de error.)
 * @param rcvbyte funcion de callback que se encarga de recibir un byte por el canal. (En el puntero a entero se deposita el byte recibido, si llego alguno. Devuelve 1 si es que llego algun byte un byte y cero en caso contrario.)
 * @param getDCDStatus funcion de callback que verifica el estado del data carrier detect
 * @return handle que se le asigna al nuevo dmodem o -1 si no hay conexion disponible
 */
int dmodem_open( int flags, void *uplayer_data, SendBufHandler *sndbuf, ReceiveByte *rcvbyte,GetDCDStatus *getDCDStatus );
 
 /**
  * Cierre un handle de dmodem abierto
  * @param handle handle del dmodem que se necesita cerrar
  * @return si la operacion fue exitosa o no    
  */
int dmodem_close( const int handle );
 

 /**
  * Efectua el proceso de conexcion con un servidor dmodem (cliente enviar SYN; servidor enviar NAK; comienzo de la comunicacion)
  * @param handle handle del dmodem a conectar
  * @return si la operacion fue exitosa o no      
  */
int dmodem_connect( const int handle );

 /**
  *  Envia el nak inicial de la conexion, luego de llamar a esta funcion se debe poner a la espera del paquete pic. (Esta funcion solo debe ser utilizada por el servidor dmodem y no por el cliente) 
  * @param handle handle del dmodem a conectar
  * @return si la operacion fue exitosa o no      
  */
int dmodem_accept( const int handle );

 /**
  * Realiza la desconecion de un cliente (esta funcion solo debera ser utilizada por el servidor, este debera enviar un EOT y esperar un ACK)
  * @param handle handle del dmodem a conectar
  * @return si la operacion fue exitosa o no      
  */
int dmodem_disconnect( const int handle );

 /**
  * Envia un buffer de datos al servidor, esta funcion se encarga de particionar el buffer a enviar en las tramas que sean necesarias segun los parametros del dmodem y de controlar la recepcion de dichas tramas.
  * @param handle handle del dmodem que necesita enviar datos
  * @param buf buffer de datos a enviar
  * @param size cantidad de datos a enviar
  * #return si pudo a no enviar datos al otro extremo        
  */
int dmodem_write(const int handle, const char *buf, size_t size );
 
 /**
  * Intenta recibir del otro extremo una cantidad de datos especificada. Si no pude retorna la cantidad que pudo. Esta funcion varia su funcionamiento dependiento de si el dmodem esta en modo bloqueante o no. En modo bloqueante, esta funcion intentara leer la cantidad de datos especificados y devolvera el control a la aplicacion una vez concluido. En modo no bloqueante una vez que se recibe una trama  esta funcion retorna la cantidad leida y pasa en control a la aplicion para que ella realize el control de los datos recibidos.
  * @param handle  handle del dmodem que desea recibir datos
  * @param buf buffer donde se deben almacenar los datos recibidos
  * @param size cantidad de datos a recibir  
  * @return la cantidad de datos recibidor
  */
int dmodem_read( const int handle,char *buf, size_t size );
 
 /**
  * Configura, a partir de una estructura pasada por parametros, los parametros del dmodem 
  * @param handle handle del dmodem a configurar
  * @param conf referencia a la estructura que contiene los datos de configuracion    
  * @return si pudo o no configurar el dmodem  
  */
int dmodem_conf(const int handle, DModemConfig *conf );

 /**
  * esta funcion configura, el dmodem
  */
int dmodem_confDLL(const int handle,size_t max_data_size,unsigned long	txframe_to,unsigned long rxbyte_to ,int max_retries,unsigned long	txuplayer_to,unsigned long	rxuplayer_to,unsigned long	startconn_to);

 /**
  * Devuelve el codigo del ultimo error sucedido
  * @param handle handle del dmodem del cual se necesita conocer el error
  * @return condigo del error    
  */
int dmodem_geterror( const int handle );

 /**
  * Reinicializa las variables del dmodem. Se debe utilizar cuando se cambia de protocolo PIC a protocolo PTSD
  * @param handle handle del dmodem 
  * @return si la operacion pudo realizarce con exito     
  */
int dmodem_init( const int handle );

/**
* esta funcion permite setear el timeout de trasmicion de aplicacion
*/
void dmodem_setTxUpLayerTO(const int handle,unsigned long value);

/**
* esta funcion permite setear el timeout de recepcion de aplicacion
*/
void dmodem_setRxUpLayerTO(const int handle,unsigned long value);

/**
* Carga el buffer pasado por parametros con las estadisticas de la comunicacion, el formato devuelto es: txnaks,txacks,txframeTO,rxacks,rxnaks
* @param handle hamdle del dmodem 
* @param st referencia al buffer donde se depositaran las estadisticas de la ultima comunicacion
*/
void dmodem_getStatistics(const int handle, unsigned short *st);

/**
* Activa o desactiva el log de maquina de estados
* @param handle handle del dmodem
* @param value 0 desactiva el log y 1 activa el log
*/
void dmodem_setLogState(const int handle,int value);

/**
* Devuelve el estado del log de la maquina de estados
* @param handle handle del dmodem
* @return 0 log desactivado y 1 log activado
*/
int dmodem_getLogState(const int handle);

/**
* Devuelve el upldata del dmodem con ese handle
* @param handle handle del dmodem
* @return referencia al upldata
*/
void * dmodem_getUplData(const int handle);

/**
 * LM
 */ 
int dmodem_getError (int handle);
#endif
