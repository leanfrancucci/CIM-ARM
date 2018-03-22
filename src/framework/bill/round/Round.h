#ifndef ROUND_H
#define ROUND_H

#define ROUND id

#include <Object.h>
#include "ctapp.h"


/**
 *	Encapsula el manejo del redondeo.
 *
 *  <<singleton>>
 *
 */

@interface Round:  Object
{
	int itemDecimals;
	int subtotalDecimals;
	int taxDecimals;
	int totalDecimals;
	int roundType;
}

/**
 *	Devuelve la unica instancia posible de este objeto.
 */
+ getInstance;

/**
 * Redondea el valor de la entidad pasada como parametro.
 * La entidad es pasada como parametro, ya que cada entidad es posible redondearla
 * a diferente cantidad de decimales.
 * @param anEntity la entidad que se redondeara, actualmente son ITEM_ENTITY, SUBTOTAL_ENTITY,
 * TAX_ENTITY, TOTAL_ENTITY.
 * @param value valor a redondear.
 */

- (money_t) roundEntity: (EntityType) anEntity value: (money_t) aValue;

/**
 * Metodo que redondea el valor pasado como parametro, a la cantidad de decimales especificada.
 * El tipo de redondeo a aplicar tambien debe pasarse como parametro.
 * @param aValue valor a redondear.
 * @param decimalQty cantidad de decimales a la que se redondeara el valor.
 * @param roundType tipo de redondeo que se aplicara, actualmente puede ser NORMAL, UP, DOWN.
 */

- (money_t) round: (money_t) aValue decimalQty: (int) aDecimalQty roundType: (int) aRoundType;


@end

#endif

