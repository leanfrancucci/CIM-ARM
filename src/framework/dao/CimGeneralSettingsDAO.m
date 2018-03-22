#include "CimGeneralSettingsDAO.h"
#include "CimGeneralSettings.h"
#include "SettingsExcepts.h"
#include "system/db/all.h"
#include "Audit.h"
#include "MessageHandler.h"
#include "util.h"
#include "JSystem.h"
#include "Persistence.h"
#include "ZCloseDAO.h"

static id singleInstance = NULL;

@implementation CimGeneralSettingsDAO

- (id) newCimGeneralSettingsFromRecordSet: (id) aRecordSet; 

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


/**/
- (id) newCimGeneralSettingsFromRecordSet: (id) aRecordSet
{
	CIM_GENERAL_SETTINGS obj;
	char buffer[50];

	obj = [CimGeneralSettings getInstance];

	[obj setCimGeneralSettingsId: [aRecordSet getShortValue: "CIM_GENERAL_SETTINGS_ID"]];
	[obj setNextDepositNumber: [aRecordSet getLongValue: "NEXT_DEPOSIT_NUMBER"]];
	[obj setNextExtractionNumber: [aRecordSet getLongValue: "NEXT_EXTRACTION_NUMBER"]];
	[obj setNextXNumber: [aRecordSet getLongValue: "NEXT_X_NUMBER"]];
	[obj setNextZNumber: [aRecordSet getLongValue: "NEXT_Z_NUMBER"]];
	[obj setDepositCopiesQty: [aRecordSet getCharValue: "DEPOSIT_COPIES_QTY"]];
	[obj setExtractionCopiesQty: [aRecordSet getCharValue: "EXTRACTION_COPIES_QTY"]];
	[obj setXCopiesQty: [aRecordSet getCharValue: "X_COPIES_QTY"]];
	[obj setZCopiesQty: [aRecordSet getCharValue: "Z_COPIES_QTY"]];
	[obj setAutoPrint: [aRecordSet getCharValue: "AUTO_PRINT"]];
	[obj setMailboxOpenTime: [aRecordSet getShortValue: "MAIL_BOX_OPEN_TIME"]];
	[obj setMaxInactivityTimeOnDeposit: [aRecordSet getShortValue: "MAX_INACTIVITY_TIME_ON_DEPOSIT"]];
	[obj setWarningTime: [aRecordSet getShortValue: "WARNING_TIME"]];
	[obj setMaxUserInactivityTime: [aRecordSet getShortValue: "MAX_USER_INACTIVITY_TIME"]];
	[obj setLockLoginTime: [aRecordSet getShortValue: "LOCK_LOGIN_TIME"]];
	[obj setStartDay: [aRecordSet getShortValue: "START_DAY"]];
  [obj setEndDay: [aRecordSet getShortValue: "END_DAY"]];
	[obj setPOSId: [aRecordSet getStringValue: "POS_ID" buffer: buffer]];
	[obj setDefaultBankInfo: [aRecordSet getStringValue: "DEFAULT_BANK_INFO" buffer: buffer]];
	[obj setIdleText: [aRecordSet getStringValue: "IDLE_TEXT" buffer: buffer]];
	[obj setPinLenght: [aRecordSet getCharValue: "PIN_LENGHT"]];
	[obj setPinLife: [aRecordSet getShortValue: "PIN_LIFE"]];
	[obj setPinAutoInactivate: [aRecordSet getCharValue: "PIN_AUTO_INACTIVATE"]];
	[obj setPinAutoDelete: [aRecordSet getCharValue: "PIN_AUTO_DELETE"]];
	[obj setAskEnvelopeNumber: [aRecordSet getCharValue: "ASK_ENVELOPE_NUMBER"]];
	[obj setUseCashReference: [aRecordSet getCharValue: "USE_CASH_REFERENCE"]];
	[obj setAskRemoveCash: [aRecordSet getCharValue: "ASK_REMOVE_CASH"]];
	[obj setCimModel: [aRecordSet getShortValue: "CIM_MODEL"]];
	[obj setPrintLogo: [aRecordSet getCharValue: "PRINT_LOGO"]];
	[obj setAskQtyInManualDrop: [aRecordSet getCharValue: "ASK_QTY_IN_MANUAL_DROP"]];
	[obj setAskApplyTo: [aRecordSet getCharValue: "ASK_APPLY_TO"]];
	[obj setPrintOperatorReport: [aRecordSet getCharValue: "PRINT_OPERATOR_REPORT"]];
	[obj setEnvelopeIdOpMode: [aRecordSet getCharValue: "ENVELOPE_ID_OP_MODE"]];
	[obj setApplyToOpMode: [aRecordSet getCharValue: "APPLY_TO_OP_MODE"]];
	[obj setUseBarCodeReader: [aRecordSet getCharValue: "USE_BARCODE_READER"]];
	[obj setRemoveBagVerification: [aRecordSet getCharValue: "REMOVE_BAG_VERIFICATION"]];
	[obj setBagTracking: [aRecordSet getCharValue: "BAG_TRACKING"]];
	[obj setBarCodeReaderComPort: [aRecordSet getCharValue: "BARCODE_READER_COM_PORT"]];
	[obj setLoginDevType: [aRecordSet getCharValue: "LOGIN_DEV_TYPE"]];
	[obj setLoginDevComPort: [aRecordSet getCharValue: "LOGIN_DEV_COM_PORT"]];
	[obj setSwipeCardTrack: [aRecordSet getCharValue: "SWIPE_CARD_TRACK"]];
	[obj setSwipeCardOffset: [aRecordSet getShortValue: "SWIPE_CARD_OFFSET"]];
	[obj setSwipeCardReadQty: [aRecordSet getShortValue: "SWIPE_CARD_READ_QTY"]];
	[obj setRemoveCashOuterDoor: [aRecordSet getCharValue: "REMOVE_CASH_OUTER_DOOR"]];
	[obj setUseEndDay: [aRecordSet getCharValue: "USE_END_DAY"]];
	[obj setAskBagCode: [aRecordSet getCharValue: "ASK_BAG_CODE"]];
	[obj setAcceptorsCodeType: [aRecordSet getCharValue: "ACCEPTORS_CODE_TYPE"]];
	[obj setConfirmCode: [aRecordSet getCharValue: "CONFIRM_CODE"]];
	[obj setAutomaticBackup: [aRecordSet getCharValue: "AUTO_BACKUP"]];
	[obj setBackupTime: [aRecordSet getShortValue: "BACKUP_TIME"]];
	[obj setBackupFrame: [aRecordSet getCharValue: "BACKUP_FRAME"]];
	[obj setLoginOpMode: [aRecordSet getCharValue: "LOGIN_OP_MODE"]];

	return obj;
}

