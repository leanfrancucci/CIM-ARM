#include <assert.h>
#include <assert.h>
#include <ctype.h>
#include "util.h"
#include "keypadlib.h"
#include "UserInterfaceExcepts.h"
#include "UserInterfaceDefs.h"
#include "InputKeyboardManager.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation InputKeyboardManager

static id singleInstance = NULL;

/**/
+ new
{
	if (singleInstance == NULL)
		singleInstance = [[super new] initialize];
	
	return singleInstance;
}

/**/
+ getInstance
{
	return [self new];
}

/**/
- initialize
{
	[super initialize];

	myEventQueue = [JEventQueue getInstance];
	myIgnoreKeyEvents = FALSE;
	myObjectHandler = NULL;
	myIgnoreLowerCase = FALSE;
		
	if ( kp_open() < 0)
		THROW( UI_GENERAL_EX );

	kp_set_xlate_mode();
	kp_set_alphanum_mode();

	myCurrentCase = CaseMode_UPPER;

	return self;
}

/**/
- (void) setNumericMode
{
	myIgnoreLowerCase = FALSE;

	kp_set_numeric_mode();
	kp_set_mapscancode(29, "");
	kp_set_mapscancode(13, "^");
}

/**/
- (void) setAlphaNumericMode
{
	char buf[20];

	myIgnoreLowerCase = FALSE;

	// actualizo el mapa de caracteres de acuerdo al idioma actual
	switch (myCurrentLanguage) {
		case LanguageTypeKB_SPANISH:
				// seteo el mapa de caracteres generico
				kp_set_alphanum_mode();

				// reemplazo las teclas correspondientes
				// TUÚV8
				sprintf(buf,"TU%cV8",'\xDA');
				kp_set_mapscancode(20, buf);
				// MNÑOÓ6
				sprintf(buf,"MN%cO%c6",'\xD1','\xD3');
				kp_set_mapscancode(11, buf);
				// GHIÍ4
				sprintf(buf,"GHI%c4",'\xCD');
				kp_set_mapscancode(27, buf);
				// AÁBC2
				sprintf(buf,"A%cBC2",'\xC1');
				kp_set_mapscancode(18, buf);
				// DEÉF3
				sprintf(buf,"DE%cF3",'\xC9');
				kp_set_mapscancode(10, buf);

				break;

		case LanguageTypeKB_ENGLISH:
				// seteo el mapa de caracteres generico
				kp_set_alphanum_mode();

				break;

		case LanguageTypeKB_FRENCH:
				// seteo el mapa de caracteres generico
				kp_set_alphanum_mode();

				// reemplazo las teclas correspondientes
				// TUÙÚÛÜV8
				sprintf(buf,"TU%c%c%c%cV8",'\xD9','\xDA','\xDB','\xDC');
				kp_set_mapscancode(20, buf);
				// WXYÿZ9
				sprintf(buf,"WXY%cZ9",'\xFF');
				kp_set_mapscancode(12, buf);
				// MNÑOÒÓÔÕÖ6
				sprintf(buf,"MN%cO%c%c%c%c%c6",'\xD1','\xD2','\xD3','\xD4','\xD5','\xD6');
				kp_set_mapscancode(11, buf);
				// GHIÌÍÎÏ4
				sprintf(buf,"GHI%c%c%c%c4",'\xCC','\xCD','\xCE','\xCF');
				kp_set_mapscancode(27, buf);
				// AÀÁÂÃÄBCÇ2
				sprintf(buf,"A%c%c%c%c%cBC%c2",'\xC0','\xC1','\xC2','\xC3','\xC4','\xC7');
				kp_set_mapscancode(18, buf);
				// DEÈÉÊËF3
				sprintf(buf,"DE%c%c%c%cF3",'\xC8','\xC9','\xCA','\xCB');
				kp_set_mapscancode(10, buf);
				// $@.#-«»Æß1
				sprintf(buf,"$@.#-%c%c%c%c1",'\xAB','\xBB','\xC6','\xDF');
				kp_set_mapscancode(26, buf);

				break;
	}
}

	/* {21, " 0"}
	,{13, "^"}
	,{29, "*"}
	,{20, "TUV8"}
	,{12, "WXYZ9"}
	,{28, "PQRS7"}
	,{19, "JKL5"}
	,{11, "MNO6"}
	,{27, "GHI4"}
	,{18, "ABC2"}
	,{10, "DEF3"}
	,{26, "$@.#-1"}*/

