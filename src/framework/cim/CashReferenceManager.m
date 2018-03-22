#include "CashReferenceManager.h"
#include "Persistence.h"
#include "CashReferenceDAO.h"

@implementation CashReferenceManager

static CASH_REFERENCE_MANAGER singleInstance = NULL;

// forward
- (void) relationateReferences;

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}
 
/**/
- initialize
{
	myReferences = [[[Persistence getInstance] getCashReferenceDAO] loadAll];
	[self relationateReferences];
	return self;
}

/**/
+ getInstance
{
  return [self new];
}

/**/
- (void) relationateReferences
{
	int i;

	// Relaciono los objectos con sus padres
	// hasta este punto solo tiene el parentId pero no el objecto padre en si.

	for (i = 0; i < [myReferences size]; ++i) {
		if ([[myReferences at: i] getParentId] != 0) {
			[[myReferences at: i] setParent: [self getCashReferenceById: [[myReferences at: i] getParentId]]];
		}
	}

}

/**/
- (void) getCashReferenceChilds: (COLLECTION) aCollection cashReference: (CASH_REFERENCE) aCashReference
{
	int i;
	CASH_REFERENCE parent;

	[aCollection removeAll];

	for (i = 0; i < [myReferences size]; ++i) {

		if ([[myReferences at: i] isDeleted]) continue;

		parent = [[myReferences at: i] getParent];

		if (parent != NULL && [parent isDeleted]) continue;

		if (parent == aCashReference) {
			[aCollection add: [myReferences at: i]];
		}

	}

}

/**/
- (COLLECTION) getCashReferences
{
	return myReferences;
}

/**/
- (void) addCashReference: (CASH_REFERENCE) aCashReference
{
	[myReferences add: aCashReference];
}

/**/
- (int) addCashReference: (char *) aName parentId: (int) aParentId
{
	CASH_REFERENCE cashReference = [CashReference new];

	[cashReference setName: aName];
	[cashReference setParentId: aParentId];
	[cashReference setParent: [self getCashReferenceById: aParentId]];
	[cashReference applyChanges];
	[self addCashReference: cashReference];

	return [cashReference getCashReferenceId];
}

/**/
- (void) removeCashReference: (CASH_REFERENCE) aCashReference
{
	[aCashReference setDeleted: TRUE];
	[aCashReference applyChanges];
}

/**/
- (CASH_REFERENCE) getCashReferenceById: (int) aCashReferenceId
{
	int i;

	for (i = 0; i < [myReferences size]; ++i) {
		if ([[myReferences at: i] getCashReferenceId] == aCashReferenceId) 
			return [myReferences at: i];
	}

	return NULL;
}

@end