/**/
- (id) loadById: (unsigned long) anId
{
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "cim_settings"];
	id obj = NULL;

	[myRecordSet open];
	
	if ([myRecordSet findById: "CIM_GENERAL_SETTINGS_ID" value: anId]) {
		obj = [self newCimGeneralSettingsFromRecordSet: myRecordSet];
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
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSet: "cim_settings"];
	ABSTRACT_RECORDSET myRecordSetBck;
	AUDIT audit;
	char buffer[512];
	BOOL changeUseChashRef = FALSE;

	[self validateFields: anObject];

	TRY
	
		[myRecordSet open];

		if ([myRecordSet findById: "CIM_GENERAL_SETTINGS_ID" value: [anObject getCimGeneralSettingsId]]) {

			if ([anObject getValidateNextNumbers]) {

				/*Valido que el next deposit sea mayor al actual*/
				if ([myRecordSet getLongValue: "NEXT_DEPOSIT_NUMBER"] != [anObject getNextDepositNumber])
					if ([anObject getNextDepositNumber] <= [[[Persistence getInstance] getDepositDAO] getLastDepositNumber])
						THROW(DAO_NEXT_DROP_BIGGER_THAN_EX);
		
				/*Valido que el next extraction sea mayor al actual*/
				if ([myRecordSet getLongValue: "NEXT_EXTRACTION_NUMBER"] != [anObject getNextExtractionNumber])
					if ([anObject getNextExtractionNumber] <= [[[Persistence getInstance] getExtractionDAO] getLastExtractionNumber])
						THROW(DAO_NEXT_DEPOSIT_BIGGER_THAN_EX);
				
				/*Valido que el next Z sea mayor al actual*/
				if ([myRecordSet getLongValue: "NEXT_Z_NUMBER"] != [anObject getNextZNumber])
					if ([anObject getNextZNumber] <= [[[Persistence getInstance] getZCloseDAO] getLastZCloseNumber])
						THROW(DAO_NEXT_Z_BIGGER_THAN_EX);
			}

      audit = [[Audit new] initAuditWithCurrentUser: GENERAL_SETTING additional: "" station: 0 logRemoteSystem: TRUE];

      /// LOG DE CAMBIOS 
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_NEXT_DEPOSIT_NUMBER oldValue: [myRecordSet getLongValue: "NEXT_DEPOSIT_NUMBER"] newValue: [anObject getNextDepositNumber]];
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_NEXT_EXTRACTION_NUMBER oldValue: [myRecordSet getLongValue: "NEXT_EXTRACTION_NUMBER"] newValue: [anObject getNextExtractionNumber]];
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_NEXT_X_NUMBER oldValue: [myRecordSet getLongValue: "NEXT_X_NUMBER"] newValue: [anObject getNextXNumber]];
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_NEXT_Z_NUMBER oldValue: [myRecordSet getLongValue: "NEXT_Z_NUMBER"] newValue: [anObject getNextZNumber]];      
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_DEPOSIT_COPIES_QTY oldValue: [myRecordSet getCharValue: "DEPOSIT_COPIES_QTY"] newValue: [anObject getDepositCopiesQty]];
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_EXTRACTION_COPIES_QTY oldValue: [myRecordSet getCharValue: "EXTRACTION_COPIES_QTY"] newValue: [anObject getExtractionCopiesQty]];      
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_X_COPIES_QTY oldValue: [myRecordSet getCharValue: "X_COPIES_QTY"] newValue: [anObject getXCopiesQty]];
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_Z_COPIES_QTY oldValue: [myRecordSet getCharValue: "Z_COPIES_QTY"] newValue: [anObject getZCopiesQty]];
      [audit logChangeAsBoolean: RESID_CIM_GeneralSettings_AUTO_PRINT oldValue: [myRecordSet getCharValue: "AUTO_PRINT"] newValue: [anObject getAutoPrint]];
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_MAIL_BOX_OPEN_TIME oldValue: [myRecordSet getShortValue: "MAIL_BOX_OPEN_TIME"] newValue: [anObject getMailboxOpenTime]];
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_MAX_INACTIVITY_TIME_ON_DEPOSIT oldValue: [myRecordSet getShortValue: "MAX_INACTIVITY_TIME_ON_DEPOSIT"] newValue: [anObject getMaxInactivityTimeOnDeposit]];
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_WARNING_TIME oldValue: [myRecordSet getShortValue: "WARNING_TIME"] newValue: [anObject getWarningTime]];
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_MAX_USER_INACTIVITY_TIME oldValue: [myRecordSet getShortValue: "MAX_USER_INACTIVITY_TIME"] newValue: [anObject getMaxUserInactivityTime]];
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_LOCK_LOGIN_TIME oldValue: [myRecordSet getShortValue: "LOCK_LOGIN_TIME"] newValue: [anObject getLockLoginTime]];
			[audit logChangeAsInteger: RESID_CIM_GeneralSettings_START_DAY oldValue: [myRecordSet getShortValue: "START_DAY"] newValue: [anObject getStartDay]];
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_END_DAY oldValue: [myRecordSet getShortValue: "END_DAY"] newValue: [anObject getEndDay]];      
      [audit logChangeAsString: RESID_CIM_GeneralSettings_POS_ID oldValue: [myRecordSet getStringValue: "POS_ID" buffer: buffer] newValue: [anObject getPOSId]];
      [audit logChangeAsString: RESID_CIM_GeneralSettings_DEFAULT_BANK_INFO oldValue: [myRecordSet getStringValue: "DEFAULT_BANK_INFO" buffer: buffer] newValue: [anObject getDefaultBankInfo]];
      [audit logChangeAsString: RESID_CIM_GeneralSettings_IDLE_TEXT oldValue: [myRecordSet getStringValue: "IDLE_TEXT" buffer: buffer] newValue: [anObject getIdleText]];      
			[audit logChangeAsInteger: RESID_CIM_GeneralSettings_PIN_LENGHT oldValue: [myRecordSet getCharValue: "PIN_LENGHT"] newValue: [anObject getPinLenght]];
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_PIN_LIFE oldValue: [myRecordSet getShortValue: "PIN_LIFE"] newValue: [anObject getPinLife]];
			[audit logChangeAsInteger: RESID_CIM_GeneralSettings_PIN_AUTO_INACTIVATE oldValue: [myRecordSet getCharValue: "PIN_AUTO_INACTIVATE"] newValue: [anObject getPinAutoInactivate]];
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_PIN_AUTO_DELETE oldValue: [myRecordSet getCharValue: "PIN_AUTO_DELETE"] newValue: [anObject getPinAutoDelete]];
      [audit logChangeAsBoolean: RESID_CIM_GeneralSettings_ASK_ENVELOPE_NUMBER oldValue: [myRecordSet getCharValue: "ASK_ENVELOPE_NUMBER"] newValue: [anObject getAskEnvelopeNumber]];

			/*[audit logChangeAsResourceString: FALSE
																				resourceId: RESID_CIM_GeneralSettings_ASK_ENVELOPE_NUMBER 
																				resourceStringBase: RESID_CIM_GeneralSettings_ASK_ENVELOPE_NUMBER
																				oldValue: ([myRecordSet getCharValue: "ASK_ENVELOPE_NUMBER"]+1)
																				newValue: ([anObject getAskEnvelopeNumber]+1)
																			  oldReference: [myRecordSet getCharValue: "ASK_ENVELOPE_NUMBER"]
																				newReference: [anObject getAskEnvelopeNumber]];
      */
      
      [audit logChangeAsBoolean: RESID_CIM_GeneralSettings_USE_CASH_REFERENCE oldValue: [myRecordSet getCharValue: "USE_CASH_REFERENCE"] newValue: [anObject getUseCashReference]];
      [audit logChangeAsBoolean: RESID_CIM_GeneralSettings_ASK_REMOVE_CASH oldValue: [myRecordSet getCharValue: "ASK_REMOVE_CASH"] newValue: [anObject getAskRemoveCash]];
      [audit logChangeAsBoolean: RESID_CIM_GeneralSettings_PRINT_LOGO oldValue: [myRecordSet getCharValue: "PRINT_LOGO"] newValue: [anObject getPrintLogo]];
      [audit logChangeAsBoolean: RESID_CIM_GeneralSettings_ASK_QTY_IN_MANUAL_DROP oldValue: [myRecordSet getCharValue: "ASK_QTY_IN_MANUAL_DROP"] newValue: [anObject getAskQtyInManualDrop]];
      [audit logChangeAsBoolean: RESID_CIM_GeneralSettings_ASK_APPLY_TO oldValue: [myRecordSet getCharValue: "ASK_APPLY_TO"] newValue: [anObject getAskApplyTo]];

			[audit logChangeAsResourceString: FALSE
				resourceId: RESID_CIM_GeneralSettings_PRINT_OPERATOR_REPORT
				resourceStringBase: RESID_CIM_GeneralSettings_PRINT_OPERATOR_REPORT
				oldValue: ([myRecordSet getCharValue: "PRINT_OPERATOR_REPORT"])
				newValue: ([anObject getPrintOperatorReport])
				oldReference: [myRecordSet getCharValue: "PRINT_OPERATOR_REPORT"]
				newReference: [anObject getPrintOperatorReport]];

			[audit logChangeAsResourceString: FALSE
				resourceId: RESID_CIM_GeneralSettings_KEY_PAD_OP_MODE_ENVELOPE_ID
				resourceStringBase: RESID_CIM_GeneralSettings_KEY_PAD_OP_MODE_ENVELOPE_ID
				oldValue: ([myRecordSet getCharValue: "ENVELOPE_ID_OP_MODE"])
				newValue: ([anObject getEnvelopeIdOpMode])
				oldReference: [myRecordSet getCharValue: "ENVELOPE_ID_OP_MODE"]
				newReference: [anObject getEnvelopeIdOpMode]];

			[audit logChangeAsResourceString: FALSE
				resourceId: RESID_CIM_GeneralSettings_KEY_PAD_OP_MODE_APPLY_TO
				resourceStringBase: RESID_CIM_GeneralSettings_KEY_PAD_OP_MODE_ENVELOPE_ID
				oldValue: ([myRecordSet getCharValue: "APPLY_TO_OP_MODE"])
				newValue: ([anObject getApplyToOpMode])
				oldReference: [myRecordSet getCharValue: "APPLY_TO_OP_MODE"]
				newReference: [anObject getApplyToOpMode]];

      [audit logChangeAsBoolean: RESID_CIM_GeneralSettings_USE_BARCODE_READER oldValue: [myRecordSet getCharValue: "USE_BARCODE_READER"] newValue: [anObject getUseBarCodeReader]];
      [audit logChangeAsBoolean: RESID_CIM_GeneralSettings_REMOVE_BAG_VERIFICATION oldValue: [myRecordSet getCharValue: "REMOVE_BAG_VERIFICATION"] newValue: [anObject getRemoveBagVerification]];
      [audit logChangeAsBoolean: RESID_CIM_GeneralSettings_BAG_TRACKING oldValue: [myRecordSet getCharValue: "BAG_TRACKING"] newValue: [anObject getBagTracking]];
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_BARCODE_READER_COM_PORT oldValue: [myRecordSet getCharValue: "BARCODE_READER_COM_PORT"] newValue: [anObject getBarCodeReaderComPort]];

			[audit logChangeAsResourceString: FALSE
				resourceId: RESID_CIM_GeneralSettings_LOGIN_DEV_TYPE
				resourceStringBase: RESID_CIM_GeneralSettings_LOGIN_DEV_TYPE
				oldValue: ([myRecordSet getCharValue: "LOGIN_DEV_TYPE"])
				newValue: ([anObject getLoginDevType])
				oldReference: [myRecordSet getCharValue: "LOGIN_DEV_TYPE"]
				newReference: [anObject getLoginDevType]];

      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_LOGIN_DEV_COM_PORT oldValue: [myRecordSet getCharValue: "LOGIN_DEV_COM_PORT"] newValue: [anObject getLoginDevComPort]];
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_SWIPE_CARD_TRACK oldValue: [myRecordSet getCharValue: "SWIPE_CARD_TRACK"] newValue: [anObject getSwipeCardTrack]];
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_SWIPE_CARD_OFFSET oldValue: [myRecordSet getShortValue: "SWIPE_CARD_OFFSET"] newValue: [anObject getSwipeCardOffset]];
      [audit logChangeAsInteger: RESID_CIM_GeneralSettings_SWIPE_CARD_READ_QTY oldValue: [myRecordSet getShortValue: "SWIPE_CARD_READ_QTY"] newValue: [anObject getSwipeCardReadQty]];
      [audit logChangeAsBoolean: RESID_CIM_GeneralSettings_REMOVE_CASH_OUTER_DOOR oldValue: [myRecordSet getCharValue: "REMOVE_CASH_OUTER_DOOR"] newValue: [anObject removeCashOuterDoor]];
      [audit logChangeAsBoolean: RESID_CIM_GeneralSettings_USE_END_DAY oldValue: [myRecordSet getCharValue: "USE_END_DAY"] newValue: [anObject getUseEndDay]];

      [audit logChangeAsBoolean: RESID_CIM_GeneralSettings_ASK_BAG_CODE oldValue: [myRecordSet getCharValue: "ASK_BAG_CODE"] newValue: [anObject getAskBagCode]];

			[audit logChangeAsResourceString: FALSE
				resourceId: RESID_CIM_GeneralSettings_ACCEPTORS_CODE_TYPE
				resourceStringBase: RESID_CIM_GeneralSettings_ACCEPTORS_CODE_TYPE
				oldValue: ([myRecordSet getCharValue: "ACCEPTORS_CODE_TYPE"])
				newValue: ([anObject getAcceptorsCodeType])
				oldReference: [myRecordSet getCharValue: "ACCEPTORS_CODE_TYPE"]
				newReference: [anObject getAcceptorsCodeType]];      
			
			[audit logChangeAsBoolean: RESID_CIM_GeneralSettings_CONFIRM_CODE oldValue: [myRecordSet getCharValue: "CONFIRM_CODE"] newValue: [anObject getConfirmCode]];
			[audit logChangeAsBoolean: RESID_CIM_GeneralSettings_AUTO_BACKUP oldValue: [myRecordSet getCharValue: "AUTO_BACKUP"] newValue: [anObject isAutomaticBackup]];
			[audit logChangeAsInteger: RESID_CIM_GeneralSettings_BACKUP_TIME oldValue: [myRecordSet getShortValue: "BACKUP_TIME"] newValue: [anObject getBackupTime]];
			[audit logChangeAsBoolean: RESID_CIM_GeneralSettings_BACKUP_FRAME oldValue: [myRecordSet getCharValue: "BACKUP_FRAME"] newValue: [anObject getBackupFrame]];

			[audit logChangeAsResourceString: FALSE
				resourceId: RESID_CIM_GeneralSettings_KEY_PAD_OP_MODE_LOGIN
				resourceStringBase: RESID_CIM_GeneralSettings_KEY_PAD_OP_MODE_ENVELOPE_ID
				oldValue: ([myRecordSet getCharValue: "LOGIN_OP_MODE"])
				newValue: ([anObject getLoginOpMode])
				oldReference: [myRecordSet getCharValue: "LOGIN_OP_MODE"]
				newReference: [anObject getLoginOpMode]];

  		[myRecordSet setLongValue: "NEXT_DEPOSIT_NUMBER" value: [anObject getNextDepositNumber]];
  		[myRecordSet setLongValue: "NEXT_EXTRACTION_NUMBER" value: [anObject getNextExtractionNumber]];
  		[myRecordSet setLongValue: "NEXT_X_NUMBER" value: [anObject getNextXNumber]];
  		[myRecordSet setLongValue: "NEXT_Z_NUMBER" value: [anObject getNextZNumber]];
  		[myRecordSet setCharValue: "DEPOSIT_COPIES_QTY" value: [anObject getDepositCopiesQty]];
  		[myRecordSet setCharValue: "EXTRACTION_COPIES_QTY" value: [anObject getExtractionCopiesQty]];
  		[myRecordSet setCharValue: "X_COPIES_QTY" value: [anObject getXCopiesQty]];
  		[myRecordSet setCharValue: "Z_COPIES_QTY" value: [anObject getZCopiesQty]];
  		[myRecordSet setCharValue: "AUTO_PRINT" value: [anObject getAutoPrint]];
  		[myRecordSet setShortValue: "MAIL_BOX_OPEN_TIME" value: [anObject getMailboxOpenTime]];
  		[myRecordSet setShortValue: "MAX_INACTIVITY_TIME_ON_DEPOSIT" value: [anObject getMaxInactivityTimeOnDeposit]];
  		[myRecordSet setShortValue: "WARNING_TIME" value: [anObject getWarningTime]];
  		[myRecordSet setShortValue: "MAX_USER_INACTIVITY_TIME" value: [anObject getMaxUserInactivityTime]];
  		[myRecordSet setShortValue: "LOCK_LOGIN_TIME" value: [anObject getLockLoginTime]];
  		[myRecordSet setShortValue: "START_DAY" value: [anObject getStartDay]];
  		[myRecordSet setShortValue: "END_DAY" value: [anObject getEndDay]];
  		[myRecordSet setStringValue: "POS_ID" value: [anObject getPOSId]];
  		[myRecordSet setStringValue: "DEFAULT_BANK_INFO" value: [anObject getDefaultBankInfo]];
  		[myRecordSet setStringValue: "IDLE_TEXT" value: [anObject getIdleText]];
  		[myRecordSet setCharValue: "PIN_LENGHT" value: [anObject getPinLenght]];
  		[myRecordSet setShortValue: "PIN_LIFE" value: [anObject getPinLife]];
  		[myRecordSet setCharValue: "PIN_AUTO_INACTIVATE" value: [anObject getPinAutoInactivate]];
  		[myRecordSet setCharValue: "PIN_AUTO_DELETE" value: [anObject getPinAutoDelete]];
  		[myRecordSet setCharValue: "ASK_ENVELOPE_NUMBER" value: [anObject getAskEnvelopeNumber]];
  		changeUseChashRef = ([myRecordSet getCharValue: "USE_CASH_REFERENCE"] != [anObject getUseCashReference]);
      [myRecordSet setCharValue: "USE_CASH_REFERENCE" value: [anObject getUseCashReference]];
  		[myRecordSet setCharValue: "ASK_REMOVE_CASH" value: [anObject getAskRemoveCash]];
			[myRecordSet setCharValue: "PRINT_LOGO" value: [anObject getPrintLogo]];
			[myRecordSet setCharValue: "ASK_QTY_IN_MANUAL_DROP" value: [anObject getAskQtyInManualDrop]];
			[myRecordSet setCharValue: "ASK_APPLY_TO" value: [anObject getAskApplyTo]];
			[myRecordSet setCharValue: "PRINT_OPERATOR_REPORT" value: [anObject getPrintOperatorReport]];
						

			if ([anObject getCimModel] != -1)
				[myRecordSet setShortValue: "CIM_MODEL" value: [anObject getCimModel]];

			[myRecordSet setCharValue: "ENVELOPE_ID_OP_MODE" value: [anObject getEnvelopeIdOpMode]];
			[myRecordSet setCharValue: "APPLY_TO_OP_MODE" value: [anObject getApplyToOpMode]];
			[myRecordSet setCharValue: "USE_BARCODE_READER" value: [anObject getUseBarCodeReader]];
			[myRecordSet setCharValue: "REMOVE_BAG_VERIFICATION" value: [anObject getRemoveBagVerification]];
			[myRecordSet setCharValue: "BAG_TRACKING" value: [anObject getBagTracking]];
			[myRecordSet setCharValue: "BARCODE_READER_COM_PORT" value: [anObject getBarCodeReaderComPort]];
			[myRecordSet setCharValue: "LOGIN_DEV_TYPE" value: [anObject getLoginDevType]];
			[myRecordSet setCharValue: "LOGIN_DEV_COM_PORT" value: [anObject getLoginDevComPort]];
			[myRecordSet setCharValue: "SWIPE_CARD_TRACK" value: [anObject getSwipeCardTrack]];
			[myRecordSet setShortValue: "SWIPE_CARD_OFFSET" value: [anObject getSwipeCardOffset]];
			[myRecordSet setShortValue: "SWIPE_CARD_READ_QTY" value: [anObject getSwipeCardReadQty]];
			[myRecordSet setCharValue: "REMOVE_CASH_OUTER_DOOR" value: [anObject removeCashOuterDoor]];
			[myRecordSet setCharValue: "USE_END_DAY" value: [anObject getUseEndDay]];
			[myRecordSet setCharValue: "ASK_BAG_CODE" value: [anObject getAskBagCode]];
			[myRecordSet setCharValue: "ACCEPTORS_CODE_TYPE" value: [anObject getAcceptorsCodeType]];
			[myRecordSet setCharValue: "CONFIRM_CODE" value: [anObject getConfirmCode]];
			[myRecordSet setCharValue: "AUTO_BACKUP" value: [anObject isAutomaticBackup]];
			[myRecordSet setShortValue: "BACKUP_TIME" value: [anObject getBackupTime]];
			[myRecordSet setCharValue: "BACKUP_FRAME" value: [anObject getBackupFrame]];
			[myRecordSet setCharValue: "LOGIN_OP_MODE" value: [anObject getLoginOpMode]];

  		[myRecordSet save];

      [audit saveAudit];
      [audit free];

			// *********** Analiza si debe hacer backup online ***********
			if ([dbConnection tableHasBackup: "cim_settings_bck"]) {
				myRecordSetBck = [dbConnection createRecordSet: "cim_settings_bck"];

				[self doUpdateBackupById: "CIM_GENERAL_SETTINGS_ID" value: [anObject getCimGeneralSettingsId] backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "cim_settings_bck"];
			}

      if (changeUseChashRef)
        [[JSystem getInstance] onRefreshMenu];
		}
	
	FINALLY
		
			[myRecordSet free];			

	END_TRY
}

