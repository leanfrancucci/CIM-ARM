#ifndef PRINTER_INTERFACE_H
#define PRINTER_INTERFACE_H

#define PRINTER_INTERFACE id

#include <Object.h>
#include "AbstractPrinterDriver.h"

/**
 *	
 */
@interface PrinterInterface : Object
{
  id myDriver;
}

/**
 *
 */
- (void) initWithDriver: (id) aDriver;
  
/**
 * 
 */
- (void) setFiscalHeaderFooter: (int) aLine text: (char*) aText withContent: (BOOL) aWithContent isHeader: (BOOL) isHeader;
 
/**
 *
 */
- (void) openFiscalVoucher;

/**
 * Cierra el comprobante fiscal y devuelve el numero fiscal generado por la impresora.
 */
- (unsigned long) closeFiscalVoucher;

/**
 *
 */
- (void) setHeader;

/**
 *
 */
- (void) printFiscalText: (char*) aText;

/**
 *
 */
- (void) addLineItem: (char*) aText qty: (double) aQty amountPerUnit: (double) anAmountPerUnit tax: (double) aTax totalAmount: (double) aTotalAmount;

/**
 * 
 */
- (void) openCommonVoucher;

/**
 *
 */
- (void) closeCommonVoucher;

/**
 *
 */
- (void) printText: (char*) aText;

/**
 *
 */
- (void) closeX;

/**
 *
 */
- (void) closeZ;

/**
 *
 */
- (void) getPrinterStatus;  

/**
 *
 */
- (void) advancePaper; 

/**
 *
 */
- (void) advancePaper: (int) aQty;

/**
 *
 */
- (void) cutPaper; 

/**
 *
 */
- (void) clean;

/**
 *
 */
- (void) resetVoucher;

/**
 *
 */
- (char*) getFormatSubdirectory: (char*) aFormatSubdirectory; 

/**
 *
 */
- (int) getPrinterWidth;

/**
 *
 */
- (void) openCashDrawer; 

/**
 *
 */
- (void) setFiscalCloseObserver: (id) anObserver;

/**
 *
 */
- (unsigned long) getLastZFiscalCloseNumber; 

/**
 *
 */
- (void) zFiscalCloseReport: (unsigned long) fiscalNumber; 

- (void) printLogo: (char*) aFileName;

@end

#endif
