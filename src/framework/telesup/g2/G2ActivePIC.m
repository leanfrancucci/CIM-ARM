#include "G2ActivePIC.h"
#include "Audit.h"
#include "../dmodem/dmodem.h"
#include "endian.h"
#include "system/util/all.h"
#include "Event.h"

#define MAX_PTSD_APP_VERSION 		"PTSD-1.19"

//#define printd(args...) doLog(0,args)
#define printd(args...)

typedef struct {
	char* systemTypeDesc;
	int systemTypeId;
	char* ptsdSystemTypeVersion;
} PTSDVersion;

static PTSDVersion versions[] =
{
	{"SAR II", 			1, 	  ""},
	{"G2", 					2,  	""},
	{"TELEFONICA",	3, 		""},
	{"TELECOM", 		4,  	""},
	{"SAR I", 			5,  	""},
	{"IMAS", 				6,  	""},
	{"SAR II PTSD", 7,  	""},
	{"PIMS", 				8,  	"PTSD-1.18"},
	{"CMP", 				9,  	"PTSD-1.19"},
	{"CMP OUT", 		10,  	"PTSD-1.19"},
    {"CONSOLE", 	 10,  	"PTSD-1.18"}

};	


/**/
@implementation G2ActivePIC

- (char*) getSystemVersionByTelcoType: (int) aTelcoType;

/**/
+ new
{
	return [[super new] initialize];
}	

/**/
- free
{
	return self;
}
	

/**/
- initialize
{
	[super initialize];
	
	[self clear];
		
	return self;	
}

/**/
- (void) clear
{
	myReader = NULL;
	myWriter = NULL;	
}

/**/
- (void) setConnectionType: (int) cType { 	connectionType = cType; }
- (int) getConnectionType { return connectionType; }

/**/
- (void) setReader: (READER) aReader { 	myReader = aReader; }

/**/
- (void) setWriter: (WRITER) aWriter { 	myWriter = aWriter; }

/**/
- (void) executeProtocol
{
	int size = 0;
	int nRead;
	int retry = 10;

	assert(myWriter);
	assert(myReader);
	
	/**/
	size = [self setupConfigurationMessage: myMessageBuffer];
	
	/* Envia el mensaje de configuracion */
	//doLog(0,"Size PIC %d\n",size);

	[myWriter write: myMessageBuffer qty: size];

	/* Espera la respuesta */
	/** @todo: leer como corresponde en un while y la cantidad de datos correcta */
	memset(myMessageBuffer, 0, sizeof(myMessageBuffer) - 1);

	size = 0;
	while (size < 3 && retry > 0) {
		nRead = [myReader read: &myMessageBuffer[size] qty: 3-size];
		size += nRead;
    		retry--;
	}

	/* Si no acepto la configuracion lanza una excepcion */
	if (![self checkForAcceptedResponse: myMessageBuffer]){
    [Audit auditEvent: TELESUP_PIC_ERROR additional: "" station: 0 logRemoteSystem: FALSE];	
		THROW( TRANSPORT_INVALID_CONNECTION_EX );
	}
	
	/*Si es dmodem lo reinicio, lo que voy a hacer es medio chancho, pero sirve
  como el reader es el DModemProto mismo lo uso para ejecutar el reinicio del dmodem
  TODO Mejorar este cableeeeeee*/
	if (connectionType == 1) /*DMODEM*/
    [myReader restart];
}

