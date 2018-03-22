#include "SQLAudit.h"
#include "Audit.h"
#include "util.h"


static id singleInstance = NULL;

@implementation SQLAudit


/**/
+ new
{
	if (!singleInstance) singleInstance = [super new];
	return singleInstance;
}

/**/
- (void) createRecordSet
{

	myRecordSet = [[DBConnection getInstance] createRecordSet: "audits"];
  [myRecordSet setFetchOnOpen: FALSE];
	[myRecordSet open];

  myChangeLogRecordSet = [[DBConnection getInstance] createRecordSet: "change_log"];
  [myChangeLogRecordSet setFetchOnOpen: FALSE];
	[myChangeLogRecordSet open];
 
}

/**/
+ getInstance
{
	return [self new];
}

/**/
- (void) checkAuditId 
{
  char sql[512];
  unsigned long lastAuditId;

  // Setea el generator al ultimo id de auditoria existente.
  // Pude ocurrir que por un corte de energia se saltee el numero de AUDIT_ID, y eso
  // nunca debe suceder, especialmente en Ecuador.
  lastAuditId = [self getLastAuditId];
  sprintf(sql, "set generator GEN_AUDITS to %ld", lastAuditId);
  [[DBConnection getInstance] executeStatement: sql];
}

/**/

- (id) loadById: (unsigned long) anId
{
	return NULL;
}


/* Agregado por GV */ 
- (ABSTRACT_RECORDSET) getNewAuditsRecordSet
{ 
  ABSTRACT_RECORDSET rs;
  rs = [[DBConnection getInstance] createRecordSet: "audits"];
	return rs;	 
} 


/* Agregado por GV */ 
- (ABSTRACT_RECORDSET) getNewAuditsRecordSetById: (unsigned long) aFromId to: (unsigned long) aToId 
{ 
  ABSTRACT_RECORDSET rs;
  char query[255];

  if (aFromId > 0 && aToId > 0)
    snprintf(query, 255, "select * from audits where audit_id >= %ld and audit_id <= %ld", aFromId, aToId);
  else if (aFromId > 0)
    snprintf(query, 255, "select * from audits where audit_id >= %ld", aFromId);
  else if (aToId > 0)
    snprintf(query, 255, "select * from audits where audit_id <= %ld", aToId);
  else 
    snprintf(query, 255, "select * from audits");

  rs = [[DBConnection getInstance] createRecordSetFromQuery: query];

	return rs;
} 

/* Agregado por GV */ 
- (ABSTRACT_RECORDSET) getNewAuditsRecordSetByDate: (datetime_t) aFromDate to: (datetime_t) aToDate
{ 
  ABSTRACT_RECORDSET rs;
  char query[255];
  char date1[30];
  char date2[30];

  if (aFromDate > 0 && aToDate > 0)
    snprintf(query, 255, "select * from audits where \"DATE\" >= '%s' and \"DATE\" <= '%s'", formatSQLDateTime(date1, aFromDate), formatSQLDateTime(date2, aToDate)); 
  else if (aFromDate > 0)
    snprintf(query, 255, "select * from audits where \"DATE\" >= '%s'", formatSQLDateTime(date1, aFromDate));
  else if (aToDate > 0)
    snprintf(query, 255, "select * from audits where \"DATE\" <= '%s'", formatSQLDateTime(date1, aToDate));
  else 
    snprintf(query, 255, "select * from audits");

 // doLog(0,"ejecutando query = %s\n", query);fflush(stdout);

  rs = [[DBConnection getInstance] createRecordSetFromQuery: query];

	return rs;
} 


/**/
- (unsigned long) getLastAuditId
{
  char query[512];
  ABSTRACT_RECORDSET rs;
  unsigned long lastAuditId= -1;
  
  snprintf(query, 512, " select first 1 audit_id "
                       " from audits where audit_id > ((select gen_id(gen_audits,0) from rdb$database)-500) "
                       " order by audit_id desc");
                       
  rs = [[DBConnection getInstance] createRecordSetFromQuery: query];
  [rs open];
  if ([rs moveFirst]) lastAuditId = (unsigned long)[rs getLongValue: "AUDIT_ID"];
  [rs free];

  return lastAuditId;	
}

@end
