#include <assert.h>
#include "OSServices.h"
#include "DModemProto.h"
#include "dmodem.h"

#define printd(args...)	

@implementation DModemProto

/**/
static int send_serial(void * obj, char *buf, int q)
{
  printd("send_serial(\n");
	return [obj __dm_writeSerial: buf qty: q];
}

static int read_serial(void * obj, int rcv_type, int *pdata)
{
	return [obj __dm_readSerial: rcv_type data: pdata];
}

#ifdef _WIN32
static int dcdStatus(void)
{
		return 1;
}
#else

int dcdStatus(void)
{
/*	
		int dcd;
		
 		ioctl([modem getComPort] , TIOCMGET, &dcd);
		
		if (!(dcd & TIOCM_CAR)){
			logStr("Se Perdio la portadora.  SE ABORTA LA COMUNICACION\n");
		}
	
		return (dcd & TIOCM_CAR);
*/
	return 1;		
}  
#endif

/**/
+ new
{
	return [[super new]initialize];
}

/**/
- initialize
{	
	myFlags = 0;
		
	/*cargo configuracion default del dmodem*/
	dm.max_data_size = 32;	
	dm.txframe_to = DMODEM_TXFRAME_TO_DEF;
	dm.rxbyte_to = DMODEM_RXBYTE_TO_DEF;
	dm.max_retries = DMODEM_MAX_RETIRES_DEF;
	dm.txuplayer_to = DMODEM_TXUPLAYER_TO_DEF;
	dm.rxuplayer_to = DMODEM_RXUPLAYER_TO_DEF;
	dm.startconn_to = DMODEM_STARTCONN_TO_DEF;
	
	return self;
}


/**/
- free
{	
	return [super free];
}

/**/
- (void) setSpecialReadBlockMode: (int) aMode
{
	if (aMode) myFlags &= ~O_DMODEM_SPRD_NONBLOCK; else myFlags |= O_DMODEM_SPRD_NONBLOCK; 
}

/**/
- (void) setReader: (READER) aReader
{
	myReader = aReader;
};

/**/
- (void) setWriter: (WRITER) aWriter
{
	myWriter = aWriter;
};
	
/**/
- (void) open
{		
	int n;
  //char *buf;
  
	n = dmodem_open(O_DMODEM_SPRD_BLOCK, (void *) self, send_serial,read_serial, dcdStatus);	
	if (n == -1)
		THROW(GENERAL_IO_EX);
	
	/*configuro el dmodem por defecto*/
	dmodem_conf(0,&dm);
	
	/*inicializo dmodem*/
	dmodem_init(0);
}


/**/
- (void) close
{
	if (dmodem_close(0) == -1) THROW(GENERAL_IO_EX);
}


/**/
- (void) connect
{
	char aux[20];

	if (dmodem_connect(0) == -1) THROW(GENERAL_IO_EX); 	
	if (dmodem_getError(0) != EDMODEM_NOERROR) {
		sprintf(aux, "%d", dmodem_getError(0));
		THROW_MSG(GENERAL_IO_EX, aux);
	}
	
}


/**/
- (void) waitConnection
{
	if (dmodem_accept(0) == -1) THROW(GENERAL_IO_EX);
}


	
/**/
- (int) write: (char *) aBuf qty: (int) aQty
{
	int s = dmodem_write(0, aBuf, aQty );
	if (s == -1) THROW(DMODEM_READ_EX);
	if (dmodem_getError(0) != EDMODEM_NOERROR) THROW(GENERAL_IO_EX);
	return s;
}

/**/
- (int)  read:(char *)aBuf qty: (int) aQty
{
	int s = dmodem_read(0, aBuf, aQty );	
	if (s == -1) THROW(DMODEM_READ_EX);
	if (dmodem_getError(0) != EDMODEM_NOERROR) THROW(GENERAL_IO_EX);
	return s;
}



/**/
- (int) __dm_writeSerial: (unsigned char *)aBuf qty: (int) aQty
{
	assert(myWriter);
	return [myWriter write: (unsigned char *)aBuf qty: aQty];
};

/** 
 * Retorna
 *	0 si no hay bytes y rcv_type = 0
 *	1 si hay un byte recibido
 *	2 si se vencio el timeout y rcv_type = 1
 */
- (int) __dm_readSerial: (int) aRcvType data: (int *) aPData
{
	int n;
	char b;
	
	assert(myReader);
	n = [myReader read: &b qty: 1];
	
	if (n == 1) {
		*aPData = b;		
		return 1;
	} 
	
	if (aRcvType == 1 && n == 0)
		return 2; /* timeout de recepcion entre bytes */
	
	return 0;
};

/**
 *  Funcion que reinicia el dmodem asignando el nuevo maxDataSize
 */ 
- (void) restart
{
  dmodem_init(0);
  dm.max_data_size= DMODEM_MAX_DATA_SIZE_DEF;
  dmodem_conf(0,&dm);  
}

@end

