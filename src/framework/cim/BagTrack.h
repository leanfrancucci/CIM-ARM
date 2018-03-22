#ifndef BAG_TRACK_H
#define BAG_TRACK_H

#define BAG_TRACK id

#include <Object.h>
#include "CimDefs.h"
#include "system/lang/all.h"

@interface BagTrack: Object
{
	unsigned long myExtractionNumber;
	char myNumber[20];
	unsigned long myParentId;
	int myType;
	int myAcceptorId;
}

/**/
- (void) setExtractionNumber: (unsigned long) aValue;
- (unsigned long) getExtractionNumber;

/**/
- (void) setBNumber: (char*) aValue;
- (char*) getBNumber;

/**/
- (void) setBParentId: (unsigned long) aValue;
- (unsigned long) getBParentId;

/**/
- (void) setAcceptorId: (int) aValue;
- (int) getAcceptorId;

/**/
- (void) debugBagTrack;

@end

#endif
