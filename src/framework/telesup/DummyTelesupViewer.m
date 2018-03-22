#include "DummyTelesupViewer.h"
#include "log.h"

//#define printd(args...) doLog(0,args)
#define printd(args...) 	

/**/
@implementation DummyTelesupViewer

/**/
- (void) start
{
	[super start];
	printd("DummyTelesupViewer: %s.\n", "Start");
}

/**/
- (void) finish
{
	[super finish];
	printd("DummyTelesupViewer: %s.\n", "Finish");
}

/**/
- (void) startFileTransfer: (char *) aFileName download: (BOOL) aDownload totalBytes: (long) aTotalBytes
{
	[super startFileTransfer: aFileName download: aDownload totalBytes: aTotalBytes];
	printd("DummyTelesupViewer: %s file:%s, size: %ld bytes.\n", aDownload ? "Download" : "Upload",
												aFileName, aTotalBytes);
}

/**/
- (void) updateFileTransfer: (long) aBytesTransfered
{
	[super updateFileTransfer: aBytesTransfered];
	printd("DummyTelesupViewer: Transfered: %ld bytes.\n", aBytesTransfered);
}

/**/
- (void) finishFileTransfer
{
	[super finishFileTransfer];
	printd("DummyTelesupViewer: %s.\n", "FinishFileTransfer");
}

/**/
- (void) updateText: (char *) aText
{
	[super updateText: aText];
	printd("DummyTelesupViewer: %s.\n", aText);
}


@end