/**/
- (int) setupConfigurationMessage: (char *) aMessage
{	
	// Lo tengo hermosamente cableado para configurar sockets
	// En realidad no configura nada
	char *p = aMessage;
	short tmp;
	unsigned int txTO;
	FILE *f;
	
	
	/*
		Mensaje de configuracion: 
			[
				codigo(1)  						0x01
				data-len(2) 					0x0000
				transport-version(0..32)		"tcp-ip\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
				opts-len(2)						0x0000
				transport-options(0..512)		""
				app-family(0..32)				"ct8016-v1.0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
				app-version(0..32)			"ct8016-v1.0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
				opts-len(2)						0x0000
				app-opts(0..512)				""
			]
	*/
	/**/
	if (connectionType== 0){ /*PTSD*/
  	*p++ = 0x01; // codigo
  	*p++ = 0x66; // datalen[0] : datalen = 100
  	*p++ = 0x00; // datalen[1]
  	memset(p, '\0', 32);
  	strcpy(p, "tcp_ip"); // transport-version		
  	p += 32;
  	*p++ = 0x00; // opts-len[0]
  	*p++ = 0x00; // opts-len[1]		
  	memset(p, '\0', 32);
  	strcpy(p, "ptsd"); // app-family
  	p += 32;
  	memset(p, '\0', 32);	
  	strcpy(p, [self getSystemVersionByTelcoType: myTelcoType]); // app-version
  	p += 32;	
		
		// opt-len	
  	*p++ = 0x22; 
  	*p++ = 0x00; 

		// timeout
   	*p++ = 0x58; 
   	*p++ = 0x02; 

		// maxima version
  	memset(p, '\0', 32);	
  	strcpy(p, MAX_PTSD_APP_VERSION); // max-app-version
  	p += 32;	

		return p - aMessage;	

  } else {

		//doLog(0,"UTILIZA DMODEM\n");
  	/*msg type*/
  	*p++ = 0x01;
  	
  	/*msg data len*/
  	tmp= SHORT_TO_L_ENDIAN(0x73);
  	memcpy(p,&tmp,2);
   	p+=2;
  		
  	/*transport version*/
  	memset(p,0,32);
  	//strcpy(p,"dmodem");
    strcpy(p, "DModem-1.0");
		//doLog(0,"Transport Version %s\n",p);
  	p+=32;
  					
  	/*opt len*/
  	tmp= SHORT_TO_L_ENDIAN(0x0D);/*pasar a 0x0D por los dos bytes del TxFramTO*/
  	memcpy(p,&tmp,2);
  	p+=2;
		  	
  	/*transport options*/
  	txTO= LONG_TO_L_ENDIAN(DMODEM_TXFRAME_TO_DEF); /*TxFrameTO Pasarlo a 4 bytes */
  	memcpy(p,&txTO,4);
  	p+=4;
  			
  	tmp= SHORT_TO_L_ENDIAN(DMODEM_RXBYTE_TO_DEF); /*RxByteTO*/
  	memcpy(p,&tmp,2);
  	p+=2;
		  	
  	*p= DMODEM_MAX_RETIRES_DEF; /*MaxRetries*/
  	//memcpy(p,&tmp,2);
  	p++;	
  	
  	tmp= SHORT_TO_L_ENDIAN(DMODEM_MAX_DATA_SIZE_DEF); /*MaxDataSize*/
  	//doLog(0,"--DMODEM_TXFRAME_TO_DEF PIC %d",DMODEM_TXFRAME_TO_DEF);
  	memcpy(p,&tmp,2);
  	p+=2;
		
  	tmp= SHORT_TO_L_ENDIAN(900); /*TxUpLayerTO*/
  	memcpy(p,&tmp,2);
  	p+=2;
		
  	tmp= SHORT_TO_L_ENDIAN(900); /*RxUpLayerTO*/
  	memcpy(p,&tmp,2);
  	p+=2;
		
  	/*application family*/
  	memset(p,0,32);
  	strcpy(p,"ptsd");			
		//doLog(0,"Application Family %s\n",p);		
  	p+=32;
  	
  	/*application version*/
  	memset(p,0,32);
  	strcpy(p,MAX_PTSD_APP_VERSION);			
		//doLog(0,"App Version %s\n",p);
  	p+=32;
  	
  	/*opt len*/
  	tmp= SHORT_TO_L_ENDIAN(0x02); /*OptLen2*/
  	memcpy(p,&tmp,2);
  	p+=2;

  	/*PTSDRX_TO */
  	tmp= SHORT_TO_L_ENDIAN(900); /*PTSDRX_TO*/
  	memcpy(p,&tmp,2);
  	p+=2;
		
  	f = fopen("log.txt", "w+b");
    fwrite(aMessage,1,0x73+3,f);		
    fclose(f);	
    
  	return 0x73+3;
  }
}

- (BOOL) checkForAcceptedResponse: (char *) aMessage
{
	/* Mensaje de aceptacion : [0x02 0x0000]  */
	return aMessage[0] == 2 && aMessage[1] == 0 && aMessage[2] == 0;
}

/**/
- (void) setTelcoType: (int) aTelcoType
{
	myTelcoType = aTelcoType;
}

/**/
- (char*) getSystemVersionByTelcoType: (int) aTelcoType
{
	int i;

	for (i = 0; i < sizeOfArray(versions); ++i)
		if (versions[i].systemTypeId == aTelcoType) return versions[i].ptsdSystemTypeVersion;

	return NULL;
}

/**/
- (char*) getPTSDVersion
{
	return MAX_PTSD_APP_VERSION;
}

@end

