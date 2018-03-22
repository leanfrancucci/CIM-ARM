#ifndef REMOTEPROXY_H
#define REMOTEPROXY_H

#define REMOTE_PROXY id

#include <Object.h>
#include "ctapp.h"
#include "system/io/all.h"

#include "FileTransfer.h"

#include "TelesupViewer.h"

#include "TelesupDefs.h"
//#include "TelesupParser.h"

/*
 *	Define el tipo de los proxies remotos utilizados
 *  para comunicar el sistema con el sistema remoto.
 */
@interface RemoteProxy: Object /* {Abstract} */
{
	TELESUP_VIEWER		myTelesupViewer;

	//TELESUP_PARSER 		myTelesupParser;
	
	READER				myReader;
	WRITER				myWriter;
	char				mySystemId[ TELESUP_SYSTEM_ID_LEN + 1 ];
	int 				myTelesupRol;	
}

/**
 * Configura el observer de telesuprvision.
 * @param aTelesupViewer no puede ser nulo.
 */
- (void) setTelesupViewer: aTelesupViewer;
- (TELESUP_VIEWER) getTelesupViewer;

/**
 * Configura el identificador de sistema local.
 */
- (void) setSystemId: (char *) aSystemId;
- (char *) getSystemId;

/*
 * Configura el identificador de rol del sistema de telesupervision remoto
 */
- (void) setTelesupRol: (int) aTelesupRol;	
- (int) getTelesupRol;
	
/*
 * Configura el parser de telesupervision que conoce el protocolo implementado.
 * 
 */	
//- (void) setTelesupParser: (TELESUP_PARSER) aTelesupParser;

/*
 * Configura el Reader por el cual el proxy 
 * lee informaci� desde el sistema remoto.
 * 
 */	
- (void) setReader: (READER) aReader;


/*
 * Configura el Writer por donde el proxy 
 * escribe informaci� hacia el sistema remoto.
 * 
 */
 - (void) setWriter: (WRITER) aWriter;

 /**
 * Decodifica el mensaje justo luego de leerlo. Permite que el proxy formatee el mensaje adecuadamente
 * antes que se trabaje con el.
 *
 * En el G2 por ejemplo:
 *	Copia aSourceBuffer en aTargetBuffer eliminando los espacios intermedios molestos 
 * 	de los nombres de los Request, de las lineas entre "   param    =value", 
 * 	y eliminando "\n" de mas (deja solo uno al final de cadalinea), y decodifica los caracteresno imprimibles.
 * 	Controla que no se copien mas de aSize caracteres en aTargetBuffer.
 *
 * De manera predeterminada copia aSourceBuffer en aTargetBuffer.
 *
 * @result (int) devuelve la cantidad de datos resultante luego de formatear el mensaje.
 *
 * @throws TSUP_INVALID_REQUEST_EX si no pudo decodificar correctamente el mensaje.
 * @throws TSUP_MSG_TOO_LARGE_EX
 */
- (int) decodeTelesupMessage: (char *) aTargetBuffer from: (char *) aSourceBuffer size: (int) aSize;

/**
 * Codifica el mensaje justo luego de leerlo. 
 *
 * En el G2 por ejemplo:
 *	Copia aSourceBuffer en aTargetBuffer eliminando los espacios intermedios molestos 
 * 	de los nombres de los Request, de las lineas entre "   param    =value", 
 * 	y eliminando "\n" de mas (deja solo uno al final de cadalinea), y decodifica los caracteresno imprimibles.
 * 	Controla que no se copien mas de aSize caracteres en aTargetBuffer.
 *
 * De manera predeterminada copia aSourceBuffer en aTargetBuffer.
 *
 * @result (int) devuelve la cantidad de datos resultante luego de formatear el mensaje.
 *
 * @throws TSUP_INVALID_REQUEST_EX si no pudo decodificar correctamente el mensaje.
 * @throws TSUP_MSG_TOO_LARGE_EX
 */
- (int) encodeTelesupMessage: (char *) aTargetBuffer from: (char *) aSourceBuffer size: (int) aSize;


/**
 * Configura el protocolo de transferencia de archivos asignandole el reader, writer,
 * el telesup viewer y demas al @param (FILE_TRANSFER) aFileTransfer.
 * Debe ser invocado si o si en cada llamada a sendFile() y a receiveFile().
 *
 */
- (void) configureFileTransfer: (FILE_TRANSFER) aFileTransfer;

/**
 * Lee un mensaje completo desde el otro extremo de la conexion y lo
 * ubica en aBuffer.
 * Lee solo hasta aQty bytes, puede leer menos hasta completar el mensaje o
 * lee solo hasta aQty.
 * Lee y decodifica adecuadamente el mensaje.
 * @result devuelve la cantidad de bytes leidos.
 */
- (int) readTelesupMessage: (char *) aBuffer qty: (int) aQty;

/**
 * Devuelve TRUE si el mensaje en aBuffer esta completo.
 * Por completo se entienede: 
 *		NombreMensaje\n
 *		 Parametros\n
 *		End\n
 * Devuelve FAlSE en caso contrario.
 */
- (BOOL) isRequestComplete: (char *)aBuffer;

/*
 * Devuelve 1 si es el ultimo mensaje (Logout) y
 * 0 en caso contrario
 */
- (BOOL) isLogoutTelesupMessage: (char *) aMessage;

