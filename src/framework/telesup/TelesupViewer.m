#include "TelesupViewer.h"

@implementation TelesupViewer

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	fileTransferInProgress = FALSE;;
	download = FALSE;
	strcpy(currentFile, "");
	totalBytes = 0;
	bytesTransfered = 0;
	telesupId = 0;
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
	strcpy(currentFile, aFileName);
	download = aDownload;
	totalBytes = aTotalBytes;
	bytesTransfered = 0;
	fileTransferInProgress = TRUE;
}

/**/
- (void) updateFileTransfer: (long) aBytesTransfered
{
	bytesTransfered = aBytesTransfered;
}

/**/
- (void) finishFileTransfer
{
	fileTransferInProgress = FALSE;
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
