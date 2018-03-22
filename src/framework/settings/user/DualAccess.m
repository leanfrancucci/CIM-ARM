#include "DualAccess.h"
#include "Persistence.h"
#include "util.h"
#include "UserManager.h"
#include "objpak.h"
#include "integer.h"
#include "MessageHandler.h"
#include "Collection.h"

@implementation DualAccess

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myProfile1Id = 0;
	myProfile2Id = 0;
	myDeleted = FALSE;
	return self;
}

/**/
- (void) setProfile1Id: (int) aValue { myProfile1Id = aValue; }
- (void) setProfile2Id: (int) aValue { myProfile2Id = aValue; }
- (void) setDeleted: (BOOL) aValue { myDeleted = aValue; }

/**/

- (int) getProfile1Id { return myProfile1Id; }
- (int) getProfile2Id { return myProfile2Id; }
- (BOOL) isDeleted { return myDeleted; }


/**/
- (STR) str
{
	
	myDescription[0] = '\0';
	
	if ([self getProfile1Id] > 0){
  	strcpy(myDescription, [[[UserManager getInstance] getProfile: [self getProfile1Id]] getProfileName]);
  	strcat(myDescription, "|");
  	strcat(myDescription, [[[UserManager getInstance] getProfile: [self getProfile2Id]] getProfileName]);
	}
	
  return myDescription;
}

/**/
- (void) applyChanges
{
}

/**/
- (void) restore
{
}

@end
