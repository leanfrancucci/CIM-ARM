#ifndef  JCOMPONENT_H
#define  JCOMPONENT_H

#define  JCOMPONENT  id

#include <objpak.h>
#include "JPrintDebug.h"
#include "system/lang/syslang.h"
#include "JGraphicContext.h"
#include "JEventQueue.h"
#include "UserInterfaceDefs.h"


#define JComponent_MAX_HEIHT		         				4
#define JComponent_MAX_WIDTH 										20
#define JComponent_MAX_LEN		  								(JComponent_MAX_WIDTH * JComponent_MAX_HEIHT)

#define JComponent_FILL_CHAR		       					'_'
#define JComponent_PASSWORD_CHAR	       				'*'

#ifdef CT_NCURSES_SUPPORT
#define JComponent_DOWN_ARROW_CHAR	    				'#'
#else
#define JComponent_DOWN_ARROW_CHAR	    				'\xAC'
#endif

#define JComponent_LEFT_FOCUSED_BUTTON_CHAR			'<'
#define JComponent_RIGTH_FOCUSED_BUTTON_CHAR		'>'

#define JComponent_TAB 													UserInterfaceDefs_KEY_DOWN
#define JComponent_SHIFT_TAB 										UserInterfaceDefs_KEY_UP
#define JComponent_CTRL_TAB 										UserInterfaceDefs_KEY_LEFT /* El boton de vista */

/* Los text box */
#define JText_KEY_LEFT 				 UserInterfaceDefs_KEY_LEFT
#define JText_KEY_RIGHT 			 UserInterfaceDefs_KEY_RIGHT
#define JText_KEY_DELETE 			 UserInterfaceDefs_KEY_MENU_X
#define JText_XLATE_SPECIAL_KEY 		 		UserInterfaceDefs_XLATE_SPECIAL_KEY


/* Los check box*/
#define JCheckBox_KEY_CLICK 			 			UserInterfaceDefs_KEY_MENU_X




/* Los menues */
#define JMenuItem_MSECS_TO_PRESS_KEY				750

#define JMenuItem_KEY_ENTER 							UserInterfaceDefs_KEY_MENU_2
#define JMenuItem_KEY_ESCAPE							UserInterfaceDefs_KEY_MENU_1
#define JMenuItem_KEY_DOWN 								UserInterfaceDefs_KEY_DOWN
#define JMenuItem_KEY_UP 									UserInterfaceDefs_KEY_UP

#ifdef CT_NCURSES_SUPPORT
#define JMenuItem_SEL_ITEM								'|'
#else
#define JMenuItem_SEL_ITEM								'\xBB'
#endif

#define JMenuItem_SUB_MENU									'>'



/* Los botones */
#define JButton_KEY_ENTER 								UserInterfaceDefs_KEY_MENU_X



/* Los combos */
#define JCombo_KEY_LEFT 			UserInterfaceDefs_KEY_LEFT
#define JCombo_KEY_RIGHT 			UserInterfaceDefs_KEY_RIGHT
#define JCombo_KEY_ENTER 			UserInterfaceDefs_KEY_MENU_X



/* Las listas */
#define JList_KEY_LEFT 				UserInterfaceDefs_KEY_LEFT
#define JList_KEY_RIGHT 			UserInterfaceDefs_KEY_RIGHT
#define JList_KEY_ENTER 			UserInterfaceDefs_KEY_MENU_X

#ifdef CT_NCURSES_SUPPORT
#define JList_SEL_ITEM_CHAR			'|'
#else
#define JList_ITEM_CHAR			        '|'
#endif

/* Las grillas */
#define JGrid_KEY_UP 					UserInterfaceDefs_KEY_UP
#define JGrid_KEY_DOWN 				UserInterfaceDefs_KEY_DOWN
#define JGrid_KEY_ENTER 			UserInterfaceDefs_KEY_MENU_X

#ifdef CT_NCURSES_SUPPORT
#define JGrid_SEL_ITEM				'|'
#else
#define JGrid_SEL_ITEM				'\xBB'
#endif
/* Los checkBoxList*/
#define JCheckBoxList_KEY_UP      UserInterfaceDefs_KEY_UP
#define JCheckBoxList_KEY_DOWN    UserInterfaceDefs_KEY_DOWN
#define JCheckBoxList_KEY_ENTER   UserInterfaceDefs_KEY_MENU_X
#define JCheckBoxList_KEY_RIGHT   UserInterfaceDefs_KEY_RIGHT
#define JCheckBoxList_KEY_LEFT    UserInterfaceDefs_KEY_LEFT

/* El ScrollBar que no existe pero que si se dibuja */

// flecha abajo ('\xB4')
// flecha izquierda ('\x7F')
// flecha arriba ('\xB3')
// flecha derecha ('\x7E')
// flecha arriba/abajo ('\xE8')
// flecha tres lineas horizaontales ('\xEF')

