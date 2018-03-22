#ifndef REPAIR_ORDER_MANAGER_H
#define REPAIR_ORDER_MANAGER_H

#define REPAIR_ORDER_MANAGER id

#include "Object.h"
#include "ctapp.h"
#include "RepairOrderItem.h"


@interface RepairOrderManager:  Object
{
	COLLECTION myRepairOrderItemList;
}

/**
 * 
 */

+ new;
+ getInstance;
- initialize;

/*******************************************************************************************
*																			REPAIR ORDER SETTINGS
*
*******************************************************************************************/

/**
 * Setea los valores correspondientes a la configuracion de los items
 */
- (void) setRepairOrderDescription: (int) anItemId value: (char*) aValue;

/**
 * Devuelve los valores correspondientes a la configuracion de los items
 */
- (char*) getRepairOrderDescription: (int) anItemId;

/**
 * Obtiene un item de la lista
 */
- (REPAIR_ORDER_ITEM) getRepairOrderItem: (int) anItemId;

/**
 * Aplica los cambios en la persistencia realizados al perfil pasado como parametro
 */
- (void) applyRepairOrderChanges: (int) anItemId;

/**
 * Agrega un item
 */
- (int) addRepairOrder:(char*) aDescription;

/**
 * Verifica si se puede eliminar un item
 */
- (void) removeRepairOrder: (int) anItemId;

/**/
- (void) deleteRepairOrder: (REPAIR_ORDER_ITEM) aRepairOrderItem;

/**
 * Agrega un item a la lista de items
 */
- (void) addRepairOrderToCollection: (REPAIR_ORDER_ITEM) aRepairOrderItem;

/**
 * Remueve un item de la lista de items
 */
- (void) removeRepairOrderFromCollection: (int) anItemId;

/**
 * Restaura los valores de la configuracion del perfil
 */

- (void) restoreRepairOrder: (int) anItemId;

/**
 * Devuelve una coleccion con todos los items activos
 */
- (COLLECTION) getRepairOrderItems;


@end

#endif

