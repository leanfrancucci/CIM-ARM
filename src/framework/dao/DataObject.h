#ifndef DATA_OBJECT_H
#define DATA_OBJECT_H

#define DATA_OBJECT id

#include <Object.h>
#include "ctapp.h"
#include "DAOExcepts.h"
#include "system/db/all.h"
#include <limits.h>

/**
 * Define los valores buylos para cada tipo de datos
 */
#define	NULL_INT		INT_MIN
#define	NULL_SHORT		SHRT_MIN
#define	NULL_LONG		LONG_MIN
#define	NULL_LONG_LONG	LONG_MIN
#define	NULL_BOOL		-1
#define	NULL_MONEY		LONG_MIN
#define	NULL_DATETIME	LONG_MIN


/**
 *	Clase padre para todos los objetos de la persistencia.
 *	Ver [http://java.sun.com/blueprints/corej2eepatterns/Patterns/DataAccessObject.html]
 *
 */
@interface DataObject : Object
{

} 

+ new;
- initialize;

/**
 *	Carga un objeto a partir del identificador pasado como parametro.
 *	Metodo abstracto, debe ser reimplementado para una entidad especifica (por ejemplo: Call) y
 *	para un mecanismo especifico (por ejemplo: ROP, SQL).
 *
 *	@return el objeto creado y cargado.
 */
- (id) loadById: (unsigned long) anObjectId;

/**
 *	Guarda el objeto pasado como parametro.
 *	Metodo abstracto, debe ser reimplementado para una entidad especifica (por ejemplo: Call) y
 *	para un mecanismo especifico (por ejemplo: ROP, SQL).
 */
- (void) store: (id) anObject;

/**
 *	Carga todos los objetos de una "tabla" y los devuelve en una lista.
 *	Metodo abstracto, debe ser reimplementado para una entidad especifica (por ejemplo: Call) y
 *	para un mecanismo especifico (por ejemplo: ROP, SQL).
 */
- (COLLECTION) loadAll;

/**
 * Valida los campos de un objeto ya sea por nulidad de la correspondiente tabla o validacion de rangos.
 * En el caso que surga algun error en la validacion tira la excepcion correspondiente. 
 * DAO_NULLED_VALUE_EX - En el caso de que algun campo que sea obligatorio sea nulo.
 * DAO_OUT_OF_RANGE_VALUE_EX - En el caso de que el contenido de algun campo se encuentre fuera del rango permitido.
 */

- (void) validateFields: (id) anObject;

/**
 * Carga los valores por defecto de anObject en los campos en los que tiene valores no validos.
 */
- (void) loadDefaultFields: (id) anObject;

/**
 * Realiza la modificacion de un registro en el backup de la tabla basado en una busqueda por id.
 */	
- (void) doUpdateBackupById: (char*) aField value: (unsigned long) aValue backupRecordSet: (ABSTRACT_RECORDSET) aBackupRecordSet currentRecordSet: (ABSTRACT_RECORDSET) aCurrentRecordSet tableName: (char*) aTableName;

/**
 * Realiza la modificacion de un registro en el backup de la tabla basado en una busqueda mas compleja que * solo id.
 */
- (void) doUpdateBackup: (ABSTRACT_RECORDSET) aBackupRecordSet currentRecordSet: (ABSTRACT_RECORDSET) aCurrentRecordSet dataSearcher: (id) aDataSearcher tableName: (char*) aTableName;

/**
 * Realiza el agregado de un registro en el backup de la tabla
 */
- (void) doAddBackup: (ABSTRACT_RECORDSET) aBackupRecordSet currentRecordSet: (ABSTRACT_RECORDSET) aCurrentRecordSet tableName: (char*) aTableName;



/**
 ******* METODOS DE BUSQUEDA Y ACTUALIZACION ESPECIALES ********
 */

/**
 * Realiza la modificacion de un registro en el backup de la tabla DENOMINACIONES
 */	
- (void) doUpdateDenominationBck: (ABSTRACT_RECORDSET) aBackupRecordSet currentRecordSet: (ABSTRACT_RECORDSET) aCurrentRecordSet depositValueType: (int) aDepositValueType acceptorId: (int) anAcceptorId currencyId: (int) aCurrencyId denomination: (id) aDenomination tableName: (char*) aTableName;

/**
 * Realiza la modificacion de un registro en el backup de la tabla DUALL_ACCESS
 */	
- (void) doUpdateDualAccessBck: (ABSTRACT_RECORDSET) aBackupRecordSet currentRecordSet: (ABSTRACT_RECORDSET) aCurrentRecordSet dataSearcher: (id) aDataSearcher dataSearcher2: (id) aDataSearcher2 tableName: (char*) aTableName;

/**
 * Realiza la modificacion de un registro en el backup de la tabla usuarios basado en una busqueda por id.
 */	
- (void) doUpdateBackupUserById: (char*) aField value: (unsigned long) aValue backupRecordSet: (ABSTRACT_RECORDSET) aBackupRecordSet currentRecordSet: (ABSTRACT_RECORDSET) aCurrentRecordSet tableName: (char*) aTableName;

/**
 * Realiza el agregado de un registro en el backup de la tabla de usuario
 */
- (void) doAddUserBackup: (ABSTRACT_RECORDSET) aBackupRecordSet currentRecordSet: (ABSTRACT_RECORDSET) aCurrentRecordSet tableName: (char*) aTableName value: (unsigned long) aValue;

@end

#endif
