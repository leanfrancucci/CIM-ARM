#include "BillSettingsDAO.h"
#include "BillSettings.h"
#include "SettingsExcepts.h"
#include "PrintingSettings.h"
#include "system/db/all.h"
#include "Audit.h"
#include "Event.h"
#include "MessageHandler.h"

static id singleInstance = NULL;

@implementation BillSettingsDAO

- (id) newBillSettingsFromRecordSet: (id) aRecordSet; 

/**/
+ new
{
	if (!singleInstance) singleInstance = [super new];
	return singleInstance;
}

/**/
- initialize
{
	[super initialize];
	return self;
}


/**/
- free
{
	return [super free];
}

/**/
+ getInstance
{
	return [self new];
}


/*
 *	Devuelve la configuracion de la facturacion en base a la informacion del registro actual del recordset.
 */
- (id) newBillSettingsFromRecordSet: (id) aRecordSet
{
	BILL_SETTINGS obj;
	char buffer[512];

	obj = [BillSettings getInstance];

	[obj setBillSettingsId: [aRecordSet getShortValue: "BILL_SETTINGS_ID"]];
	[obj setNumeratorType: [aRecordSet getCharValue: "NUMERATOR_TYPE"]];
	[obj setTicketType: [aRecordSet getCharValue: "TICKET_TYPE"]];
	[obj setTicketReprint: [aRecordSet getCharValue: "TICKET_REPRINT"]];
	[obj setViewRoundFactor: [aRecordSet getCharValue: "VIEW_ROUND_FACTOR"]];
	[obj setViewRoundAdjust: [aRecordSet getCharValue: "VIEW_ROUND_ADJUST"]];
	[obj setTaxDiscrimination: [aRecordSet getCharValue: "TAX_DISCRIMINATION"]];
	[obj setMinAmount: [aRecordSet getMoneyValue: "MIN_AMOUNT"]];
	[obj setHeader1: [aRecordSet getStringValue: "HEADER1" buffer: buffer]];
	[obj setHeader2: [aRecordSet getStringValue: "HEADER2" buffer: buffer]];
	[obj setHeader3: [aRecordSet getStringValue: "HEADER3" buffer: buffer]];
	[obj setHeader4: [aRecordSet getStringValue: "HEADER4" buffer: buffer]];
	[obj setHeader5: [aRecordSet getStringValue: "HEADER5" buffer: buffer]];
	[obj setHeader6: [aRecordSet getStringValue: "HEADER6" buffer: buffer]];
	[obj setFooter1: [aRecordSet getStringValue: "FOOTER1" buffer: buffer]];
	[obj setFooter2: [aRecordSet getStringValue: "FOOTER2" buffer: buffer]];
	[obj setFooter3: [aRecordSet getStringValue: "FOOTER3" buffer: buffer]];
	[obj setDigitsQty: [aRecordSet getCharValue: "DIGITS_QTY"]];
	[obj setTicketQtyViewWarning: [aRecordSet getCharValue: "TICKET_VIEW_WARNING"]];
	[obj setDateChange: [aRecordSet getDateTimeValue: "DATE_CHANGE"]];
	[obj setTransport: [aRecordSet getCharValue: "TRANSPORT"]];
	[obj setPrefix: [aRecordSet getStringValue: "PREFIX" buffer: buffer]];
	[obj setInitialNumber: [aRecordSet getLongValue: "INITIAL_NUMBER"]];
	[obj setFinalNumber: [aRecordSet getLongValue: "FINAL_NUMBER"]];
	[obj setTicketMaxItemsQty: [aRecordSet getCharValue: "MAX_ITEMS_QTY"]];
	[obj setOpenCashDrawer: [aRecordSet getCharValue: "OPEN_CASH_DRAWER"]];
  [obj setRequestCustomerInfo: [aRecordSet getCharValue: "REQUEST_CUSTOMER_INFO"]]; 	
  [obj setIdentifierDescription: [aRecordSet getStringValue: "IDENTIFIER_DESCRIPTION" buffer: buffer]]; 	

	return obj;
}

