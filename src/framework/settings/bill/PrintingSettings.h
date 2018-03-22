#ifndef PRINTING_SETTINGS_H
#define PRINTING_SETTINGS_H

#define PRINTING_SETTINGS id

#include "Object.h"
#include "ctapp.h"
#include "util.h"
#include "SystemTime.h"

/**
 * Clase  
 */

@interface PrintingSettings:  Object
{
	int myPrintingSettingsId;
	PrinterType myPrinterType;
	int myLineQtyBetweenTickets;
	PrintingType myPrintTickets; 
	BOOL myPrintNextHeader;
	BOOL myAutoPaperCut;
	int myCopiesQty;
  BOOL myPrintZeroTickets;
  int myPrinterCOMPort;
  char myPrinterCode[30];
  datetime_t myUpdateDate;
}

/**
 * 
 */

+ new;
+ getInstance;
- initialize;

/**
 * Setea los valores correspondientes a la configuracion general de la impresion
 */

- (void) setPrintingSettingsId: (int) aValue;
- (void) setPrinterType: (int) aValue;
- (void) setLinesQtyBetweenTickets: (int) aValue;
- (void) setPrintTickets: (PrintingType) aValue;
- (void) setPrintNextHeader: (BOOL) aValue;
- (void) setAutoPaperCut: (BOOL) aValue;
- (void) setCopiesQty: (int) aValue;
- (void) setPrintZeroTickets: (BOOL) aValue;
- (void) setPrinterCOMPort: (int) aValue;
- (void) setPrinterCode: (char*) aValue;
- (void) setUpdateDate: (datetime_t) aValue;

/**
 * Devuelve los valores correspondientes a la configuracion general de la impresion
 */	

- (int) getPrintingSettingsId;
- (PrinterType) getPrinterType;
- (int) getLinesQtyBetweenTickets;
- (PrintingType) getPrintTickets;
- (BOOL) getPrintNextHeader;
- (BOOL) getAutoPaperCut;
- (int) getCopiesQty;
- (BOOL) getPrintZeroTickets;
- (int) getPrinterCOMPort;
- (char*) getPrinterCode;
- (datetime_t) getUpdateDate;

/**
 * Aplica los cambios realizados sobre la instancia de la configuracion de la impresion
 */

- (void) applyChanges;

/**
 * Restaura los valores que se encuentran almacenados en la persistencia
 */

- (void) restore;


@end

#endif

