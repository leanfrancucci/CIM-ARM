#ifndef CASH_REFERENCE_H
#define CASH_REFERENCE_H

#define CASH_REFERENCE id

#include "Object.h"

#define CASH_REFERENCE_NAME 30

/**
 *	
 */
@interface CashReference :  Object
{
	int myCashReferenceId;
	char myName[CASH_REFERENCE_NAME + 1];
	CASH_REFERENCE myParent;
	int myParentId;
	BOOL myIsDeleted;
}

/**/
- (void) setCashReferenceId: (int) aValue;
- (int) getCashReferenceId;

/**/
- (void) setName: (char *) aName;
- (char *) getName;

/**/
- (void) setDeleted: (BOOL) aValue;
- (BOOL) isDeleted;

/**/
- (void) setParent: (CASH_REFERENCE) aParent;
- (CASH_REFERENCE) getParent;

/**/
- (void) setParentId: (int) aParentId;
- (int) getParentId;

/**/
- (void) getCompleteName: (char *) aBuffer;

/**/
- (void) applyChanges;

/**/
- (void) restore;

@end

#endif

