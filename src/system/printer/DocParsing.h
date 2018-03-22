#ifndef DOC_PARSING_H
#define DOC_PARSING_H

#define DOC_PARSING id

#include <Object.h>
#include "PrinterInterface.h"
#include "scew.h"
#include "Configuration.h"
#include "FormatParser.h"
#include "util.h"


/**
 *	Clase que se encarga de parsear un documento en XML tomado de una ruta especifica.
 *  Luego de ser parseado, se llama a los metodos de la clase PrinterInterface, para 
 *  que el mismo sea impreso.
 */
@interface DocParsing : Object
{
  PRINTER_INTERFACE myPrinterInterface;
  scew_parser	*myParser;
  scew_tree	*myTree;
  char *doc;
  id myPendingTicketsObserver;
  id myFiscalCloseObserver;
  int myAdvLineQty;
}

/** 
 * Setea la interface de la impresora.
 */
- (void) setPrinterInterface: (PRINTER_INTERFACE) aPrinterInterface; 

/**
 *	Es la interface a la impresion de un fiscal X, solo se invoca a este metodo en el caso que se posea configurada
 *  una impresora fiscal. 
 */
- (void) printX;

/**
 *	Es la interface a la impresion de un fiscal Z, solo se invoca a este metodo en el caso que se posea configurada
 *  una impresora fiscal. 
 */
- (void) printZ;

/**
 *	Es la interface al parsing e impresion de documentos. 
 *	@param printingType tipo de impresion. Esto analiza si es un ticket, reporte detallado, etc..
 *	@param copiesQty cantidad de copias a imprimir. 
 */
- (void) processPrintingAction: (EntityPrintingType) aPrintingType copiesQty: (int) aCopiesQty tree: (scew_tree*) tree additional: (unsigned long) anAdditional;

/**
 *	Imprime el reporte pasado como parametro. 
 *	@param aReport el reporte a imprimir.
 *	@param copiesQty cantidad de copias a imprimir.
 */
- (void) printReport: (char*) aReport copiesQty: (int) aCopiesQty;

/**
 *	Imprime el reporte pasado como parametro. 
 *	@param aReport el reporte a imprimir.
 *	@param copiesQty cantidad de copias a imprimir.
 *	@param printLogo si imprime o no el logo (por defecto = TRUE)
 */
- (void) printReport: (char*) aReport copiesQty: (int) aCopiesQty printLogo: (BOOL) aPrintLogo;

/**
 *	Procesa el documento pasaado como parametro.
 *	@param aFormatFileName nombre del archivo de formato del documento.
 *	@param aFinalDoc donde se devuelve el documento procesado.
 */
- (char*) processDocument: (char*) aFormatFileName finalDoc: (char*) aFinalDoc tree: (scew_tree*) tree;

/**
 * Imprime el ticket.
 */
- (void) printTicket: (char*) aFormatFileName copiesQty: (int) aCopiesQty tree: (scew_tree*) tree;

/** 
 * Limpia los buffers
 */
- (void) clean;  

/**
 * Setea los encabezados y pies.
 */
- (void) setHeaders: (BOOL) withContent;
- (void) setHeadersExt;
- (void) setFooters: (BOOL) withContent;
- (void) setFootersExt;

/**
 * Resetea el comprobante, ya sea fiscal o no fiscal.
 */
- (void) resetVoucher;

/**
 *
 */
- (void) zFiscalCloseReport: (unsigned long) fiscalNumber;

/**
 *
 */
- (void) setPendingTicketsObserver: (id) anObserver; 

/**
 *
 */
- (void) setFiscalCloseObserver: (id) anObserver; 
 
/**
 *
 */
- (void) notifyPrintedTicket: (unsigned long) aTicketId fiscalTicketNumber: (unsigned long) aFiscalTicketNumber;

/**
 *
 */
- (void) setAdvanceLineQty: (int) aLineQty;

/**
 *
 */
- (int) getAdvanceLineQty;

/**
 *
 */
- (void) setAdvanceLineQty: (int) aLineQty;

@end

#endif
