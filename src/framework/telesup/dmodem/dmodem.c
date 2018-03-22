#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "system/util/endian.h"
#include "dmodem.h"
#include "ctimers.h"
#include "ptsm.h"
#include "osrt.h"
//#include "log.h"

#define printd(args...)	

/*
 * El modulo no es reentrante para las operaciones write y read al mismo tiempo
 *
 */

#define CLEAR_GLOBAL_ERROR(handle)			dmodemController[handle].dm_global_error = EDMODEM_NOERROR
#define SET_GLOBAL_ERROR(handle,err)	dmodemController[handle].dm_global_error = (err)
#define GET_GLOBAL_ERROR(handle)		dmodemController[handle].dm_global_error

typedef struct 
{ 	
  /*estadisticas de transmicion*/
  unsigned short txnaks;
  unsigned short txacks;
  unsigned short txframeTO;
  
  /*estadisticas de recepcion*/
  unsigned short rxacks;
  unsigned short rxnaks;
  
} Statistic;

/* El estado actual de la operacion read */
typedef struct 
{ 	
	char			*pframe; /* el puntero fijo al buffer de trama */
 	char 			*ppayload;/* el puntero a los bytes leidos , se va corriendo a medida que manda datos */
 	size_t			size_to_read; /* la cantidad de bytes a leer en la operacion */
	size_t			size_readed;/* el tamanio del payload leido en total */
	size_t			curr_bytes_readed;/* el tamanio del payload leido del frame actual */
	unsigned char	next_seqno; /* el numero de secuencia de la trama */
	unsigned char	curr_seqno; /* el numero de secuencia de la trama */
	unsigned char	byte_rcv; /* el ultimo byte recibido */
	unsigned short	curr_payload_len; /* el tamanio del payload recibido en el campo payload-len de la trama */
	unsigned short	curr_payload_len_comp; /* el mismo que unsigned curr_payload_len pero complementado */
	unsigned long	checksum; /* el valor del checksum recibido */
	char			*pchecksum; /* puntero al checksum */
	int 			retrans_no; /* la cantidad de retransmisiones del frame actual */
		
	char 			databuf[ DM_MAX_DATA_READ ]; /* Los bytes La trama actual recibida */
	int 			last_data_index;
	int				first_data_index;
	int 			data_count;
	int 			max_data_count;
		

	CTimer			rxuplayer_timer;
	unsigned char	rxuplayer_timer_expired;
 	
 } DMReadCurrState;
 
/* El estado actual de la operacion write*/
typedef struct 
{
 	char 			*pframe; 	/* el puntero a la trama */
 	char 			*pbufdata; 	/* el puntero a los datos a enviar, queda siempre apuntando al original que se pasa en write */
 	char 			*pdata; 	/* el puntero a los datos a enviar, se va corriendo a medida que manda datos */
	size_t			data_size;	/* la cantidad de datos que se quiere enviar */
	size_t			remain_size;/* la cantidad de datos que quedan por enviar */
	size_t			curr_frame_data_size; /** el tamanio de los datos del ultimo frame enviado */
 	unsigned char 	curr_seqno;		/* el numero de secuencia de la trama actual (dejarlo uchar)*/
 	int				retrans_no;	/* la cantidad de retransmisiones */

	CTimer			txuplayer_timer;
	unsigned char	txuplayer_timer_expired;
	
	CTimer			txframe_timer;
	unsigned char	txframe_timer_expired;
 	
 } DMWriteCurrState;

/* El estado actual de la operacion connect */
typedef struct 
{
	int 			retrans_no;
	CTimer			connuplayer_timer;
	unsigned char	connuplayer_timer_expired;
	
	CTimer			connframe_timer;
	unsigned char	connframe_timer_expired;
 	
 } DMConnectCurrState;
 
typedef struct 
{
	int 			retrans_no;
	CTimer			disconnuplayer_timer;
	unsigned char	disconnuplayer_timer_expired;
	
	CTimer			disconnframe_timer;
	unsigned char	disconnframe_timer_expired;
 	
 } DMDisconnectCurrState; 

/*estructura que contiene todos los datos necesarios para cada handle de dmodem*/
typedef struct {
	int handle;
	
	/* el error que ... */
	int dm_global_error;
	
	/* las funciones de callback */
	SendBufHandler 	*send_buf;
	ReceiveByte  	*rcv_byte;
	void 			*uplayer_data;
	GetDCDStatus 	*get_dcd_status;	
	
	/* La configuracion del protocolo */
	DModemConfig	dmconf;
	
	/* La trama actual a enviar */
	char dmodem_frame[ DM_MAX_FRAME_LEN ];
	
	/* el estado actual de la operacion write */
	DMWriteCurrState wr_curr_state;
	
	/* el estado actual de la operacion read */
	DMReadCurrState rd_curr_state;

	/* el estado actual de la operacion connect */
	DMConnectCurrState conn_curr_state;	
	
	DMDisconnectCurrState disconn_curr_state;
	
	/*timer de conexion*/
	CTimer conn_timer;    
	unsigned long acc_conn_timer_expired;
	
	/*estadisticas de la comunicacion*/
	Statistic statistics;

  /*log de maquina de estados activa*/
  int logActive;
  
}DmodemHandler;

/*buffer de conexiones*/
DmodemHandler dmodemController[MAX_CONN_ACCEPTED];

/*mutexs localizacion del handle*/
static Mutex_t dmodem_handle_mutex;

#define TAKE_MUTEX()			mutexLock( &dmodem_handle_mutex )
#define RELEASE_MUTEX()		mutexUnlock( &dmodem_handle_mutex )

/* el error que ... */
//static int dm_global_error;

/* las funciones de callback */
//static SendBufHandler 	*send_buf;
//static ReceiveByte  	*rcv_byte;
//static void 			*uplayer_data;
//static GetDCDStatus 	*get_dcd_status;


/* La configuracion del protocolo */
//static DModemConfig	dmconf;

/* La trama actual a enviar */
//static char dmodem_frame[ DM_MAX_FRAME_LEN ];


/* Los estados */
enum 
{	  
	  INVALID_ST = 0
	 ,EXIT_ST = 1	 
	 
	/* Write states */
	,START_WRST
	,FRAMESENDED_WRST	
	,CTRLMOREFRAMES_WRST
	,CTRLRETRANS_WRST
	,ACKRCV_WRST
	,NACKRCV_WRST
	
	/* Read states */
	,WAITSOH_RDST
	,WAITCTRL0_RDST
	,WAITCTRL1_RDST
	,WAITSEQ_RDST
	,WAITSEQCOMP_RDST
	,WAITLEN0_RDST
	,WAITLEN1_RDST
	,WAITLEN0COMP_RDST
	,WAITLEN1COMP_RDST
	,WAITPAYLOAD_RDST
	,WAITCHECKSUM_RDST
	,CTRLRETRANS_RDST
	,DISCARDBYTES_RDST
	,DISCARDRETRANS_RDST
	,SYNRCV_RDST
	,SYNCOMPRCV_RDST
	,EOTRCV_RDST
	,EOTCOMPRCV_RDST
	
	/*connect states*/
	,START_CONNST
	,SYNSENDED_CONNST
	,CTRLRETRANS_CONNST
	,NACKRCV_CONNST
	
	/*disconnect states*/
	,START_DISCONNST
	,EOTSENDED_DISCONNST
	,CTRLRETRANS_DISCONNST
	,ACKRCV_DISCONNST
};

/* Los eventos */
enum
{
	  NO_EVT
	 ,START_EVT
	 	 
	 /* Write events */	
	,SENDFRAME_WREVT

	,ACK_WREVT
	,ACKCOMP_WREVT	
	,NACK_WREVT
 	,NACKCOMP_WREVT 	
	,UNBYTE_WREVT	
	
	,TXFRAMETO_WREVT
	,TXUPLAYERTO_WREVT
	
	,MOREFRAMES_WREVT
	,NOMOREFRAMES_WREVT
	,MORERETRANS_WREVT
	,NOMORERETRANS_WREVT
	,FRAMESENDEDERR_WREVT

						
	/* Read events */
	,RCVSOH_RDEVT
	,NOTSOH_RDEVT	
	,RCVCTRL0_RDEVT
	,RCVCTRL1_RDEVT
	,RCVSEQ_RDEVT
	,RCVSEQCOMP_RDEVT
	,RCVLEN0_RDEVT
	,RCVLEN1_RDEVT
	,RCVLEN0COMP_RDEVT
	,RCVLEN1COMP_RDEVT
	,RCVBYTE_RDEVT
	,PAYLOADRCV_RDEVT
	,NOMOREFRAMES_RDEVT
	,MOREFRAMES_RDEVT			
	,MORERETRANS_RDEVT
	,NOMORERETRANS_RDEVT
	,BADFRAME_RDEVT
	,RETRANS_RDEVT
	
	,RXBYTETO_RDEVT	
	,RXUPLAYERTO_RDEVT	
	,SYN_RDEVT		
	
	/*connect events*/
	,SENDSYN_CONNEVT
	,UNBYTE_CONNEVT
	,TXFRAMETO_CONNEVT
	,TXUPLAYERTO_CONNEVT
	,NACK_CONNEVT
	,SYN_SENDEDERR_CONNEVT
	,MORERETRANS_CONNEVT
	,NOMORERETRANS_CONNEVT
	,NACKCOMP_CONNEVT
	,EOT_RDEVT
	
	/*disconnect events*/
	,SENDEOT_DISCONNEVT
	,UNBYTE_DISCONNEVT
	,TXFRAMETO_DISCONNEVT
	,TXUPLAYERTO_DISCONNEVT
	,ACK_DISCONNEVT
	,EOT_SENDEDERR_DISCONNEVT
	,MORERETRANS_DISCONNEVT
	,NOMORERETRANS_DISCONNEVT
	,ACKCOMP_DISCONNEVT

};

/***
 * Funciones de armado de tramas 
 */

/**/
static
int 
send_nack(int handle)
{
	char nackb[2];
	
	nackb[0] = DM_NACK;
	nackb[1] = ~DM_NACK;
	return dmodemController[handle].send_buf(dmodemController[handle].uplayer_data, &nackb[0], sizeof(nackb));
}

/**/
static
int
send_ack(int handle)
{
	char ackb[2];

	/* envia el ack */
	ackb[0] = DM_ACK;
	ackb[1] = ~DM_ACK;
	return dmodemController[handle].send_buf(dmodemController[handle].uplayer_data, &ackb[0], sizeof(ackb));	
}	