#define JScrollBar_TOP_PAGE_IMAGE				'\x7E'
#define JScrollBar_MIDDLE_PAGE_IMAGE		'-'
#define JScrollBar_BOOTOM_PAGE_IMAGE		'\x7F'

// nada
#define JScrollBar_ONLY_ONE_PAGE_IMAGE		' '	
												
/**
 * Define la interfaz de los componentes visuales del esquemade ventanas definido.
 * El origen (x, y) es (1, 1).
 */
@interface  JComponent: Object
{
	JEVENT_QUEUE 				myEventQueue;
	JGRAPHIC_CONTEXT		myGraphicContext;
	
	JCOMPONENT					myOwner;
		
	int   							myXPosition;
	int   							myYPosition;
	
	int   							myWidth;
	int									myHeight;
	
	int 								myMaxWidth;
	int									myMaxHeight;	

	BOOL   							myIsVisible;
	BOOL   							myCanFocus;
	BOOL   							myReadOnly;
	BOOL                myEnabled;
  
	BOOL								myIsFocused;
	
	BOOL								myIsLockedComponent;

	id 									myOnFocusActionObject;
	char								*myOnFocusActionMethod;

	id 									myOnBlurActionObject;
	char								*myOnBlurActionMethod;
		
	id 									myOnClickActionObject;
	char								*myOnClickActionMethod;

	id 									myOnChangeActionObject;
	char								*myOnChangeActionMethod;
	
	id 									myOnSelectActionObject;
	char 								*myOnSelectActionMethod;
}

/*****
 * Metodos publicos
 */

/**/
+ new;

/**/
- initialize;

/**/
- free;

/**/
- (void) initComponent;


/**/
- initWithOwner: (JCOMPONENT) aComponent;

/**
 * Configura y devuelce el owner del componente.
 */
- (void) setOwner: (JCOMPONENT) aValue;
- (JCOMPONENT) getOwner;

/**
 *
 * @visibility public
 */
- (void) setXPosition: (int) aPosition;
- (int) getXPosition;

/**
 *
 * @visibility public
 */
- (void) setYPosition: (int) aPosition;
- (int) getYPosition;

/**
 * @throws UI_INDEX_OUT_OF_RANGE_EX
 * @visibility public
 */
- (void) setWidth: (int) aWidth;

/**
 *
 * @visibility public
 */
- (int) getWidth;

/**
 * @throws UI_INDEX_OUT_OF_RANGE_EX
 * @visibility public
 */
- (void) setHeight: (int) aHeight;

/**
 *
 * @visibility public
 */
- (int) getHeight;

/**
 * Devuelve myWidth * myHeight
 */
- (int) getComponentArea;

/**
 *
 * @visibility public
 */
- (void) setVisible: (int) aValue;
- (BOOL) isVisible;


/**
 * Le avisa al componente que obtuvo el foco
 * @visibility public
 */
- (void) doFocusComponent;

/**
 * Le avisa al contro que perdio el foco
 * @visibility public
 */
- (void) doBlurComponent;

/**
 *
 */
//- (void) setFocus: (BOOL) aValue;
- (BOOL) isFocused;


/**
 *
 * @visibility public
 */
- (void) setCanFocus: (BOOL) aValue;
- (BOOL) canFocus;

/**
 *
 * @visibility public
 * El metodo setReadOnly llamada a doReadOnlyMode().
 */
- (void) setReadOnly: (BOOL) aValue;
- (BOOL) isReadOnly;

/**
 *
 * @visibility public
  */
- (void) setEnabled: (BOOL) aValue;
- (BOOL) isEnabled;

/**
 *	@visibility protected
 *	Es un metodo hook para cuando cambia el modo del control a ReadOnly o No-ReadOnly
 */
- (void) doReadOnlyMode: (BOOL) aValue;

/**
 *
 * @visibility public
 */
- (BOOL) processKey: (int) aKey isKeyPressed: (BOOL) isPressed;

/**
 * Configura el control para que se vizualice solo
 * si esta en la parte visible de la pantalla virtual.
 * @visibility public
 */
- (void) showComponent;

/**
 * Oculta el componente
 * @visibility public
 */
- (void) hideComponent;


/**
 *
 * @visibility public
 */
- (void) validateComponent;


/****
 * Metodos protegidos para reimplementar
 */

/**
 *
 * @visibility protected
 */
- (void) doShow;

/**
 *
 * @visibility protected
 */
- (void) doHide;

/**
 *
 */
- (void) setGraphicContext: (JGRAPHIC_CONTEXT) aGraphicContext;

/**
 * Recibe el mensaje para repintarse.
 * Invoca directamente a doDraw().
 * Es reimplementado por JContainer para pintar el contenedor con su propio contexto.
 * @visibility public
 */
