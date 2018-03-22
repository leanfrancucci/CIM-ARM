#include <time.h>
#include "AESencript.h"
#include "net.h"
#include "dynamicPin.h"
#include "log.h"


static unsigned char secretWord[32] = {'P','a' ,'s','s','w','o','r' ,'d','P','a' ,'s','s','w','o','r' ,'d'};
static char *charSet = "0123456789ABCDEF";
static char buffer[50];

//este no mete espacios en blanco en el medio de cada hexa char, por eso 
// no puedo reutilizar la funcion de logcomm
char *getHexFrame2(unsigned char *data, int qty)
{
	char *str;
	int i;

	str = buffer;
    for ( i = 0; i < qty ; ++i ){
        *str = charSet[data[i] / 16];
        ++str;
        *str = charSet[data[i] % 16];
        ++str;
	}    
    *str = '\n';
    ++str;
    *str = 0;
	
    return buffer;
}

void doGeneratePin ( char *closingCode, char * newPIN, char * newDuress )
{
	int i;
	static char myClosingCode[17];
	unsigned char *newPinTemp;
	
	sprintf(myClosingCode, "%s%s",closingCode, closingCode);

	newPinTemp = Cipher(myClosingCode, secretWord);
	for(i=0;i<8;i++){
	    newPIN[i]= newPinTemp[i] % 10 + '0';
		if ( i == 7 ) 
			newDuress[i]= (newPinTemp[i] + 1 ) % 10 + '0';
		else
			newDuress[i]=newPIN[i];
	}
	newPIN[8]=0;
	newDuress[8]=0;
}

void generateNewPin( int idUsuario, char *newClosingCode, char *oldPIN, char *newPIN, char *newDuress  )
{
	unsigned char *codigoCierre; 
	unsigned char * codigoCierreFinal;
	long fechaHoraApertura;
	//long idUsuario;
	static unsigned char plainText[100];
  	// la voy a usar de clave de encriptacion para el codigo de cierre:
	unsigned char macAddress[32];

	fechaHoraApertura = time(NULL);
	if_netInfo  ("eth0", macAddress);
//	doLog(0,"MAC ADDRESS: %s\n", macAddress);
	
 	sprintf(plainText, "%d%d%s", fechaHoraApertura, idUsuario, oldPIN );
	codigoCierre = Cipher(plainText, macAddress);
	codigoCierreFinal = getHexFrame2(codigoCierre, 16);
	codigoCierreFinal[8]='\0';
	strcpy(newClosingCode, codigoCierreFinal);

	doGeneratePin ( codigoCierreFinal, newPIN, newDuress );
      //  doLog(0,"%s\n", newPIN);
}
