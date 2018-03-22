#include "GetFileRequest.h"
#include "assert.h"
#include "system/util/all.h"

/* macro para debugging */
//#define printd(args...) doLog(args)
#define printd(args...)


static GET_FILE_REQUEST mySingleInstance = nil;
static GET_FILE_REQUEST myRestoreSingleInstance = nil;


@implementation GetFileRequest	

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
	return self;
}
/**/
- (void) clearRequest
{	
	mySourceFileName[0] = '\0';
	myTargetFileName[0] = '\0';
}

/**/
- (void) setTargetFileName: (char *) aFileName { 	stringcpy(myTargetFileName, aFileName); }
- (char *) getTargetFileName {	return myTargetFileName; }

/**/
- (void) setSourceFileName: (char *) aFileName { 	stringcpy(mySourceFileName, aFileName); }
- (char *) getSourceFileName { return mySourceFileName; }


/**/
- (void) executeRequest
{
	FILE *f;

	/* controlar si el archivo existe */
	f = fopen(mySourceFileName, "r");	

	if (f)  {
	
		fclose(f);
		[myRemoteProxy sendAckMessage];
		[myRemoteProxy sendFile: mySourceFileName targetFileName: myTargetFileName appendMode: FALSE];

	} else
		THROW( TSUP_FILE_NOT_FOUND_EX );
}



@end



