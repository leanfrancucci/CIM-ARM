#ifndef REQUEST_H
#define REQUEST_H

#define REQUEST id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"

#include "RemoteProxy.h"
#include "InfoFormatter.h"
#include "TelesupExcepts.h"
#include "TelesupErrorManager.h"

#include "ReqTypes.h"


enum 
{
	 NO_INFO_FILTER = 0
	,NOT_TRANSFER_INFO_FILTER
	,ID_INFO_FILTER
	,DATE_INFO_FILTER
	,NUMBER_INFO_FILTER 
}; 

/** Listado de acciones generales */
typedef enum
{

		 NO_REQ_OP = 0
		,ACTIVATE_REQ_OP
		,DEACTIVATE_REQ_OP 
		,ADD_REQ_OP
		,REMOVE_REQ_OP
		,SETTINGS_REQ_OP
		,LIST_REQ_OP
		
} ENTITY_REQUEST_OPS;


/**/
enum {
	
	 GENERAL_REQUEST_TYPE = 0
	,GET_REQUEST_TYPE
	,SET_REQUEST_TYPE

	,GET_FILE_REQUEST_TYPE	
	,PUT_FILE_REQUEST_TYPE

	,GET_DATA_FILE_REQUEST_TYPE	
};


/**
 * Define el tipo abstracto de las clases que implementan
 * las solicitudes que recibe el sistema de telesupervision.
 * Las subclases de Request deben ser calses <<bisingleton>>
 * Esto es, definen dos instancias: una para el Request normal
 * y otra para el Request de restauracion utilizado en las configuraciones 
 * diferidas temporales.
 */
@interface Request: Object /** {Abstract} */
{	
	unsigned long		myReqId;	
	int 				myReqType;
	ENTITY_REQUEST_OPS	myReqOperation;
	int					myReqTelesupId;
	int 				myReqTelesupRol;
	int					myReqUserId;
	
	BOOL 				myReqExecuted;
	BOOL 				myReqFailed;
	int 				myReqErrorCode;

	DATETIME			myReqInitialVigencyDate;
	DATETIME			myReqFinalVigencyDate;
		
	unsigned long		myMessageId;
	unsigned long		myJobId;
	BOOL				myJobable;
	
	TELESUP_ERROR_MANAGER	myTelesupErrorMgr;	
	REMOTE_PROXY 		myRemoteProxy;
	INFO_FORMATTER		myInfoFormatter;
	BOOL	myFreeAfterExecute;
}

/**
 * Devuelve una instancia normal del Request
 * No debe ser invocado desde afuera: las instancias
 * se piden con getInstance() o getRestoreInstance()
 */
+ new;

/**
 * Devuelve la instancia normal de la clase (no la de restauracion)
 *
 */
+ getInstance;

/**
 * Devuelve la referencia a la variable de la unica instancia del Request normal.
 * Debe ser reimplementado por cada subclase de Request.
 */
+ getSingleVarInstance;

/**
 * Configura el valor de la unica instancia del Request normal.
 * Debe ser reimplementado por cada subclase de Request.
 * @param id : el valor de la unica instancia normal del Request.  
 */
+ (void) setSingleVarInstance: (id) aSingleVarInstance;

/**
 * Devuelve la instancia de restauracion de la clase
 */
+ getRestoreInstance;

/**
 * Devuelve la referencia a la variable de la unica instancia del Request de restauracion.
 * Debe ser reimplementado por cada subclase de Request.
 */
+ getRestoreVarInstance ;

/**
 * Configura el valor de la unica instancia del Request de restauracion.
 * Debe ser reimplementado por cada subclase de Request.
 * @param id : el valor de la unica instancia del Request de restauracion.  
 */
 + (void) setRestoreVarInstance: (id) aRestoreVarInstance; 


/**
 *
 */
- initialize;

/**
 * Se imprime el request para la salida estandar
 *
 */
- (void) printRequest;

/**
 * Limpia el estado del Request.
 * Como cada subtipo de Request es un singleton el metodo clear
 * se llama para reutilizar el Request.
 * El metodo llama a clearRequest() que realiza una limpieza de los
 * subtipos de Request.
 */
- (void) clear;

/**
 * Limpia el estado de los subtipos de Request.
 * Es llamao por clear() en Request.
 * Debe ser reimplementado, si es necesario, por los subtipos de Request 
 */
- (void) clearRequest;

/**
 *
 */
- (void) setTelesupErrorManager: (TELESUP_ERROR_MANAGER) aTelesupErrorMgr;	
- (TELESUP_ERROR_MANAGER) getTelesupErrorManager;

/**
 * El esquema de telesupervision
 */
- (void) setReqTelesupId: (int) aReqTelesupId;
- (int) getReqTelesupId;

/**
 * Identificador autonumerico de cada request almacenado
 */
- (void) setReqId: (unsigned long) anId;
- (unsigned long) getReqId;

/**
 * Consulta y configura la fecha de vigencia inicial del Request.
 *
 */
- (void) setReqInitialVigencyDate: (DATETIME) anInitialVigencydate;
- (DATETIME) getReqInitialVigencyDate;


/**
 * Consulta y configura la fecha de vigencia final del Request.
 *
 */
- (void) setReqFinalVigencyDate: (DATETIME) aFinalVigencyDate;
- (DATETIME) getReqFinalVigencyDate;

/**
 * Configura y consulta el tipo de Request
 */
- (void) setReqType: (int) aRequestType;
- (int) getReqType;

