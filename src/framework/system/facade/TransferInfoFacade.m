#include "system/db/all.h"
#include "Persistence.h"
#include "TransferInfoFacade.h"
#include "AuditDAO.h"

static id singleInstance = NULL;

@implementation TransferInfoFacade

/**/
+ new
{
	if (!singleInstance) singleInstance = [[super new] initialize];
	return singleInstance;
}

/**/
+ getInstance
{
	return [self new];
}

/**/
- initialize
{
	[super initialize];
	
	return self;
}

- free
{
	return self;
}

/**
 * AUDITORIAS
 */

/**/
- (ABSTRACT_RECORDSET) getAuditsRecordSet
{	
	return [[[Persistence getInstance] getAuditDAO] getNewAuditsRecordSet];
}

/**/
- (ABSTRACT_RECORDSET) getAuditsRecordSetById: (unsigned long) aFromId to: (unsigned long) aToId
{	
	return [[[Persistence getInstance] getAuditDAO] getNewAuditsRecordSetById: aFromId to: aToId];
}

/**/
- (ABSTRACT_RECORDSET) getAuditsRecordSetByDate: (datetime_t) aFromDate to: (datetime_t) aToDate
{	
	return [[[Persistence getInstance] getAuditDAO] getNewAuditsRecordSetByDate: aFromDate to: aToDate];
}
 
 
@end
