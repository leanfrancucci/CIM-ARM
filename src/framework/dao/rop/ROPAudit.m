#include "ROPAudit.h"
#include "Audit.h"
#include "util.h"
#include "FilteredRecordSet.h" 

static id singleInstance = NULL;

@implementation ROPAudit


/**/
+ new
{
	if (!singleInstance) singleInstance = [super new];
	return singleInstance;
}

/**/
- (void) createRecordSet
{
	myRecordSet = [[MultiPartRecordSet new] initWithTableName: "audits"];
	[myRecordSet setDateField: "DATE"];
	[myRecordSet setIdField: "AUDIT_ID"];
	[myRecordSet open];

  myChangeLogRecordSet = [[MultiPartRecordSet new] initWithTableName: "change_log"];
  [myChangeLogRecordSet setIdField: "AUDIT_ID"];
	[myChangeLogRecordSet setDateField: ""];
	[myChangeLogRecordSet open];
 
}

/**/
+ getInstance
{
	return [self new];
}

/**/

- (id) loadById: (unsigned long) anId
{
	return NULL;
}

/* Agregado por GV */ 
- (ABSTRACT_RECORDSET) getNewAuditsRecordSet
{ 
	RECORD_SET rs = [[MultiPartRecordSet new] initWithTableName: "audits"]; 
	[rs setIdField: "AUDIT_ID"]; 
	[rs setDateField: "DATE"]; 
	return rs;	 
} 

- (ABSTRACT_RECORDSET) getNewChangeLogRecordSet
{
	RECORD_SET rs = [[MultiPartRecordSet new] initWithTableName: "change_log"]; 
	[rs setIdField: "AUDIT_ID"]; 
	[rs setDateField: ""]; 
	return rs;	 
}


/* Agregado por GV */ 
- (ABSTRACT_RECORDSET) getNewAuditsRecordSetById: (unsigned long) aFromId to: (unsigned long) aToId 
{ 
	FILTERED_RECORDSET recordSet; 
	
	recordSet = [[FilteredRecordSet new] initWithRecordset: [self getNewAuditsRecordSet]];
	
	/**/
	if (aFromId > 0)
		[recordSet addLongFilter: "AUDIT_ID" operator: ">=" value: aFromId];
		
	/**/
	if (aToId > 0)
		[recordSet addLongFilter: "AUDIT_ID" operator: "<=" value: aToId];
								
	return recordSet;	
} 

/* Agregado por GV */ 
- (ABSTRACT_RECORDSET) getNewAuditsRecordSetByDate: (datetime_t) aFromDate to: (datetime_t) aToDate
{ 
	FILTERED_RECORDSET recordSet; 
	
	recordSet = [[FilteredRecordSet new] initWithRecordset: [self getNewAuditsRecordSet]];
	
	if (aFromDate > 0)
		[recordSet addLongFilter: "DATE" operator: ">=" value: aFromDate];
		
	if (aToDate > 0)
		[recordSet addLongFilter: "DATE" operator: "<=" value: aToDate];
								
	return recordSet;		
}

/**/
- (unsigned long) getLastAuditId
{
 ABSTRACT_RECORDSET rs = [self getNewAuditsRecordSet];
 unsigned long lastId = 0;

 [rs open];

 if ([rs moveLast]) lastId = [rs getLongValue: "AUDIT_ID"];

 [rs close];
 [rs free];

 return lastId;
}

@end
