#ifndef PUT_TEXT_MESSAGES_REQUEST_H
#define PUT_TEXT_MESSAGES_REQUEST_H

#define PUT_TEXT_MESSAGES_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "PutFileRequest.h"

/**
 * 	Transfiere mensajes del sistema remoto al sistema local.
 *	Los mensajes vienen en un archivo con un formato determinado (ver especificacion PTSD).
 *
 */
@interface PutTextMessagesRequest: PutFileRequest
{		
}


@end

#endif
