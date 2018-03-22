#include <math.h>
#include "Round.h"
#include "AmountSettings.h"
#include "system/util/all.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

static id singleInstance = NULL;

/**//*
void printValue(double value, int exp)
{
	char format[40];
	
	sprintf(format, "result = %s%d%s ", "%.", exp, "f");
	doLog(0,format, value);
	
}
*/
/**/
money_t roundTo(money_t value, int decimals, int roundType);

@implementation Round

/**/
- initialize
{
	itemDecimals = [[AmountSettings getInstance] getItemsRoundDecimalQty];
	subtotalDecimals = [[AmountSettings getInstance] getSubtotalRoundDecimalQty];
	taxDecimals = [[AmountSettings getInstance] getTaxRoundDecimalQty];
	totalDecimals = [[AmountSettings getInstance] getTotalRoundDecimalQty];
	roundType = [[AmountSettings getInstance] getRoundType];
	return self;
}

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [[super new] initialize];
	return singleInstance;
}

/**/
+ getInstance
{
	return [self new];	
}

/**/
- (money_t) round: (money_t) aValue decimalQty: (int) aDecimalQty roundType: (int) aRoundType
{
	return roundTo(aValue, aDecimalQty, aRoundType);
}

/**/
- (money_t) roundEntity: (EntityType) anEntity value: (money_t) aValue
{
	int decimalQty = 0;

	//Toma la cantidad de decimales a la cual se debe redondear la entidad.
	switch (anEntity)
	{
		case ITEM_ENTITY:
											decimalQty = itemDecimals;
											break;
							
		case SUBTOTAL_ENTITY:
											decimalQty = subtotalDecimals;
											break;
								
		case TAX_ENTITY:
											decimalQty = taxDecimals;
											break;

		case TOTAL_ENTITY:
											decimalQty = totalDecimals;
											break;
	}

	return roundTo(aValue, decimalQty, roundType);
}


/**/
money_t roundTo(money_t value, int decimals, int roundType)
{
	
	long long lvalue;
	long long q;
	long long qdec;
	long long remainder;
	int negative;

	negative = 0;
	
	if (value < 0) negative = 1;
	
	q = llpow(10, MONEY_DECIMAL_DIGITS);
	qdec = llpow(10, MONEY_DECIMAL_DIGITS - decimals);

	printd("Rounding value %f to %d decimales\n", value * 1.0 / q * 1.0, decimals);

	if (value < 0) lvalue = 0 - value; else lvalue = value;
	remainder = (lvalue % qdec);

	if ( (roundType == UP_ROUND || (roundType == NORMAL_ROUND && remainder >= qdec / 2)) && remainder != 0)
	{
		lvalue = lvalue + (qdec - remainder);
	} else
		lvalue = lvalue - remainder;

	if (negative) lvalue = 0 - lvalue;

	printd("Result value is %lld\n", lvalue);
	
	return lvalue;
	
}

@end

