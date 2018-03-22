#ifndef STRING_TOKENIZER_H
#define STRING_TOKENIZER_H

#define STRING_TOKENIZER id

#include <Object.h>

/**
 *	Define los tipos de Trim que se le puede setear al tokenizer.
 */
typedef enum {
	TRIM_NONE,
	TRIM_LEFT,
	TRIM_RIGHT,
	TRIM_ALL
} TokenizerTrimMode;

/**
 *	Permite separar una cadena en tokens, especificando un delimitador de tokens.
 */
@interface StringTokenizer : Object
{
	char *myTextPtr;
	char *myText;
	char myDelimiter[10];
	TokenizerTrimMode myTrimMode;
}

/**
 *	Crea el objeto, iniciandolo con el texto y el delimitador pasado como parametro.
 */
+ new;

- initialize;

/**
 *	Inicializa el tokenizer con el texto y el delimitador pasado como parametro.
 */
- (id) initTokenizer:(char*)aText delimiter:(char*)aDelimiter;

/**
 *	Setea el texto a analizar por el objeto.
 */
- (void) setText: (char*)aText;

/**
 *	Setea el delimitador de cadena.
 */
- (void) setDelimiter: (char*)aDelimiter;

/** 
 *	Setea si elimina los espacios en blanco del token devuelto.
 */
- (void) setTrimMode: (TokenizerTrimMode) aValue;

/**
 *	Reinicia el tokenizer, puedo volver a preguntar nuevamente por los tokens.
 */
- (void) restart;

/**
 *	Devuelve TRUE si hay mas tokens.
 */
- (BOOL) hasMoreTokens;

/**
 *	Devuelve el proximo token en el buffer pasado como parametro.
 */
- (char*) getNextToken: (char*) aToken;

/**
 *	Destructor.
 */
- free;

@end

#endif
