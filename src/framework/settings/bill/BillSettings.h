  #ifndef BILL_SETTINGS_H
#define BILL_SETTINGS_H

#define BILL_SETTINGS id

#include "Object.h"
#include "ctapp.h"

/**
 * Clase  
 */

@interface BillSettings:  Object
{
	int myBillSettingsId;
	TicketNumeratorType myNumeratorType;
	BillModeType myTicketType;
	BOOL myTicketReprint;
	BOOL myViewRoundFactor;
	BOOL myViewRoundAdjust;
	BOOL myTaxDiscrimination;
	money_t myMinAmount;
	char myHeader1[40 + 1];
	char myHeader2[40 + 1];
	char myHeader3[40 + 1];
	char myHeader4[40 + 1];
	char myHeader5[40 + 1];
	char myHeader6[40 + 1];
	char myFooter1[40 + 1];
	char myFooter2[40 + 1];
	char myFooter3[40 + 1];
	int myDigitsQty;
	int myTicketQtyViewWarning;
	datetime_t myDateChange;
	BOOL myTransport;
	char myPrefix[10 + 1];
	long myInitialNumber;
	long myFinalNumber;
	int myMaxItemsQty;
  BOOL myOpenCashDrawer;
  BOOL myRequestCustomerInfo;
  char myIdentifierDescription[30 + 1];
}

/**
 * 
 */

+ new;
+ getInstance;
- initialize;

/**
 * Setea los valores correspondientes a la configuracion general de la facturacion
 */

- (void) setBillSettingsId: (int) aBillSettingsId;
- (void) setNumeratorType: (TicketNumeratorType) aValue;
- (void) setTicketType: (BillModeType) aValue;
- (void) setTicketReprint: (BOOL) aValue;
- (void) setViewRoundFactor: (BOOL) aValue;
- (void) setViewRoundAdjust: (BOOL) aValue;
- (void) setTaxDiscrimination: (BOOL) aValue;
- (void) setMinAmount: (money_t) aValue;
- (void) setHeader1: (char*) aValue;
- (void) setHeader2: (char*) aValue;
- (void) setHeader3: (char*) aValue;
- (void) setHeader4: (char*) aValue;
- (void) setHeader5: (char*) aValue;
- (void) setHeader6: (char*) aValue;
- (void) setFooter1: (char*) aValue;
- (void) setFooter2: (char*) aValue;
- (void) setFooter3: (char*) aValue;
- (void) setDigitsQty: (int) aValue;
- (void) setTicketQtyViewWarning: (int) aValue;
- (void) setDateChange: (datetime_t) aValue;
- (void) setTransport: (BOOL) aValue;
- (void) setPrefix: (char*) aValue;
- (void) setInitialNumber: (long) aValue;
- (void) setFinalNumber: (long) aValue;
- (void) setTicketMaxItemsQty: (int) aValue;
- (void) setOpenCashDrawer: (BOOL) aValue;
- (void) setRequestCustomerInfo: (BOOL) aValue;
- (void) setIdentifierDescription: (char*) aValue;

/**
 * Devuelve los valores correspondientes a la configuracion general de la facturacion
 */	

- (int) getBillSettingsId;	
- (TicketNumeratorType) getNumeratorType;
- (BillModeType) getTicketType;
- (BOOL) getTicketReprint;
- (BOOL) getViewRoundFactor;
- (BOOL) getViewRoundAdjust;
- (BOOL) getTaxDiscrimination;
- (money_t) getMinAmount;
- (char*) getHeader1;
- (char*) getHeader2;
- (char*) getHeader3;
- (char*) getHeader4;
- (char*) getHeader5;
- (char*) getHeader6;
- (char*) getFooter1;
- (char*) getFooter2;
- (char*) getFooter3;
- (int) getDigitsQty;
- (int) getTicketQtyViewWarning;
- (datetime_t) getDateChange;
- (BOOL) getTransport;
- (char*) getPrefix;
- (long) getInitialNumber;
- (long) getFinalNumber;
- (int) getTicketMaxItemsQty;
- (BOOL) getOpenCashDrawer;
- (BOOL) getRequestCustomerInfo;
- (char*) getIdentifierDescription;


/**
 * Aplica los cambios realizados sobre la instancia de la configuracion de la facturacion
 */

- (void) applyChanges;

/**
 * Restaura los valores que se encuentran almacenados en la persistencia
 */

- (void) restore;


@end

#endif
