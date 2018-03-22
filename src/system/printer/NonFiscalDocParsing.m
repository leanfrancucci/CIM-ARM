#include "NonFiscalDocParsing.h"

@implementation NonFiscalDocParsing

/**/
- (void) printReport: (char*) aReport copiesQty: (int) aCopiesQty
{
  [self printReport: aReport copiesQty: aCopiesQty printLogo: TRUE];
}

/**/
- (void) printReport: (char*) aReport copiesQty: (int) aCopiesQty printLogo: (BOOL) aPrintLogo
{
  int i;

  for ( i=0; i<aCopiesQty; ++i) {
		if (aPrintLogo) {
			[myPrinterInterface printLogo: BASE_APP_PATH "/logos/default.logo"];
		}
        
    [myPrinterInterface printText: aReport];
    
    // esto solo se ejecuta para cuando la cantidad de copias es mayor a 1. (la ultima copia no se tiene en cuenta)
    if ((aCopiesQty > 1) && (i != aCopiesQty-1)){
			if ([self getAdvanceLineQty] != 0) [myPrinterInterface advancePaper: [self getAdvanceLineQty]];              
			else [myPrinterInterface advancePaper];
		}
	}
	
}

/**/
- (void) printTicket: (char*) aFormatFileName copiesQty: (int) aCopiesQty tree: (scew_tree*) tree
{
  int i;

  [self processDocument: aFormatFileName finalDoc: doc tree: tree];

  for ( i=0; i<aCopiesQty; ++i)
    [myPrinterInterface printText: doc];
}

/**/
- (void) clean
{
  [myPrinterInterface clean];
}


@end
