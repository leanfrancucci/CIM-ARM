#ifndef TELESUPD_H
#define TELESUPD_H

#define TELESUPD id

#include <Object.h>
#include "ctapp.h"
#include "system/io/all.h"
#include "system/os/all.h"

#include "TelesupViewer.h"

#include "TelesupDefs.h"
#include "TelesupSecurityManager.h"
#include "TelesupParser.h"
#include "RemoteProxy.h"
#include "Request.h"
#include "InfoFormatter.h"
#include "TelesupErrorManager.h"

/*
 *	Define el tipo de las clases que implementan
 *  los diferentes protocolos de telesupervisi�
 */
@interface TelesupD: OThread /* {A} */
{
	int							myTelesupId;
	int							myTelesupRol;
	BOOL						myExecuteLoginProcess;	
	
	char						mySystemId[ TELESUP_SYSTEM_ID_LEN + 1];	
		
	char						myRemoteSystemId[ TELESUP_SYSTEM_ID_LEN  + 1];
	char						myRemoteUserName[ TELESUP_USER_NAME_LEN + 1];
	char						myRemotePassword[ TELESUP_PASSWORD_LEN + 1];

	BOOL						myIsRunning;
	BOOL						myIsActiveLogger;
	
	TELESUP_ERROR_MANAGER		myTelesupErrorMgr;
	READER 						myRemoteReader;
	WRITER 						myRemoteWriter;
	TELESUP_PARSER				myTelesupParser;
	REMOTE_PROXY				myRemoteProxy;
	
	INFO_FORMATTER				myInfoFormatter;
	int							myErrorCode;
	TELESUP_VIEWER				myTelesupViewer;
  BOOL  myGetCurrentSettings;
}

/**
 *	
 */
+ new;

/**
 *	
 */
- initialize;

/**
 * Se utiliza con fines de testing.
 * Especificar en TRUE si se quiere ejecutar el proceso de lin y FALSE
 * en caso contrario.
 */
- (void) setExecuteLoginProcess: (BOOL) aValue;
- (BOOL) getExecuteLoginProcess;

/**/
- (void) setTelesupErrorManager: (TELESUP_ERROR_MANAGER) aTelesupErrorMgr;
- (TELESUP_ERROR_MANAGER) getTelesupErrorManager;

/**
 * Configura el observer de telesuprvision.
 * @param aTelesupViewer no puede ser nulo.
 */
- (void) setTelesupViewer: aTelesupViewer;
- (TELESUP_VIEWER) getTelesupViewer;


/**
 * El esquema de telesupervision
 */
- (void) setTelesupId: (int) aTelesupId;
- (int) getTelesupId;

/**
 * Configura el identificador de sistema local.
 */
- (void) setSystemId: (char *) aSystemId;
- (char *) getSystemId;

/**
 * Configura y obtiene el rol de telesupervision con el que se debe 
 * telesupervisar el sistema.
 * Del rol obtiene el nombre de usuario local y remoto y los 
 * passwords correspondientes.
 * Cuando el sistema es el que inicia la conexion debe configurar el rol de 
 * telesupervision a traves de el setTelesupRol() antes de iniciar el provceso de telesupervision.
 * Este metodo obtiene el nombre de usuario y password con el que debe loguearse al sistema remoto n
 * base al rol configurado.
 */
- (void) setTelesupRol: (int) aTelesupRol;
/**/
- (int) getTelesupRol;

 
/**
 *	Configura el Reader sobre el cual el proceso de 
 *  telesupervision debe ler los mensajes recibidos
 */
- (void) setRemoteReader: (READER) aRemoteReader;

/**
 *	Configura el Writer sobre el cual el proceso de
 *  telesupervision escribe remotamente
 */
- (void) setRemoteWriter: (WRITER) aRemoteWriter;

/**
 * Configura el parser de telesupervision especifico 
 * del protocolo actual
 */	
- (void) setTelesupParser: (TELESUP_PARSER) aTelesupParser;
- (TELESUP_PARSER) getTelesupParser;


/** 
 * Configura el proxy remoto especifico  necesario 
 * para el protocolo de telesupervision actual 
 */	
- (void) setRemoteProxy: (REMOTE_PROXY) aRemoteProxy;
- (REMOTE_PROXY) getRemoteProxy;

/**
 * Configura el formateador de la informacion a transferir
 */
- (void) setInfoFormatter: (INFO_FORMATTER) anInfoFormatter;
- (INFO_FORMATTER) getInfoFormatter;

/**
 * Lee un mensaje completo de telesupervision desde el RemoteProxy y lo decodifica adecuadamente
 * utilizando el TelesupParser que tenga configurado.
 * @param (char *) aBuffer en donde se almacena el contenido del mensaje leido.
 * @param (int) aQty la cantidad maxima de bytes a leer.
 * @result (int) devuelve la cantidad de bytes leidos.
 */
- (int) readMessage: (char *) aBuffer qty: (int) aQty;
			
/**
 * Controla que sea o no un mensaje de fin de telesupervision a traves 
 * del Parser de telesupervsion.
 * @param (char *) aMessage el contenido del mensaje parseado
 * @result devuelve TRUE si es un mensaje de logout o de fin de telesupervision
 * y FALSE en caso contrario..
 */
- (BOOL) isLogoutMessage: (char *) aMessage;
			
/**
 * Configura el request con datos comunes
 *
 */
- (void) configRequest: (REQUEST) aRequest;

/**
 * Ejecuta el proceso de telesupervision correspondiente
 * {A}
 */
- (void) run;

/**
 * Obtiene un Request a partir de aMessage a traves del parser.
 * Si no es un request valido lanza una excepcion.
 * @throws TSUP_INVALID_REQUEST_EX
 */
- (REQUEST) getRequestFrom: (char *) aMessage;


/**
 * Ejecuta un Request.
 * Si el Request tiene fecha de vigencia futura entonces
 * lo agrega a la cola de Request pendientes.
 * No libera el request
 */
- (void) processRequest: (REQUEST) aRequest;

/**
 * Agrega el Request en la cola de pendientes.
 *
 */
- (void) saveRequest: (REQUEST) aRequest;


/**
 * Devuelve TRUE si el hilo de telesupervision esta corriendo, y FALSE en
 * caso contrario.
 */										
- (BOOL) isRunning;

/**
 * Define si el sistema telesupervisado (o sea este sistema) es el que debe
 * iniciar el proceso cruzado de login de telesupervision o no.
 */										
- (void) setIsActiveLogger: (BOOL) anIsActiveLogger;
- (BOOL) isActiveLogger;

/**
 * Arranca el hilo de telesupervision.
 */
- (void) startTelesup;

/**
 * Detiene el hilo de telesupervision.
 */
- (void) stopTelesup;									  	


/**
 * Valida el sistema remoto en base al rol, nombre de usuario y password 
 * recibidos remotamente.
 */
- (void) validateRemoteSystem;

/**
 *	Devuelve el codigo de error correspondiente. 0 Si no hubo ningun error.
 */
- (int) getErrorCode;

/**/
- (void) setGetCurrentSettings: (BOOL) aValue;

@end

#endif
