#include "assert.h"
#include "GetUserRequest.h"
#include "system/util/all.h"
#include "Persistence.h"
#include "TransferInfoFacade.h"
#include "TelesupFacade.h"
#include "Audit.h"
#include "Persistence.h"
#include "UserManager.h"


// 1500 usuarios
#define MAX_USER_FILE_SIZE 169500

static GET_USER_REQUEST mySingleInstance = nil;
static GET_USER_REQUEST myRestoreSingleInstance = nil;

/**/
@implementation GetUserRequest

/**/
+ getSingleVarInstance { return mySingleInstance; };
+ (void) setSingleVarInstance: (id) aSingleVarInstance { mySingleInstance =  aSingleVarInstance; };

/**/
+ getRestoreVarInstance { return myRestoreSingleInstance; };
+ (void) setRestoreVarInstance: (id) aRestoreVarInstance { myRestoreSingleInstance = aRestoreVarInstance; };

/**/
- initialize
{
	[super initialize];
	[self setReqType: GET_ALL_USER_REQ];
	myUserId = 0;
	return self;
}

/**/
- (void) clearRequest
{
	[super clearRequest];
}

/**/
- (void) setUserId: (int) aUserId
{
	myUserId = aUserId;
}

/**/
- (void) generateRequestDataFile
{
	COLLECTION users = NULL;
	int n, i;
	unsigned long fileSize = 0;

	assert(myInfoFormatter);

	if (myUserId == 0)
		users = [[UserManager getInstance] getUsersCompleteList];
	else
		users = [[UserManager getInstance] getUsersWithChildren: myUserId];

	// Verifica que la lista no este vacia.
	if ([users size] == 0) return;

	for (i=0; i<[users size]; i++) {

		// Formateo el usuario
		n = [myInfoFormatter formatUser: myBuffer user: [users at: i]];

		// Escribe el usuario
		if (n != 0) {
			if ([self writeToRequestDataFile: myBuffer size: n] <= 0)
				THROW( TSUP_GENERAL_EX );

			fileSize += n;

			// si llego al maximo permitido corta
			if ([self reachMaxFileSize: fileSize maxFileSize: MAX_USER_FILE_SIZE]) 
				break;
		}
	}

}

/**/
- (void) endRequestDataFile
{

}


@end
