#include "BillSettings.h"
#include "Persistence.h"
#include "SettingsExcepts.h"
#include "util.h"
#include "UserManager.h"
#include "PrinterSpooler.h"
#include "MessageHandler.h"

static id singleInstance = NULL;

@implementation BillSettings

static char myBillSettingsMessageString[] 		= "Configuracion";

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
	return[[[Persistence getInstance] getBillSettingsDAO] loadById: 1];
}


/**/
- (void) setBillSettingsId: (int) aBillSettingsId {	myBillSettingsId = aBillSettingsId; }
- (int) getBillSettingsId { return myBillSettingsId; }	
					
/**/
- (void) setNumeratorType: (TicketNumeratorType) aValue {	myNumeratorType = aValue; }
- (void) setTicketType: (BillModeType) aValue { myTicketType = aValue; }
- (void) setTicketReprint: (BOOL) aValue { myTicketReprint = aValue; }
- (void) setViewRoundFactor: (BOOL) aValue { myViewRoundFactor = aValue; }
- (void) setViewRoundAdjust: (BOOL) aValue { myViewRoundAdjust = aValue; }
- (void) setTaxDiscrimination: (BOOL) aValue { myTaxDiscrimination = aValue; }
- (void) setMinAmount: (money_t) aValue { 	myMinAmount = aValue; }
- (void) setHeader1: (char*) aValue { strncpy2(myHeader1, aValue, sizeof(myHeader1) - 1); }
- (void) setHeader2: (char*) aValue { strncpy2(myHeader2, aValue, sizeof(myHeader2) - 1); }
- (void) setHeader3: (char*) aValue { strncpy2(myHeader3, aValue, sizeof(myHeader3) - 1); }
- (void) setHeader4: (char*) aValue { strncpy2(myHeader4, aValue, sizeof(myHeader4) - 1); }
- (void) setHeader5: (char*) aValue { strncpy2(myHeader5, aValue, sizeof(myHeader5) - 1); }
- (void) setHeader6: (char*) aValue { strncpy2(myHeader6, aValue, sizeof(myHeader6) - 1); }
- (void) setFooter1: (char*) aValue { strncpy2(myFooter1, aValue, sizeof(myFooter1) - 1); }
- (void) setFooter2: (char*) aValue { strncpy2(myFooter2, aValue, sizeof(myFooter2) - 1); }
- (void) setFooter3: (char*) aValue { strncpy2(myFooter3, aValue, sizeof(myFooter3) - 1); }
- (void) setDigitsQty: (int) aValue { myDigitsQty = aValue; }
- (void) setTicketQtyViewWarning: (int) aValue { myTicketQtyViewWarning = aValue; }
- (void) setDateChange: (datetime_t) aValue { myDateChange = aValue; }
- (void) setTransport: (BOOL) aValue { myTransport = aValue; }
- (void) setPrefix: (char*) aValue { strncpy2(myPrefix, aValue, sizeof(myPrefix) - 1); }
- (void) setInitialNumber: (long) aValue { myInitialNumber = aValue; }
- (void) setFinalNumber: (long) aValue { myFinalNumber = aValue; }
- (void) setTicketMaxItemsQty: (int) aValue { myMaxItemsQty = aValue; }
- (void) setOpenCashDrawer: (BOOL) aValue { myOpenCashDrawer = aValue; }
- (void) setRequestCustomerInfo: (BOOL) aValue { myRequestCustomerInfo = aValue; }
- (void) setIdentifierDescription: (char*) aValue { strncpy2(myIdentifierDescription, aValue, sizeof(myIdentifierDescription) - 1); }
                                                           

/**/	
- (TicketNumeratorType) getNumeratorType { return myNumeratorType; }
- (BillModeType) getTicketType { return myTicketType; }
- (BOOL) getTicketReprint { return myTicketReprint; }
- (BOOL) getViewRoundFactor { return myViewRoundFactor; }
- (BOOL) getViewRoundAdjust { return myViewRoundAdjust ; }
- (BOOL) getTaxDiscrimination { return myTaxDiscrimination; }
- (money_t) getMinAmount { return myMinAmount; }
- (char*) getHeader1 { return myHeader1; }
- (char*) getHeader2 { return myHeader2; }
- (char*) getHeader3 { return myHeader3; }
- (char*) getHeader4 { return myHeader4; }
- (char*) getHeader5 { return myHeader5; }
- (char*) getHeader6 { return myHeader6; }
- (char*) getFooter1 { return myFooter1; }
- (char*) getFooter2 { return myFooter2; }
- (char*) getFooter3 { return myFooter3; }
- (int) getDigitsQty { return myDigitsQty; }
- (int) getTicketQtyViewWarning { return myTicketQtyViewWarning; }
- (datetime_t) getDateChange { return myDateChange; }
- (BOOL) getTransport { return myTransport; }
- (char*) getPrefix { return myPrefix; }
- (long) getInitialNumber { return myInitialNumber; }
- (long) getFinalNumber{ return myFinalNumber; }
- (int) getTicketMaxItemsQty { return myMaxItemsQty; }
- (BOOL) getOpenCashDrawer { return myOpenCashDrawer; }
- (BOOL) getRequestCustomerInfo { return myRequestCustomerInfo; }
- (char*) getIdentifierDescription { return myIdentifierDescription; }


/**/
- (void) applyChanges
{
	id billSettingsDAO;
	billSettingsDAO = [[Persistence getInstance] getBillSettingsDAO];		

	[billSettingsDAO store: self];

  // Se setean los encabezados y pies en la impresora --> esto se dara solo para las fiscales.
  [[PrinterSpooler getInstance] setHeaderFooterInfo: myHeader1 header2: myHeader2 
                                            header3: myHeader3 header4: myHeader4
                                            header5: myHeader5 header6: myHeader6 
																						footer1: myFooter1 footer2: myFooter2 footer3: myFooter3];  
    
}

/**/
- (void) restore
{
	//doLog(0,"BillSettings -> restore\n");fflush(stdout);
	[self initialize];
}

/**/
- (STR) str
{
  return getResourceStringDef(RESID_SAVE_CONFIGURATION_QUESTION, myBillSettingsMessageString);
}

@end


