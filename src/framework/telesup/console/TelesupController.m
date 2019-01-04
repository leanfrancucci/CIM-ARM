#include <stdio.h>
#include <stdlib.h>
#include "TelesupController.h"
#include "log.h"
#include "UICimUtils.h"
#include "TelesupervisionManager.h"
#include "TelesupScheduler.h"
#include "Acceptor.h"

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
- (void) startManualTelesup
{
        
    id telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];

    if (telesup == NULL) THROW(TSUP_PIMS_SUPERVISION_NOT_DEFINED);
    
    [[TelesupScheduler getInstance] isManual: TRUE];
    [[TelesupScheduler getInstance] startTelesup: telesup getCurrentSettings: FALSE telesupViewer: self];

}

/**/
- (void) setTelesupId: (int) aTelesupId
{
	telesupId = aTelesupId;
}

/**/
- (void) start
{
    [[AsyncMsgThread getInstance] addAsyncMsg: "1000" description: "Comienza la supervision" isBlocking: TRUE];
}

/**/
- (void) finish
{
    [[AsyncMsgThread getInstance] addAsyncMsg: "-1" description: "Finaliza la supervision" isBlocking: FALSE];
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
    [[AsyncMsgThread getInstance] addAsyncMsg: "1000" description: aText isBlocking: TRUE];
}

/**/
- (void) updateTitle: (char *) aText
{
    [[AsyncMsgThread getInstance] addAsyncMsg: "1000" description: aText isBlocking: TRUE];
}

/**/
- (void) informEvent: (TelesupEventType) anEventType name: (char*) aName
{
    [[AsyncMsgThread getInstance] addAsyncMsg: "1000" description: aName isBlocking: TRUE];
}

/**/
- (void) informEvent: (TelesupEventType) anEventType
{

}

/**/
- (void) informError: (int) anErrorCode
{
    //[[AsyncMsgThread getInstance] addAsyncMsg: "1000" description: aText isBlocking: TRUE];
}



/**/
- (void) acceptCMPSupervision: (BOOL) aValue
{    

    [[Acceptor getInstance] acceptIncomingSupervision: aValue];	 
    [[Acceptor getInstance] setFormObserver: self];
}


/**/
- (void) startIncomingTelesup
{
    char auxStr[10];
    
    sprintf(auxStr,"%d",AsyncMsgCode_StartIncomingSupervision);
    
    [[AsyncMsgThread getInstance] addAsyncMsg: auxStr description: "Comienzo supervision entrante" isBlocking: TRUE];
    
    
}

/**/
- (void) finishIncomingTelesup
{
    char auxStr[10];
    
    sprintf(auxStr,"%d",AsyncMsgCode_FinishIncomingSupervision);
    
    [[AsyncMsgThread getInstance] addAsyncMsg: auxStr description: "Finaliza supervision entrante" isBlocking: FALSE];
    
    [[Acceptor getInstance] acceptIncomingSupervision: FALSE];	
}


@end
