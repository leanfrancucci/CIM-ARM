#ifndef AUDIT_H
#define AUDIT_H

#define AUDIT id

#include <Object.h>
#include "User.h"
#include "ctapp.h"
#include "Event.h"




// USO DE PC
#define AUDIT_WS_UNKNOWN_WORK_STATION		      200	/** Se conecto una PC desconocida al servidor */
#define AUDIT_WS_RECOVERY_ERROR					      201	/** Error recuperando cuenta por corte de energia */
#define	AUDIT_WS_OPEN_MAINTENANCE				      202	/** Se abre un puesto para mantenimiento */
#define AUDIT_WS_CLOSE_MAINTENANCE			      203	/** Se cierra un puesto abierto para mantenimiento */
#define AUDIT_WS_TARIFF_TABLE_CHANGE		      204	/** Se modifico la tabla de tarifas */
#define AUDIT_WS_OPEN_DIFFERENT_TARIFF_GROUP	205	/** Puesto abierto en otro grupo de tarifacion */
#define AUDIT_WS_INIT_TOLERANCE_CHARGE_FREE		206	/** No se cobra por no llegar a la tolerancia minima */
#define AUDIT_WS_PASSWORD_CHANGE				207				/** Cambio el password de administrador de los puestos */
//#define AUDIT_WS_WORK_STATION_SETTINGS_CHANGE	208	/** Cambio la configuracion de puesto */
#define AUDIT_WS_GENERAL_SETTINGS_CHANGE			209	/** Cambio la configuracion general  */
#define AUDIT_WS_TARIFF_TABLE_CHECKSUM_ERROR  210	/** Error de checksum en la tabla de tarifas */
#define AUDIT_WS_ACCOUNT_ADJUST								211	/** Se realizo un ajuste sobre la cuenta */
#define AUDIT_WS_GENERAL_SETTING							212	/** Se modificaron los seteos generales de los puestos */
#define AUDIT_WS_ACTIVATED							      213	/** Se activo un puesto */
#define AUDIT_WS_DEACTIVATED							    214	/** Se desactivo un puesto */
#define AUDIT_WS_UPDATED    							    215	/** Se modifico un puesto */
#define AUDIT_TAX_BY_WS_INSERTED              216 /** Asociacion de impuesto a puestos */
#define AUDIT_TAX_BY_WS_DELETED               217 /** Baja asociacion de impuesto a puestos */

// ENVIO / RECEPCION DE SMS
#define AUDIT_SMS_UPDATE_CONFIGURATION        300 /** Se actualizo la configuracion */
#define AUDIT_SMS_SENT_ERROR                  301 /** No se pudo enviar el mensaje SMS, adicional: codigo de error */
#define AUDIT_SMS_DEVICE                      302 /** Ocurrio un error con el dispositivo, adicional: codigo de error */
#define AUDIT_SMS_UNKNOWN_SENDER              303 /** No se conoce el remitente, no hay ninguna cabina a la cual asociar el numero, adicional: direccion */
#define AUDIT_SMS_FORBIDDEN_NUMBER            304 /** El numero esta prohibido, adicional: direccion */
#define AUDIT_SMS_DESTINATION_IN_USE          305 /** El destinatario esta utilizado desde otra cabina, adicional: direccion */
#define AUDIT_SMS_DISCARD_INCOMING_SMS        306 /** Descarta el SMS entrante ya que el servicio no esta habilitado */
#define AUDIT_SMS_DISCARD_INCOMING_MAIL       307 /** Descarta el mail entrante ya que el servicio no esta habilitado */
#define AUDIT_SMS_INVALID_SIM                 308 /** El SIM es invalido o no esta habilitado */
#define AUDIT_SMS_COM_PORT_ERROR              309 /** Error en el puerto COM */
#define AUDIT_SMS_INVALID_CODING              310 /** Codificacion del mensaje invalida, adicional: direccion */


// GENERALES
#define UNHANDLE_EXCEPTION						  999	  // Excepcion no capturada

#define AUDIT_ADDITIONAL_SIZE 20
#define FIELD_NAME_SIZE   50
#define VALUE_SIZE        40


typedef enum {
	SystemType_NOT_DEFINED,
	SystemType_CIM,
	SystemType_CMP,
  SystemType_PIMS
} SystemType;


typedef struct {
  long field;
  char oldValue[VALUE_SIZE + 1];
  char newValue[VALUE_SIZE + 1];
	long oldReference;
	long newReference;
} ChangeLog;

@interface	Audit : Object
{
	int myAuditId;
	int myEventId;
	int myUserId;
	datetime_t myDate;
	int myStation;
	char myAdditional[AUDIT_ADDITIONAL_SIZE + 1];
	
	int mySystemType;
  COLLECTION myChangeLog;
	BOOL myAlwaysLog;
}

/**
 *
 */
- (void) setAuditId: (int) anAuditId;
- (void) setEventId: (int) aEventId;
- (void) setUserId: (int) aUserId;
//- (void) setSystemType: (int) aSystemType;
- (void) setAuditDate: (datetime_t) aDate;
- (void) setStation: (int) aStation;
- (void) setAdditional: (char *) anAdditional;

/**
 *
 */
- (int) getAuditId;
- (int) getEventId;
- (int) getUserId;
- (int) getSystemType;
- (datetime_t) getAuditDate;
- (int) getStation;
- (char *) getAdditional;

/**
 *
 */
- (unsigned long) saveAudit;

/**/
- initAudit: (USER) aUser eventId: (int) anEventId additional: (char*) anAdditional station: (int) aStation logRemoteSystem: (BOOL) logRemoteSystem;