/**/
- (void) setAlphaNumericLoginMode
{
	char buf[20];

	myIgnoreLowerCase = TRUE;

	// se modifico esta funcion para que las teclas aceptadas sean igual para todos los idiomas
	// 0..9 y de la A..Z
	// seteo el mapa de caracteres generico
	kp_set_alphanum_mode();

	// reemplazo las teclas correspondientes
	kp_set_mapscancode(21, "0");
	kp_set_mapscancode(13, "");
	kp_set_mapscancode(29, "");
	kp_set_mapscancode(20, "8TUV");
	kp_set_mapscancode(12, "9WXYZ");
	kp_set_mapscancode(28, "7PQRS");
	kp_set_mapscancode(19, "5JKL");
	kp_set_mapscancode(11, "6MNO");
	kp_set_mapscancode(27, "4GHI");
	kp_set_mapscancode(18, "2ABC");
	kp_set_mapscancode(10, "3DEF");
	kp_set_mapscancode(26, "1");

	// actualizo el mapa de caracteres de acuerdo al idioma actual
/*	switch (myCurrentLanguage) {
		case LanguageTypeKB_SPANISH:
				// seteo el mapa de caracteres generico
				kp_set_alphanum_mode();

				// reemplazo las teclas correspondientes
				//0
				kp_set_mapscancode(21, "0");
				//kp_set_mapscancode(13, "^");
				kp_set_mapscancode(29, "");
				// 8TUÚV
				sprintf(buf,"8TU%cV",'\xDA');
				kp_set_mapscancode(20, buf);
				//9WXYZ
				kp_set_mapscancode(12, "9WXYZ");
				//7PQRS
				kp_set_mapscancode(28, "7PQRS");
				//5JKL
				kp_set_mapscancode(19, "5JKL");
				// 6MNÑOÓ
				sprintf(buf,"6MN%cO%c",'\xD1','\xD3');
				kp_set_mapscancode(11, buf);
				// 4GHIÍ
				sprintf(buf,"4GHI%c",'\xCD');
				kp_set_mapscancode(27, buf);
				// 2AÁBC
				sprintf(buf,"2A%cBC",'\xC1');
				kp_set_mapscancode(18, buf);
				// 3DEÉF
				sprintf(buf,"3DE%cF",'\xC9');
				kp_set_mapscancode(10, buf);
				//1
				kp_set_mapscancode(26, "1");

				break;

		case LanguageTypeKB_ENGLISH:
				// seteo el mapa de caracteres generico
				kp_set_alphanum_mode();

				// reemplazo las teclas correspondientes
				kp_set_mapscancode(21, "0");
				//kp_set_mapscancode(13, "^");
				kp_set_mapscancode(29, "");
				kp_set_mapscancode(20, "8TUV");
				kp_set_mapscancode(12, "9WXYZ");
				kp_set_mapscancode(28, "7PQRS");
				kp_set_mapscancode(19, "5JKL");
				kp_set_mapscancode(11, "6MNO");
				kp_set_mapscancode(27, "4GHI");
				kp_set_mapscancode(18, "2ABC");
				kp_set_mapscancode(10, "3DEF");
				kp_set_mapscancode(26, "1");

				break;

		case LanguageTypeKB_FRENCH:
				// seteo el mapa de caracteres generico
				kp_set_alphanum_mode();

				// reemplazo las teclas correspondientes
				//0
				kp_set_mapscancode(21, "0");
				//kp_set_mapscancode(13, "^");
				kp_set_mapscancode(29, "");
				// 8TUÙÚÛÜV
				sprintf(buf,"8TU%c%c%c%cV",'\xD9','\xDA','\xDB','\xDC');
				kp_set_mapscancode(20, buf);
				// 9WXYÿZ
				sprintf(buf,"9WXY%cZ",'\xFF');
				kp_set_mapscancode(12, buf);
				//7PQRS
				kp_set_mapscancode(28, "7PQRS");
				//5JKL
				kp_set_mapscancode(19, "5JKL");
				// 6MNÑOÒÓÔÕÖ
				sprintf(buf,"6MN%cO%c%c%c%c%c",'\xD1','\xD2','\xD3','\xD4','\xD5','\xD6');
				kp_set_mapscancode(11, buf);
				// 4GHIÌÍÎÏ
				sprintf(buf,"4GHI%c%c%c%c",'\xCC','\xCD','\xCE','\xCF');
				kp_set_mapscancode(27, buf);
				// 2AÀÁÂÃÄBCÇ
				sprintf(buf,"2A%c%c%c%c%cBC%c",'\xC0','\xC1','\xC2','\xC3','\xC4','\xC7');
				kp_set_mapscancode(18, buf);
				// 3DEÈÉÊËF
				sprintf(buf,"3DE%c%c%c%cF",'\xC8','\xC9','\xCA','\xCB');
				kp_set_mapscancode(10, buf);
				// 1
				kp_set_mapscancode(26, "1");

				break;
	}*/
}

