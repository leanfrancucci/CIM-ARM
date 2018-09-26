#include <stdio.h>
#include <stdlib.h>
#include "TelesupController.h"
#include "log.h"
#include "UICimUtils.h"


@implementation TelesupController

static TELESUP_CONTROLLER singleInstance = NULL;


+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}

+ getInstance
{
    return [self new];
}

/**/
- initialize
{
	[super initialize];
	return self;
    
    
}   

/**/
- (void) setTelesupId: (int) aTelesupId
{
	telesupId = aTelesupId;
}

/**/
- (void) start
{
}

/**/
- (void) finish
{
}

/**/
- (void) startFileTransfer: (char *) aFileName download: (BOOL) aDownload totalBytes: (long)aTotalBytes
{
	//strcpy(currentFile, aFileName);
	//download = aDownload;
	//totalBytes = aTotalBytes;
	bytesTransfered = 0;
	//fileTransferInProgress = TRUE;
}

/**/
- (void) updateFileTransfer: (long) aBytesTransfered
{
	bytesTransfered = aBytesTransfered;
}

/**/
- (void) finishFileTransfer
{

}

/**/
- (void) updateText: (char *) aText
{
	aText = aText;
}

/**/
- (void) updateTitle: (char *) aText
{
}

/**/
- (void) informEvent: (TelesupEventType) anEventType name: (char*) aName
{
}

/**/
- (void) informEvent: (TelesupEventType) anEventType
{

}

/**/
- (void) informError: (int) anErrorCode
{
}

@end
