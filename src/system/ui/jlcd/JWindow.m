#include <assert.h>
#include "util.h"
#include "osrt.h"
#include "UserInterfaceExcepts.h"
#include "UserInterfaceDefs.h"
#include "JWindow.h"

//#define printd(args...) doLog(args)
#define printd(args...)

static JWINDOW _myActiveWindow = NULL;

/**
 *
 *
 */

@implementation  JWindow

/* se define para evitar el warning */
- (void) printerStateNotification: (int) aPrinterState
{
}

/***
 * Metodos Publicos
 */

/**/
+ (JWINDOW) getActiveWindow
{
	return _myActiveWindow;
}

/**/
- (void) initComponent
{
 	[super initComponent];

	[self lockWindowsUpdate];
	
	[myGraphicContext setXPosition: myXPosition];
	[myGraphicContext setYPosition: myYPosition];
	
	myWidth = [myGraphicContext getWidth];
	myHeight = [myGraphicContext getHeight];

	myCanFocus = TRUE;
	myCanClose = TRUE;	

	myParentWindow = NULL;

	myOnCloseWindowHandler = NULL;

	[self doCreateWindow];
}

/**/
- free
{
	[self doDestroyWindow];
	
	return [super free];
}

/**/
+ createWindow: (JWINDOW) aParentWindow
{
	JWINDOW w;
	
	w = [self new];		
	[w setParentWindow: aParentWindow];
	return w;
}

- (void) setParentWindow: (JWINDOW) aParentWindow { myParentWindow = aParentWindow; }
- (JWINDOW) getParentWindow { return myParentWindow; }

/**/
- (void) setCanClose: (BOOL) aValue { myCanClose = aValue; }
- (BOOL) canClose { return myCanClose; }

/**/
- (void) openWindow
{
	[self openWindowWithModalMode: FALSE];
}

/**/
- (void) openModalWindow
{	
	[self openWindowWithModalMode: TRUE];
}

/**/
- (void) openWindowWithModalMode: (BOOL) aModal
{
	BOOL parentWindowsWasActivated;

	myModalMode = aModal;
	
	/* Esto es para prevenir que el mensaje lo reciba otr ventana */
	myIamClosing = FALSE; 
		
	parentWindowsWasActivated = FALSE;
	if (myParentWindow != NULL) {
		
		parentWindowsWasActivated = [myParentWindow isActiveWindow];
		[myParentWindow deactivateWindow];
	}
	
	[self focusFirstComponent];	
	
	[self doOpenWindow];	
	
	[self activateWindow];
	
	/* Procesa todos los mensajes que haya en la cola de mensajes */
	if (myModalMode == TRUE) {		
				
		[self doProcessMessages];
		[self deactivateWindow];

		if (myParentWindow != NULL) {
			if (parentWindowsWasActivated) {
				// una de las mayores chanchadas posibles, pero efectivo si no queremos repintar el
				// menu principal dos veces luego de volver de un formulario
				if (strcmp([myParentWindow name], "JMainMenuForm") == 0) {
					[myParentWindow activateWindow2];
				}
				else {
					[myParentWindow activateWindow];
				}
			}
		} else {
			[self sendPaintMessage];
		}
	}
}

/**/
- (void) doProcessMessages
{
	BOOL 			exception;
	JEvent		evt;

	exception = FALSE;
	
	while (TRUE) {						

		TRY

			evt.evtid = JEventQueueMessage_NONE;
			[myEventQueue getJEvent: &evt];
			
			if (![self doProcessMessage: &evt])
					BREAK_TRY;
						
		CATCH

			exception = TRUE;
			ex_printfmt();
		
			/* Metodo de clase que dispara un dialogo mostrando la excepcion actual */	
			[self showDefaultExceptionDialog];
			
		END_TRY;
		
		if (exception) 
			exception = FALSE;
	}
}

/**/
- (BOOL) doProcessMessage: (JEvent *) anEvent
{

	 switch(anEvent->evtid) {

			/* Close Event */
				case JEventQueueMessage_CLOSE:
					printd("JWindow -> CLOSE\n");
					/* Esto es para prevenir que el mensaje lo reciba otr ventana 
					   Si no se ejecuto el closeForm() en esta ventana el mensaje es descartado */
					if (myIamClosing) {					
						/* Si myCanClose es TRUE entonces devuelve FALSE para que se cierre la vetana,
					   	si es FALSE devuelve TRUE para que no se puea cerrar. */
						myIamClosing = FALSE;
						if (myCanClose) {
							[self doCloseWindow];
							return FALSE;
						}
					}
					
					return TRUE;

			/* Paint Event */
	 			case JEventQueueMessage_PAINT:
					[self paintComponent];					
					return TRUE;

			/* Key Pressed Event */
				case JEventQueueMessage_KEY_PRESSED:
					[self processKey: anEvent->event.keyEvt.keyPressed
																							isKeyPressed: anEvent->event.keyEvt.isPressed];
		
					return TRUE;
			
			/* Falta de papel */						
				case JEventQueueMessage_PRINTER_STATE:
					[self printerStateNotification: anEvent->evtParam1];
					return TRUE;
          
			/**/		
				default:
				
					break;
		}
		
		return TRUE;
}