/**/
- (id) loadById: (unsigned long) anId
{
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "bill_settings"];
	id obj = NULL;

	[myRecordSet open];
	
	if ([myRecordSet findById: "BILL_SETTINGS_ID" value: anId]) {
		obj = [self newBillSettingsFromRecordSet: myRecordSet];
		[myRecordSet free];
		return obj;
	}

	[myRecordSet free];
	THROW(REFERENCE_NOT_FOUND_EX);
	return NULL;
}

/**/
- (void) store: (id) anObject
{
	DB_CONNECTION dbConnection = [DBConnection getInstance]; 
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSet: "bill_settings"];
	ABSTRACT_RECORDSET myRecordSetBck;
	AUDIT audit;
	char buffer[100];

	[self validateFields: anObject];

	TRY
	
		[myRecordSet open];

		if ([myRecordSet findById: "BILL_SETTINGS_ID" value: [anObject getBillSettingsId]]) {

      audit = [[Audit new] initAuditWithCurrentUser: BILL_SETTING additional: "" station: 0 logRemoteSystem: TRUE];
 
      // Log de cambios
      [audit logChangeAsString: RESID_BillSettings_HEADER1 oldValue: [myRecordSet getStringValue: "HEADER1" buffer: buffer] newValue: [anObject getHeader1]];
      [audit logChangeAsString: RESID_BillSettings_HEADER2 oldValue: [myRecordSet getStringValue: "HEADER2" buffer: buffer] newValue: [anObject getHeader2]];
      [audit logChangeAsString: RESID_BillSettings_HEADER3 oldValue: [myRecordSet getStringValue: "HEADER3" buffer: buffer] newValue: [anObject getHeader3]];
      [audit logChangeAsString: RESID_BillSettings_HEADER4 oldValue: [myRecordSet getStringValue: "HEADER4" buffer: buffer] newValue: [anObject getHeader4]];
      [audit logChangeAsString: RESID_BillSettings_HEADER5 oldValue: [myRecordSet getStringValue: "HEADER5" buffer: buffer] newValue: [anObject getHeader5]];
      [audit logChangeAsString: RESID_BillSettings_HEADER6 oldValue: [myRecordSet getStringValue: "HEADER6" buffer: buffer] newValue: [anObject getHeader6]];
      [audit logChangeAsString: RESID_BillSettings_FOOTER1 oldValue: [myRecordSet getStringValue: "FOOTER1" buffer: buffer] newValue: [anObject getFooter1]];
      [audit logChangeAsString: RESID_BillSettings_FOOTER2 oldValue: [myRecordSet getStringValue: "FOOTER2" buffer: buffer] newValue: [anObject getFooter2]];
      [audit logChangeAsString: RESID_BillSettings_FOOTER3 oldValue: [myRecordSet getStringValue: "FOOTER3" buffer: buffer] newValue: [anObject getFooter3]];

      // Configuro el recordset y grabo
			[myRecordSet setCharValue: "NUMERATOR_TYPE" value: [anObject getNumeratorType]];
			[myRecordSet setCharValue: "TICKET_TYPE" value: [anObject getTicketType]];
			[myRecordSet setCharValue: "TICKET_REPRINT" value: [anObject getTicketReprint]];
			[myRecordSet setCharValue: "VIEW_ROUND_FACTOR" value: [anObject getViewRoundFactor]];
			[myRecordSet setCharValue: "VIEW_ROUND_ADJUST" value: [anObject getViewRoundAdjust]];
			[myRecordSet setCharValue: "TAX_DISCRIMINATION" value: [anObject getTaxDiscrimination]];
			[myRecordSet setMoneyValue: "MIN_AMOUNT" value: [anObject getMinAmount]];
			[myRecordSet setStringValue: "HEADER1" value: [anObject getHeader1]];
			[myRecordSet setStringValue: "HEADER2" value: [anObject getHeader2]];
			[myRecordSet setStringValue: "HEADER3" value: [anObject getHeader3]];
			[myRecordSet setStringValue: "HEADER4" value: [anObject getHeader4]];
			[myRecordSet setStringValue: "HEADER5" value: [anObject getHeader5]];
			[myRecordSet setStringValue: "HEADER6" value: [anObject getHeader6]];
			[myRecordSet setStringValue: "FOOTER1" value: [anObject getFooter1]];
			[myRecordSet setStringValue: "FOOTER2" value: [anObject getFooter2]];
			[myRecordSet setStringValue: "FOOTER3" value: [anObject getFooter3]];
			[myRecordSet setCharValue: "DIGITS_QTY" value: [anObject getDigitsQty]];
			[myRecordSet setCharValue: "TICKET_VIEW_WARNING" value: [anObject getTicketQtyViewWarning]];
			[myRecordSet setDateTimeValue: "DATE_CHANGE" value: [anObject getDateChange]];
			[myRecordSet setCharValue: "TRANSPORT" value: [anObject getTransport]];
			[myRecordSet setStringValue: "PREFIX" value: [anObject getPrefix]];
			[myRecordSet setLongValue: "INITIAL_NUMBER" value: [anObject getInitialNumber]];
			[myRecordSet setLongValue: "FINAL_NUMBER" value: [anObject getFinalNumber]];
			[myRecordSet setCharValue: "MAX_ITEMS_QTY" value: [anObject getTicketMaxItemsQty]];
      [myRecordSet setCharValue: "OPEN_CASH_DRAWER" value: [anObject getOpenCashDrawer]];
      [myRecordSet setCharValue: "REQUEST_CUSTOMER_INFO" value: [anObject getRequestCustomerInfo]];
      [myRecordSet setStringValue: "IDENTIFIER_DESCRIPTION" value: [anObject getIdentifierDescription]];

			[myRecordSet save];

      [audit saveAudit];
      [audit free];

			// *********** Analiza si debe hacer backup online ***********
			if ([dbConnection tableHasBackup: "bill_settings_bck"]) {
				myRecordSetBck = [dbConnection createRecordSet: "bill_settings_bck"];

				[self doUpdateBackupById: "BILL_SETTINGS_ID" value: [anObject getBillSettingsId] backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "bill_settings_bck"];
			}

		}
	
	FINALLY
		
			[myRecordSet free];			

	END_TRY
}