/**/
- (void) stopRunning
{
	myRunning = FALSE;
}

/**/
- (CaseMode) getCurrentCaseMode
{
	return myCurrentCase;
}

/**/
- (void) invertCaseMode
{
	if (myCurrentCase == CaseMode_UPPER) myCurrentCase = CaseMode_LOWER;
	else myCurrentCase = CaseMode_UPPER;
}

/**/
- (void) setSuspended: (BOOL) aValue
{
	mySuspended = aValue;
}

/**/
- (void) run
{
	JEvent		evt;
	int c;
	int k;
	SEL sel;

	assert(myEventQueue != NULL);

	threadSetPriority(20);

	printd("InputManager:start()\n");

	myRunning = TRUE;
	while (myRunning) {

	//	while (mySuspended) msleep(100);		// Si el hilo esta suspendido
		
		/* Lee del teclado */
		c =  kp_getc();
		//doLog(0,"key is %c, %02X\n", c, (unsigned char)c); fflush(stdout);
		if (myIgnoreKeyEvents) continue;

		if (myObjectHandler) {
			sel = [myObjectHandler findSel: myMethodHandler];
			[myObjectHandler perform: sel with: (void*)&c];
			continue;
		}

		if (c == '\n')
			continue;

		switch (c) {

#ifdef CT_NCURSES_SUPPORT  
			case 8:
					k = UserInterfaceDefs_KEY_MENU_X;
					break;

			case 'a':
					k = UserInterfaceDefs_KEY_LEFT;
					break;

			case 'd':
					k = UserInterfaceDefs_KEY_RIGHT;
					break;

			case 'q':
					k = UserInterfaceDefs_KEY_FNC;
					break;
					
			case 'e':
					k = UserInterfaceDefs_KEY_FNC_2;
					break;
					
			case 'u':
					k = UserInterfaceDefs_KEY_MANUAL_DROP;
					break;
          
			case 'i':
					k = UserInterfaceDefs_KEY_DEPOSIT;
					break;
          
			case 'o':
					k = UserInterfaceDefs_KEY_REPORTS;
					break;
          
			case 'p':
					k = UserInterfaceDefs_KEY_VALIDATED_DROP;
					break;                              					

			case 'w':
					k = UserInterfaceDefs_KEY_UP;
					break;

			case 's':
					k = UserInterfaceDefs_KEY_DOWN;
					break;

			case 'z':
					k = UserInterfaceDefs_KEY_MENU_1;
					break;

			case 'x':
					k = UserInterfaceDefs_KEY_MENU_X;
					break;

			case 'c':
					k = UserInterfaceDefs_KEY_MENU_2;
					break;

			case '>':			
					k = UserInterfaceDefs_XLATE_SPECIAL_KEY;
					break;

#else

			case 'a':
					k = UserInterfaceDefs_KEY_LEFT;
					break;

			case 'd':
					k = UserInterfaceDefs_KEY_RIGHT;
					break;

			case 'z':
					k = UserInterfaceDefs_KEY_FNC;
					break;
					
			case 'm':
					k = UserInterfaceDefs_KEY_FNC_2;
					break;
					
			case 'n':
					k = UserInterfaceDefs_KEY_MANUAL_DROP;
					break;
          
			case 'o':
					k = UserInterfaceDefs_KEY_DEPOSIT;
					break;
          
			case 'p':
					k = UserInterfaceDefs_KEY_REPORTS;
					break;
          
			case 'q':
					k = UserInterfaceDefs_KEY_VALIDATED_DROP;
					break;                              					

			case '\xF0':
					k = UserInterfaceDefs_KEY_UP;
					break;

			case '+':
					k = UserInterfaceDefs_KEY_DOWN;
					break;

			case 'e':

					k = UserInterfaceDefs_KEY_MENU_1;
					break;

			case 'x':
					k = UserInterfaceDefs_KEY_MENU_X;
					break;

			case 'c':
					k = UserInterfaceDefs_KEY_MENU_2;
					break;

			case '>':
					k = UserInterfaceDefs_XLATE_SPECIAL_KEY;
					break;

#endif
					
			default:
				if (!myIgnoreLowerCase) {
					if ( isalpha(c) ) {
	
						if (isupper(c) && myCurrentCase == CaseMode_LOWER) c = tolower(c);
	
					} else {
	
						if ((unsigned char)c > 126) { // 7E = 126 indica desde donde comienzan los caracteres extendidos, de 7E para abajo se procesan en el if(isalpha(c))
							//doLog(0,"c Upper = [%d] [%02X]\n",(unsigned char)c,(unsigned char)c);
							// si NO son los caracteres: « (= AB = 171), » (= BB = 187), Æ (= C6 = 198), ß (= DF = 223) entonces proceso el lower si corresponde
							if ( ((unsigned char)c != 171) && ((unsigned char)c != 187) && ((unsigned char)c != 198) && ((unsigned char)c != 223) ) {
								if ([self isSpecialCharUpper: c] && myCurrentCase == CaseMode_LOWER) c = [self toLowerSpecialChar: c];
							}
							//doLog(0,"c Lower = [%d] [%02X]\n",(unsigned char)c,(unsigned char)c);
						}
	
					}
				}
				k = c;
		}

		/* Arma el evento */
		evt.evtid = JEventQueueMessage_KEY_PRESSED;
		evt.event.keyEvt.keyPressed = k;
		evt.event.keyEvt.isPressed = TRUE;

		TRY
			/* Agrega el evento a la cola */
			[myEventQueue putJEvent: &evt];
#ifdef CT_NCURSES_SUPPORT
		if (k == 32 || (k >= 'A' && k <= 'Z')) {
			
			evt.evtid = JEventQueueMessage_KEY_PRESSED;
			evt.event.keyEvt.keyPressed = UserInterfaceDefs_KEY_RIGHT;
			evt.event.keyEvt.isPressed = TRUE;
			[myEventQueue putJEvent: &evt];
		}

#endif

		CATCH

			/* Cola llena ... */
			ex_printfmt();
		//	doLog(0,"ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - \n");
		//	doLog(0,"Ha ocurrido una excepcion en el hilo del manejo del teclado.\n");
		//	doLog(0,"ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - \n");
			
		END_TRY;

		sched_yield();
		msleep(5);

	}

	//kp_close();
}

