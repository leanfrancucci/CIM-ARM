#include "PrinterInterface.h"
#include "util.h"

@implementation PrinterInterface

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
  myDriver = NULL;
	return self;
}

/**/
- (void) initWithDriver: (id) aDriver
{
  myDriver = aDriver;
}

/**/
- (void) setFiscalHeaderFooter: (int) aLine text: (char*) aText withContent: (BOOL) aWithContent isHeader: (BOOL) isHeader
{
  [myDriver setFiscalHeaderFooter: aLine text: aText withContent: aWithContent isHeader: isHeader];
}

/**/
- (void) openFiscalVoucher
{
  [myDriver openFiscalVoucher];
}

/**/
- (unsigned long) closeFiscalVoucher
{
  return [myDriver closeFiscalVoucher];
}

/**/
- (void) setHeader
{
  [myDriver setHeader];
}

/**/
- (void) printFiscalText: (char*) aText
{
  [myDriver printFiscalText: aText];
}

/**/
- (void) addLineItem: (char*) aText qty: (double) aQty amountPerUnit: (double) anAmountPerUnit tax: (double) aTax totalAmount: (double) aTotalAmount
{
  [myDriver addLineItem: aText qty: aQty amountPerUnit: anAmountPerUnit tax: aTax totalAmount: aTotalAmount];
}

/**/
- (void) openCommonVoucher
{
  [myDriver openCommonVoucher];
}

/**/
- (void) closeCommonVoucher
{
  [myDriver closeCommonVoucher];
}

/**/
- (void) printText: (char*) aText
{
  [myDriver printText: aText];
}

/**/
- (void) closeX
{
  [myDriver closeX];
}

/**/
- (void) closeZ
{
  [myDriver closeZ];
}

/**/
- (void) getPrinterStatus
{
  return [myDriver getPrinterStatus];
}  

/**/
- (void) advancePaper
{
  [myDriver advancePaper];
}

/**/
- (void) advancePaper: (int) aQty
{
   [myDriver advancePaper: aQty];
}

/**/
- (void) cutPaper
{
  [myDriver cutPaper];
}

/**/
- (void) clean
{
  [myDriver clean];
}

/**/
- (void) resetVoucher
{
  [myDriver resetVoucher];
}

/**/
- (char*) getFormatSubdirectory: (char*) aFormatSubdirectory
{
  return [myDriver getFormatSubdirectory: aFormatSubdirectory];
}

/**/
- (int) getPrinterWidth
{
  return [myDriver getPrinterWidth];
}

/**/
- (void) openCashDrawer
{
  [myDriver openCashDrawer];
}

/**/
- (void) setFiscalCloseObserver: (id) anObserver
{
  [myDriver setFiscalCloseObserver: anObserver];
}

/**/
- (unsigned long) getLastZFiscalCloseNumber
{
  return [myDriver getLastZFiscalCloseNumber];
} 

/**/
- (void) zFiscalCloseReport: (unsigned long) fiscalNumber
{
  [myDriver zFiscalCloseReport: fiscalNumber];
}

/**/
- (void) printLogo: (char*) aFileName
{
   [myDriver printLogo: aFileName];
}


@end