/**/
- (void) validateFields: (id) anObject
{
  
  if ( ([anObject getNextDepositNumber] < 0) || ([anObject getNextDepositNumber] > 99999999) ) 
    THROW(DAO_NEXT_DEPOSIT_NUMBER_VALUE_INCORRECT_EX);

  if ( ([anObject getNextExtractionNumber] < 0) || ([anObject getNextExtractionNumber] > 99999999) ) 
    THROW(DAO_NEXT_EXTRACTION_NUMBER_VALUE_INCORRECT_EX);

  if ( ([anObject getNextXNumber] < 0) || ([anObject getNextXNumber] > 99999999) ) 
    THROW(DAO_NEXT_X_NUMBER_VALUE_INCORRECT_EX);

  if ( ([anObject getNextZNumber] < 0) || ([anObject getNextZNumber] > 99999999) ) 
    THROW(DAO_NEXT_Z_NUMBER_VALUE_INCORRECT_EX);

  if ( ([anObject getDepositCopiesQty] < 0) || ([anObject getDepositCopiesQty] > 5) )
    THROW(DAO_DEPOSIT_COPIES_QTY_INCORRECT_EX);

  if ( ([anObject getExtractionCopiesQty] < 0) || ([anObject getExtractionCopiesQty] > 5) )
    THROW(DAO_EXTRACTION_COPIES_QTY_INCORRECT_EX);

  if ( ([anObject getXCopiesQty] < 0) || ([anObject getXCopiesQty] > 5) )
    THROW(DAO_X_COPIES_QTY_INCORRECT_EX);

  if ( ([anObject getZCopiesQty] < 0) || ([anObject getZCopiesQty] > 5) )
    THROW(DAO_Z_COPIES_QTY_INCORRECT_EX);

	// start day
  if ( ([anObject getStartDay] < 0) || ([anObject getStartDay] >= 1440) )
    THROW(DAO_START_DAY_INCORRECT_EX);

	// end day
  if ( ([anObject getEndDay] < 0) || ([anObject getEndDay] >= 1440) )
    THROW(DAO_END_DAY_INCORRECT_EX);

	// pin length
  if ( ([anObject getPinLenght] < 4) || ([anObject getPinLenght] > 8) )
    THROW(DAO_PIN_LENGTH_INCORRECT_EX);

	// pin life
  if ( ([anObject getPinLife] < 0) || ([anObject getPinLife] > 365) )
    THROW(DAO_PIN_LIFE_INCORRECT_EX);

	// pin auto inactivate
  if ( ([anObject getPinAutoInactivate] < 0) || ([anObject getPinAutoInactivate] > 12) )
    THROW(DAO_PIN_AUTO_INACTIVATE_EX);

	// pin auto delete
  if ( ([anObject getPinAutoDelete] < 0) || ([anObject getPinAutoDelete] > 12) )
    THROW(DAO_PIN_AUTO_DELETE_EX);

	// No puede ser AutoPrint y PrintOperatorReport=Ask
	if ([anObject getAutoPrint] && [anObject getPrintOperatorReport] == PrintOperatorReport_ASK)
		THROW(DAO_CANNOT_AUTO_PRINT_AND_ASK_EX);

	// El puerto COM de los dispositivos de login no puede ser igual al puerto COM del 
	// lector de codigos de barras
	// Primero verifico que ambos esten activos
	if ( ([anObject getLoginDevType] != LoginDevType_NONE) && ([anObject getUseBarCodeReader]) ) {
		if ([anObject getBarCodeReaderComPort] == [anObject getLoginDevComPort])
			THROW(DAO_EQUALS_COM_PORT_EX);
	}

	// bug tracking y removeCashOuterDoor no se pueden usar al mismo tiempo
	if ( ([anObject getRemoveBagVerification] || [anObject getBagTracking]) &&
		   ([anObject removeCashOuterDoor]) ){
			THROW(DAO_BUG_AND_OUTER_EX);
	}

	// backup time
  if ( ([anObject getBackupTime] < 0) || ([anObject getBackupTime] >= 1440) )
    THROW(DAO_BACKUP_TIME_INCORRECT_EX);

	// backup time
  if ( ([anObject getBackupFrame] < 1) || ([anObject getBackupFrame] >= 60) )
    THROW(DAO_BACKUP_FRAME_INCORRECT_EX);

}



@end
