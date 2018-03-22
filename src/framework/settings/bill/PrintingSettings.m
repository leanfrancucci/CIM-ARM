#include "PrintingSettings.h"
#include "Persistence.h"
#include "UserManager.h"
#include "Audit.h"
#include "PrinterSpooler.h"
#include "MessageHandler.h"

static id singleInstance = NULL;

@implementation PrintingSettings

static char myPrintingSettingsMessageString[] 		= "Configuracion";

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}

/**/
+ getInstance
{
	return [self new];		
}

/**/
- initialize
{
	return[[[Persistence getInstance] getPrintingSettingsDAO] loadById: 1];
}

/**/
- (void) setPrintingSettingsId: (int) aValue { myPrintingSettingsId = aValue; }
- (void) setPrinterType: (int) aValue { myPrinterType = aValue; }
- (void) setLinesQtyBetweenTickets: (int) aValue { myLineQtyBetweenTickets = aValue; }
- (void) setPrintTickets: (PrintingType) aValue { myPrintTickets = aValue; }
- (void) setPrintNextHeader: (BOOL) aValue { myPrintNextHeader = aValue; }
- (void) setAutoPaperCut: (BOOL) aValue { myAutoPaperCut = aValue; }
- (void) setCopiesQty: (int) aValue { myCopiesQty = aValue; }
- (void) setPrintZeroTickets: (BOOL) aValue { myPrintZeroTickets = aValue; }
- (void) setPrinterCOMPort: (int) aValue { myPrinterCOMPort = aValue; }
- (void) setPrinterCode: (char*) aValue { stringcpy(myPrinterCode, aValue); }
- (void) setUpdateDate: (datetime_t) aValue { myUpdateDate = aValue; }

/**/	
- (int) getPrintingSettingsId { return myPrintingSettingsId; }
- (PrinterType) getPrinterType { return myPrinterType; }
- (int) getLinesQtyBetweenTickets { return myLineQtyBetweenTickets; }
- (PrintingType) getPrintTickets { return myPrintTickets; }
- (BOOL) getPrintNextHeader { return myPrintNextHeader; }
- (BOOL) getAutoPaperCut { return myAutoPaperCut; }
- (int) getCopiesQty { return myCopiesQty; }
- (BOOL) getPrintZeroTickets { return myPrintZeroTickets; }
- (int) getPrinterCOMPort { return myPrinterCOMPort; }
- (char*) getPrinterCode { return myPrinterCode; }
- (datetime_t) getUpdateDate { return myUpdateDate; }


/**/
- (void) applyChanges
{
	id printingSettingsDAO;
	printingSettingsDAO = [[Persistence getInstance] getPrintingSettingsDAO];		

  myUpdateDate = [SystemTime getLocalTime];
	[printingSettingsDAO store: self];
	[[PrinterSpooler getInstance] setLinesQtyBetweenTickets: myLineQtyBetweenTickets];
}

/**/
- (void) restore
{
	[self initialize];
}

/**/
- (STR) str
{
  return getResourceStringDef(RESID_SAVE_CONFIGURATION_QUESTION, myPrintingSettingsMessageString);
}

@end