/**/
- (void) processApplicationMessages
{
	JEvent		evt;
	
		while (TRUE) {
		
			if ([myEventQueue getMessageCount] == 0)
				return;
			
			evt.evtid = JEventQueueMessage_NONE;
			[myEventQueue getJEvent: &evt];						
						
			if (![self doProcessMessage: &evt])
				return;
		}
}

/**/
- (void) closeWindow         
{
	JEvent		evt;

	myIamClosing = TRUE; /* Esto es para prevenir que el mensaje lo reciba otr ventana */
	evt.evtid = JEventQueueMessage_CLOSE;
	[myEventQueue putJEvent: &evt];
}


/**/
- (void) doCreateWindow
{
	[self onCreateWindow];
}


/**/
- (void) doDestroyWindow
{
	[self onDestroyWindow];
}

/**/
- (void) doOpenWindow
{
	[self onOpenWindow];
}

/**/
- (void) doCloseWindow
{
	/*int i;
	int msgCount;
	JEvent evt;
	int hasPaintMsg = FALSE;
*/
	[self onCloseWindow];

	if (myOnCloseWindowHandler != NULL) [myOnCloseWindowHandler onCloseWindow: self];

//	doLog("doCloseWindow = %s\n", [self str]);

	// Elimino todos los mensajes de la cola menos el de Pintado
/*	msgCount = [myEventQueue getMessageCount];
	for (i = 0; i < msgCount; ++i)
	{
		[myEventQueue getJEvent: &evt];
		if (evt.evtid == JEventQueueMessage_PAINT) hasPaintMsg = TRUE;
	}

	if (hasPaintMsg) {
		evt.evtid = JEventQueueMessage_PAINT;
		[myEventQueue putJEvent: &evt];
	}
	*/
}


/**/
- (void) onCreateWindow
{	
}

/**/
- (void) onDestroyWindow
{	
}


/**/
- (void) onOpenWindow
{	
}

/**/
- (void) onCloseWindow
{
}

/**/
- (void) showDefaultExceptionDialogWithExCode: (int) anExceptionCode
{
	//doLog(0,"JWindow -> showDefaultExceptionDialogWithExCode, class = %s\n", [self str]);
	THROW( ABSTRACT_METHOD_EX );
}

/**/
- (void) showDefaultExceptionDialog
{
	[self showDefaultExceptionDialogWithExCode: ex_get_code()];
}

/**/
- (void) lockWindowsUpdate
{
	[self lockComponent];
}

/**/
- (void) unlockWindowsUpdate
{	
	[self unlockComponent];	
}

/**/
- (BOOL) isActiveWindow
{
	return ![self isLockedComponent];
}

/**/
- (void) activateWindow
{		
	[self doFocusComponent];
	[self unlockWindowsUpdate];
	[self sendPaintMessage];	
	[self onActivateWindow];
	_myActiveWindow = self;
}

/**/
- (void) activateWindow2
{		
	[self doFocusComponent];
	[self unlockWindowsUpdate];
	[self onActivateWindow];
	_myActiveWindow = self;
}

/**/
- (void) deactivateWindow
{
	[self doBlurComponent];
	[self lockWindowsUpdate];
	[self onDeactivateWindow];	
}

/**/
- (void) onActivateWindow
{
}

/**/
- (void) onDeactivateWindow
{
}


/**
 * Reimplementa el metodo enviando el mensaje clear al LCD.
 * Se hace asi para evitar un refresh titilante perceptible al usuario.
 * Porque la ventana limpia su zona imprimible y tambin lo hacen los contenedores que
 * esta contiene.
 * Se supone las ventanas del tamanio igual al area total del lcd.
 */
- (void) clearContainerScreen
{
	assert(myGraphicContext != NULL);
	[myGraphicContext clearScreen];
}

/**/
- (void) setOnCloseWindowHandler: (id) anObject
{
	myOnCloseWindowHandler = anObject;
}

/**/
- (id) getOnCloseWindowHandler
{
	return myOnCloseWindowHandler;
}
@end

