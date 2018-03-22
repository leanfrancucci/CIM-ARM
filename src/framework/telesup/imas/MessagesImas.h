#ifndef __TELESUP_H__
#define __TELESUP_H__

#include "sysdefs.h"

//#define __PC
#define __CONSOLE
#define __PLACA

/* mensajes de supervision*/
#define BUSY						"BUSY"
#define MSG_ZIP						"ZIP"
#define MSG_NOZIP					"NOZIP"
#define MSG_ALLOW					"ALLOW"
#define MSG_DENIED					"DENIED"
#define MSG_OK						"OK"
#define MSG_SENDALLFILES_ENTER		"SENDALLFILES\xD\xA"
#define MSG_SENDFILE				"SENDFILE"
#define MSG_ENDSENDFILE				"ENDSENDFILE"
#define MSG_ENDSENDFILE_ENTER		"ENDSENDFILE\xD\xA"
#define MSG_MAL						"MAL"
#define MSG_SENDALLFILES			"SENDALLFILES"
#define MSG_ENDSENDALLFILES			"ENDSENDALLFILES"
#define MSG_OK_ENTER				"OK\xD\xA"
#define MSG_ENDSENDALLFILES_ENTER	"ENDSENDALLFILES\xD\xA"
#define MSG_ENDTELESUP				"ENDTELESUP\xD\xA"
#define MSG_GETCONFACTUAL			"GETCONFACTUAL\xD\xA"
#define MSG_CLIENTE					"CLIENTE"
#define MSG_NO_PREPAGO				"NO PREPAGO"
#define MSG_PREPAGO					"PREPAGO"
#define MSG_CT8016					"CT8016"

/*modos de finalizacion de la telesupervision*/
#define ERROR_TELESUP	0
#define TELESUP_OK		1

#define BUFFER_RX_SIZE 20000

#endif