/**
 * Configura y consulta la accion que debe ejecutar el request.
 * Se utiliza en los SetEntityRequest para saber si tiene que ejecutar 
 * un activate, deactivate, add, remove o set de la entidad.
 * Los GetRequest no lo usan pero esta disponible para usarse
 */
- (void) setReqOperation: (ENTITY_REQUEST_OPS) aReqOperation;
- (ENTITY_REQUEST_OPS) getReqOperation;

/**
 * Configura el Request con el rol con el cual el sistema remoto
 * esta realizando la telesupervision.
 *
 */
- (void) setReqTelesupRol: (int) aTelesupRol;
- (int) getReqTelesupRol;

/**
 * Establece si el Request fue ejecutado - exitosamente o no -.
 */
- (void) setReqExecuted: (BOOL) aValue;
- (BOOL) isReqExecuted;

/**
 * Establece si el Request fue ejecutado con fallo.
 */
- (void) setReqFailed: (BOOL) aValue;
- (BOOL) isReqFailed;
	
/**
 * Si el Request fue ejecutado con fallo establece el codigo de error correspondiente.
 */
- (void) setReqErrorCode: (int) aValue;
- (int) getReqErrorCode;


/**
 * Configura elusuario que esta usando el Request (en realidad la telesupervision toda).
 * Cuando se crea el request se le asigna el usuario que esta ejecutando el 
 * proceso de telesupervision.
 *
 */
- (int) getUserId;
- (void) setUserId: (int) aUserId;

/**
 * Configura el proxy remoto que usa el Request
 *
 */
- (void) setReqRemoteProxy: (REMOTE_PROXY) aRemoteProxy;
- (REMOTE_PROXY) getReqRemoteProxy;

/**
 * Configura el formateador de informacion a transferor predeterminado.
 * Lo utilizan los Request que transsfieren informacion.
 */
- (void) setReqInfoFormatter: (INFO_FORMATTER) anInfoFormatter;
- (INFO_FORMATTER) getReqInfoFormatter;

/**
 * El identificador al Job al que pertenece el Request.
 * El valor 0 indica que el request no pertence a ningun Job.
 */ 
- (void) setReqJobId: (unsigned long) aJobId;
- (unsigned long) getReqJobId;

/**
 * Un identificador de mensaje generado por el sistema de telesupervision central.
 * Se utiliza para realizar el seguimiento de los request ejecutados en el marco
 * de un Job.
 */
- (void) setReqMessageId: (unsigned long) aMessageId;
- (unsigned long) getReqMessageId;

/**
 * Indica si el request puede ser recibido dentro de un job.
 */
- (void) setJobable: (BOOL) aValue;
- (BOOL) isJobable;
	
/**
 * Almacena el request utilizando los servicios de persistencia
 */
- (void) saveRequest;

/**
 * Devuelve la instancia DAO que maneja la persistencia de la subclase
 * de Request espec�ica. 
 * {A} Debe ser reimplementado por cada subclase
 */
- (DATA_OBJECT) getRequestDAO;

/**
 * Asigna el estado completo de self hacia anObject
*  (invoca al hook assignStateRequestTo()) 
 * @param anObject Request es el request al que se debe copiar el estado del 
 * sender del mensaje 
 */
- (void ) assignRequestTo: (id) anObject;

/**
 * Visivility: Protected
 * Hook qebe ser reimplementado por cada subclases.
 * Debe asginar el estado del request (self) al request anObject.
 * @param anObject Request es el request al que se debe copiar el estado del 
 * sender del mensaje 
 */
- (void) assignStateRequestTo: (id) anObject;


/**
 *  Devuelve un nuevo Request con la configuracion del la parte del
 *  estado actual del sistema que el Request gestiona.
 *  El Request devuelto se utiliza para, a futuro, volver el estado
 * del sistema al estado actual (antes de ejecutarse el Request original).
 */
- (REQUEST) getRestoreRequest;

/**
 * Configura el estado del Request obtieniendo los valores desde el facade adecuado.
 * Este metodo es implementado por cada Request concreto.
 * Llama a assignRestoreRequestInfo() 
 */
- (void) assignRestoreInfo;

/**
 * Visibility: Protected
 * Configura el estado del Request obtieniendo los valores desde el facade adecuado.
 * Este metodo es implementado por cada Request concreto.
 * Implementado vacio.
 */
- (void) assignRestoreRequestInfo;


/**
 * Metodo template que procesa un Request ejecutando los
 * los metodos hook:
 *    beginRequest();
 *    executeRequest();
 *    endRequest()
 *
 */
- (void) processRequest;


/**
 * Visibility: Protected
 *
 */
- (void) beginRequest;


/**
 * Visibility: Protected
 *
 */
- (void) executeRequest;


/**
 * Visibility: Protected
 *
 */
- (void) endRequest;

/**
 * Marca el Requests como ejecutado.
 * No almacena el Request en e medio de persistencia.
 * Visibility: Public
 */
- (void) requestExecuted;
 
/**
 * Marca el request como ejecucion fallida configurando el codigo de
 * error con el que fallo la ejecucion.
 * No almacena el Request en e medio de persistencia.
 * @param anErrorcode es el codigo de error por el que fallo la ejecucion del Request.
 * Visibility: Public 
 */
- (void) requestFailedWithErrorCode: (int) anErrorCode;

/** Marca si debe librerar el request luego de ejecutarlo */
- (void) setFreeAfterExecute: (BOOL) aValue;
- (BOOL) getFreeAfterExecute;

@end

#endif
