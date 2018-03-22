#ifndef EXTRACTION_DAO_H
#define EXTRACTION_DAO_H

#define EXTRACTION_DAO id

#include <Object.h>
#include "ctapp.h"
#include "system/db/all.h"
#include "DataObject.h"

/** 
 *	<<singleton>>
 */
@interface ExtractionDAO: DataObject
{
	ABSTRACT_RECORDSET myExtractionRS;
	ABSTRACT_RECORDSET myExtractionDetailRS;
	ABSTRACT_RECORDSET myBagTrackingRS;
}

/**/
+ getInstance;

/**/
- (ABSTRACT_RECORDSET) getNewExtractionRecordSet;

/**/
- (ABSTRACT_RECORDSET) getNewExtractionDetailRecordSet;

/**/
- (id) loadLast;

/**/
- (id) loadLastFromDoor: (int) aDoorId;

/**/
- (unsigned long) getLastExtractionNumber;

/**/
- (ABSTRACT_RECORDSET) getExtractionRecordSetByDate: (datetime_t) aFromDate to: (datetime_t) aToDate;

/**/
- (unsigned long) storeBagTracking: (id) anObject;
- (COLLECTION) storeAutoBagTrack: (id) anObject;

/** 
 * Comienza desde el final por una cuestion de cercania de datos	
 */
- (id) loadExtractionHeaderByNumber: (unsigned long) aNumber;
- (unsigned long) loadBagTrackParentIdByExtraction: (unsigned long) aNumber type: (int) aType;

/**/
- (void) loadBagTrackingByExtraction: (id) anExtraction;

@end

#endif