/**
*  tabla CRC32
*/
unsigned int crc32_tab[256] =
{
	0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA,
	0x076DC419, 0x706AF48F, 0xE963A535, 0x9E6495A3,
	0x0EDB8832, 0x79DCB8A4, 0xE0D5E91E, 0x97D2D988,
	0x09B64C2B, 0x7EB17CBD, 0xE7B82D07, 0x90BF1D91,
	0x1DB71064, 0x6AB020F2, 0xF3B97148, 0x84BE41DE,
	0x1ADAD47D, 0x6DDDE4EB, 0xF4D4B551, 0x83D385C7,
	0x136C9856, 0x646BA8C0, 0xFD62F97A, 0x8A65C9EC,
	0x14015C4F, 0x63066CD9, 0xFA0F3D63, 0x8D080DF5,
	0x3B6E20C8, 0x4C69105E, 0xD56041E4, 0xA2677172,
	0x3C03E4D1, 0x4B04D447, 0xD20D85FD, 0xA50AB56B,
	0x35B5A8FA, 0x42B2986C, 0xDBBBC9D6, 0xACBCF940,
	0x32D86CE3, 0x45DF5C75, 0xDCD60DCF, 0xABD13D59,
	0x26D930AC, 0x51DE003A, 0xC8D75180, 0xBFD06116,
	0x21B4F4B5, 0x56B3C423, 0xCFBA9599, 0xB8BDA50F,
	0x2802B89E, 0x5F058808, 0xC60CD9B2, 0xB10BE924,
	0x2F6F7C87, 0x58684C11, 0xC1611DAB, 0xB6662D3D,

	0x76DC4190, 0x01DB7106, 0x98D220BC, 0xEFD5102A,
	0x71B18589, 0x06B6B51F, 0x9FBFE4A5, 0xE8B8D433,
	0x7807C9A2, 0x0F00F934, 0x9609A88E, 0xE10E9818,
	0x7F6A0DBB, 0x086D3D2D, 0x91646C97, 0xE6635C01,
	0x6B6B51F4, 0x1C6C6162, 0x856530D8, 0xF262004E,
	0x6C0695ED, 0x1B01A57B, 0x8208F4C1, 0xF50FC457,
	0x65B0D9C6, 0x12B7E950, 0x8BBEB8EA, 0xFCB9887C,
	0x62DD1DDF, 0x15DA2D49, 0x8CD37CF3, 0xFBD44C65,
	0x4DB26158, 0x3AB551CE, 0xA3BC0074, 0xD4BB30E2,
	0x4ADFA541, 0x3DD895D7, 0xA4D1C46D, 0xD3D6F4FB,
	0x4369E96A, 0x346ED9FC, 0xAD678846, 0xDA60B8D0,
	0x44042D73, 0x33031DE5, 0xAA0A4C5F, 0xDD0D7CC9,
	0x5005713C, 0x270241AA, 0xBE0B1010, 0xC90C2086,
	0x5768B525, 0x206F85B3, 0xB966D409, 0xCE61E49F,
	0x5EDEF90E, 0x29D9C998, 0xB0D09822, 0xC7D7A8B4,
	0x59B33D17, 0x2EB40D81, 0xB7BD5C3B, 0xC0BA6CAD,

	0xEDB88320, 0x9ABFB3B6, 0x03B6E20C, 0x74B1D29A,
	0xEAD54739, 0x9DD277AF, 0x04DB2615, 0x73DC1683,
	0xE3630B12, 0x94643B84, 0x0D6D6A3E, 0x7A6A5AA8,
	0xE40ECF0B, 0x9309FF9D, 0x0A00AE27, 0x7D079EB1,
	0xF00F9344, 0x8708A3D2, 0x1E01F268, 0x6906C2FE,
	0xF762575D, 0x806567CB, 0x196C3671, 0x6E6B06E7,
	0xFED41B76, 0x89D32BE0, 0x10DA7A5A, 0x67DD4ACC,
	0xF9B9DF6F, 0x8EBEEFF9, 0x17B7BE43, 0x60B08ED5,
	0xD6D6A3E8, 0xA1D1937E, 0x38D8C2C4, 0x4FDFF252,
	0xD1BB67F1, 0xA6BC5767, 0x3FB506DD, 0x48B2364B,
	0xD80D2BDA, 0xAF0A1B4C, 0x36034AF6, 0x41047A60,
	0xDF60EFC3, 0xA867DF55, 0x316E8EEF, 0x4669BE79,
	0xCB61B38C, 0xBC66831A, 0x256FD2A0, 0x5268E236,
	0xCC0C7795, 0xBB0B4703, 0x220216B9, 0x5505262F,
	0xC5BA3BBE, 0xB2BD0B28, 0x2BB45A92, 0x5CB36A04,
	0xC2D7FFA7, 0xB5D0CF31, 0x2CD99E8B, 0x5BDEAE1D,

	0x9B64C2B0, 0xEC63F226, 0x756AA39C, 0x026D930A,
	0x9C0906A9, 0xEB0E363F, 0x72076785, 0x05005713,
	0x95BF4A82, 0xE2B87A14, 0x7BB12BAE, 0x0CB61B38,
	0x92D28E9B, 0xE5D5BE0D, 0x7CDCEFB7, 0x0BDBDF21,
	0x86D3D2D4, 0xF1D4E242, 0x68DDB3F8, 0x1FDA836E,
	0x81BE16CD, 0xF6B9265B, 0x6FB077E1, 0x18B74777,
	0x88085AE6, 0xFF0F6A70, 0x66063BCA, 0x11010B5C,
	0x8F659EFF, 0xF862AE69, 0x616BFFD3, 0x166CCF45,
	0xA00AE278, 0xD70DD2EE, 0x4E048354, 0x3903B3C2,
	0xA7672661, 0xD06016F7, 0x4969474D, 0x3E6E77DB,
	0xAED16A4A, 0xD9D65ADC, 0x40DF0B66, 0x37D83BF0,
	0xA9BCAE53, 0xDEBB9EC5, 0x47B2CF7F, 0x30B5FFE9,
	0xBDBDF21C, 0xCABAC28A, 0x53B39330, 0x24B4A3A6,
	0xBAD03605, 0xCDD70693, 0x54DE5729, 0x23D967BF,
	0xB3667A2E, 0xC4614AB8, 0x5D681B02, 0x2A6F2B94,
	0xB40BBE37, 0xC30C8EA1, 0x5A05DF1B, 0x2D02EF8D,
};

/**
 * Calcular el CRC32 del buffer pasado como parámetro
 * 
 * @param buffer buffer con datos para calcular CRC32
 * @param bufsize tamaño del buffer
 * 
 * @retval int CRC32 del buffer
 * 
 */	
 static
unsigned long get_dmchecksum(char *payload, size_t size)
{
    unsigned int crc = 0xFFFFFFFF;
    //unsigned char* buf = buffer;
	unsigned char* buf = payload;
	unsigned short i;

    for (i = 0;  i < size;  i ++)
        crc = crc32_tab[ (crc & 0xFF) ^ buf[i] ] ^ (crc >> 8);
    
    return ( crc ^ 0xFFFFFFFF ) ;
} 

/*Lucas 23-11-2005, cambio por CRC32*/
/***
 * Devuelve el checksum sumando byte a byte 
 */
/*static
unsigned long get_dmchecksum(char *payload, size_t size)
{
	unsigned long cs = 0;
	
	while (size--)
		cs += (unsigned char)*payload++;
		
	return cs;	
};*/

 

/**/ 
static
int make_dmframe(char *frame, int ctrl1, int ctrl2, unsigned char seqno, char *payload, size_t size)
{
	char *f = frame;
	unsigned long l;
	size_t size2;
//	FILE *fo;
//	unsigned char st[30];
	
	/* Todos los binarios van en little endian */
	assert(size <= DM_MAX_DATA_LEN);
	
	/* soh */
	*f++ = DM_SOH;
		
	/* los bytes de control */
	*f++ = ctrl1; *f++ = ctrl2;
	
	/* el numero de secuencia y su complemento */
	*f++ = seqno;	
	*f++ = ~seqno;
		
	/* el tamano del payload (Todo little endian) */
	*f++ = size & 0xFF; /* primero la parte baja */
	//*f++ = size << 8; /* luego la parte alta */	
	*f++ = (size >> 8) & 0xFF; /* luego la parte alta */	
	printd("Tamanio Trama %d nro secuencia %d\n",size,seqno);	
	
	/* el tamanio del payload complementado */
	size2= ~(unsigned short)size;
	//*f++ = (~(unsigned short)size) & 0xFF; /* primero la parte baja */
	//*f++ = (~(unsigned short)size) << 8; /* luego la parte alta */
	*f++ = (unsigned short)size2 & 0xFF; /* primero la parte baja */
	*f++ = ((unsigned short)size2 >> 8) & 0xFF; /* luego la parte alta */
	
	/* el payload */
	memcpy(f, payload, size);
	f += size;
	
	/* el checksum */
	l = get_dmchecksum(payload, size);	
	
	/* bytes: 32 10 -> 01 23*/
	*f++ = l       & 0x000000FF;	/* 1. byte 0 */
	*f++ = l >>  8 & 0x000000FF;	/* 2. byte 1 */
	*f++ = l >> 16 & 0x000000FF;	/* 3. byte 2 */
	*f++ = l >> 24; 				/* 4. byte 3 */
	
	/*gRABA LOS FRAMES ENVIADOR*//*
	sprintf(st,"frame%d.bin",seqno);
	fo= fopen(st,"wb");
	fwrite(frame,f - frame,1,fo);
	fclose(fo);*/
	
	return f - frame;
}

/************************
 * Operacion WRITE
 ***********************/



/* el estado actual de la operacion write */
//static DMWriteCurrState wr_curr_state;


/* Las funciones */
static int wr_none( int handle);
static int wr_send_frame( int handle );
static int wr_prepare_next_frame( int handle );
static int wr_prepare_retrans( int handle );

static int wr_exit_ok( int handle );
static int wr_exit_txuplayerto( int handle );
static int wr_exit_retrans( int handle );
static int wr_exit_frame_error( int handle );


static ProtoTransition wr_transitions[] =
{		
	  /* estado actual */	/* evento */		/*  sig. estado */	/* function handler */
	 { START_WRST, 			SENDFRAME_WREVT,	FRAMESENDED_WRST,	wr_send_frame } 
	
	,{ FRAMESENDED_WRST, 	ACK_WREVT,	 		ACKRCV_WRST,		wr_none} 	
	,{ FRAMESENDED_WRST, 	TXFRAMETO_WREVT,	CTRLRETRANS_WRST, 	wr_prepare_retrans } 
	,{ FRAMESENDED_WRST, 	TXUPLAYERTO_WREVT,	EXIT_ST, 			wr_exit_txuplayerto } 
	,{ FRAMESENDED_WRST, 	NACK_WREVT,			NACKRCV_WRST, 		wr_none } 
	,{ FRAMESENDED_WRST, 	UNBYTE_WREVT,		FRAMESENDED_WRST, 	wr_none } 
	,{ FRAMESENDED_WRST, 	FRAMESENDEDERR_WREVT,EXIT_ST, 			wr_exit_frame_error } 	
	
	,{ CTRLMOREFRAMES_WRST, MOREFRAMES_WREVT, 	FRAMESENDED_WRST, 	wr_send_frame } 
	,{ CTRLMOREFRAMES_WRST, NOMOREFRAMES_WREVT, EXIT_ST, 			wr_exit_ok } 
	,{ CTRLMOREFRAMES_WRST, TXUPLAYERTO_WREVT,	EXIT_ST, 			wr_exit_txuplayerto } 	
		
	
	,{ ACKRCV_WRST, 		ACKCOMP_WREVT,		CTRLMOREFRAMES_WRST, wr_prepare_next_frame  } 
	,{ ACKRCV_WRST, 		UNBYTE_WREVT,		CTRLRETRANS_WRST, 	 wr_prepare_retrans } 	
	,{ ACKRCV_WRST, 		TXFRAMETO_WREVT,	CTRLRETRANS_WRST, 	 wr_prepare_retrans } 	
	,{ ACKRCV_WRST, 		TXUPLAYERTO_WREVT,	EXIT_ST, 			 wr_exit_txuplayerto } 
	
	,{ NACKRCV_WRST, 		NACKCOMP_WREVT,		CTRLRETRANS_WRST, 	wr_prepare_retrans } 
	,{ NACKRCV_WRST, 		UNBYTE_WREVT,		FRAMESENDED_WRST, 	wr_none } 	
	,{ NACKRCV_WRST, 		TXFRAMETO_WREVT,	CTRLRETRANS_WRST, 	wr_prepare_retrans } 
	,{ NACKRCV_WRST, 		TXUPLAYERTO_WREVT,	EXIT_ST, 			wr_exit_txuplayerto } 
	
	,{ CTRLRETRANS_WRST,	MORERETRANS_WREVT, 	FRAMESENDED_WRST, 	wr_send_frame }
	,{ CTRLRETRANS_WRST,	NOMORERETRANS_WREVT,EXIT_ST, 			wr_exit_retrans }	
	,{ CTRLRETRANS_WRST,	TXUPLAYERTO_WREVT,	EXIT_ST, 			wr_exit_txuplayerto } 
};


