#ifndef AUDIT_DAO_H
#define AUDIT_DAO_H

#define AUDIT_DAO id

#include <Object.h>
#include "ctapp.h"
#include "system/db/all.h"
#include "DataObject.h"

/** 
 *	<<singleton>>
 */
@interface AuditDAO: DataObject
{
	ABSTRACT_RECORDSET myRecordSet;
  ABSTRACT_RECORDSET myChangeLogRecordSet;
	OMUTEX myMutex;
}

+ getInstance;

- (unsigned long) storeAudit: (int) anEventId userId: (int) aUserId date: (datetime_t) aDate station: (int) aStation additional: (char*) anAdditional systemType: (int) aSystemType;

- (unsigned long) getLastAuditId;

/* Agregado por GV */ 
- (ABSTRACT_RECORDSET) getNewAuditsRecordSet;	 

/* Agregado por GV */ 
- (ABSTRACT_RECORDSET) getNewAuditsRecordSetById: (unsigned long) aFromId to: (unsigned long) aToId;	 

/* Agregado por GV */ 
- (ABSTRACT_RECORDSET) getNewAuditsRecordSetByDate: (datetime_t) aFromDate to: (datetime_t) aToDate;

/**/
- (ABSTRACT_RECORDSET) getNewChangeLogRecordSet;

/**/
- (unsigned long) getLastAuditId;

@end

#endif
