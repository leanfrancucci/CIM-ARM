#include "LCDTelesupViewer.h"
#include "InputKeyboardManager.h"
#include "MessageHandler.h"

@implementation LCDTelesupViewer

/**/
- (void) start
{
	[super start];
	
	telesupForm = [JTelesupViewerForm createForm: NULL];
									
/*	activeForm = [ActiveForm new];
	[activeForm setActiveForm: telesupForm];
	[activeForm start];
	*/
	oldForm = [JWindow getActiveWindow];
	if (oldForm) [oldForm deactivateWindow];
	
	[[InputKeyboardManager getInstance] setIgnoreKeyEvents: TRUE];
	//[myActiveForm showModalForm];
	[telesupForm showForm];
	[telesupForm start];
	//doLog(0,"Mostrando formulario de telesupervision...\n");

}

/**/
- (void) finish
{
	[telesupForm stop];
	[telesupForm closeForm];
	[[InputKeyboardManager getInstance] setIgnoreKeyEvents: FALSE];	
	[telesupForm free];
	if (oldForm) [oldForm activateWindow];

}

/**/
- (void) setTelesupForm: (JTELESUP_VIEWER_FORM) aTelesupForm
{
	telesupForm = aTelesupForm;
}

/**/
- (void) startFileTransfer: (char *) aFileName download: (BOOL) aDownload totalBytes: (long)aTotalBytes
{
	char text[100];
	[super startFileTransfer: aFileName download: aDownload totalBytes: aTotalBytes];

	if (download) {
	  formatResourceStringDef(text, RESID_DOWNLOADING, "Bajando %s", aFileName);
	} else {
		formatResourceStringDef(text, RESID_SENDING, "Enviando %s", aFileName);
	}

	[telesupForm updateDisplay: text];
	[telesupForm updateTransfered: 0 totalBytes: aTotalBytes];
}

/**/
- (void) updateFileTransfer: (long) aBytesTransfered
{
	[super updateFileTransfer: aBytesTransfered];
	[telesupForm updateTransfered: aBytesTransfered totalBytes: totalBytes];
}

/**/
- (void) finishFileTransfer
{
	[super finishFileTransfer];
	[telesupForm updateDisplay: getResourceStringDef(RESID_END_TRANSFER, "Fin de transferencia")];
}

/**/
- (void) updateTitle: (char*) aTitle
{
	[telesupForm updateTitle: aTitle];
}

/**/
- (void) updateText: (char *) aText
{
	[telesupForm updateDisplay: aText];
}

- (void) updateCommand: (int) aCommand
{

}



@end