/**/
- (void) validateFields: (id) anObject
{
	/*
		Validacion de rangos en cuanto a los valores que presentan restricciones
	  NumerationType = 1..2 (el 3 es el FIXED_RANGE) que aun no esta implementado
		TicketType = 1..2
		InitialNumber = 0..99999999
		FinalNumber = 0..999999999
		MaxItemsQty = 0..255
		DigitsQty   = 4..9
	*/
  
  if ( ([anObject getInitialNumber] < 0) || ([anObject getInitialNumber] > 99999999) ) 
    THROW(DAO_INITIAL_NUMBER_VALUE_INCORRECT_EX);

  if ( ([anObject getNumeratorType] < 1) || ([anObject getNumeratorType] > 2) )
    THROW(DAO_INVALID_NUMERATOR_TYPE_EX);
	
	if ([[PrintingSettings getInstance] getPrintTickets] == QUESTION_PRINT &&
	    [anObject getTicketType] == UNIQUE_BILL)
		THROW(DAO_ASK_QUESTION_AND_UNIQUE_BILL_INCOMPATIBLE_EX);

  if ( (strlen([anObject getIdentifierDescription]) == 0) ) 
    THROW(DAO_NULLED_IDENTIFIER_DESCRIPTION_EX);	

  if ( ([anObject getDigitsQty] < 4) || ([anObject getDigitsQty] > 9) ) 
    THROW(DAO_DIGITS_QTY_VALUE_INCORRECT_EX);

}



@end
