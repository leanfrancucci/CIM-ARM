#ifndef PERSISTENCE_H
#define PERSISTENCE_H

#define PERSISTENCE id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"

/**
 *	Factory de objetos de persistencia. Es una clase abstracta y debe ser redefinida para cada
 *	uno de las implementaciones particulares (SQL, ROP, etc.).
 *	Tiene metodos para obtener objetos DAO 
 */
@interface Persistence : Object
{

}

+ (void) setInstance: (id) anObject;

+ (id) getInstance;

/**
 *	Devuelve un objeto para el manejo de persistencia de auditorias.
 */
- (DATA_OBJECT) getAuditDAO;

/**
 *	Devuelve un objeto para el manejo de persistencia de eventos.
 */
- (DATA_OBJECT) getEventDAO;

/**
 * Devuelve un objeto para el manejo de la persistencia de la configuracion regional.
 */
- (DATA_OBJECT) getRegionalSettingsDAO;

/**
 * Devuelve un objeto para el manejo de la persistencia del estado comercial del sistema.
 */
- (DATA_OBJECT) getCommercialStateDAO;

/**
 * Devuelve un objeto para el manejo de la persistencia de los modulos.
 */
- (DATA_OBJECT) getLicenceModuleDAO;

/**
 * Devuelve un objeto para el manejo de la persistencia de la configuracion de los montos.
 */
- (DATA_OBJECT) getAmountSettingsDAO;

/**
 * Devuelve un objeto para el manejo de la persistencia de la configuracion de la impresion.
 */
- (DATA_OBJECT) getPrintingSettingsDAO;

/**
 * Devuelve un objeto para el manejo de la persistencia de la configuracion de las categorias de eventos.
 */
- (DATA_OBJECT) getEventCategoryDAO;

/**
 * Devuelve un objeto para el manejo de la persistencia de la configuracion de los perfiles.
 */
- (DATA_OBJECT) getProfileDAO;

/**
 * Devuelve un objeto para el manejo de la persistencia de la configuracion de los usuarios.
 */
- (DATA_OBJECT) getUserDAO;

/**
 * Devuelve un objeto para el manejo de la persistencia de la configuracion de las telesupervisiones.
 */
- (DATA_OBJECT) getTelesupSettingsDAO;

/**
 * Devuelve un objeto para el manejo de la persistencia de la configuracion de las conexiones.
 */
- (DATA_OBJECT) getConnectionSettingsDAO;

/**
 * Devuelve un objeto para el manejo de la persistencia de la configuracion de las operaciones.
 */
- (DATA_OBJECT) getOperationDAO;

/**
 *
 */
- (DATA_OBJECT) getDepositDAO;

/**
 *
 */
- (DATA_OBJECT) getCurrencyDAO;

/**
 *
 */
- (DATA_OBJECT) getExtractionDAO;

/**
 *
 */
- (DATA_OBJECT) getTempDepositDAO;

/**
 *
 */
- (DATA_OBJECT) getZCloseDAO;

/**
 *
 */
- (DATA_OBJECT) getCimGeneralSettingsDAO;

/**
 *
 */
- (DATA_OBJECT) getBackupsDAO;

/**
 *
 */
- (DATA_OBJECT) getDoorDAO;

/**
 *
 */
- (DATA_OBJECT) getAcceptorDAO;

/**/
- (DATA_OBJECT) getCimCashDAO;

/**/
- (DATA_OBJECT) getCashReferenceDAO;

/**/
- (DATA_OBJECT) getBoxDAO;

/**/
- (DATA_OBJECT) getRepairOrderItemDAO;

- (DATA_OBJECT) getBillSettingsDAO;


@end

#endif
