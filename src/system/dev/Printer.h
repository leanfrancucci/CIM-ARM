#ifndef PRINTER_H
#define PRINTER_H
 
#define PRINTER id
 
#include <Object.h>

/**
 *	Estado de la impresora con respecto a la falta de papel.
 */
typedef enum {
	 PrinterState_PAPER_OUT,
   PrinterState_PAPER_IN
   PrinterState_PRINTER_INTERNAL_FATAL_ERROR,
   PrinterState_PRINTER_FATAL_ERROR,
   PrinterState_PRINTER_NOT_RESPONDING_BERIGUEL,
   PrinterState_PRINTER_NEEDS_CLOSE_Z,
   PrinterState_OUT_OF_LINE
} PrinterState;

/**
 *	Error por falta de papel
 */
#define OUT_OF_PAPER_ERR			-1

/**
 *	Wrapper de las funciones de impresion.
 */
@interface Printer : Object
{
	
}

/**
 *	Devuelve la unica instancia posible de este objeto.
 */
+ getInstance;

/**
 *	Imprime el texto pasado por parametro.
 *	@returns OUT_OF_PAPER_ERR si la impresora se quedo sin papel, 0 si tuvo exito.
 */
- (int) print: (char*) aBuffer;

/**
 *	Non-blocking. Returns the number of elements in the queue, waiting to be printed.
 * 	When it returns zero it means that the printer is idle. However, it might never
 * 	reach zero if it ran out of paper !!!
 *
 */
- (int) getQueueQty;

/**
 *	Non-blocking. Returns 1 if we have no paper, 0 (OK) if we do.
 */
- (BOOL) hasPaper;

/**
 * 	Blocking. Returns as soon as the printer sensor reports there is paper again.
 * 	It does not mean that it will restart printing the pending lines immediately:
 * 	TPRINTER_TRYPRINTING must be sent before. Might be used, for example, for dialogs
 * 	or on-screen icons showing that there's no paper.
 */
- (void) waitForPaper;

/**
 *	Pone la impresora en linea.
 *  Devuelve FALSE si no hay papel.
 */
- (BOOL) tryPrinting;

/**
 * 	This resets the queue, removing all pending lines. It may be issued whenever you
 * 	want, but you might get weird results if you send this while printing. 
 * 	This is useful if you want to remove pending lines after a run-out-of-paper event.
 */
- (void) cleanQueue;

/**
 *	Pone la impresora en linea.
 */
- (void) printerOnLine;

/**
 *	Comienza a avanzar el papel.
 */
- (void) startAdvancePaper;

/**
 *	Finaliza el avance de papel.
 */
- (void) stopAdvancePaper;

- (void) printLogo: (char*) aFileName;

@end

#endif