- (void) paintComponent;

/**
 * Este metodo debe ser reimplementado por los controles para
 * repintarse adecuadamente.
 * Los controles deben pintar a partir de su origen (myXPosition, myYPosition).
 * El GraphicContext se encarga de mapear ese origen al origen real del control.
 * @visibility protected
 */
- (void) doDraw: (JGRAPHIC_CONTEXT) aGraphicContext;

/**
 * Invoca a doDraw().
 */
- (void) drawCursor;

/**
 * Posciona el cursor y lo blinquea o no.
 * Por defecto apaga el cursor y lo posiciona en (myXPosition, myYPosition).
 * Puede ser reimplementado por las subclases para hacer lo que se considere adecuado.
 */
- (void) doDrawCursor: (JGRAPHIC_CONTEXT) aGraphicContext;

/**
 * Se invoca para que el componente obtenga el foco
 * @visibility protected
 */
- (void) doFocus;

/**
 * Se invoca para que el componente salga del foco.
 * @visibility protected
 */
- (void) doBlur;

/**
 * Procesa el mensaje. 
 * Es llamado por  JApplication.
 * Si el componente tiene un componente activo le envia el mensaje a ese.
 * Devuelve FALSE si recibe un mensaje CLOSE y TRUE en caso contrario.
 */
- (BOOL) doProcessMessage: (JEvent *) anEvent;
 
/**
 * El formulario recibe una tecla presionada mediante este mensaje.
 * Es ejecutado por processWindowMessages().
 * @param aKey (int) la tecla presionada y recibida por el form
 * @param isPressed (int) TRUE si la tecla se presiono (OnPressed) y FALSE si
 * la tecla se solto (OnReleased).
 * Devuelve TRUE si es que la tecla fue procesada y FALSE si la tecla no
 * fue usada.
 * La tecla se recibe en la sub sub clase de Window y esta la va enviando hacia
 * arriba a las superclases si es que no la necesita procesar. Cuando llega, si
 * es que llega a JWindow, se la envia al control con el foco actual, y si el control
 * no la necesita procesar la procesa la ventana en JWindow.
 * @visibility private
 */
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) anIsPressed;


/**
 *
 * @visibility protected
 */
- (void) doValidate;


/**
 * Envia un mensaje de repintado
 */
- (void) sendPaintMessage;

/**
 * En TRUE si permite que el componente se pinte y en FALSE en caso contrario.
 * En general se lo pone en FALSE cuando se realizan operaciones intensivas
 * sobre  el comonente y no queres que se ande repintando constantemente.
 */
- (void) lockComponent;
- (void) unlockComponent;
- (void) setLockedComponent: (BOOL) aValue;
- (BOOL) isLockedComponent;

/**
 * Se dispara cuando cambia la propiedad isLockComponent del componente.
 * Las subclases pueden colgarse del evento para tomar decisiones adecuadas.
 * Por ejemplo, es posible usarlo para cuando un componente dispara un timer para
 * refrescar la pantalla, entonces si se recibe el lockComponent entonces
 * debe detener el timer y si recibe unlockComponent entonces lo debe disparar.
 */
- (void) onChangeLockComponent: (BOOL) isLocked;

/**
 * Usado por los executeObXXXXAction() para ejecutar la accion correspondiente. 
 * @visibility private
 */
- (void) executeOnActionMethod: (id) anObject action: (char *) anAction;

/**
 * Los eventos que disparan los componentes.
 * @visibility public
 **/

 
/**
 * Se ejecuta cuando el componente recibe el foco.
 */
- (void) setOnFocusAction: (id) anObject action: (char *) anAction;
- (BOOL) hasOnFocusAction;
- (void) executeOnFocusAction;

/**
 * Se ejecuta cuando el componente pierde el foco.
 */
- (void) setOnBlurAction: (id) anObject action: (char *) anAction;
- (BOOL) hasOnBlurAction;
- (void) executeOnBlurAction;


/**
 * Se ejecuta al presionar enter sobre el control
 */
- (void) setOnClickAction: (id) anObject action: (char *) anAction;
- (BOOL) hasOnClickAction;
- (void) executeOnClickAction;

/**
 * Se ejecuta al cambiar el texto de un control
 */
- (void) setOnChangeAction: (id) anObject action: (char *) anAction;
- (BOOL) hasOnChangeAction;
- (void) executeOnChangeAction;

/**
 * Se ejecuta al cambiar la posicion del control de seleccion (combo , lista) : al
 * presionar flechas arriba o flecha abajo.
 */
- (void) setOnSelectAction: (id) anObject action: (char *) anAction;
- (BOOL) hasOnSelectAction;
- (void) executeOnSelectAction;


@end

#endif