/**/
static TIMEOUT_CTIMER_HANDLER(txuplayer_timer_handler)
{
	printd("%s\n", __FUNCTION__);
	//logStr("Vencio CTimer txUpLayer %d \n",(unsigned int)GET_TIMEOUT_CTIMER_PARAM());
	
	dmodemController[(unsigned int)GET_TIMEOUT_CTIMER_PARAM()].wr_curr_state.txuplayer_timer_expired = 1;
};

/**/
static TIMEOUT_CTIMER_HANDLER(txframe_timer_handler)
{
	printd("%s\n", __FUNCTION__);	
	//logStr("Vencio CTimer txFrame %d \n",(unsigned int)GET_TIMEOUT_CTIMER_PARAM());
	dmodemController[(unsigned int)GET_TIMEOUT_CTIMER_PARAM()].wr_curr_state.txframe_timer_expired = 1;
};
 	
/**/
static int wr_wait_event( int handle )
{
	int b;
			
	assert(dmodemController[handle].rcv_byte);
	/* Si recibe un byte ... 
	   Como el segundo argumento es cero entonces entra a ver si recibe un byte
	   y si no lo recibe sale con valor 0.
	   Devuelve 1 si hay un byte recibido.
	 */		

	if (dmodemController[handle].rcv_byte(dmodemController[handle].uplayer_data, 0, &b) == 1) {
		
		switch ((unsigned char)b) {
			case (unsigned char)DM_ACK:
					return ACK_WREVT;
			case (unsigned char)DM_ACK_COMP:{
			     ++dmodemController[handle].statistics.txacks;
					return ACKCOMP_WREVT;
				}
			case (unsigned char)DM_NACK:
					return NACK_WREVT;
			case (unsigned char)DM_NACK_COMP:{
			    ++dmodemController[handle].statistics.txnaks;
					return NACKCOMP_WREVT;
				}
			default:				
			     printd("Valor desconocido: %d\n",(unsigned char)b);
					return UNBYTE_WREVT;
		}
	}
	
	/*si se perdio la portadora, por ahora devuelvo TXUPLAYERTO_WREVT pero despues se debe cambiar a un evento nuevo*/
 	if (!dmodemController[handle].get_dcd_status(dmodemController[handle].uplayer_data))
 		return TXUPLAYERTO_WREVT;
		
	/* Si se dispara el timer xuplayer_timer_expired ...*/
	if (dmodemController[handle].wr_curr_state.txuplayer_timer_expired) {
		dmodemController[handle].wr_curr_state.txuplayer_timer_expired = 0;
		printd("Vencio Timeout WR Uplayer\n");
		return TXUPLAYERTO_WREVT;
	}
	
	/* Si se dispara el timer txframe_timer_expired ...*/
	if (dmodemController[handle].wr_curr_state.txframe_timer_expired) {
		dmodemController[handle].wr_curr_state.txframe_timer_expired = 0;
		//logStr("Vencio Timeout WR FrameTO\n");
		return TXFRAMETO_WREVT;
	}
		
	return NO_EVT;
};

/**/
static void wr_clean_curr_state( int handle )
{
	printd("%s\n", __FUNCTION__);
	
	/* detiene los timers */
	del_ctimer(&dmodemController[handle].wr_curr_state.txuplayer_timer);
	del_ctimer(&dmodemController[handle].wr_curr_state.txframe_timer);
};

/**/
static int wr_init( int handle )
{	
 	printd("%s\n", __FUNCTION__);
 	
 	dmodemController[handle].wr_curr_state.pframe = (char *)dmodemController[handle].dmodem_frame;
 	dmodemController[handle].wr_curr_state.remain_size = dmodemController[handle].wr_curr_state.data_size;
 	dmodemController[handle].wr_curr_state.retrans_no = 0;
	dmodemController[handle].wr_curr_state.txuplayer_timer_expired = 0;
	dmodemController[handle].wr_curr_state.txframe_timer_expired = 0; 	
	
	/* configura el timer de envio de tramas */
	dmodemController[handle].wr_curr_state.txframe_timer.expires = dmodemController[handle].dmconf.txframe_to;

	/* hay que disparar el timer txuplayer_timer */
	dmodemController[handle].wr_curr_state.txuplayer_timer.period = dmodemController[handle].dmconf.txuplayer_to * 10;
	dmodemController[handle].wr_curr_state.txuplayer_timer.expires = getTicks() + (dmodemController[handle].dmconf.txuplayer_to * 10);
	//dmodemController[handle].wr_curr_state.txuplayer_timer.expires = dmodemController[handle].dmconf.txuplayer_to * 10;

/*	myTimer.function = timeoutCtTimer; 
	myTimer.expires = getTicks() + myOriginalPeriod;
	myTimer.period  = myOriginalPeriod;
	myTimer.periodic = (myCycle == PERIODIC);
	*/
	printd ("Seteo el timer de WR en %d\n",dmodemController[handle].dmconf.txuplayer_to);
	add_ctimer(&dmodemController[handle].wr_curr_state.txuplayer_timer);
	
	/* envia el primer frame*/
	return wr_send_frame(handle) == NO_EVT;	
};


  
/**/
int wr_none( int handle )
{
	printd("%s\n", __FUNCTION__);
	return NO_EVT;
};

/**/
int wr_send_frame( int handle )
{
	size_t frame_size;
	
	printd("%s\n", __FUNCTION__);
	
	/* se dispara el timer wr_curr_state.txframe_timer */
	dmodemController[handle].wr_curr_state.txframe_timer.expires = dmodemController[handle].dmconf.txframe_to;
	add_ctimer(&dmodemController[handle].wr_curr_state.txframe_timer);
	
	/* particiona en tramas los datos a mandar si exceden el tamaniomaxino de payload */
	if (dmodemController[handle].wr_curr_state.remain_size <= dmodemController[handle].dmconf.max_data_size)
		dmodemController[handle].wr_curr_state.curr_frame_data_size = dmodemController[handle].wr_curr_state.remain_size;
	else
		dmodemController[handle].wr_curr_state.curr_frame_data_size = dmodemController[handle].dmconf.max_data_size;
	
	/* arma la trama */
	frame_size = make_dmframe(dmodemController[handle].wr_curr_state.pframe, DM_CTRL_BYTE_0, DM_CTRL_BYTE_1, 
						dmodemController[handle].wr_curr_state.curr_seqno, 
						dmodemController[handle].wr_curr_state.pdata, 
						dmodemController[handle].wr_curr_state.curr_frame_data_size);
	
	/* envia la trama */
	if (!dmodemController[handle].send_buf(dmodemController[handle].uplayer_data, dmodemController[handle].wr_curr_state.pframe, frame_size)) {
		SET_GLOBAL_ERROR(handle,EDMODEM_FATAL);
		return FRAMESENDEDERR_WREVT;
	}
	
	return NO_EVT;
};

/**/
int wr_prepare_next_frame( int handle )
{
	printd("%s\n", __FUNCTION__);
	
	/* detiene el timer wr_curr_state.txframe_timer */
	del_ctimer(&dmodemController[handle].wr_curr_state.txframe_timer);

	/* Corre el puntero a los datos para que en el proximo frame se envien los que siguen 
	   y actualiza la cantidad de bytes que quedar por mandar */	
	dmodemController[handle].wr_curr_state.pdata += dmodemController[handle].wr_curr_state.curr_frame_data_size;
	
	dmodemController[handle].wr_curr_state.remain_size -= dmodemController[handle].wr_curr_state.curr_frame_data_size;
	//logStr("Frame Data: %d Remain Data: %d\n",wr_curr_state.curr_frame_data_size,wr_curr_state.remain_size);
			
	/* Circula el numero de secuencia */
	dmodemController[handle].wr_curr_state.curr_seqno++;
	//if (wr_curr_state.curr_seqno == 0) wr_curr_state.curr_seqno = 1;

	/* Si hay mas datos para mandar pasa a un estado directamente y si no hay mas
	pasa al estado de salida por exito directamente */	
	if (dmodemController[handle].wr_curr_state.remain_size)
		return MOREFRAMES_WREVT;
	else
		return NOMOREFRAMES_WREVT;
};

/**/
int wr_prepare_retrans( int handle )
{
	printd("%s\n", __FUNCTION__);
	
	/* detiene el timer wr_curr_state.txframe_timer */
	del_ctimer(&dmodemController[handle].wr_curr_state.txframe_timer);
  //logStr("Vencio CTimer Frame\n");	
  ++dmodemController[handle].statistics.txframeTO;
  
	/* incrementa las retransmisiones */
	if (++dmodemController[handle].wr_curr_state.retrans_no < dmodemController[handle].dmconf.max_retries)
		return MORERETRANS_WREVT;
	else
		return NOMORERETRANS_WREVT;
};

/**/
int wr_exit_ok( int handle )
{
	printd("%s\n", __FUNCTION__);
	
	/* detiene el timer wr_curr_state.txuplayer_timer */
	del_ctimer(&dmodemController[handle].wr_curr_state.txuplayer_timer);

	SET_GLOBAL_ERROR(handle,EDMODEM_NOERROR);
	return NO_EVT;
};

/**/
int wr_exit_txuplayerto( int handle )
{
	printd("%s\n", __FUNCTION__);
	
	/* detiene el timer wr_curr_state.txuplayer_timer */
	del_ctimer(&dmodemController[handle].wr_curr_state.txuplayer_timer);

	SET_GLOBAL_ERROR(handle,EDMODEM_TXUPLAYER_TO);
	return NO_EVT;		
};

/**/
int wr_exit_retrans( int handle )
{
	printd("%s\n", __FUNCTION__);
	/* detiene el timer wr_curr_state.txuplayer_timer */
	del_ctimer(&dmodemController[handle].wr_curr_state.txuplayer_timer);

	SET_GLOBAL_ERROR(handle,EDMODEM_MAXRETRIES);	
	return NO_EVT;		
};

/**/
int wr_exit_frame_error( int handle )
{
	printd("%s\n", __FUNCTION__);

	/* detiene el timer wr_curr_state.txuplayer_timer */
	del_ctimer(&dmodemController[handle].wr_curr_state.txuplayer_timer);
	
	SET_GLOBAL_ERROR(handle,EDMODEM_FATAL);
	return NO_EVT;		
};


/**************************
 * La operacion READ
 **************************/

/* el estado actual de la operacion write */
//static DMReadCurrState rd_curr_state;
 	
/* Las funciones */
static int rd_none( int handle );
static int rd_soh( int handle );
static int rd_seqno( int handle );
static int rd_seqnocomp( int handle );
static int rd_len0( int handle );
static int rd_len1( int handle );
static int rd_len0comp( int handle );
static int rd_len1comp( int handle );
static int rd_rcv_byte( int handle );
static int rd_rcv_checksum_byte( int handle );
static int rd_prepare_retrans( int handle );
static int rd_discard_byte( int handle );
static int rd_discard_retrans( int handle );
static int rd_send_nack( int handle );
static int rd_send_ack( int handle );
static int rd_more_frames( int handle );

static int rd_exit_rxuplayerto( int handle );
static int rd_exit_ok( int handle );
static int rd_exit_retrans( int handle );

static int rd_syn_comp_rcv( int handle );

static int rd_send_eof_ack( int handle );
static int rd_eot_comp_rcv( int handle );

