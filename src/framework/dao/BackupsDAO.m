#include "BackupsDAO.h"
#include "CimBackup.h"
#include "SettingsExcepts.h"
#include "system/db/all.h"
#include "MessageHandler.h"
#include "util.h"
#include "Persistence.h"

static id singleInstance = NULL;

@implementation BackupsDAO

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
- (void) loadById: (unsigned long) anId cimBackup: (id) aCimBackup
{
	char buffer[200];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "backups"];

	[myRecordSet open];
	
	if (![myRecordSet findById: "BACKUP_ID" value: anId]) {
		// si no lo encuentra es porque es la primera vez que accede.
		// se deben crear el registro con lo valores por defecto
		TRY

			[myRecordSet add];
			[myRecordSet setLongValue: "LAST_AUDIT_ID" value: [aCimBackup getLastAuditId]];
			[myRecordSet setLongValue: "LAST_AUDIT_DETAIL_ID" value: [aCimBackup getLastAuditDetailId]];
			[myRecordSet setLongValue: "LAST_DROP_ID" value: [aCimBackup getLastDropId]];
			[myRecordSet setLongValue: "LAST_DROP_DETAIL_ID" value: [aCimBackup getLastDropDetailId]];
			[myRecordSet setLongValue: "LAST_DEPOSIT_ID" value: [aCimBackup getLastDepositId]];
			[myRecordSet setLongValue: "LAST_DEPOSIT_DETAIL_ID" value: [aCimBackup getLastDepositDetailId]];
			[myRecordSet setLongValue: "LAST_ZCLOSE_ID" value: [aCimBackup getLastZcloseId]];
			[myRecordSet setDateTimeValue: "BACKUP_TRANS_DATE" value: [aCimBackup getBackupTransDate]];
			[myRecordSet setDateTimeValue: "BACKUP_SETT_DATE" value: [aCimBackup getBackupSettDate]];
			[myRecordSet setDateTimeValue: "BACKUP_USER_DATE" value: [aCimBackup getBackupUserDate]];
			[myRecordSet setCharArrayValue: "TABLE_CHECK" value: [aCimBackup getTableCheckList]];
			[myRecordSet save];

		FINALLY

		END_TRY

	} else {

		[aCimBackup setLastAuditId: [myRecordSet getLongValue: "LAST_AUDIT_ID"]];
		[aCimBackup setLastAuditDetailId: [myRecordSet getLongValue: "LAST_AUDIT_DETAIL_ID"]];
		[aCimBackup setLastDropId: [myRecordSet getLongValue: "LAST_DROP_ID"]];
		[aCimBackup setLastDropDetailId: [myRecordSet getLongValue: "LAST_DROP_DETAIL_ID"]];
		[aCimBackup setLastDepositId: [myRecordSet getLongValue: "LAST_DEPOSIT_ID"]];
		[aCimBackup setLastDepositDetailId: [myRecordSet getLongValue: "LAST_DEPOSIT_DETAIL_ID"]];
		[aCimBackup setLastZcloseId: [myRecordSet getLongValue: "LAST_ZCLOSE_ID"]];
		[aCimBackup setBackupTransDate: [myRecordSet getDateTimeValue: "BACKUP_TRANS_DATE"]];
		[aCimBackup setBackupSettDate: [myRecordSet getDateTimeValue: "BACKUP_SETT_DATE"]];
		[aCimBackup setBackupUserDate: [myRecordSet getDateTimeValue: "BACKUP_USER_DATE"]];
		[aCimBackup setTableCheckList: [myRecordSet getCharArrayValue: "TABLE_CHECK" buffer: buffer]];

	}

	[myRecordSet free];
}

/**/
- (void) store: (id) anObject
{
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "backups"];

	TRY
	
		[myRecordSet open];

		if ([myRecordSet findById: "BACKUP_ID" value: 1]) {

			[myRecordSet setLongValue: "LAST_AUDIT_ID" value: [anObject getLastAuditId]];
			[myRecordSet setLongValue: "LAST_AUDIT_DETAIL_ID" value: [anObject getLastAuditDetailId]];
			[myRecordSet setLongValue: "LAST_DROP_ID" value: [anObject getLastDropId]];
			[myRecordSet setLongValue: "LAST_DROP_DETAIL_ID" value: [anObject getLastDropDetailId]];
			[myRecordSet setLongValue: "LAST_DEPOSIT_ID" value: [anObject getLastDepositId]];
			[myRecordSet setLongValue: "LAST_DEPOSIT_DETAIL_ID" value: [anObject getLastDepositDetailId]];
			[myRecordSet setLongValue: "LAST_ZCLOSE_ID" value: [anObject getLastZcloseId]];
			[myRecordSet setDateTimeValue: "BACKUP_TRANS_DATE" value: [anObject getBackupTransDate]];
			[myRecordSet setDateTimeValue: "BACKUP_SETT_DATE" value: [anObject getBackupSettDate]];
			[myRecordSet setDateTimeValue: "BACKUP_USER_DATE" value: [anObject getBackupUserDate]];
			[myRecordSet setCharArrayValue: "TABLE_CHECK" value: [anObject getTableCheckList]];

  		[myRecordSet save];
		}
	
	FINALLY
		
			[myRecordSet free];			

	END_TRY
}

@end
