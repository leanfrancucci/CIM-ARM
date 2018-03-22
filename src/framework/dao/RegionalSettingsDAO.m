#include "RegionalSettingsDAO.h"
#include "RegionalSettings.h"
#include "SettingsExcepts.h"
#include "system/db/all.h"
#include "Audit.h"
#include "MessageHandler.h"
#include "Event.h"

static id singleInstance = NULL;

@implementation RegionalSettingsDAO

- (id) newRSettingFromRecordSet: (id) aRecordSet; 

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
 *	Devuelve la configuracion regional en base a la informacion del registro actual del recordset.
 */
- (id) newRSettingFromRecordSet: (id) aRecordSet
{
	REGIONAL_SETTINGS obj;
	char buffer[11];

	obj = [RegionalSettings getInstance];

	[obj setRegionalSettingsId: [aRecordSet getShortValue: "REGIONAL_SETTINGS_ID"]];
	[obj setMoneySymbol: [aRecordSet getStringValue: "MONEY_SYMBOL" buffer: buffer]];
	[obj setLanguage: [aRecordSet getShortValue: "LANGUAGE"]];
	[obj setTimeZone: [aRecordSet getShortValue: "TIME_ZONE"] * 3600];
	[obj setDSTEnable: [aRecordSet getCharValue: "DST_ENABLE"]];
	[obj setInitialMonth: [aRecordSet getShortValue: "INITIAL_MONTH"]];
	[obj setInitialWeek: [aRecordSet getShortValue: "INITIAL_WEEK"]];
	[obj setInitialDay: [aRecordSet getShortValue: "INITIAL_DAY"]];
	[obj setInitialHour: [aRecordSet getShortValue: "INITIAL_HOUR"]];
	[obj setFinalMonth: [aRecordSet getShortValue: "FINAL_MONTH"]];
	[obj setFinalWeek: [aRecordSet getShortValue: "FINAL_WEEK"]];
	[obj setFinalDay: [aRecordSet getShortValue: "FINAL_DAY"]];
	[obj setFinalHour: [aRecordSet getShortValue: "FINAL_HOUR"]];
	[obj setBlockDateTimeChange: [aRecordSet getCharValue: "BLOCK_DATE_TIME_CHANGE"]];
	[obj setDateFormat: [aRecordSet getCharValue: "DATE_FORMAT"]];

	return obj;
}

/**/

