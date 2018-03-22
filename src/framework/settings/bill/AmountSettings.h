#ifndef AMOUNT_SETTINGS_H
#define AMOUNT_SETTINGS_H

#define AMOUNT_SETTINGS id

#include "Object.h"
#include "ctapp.h"

/**
 * Clase  
 */

@interface AmountSettings:  Object
{
	int myAmountSettingsId;
	int myRoundType;
	int myDecimalQty;
	int myItemsRoundDecimalQty;
	int mySubtotalRoundDecimalQty;
	int myTotalRoundDecimalQty;
	int myTaxRoundDecimalQty;
	money_t myRoundValue;
}

/**
 * 
 */

+ new;
+ getInstance;
- initialize;

/**
 * Setea los valores correspondientes a la configuracion general de los montos
 */

- (void) setAmountSettingsId: (int) aValue;
- (void) setRoundType: (RoundType) aValue;
- (void) setDecimalQty: (int) aValue;
- (void) setItemsRoundDecimalQty: (int) aValue;
- (void) setSubtotalRoundDecimalQty: (int) aValue;
- (void) setTotalRoundDecimalQty: (int) aValue;
- (void) setTaxRoundDecimalQty: (int) aValue;
- (void) setRoundValue: (money_t) aValue;

/**
 * Devuelve los valores correspondientes a la configuracion general de los montos
 */	

- (int) getAmountSettingsId;
- (RoundType) getRoundType;
- (int) getDecimalQty;
- (int) getItemsRoundDecimalQty;
- (int) getSubtotalRoundDecimalQty;
- (int) getTotalRoundDecimalQty;
- (int) getTaxRoundDecimalQty;
- (money_t) getRoundValue;


/**
 * Aplica los cambios realizados sobre la instancia de la configuracion de la facturacion
 */

- (void) applyChanges;

/**
 * Restaura los valores que se encuentran almacenados en la persistencia
 */

- (void) restore;


@end

#endif

