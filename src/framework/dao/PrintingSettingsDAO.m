#include "PrintingSettingsDAO.h"
#include "PrintingSettings.h"
#include "SettingsExcepts.h"
#include "BillSettings.h"
#include "system/db/all.h"
#include "Audit.h"
#include "MessageHandler.h"
#include "Event.h"

static id singleInstance = NULL;

@implementation PrintingSettingsDAO

- (id) newPrintingSettingsFromRecordSet: (id) aRecordSet; 

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
 *	Devuelve la configuracion de la impresion en base a la informacion del registro actual del recordset.
 */
- (id) newPrintingSettingsFromRecordSet: (id) aRecordSet
{
	PRINTING_SETTINGS obj;
  char buffer[30];

	obj = [PrintingSettings getInstance];

	[obj setPrintingSettingsId: [aRecordSet getShortValue: "PRINTING_SETTINGS_ID"]];
	[obj setPrinterType: [aRecordSet getCharValue: "PRINTER_TYPE"]];
	[obj setLinesQtyBetweenTickets: [aRecordSet getCharValue: "LINES_QTY_BETWEEN_TICKETS"]];
	[obj setPrintTickets: [aRecordSet getCharValue: "PRINT_TICKETS"]];
	[obj setPrintNextHeader: [aRecordSet getCharValue: "PRINT_NEXT_HEADER"]];
	[obj setAutoPaperCut: [aRecordSet getCharValue: "AUTO_PAPER_CUT"]];
	[obj setCopiesQty: [aRecordSet getCharValue: "COPIES_QTY"]];
	[obj setPrintZeroTickets: [aRecordSet getCharValue: "PRINT_ZERO_TICKETS"]];  
	[obj setPrinterCOMPort: [aRecordSet getCharValue: "PRINTER_COM_PORT"]];  
  [obj setPrinterCode: [aRecordSet getStringValue: "PRINTER_CODE" buffer: buffer]];
  [obj setUpdateDate: [aRecordSet getDateTimeValue: "UPDATE_DATE"]];

	return obj;
}

/**/
- (id) loadById: (unsigned long) anId
{

	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "printing_settings"];
	
	id obj = NULL;

	[myRecordSet open];

	if ([myRecordSet findById: "PRINTING_SETTINGS_ID" value: anId]) {
		obj = [self newPrintingSettingsFromRecordSet: myRecordSet];
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
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSet: "printing_settings"];
	ABSTRACT_RECORDSET myRecordSetBck;
	AUDIT audit;

  [self validateFields: anObject];
  
	TRY
	
		[myRecordSet open];

		if ([myRecordSet findById: "PRINTING_SETTINGS_ID" value: [anObject getPrintingSettingsId]]) {
    
			// si la impresora es interna cableo el puerto en 2 y lineas de avance en 3
			if ([anObject getPrinterType] == INTERNAL) {
				// Puerto impresora
				[anObject setPrinterCOMPort: 2];
				// Cantida de lineas de avance
				[anObject setLinesQtyBetweenTickets: 3];
			}

      audit = [[Audit new] initAuditWithCurrentUser: PRINTING_SETTING additional: "" station: 0 logRemoteSystem: TRUE];

      // Log de cambios
      [audit logChangeAsInteger: RESID_PRINTER_LINES_QTY oldValue: [myRecordSet getCharValue: "LINES_QTY_BETWEEN_TICKETS"] newValue: [anObject getLinesQtyBetweenTickets]];

			[audit logChangeAsResourceString: FALSE
				resourceId: RESID_PRINTER
				resourceStringBase: RESID_PRINTER
				oldValue: ([myRecordSet getCharValue: "PRINTER_TYPE"])
				newValue: ([anObject getPrinterType])
				oldReference: [myRecordSet getCharValue: "PRINTER_TYPE"]
				newReference: [anObject getPrinterType]];

			[audit logChangeAsInteger: RESID_PRINTER_COM_PORT oldValue: [myRecordSet getCharValue: "PRINTER_COM_PORT"] newValue: [anObject getPrinterCOMPort]];

      // Configuro el recordset y grabo
			[myRecordSet setCharValue: "PRINTER_TYPE" value: [anObject getPrinterType]];
			[myRecordSet setCharValue: "LINES_QTY_BETWEEN_TICKETS" value: [anObject getLinesQtyBetweenTickets]];
			[myRecordSet setCharValue: "PRINT_TICKETS" value: [anObject getPrintTickets]];
			[myRecordSet setCharValue: "PRINT_NEXT_HEADER" value: [anObject getPrintNextHeader]];
			[myRecordSet setCharValue: "AUTO_PAPER_CUT" value: [anObject getAutoPaperCut]];
			[myRecordSet setCharValue: "COPIES_QTY" value: [anObject getCopiesQty]];
      [myRecordSet setCharValue: "PRINT_ZERO_TICKETS" value: [anObject getPrintZeroTickets]];
      [myRecordSet setCharValue: "PRINTER_COM_PORT" value: [anObject getPrinterCOMPort]];
      [myRecordSet setStringValue: "PRINTER_CODE" value: [anObject getPrinterCode]];
      [myRecordSet setDateTimeValue: "UPDATE_DATE" value: [anObject getUpdateDate]];
			
			[myRecordSet save];

      [audit saveAudit];  
      [audit free];

			// *********** Analiza si debe hacer backup online ***********
			if ([dbConnection tableHasBackup: "printing_settings_bck"]) {
				myRecordSetBck = [dbConnection createRecordSet: "printing_settings_bck"];

				[self doUpdateBackupById: "PRINTING_SETTINGS_ID" value: [anObject getPrintingSettingsId] backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "printing_settings_bck"];
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
		PrinterType = 1..2
		LineQtyBetweenTickets = 1..50
	*/

  if (([anObject getLinesQtyBetweenTickets] < 1) || ([anObject getLinesQtyBetweenTickets] > 50) )
    THROW(DAO_LINES_QTY_VALUE_INCORRECT_EX);

	if ([anObject getPrintTickets] == QUESTION_PRINT &&
	    [[BillSettings getInstance] getTicketType] == UNIQUE_BILL)
		THROW(DAO_ASK_QUESTION_AND_UNIQUE_BILL_INCOMPATIBLE_EX);
		
}

@end
