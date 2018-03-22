#include "BagTrack.h"
#include "system/util/all.h"
#include "CimGeneralSettings.h"

@implementation BagTrack

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myExtractionNumber = 0;
	myNumber[0] = '\0';
	myParentId = 0;
	myType = BagTrackingMode_NONE;
	myAcceptorId = 0;

	return self;
}

- (void) setExtractionNumber: (unsigned long) aValue { myExtractionNumber = aValue; }
- (unsigned long) getExtractionNumber { return myExtractionNumber; }

/**/
- (void) setBNumber: (char*) aValue { stringcpy(myNumber, aValue); }
- (char*) getBNumber { return myNumber; }

/**/
- (void) setBParentId: (unsigned long) aValue { myParentId = aValue; }
- (unsigned long) getBParentId { return myParentId; }

/**/
- (void) setBType: (int) aValue { myType = aValue; }
- (int) getBType { return myType; }

- (void) setAcceptorId: (int) aValue { myAcceptorId = aValue; }
- (int) getAcceptorId { return myAcceptorId; }

/**/
- (void) debugBagTrack
{
	printf("BagTrack\n");
	printf("Extraction          Number 			  ParentId  Type   AcceptorId\n");
	printf("%ld                 %s            %ld       %d    %d\n", myExtractionNumber, myNumber, myParentId, myType, myAcceptorId);

}

@end
