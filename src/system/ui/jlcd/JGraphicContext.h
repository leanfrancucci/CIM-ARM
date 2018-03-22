#ifndef  JGRAPHIC_CONTEXT_H
#define  JGRAPHIC_CONTEXT_H

#define  JGRAPHIC_CONTEXT  id

#include <objpak.h>
#include "system/lang/all.h"
#include "JVirtualScreen.h"


/**
 * Implementa una zona de impresion para los componentes visuales.
 * Este particularmente imprime en el lcd, pero se puedeplantear otro
 * que imprima en la impresora: asi una ventana puede ser impresa sin tener 
 * que reimplementar nada, solo cambiar el contexto grafico.
 * El origen (x, y) es (1, 1).
 *
 * En base a la ubicacion (myXPosition, myYPosition) el contexto grafico mapea lo 
 * que escribe cada componente con la posicion real en el lcd en base al Height del
 * contexto.
 *
 * Ponele: si el Height = 3 y un control hace un print en (11, 3) el contexto, entonces,
 * manda al lcd un print en (2, 3) : 11 % 3 = 2.
 * Por ahora el widht no lo maneja, pero puedo hacer que lo maneje mas adelante, asi
 * haria scroll horizontal (por ahora no se necesita).
 * 
 */
@interface  JGraphicContext: Object
{
		JVIRTUAL_SCREEN			myVirtualScreen;
		BOOL 								myIsClear;				
		int   							myWidth;
		int									myHeight;

		int									myXPosition;
		int									myYPosition;
		
		int									myCurrentXPosition;
		int									myCurrentYPosition;
		
		int 								myCursorXPosition;
		int 								myCursorYPosition;
};


/****
 * Metodos publicos
 */

/**/
- initialize;

/**/
- free;

/**/
- (void) setWidth: (int) aWidth ;
- (int) getWidth;

/**/
- (void) setHeight: (int) aHeight;
- (int) getHeight;


/**/
- (void) setXPosition: (int) aPosition;
- (int) getXPosition;

/**
 * La coordenada y fija en donde esta ubicado el contexto.
 */
- (void) setYPosition: (int) aPosition;
- (int) getYPosition;

/**
 * La coordenada x donde tiene actualmente el origen el contexto. 
 */
- (void) setCurrentXPosition: (int) aPosition;
- (int) getCurrentXPosition;

/**
 * La coordenada y donde tiene actualmente el origen el contexto. 
 */
- (void) setCurrentYPosition: (int) aPosition;
- (int) getCurrentYPosition;

/**
 *
 */
- (int) getWidth;


/**
 *
 */
- (int) getHeight;

/**
 *
 */
- (void) setCursorState: (BOOL) aValue;

/**
 * Enciende o apaga el blink del cursor en la posicion actual del cursor.
 */
- (void) setBlinkCursor: (BOOL) aValue;

/**
 * Enciende el blink del cursor en la posicion (aPosX, aPosY).
 * La posicion del cursor se configura con la nueva posicion pasada como argumento.
 */
- (void) blinkCursorAtPosX: (int) aPosX atPosY: (int) aPosY;


/**
 *
 */
- (void) gotoPosX: (int) aPosX  posY: (int) aPosY;

/**
 * Limpia todo el area del lcd completo.
 * (peligroso)
 */
- (void) clearScreen;

/**
 * Limpia solo el area del contenedor n base al height y al width.
 */
- (void) clearArea;

/**
 *
 */
- (void) printChar: (char) aChar atPosX: (int) aPosX atPosY: (int) aPosY;

/**
 *
 */
- (void) printString: (char *) aText atPosX: (int) aPosX atPosY: (int) aPosY;


/**
 *
 */
- (void) scrollDown: (int) aLinesQty;

/**
 *
 */
- (void) scrollUp: (int) aLinesQty;


/**
 * Devuelve TRUE si la posicion (x, y) esta contenida en la pantalla actual en
 * base al origen (x, y) del contexto grafico y en base al width y height del mismo.
 * Devuelve FALSE en caso contrario.
 */
- (BOOL) intersecsAreaAtXPos: (int) anXPos atYPos: (int) anYPos;

/**
 * Mapea la posicion en X del  @param aPosX y con la del contexto.
 */
- (int) mapXPosition: (int) aPosX;

/**
 * Mapea la posicion en Y del  @param aPosX y con la del contexto.
 */
- (int) mapYPosition: (int) aPosY;


@end

#endif

