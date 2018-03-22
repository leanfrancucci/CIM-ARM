#ifndef  JNUMERICTEXT_H
#define  JNUMERICTEXT_H

#define  JNUMERIC_TEXT  id

#include "JText.h"

#define JNumericText_DEFAULT_DECIMAL_DIGITS						2
#define JNumericText_DEFAULT_DECIMAL_SEPARATOR				'.'
	
#define JNumericText_MAX_LEN		JComponent_LINE_SIZE

/**
 * Implementa una cajita de texto para ingresar valores decimales.
 * Es posible configurarle la cantidad de decimales.
 * Los numeros los edita igual que un cajero automatico: comenzando desde la 
 * derecha con el punto fijo en la cantidad de decimales configurada.
 *
 * @warning No maneja valores negativos.
 *
 **/
@interface  JNumericText: JText
{
	unsigned long long			myValue;

	char 										myDecimalSeparator;		
	int											myDecimalDigits;		
	double   								myMinDoubleValue;
 	double   								myMaxDoubleValue;
  char  									myValuePrefix[4];          
}

/**
 * Arma myText en base a myValue.
 */
- (void) configureTextValue;

/**
 * Configura la cantidad de digitos decimales
 */
- (void) setDecimalDigits: (int) aValue;
- (int) getDecimalDigits;

/**
 * Configura el separador de decimales
 */
- (void) setDecimalSeparator: (char) aValue;
- (char) getDecimalSeparator;
	
/**
 *
 */
- (void) setMinValueAsDouble: (double) aMinValue;
- (double) getMinValueAsDouble;

/**
 *
 */
- (void) setMaxValueAsDouble: (double) aMaxValue;
- (double) getMaxValueAsDouble;


/**
 *
 */
- (void) setFloatValue: (float) aValue;
- (float) getFloatValue;

/**
 *
 */
- (void) setDoubleValue: (double) aValue;
- (double) getDoubleValue;

/**
 *
 */
- (void) setMoneyValue: (money_t) aValue;
- (money_t) getMoneyValue;

/**
 *
 */
- (void) setValuePrefix: (char*) aValuePrefix;

/**
 *
 */
- (BOOL) isValid;

@end

#endif