/**/
- initAuditWithCurrentUser: (int) anEventId additional: (char*) anAdditional station: (int) aStation logRemoteSystem: (BOOL) logRemoteSystem;

/**
 *  Funciones para log de cambios, se llama, segun el tipo de datos a comparar a una funcion u otra.
 *  La funcion evalua si el valor contenido en oldValue es diferente al de newValue, en cuyo caso
 *  agrega el cambio a una lista (identificado por el campo FieldName).
 */


- (BOOL) logChangeAsPassword: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (char *) anOldValue newValue: (char *) aNewValue oldReference: (long) anOldReference newReference: (long) aNewReference;

/* D A T E  T I M E*/
- (BOOL) logChangeAsDateTime: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (datetime_t) anOldValue newValue: (datetime_t) aNewValue; 
- (BOOL) logChangeAsDateTime: (int) aResourceId oldValue: (datetime_t) anOldValue newValue: (datetime_t) aNewValue;
- (BOOL) logChangeAsDateTime: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (datetime_t) anOldValue newValue: (datetime_t) aNewValue oldReference: (long) anOldReference newReference: (long) aNewReference;


/* S T R I N G */
- (BOOL) logChangeAsString: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (char *) anOldValue newValue: (char *) aNewValue;
- (BOOL) logChangeAsString: (int) aResourceId oldValue: (char *) anOldValue newValue: (char *) aNewValue;
- (BOOL) logChangeAsString: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (char *) anOldValue newValue: (char *) aNewValue oldReference: (long) anOldReference newReference: (long) aNewReference;


/* I N T E G E R */
- (BOOL) logChangeAsInteger: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (int) anOldValue newValue: (int) aNewValue; 
- (BOOL) logChangeAsInteger: (int) aResourceId oldValue: (int) anOldValue newValue: (int) aNewValue;
- (BOOL) logChangeAsInteger: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (int) anOldValue newValue: (int) aNewValue oldReference: (long) anOldReference newReference: (long) aNewReference;

 
/* B O O L E A N */
- (BOOL) logChangeAsBoolean: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (int) anOldValue newValue: (int) aNewValue;
- (BOOL) logChangeAsBoolean: (int) aResourceId oldValue: (int) anOldValue newValue: (int) aNewValue;
- (BOOL) logChangeAsBoolean: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (int) anOldValue newValue: (int) aNewValue oldReference: (long) anOldReference newReference: (long) aNewReference;


/* M O N E Y */
- (BOOL) logChangeAsMoney: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (money_t) anOldValue newValue: (money_t) aNewValue; 
- (BOOL) logChangeAsMoney: (int) aResourceId oldValue: (money_t) anOldValue newValue: (money_t) aNewValue;
- (BOOL) logChangeAsMoney: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (money_t) anOldValue newValue: (money_t) aNewValue oldReference: (long) anOldReference newReference: (long) aNewReference;


/**/
- (BOOL) logChangeAsPassword: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (char *) anOldValue newValue: (char *) aNewValue; 
- (BOOL) logChangeAsPassword: (int) aResourceId oldValue: (char *) anOldValue newValue: (char *) aNewValue oldReference: (long) anOldReference newReference: (long) aNewReference;


/* R E S O U R C E  S T R I N G */
- (BOOL) logChangeAsResourceString: (BOOL) aLogAlways resourceId: (int) aResourceId resourceStringBase: (int) aResourceStringBase oldValue: (int) anOldValueResId newValue: (int) aNewValueResId; 
- (BOOL) logChangeAsResourceString: (int) aResourceId resourceStringBase: (int) aResourceStringBase oldValue: (int) anOldValueResId newValue: (int) aNewValueResId;
- (BOOL) logChangeAsResourceString: (BOOL) aLogAlways resourceId: (int) aResourceId resourceStringBase: (int) aResourceStringBase oldValue: (int) anOldValueResId newValue: (int) aNewValueResId oldReference: (long) anOldReference newReference: (long) aNewReference;


/**
 *	Configura si siempre debe loguear los cambios para esta auditoria.
 *	Tiene prioridad por sobre lo que se envie a cada funcion.
 */
- (void) setAlwaysLog: (BOOL) aValue;

/**
 *  Devuelve el log de cambios, puede ser NULL si nunca se llamo a ningun funcion logChangeAsXxx().
 */
- (COLLECTION) getChangeLog;


/**
 *  Activa o desactiva globalmente el log de cambios.
 *  Es un metodo estatico, a partir del momento que se llama a esta funcion se comienzan a
 *  loguear los cambios o se dejan de loguear, segun el caso.
 */
+ (void) setActivateChangeLog: (BOOL) aValue; 

/**
 *
 */

+ (long) auditEventCurrentUser: (int) anEventId additional: (char*) anAdditional station: (int) aStation logRemoteSystem: (BOOL) logRemoteSystem;

+ (long) auditEventWithDate: (USER) aUser eventId: (int) anEventId additional: (char*) anAdditional station: (int) aStation datetime: (datetime_t) aDateTime logRemoteSystem: (BOOL) logRemoteSystem;

+ (long) auditEventCurrentUserWithDate: (int) anEventId additional: (char*) anAdditional station: (int) aStation datetime: (datetime_t) aDateTime logRemoteSystem: (BOOL) logRemoteSystem;

+ (long) auditEvent: (int) anEventId additional: (char*) anAdditional station: (int) aStation logRemoteSystem: (BOOL) logRemoteSystem;

+ (long) auditEvent: (USER) aUser eventId: (int) anEventId additional: (char*) anAdditional station: (int) aStation logRemoteSystem: (BOOL) logRemoteSystem;

@end

#endif
