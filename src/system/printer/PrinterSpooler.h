#ifndef PRINTER_SPOOLER_H
#define PRINTER_SPOOLER_H

#define PRINTER_SPOOLER id

#include <Object.h>
#include "DocParsing.h"
#include "NonFiscalDocParsing.h"
#include "DummyDocParsing.h"
#include "SyncQueue.h"
#include "StaticSyncQueue.h"
#include "ThermalDriver.h"
#include "SerialDriver.h"
#include "system/dev/all.h"

#ifdef CT_INCLUDE_PARALLEL_PRINTER
#include "ParallelDriver.h"
#endif

// para prueba
#include "scew.h"



/**
 *	Acciones a realizar ante la falta de papel.
 *	SpoolerAction_REPRINT cuando desea reimprimir el trabajo.
 *  SpoolerAction_CANCEL cuando desea cancelar el trabajo.
 */
typedef enum {
	SpoolerAction_REPRINT,
	SpoolerAction_CANCEL
} SpoolerAction;

/**
 *	Spooler de impresion a la cual se le agregan trabajos que imprime.
 */
@interface PrinterSpooler : OThread
{
  DOC_PARSING myDocParsing;
	SYNC_QUEUE queue;		// Cola sincronizada
	STATIC_SYNC_QUEUE actionQueue;
  int myPrinterType;
  id myPrinterStateListener;
  COLLECTION myPrinterStateListeners;
  int myPrinterCOMPort;
  id myPrinter;
	BOOL myHasCancelJobs;
	int myAdvanceLineQty;
	char myReportPathByLanguage[10];
}

/**
 *
 */
+ getInstance;

/**
 *
 */
- (int) getJobCount;

/**
 *	Devuelve si la ultima accion realizada fue cancelar trabajos de impresion.
 */
- (BOOL) hasCancelJobs;

/**
 *
 */
- (void) setDocParsing: (DOC_PARSING) aDocParsing; 

/**
 * Agrega un trabajo al spooler de impresion
 */
- (void) addPrintingJob: (int) aType copiesQty: (int) aCopiesQty ignorePaperOut: (BOOL) aIgnorePaperOut tree: (scew_tree*) tree;

/**
 *
 */
- (void) addPrintingJob: (int) aType copiesQty: (int) aCopiesQty ignorePaperOut: (BOOL) aIgnorePaperOut tree: (scew_tree*) tree additional: (unsigned long) anAdditional;
 
/**
 *
 */
- (void) printX;

/**
 *
 */
- (void) printZ;

/**
 *
 */
- (void) setPrinterStateListener: (id) aListener; 

/**
 *
 */
- (void) reprintLastJob;

/**
 * 
 */
- (void) cancelLastJob; 

/**
 *
 */
- (void) setHeaderFooterInfo: (char*) aHeader1 header2: (char*) aHeader2 header3: (char*) aHeader3 header4: (char*) aHeader4
                                               header5: (char*) aHeader5 header6: (char*) aHeader6 footer1: (char*) aFooter1
																							 footer2: (char*) aFooter2 footer3: (char*) aFooter3;  
                                            
/**
 *
 */                                                  
- (void) setPrinterType: (int) aPrinterType;                                               

/**
 *
 */
- (void) setPrinterCOMPort: (int) aCOMPort; 

/**
 *
 */
- (void) initSpooler; 

/**
 *
 */
- (void) resetVoucher; 

/**
 * Observer para avisar que se ha impreso con exito un ticket completo.
 */
- (void) setPendingTicketsObserver: (id) anObserver; 

/**
 * Observer para avisar que se ha impreso/generado un ticket/cierre fiscal.
 */
- (void) setFiscalCloseObserver: (id) anObserver;

/**
 * Retorna el numero del ultimo cierre fiscal z generado.
 */
- (unsigned long) getLastZFiscalCloseNumber; 

/*
 *
 */
- (void) setLinesQtyBetweenTickets: (int) aValue;

/*
 * Setea la ruta a la cual hay que ir a buscar los reportes dependiendo del idioma
 * sp/
 * en/
 */
- (void) setReportPathByLanguage: (int) aValue;

/*
 * Devuelve la ruta a la cual hay que ir a buscar los reportes dependiendo del idioma
 * sp/
 * en/
 */
- (char *) getReportPathByLanguage;

@end

#endif
