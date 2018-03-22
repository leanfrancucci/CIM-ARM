#include <assert.h>
#include "UtilExcepts.h"
#include "Collection.h"
#include "ordcltn.h"
#include "log.h"

@implementation Collection

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{	
	myCollection = [OrdCltn new];
	assert(myCollection != NULL);
	return self;
}

/**/
- free
{
	[myCollection free];
	return [super free];
}

/**/
- freeContents
{
	assert(myCollection != NULL);	
	return [myCollection freeContents];	
}

/**/
- freePointers
{
	int i;
	int count = [myCollection size];

	for (i = 0; i < count; i++) {
		free((void*)[myCollection firstElement]);
		[myCollection removeFirst];
	}

	return self;
}

/**/
- (unsigned) size
{
	assert(myCollection != NULL);
	return [myCollection size];
}

/**/
- (BOOL) isEmpty
{
	assert(myCollection != NULL);
	return [myCollection isEmpty];
}

/**/ 
- firstElement
{
	assert(myCollection != NULL);
	return [myCollection firstElement];
}

/**/ 
- lastElement
{
	assert(myCollection != NULL);
	return [myCollection lastElement];
}

/**/
- (BOOL) isEqual: (id) aCltn
{
	assert(myCollection != NULL);
	return [myCollection isEqual: aCltn];
}

/**/
- add: (id) anObject
{
	assert(myCollection != NULL);
	return [myCollection add: anObject];
}

/**/ 
- addFirst: (id) newObject
{
	assert(myCollection != NULL);
	return [myCollection addFirst: newObject];
}

/**/
- addLast: (id) newObject
{
	assert(myCollection != NULL);
	return [myCollection addLast: newObject];
}

/**/ 
- at: (unsigned) anOffset
{
	assert(myCollection != NULL);
	
	if (anOffset >= [myCollection size])
		THROW( COL_OUT_OF_BOUNDS_EX );
	
	return [myCollection at: anOffset];
}

/**/
- at: (unsigned) anOffset put: (id) anObject
{
	assert(myCollection != NULL);
	
	if (anOffset >= [myCollection size])
		THROW( COL_OUT_OF_BOUNDS_EX );	
	
	return [myCollection at: anOffset put: anObject];
}

/**/
- at: (unsigned) anOffset insert: (id) anObject
{
	assert(myCollection != NULL);
	
	if (anOffset > [myCollection size])
		THROW( COL_OUT_OF_BOUNDS_EX );	

	return [myCollection at: anOffset insert: anObject];
}

/**/ 
- removeFirst
{
	assert(myCollection != NULL);
	return [myCollection removeFirst];
}

/**/
- removeLast
{
	assert(myCollection != NULL);
	return [myCollection removeLast];
}

/**/ 
- removeAt: (unsigned) anOffset
{
	assert(myCollection != NULL);
	
	if (anOffset >= [myCollection size])
		THROW( COL_OUT_OF_BOUNDS_EX );
			
	return [myCollection removeAt: anOffset];
}

/**/
- remove: (id) oldObject
{
	assert(myCollection != NULL);
	return [myCollection remove: oldObject];
}

/**/
- removeAll
{
	int i, count;

	count = [self size];

	for (i = 0; i < count; ++i)
		[self removeFirst];

	return self;

}


/**/
- find: (id) anObject
{
	assert(myCollection != NULL);
	return [myCollection find: anObject];
}

/**/
- findMatching: (id) anObject
{
	assert(myCollection != NULL);
	return [myCollection findMatching: anObject];
}

/**/
- (BOOL) includes: (id) anObject
{
	assert(myCollection != NULL);

#ifndef __UCLINUX
	// EL INCLUDE DE OBJECTIVE-C ESTA AL REVES DE LO QUE DEBERIA SER
	return ![myCollection includes: anObject];
#else
	return [myCollection includes: anObject];
#endif

}

/**/
- findSTR: (STR) aString
{
	assert(myCollection != NULL);
	return [myCollection findSTR: aString];
}

/**/
- (BOOL) contains: (id) anObject
{
	assert(myCollection != NULL);
	return [myCollection contains: anObject];
}

/**/
- (unsigned) offsetOf: (id) anObject
{
	assert(myCollection != NULL);
	return [myCollection offsetOf: anObject];
}

/**/
- (COLLECTION) clone
{
  COLLECTION newList = [Collection new];
  int i;

  for (i = 0; i < [self size]; ++i) {

    TRY

      [newList add: [self at: i]];

    CATCH

    //  doLog(0,"Collection -> clone\n");
      ex_printfmt();

    END_TRY

  }

  return newList;
}

@end