/*
 */
- (BOOL) isLoginTelesupMessage: (char *) aMessage;

/**
 * Devuelve TRUE si encuentra el mensaje "Message\nOk\nEnd\n" 
 */
- (BOOL) isOkMessage: (char *) aMessage;

/*
 * Inicia un nuevo mensaje.
 * Un mensaje se envia mediante la siguiente secuancia:
 *		proxy.newMessage();
 *		proxy.addParamAsXXX("ParamName", value);
 *		proxy.addParamAsXXX("ParamName", value);
 *		. . .
 *		proxy.sendMessage();
 * @param char * el nombre del mensaje a enviar (no lo usan todos los proxy).
 */	
- (void) newMessage: (const char *) aMessageName; 
 
/*
 * Arma el mensaje con el nombre configurado y los parametreos agregados y lo envia.
 * {A}
 */	
- (void) sendMessage;

/*
 * Inicia un nuevo mensaje de respuesta ante una solicitud exitosa.
 */	
- (void) newResponseMessage;

/**
 *  Inicia un nuevo mensaje de respuesta ante una solicitud exitosa pero no concatena la fecha/hora.
 */
- (void) newResponseMessageWithoutDateTime;

/*
 * Envia un mensaje de operacion exitosa al sistema remoto.
 * {A}
 */	
- (void) sendAckMessage;

/*
 * Envia un mensaje de aceptacion de transferecnia de archivos
 * {A}
 */	
- (void) sendAckDataFileMessage;

/*
 * Envia un mensaje de error
 * {A}
 */
- (void) sendErrorRequestMessage: (int) aCode description: (char *) aDescription;


/*
 * Configura el nombre del mensaje
 */	
- (void) setMessageName: (const char *) aMessageName;

/*
 * Agrega la linea @param aLine  en el mensaje.
 * @param (char *) aLine no debe contener el \n final, el metodo lo agrega automaticamente.
 */
- (void) addLine: (char *) aLine;

/**
 * Agregan los parametros al mensaje antes de enviarlo.
 * Para enviar un mensaje se hace:
 *		clearMessage();
 *		setName("MessageName");
 *		addParamAsXXX("ParamName", value);
 *		addParamAsXXX("ParamName", value);
 *		. . .
 *		sendMessage();
 */
 
/*
 * {A}
 */
- (void) addParamAsDateTime: (char *) aParamName value: (datetime_t) aValue;
/**/
- (datetime_t) getParamAsDateTime: (char *) aParamName;


/*
 *
 * {A}
 */
- (void) addParamAsString: (char *) aParamName value: (char *) aValue;
/**/
- (char *) getParamAsString: (char *) aParamName;


/*
 *
 * {A}
 */
- (void) addParamAsLong: (char *) aParamName value: (long) aValue;
/**/
- (long) getParamAsLong: (char *) aParamName;

/*
 *
 * {A}
 */
- (void) addParamAsFloat: (char *) aParamName value: (float) aValue;
/**/
- (float) getParamAsFloat: (char *) aParamName;

/*
 *
 * {A}
 */
- (void) addParamAsInteger: (char *) aParamName value: (int) aValue;
/**/
- (int) getParamAsInteger: (char *) aParamName;

/*
 *
 * {A}
 */
- (void) addParamAsCurrency: (char *) aParamName value: (money_t) aValue;
/**/
- (money_t) getParamAsCurrency: (char *) aParamName;
- (void) addParamAsCurrency: (char *) aParamName value: (money_t) aValue decimals: (int) aDecimals;

/*
 *
 * {A}
 */
- (void) addParamAsBoolean: (char *) aParamName value: (BOOL) aValue;
/**/
- (BOOL) getParamAsBoolean: (char *) aParamName;

/* Transferecnia de informacion */


/**
 * Envia un archivo hacia el otro lado de la conexion.
 * @param (char *) aSourceFileName el nombre del archivo con la ruta completa que se debe trasferir.
 * @param (char *) aTargetFileName el nombre del archivo destino transmitido.
 * @param (BOOL) anAppendMode si se debe agregar el contenido del archivo a otro existente.
 */
- (void) sendFile: (char *)aSourceFileName targetFileName: (char *) aTargetFileName
					appendMode: (BOOL) anAppendMode;

/**
 * Recibe un archivo Desde el sistema de archivos remoto.
 * @param (char *) aSourceFileName es el archivo remoto que se va a recibir. Si el nombre no es
 * vacio entonces controla que el archivo recibido se llame de la misma manera.
 * @param (char *) aTargetFileName es el nombre con el que se debe grabar en el file
 * sistema local el archivo recibido.
 * @result (char *) devuelve el nombre del archivo remoto recibido.
 */
- (char *) receiveFile: (char *)aSourceFileName targetFileName: (char *) aTargetFileName;

/*
 *
 */
- (void) sendCallTrafficFrom: (READER) aReader;

/*
 *
 */
- (void) sendAuditEventsFrom: (READER) aReader;

/*
 *
 */
- (void) sendTextMessagesFrom: (READER) aReader;

/*
 *
 */
- (void) sendHardwareInfoFrom: (READER) aReader;

/*
 *
 */
- (void) sendSoftwareInfoFrom: (READER) aReader;

/**
 *
 */
- (void) appendTimestamp;

- (void) sendAckWithTimestampMessage;

@end

#endif
