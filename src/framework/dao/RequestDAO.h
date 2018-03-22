#ifndef REQUEST_DAO_H
#define REQUEST_DAO_H


#define REQUEST_DAO id

#include <Object.h>
#include "ctapp.h"

#include "system/db/all.h"
#include "DataObject.h"
#include "Request.h"

 
/**
 *	Clase base abstracta para manejar la persistencia de todos los tipos de Request
 *
 */
@interface RequestDAO: DataObject
{	
	ABSTRACT_RECORDSET 		myRecordSet;
	ABSTRACT_RECORDSET 		mySubRecordSet;
}


/**/
+ getInstance;

#if 0
/**
 * Visibility: Protected
 * Metodo hook reimplementado por cada subclase que devuelve el
 * nombre de la tabla en donde se alamacenan los request del tipo determinado
 */
- (char *) getSubTableName;

/**
 * Visibility: Protected
 * Metodo hook que devuelve la unica instancia del Request del subtipo adecuado
 *  {A}
 */
- (REQUEST) getRequestInstance;

/**
 * Visibility: Protected
 * Metodo hook que almacena el Request en la tabla correspondiente
 *  {A}
 */
- (void) loadRequestToRecordSet: (REQUEST) aRequest recordSet: (ABSTRACT_RECORDSET) aRecordSet;

/**
 * Visibility: Protected
 * Metodo hook que carga el estado del request desde la tabla correspondiente
 *  {A}
 */
- (void) loadRequestFromRecordSet: (REQUEST) aRequest recordSet: (ABSTRACT_RECORDSET) aRecordSet;

/**
 * Metodos de clase
 */ 
 
/**
 * Devuelve un nuevo RecordSet 
 */
+ (ABSTRACT_RECORDSET) createRequestRecordSet;

/**
 * Devuelve el Request del subtipo adecuado en base al identificador de Request dado.
 */
+ (REQUEST) getRequestById: (unsigned long) anId;

/**
 * Devuelve el Request del subtipo adecuado en base a aRequestType
 * almacenado en la tabla de requests.
 */
+ (REQUEST) getRequestById: (unsigned long) anId requestType: (int) aRequestType;
	
/**
 * Devuelve el Request del subtipo adecuado en base a los datos obtenidos del 
 * registro actual del recordset de Request general.
 */
+ (REQUEST) getRequestFromRecordSet: (ABSTRACT_RECORDSET) aRecordSet;

/**
 * Devuelve un Recordset con los Request Pendientes.
 */
+ (ABSTRACT_RECORDSET) getNotAppliedRequestsRecordSetByRol: (int) aTelesupRol
									fromMessageId: (unsigned long) aFromId toMessageId: (unsigned long) aToId;

/**
 * Devuelve un Recordset con los Request ya aplicados (ejecutados)
 */
+ (ABSTRACT_RECORDSET) getAppliedRequestsRecordSetByRol: (int) aTelesupRol
									fromMessageId: (unsigned long) aFromId toMessageId: (unsigned long) aToId;

#endif
																												
@end

#endif