/**/
- (void) setIgnoreKeyEvents: (BOOL) aValue
{
	myIgnoreKeyEvents = aValue;
}

/**/
- (BOOL) getIgnoreKeyEvents
{
	return myIgnoreKeyEvents;
}

/**/
- (void) setNumericPhoneMode
{
	myIgnoreLowerCase = FALSE;

	kp_set_numeric_mode();	
	kp_set_mapscancode(29, "*");
	kp_set_mapscancode(13, "#");
}

/**/
- (void) setNumericModemPhoneMode
{
	myIgnoreLowerCase = FALSE;

	kp_set_numeric_mode();	
	kp_set_mapscancode(29, "*");
	kp_set_mapscancode(13, ",");
}

/**/
- (void) setNumericIPMode
{
	myIgnoreLowerCase = FALSE;

 	kp_set_numeric_mode();
	kp_set_mapscancode(13, ".");
}

/**/
- (void) setNumericCodeMode
{
	myIgnoreLowerCase = FALSE;

 	kp_set_numeric_mode();
	kp_set_mapscancode(13, " ");
}

/**/
- (void) setKeyboardHandler: (id) anObject method: (char*) aMethod
{
	myObjectHandler = anObject;
	strcpy(myMethodHandler, aMethod);
}

/**/
- (void) close
{
	kp_close();
}

- (void) setCurrentLanguage: (LanguageTypeKB) aValue
{
	myCurrentLanguage = aValue;
}

/**/
- (BOOL) isSpecialCharUpper: (int) aChar
{
	// si esta entre À (= C0 = 192) .. Ü (= DC = 220)
	return ( ((unsigned char)aChar >= 192) && ((unsigned char)aChar <= 220) );
}

/**/
- (int) toLowerSpecialChar: (int) aChar
{
	// se suman 32 para pasarlo a lower
	return (aChar + 32);
}

@end
