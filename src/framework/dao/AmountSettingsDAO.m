#include "AmountSettingsDAO.h"
#include "AmountSettings.h"
#include "SettingsExcepts.h"
#include "system/db/all.h"
#include "Audit.h"
#include "Event.h"
#include "MessageHandler.h"

static id singleInstance = NULL;

@implementation AmountSettingsDAO

- (id) newAmountSettingsFromRecordSet: (id) aRecordSet; 

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
 *	Devuelve la configuracion de los montos en base a la informacion del registro actual del recordset.
 */
- (id) newAmountSettingsFromRecordSet: (id) aRecordSet
{
	AMOUNT_SETTINGS obj;

	obj = [AmountSettings getInstance];

	[obj setAmountSettingsId: [aRecordSet getShortValue: "AMOUNT_SETTINGS_ID"]];
	[obj setRoundType: [aRecordSet getCharValue: "ROUND_TYPE"]];
	[obj setDecimalQty: [aRecordSet getCharValue: "DECIMAL_QTY"]];
	[obj setItemsRoundDecimalQty: [aRecordSet getCharValue: "ITEMS_ROUND_DECIMAL_QTY"]];
	[obj setSubtotalRoundDecimalQty: [aRecordSet getCharValue: "SUBTOTAL_ROUND_DECIMAL_QTY"]];
	[obj setTotalRoundDecimalQty: [aRecordSet getCharValue: "TOTAL_ROUND_DECIMAL_QTY"]];
	[obj setTaxRoundDecimalQty: [aRecordSet getCharValue: "TAX_ROUND_DECIMAL_QTY"]];
	[obj setRoundValue: [aRecordSet getMoneyValue: "ROUND_VALUE"]];

	return obj;
}

/**/

- (id) loadById: (unsigned long) anId
{

	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "amount_settings"];
	id obj = NULL;

	[myRecordSet open];

	if ([myRecordSet findById: "AMOUNT_SETTINGS_ID" value: anId]) {
		obj = [self newAmountSettingsFromRecordSet: myRecordSet];
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
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSet: "amount_settings"];
	ABSTRACT_RECORDSET myRecordSetBck;
	AUDIT audit;

	[self validateFields: anObject];

	TRY
	
		[myRecordSet open];

		if ([myRecordSet findById: "AMOUNT_SETTINGS_ID" value: [anObject getAmountSettingsId]]) {

      // LOG DE CAMBIOS 
      if ([myRecordSet getCharValue: "TOTAL_ROUND_DECIMAL_QTY"] != [anObject getTotalRoundDecimalQty]){
        audit = [[Audit new] initAuditWithCurrentUser: AMOUNT_SETTING additional: "" station: 0 logRemoteSystem: TRUE];
        [audit logChangeAsInteger: RESID_AmountSettings_TOTAL_ROUND_DECIMAL_QTY oldValue: [myRecordSet getCharValue: "TOTAL_ROUND_DECIMAL_QTY"] newValue: [anObject getTotalRoundDecimalQty]];
        [audit saveAudit];
        [audit free];
      }

			[myRecordSet setCharValue: "ROUND_TYPE" value: [anObject getRoundType]];
			[myRecordSet setCharValue: "DECIMAL_QTY" value: [anObject getDecimalQty]];
			[myRecordSet setCharValue: "ITEMS_ROUND_DECIMAL_QTY" value: [anObject getItemsRoundDecimalQty]];
			[myRecordSet setCharValue: "SUBTOTAL_ROUND_DECIMAL_QTY" value: [anObject getSubtotalRoundDecimalQty]];
			[myRecordSet setCharValue: "TOTAL_ROUND_DECIMAL_QTY" value: [anObject getTotalRoundDecimalQty]];
			[myRecordSet setCharValue: "TAX_ROUND_DECIMAL_QTY" value: [anObject getTaxRoundDecimalQty]];
			[myRecordSet setMoneyValue: "ROUND_VALUE" value: [anObject getRoundValue]];

			[myRecordSet save];

			// *********** Analiza si debe hacer backup online ***********
			if ([dbConnection tableHasBackup: "amount_settings_bck"]) {
				myRecordSetBck = [dbConnection createRecordSet: "amount_settings_bck"];

				[self doUpdateBackupById: "AMOUNT_SETTINGS_ID" value: [anObject getAmountSettingsId] backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "amount_settings_bck"];
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
		RoundType = 1..4
		DecimalQty = 1..10
		ItemsRoundDecimalQty = 1..10
		SubtotalRoundDecimalQty = 1..10
		TotalRoundDecimalQty = 1..10
		TaxRoundDecimalQty = 1..10
	*/

  if ( ([anObject getItemsRoundDecimalQty] < 0) || ([anObject getItemsRoundDecimalQty] > 6) )
    THROW(DAO_ITEMS_DECIMALS_INCORRECT_EX);

  if ( ([anObject getSubtotalRoundDecimalQty] < 0) || ([anObject getSubtotalRoundDecimalQty] > 6) )
    THROW(DAO_SUBTOTAL_DECIMALS_INCORRECT_EX);

  if ( ([anObject getTotalRoundDecimalQty] < 0) || ([anObject getTotalRoundDecimalQty] > 6) )
    THROW(DAO_TOTAL_DECIMALS_INCORRECT_EX);
        
  if ( ([anObject getTaxRoundDecimalQty] < 0) || ([anObject getTaxRoundDecimalQty] > 6) )
    THROW(DAO_TAX_DECIMALS_INCORRECT_EX);

    
}

@end
