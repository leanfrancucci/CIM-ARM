#ifndef TI_REMOTE_PROXY_H
#define TI_REMOTE_PROXY_H

#define TI_REMOTE_PROXY id

#include <Object.h>
#include "ctapp.h"

#include "RemoteProxy.h"
#include "ClientSocket.h"

/*
 *	Implementa el proxy remoto para la telesupervisión con Telefonica
 */
@interface TIRemoteProxy: RemoteProxy
{
	/*socket para establecer conexion*/
	CLIENT_SOCKET ctSocket;
	
	char *myMessage;
	char aParameters[15][25];
}

- (int) initConnection: (char * ) ipAddress port: (int) portNumber;

- (void) login: (char*) aUserName
			   password: (char*) aPassword
		     extension: (char*) anExtension
		     appVersion: (char*) anAppVersion;
			
/**
*	Parsea la respuesta del imas
*	@param bSize cantidad de bytes contenidos en el buffer de recepcion
*	@return cantidad de parametros de la respuesta y deja en cmdParameters 
*   los parametros en orden
*/
-(int) parseAnswer: (int) bSize;


/**
*	Espera y alamcena un mensaje del server
*	@param rSize cantidad de datos a recibir
*	@return retorna la cantidad recepcionada -1 en caso de error
*/
-(int) receiveMessage: (int) rSize;

/**
*	Envia un mensaje del protocolo
*	@param pData mensaje a enviar
*	@return si el envio fue exitoso o no
*/
- (void) sendMessage;

/**
*	Envia el paquete y verifica si la respuesta del 
*	imas es correcta ( esto ultimo solo validando la cantidad de
*	parametros esperados)
*	@param pData buffer a enviar finalizado con \n
*	@param rSize tamaño del buffer de recepcion
*	@param pQty cantidad de parametros esperados en la respuesta
*	@return paquete valido o no
*/
-(int) sendAndVerifyPkt:(char *)pData size:(int) rSize qty:(int) pQty;

/**
*	Retorna el parametro solicitado del mensaje recibido 
*	@param pNumber numero de parametro a solicitar
*	@return parametro solicitado
*/
- (char *) getParameterNumber:(int) pNumber;

/**
*	Retorna el mensaje recibido
*	@return mensaje recibido
*/
- (char *) getMsgReceived;

/**
*	Envia un buffer de un tamaño especificado. A veces se necesita enviar un mensaje que no necesariamente es string entonces se envia ese buffer por medio de esta funcion.
*	@param pData buffer a enviar
*	@param dQty cantidad de datos a enviar
*	@return si el envio fue exitoso o no
*/
-(int) sendBuffer:(char *) pData qty:(int)dQty;	 


- (int) sendVersion: (char*) versionSup;
@end

#endif