- (id) loadById: (unsigned long) anId
{
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "regional_settings"];	
	id obj = NULL;

	[myRecordSet open];

	if ([myRecordSet findById: "REGIONAL_SETTINGS_ID" value: anId]) {
		obj = [self newRSettingFromRecordSet: myRecordSet];
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
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSet: "regional_settings"];
	ABSTRACT_RECORDSET myRecordSetBck;
  AUDIT audit;

	[self validateFields: anObject];

	TRY 

		[myRecordSet open];

		//Se posiciona en el registro correspondiente que es unico
		if ( [myRecordSet findById: "REGIONAL_SETTINGS_ID" value: [anObject getRegionalSettingsId]] ) {

      audit = [[Audit new] initAuditWithCurrentUser: REGIONAL_SETTING additional: "" station: 0 logRemoteSystem: TRUE];

      // Log de cambios  

      [audit logChangeAsResourceString: FALSE 
				resourceId: RESID_RegionalSettings_LANGUAGE 
				resourceStringBase: RESID_RegionalSettings_LANGUAGE_NOT_DEFINED
				oldValue: [myRecordSet getShortValue: "LANGUAGE"] 
				newValue: [anObject getLanguage]
				oldReference: [myRecordSet getShortValue: "LANGUAGE"] 
				newReference: [anObject getLanguage]]; 

      [audit logChangeAsInteger: RESID_RegionalSettings_TIME_ZONE oldValue: [myRecordSet getShortValue: "TIME_ZONE"] newValue: [anObject getTimeZone] / 3600];

      [audit logChangeAsResourceString: FALSE 
				resourceId: RESID_RegionalSettings_DATE_FORMAT 
				resourceStringBase: RESID_RegionalSettings_DATE_FORMAT
				oldValue: [myRecordSet getCharValue: "DATE_FORMAT"] 
				newValue: [anObject getDateFormat]
				oldReference: [myRecordSet getCharValue: "DATE_FORMAT"] 
				newReference: [anObject getDateFormat]]; 

      // Configura el recordset y guarda los cambios
			[myRecordSet setStringValue: "MONEY_SYMBOL" value: [anObject getMoneySymbol]];
			[myRecordSet setShortValue: "LANGUAGE" value: [anObject getLanguage]];
			[myRecordSet setShortValue: "TIME_ZONE" value: [anObject getTimeZone] / 3600];
			[myRecordSet setCharValue: "DST_ENABLE" value: [anObject getDSTEnable]];
			[myRecordSet setShortValue: "INITIAL_MONTH" value: [anObject getInitialMonth]];
			[myRecordSet setShortValue: "INITIAL_WEEK" value: [anObject getInitialWeek]];
			[myRecordSet setShortValue: "INITIAL_DAY" value: [anObject getInitialDay]];
			[myRecordSet setShortValue: "INITIAL_HOUR" value: [anObject getInitialHour]];
			[myRecordSet setShortValue: "FINAL_MONTH" value: [anObject getFinalMonth]];
			[myRecordSet setShortValue: "FINAL_WEEK" value: [anObject getFinalWeek]];
			[myRecordSet setShortValue: "FINAL_DAY" value: [anObject getFinalDay]];
			[myRecordSet setShortValue: "FINAL_HOUR" value: [anObject getFinalHour]];
			[myRecordSet setCharValue: "BLOCK_DATE_TIME_CHANGE" value: [anObject getBlockDateTimeChange]];
			[myRecordSet setCharValue: "DATE_FORMAT" value: [anObject getDateFormat]];

			[myRecordSet save];

      [audit saveAudit];  
      [audit free];

			// *********** Analiza si debe hacer backup online ***********
			if ([dbConnection tableHasBackup: "regional_settings_bck"]) {
				myRecordSetBck = [dbConnection createRecordSet: "regional_settings_bck"];

				[self doUpdateBackupById: "REGIONAL_SETTINGS_ID" value: [anObject getRegionalSettingsId] backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "regional_settings_bck"];
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
	  language = 1..4
		timeZone = -12..12
		initMonth = 1..12
		initWeek = 1..4
		initDay = 1..7
		initHour = 0..23
		finalMonth = 1..12
		finalWeek = 1..4
		finalDay = 1..7
		finalDay = 0..23
	*/

	if (([anObject getLanguage] < 1) || ([anObject getLanguage] > 4)) 
		THROW(DAO_OUT_OF_RANGE_VALUE_EX);

	if (([anObject getInitialMonth] < 1) || ([anObject getInitialMonth] > 12)) 
		THROW(DAO_INITIAL_MONTH_INCORRECT_EX);

	if (([anObject getFinalMonth] < 1) || ([anObject getFinalMonth] > 12)) 
		THROW(DAO_FINAL_MONTH_INCORRECT_EX);

	if (([anObject getInitialDay] < 1) || ([anObject getInitialDay] > 31)) 
		THROW(DAO_INITIAL_DAY_INCORRECT_EX);

	if (([anObject getFinalDay] < 1) || ([anObject getFinalDay] > 31)) 
		THROW(DAO_FINAL_DAY_INCORRECT_EX);

	if (([anObject getInitialHour] < 0) || ([anObject getInitialHour] > 12)) 
		THROW(DAO_INITIAL_HOUR_INCORRECT_EX);

	if (([anObject getFinalHour] < 0) || ([anObject getFinalHour] > 12)) 
		THROW(DAO_FINAL_HOUR_INCORRECT_EX);

	if (([anObject getTimeZone] < (0-43200)) || ([anObject getTimeZone] > 43200)) 
		THROW(DAO_TIME_ZONE_INCORRECT_EX);

}

@end
