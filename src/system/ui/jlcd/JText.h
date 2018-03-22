#ifndef  JTEXT_H
#define  JTEXT_H

#define  JTEXT  id

#include "JComponent.h"


#define JText_MAX_LEN				64

typedef enum
{
	JTextNumericType_NORMAL,
	JTextNumericType_PHONE,
	JTextNumericType_MODEM_PHONE,
  JTextNumericType_IP,
	JTextNumericType_CODE
} JTextNumericType;

/**
 * Implementa un cuadro de texto visual.
 * El texto puede ser alfanumerico, numerico o de tipo password.
 * Tambien es posible configurarlo para que controle que se debe ingresar al menos
 * un caracter o que se deben ingresar todos los caracteres (se entendio algo?)
 *
 * Scrollea el texto dentro del cuadro.
 **/						
@interface  JText: JComponent
{
	int   				myCurrentPosition;
	char   				myText[ JText_MAX_LEN + 1 ];
		
	int						myFirstVisibleChar; /* El indice del primer caracter visible cuando hace scroll vertical */

	BOOL					myIsPasswordMode;
	BOOL					myIsMandatoryMode;
	BOOL					myIsNumericMode;
	JTextNumericType myNumericType;
	BOOL					myIsFullMandatoryMode;
	
	int						myMaxLen;
	
 	long   				myMinValue;
 	long   				myMaxValue;
	
	BOOL					myIsNewPosition;

	BOOL					myIsAlphaNumericLoginMode;
}

/**
 * Mapea la posicion actual a posiciones (x, y)
 */
- (int) mapXPosition: (int) aPos;
- (int) mapYPosition: (int) aPos;

/**
 * Se ejecuta cuando el conmponente necesita reconfigurar la posicion del control.
 * Puede ser reimplementado por las subclases de JText 
 * (asi no deben redefinir el metodo kyPressed())
 */
- (void) setNewCursorPosition;

/**
 * Se ejecuta al presionar la tecla derecha.
 * Puede ser reimplementado por las subclases de JText 
 * (asi no deben redefinir el metodo kyPressed())
 * @result TRUE si la tecla puo ser procesada por el metodo
 */
- (BOOL) setRightKeyPressed;				

/**
 * Se ejecuta al presionar la tecla izquierda.
 * Puede ser reimplementado por las subclases de JText 
 * (asi no deben redefinir el metodo kyPressed())
 * @result TRUE si la tecla puo ser procesada por el metodo
 */
- (BOOL) setLeftKeyPressed;

				
/**
 * Se ejecuta al presionar la tecla delete.
 * Puede ser reimplementado por las subclases de JText 
 * (asi no deben redefinir el metodo kyPressed())
 * @result TRUE si la tecla puo ser procesada por el metodo
 */
- (BOOL) setDeleteKeyPressed;

/**
 * Se ejecuta al presionar una tecla alfanumerica si el control acepta alfanumerica o
 * una tecla numerica si el control acepta solo numericas.
 * Puede ser reimplementado por las subclases de JText 
 * (asi no deben redefinir el metodo kyPressed())
 * @result TRUE si la tecla pudo ser procesada por el metodo
 */
- (BOOL) setNewKeyPressed: (unsigned char) aKey;


									
/**
 * Configura la cantidad maxima de caracteres que es posible ingresar en el Text.
 */				
- (void) setMaxLen: (int) aValue;
- (int) getMaxLen;

											
/**
 *
 */
- (void) setMinNumericValue: (long) aMinValue;
- (long) getMinNumericValue ;

/**
 *
 */
- (void) setMaxNumericValue: (long) aMaxValue;
- (long) getMaxNumericValue ;

/**
 *
 */
- (void) setPasswordMode: (BOOL) aValue;
- (BOOL) isPasswordMode;
	
/**
 *
 */
- (void) setMandatoryMode: (BOOL) aValue;
- (BOOL) isMandatoryMode;

/**
 *
 */
- (void) setFullMandatoryMode: (BOOL) aValue;
- (BOOL) isFullMandatoryMode;
	
/**
 *
 */
- (void) setNumericMode: (BOOL) aValue;
- (BOOL) isNumericMode;

/**
 *
 */
- (void) setNumericType: (JTextNumericType) aValue;
- (JTextNumericType) getNumericType;

/**
 *
 */
- (void) setText: (char *) aText;
- (char *) getText;
 
/**
 *
 */
- (void) setIntegerValue: (int) aValue;
- (int) getIntegerValue;

/**
 *
 */
- (void) setLongValue: (long) aValue;
- (long) getLongValue;

/**
 *
 */
- (void) setAlphaNumericLoginMode: (BOOL) aValue;

@end

#endif

