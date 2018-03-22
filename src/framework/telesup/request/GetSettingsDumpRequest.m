#include "assert.h"
#include "system/util/all.h"
#include "GetSettingsDumpRequest.h"
#include "CimBackup.h"

/* macro para debugging */
//#define printd(args...) doLog(args)
#define printd(args...)


static GET_SETTINGS_DUMP_REQUEST mySingleInstance = nil;
static GET_SETTINGS_DUMP_REQUEST myRestoreSingleInstance = nil;


@implementation GetSettingsDumpRequest	

/**/
+ getSingleVarInstance
{
	 return mySingleInstance; 
};
+ (void) setSingleVarInstance: (id) aSingleVarInstance
{
	 mySingleInstance =  aSingleVarInstance;
};

/**/
+ getRestoreVarInstance 
{
	 return myRestoreSingleInstance; 
};
+ (void) setRestoreVarInstance: (id) aRestoreVarInstance
{
	 myRestoreSingleInstance = aRestoreVarInstance; 
};

/**/
- initialize
{
	[super initialize];
	[self setReqType: GET_FILE_REQ];
	strcpy(mySourceFileName, BASE_VAR_PATH "/data.tar");
	strcpy(myTargetFileName, "data.tar");
	return self;
}

/**/
- (void) beginRequest
{
	[[CimBackup getInstance] dumpTables];
}



@end



