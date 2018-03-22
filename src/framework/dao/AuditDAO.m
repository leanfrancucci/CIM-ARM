#include "Audit.h"
#include "AuditDAO.h"
#include "system/db/all.h"
#include "CimBackup.h"
#include "CimExcepts.h"

//#define printd(args...) doLog(0,args)
//#define printd(args...)

@implementation AuditDAO

static BOOL myFirstAudit = TRUE;

/**/
- (void) createRecordSet
{
	THROW( ABSTRACT_METHOD_EX );
}

/**/
- initialize
{
	unsigned long auditId = 0;
	unsigned long backupAuditId = 0;

	[super initialize];
	myMutex = [OMutex new];
  [self createRecordSet];
	
	if ([myRecordSet moveLast]) auditId = [myRecordSet getLongValue: "AUDIT_ID"];

	TRY

		backupAuditId = [[CimBackup getInstance] getLastRowValue: "audits" field: "AUDIT_ID"];
		if (backupAuditId > auditId) {
	
			[myRecordSet moveLast];
			[myRecordSet setInitialAutoIncValue: backupAuditId];
	
		}

	CATCH
		if (ex_get_code() != CIM_USER_COMM_NOT_IN_EMER_EX) RETHROW();
	END_TRY

	//doLog(0,"lastAuditId = %ld, backupAuditId = %ld\n", auditId, backupAuditId);

	return self;
}


/**/
- free
{
	[myMutex free];
	[myRecordSet free];
  [myChangeLogRecordSet free];
	return [super free];
}

/**/
- (void) checkAuditId
{
}

/**/
- (void) store: (id) anObject
{
  unsigned long auditId;
  COLLECTION changeLogList;
  ChangeLog *changeLog;
  BOOL hasChangeLog = FALSE;
  int i;

	[myMutex lock];
	
	TRY

    if (myFirstAudit) {
      myFirstAudit = FALSE;
      [self checkAuditId];
    }
	
		[myRecordSet add];
	 
    changeLogList = [anObject getChangeLog];
  	hasChangeLog = (changeLogList != NULL && [changeLogList size] > 0);

		[myRecordSet setShortValue: "EVENT_ID" value: [anObject getEventId]];
		if ([anObject getUserId] != 0) [myRecordSet setShortValue: "USER_ID" value: [anObject getUserId]];
		[myRecordSet setCharValue: "SYSTEM_TYPE" value: [anObject getSystemType]];
		[myRecordSet setDateTimeValue: "DATE" value: [anObject getAuditDate]];
		[myRecordSet setShortValue: "STATION" value: [anObject getStation]];
		[myRecordSet setStringValue: "ADDITIONAL" value: [anObject getAdditional]];
    [myRecordSet setBoolValue: "HAS_CHANGE_LOG" value: hasChangeLog];
	
		auditId = [myRecordSet save];
		
		[anObject setAuditId: auditId];
    
		[[CimBackup getInstance] syncRecord: "audits" buffer: [myRecordSet getRecordBuffer]];

    // Grabo en el log de cambios el detalle de los cambios realizados
    // Sino existe dicho log o es vacio no hago nada
    // Si existe entonces grabo un registro por cada cambio

    if (hasChangeLog) {
      for (i = 0; i < [changeLogList size]; ++i) {
        changeLog = (ChangeLog*) [changeLogList at: i];
        [myChangeLogRecordSet add];
        [myChangeLogRecordSet setLongValue: "AUDIT_ID" value: auditId];
        [myChangeLogRecordSet setLongValue: "FIELD" value: changeLog->field];
        [myChangeLogRecordSet setStringValue: "OLD_VALUE" value: changeLog->oldValue];
        [myChangeLogRecordSet setStringValue: "NEW_VALUE" value: changeLog->newValue];
				[myChangeLogRecordSet setLongValue: "OLD_REFERENCE" value: changeLog->oldReference];
				[myChangeLogRecordSet setLongValue: "NEW_REFERENCE" value: changeLog->newReference];
        [myChangeLogRecordSet save];

				[[CimBackup getInstance] syncRecord: "change_log" buffer: [myChangeLogRecordSet getRecordBuffer]];

      }  
    }

	FINALLY
	
		[myMutex unLock];
		
	END_TRY		


}

/**/
- (unsigned long) storeAudit: (int) anEventId userId: (int) aUserId date: (datetime_t) aDate station: (int) aStation additional: (char *) anAdditional systemType: (int) aSystemType
{
  unsigned long auditId = 0;

	[myMutex lock];
	
	TRY

    if (myFirstAudit) {
      myFirstAudit = FALSE;
      [self checkAuditId];
    }
		
		[myRecordSet add];
		
		[myRecordSet setShortValue: "EVENT_ID" value: anEventId];
    if (aUserId != 0) [myRecordSet setShortValue: "USER_ID" value: aUserId];
		[myRecordSet setCharValue: "SYSTEM_TYPE" value: aSystemType];
		[myRecordSet setDateTimeValue: "DATE" value: aDate];
		[myRecordSet setShortValue: "STATION" value: aStation];
		[myRecordSet setStringValue: "ADDITIONAL" value: anAdditional];

    // Esto lo hago por las dudas, porque es muy probable que alguien ejecute
    // esta version de codigo con una base de datos vieja y si no esta esto
    // se rompe todo.
    TRY
      [myRecordSet setBoolValue: "HAS_CHANGE_LOG" value: FALSE];
    CATCH
    //  doLog(0,"No existe el campo HAS_CHANGE_LOG, actualizar version...\n");
      ex_printfmt();
    END_TRY

		auditId = [myRecordSet save];

		[[CimBackup getInstance] syncRecord: "audits" buffer: [myRecordSet getRecordBuffer]];

	FINALLY
	
		[myMutex unLock];
		
	END_TRY

//	[[CimBackup getInstance] syncFile: "audits"];
	
  return auditId; 			
}


/**/
- (ABSTRACT_RECORDSET) getNewAuditsRecordSet
{
	THROW( ABSTRACT_METHOD_EX );
	return NULL;
}

/**/
- (ABSTRACT_RECORDSET) getNewAuditsRecordSetById: (unsigned long) aFromId to: (unsigned long) aToId
{
	THROW( ABSTRACT_METHOD_EX );
	return NULL;
}


/**/
- (ABSTRACT_RECORDSET) getNewAuditsRecordSetByDate: (datetime_t) aFromDate to: (datetime_t) aToDate
{
	THROW( ABSTRACT_METHOD_EX );
	return NULL;
}

/**/
- (ABSTRACT_RECORDSET) getNewChangeLogRecordSet
{
	THROW( ABSTRACT_METHOD_EX );
	return NULL;
}

/**/
- (unsigned long) getLastAuditId
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}

/**/
- (void) deleteAll
{
	[myRecordSet deleteAll];
	[myChangeLogRecordSet deleteAll];
}

@end
