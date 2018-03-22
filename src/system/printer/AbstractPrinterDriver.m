#include "AbstractPrinterDriver.h"


@implementation AbstractPrinterDriver

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	return self;
}

/**/
- (void) initDriver
{
  // No hace nada
}

/**/
- (void) printText: (char*) aText
{
  // No hace nada
}

/**/
- (void) advancePaper
{
  // No hace nada
}

/**/
- (void) advancePaper: (int) aQty
{
   // No hace nada
} 

/**/
- (void) cutPaper
{
  // No hace nada
} 

/**/
- (void) cleanBuffer
{
  // No hace nada
}

/**/
- (void) openCashDrawer
{
  // No hace nada
}

static char *nullEscapeCode = "";

/**/
- (char*) getEscapeCode: (char*) aEscapeCodeTag escapeCode: (char*) aEscapeCode  
{
	return nullEscapeCode;
}

/**/
- (void) clean
{
  // No hace nada
}

/**/
- (char*) getFormatSubdirectory: (char*) aFormatSubdirectory
{
	return NULL;
}

/**/
- (int) getPrinterWidth
{
  return 0;
}

/**/
- (void) printLogo: (char*) aFileName
{
   // No hace nada, implementado unicamente para la termica.
}

@end
