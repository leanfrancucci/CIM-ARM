#ifndef TELESUP_CONTROLLER_H
#define TELESUP_CONTROLLER_H

#define TELESUP_CONTROLLER id

#include <Object.h>
#include "system/util/all.h"
#include "CimDefs.h"
#include "TelesupViewer.h"
#include "AsyncMsgThread.h""


/**
 *	Es el controller para efectuar una extraccion / apertura de puerta
 *	Maneja adicionalmente la apertura de una puerta interna.
 */
@interface TelesupController : Object
{
    long bytesTransfered;
    int telesupId;
}

/**/

- (void) startManualTelesup;

- (void) setTelesupId: (int) aTelesupId;
- (void) start;
- (void) finish;
- (void) startFileTransfer: (char *) aFileName download: (BOOL) aDownload totalBytes: (long)aTotalBytes;
- (void) updateFileTransfer: (long) aBytesTransfered;
- (void) finishFileTransfer;
- (void) updateText: (char *) aText;
- (void) updateTitle: (char *) aText;
- (void) informEvent: (TelesupEventType) anEventType;
- (void) informEvent: (TelesupEventType) anEventType name: (char*) aName;
- (void) informError: (int) anErrorCode;



- (void) acceptCMPSupervision: (BOOL) aValue;



@end

#endif
