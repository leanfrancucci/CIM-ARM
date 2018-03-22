#ifndef INPUT_KEYBOARD_MANAGER_H
#define INPUT_KEYBOARD_MANAGER_H

#define INPUT_KEYBOARD_MANAGER id

#include <Object.h>
#include "system/os/all.h"
#include "jlcd/JEventQueue.h"

/**
 *	El modo case actual.
 */
typedef enum {
	CaseMode_LOWER,
	CaseMode_UPPER
} CaseMode;

typedef enum {
	LanguageTypeKB_LANGUAGE_NOT_DEFINED,
	LanguageTypeKB_SPANISH,
	LanguageTypeKB_ENGLISH,
	LanguageTypeKB_FRENCH
} LanguageTypeKB;

/**
 * Obtiene teclas del teclado y las envia a la cola de eventos
 */
@interface InputKeyboardManager: OThread
{
	JEVENT_QUEUE 		myEventQueue;
	BOOL						myRunning;
	BOOL						mySuspended;
	CaseMode				myCurrentCase;
	BOOL						myIgnoreKeyEvents;
	id							myObjectHandler;
	char						myMethodHandler[255];
	LanguageTypeKB 	myCurrentLanguage;
	BOOL						myIgnoreLowerCase;
}

/**/
+ getInstance;

/**/
- initialize;

/**/
- (void) setNumericMode;

/**/
- (void) setNumericPhoneMode;

/**/
- (void) setNumericModemPhoneMode;

/**/
- (void) setAlphaNumericMode;

/**
 * Este seteo se utiliza unicamente para el caso del login. La diferencia con el setNumericPhoneMode
 * es que primero muestra los numeros y luego las letras
 */
- (void) setAlphaNumericLoginMode;

/**/
- (void) setNumericIPMode;

/**/
- (void) setNumericCodeMode;

/**/
- (CaseMode) getCurrentCaseMode;

/**/
- (void) invertCaseMode;

/**/
- (void) run;

/**/
- (void) setSuspended: (BOOL) aValue;

/**/
- (void) stopRunning;

- (void) setIgnoreKeyEvents: (BOOL) aValue;
- (BOOL) getIgnoreKeyEvents;

- (void) setKeyboardHandler: (id) anObject method: (char*) aMethod;

/**
 * Se setea el idioma actual para poder cargar dinamicamente la tabla de caracteres
 * alfanumericos dependiendo del idioma
 */
- (void) setCurrentLanguage: (LanguageTypeKB) aValue;

/**
 * Indica si el caracter especial pasado por parametro es Upper
 */
- (BOOL) isSpecialCharUpper: (int) aChar;

/**
 * Pasa el caracter especial pasado por parametro a Lower
 */
- (int) toLowerSpecialChar: (int) aChar;

@end

#endif

