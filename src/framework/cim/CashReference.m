#include "CashReference.h"
#include "system/util/all.h"
#include "Persistence.h"

@implementation CashReference

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myParent = NULL;
	myCashReferenceId = 0;
	*myName = '\0';
	myIsDeleted = FALSE;
	myParentId = 0;
	return self;
}

/**/
- (void) setCashReferenceId: (int) aValue { myCashReferenceId = aValue; }
- (int) getCashReferenceId { return myCashReferenceId; }

/**/
- (void) setName: (char *) aName { stringcpy(myName, trim(aName)); }
- (char *) getName { return myName; }

/**/
- (void) setDeleted: (BOOL) aValue { myIsDeleted = aValue; }
- (BOOL) isDeleted { return myIsDeleted; }

/**/
- (void) setParent: (CASH_REFERENCE) aParent { myParent = aParent; }
- (CASH_REFERENCE) getParent { return myParent; }

/**/
- (void) setParentId: (int) aParentId { myParentId = aParentId; }
- (int) getParentId { return myParentId; }

/**/
- (void) restore
{
	CASH_REFERENCE obj;

	obj = [[[Persistence getInstance] getCashReferenceDAO] loadById: [self getCashReferenceId]];
	[self setName: [obj getName]];
	[obj free];
}

/**/
- (void) applyChanges 
{
	[[[Persistence getInstance] getCashReferenceDAO] store: self];
}

/**/
- (void) getCompleteName: (char *) aBuffer
{

	if (myParent != NULL) {
		[myParent getCompleteName: aBuffer];
		strcat(aBuffer, " - ");
	}

	strcat(aBuffer, myName);

}

/**/
- (STR) str
{
	return myName;
}

@end

