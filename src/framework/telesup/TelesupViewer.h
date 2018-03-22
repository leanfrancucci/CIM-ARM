#ifndef TELESUP_VIEWER_H
#define TELESUP_VIEWER_H

#define TELESUP_VIEWER id

#include <Object.h>
#include "ctapp.h"

/**
 *	Eventos de la supervision
 */
typedef enum {
	 TelesupEventType_START_TELESUP = 1
	,TelesupEventType_CONNECT
	,TelesupEventType_DISCONNECT
	,TelesupEventType_END_TELESUP
	,TelesupEventType_ERROR
	,TelesupEventType_BEGIN_RX_FILE
	,TelesupEventType_END_RX_FILE
	,TelesupEventType_BEGIN_TX_FILE
	,TelesupEventType_END_TX_FILE
	,TelesupEventType_APPLY_CONFIGURATION
	,TelesupEventType_FILE_GENERATION
} TelesupEventType;

/**
 *	Es una clase que se encarga de actualizar el progreso de la Telesupervision.
 *	El framework de supervision va llamando a este objeto para informar de los pasos que va ejecutando.
 *	La supervision no conoce directamente al TelesupViewer, esto seria una especie de interfaz,
 *	pero a falta de interfaz en Objective-C se implementa directamente en una clase simple.
 *
 *	<<abstract>>
 */
@interface TelesupViewer : Object
{
	BOOL fileTransferInProgress;
	BOOL download;
	char currentFile[255];
	long totalBytes;
	long bytesTransfered;
	int  telesupId;
}

/**/
- (void) setTelesupId: (int) aTelesupId;

/**/
- (void) start;

/**/
- (void) finish;

/**/
- (void) startFileTransfer: (char *) aFileName download: (BOOL) aDownload totalBytes: (long)aTotalBytes;

/**/
- (void) updateFileTransfer: (long) aBytesTransfered;

/**/
- (void) finishFileTransfer;

/**/
- (void) updateText: (char *) aText;

/**/
- (void) updateTitle: (char *) aText;

/**/
- (void) informEvent: (TelesupEventType) anEventType;
- (void) informEvent: (TelesupEventType) anEventType name: (char*) aName;

/**/
- (void) informError: (int) anErrorCode;

@end

#endif
