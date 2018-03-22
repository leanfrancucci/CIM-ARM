#ifndef  JLABEL_H
#define  JLABEL_H

#define  JLABEL  id

#include "util.h"
#include "StringTokenizer.h"
#include "JComponent.h"

/**
 *
 */
@interface  JLabel: JComponent
{
	char   						myCaption[ JComponent_MAX_LEN + 1 ];
	char							myAuxText[ JComponent_MAX_LEN + 1 ];
	
	BOOL							myWordWrapMode;
	BOOL							myAutoSize;
	int								myFormatNumbersOfDigits;
	
	UTIL_AlignType 		myTextAlign;
	
	STRING_TOKENIZER	myTokenizer;
	OMUTEX 						myMutex;
}

/**/
- (void) setTextAlign: (UTIL_AlignType) aTextAlign;
- (UTIL_AlignType) getTextAlign;

/**
 * La inicializa con un caption determinado
 */
- initWithCaption: (char *)  aCaption;

/**
 * Cuando se utiliza setIntegerValue() o setLongValue() puede ser configurado el 
 * valor FormatNumbersOfDigits para que complete el numero con ceros adelante.
 * Por defecto esta en cero.
 */
- (void) setFormatNumbersOfDigits: (int) aValue;
- (int) getFormatNumbersOfDigits;

/**
 * Configura el texto del label
 * Si aValue es null entonces configura la cadena vacia
 */
- (void) setCaption: (char *) aValue;
- (char *) getCaption;

/**
 * Configura el texto numerico del label
 */
- (void) setIntegerValue: (int) aValue;
- (int) getIntegerValue;

/**
 * Configura el texto numerico del label
 */
- (void) setLongValue: (long) aValue;
- (long) getLongValue;

/**
 * Si AutoSize es TRUE entonces el label toma el widht del caption con el que es configurado.
 * Si AutoSize es FALSE el label mantiene siempre el tamanio seteado con setWidht. 
 */
- (void) setAutoSize: (BOOL) aValue;
- (BOOL) isAutoSize;

/**
 * Si el height del control es mayor que 1 y esta configurado para que haga
 * word wrap entonces el caption del label se corta al llegar al fin del control y
 * continua en la linea de abajo hasta llegar al tamanio height.
 */
- (void) setWordWrap: (BOOL) aValue;
- (BOOL) isWordWrap;


@end

#endif

