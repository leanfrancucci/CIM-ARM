#ifndef G2REMOTEPROXY_H
#define G2REMOTEPROXY_H

#define G2REMOTE_PROXY id

#include <Object.h>
#include "ctapp.h"

#include "RemoteProxy.h"
#include "DFileTransferProtocol.h"

/*
 *	Implementa el proxy remoto para la telesupervisi� con el G2
 */
@interface G2RemoteProxy: RemoteProxy
{
  char*	myMessageLine;
	char* myMessage;
	char* myAuxMessage;
	char *myToken;
	STRING_TOKENIZER myTokenizer;
	D_FILE_TRANSFER_PROTOCOL 	myFileTransfer;
	BOOL myPartitionMessage;
}

/*
 *	Copia aSourceBuffer en aTargetBuffer eliminando los espacios intermedios molestos 
 * 	de los nombres de los Request, de las lineas entre "   param    =value", 
 * 	y eliminando "\n" de mas (deja solo uno al final de cadalinea), y decodifica los caracteresno imprimibles.
 * 	Controla que no se copien mas de aSize caracteres en aTargetBuffer.
 */
- (int) decodeTelesupMessage: (char *) aTargetBuffer from: (char *) aSourceBuffer size: (int) aSize;
   

 /**
 * Convierte la cadena aString que son 1 o dos digitos hexadecimales a un valor entero.
 */
- (int) convertG2HexaCodeToInteger: (char *) aString;


- (void) sendMessage: (char*) aBuffer qty: (int) aQty;


- (char *) getRequestName: (char *) aMessage requestName: (char*) aRequestName;


@end

#endif