static ProtoTransition rd_transitions[] =
{		
	  /* estado actual */	/* evento */		/*  sig. estado */	/* function handler */
	  { WAITSOH_RDST, 		RCVBYTE_RDEVT, 		WAITCTRL0_RDST, 	rd_soh } 	 
	 ,{ WAITSOH_RDST, 		BADFRAME_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans }
	 ,{ WAITSOH_RDST, 		RXBYTETO_RDEVT, 	WAITSOH_RDST, 		rd_none }
	 ,{ WAITSOH_RDST, 		RXUPLAYERTO_RDEVT, 	EXIT_ST, 			rd_exit_rxuplayerto }
	 	 	 
	 ,{ WAITCTRL0_RDST, 	RCVBYTE_RDEVT, 		WAITCTRL1_RDST, 	rd_none } 	 
	 ,{ WAITCTRL0_RDST, 	NOTSOH_RDEVT, 		WAITSOH_RDST, 		rd_none } 
	 ,{ WAITCTRL0_RDST, 	SYN_RDEVT, 			SYNRCV_RDST, 		rd_none } /*Agregado para mantener conexion*/
	 ,{ WAITCTRL0_RDST, 	EOT_RDEVT, 			EOTRCV_RDST, 		rd_none } /*Agregado para tratar el EOT*/
	 ,{ WAITCTRL0_RDST, 	BADFRAME_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 	 
	 ,{ WAITCTRL0_RDST, 	RXBYTETO_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 
	 ,{ WAITCTRL0_RDST, 	RXUPLAYERTO_RDEVT, 	EXIT_ST, 			rd_exit_rxuplayerto } 
	 	 
	 ,{ WAITCTRL1_RDST, 	RCVBYTE_RDEVT, 		WAITSEQ_RDST, 		rd_none } 	 
	 ,{ WAITCTRL1_RDST, 	BADFRAME_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 
	 ,{ WAITCTRL1_RDST, 	RXBYTETO_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 
	 ,{ WAITCTRL1_RDST, 	RXUPLAYERTO_RDEVT, 	EXIT_ST, 			rd_exit_rxuplayerto } 
	 	 
	 ,{ WAITSEQ_RDST, 		RCVBYTE_RDEVT, 		WAITSEQCOMP_RDST, 	rd_seqno } 	 
	 ,{ WAITSEQ_RDST, 		BADFRAME_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 
	 ,{ WAITSEQ_RDST, 		RXBYTETO_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 
	 ,{ WAITSEQ_RDST, 		RXUPLAYERTO_RDEVT, 	EXIT_ST, 			rd_exit_rxuplayerto } 
	 	 
	 ,{ WAITSEQCOMP_RDST, 	RCVBYTE_RDEVT, 		WAITLEN0_RDST, 		rd_seqnocomp } 	 
	 ,{ WAITSEQCOMP_RDST, 	BADFRAME_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 
	 ,{ WAITSEQCOMP_RDST, 	RETRANS_RDEVT,		DISCARDRETRANS_RDST,rd_discard_retrans }
	 ,{ WAITSEQCOMP_RDST, 	RXBYTETO_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 
	 ,{ WAITSEQCOMP_RDST,	RXUPLAYERTO_RDEVT, 	EXIT_ST, 			rd_exit_rxuplayerto } 
	 	 
	 ,{ WAITLEN0_RDST, 		RCVBYTE_RDEVT, 		WAITLEN1_RDST, 		rd_len0 } 	 
	 ,{ WAITLEN0_RDST, 		BADFRAME_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 
	 ,{ WAITLEN0_RDST, 		RXBYTETO_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 
	 ,{ WAITLEN0_RDST,		RXUPLAYERTO_RDEVT, 	EXIT_ST, 			rd_exit_rxuplayerto } 
	 	 
	 ,{ WAITLEN1_RDST, 		RCVBYTE_RDEVT, 		WAITLEN0COMP_RDST, 	rd_len1 } 	 
	 ,{ WAITLEN1_RDST, 		BADFRAME_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 
	 ,{ WAITLEN1_RDST, 		RXBYTETO_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 
	 ,{ WAITLEN1_RDST,		RXUPLAYERTO_RDEVT, 	EXIT_ST, 			rd_exit_rxuplayerto } 
	 	 
	 ,{ WAITLEN0COMP_RDST, 	RCVBYTE_RDEVT, 		WAITLEN1COMP_RDST, 	rd_len0comp } 	 
	 ,{ WAITLEN0COMP_RDST, 	BADFRAME_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 
	 ,{ WAITLEN0COMP_RDST, 	RXBYTETO_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 
	 ,{ WAITLEN0COMP_RDST,	RXUPLAYERTO_RDEVT, 	EXIT_ST, 			rd_exit_rxuplayerto } 
	 	 
	 ,{ WAITLEN1COMP_RDST, 	RCVBYTE_RDEVT, 		WAITPAYLOAD_RDST, 	rd_len1comp } 	 
	 ,{ WAITLEN1COMP_RDST, 	BADFRAME_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 
	 ,{ WAITLEN1COMP_RDST, 	RXBYTETO_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 
	 ,{ WAITLEN1COMP_RDST,	RXUPLAYERTO_RDEVT, 	EXIT_ST, 			rd_exit_rxuplayerto } 
	 	 
	 ,{ WAITPAYLOAD_RDST, 	RCVBYTE_RDEVT, 		WAITPAYLOAD_RDST, 	rd_rcv_byte } 
	 ,{ WAITPAYLOAD_RDST, 	PAYLOADRCV_RDEVT, 	WAITCHECKSUM_RDST, 	rd_none } 	 
	 ,{ WAITPAYLOAD_RDST, 	BADFRAME_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 
	 ,{ WAITPAYLOAD_RDST, 	RXBYTETO_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 
	 ,{ WAITPAYLOAD_RDST,	RXUPLAYERTO_RDEVT, 	EXIT_ST, 			rd_exit_rxuplayerto } 
	 	 
	 ,{ WAITCHECKSUM_RDST,  RCVBYTE_RDEVT, 		WAITCHECKSUM_RDST,  rd_rcv_checksum_byte } 
	 ,{ WAITCHECKSUM_RDST,  MOREFRAMES_RDEVT, 	WAITSOH_RDST, 		rd_more_frames } 
	 ,{ WAITCHECKSUM_RDST,  NOMOREFRAMES_RDEVT, EXIT_ST, 			rd_exit_ok } 	 
	 ,{ WAITCHECKSUM_RDST,	BADFRAME_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 
	 ,{ WAITCHECKSUM_RDST,	RXBYTETO_RDEVT, 	CTRLRETRANS_RDST, 	rd_prepare_retrans } 
	 ,{ WAITCHECKSUM_RDST,	RXUPLAYERTO_RDEVT, 	EXIT_ST, 			rd_exit_rxuplayerto } 

	 ,{ CTRLRETRANS_RDST, 	NOMORERETRANS_RDEVT,EXIT_ST, 			rd_exit_retrans } 
	 ,{ CTRLRETRANS_RDST, 	MORERETRANS_RDEVT, 	DISCARDBYTES_RDST, 	rd_none } 
	 ,{ CTRLRETRANS_RDST, 	RXUPLAYERTO_RDEVT, 	EXIT_ST, 			rd_exit_rxuplayerto } 	 
	 	 
	 ,{ DISCARDRETRANS_RDST,RXBYTETO_RDEVT, 	WAITSOH_RDST, 		rd_send_ack } 
	 ,{ DISCARDRETRANS_RDST,RCVBYTE_RDEVT, 		DISCARDRETRANS_RDST,rd_discard_byte } 	 
	 ,{ DISCARDRETRANS_RDST,RXUPLAYERTO_RDEVT, 	EXIT_ST, 			rd_exit_rxuplayerto } 
	 
	 ,{ DISCARDBYTES_RDST, 	RCVBYTE_RDEVT, 		DISCARDBYTES_RDST, 	rd_discard_byte } 	 
	 ,{ DISCARDBYTES_RDST, 	RXBYTETO_RDEVT, 	WAITSOH_RDST, 		rd_send_nack } 
	 ,{ DISCARDBYTES_RDST, 	RXUPLAYERTO_RDEVT, 	EXIT_ST, 			rd_exit_rxuplayerto } 
	 
	 ,{ SYNRCV_RDST, 		RCVBYTE_RDEVT, 		SYNCOMPRCV_RDST,	rd_syn_comp_rcv	} 	 
	 ,{ SYNRCV_RDST, 		RXBYTETO_RDEVT, 	WAITSOH_RDST, 		rd_none } 
	 ,{ SYNRCV_RDST,		RXUPLAYERTO_RDEVT, 	EXIT_ST, 			rd_exit_rxuplayerto } 
	 
	 ,{ SYNCOMPRCV_RDST, 	RCVBYTE_RDEVT, 		WAITSOH_RDST, 		rd_none} 	 
	 ,{ SYNCOMPRCV_RDST, 	RXBYTETO_RDEVT, 	WAITSOH_RDST, 		rd_none } 
	 ,{ SYNCOMPRCV_RDST,	RXUPLAYERTO_RDEVT, 	EXIT_ST, 			rd_exit_rxuplayerto } 
	 
	 ,{ EOTRCV_RDST, 		RCVBYTE_RDEVT, 		EOTCOMPRCV_RDST,	rd_eot_comp_rcv	}
	 ,{ EOTRCV_RDST, 		RXBYTETO_RDEVT, 	WAITSOH_RDST, 		rd_none }
	 ,{ EOTRCV_RDST,		RXUPLAYERTO_RDEVT, 	EXIT_ST, 			rd_exit_rxuplayerto }
	 
	 ,{ EOTCOMPRCV_RDST, 	RCVBYTE_RDEVT, 		EXIT_ST, 			rd_send_eof_ack}
	 ,{ EOTCOMPRCV_RDST, 	RXBYTETO_RDEVT, 	WAITSOH_RDST, 		rd_none }
	 ,{ EOTCOMPRCV_RDST,	RXUPLAYERTO_RDEVT, 	EXIT_ST, 			rd_exit_rxuplayerto }
};

/**/
static size_t rd_read_data(int handle,char *buf, size_t size)
{
	char *b = buf;
		
	//logStr("@@@@@@@@@ Start rd_curr_state.first_data_index: %d\n",rd_curr_state.first_data_index);
	while (size--) {
		if (dmodemController[handle].rd_curr_state.data_count == 0 )
			break;
		*b++ = dmodemController[handle].rd_curr_state.databuf[dmodemController[handle].rd_curr_state.first_data_index];
		dmodemController[handle].rd_curr_state.data_count--;
		dmodemController[handle].rd_curr_state.first_data_index = ( dmodemController[handle].rd_curr_state.first_data_index + 1 ) % dmodemController[handle].rd_curr_state.max_data_count;
	}
	//logStr("@@@@@@@@@ End rd_curr_state.first_data_index: %d\n",rd_curr_state.first_data_index);
	return b - buf;
};


/**/
static size_t rd_write_data(int handle,char *buf, size_t size)
{
	char *b = buf;
	//logStr("@@@@@@@@@ Start rd_curr_state.last_data_index: %d\n",rd_curr_state.last_data_index);	
	while (size--) {
		if (dmodemController[handle].rd_curr_state.data_count == dmodemController[handle].rd_curr_state.max_data_count) 
			break;
		dmodemController[handle].rd_curr_state.databuf[dmodemController[handle].rd_curr_state.last_data_index] = *b++;
		dmodemController[handle].rd_curr_state.data_count++;		
   		dmodemController[handle].rd_curr_state.last_data_index = ( dmodemController[handle].rd_curr_state.last_data_index + 1 ) % dmodemController[handle].rd_curr_state.max_data_count;
	}
	//logStr("@@@@@@@@@ End rd_curr_state.last_data_index: %d\n",rd_curr_state.last_data_index);	
	return b - buf;
};		



/**/
static TIMEOUT_CTIMER_HANDLER(rxuplayer_timer_handler)
{
	printd("%s\n", __FUNCTION__);
	//logStr("Vencio CTimer rxUpLayer %d \n",(unsigned int)GET_TIMEOUT_CTIMER_PARAM());
	
	dmodemController[(unsigned int)GET_TIMEOUT_CTIMER_PARAM()].rd_curr_state.rxuplayer_timer_expired = 1;
};
 	
/**/
static int rd_wait_event( int handle )
{
	int b;
	int rslt=NO_EVT;
			
	assert(dmodemController[handle].rcv_byte);

	/* Recibe un byte recibido y como el segundo argumento es 1 se queda esperando
	   el byte y lo devuelve su lo recibe o , si pasa el tiempo de timeout entre bytes,
	   la funcion retorna 2.
	*/
	switch (dmodemController[handle].rcv_byte(dmodemController[handle].uplayer_data, 1, &b)) {	
		
		case 1: 
			dmodemController[handle].rd_curr_state.byte_rcv = b;
			printd("[%x]", b);
			return RCVBYTE_RDEVT;
			
		case 2:
			rslt=RXBYTETO_RDEVT;
			//return RXBYTETO_RDEVT;
			break;		
		default: /* 0 */
			break;
	}

	/* Si se dispara el timer rxuplayer_timer_expired */
	if (dmodemController[handle].rd_curr_state.rxuplayer_timer_expired) {
		dmodemController[handle].rd_curr_state.rxuplayer_timer_expired = 0;
		//return RXUPLAYERTO_RDEVT;
		//logStr("Vencio Timeout RD Uplayer\n");
		rslt =RXUPLAYERTO_RDEVT;		
	}
	
	/*si se perdio la portadora, por ahora devuelvo TXUPLAYERTO_WREVT pero despues se debe cambiar a un evento nuevo*/
	if (!dmodemController[handle].get_dcd_status(dmodemController[handle].uplayer_data))
		rslt =RXUPLAYERTO_RDEVT;		
		
	return rslt;
};

/**/
static void rd_clean_curr_state( int handle )
{
	printd("%s\n", __FUNCTION__);
	
	/* detiene el timer */
	del_ctimer(&dmodemController[handle].rd_curr_state.rxuplayer_timer);	
};

/**/
static int rd_init( int handle )
{	
 	printd("%s\n", __FUNCTION__);

	dmodemController[handle].rd_curr_state.pframe = (char *)dmodemController[handle].dmodem_frame;
 	dmodemController[handle].rd_curr_state.ppayload = dmodemController[handle].rd_curr_state.pframe;  	
	dmodemController[handle].rd_curr_state.size_readed = 0;
	dmodemController[handle].rd_curr_state.retrans_no = 0;	
	
	dmodemController[handle].rd_curr_state.rxuplayer_timer_expired = 0;		
			
	/* hay que disparar el timer txuplayer_timer */
	//dmodemController[handle].rd_curr_state.rxuplayer_timer.expires = dmodemController[handle].dmconf.rxuplayer_to *10;
	dmodemController[handle].rd_curr_state.rxuplayer_timer.period = dmodemController[handle].dmconf.rxuplayer_to * 10;
	dmodemController[handle].rd_curr_state.rxuplayer_timer.expires = getTicks() + (dmodemController[handle].dmconf.rxuplayer_to * 10);

	add_ctimer(&dmodemController[handle].rd_curr_state.rxuplayer_timer);
	
	return NO_EVT;
};

/**/
static int rd_syn_comp_rcv( int handle )
{
	//logStr("%s\n", __FUNCTION__);
	
	/*si en vez de llegar el complemento llega otra cosa vuelvo a esperar SOH*/		
	if (dmodemController[handle].rd_curr_state.byte_rcv == (unsigned char ) DM_SYNCOMP)		
		/*reinicio timer de uplayer*/
		mod_ctimer(&dmodemController[handle].rd_curr_state.rxuplayer_timer,dmodemController[handle].dmconf.rxuplayer_to, 0);
	
	return RCVBYTE_RDEVT;/*retorno esto asi fuerzo que pase al estado espera SOH*/
}

  
/**/
int rd_none( int handle )
{
	printd("%s\n", __FUNCTION__);
	return NO_EVT;
};

/**/
int rd_soh( int handle )
{
	//logStr("%s llego %d\n", __FUNCTION__,rd_curr_state.byte_rcv);
	
	/* la cantidad de bytes de payload leidos */	
 	dmodemController[handle].rd_curr_state.ppayload = dmodemController[handle].rd_curr_state.pframe;
	dmodemController[handle].rd_curr_state.curr_bytes_readed = 0;	
	dmodemController[handle].rd_curr_state.retrans_no = 0;	
	dmodemController[handle].rd_curr_state.pchecksum = (char *)&dmodemController[handle].rd_curr_state.checksum; 	

	/*si en vez de llegar un SOH llega un SYN debo verificar si realmente se trata de un SYN*/			
	if (dmodemController[handle].rd_curr_state.byte_rcv == DM_SYN)
		return SYN_RDEVT;

	/*si llego un EOT*/
	if (dmodemController[handle].rd_curr_state.byte_rcv == DM_EOT)
		return EOT_RDEVT;
			
	/* si no es inicio de trama vuelve a esperar el inicio */
	if (dmodemController[handle].rd_curr_state.byte_rcv != DM_SOH)
		return NOTSOH_RDEVT;
	
	return NO_EVT;
};

/**/
int rd_seqno( int handle )
{
	printd("%s\n", __FUNCTION__);

	/* recibe el numero de secuencia de la trama */
	dmodemController[handle].rd_curr_state.curr_seqno = dmodemController[handle].rd_curr_state.byte_rcv;
	
	/* si es un retransmision descarta la trama 
	   la primer vez (rd_curr_state.next_seqno == 0) no hay rtransmision posible */
	if (dmodemController[handle].rd_curr_state.next_seqno != 0 &&		
		(unsigned char)(dmodemController[handle].rd_curr_state.curr_seqno) == (unsigned char)(dmodemController[handle].rd_curr_state.next_seqno - 1)){
		printd("CurrSeqno %d netseqno %d\n",(unsigned char)(dmodemController[handle].rd_curr_state.curr_seqno),(unsigned char)(dmodemController[handle].rd_curr_state.next_seqno));
		return RETRANS_RDEVT;
	}
			
	/* si el numero de trama recibido no es el esperado error */
	if ((unsigned char)dmodemController[handle].rd_curr_state.curr_seqno != (unsigned char)dmodemController[handle].rd_curr_state.next_seqno)
		return BADFRAME_RDEVT;
	
	return NO_EVT;
};

/**/
int rd_seqnocomp( int handle )
{
	printd("%s\n", __FUNCTION__);

	/* Recibe el complemento del numero de secuencia	
	 Si el numero recibido no es el complemento de la secuencia leido da error */
	//if ((unsigned char)~rd_curr_state.curr_seqno != (unsigned char)rd_curr_state.byte_rcv)
	if ((unsigned char)dmodemController[handle].rd_curr_state.curr_seqno + (unsigned char)dmodemController[handle].rd_curr_state.byte_rcv != 0xFF)
		return BADFRAME_RDEVT;	
	
	return NO_EVT;
};

/**/
int rd_len0( int handle )
{
	unsigned char b = dmodemController[handle].rd_curr_state.byte_rcv;
	
	printd("%s\n", __FUNCTION__);
	
	/* Arma el tamanio de datos: recibe la parte baja primero (little endian)  */
	dmodemController[handle].rd_curr_state.curr_payload_len = (unsigned short)b;

	return NO_EVT;
};

/**/
int rd_len1( int handle )
{
	unsigned char b = dmodemController[handle].rd_curr_state.byte_rcv;
	
	printd("%s\n", __FUNCTION__);

	/* Arma el tamanio de datos: recibe la parte alta despues (little endian) */
	dmodemController[handle].rd_curr_state.curr_payload_len += ((unsigned short)b << 8);
	if (dmodemController[handle].rd_curr_state.curr_payload_len > DM_MAX_DATA_LEN)
	{
	 printd("Mas datos de lo permitido\n");
		return BADFRAME_RDEVT;
	}

	return NO_EVT;
};

/**/
int rd_len0comp( int handle )
{
	unsigned char b = dmodemController[handle].rd_curr_state.byte_rcv;
	
	printd("%s\n", __FUNCTION__);
	/* Arma el tamanio de datos: recibe la parte alta  */
	dmodemController[handle].rd_curr_state.curr_payload_len_comp = (unsigned short)b;
	return NO_EVT;
};

/**/
int rd_len1comp( int handle )
{
	unsigned char b = dmodemController[handle].rd_curr_state.byte_rcv;
	
	printd("%s\n", __FUNCTION__);

	/* Arma el tamanio de datos: recibe la parte baja */
	
	dmodemController[handle].rd_curr_state.curr_payload_len_comp += ((unsigned short)b << 8) ;
	
	dmodemController[handle].rd_curr_state.curr_bytes_readed = 0;
	if ((unsigned short)dmodemController[handle].rd_curr_state.curr_payload_len != (unsigned short)~dmodemController[handle].rd_curr_state.curr_payload_len_comp)	{
		/*logStr("Llego BADFRAME_RDEVT rd_curr_state.curr_payload_len: %d rd_curr_state.curr_payload_len_comp: %d ~rd_curr_state.curr_payload_len_comp %d\n",rd_curr_state.curr_payload_len,rd_curr_state.curr_payload_len_comp,(unsigned short)~rd_curr_state.curr_payload_len_comp);*/
		return BADFRAME_RDEVT;
	}

	return NO_EVT;
};

/**/
int rd_rcv_byte( int handle )
{
	printd("%s\n", __FUNCTION__);

	/* pone los datos del payload en el buffer de trama */
	*dmodemController[handle].rd_curr_state.ppayload++ = dmodemController[handle].rd_curr_state.byte_rcv;
	
	dmodemController[handle].rd_curr_state.curr_bytes_readed++;
	
	/* Recibe ya todos los bytes del payload */
	if (dmodemController[handle].rd_curr_state.curr_bytes_readed == dmodemController[handle].rd_curr_state.curr_payload_len)
		return PAYLOADRCV_RDEVT;	

	return NO_EVT;
};

/**/
int rd_rcv_checksum_byte( int handle )
{
	unsigned long cs;
	
	printd("%s\n", __FUNCTION__);
		
	/* el byte de checksum en la posicion adecuada (son 4 bytes) */
	/* 	little endian 	 	 0x4321 -> 21 43							 
	*/				
	(*dmodemController[handle].rd_curr_state.pchecksum++) = (unsigned char)dmodemController[handle].rd_curr_state.byte_rcv;
	//(unsigned char)(*dmodemController[handle].rd_curr_state.pchecksum++) = (unsigned char)dmodemController[handle].rd_curr_state.byte_rcv;
				
	/* termino con el checksum */
	if (dmodemController[handle].rd_curr_state.pchecksum - (char *)&dmodemController[handle].rd_curr_state.checksum == 4) {
		
		/* controla el valor del checksum */		
		cs = L_ENDIAN_TO_LONG(dmodemController[handle].rd_curr_state.checksum);		
		if ((unsigned long)get_dmchecksum(dmodemController[handle].rd_curr_state.pframe, dmodemController[handle].rd_curr_state.curr_bytes_readed) != (unsigned long)cs)
			return BADFRAME_RDEVT;

		/* pone los bytes leidos en el buffer de lectura */
		rd_write_data(handle,dmodemController[handle].rd_curr_state.pframe, dmodemController[handle].rd_curr_state.curr_bytes_readed);
	
		/* se fija si tiene que enviar mas frames */
		dmodemController[handle].rd_curr_state.size_readed += dmodemController[handle].rd_curr_state.curr_bytes_readed;
		
		/*si llego una trama con menor cantidad de datos que el tama�o maximo configurado
		lo tomo como que no bienen mas tramas*/
		if (dmodemController[handle].rd_curr_state.curr_bytes_readed < dmodemController[handle].dmconf.max_data_size){
			//logStr("PASO\n");
			return NOMOREFRAMES_RDEVT;			
		}

		/* Si ya leyo todos los bytes que necesitaba
		   o si esta abierto en modo no bloqueante */		
		if ( dmodemController[handle].rd_curr_state.size_readed >= dmodemController[handle].rd_curr_state.size_to_read || 
			(dmodemController[handle].dmconf.flags & O_DMODEM_SPRD_NONBLOCK))
			return NOMOREFRAMES_RDEVT;
		else
			return MOREFRAMES_RDEVT;
	}
	
	return NO_EVT;
};

/**/
int rd_more_frames( int handle )
{
	printd("%s\n", __FUNCTION__);

	/* envia el ack */
	send_ack(handle);
	dmodemController[handle].rd_curr_state.next_seqno++;	
		
	return NO_EVT;
};


/**/
int rd_prepare_retrans( int handle )
{
	printd("%s\n", __FUNCTION__);

	/* incrementa las retransmisiones */
	if (++dmodemController[handle].rd_curr_state.retrans_no < dmodemController[handle].dmconf.max_retries)
		return MORERETRANS_RDEVT;
	else
		return NOMORERETRANS_RDEVT;
};

/**/
int rd_discard_byte( int handle )
{
	printd("%s\n", __FUNCTION__);

	return NO_EVT;
};

/**/
int rd_discard_retrans( int handle )
{
	printd("%s\n", __FUNCTION__);
	
	return NO_EVT;
};

/**/
int rd_send_ack( int handle )
{
	send_ack(handle);
	++dmodemController[handle].statistics.rxacks;
	return NO_EVT;
}	


/**/
int rd_send_nack( int handle )
{
	send_nack(handle);
	++dmodemController[handle].statistics.rxnaks;
	return NO_EVT;
};


/**/
int rd_exit_ok( int handle )
{
	printd("%s\n", __FUNCTION__);
	
	/* detiene el timer */
	del_ctimer(&dmodemController[handle].rd_curr_state.rxuplayer_timer);
	
	/* envia el ack */
	rd_send_ack(handle);
	dmodemController[handle].rd_curr_state.next_seqno++;	
	
	return NO_EVT;
};

/**/
int rd_exit_rxuplayerto( int handle )
{
	printd("%s\n", __FUNCTION__);
	
	SET_GLOBAL_ERROR(handle,EDMODEM_RXUPLAYER_TO);	
	return NO_EVT;
};

/**/
int rd_exit_retrans( int handle )
{
	printd("%s\n", __FUNCTION__);

	/* detiene el timer */
	del_ctimer(&dmodemController[handle].rd_curr_state.rxuplayer_timer);
	
	SET_GLOBAL_ERROR(handle,EDMODEM_MAXRETRIES);
 	return NO_EVT;	
};

/**/
int rd_send_eof_ack( int handle )
{
	printd("%s\n", __FUNCTION__);
	
	/* detiene el timer */
	del_ctimer(&dmodemController[handle].rd_curr_state.rxuplayer_timer);
	
	/* envia el ack */
	rd_send_ack(handle);
	
	SET_GLOBAL_ERROR(handle,EDMODEM_EOT);
	return NO_EVT;
}

/**/
int rd_eot_comp_rcv( int handle )
{
	//unsigned char c=DM_EOTCOMP;
	//logStr("%s %d %u\n", __FUNCTION__,dmodemController[handle].rd_curr_state.byte_rcv,c);
	
	/*si en vez de llegar el complemento llega otra cosa vuelvo a esperar SOH*/		
	
	if (dmodemController[handle].rd_curr_state.byte_rcv == (unsigned char) DM_EOTCOMP)	
		return RCVBYTE_RDEVT;
	else
		/*retorne asi asi voy al estado esperando SOH*/
		return RXBYTETO_RDEVT;	
}

/*******************************
	operacion connect
*******************************/
 /* el estado actual de la operacion connect */
//static DMConnectCurrState conn_curr_state;

/*funciones de la operacion connect*/
static int conn_send_syn( int handle );
static int conn_none( int handle );
static int conn_prepare_retrans( int handle );
static int conn_exit_txuplayerto( int handle );
static int conn_exit_syn_error( int handle );
static int conn_exit_retrans( int handle );
static int conn_exit_ok( int handle );

/*transiciones de la operacion connect*/
static ProtoTransition conn_transitions[] =
{		
	  /* estado actual */	/* evento */		/*  sig. estado */	/* function handler */
	 { START_CONNST, 		SENDSYN_CONNEVT, 		SYNSENDED_CONNST,	conn_send_syn } 
	
	,{ SYNSENDED_CONNST, 	UNBYTE_CONNEVT,	 		SYNSENDED_CONNST,	conn_none} 	
	,{ SYNSENDED_CONNST, 	TXFRAMETO_CONNEVT, 		CTRLRETRANS_CONNST,	conn_prepare_retrans} 	
	,{ SYNSENDED_CONNST, 	TXUPLAYERTO_CONNEVT,	EXIT_ST, 			conn_exit_txuplayerto } 
	,{ SYNSENDED_CONNST, 	NACK_CONNEVT,			NACKRCV_CONNST, 	conn_none } 
	,{ SYNSENDED_CONNST, 	SYN_SENDEDERR_CONNEVT,	EXIT_ST, 			conn_exit_syn_error } 
	
	,{ CTRLRETRANS_CONNST,	MORERETRANS_CONNEVT	,	SYNSENDED_CONNST, 	conn_send_syn }
	,{ CTRLRETRANS_CONNST,	NOMORERETRANS_CONNEVT,	EXIT_ST, 			conn_exit_retrans }	
	,{ CTRLRETRANS_CONNST,	TXUPLAYERTO_CONNEVT	,	EXIT_ST, 			conn_exit_txuplayerto } 
	
	,{ NACKRCV_CONNST, 		NACKCOMP_CONNEVT,		EXIT_ST, 	 		conn_exit_ok} 
	,{ NACKRCV_CONNST, 		UNBYTE_CONNEVT,			SYNSENDED_CONNST, 	conn_none } 	
	,{ NACKRCV_CONNST, 		TXFRAMETO_CONNEVT,		CTRLRETRANS_CONNST,	conn_prepare_retrans } 
	,{ NACKRCV_CONNST, 		TXUPLAYERTO_CONNEVT,	EXIT_ST, 			conn_exit_txuplayerto } 
};

/**/
static TIMEOUT_CTIMER_HANDLER(connuplayer_timer_handler)
{
	printd("%s\n", __FUNCTION__);
	//logStr("Vencio CTimer txUpLayerConn\n");
	
 	dmodemController[(unsigned int)GET_TIMEOUT_CTIMER_PARAM()].conn_curr_state.connuplayer_timer_expired = 1;
};

/**/
static TIMEOUT_CTIMER_HANDLER(connframe_timer_handler)
{
	printd("%s\n", __FUNCTION__);
	//logStr("Vencio CTimer Conn\n");
	dmodemController[(unsigned int)GET_TIMEOUT_CTIMER_PARAM()].conn_curr_state.connframe_timer_expired = 1;
};

/**/
static int conn_wait_event( int handle )
{
	unsigned int b;
			
	assert(dmodemController[handle].rcv_byte);
	/* Si recibe un byte ... 
	   Como el segundo argumento es cero entonces entra a ver si recibe un byte
	   y si no lo recibe sale con valor 0.
	   Devuelve 1 si hay un byte recibido.
	 */		
	if (dmodemController[handle].rcv_byte(dmodemController[handle].uplayer_data, 0, &b) == 1) {
		switch ((unsigned char)b) {
			case (unsigned char)DM_NACK:
					return NACK_CONNEVT;
			case (unsigned char)DM_NACK_COMP:
					return NACKCOMP_CONNEVT;
			default:				{
					return UNBYTE_CONNEVT;
			}
		}
	}
	
	/*si se perdio la portadora, por ahora devuelvo TXUPLAYERTO_WREVT pero despues se debe cambiar a un evento nuevo*/
 	  if (!dmodemController[handle].get_dcd_status(dmodemController[handle].uplayer_data))
 		return TXUPLAYERTO_CONNEVT;
		
	/* Si se dispara el timer xuplayer_timer_expired ...*/
	if (dmodemController[handle].conn_curr_state.connuplayer_timer_expired) {
		dmodemController[handle].conn_curr_state.connuplayer_timer_expired = 0;
		return TXUPLAYERTO_CONNEVT;
	}
	
	/* Si se dispara el timer txframe_timer_expired ...*/
	if (dmodemController[handle].conn_curr_state.connframe_timer_expired) {
		dmodemController[handle].conn_curr_state.connframe_timer_expired = 0;
		return TXFRAMETO_CONNEVT;
	}
		
	return NO_EVT;
};

/**/
static void conn_clean_curr_state( int handle )
{
	printd("%s\n", __FUNCTION__);
	
	/* detiene los timers */
	del_ctimer(&dmodemController[handle].conn_curr_state.connuplayer_timer);
	del_ctimer(&dmodemController[handle].conn_curr_state.connframe_timer);
};

/**/
static int conn_init( int handle )
{	
 	//logStr("%s\n", __FUNCTION__);
 	
	dmodemController[handle].conn_curr_state.connuplayer_timer_expired = 0;
	dmodemController[handle].conn_curr_state.connframe_timer_expired = 0; 	
	
	/* configura el timer de envio de tramas */
	dmodemController[handle].conn_curr_state.connframe_timer.expires = dmodemController[handle].dmconf.txframe_to;

	/* hay que disparar el timer txuplayer_timer */
	dmodemController[handle].conn_curr_state.connuplayer_timer.expires = dmodemController[handle].dmconf.txuplayer_to;
	add_ctimer(&dmodemController[handle].conn_curr_state.connuplayer_timer);
	
	
	/* envia el syn*/
	return conn_send_syn(handle) == NO_EVT;	
};

/**/
int conn_send_syn( int handle )
{
	unsigned char syn[2];
	
	//logStr("%s\n", __FUNCTION__);
	
	syn[0]= DM_SYN;
	syn[1]=~DM_SYN;
	
	/* se dispara el timer conn_curr_state.connframe_timer */
	dmodemController[handle].conn_curr_state.connframe_timer.expires = dmodemController[handle].dmconf.txframe_to;
	add_ctimer(&dmodemController[handle].conn_curr_state.connframe_timer);
		
	/* envia el syn */
	if (!dmodemController[handle].send_buf(dmodemController[handle].uplayer_data,syn , 2)) {
		SET_GLOBAL_ERROR(handle,EDMODEM_FATAL);
		return SYN_SENDEDERR_CONNEVT;
	}
	
	return NO_EVT;
}

/**/
int conn_none( int handle )
{
	return NO_EVT;
}

/**/
int conn_prepare_retrans( int handle )
{
	//logStr("%s\n", __FUNCTION__);
	
	/* detiene el timer conn_curr_state.connframe_timer */
	del_ctimer(&dmodemController[handle].conn_curr_state.connframe_timer);

	/* incrementa las retransmisiones */
	if (++dmodemController[handle].conn_curr_state.retrans_no < dmodemController[handle].dmconf.max_retries)
		return MORERETRANS_CONNEVT;
	else
		return NOMORERETRANS_CONNEVT;
}

/**/
int conn_exit_txuplayerto( int handle )
{
	/* detiene el timer conn_curr_state.connuplayer_timer */
	del_ctimer(&dmodemController[handle].conn_curr_state.connuplayer_timer);

	SET_GLOBAL_ERROR(handle,EDMODEM_TXUPLAYER_TO);
	return NO_EVT;
}

/**/
int conn_exit_syn_error( int handle )
{
	printd("%s\n", __FUNCTION__);

	/* detiene el timer conn_curr_state.connuplayer_timer */
	del_ctimer(&dmodemController[handle].conn_curr_state.connuplayer_timer);
	
	SET_GLOBAL_ERROR(handle,EDMODEM_FATAL);
	return NO_EVT;		
}

/**/
int conn_exit_retrans( int handle )
{
	printd("%s\n", __FUNCTION__);
	/* detiene el timer conn_curr_state.connuplayer_timer */
	del_ctimer(&dmodemController[handle].conn_curr_state.connuplayer_timer);

	SET_GLOBAL_ERROR(handle,EDMODEM_MAXRETRIES);	
	return NO_EVT;		
}

/**/
int conn_exit_ok( int handle )
{
	printd("%s\n", __FUNCTION__);
	
	/* detiene el timer conn_curr_state.connuplayer_timer */
	del_ctimer(&dmodemController[handle].conn_curr_state.connuplayer_timer);
	
	del_ctimer(&dmodemController[handle].conn_curr_state.connframe_timer);

	SET_GLOBAL_ERROR(handle,EDMODEM_NOERROR);
	return NO_EVT;
}

/*funciones de la operacion disconnect*/
static int disconn_send_eot( int handle );
static int disconn_none( int handle );
static int disconn_prepare_retrans( int handle );
static int disconn_exit_txuplayerto( int handle );
static int disconn_exit_error( int handle );
static int disconn_exit_retrans( int handle );
static int disconn_exit_ok( int handle );

/*transiciones de la operacion connect*/
static ProtoTransition disconnect_transitions[] =
{		
	  /* estado actual */	/* evento */		/*  sig. estado */	/* function handler */
	 { START_DISCONNST, 		SENDEOT_DISCONNEVT, 		EOTSENDED_DISCONNST,	disconn_send_eot } 
	
	,{ EOTSENDED_DISCONNST, 	UNBYTE_DISCONNEVT,	 		EOTSENDED_DISCONNST,	disconn_none} 	
	,{ EOTSENDED_DISCONNST, 	TXFRAMETO_DISCONNEVT, 		CTRLRETRANS_DISCONNST,	disconn_prepare_retrans} 	
	,{ EOTSENDED_DISCONNST, 	TXUPLAYERTO_DISCONNEVT,	EXIT_ST, 			disconn_exit_txuplayerto } 
	,{ EOTSENDED_DISCONNST, 	ACK_DISCONNEVT,			ACKRCV_DISCONNST, 	disconn_none } 
	,{ EOTSENDED_DISCONNST, 	EOT_SENDEDERR_DISCONNEVT,	EXIT_ST, 			disconn_exit_error } 
	
	,{ CTRLRETRANS_DISCONNST,	MORERETRANS_DISCONNEVT	,	EOTSENDED_DISCONNST, 	disconn_send_eot }
	,{ CTRLRETRANS_DISCONNST,	NOMORERETRANS_DISCONNEVT,	EXIT_ST, 			disconn_exit_retrans }	
	,{ CTRLRETRANS_DISCONNST,	TXUPLAYERTO_DISCONNEVT	,	EXIT_ST, 			disconn_exit_txuplayerto } 
	
	,{ ACKRCV_DISCONNST, 		ACKCOMP_DISCONNEVT,		EXIT_ST, 	 		disconn_exit_ok} 
	,{ ACKRCV_DISCONNST, 		UNBYTE_DISCONNEVT,			EOTSENDED_DISCONNST, 	disconn_none } 	
	,{ ACKRCV_DISCONNST, 		TXFRAMETO_DISCONNEVT,		CTRLRETRANS_DISCONNST,	disconn_prepare_retrans } 
	,{ ACKRCV_DISCONNST, 		TXUPLAYERTO_DISCONNEVT,	EXIT_ST, 			disconn_exit_txuplayerto } 
};

/**/
static TIMEOUT_CTIMER_HANDLER(disconnuplayer_timer_handler)
{
	printd("%s\n", __FUNCTION__);
	//logStr("Vencio CTimer txUpLayerConn\n");
	
 	dmodemController[(unsigned int)GET_TIMEOUT_CTIMER_PARAM()].disconn_curr_state.disconnuplayer_timer_expired = 1;
};

/**/

static TIMEOUT_CTIMER_HANDLER(disconnframe_timer_handler)
{
	printd("%s\n", __FUNCTION__);
	//logStr("Vencio CTimer Conn\n");
	dmodemController[(unsigned int)GET_TIMEOUT_CTIMER_PARAM()].disconn_curr_state.disconnframe_timer_expired = 1;
};

/**/
static int disconn_wait_event( int handle )
{
	int b;
			
	assert(dmodemController[handle].rcv_byte);
	/* Si recibe un byte ... 
	   Como el segundo argumento es cero entonces entra a ver si recibe un byte
	   y si no lo recibe sale con valor 0.
	   Devuelve 1 si hay un byte recibido.
	 */		
	if (dmodemController[handle].rcv_byte(dmodemController[handle].uplayer_data, 0, &b) == 1) {
		switch ((unsigned char)b) {
			case (unsigned char)DM_ACK:
					return ACK_DISCONNEVT;
			case (unsigned char)DM_ACK_COMP:
					return ACKCOMP_DISCONNEVT;
			default:				{
			     //logStr("Llego %d",(unsigned char)b);
					return UNBYTE_DISCONNEVT;
			}
		}
	}
	
	/*si se perdio la portadora, por ahora devuelvo TXUPLAYERTO_WREVT pero despues se debe cambiar a un evento nuevo*/
 	  if (!dmodemController[handle].get_dcd_status(dmodemController[handle].uplayer_data))
 		return TXUPLAYERTO_DISCONNEVT;
		
	/* Si se dispara el timer xuplayer_timer_expired ...*/
	if (dmodemController[handle].disconn_curr_state.disconnuplayer_timer_expired) {
		dmodemController[handle].disconn_curr_state.disconnuplayer_timer_expired = 0;
		return TXUPLAYERTO_DISCONNEVT;
	}
	
	/* Si se dispara el timer txframe_timer_expired ...*/
	if (dmodemController[handle].disconn_curr_state.disconnframe_timer_expired) {
		dmodemController[handle].disconn_curr_state.disconnframe_timer_expired = 0;
		return TXFRAMETO_DISCONNEVT;
	}
		
	return NO_EVT;
};

/**/
static void disconn_clean_curr_state( int handle )
{
	printd("%s\n", __FUNCTION__);
	
	/* detiene los timers */
	del_ctimer(&dmodemController[handle].disconn_curr_state.disconnuplayer_timer);
	del_ctimer(&dmodemController[handle].disconn_curr_state.disconnframe_timer);
};

/**/
static int disconn_init( int handle )
{	
 	//logStr("%s\n", __FUNCTION__);
 	
	dmodemController[handle].disconn_curr_state.disconnuplayer_timer_expired = 0;
	dmodemController[handle].disconn_curr_state.disconnframe_timer_expired = 0; 	
	
	/* configura el timer de envio de tramas */
	dmodemController[handle].disconn_curr_state.disconnframe_timer.expires = dmodemController[handle].dmconf.txframe_to;

	/* hay que disparar el timer txuplayer_timer */
	dmodemController[handle].disconn_curr_state.disconnuplayer_timer.expires = dmodemController[handle].dmconf.txuplayer_to;
	add_ctimer(&dmodemController[handle].disconn_curr_state.disconnuplayer_timer);
	
	/* envia el syn*/
	return disconn_send_eot(handle) == NO_EVT;	
};

/**/
int disconn_send_eot( int handle )
{
	unsigned char eot[2];
	
	//logStr("%s\n", __FUNCTION__);
	
	eot[0]= DM_EOT;
	eot[1]=~DM_EOT;
	
	/* se dispara el timer conn_curr_state.connframe_timer */
	dmodemController[handle].disconn_curr_state.disconnframe_timer.expires = dmodemController[handle].dmconf.txframe_to;
	add_ctimer(&dmodemController[handle].disconn_curr_state.disconnframe_timer);
		
	/* envia el syn */
	if (!dmodemController[handle].send_buf(dmodemController[handle].uplayer_data,eot , 2)) {
		SET_GLOBAL_ERROR(handle,EDMODEM_FATAL);
		return EOT_SENDEDERR_DISCONNEVT;
	}
	
	return NO_EVT;
}

/**/
int disconn_none( int handle )
{
	return NO_EVT;
}

/**/
int disconn_prepare_retrans( int handle )
{
	//logStr("%s\n", __FUNCTION__);
	
	/* detiene el timer conn_curr_state.connframe_timer */
	del_ctimer(&dmodemController[handle].disconn_curr_state.disconnframe_timer);

	/* incrementa las retransmisiones */
	if (++dmodemController[handle].disconn_curr_state.retrans_no < dmodemController[handle].dmconf.max_retries)
		return MORERETRANS_DISCONNEVT;
	else
		return NOMORERETRANS_DISCONNEVT;
}

/**/
int disconn_exit_txuplayerto( int handle )
{
	/* detiene el timer conn_curr_state.connuplayer_timer */
	del_ctimer(&dmodemController[handle].disconn_curr_state.disconnuplayer_timer);

	SET_GLOBAL_ERROR(handle,EDMODEM_TXUPLAYER_TO);
	return NO_EVT;
}

/**/
int disconn_exit_error( int handle )
{
	printd("%s\n", __FUNCTION__);

	/* detiene el timer conn_curr_state.connuplayer_timer */
	del_ctimer(&dmodemController[handle].disconn_curr_state.disconnuplayer_timer);
	
	SET_GLOBAL_ERROR(handle,EDMODEM_FATAL);
	return NO_EVT;		
}

/**/
int disconn_exit_retrans( int handle )
{
	printd("%s\n", __FUNCTION__);
	/* detiene el timer conn_curr_state.connuplayer_timer */
	del_ctimer(&dmodemController[handle].disconn_curr_state.disconnuplayer_timer);

	SET_GLOBAL_ERROR(handle,EDMODEM_MAXRETRIES);	
	return NO_EVT;		
}

/**/
int disconn_exit_ok( int handle )
{
	printd("%s\n", __FUNCTION__);
	
	/* detiene el timer conn_curr_state.connuplayer_timer */
	del_ctimer(&dmodemController[handle].disconn_curr_state.disconnuplayer_timer);
	
	del_ctimer(&dmodemController[handle].disconn_curr_state.disconnframe_timer);

	SET_GLOBAL_ERROR(handle,EDMODEM_NOERROR);
	return NO_EVT;
}

/**
*
*/
void initDmodemController()
{
	int i;
  	
	/*creo el mutex para la obtencion del handle del dmodem*/
  mutexInit( &dmodem_handle_mutex, NULL );
  
  //inicializo timers del sistema
	init_ctimers();
	
	/*incializo el array de los dmodem*/
	for (i=0;i<MAX_CONN_ACCEPTED;++i)
		dmodemController[i].handle=-1;
}
/**
*
*/
int getDmodemHandle(void)
{
	int i=0;
 
  TAKE_MUTEX();

	while ((i< MAX_CONN_ACCEPTED)&& (dmodemController[i].handle != -1))
		++i;
	
	RELEASE_MUTEX();

	if (i >= MAX_CONN_ACCEPTED )
		return -1;
	else
		return i;
}
/******************************
 * Las funciones publicas
 ******************************/
 
 /**/
//int dmodem_open( int f, void *upldata, SendBufHandler *sb, ReceiveByte *rb )
int dmodem_open( int f, void *upldata, SendBufHandler *sb, ReceiveByte *rb, GetDCDStatus *getDCDStatus)
{
 	//int handle=getDmodemHandle();
 	int handle=0;
	
	printd("DMODEM OPEN\n");
	if (handle != -1){
		CLEAR_GLOBAL_ERROR(handle);
	
    dmodemController[handle].handle	=handle;
		/* la configuracion por defecto */ 	
		dmodemController[handle].dmconf.max_data_size = DMODEM_MAX_DATA_SIZE_DEF;
		dmodemController[handle].dmconf.txframe_to = DMODEM_TXFRAME_TO_DEF;		
		printd("--DMODEM_TXFRAME_TO_DEF %d",DMODEM_TXFRAME_TO_DEF);
		dmodemController[handle].dmconf.rxbyte_to = DMODEM_RXBYTE_TO_DEF;
		dmodemController[handle].dmconf.max_retries = DMODEM_MAX_RETIRES_DEF;
		dmodemController[handle].dmconf.txuplayer_to = DMODEM_TXUPLAYER_TO_DEF;
		dmodemController[handle].dmconf.rxuplayer_to = DMODEM_RXUPLAYER_TO_DEF;
		dmodemController[handle].dmconf.startconn_to = DMODEM_STARTCONN_TO_DEF; 
		
		dmodemController[handle].dmconf.flags = f;
	
	
		/* Configura las funciones de callback */
		dmodemController[handle].send_buf = sb;
		dmodemController[handle].rcv_byte = rb;
		dmodemController[handle].get_dcd_status =getDCDStatus;
		dmodemController[handle].uplayer_data = upldata; 
		
		/* Configura la escritura */	
		dmodemController[handle].wr_curr_state.curr_seqno = 1;
		dmodemController[handle].wr_curr_state.txuplayer_timer.function = txuplayer_timer_handler;
		dmodemController[handle].wr_curr_state.txuplayer_timer.data=handle;
		init_ctimer( &dmodemController[handle].wr_curr_state.txuplayer_timer );
		dmodemController[handle].wr_curr_state.txframe_timer.function = txframe_timer_handler;
		dmodemController[handle].wr_curr_state.txframe_timer.data=handle;
		init_ctimer( &dmodemController[handle].wr_curr_state.txframe_timer );		
		
		/* Configura la lectura */
		dmodemController[handle].rd_curr_state.curr_seqno = 1;
		dmodemController[handle].rd_curr_state.next_seqno = 1;
		
		dmodemController[handle].rd_curr_state.rxuplayer_timer.function = rxuplayer_timer_handler;
		dmodemController[handle].rd_curr_state.rxuplayer_timer.data=handle;
		init_ctimer( &dmodemController[handle].rd_curr_state.rxuplayer_timer ); 	
		
		/* maneja el buffer de datos */
		dmodemController[handle].rd_curr_state.last_data_index = 0;
		dmodemController[handle].rd_curr_state.first_data_index = 0;
		dmodemController[handle].rd_curr_state.data_count = 0;
		dmodemController[handle].rd_curr_state.max_data_count = DM_MAX_DATA_READ;
	
		/*configura el connect*/	
		dmodemController[handle].conn_curr_state.connuplayer_timer.function=connuplayer_timer_handler;
		dmodemController[handle].conn_curr_state.connuplayer_timer.data=handle;
		dmodemController[handle].conn_curr_state.connframe_timer.function=connframe_timer_handler;
		dmodemController[handle].conn_curr_state.connframe_timer.data= handle;
	
	  /*inicializo las estadisticas de la conexion*/
	  dmodemController[handle].statistics.txnaks=0;
    dmodemController[handle].statistics.txacks=0;
    dmodemController[handle].statistics.txframeTO=0;
    dmodemController[handle].statistics.rxacks=0;
    dmodemController[handle].statistics.rxnaks=0;
    
    /*anulo el log por defecto*/
    dmodemController[handle].logActive=0;
    printd("FIN DMODEM OPEN\n");   
		return handle;
	}
	else
		return -1;
};
 
 
/**/
int dmodem_close( const int handle )
{ 	
 	CLEAR_GLOBAL_ERROR(handle);
 	
 	del_ctimer( &dmodemController[handle].wr_curr_state.txuplayer_timer );
 	del_ctimer( &dmodemController[handle].wr_curr_state.txframe_timer ); 	 	
 	del_ctimer( &dmodemController[handle].rd_curr_state.rxuplayer_timer ); 	
 	 	 	 	
 	return 1;
};
 

/**/
int dmodem_connect( const int handle )
{
	printd("%s\n", __FUNCTION__);
 	printd("DMODEM CONNECT\n");  	
 	CLEAR_GLOBAL_ERROR(handle);
	
  	/* arranca la secuencia de pasos del protocolo */
  	printd("if (conn_init(handle) == -1)\n"); 	
  	if (conn_init(handle) == -1)
  		return -1;
	printd("PROTO ENGINE\n"); 		
  	if ( !proto_engine(&conn_transitions[0], sizeof(conn_transitions) / sizeof(conn_transitions[0]),
  					   conn_wait_event, conn_clean_curr_state ,
  					   NO_EVT, SYNSENDED_CONNST, EXIT_ST ,handle) )  								
 		 return -1;
  printd("FIN DMODEM CONNECT\n"); 
 	return 1;
};


/*******************
 * Operacion ACCEPT
 */


/**/
static TIMEOUT_CTIMER_HANDLER(conn_timer_handler)
{
	printd("%s\n", __FUNCTION__);
	
dmodemController[(unsigned int)GET_TIMEOUT_CTIMER_PARAM()].acc_conn_timer_expired = 1;
};


/**/
int dmodem_accept( const int handle )
{
  send_ack(handle);
  return 1;
};


/**/
int dmodem_disconnect( const int handle )
{	
  printd("%s\n", __FUNCTION__);
 	 	
 	CLEAR_GLOBAL_ERROR(handle);
	
  /* arranca la secuencia de pasos del protocolo */
  if (disconn_init(handle) == -1)
  		return -1;
		
  if ( !proto_engine(&disconnect_transitions[0], sizeof(disconnect_transitions) / sizeof(disconnect_transitions[0]),
  					   disconn_wait_event, disconn_clean_curr_state ,
  					   NO_EVT, SENDEOT_DISCONNEVT, EXIT_ST ,handle) )  								
 	  return -1;

 	return 1;
};
 
/**/
int dmodem_write( const int handle,const char *buf, size_t size )
{
 	printd("%s\n", __FUNCTION__);
 	 	
 	CLEAR_GLOBAL_ERROR(handle);
 	dmodemController[handle].wr_curr_state.pdata = (char *)buf; 
 	dmodemController[handle].wr_curr_state.data_size = size;

  	/* arranca la secuencia de pasos del protocolo */
  	if (wr_init(handle) == -1)
  		return -1;
  	if ( !proto_engine(&wr_transitions[0], sizeof(wr_transitions) / sizeof(wr_transitions[0]),
  					   wr_wait_event, wr_clean_curr_state ,
  					   NO_EVT, FRAMESENDED_WRST, EXIT_ST ,handle) )
  								
 		return -1;

 	//return wr_curr_state.data_size - wr_curr_state.remain_size;
	return GET_GLOBAL_ERROR(handle)== EDMODEM_NOERROR;
};
 
 
/**/
int dmodem_read( const int handle, char *buf, size_t size )
{ 	
 	CLEAR_GLOBAL_ERROR(handle);

	/* si ya tiene datos y son suficientes los devuelve y sale */
	if (size <= dmodemController[handle].rd_curr_state.data_count){	
 		return rd_read_data(handle,buf, size);
	}
 	
 	/* Si no esta en modo bloqueante y tiene algun dato sale con los datos */
 	if (dmodemController[handle].rd_curr_state.data_count && (dmodemController[handle].dmconf.flags & O_DMODEM_SPRD_NONBLOCK)){
 		return rd_read_data(handle,buf, size);	
	}
 	 	
  	/* arranca la secuencia de pasos del protocolo */  	
  	if (rd_init(handle) == -1)
  		return -1;
  	dmodemController[handle].rd_curr_state.size_to_read = size; 
   	if ( !proto_engine(&rd_transitions[0], sizeof(rd_transitions) / sizeof(rd_transitions[0]),
  					   rd_wait_event, rd_clean_curr_state ,
  					   NO_EVT, WAITSOH_RDST, EXIT_ST ,handle) )
 		return -1; 	
					
	//return rd_read_data(buf, size);	
	return rd_read_data(handle,buf, dmodemController[handle].rd_curr_state.size_readed);	
};
 
  
 /**/
int dmodem_conf( const int handle,DModemConfig *conf )
{  	
 	CLEAR_GLOBAL_ERROR(handle);
 		
	dmodemController[handle].dmconf = *conf; 
	return 0;
};

int dmodem_confDLL(const int handle,size_t max_data_size,unsigned long	txframe_to,unsigned long rxbyte_to ,int max_retries,unsigned long	txuplayer_to,unsigned long	rxuplayer_to,unsigned long	startconn_to)
{  	
 	CLEAR_GLOBAL_ERROR(handle);
 		
	dmodemController[handle].dmconf.max_data_size  = max_data_size; 
	dmodemController[handle].dmconf.txframe_to     = txframe_to; 
	dmodemController[handle].dmconf.rxbyte_to      = rxbyte_to; 
	dmodemController[handle].dmconf.max_retries    = max_retries; 
	dmodemController[handle].dmconf.txuplayer_to   = txuplayer_to; 
	dmodemController[handle].dmconf.rxuplayer_to   = rxuplayer_to; 
	dmodemController[handle].dmconf.startconn_to   = startconn_to; 

	/*logStr("max_data_size  = %d",dmodemController[handle].dmconf.max_data_size); 
	logStr("txframe_to     = %d",dmodemController[handle].dmconf.txframe_to); 
	logStr("rxbyte_to      = %d",dmodemController[handle].dmconf.rxbyte_to); 
	logStr("max_retries    = %d",dmodemController[handle].dmconf.max_retries); 
	logStr("txuplayer_to   = %d",dmodemController[handle].dmconf.txuplayer_to); 
	logStr("rxuplayer_to   = %d",dmodemController[handle].dmconf.rxuplayer_to); 
	logStr("startconn_to   = %d",dmodemController[handle].dmconf.startconn_to); 
	*/
	return 0;
};


/**/
int dmodem_geterror( const int handle )
{
	return -GET_GLOBAL_ERROR(handle);
};

/**/
int dmodem_init( const int handle )
{ 
	dmodemController[handle].wr_curr_state.curr_seqno=1;
	dmodemController[handle].rd_curr_state.curr_seqno = 1;
 	dmodemController[handle].rd_curr_state.next_seqno = 1;
  return 1;
}

/**/
void dmodem_setTxUpLayerTO(const int handle, unsigned long value)
{
	dmodemController[handle].dmconf.txuplayer_to =value;
}

/**/
void dmodem_setRxUpLayerTO(const int handle, unsigned long value)
{
	dmodemController[handle].dmconf.rxuplayer_to =value;
}
/**/
void dmodem_getStatistics(const int handle, unsigned short *st)
{
  memcpy(st,&dmodemController[handle].statistics,sizeof(Statistic));
  
}

/**/
void dmodem_setLogState(const int handle,int value)
{
	dmodemController[handle].logActive = value;
		
}
/**/
int dmodem_getLogState(const int handle)
{
	return dmodemController[handle].logActive;
}
void * dmodem_getUplData(const int handle)
{
  return dmodemController[handle].uplayer_data;
}

int dmodem_getError (int handle)
{
  return dmodemController[handle].dm_global_error;
}
