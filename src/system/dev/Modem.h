#ifndef MODEM_H
#define MODEM_H

#define MODEM id

#include <Object.h>
#include "comportapi.h"
#include "ComPort.h"

/**
 *	Define el estado del modem.
 */
typedef enum
{
	ModemStatus_OK,
	ModemStatus_NO_DIAL_TONE,
	ModemStatus_NO_CARRIER,
	ModemStatus_BUSY,
	ModemStatus_NO_ANSWER,
	ModemStatus_TIMEOUT,
	ModemStatus_UNKNOWN_ERROR
} ModemStatus;

/**
 *	Encapsula el funcionamiento de un MODEM.
 *	Contiene metodos para discar, cortar, configurar.
 *	Permite obtener un Reader y un Writer para leer o escribir en el dispositivo.
 *
 *	Internamente, maneja un ComPort para las lecturas y escrituras.
 */
@interface Modem : Object
{
	int portNumber;
	char *initScript;
	BaudRateType baudRate;
	COM_PORT comPort;
	int connectTimeout;
	int connectionSpeed;
}

/**
 *	Disca el numero telefonica pasado por parametro y espera a que se realiza la conexion.
 *	Devuelve el estado de la conexion. Ver ModemStatus.
 */
- (ModemStatus) connect: (char*) aPhone;

/**
 *	Setea la velocidad del modem. Por ejemplo: BR_57600.
 *	Por defecto esta configurado en BR_115200.
 */
- (void) setBaudRate: (BaudRateType) aBaudRate;

/**
 *	Configura comandos adicionales que debe ejecutar el modem.
 */
- (void) setInitScript: (char *) aScript;

/**
 *	Setea el timeout de lectura en milisegundos.
 */
- (void) setReadTimeout: (int) aReadTimeout;

/**
 *	Setea el timeout de escritura en milisegundos.
 */
- (void) setWriteTimeout: (int) aWriteTimeout;

/**
 *	Setea el timeout en milisegundos para establecer la conexion.
 *	Este timeout se considera desde el momento en que se disca el numero, hasta el momento
 *	que llega un CONNECT xxxxxx.
 *	Por defecto es 60000 (es decir 60 segundos).
 */
- (void) setConnectTimeout: (int) aConnectTimeout;

/**
 *	Establece el puerto COM que utilizara el MODEM.
 *	Los puertos COM deben ser pasados en formato Windows (1=COM1, 2=COM2, etc...).
 */
- (void) setPortNumber: (int) aPortNumber;

/**/
- (void) open;
- (void) close;

/**
 *	Corta la comunicacion por modem.
 */
- (void) disconnect;

/**
 *	Devuelve el Reader asociado al MODEM.
 */
- (READER) getReader;

/**
 *	Devuelve el Writer asociado al modem.
 */
- (WRITER) getWriter;

/**/
- (int) getConnectionSpeed;

- (void) flush;

+ (BaudRateType) getBaudRateFromSpeed: (int) aSpeed;

@end

#endif
