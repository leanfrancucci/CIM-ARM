#ifndef  JEVENT_QUEUE_H
#define  JEVENT_QUEUE_H

#include <objpak.h>

#include "system/os/all.h"
#include "queue.h"

#define  JEVENT_QUEUE  id

#define  MAX_JEVENTS		256

typedef enum
{
	 
	 JEventQueueMessage_NONE = 0
	,JEventQueueMessage_CLOSE
	,JEventQueueMessage_PAINT	  
	,JEventQueueMessage_KEY_PRESSED	
	
	,JEventQueueMessage_LOGOUT_APPLICATION
	,JEventQueueMessage_LOGIN_APPLICATION
	,JEventQueueMessage_CLOSE_APPLICATION
	,JEventQueueMessage_ACTIVATE_MAIN_APPLICATION_FORM
	,JEventQueueMessage_ACTIVATE_NEXT_APPLICATION_FORM
	,JEventQueueMessage_PRINTER_STATE
  ,JEventQueueMessage_SHOW_ALARM
	
} JEventQueueMessage;


/* el evento de tecla presionada */
typedef struct 
{
	int  keyPressed;
	int  isPressed;
		
} JEventKeyPressed;
	
/*
	evt.evtid = JEventMessage_KEY_PRESSED;	
	evt.event.keyEvt.keyPressed = aKey;
	evt.event.keyEvt.isPressed = isPressed;
	[myEventQueue putUEvent: &evt];
*/
	
/**
 * La estructura general para gstionar eventos de interface de usuario 
 */
typedef struct 
{
	int		evtid;
  int   evtParam1;
  
	union 
	{
		JEventKeyPressed	 keyEvt;
		void 							*data;
	} event;	
	
} JEvent;


/**
 *  
 */
@interface  JEventQueue: Object 
{
	OSEMAPHORE 		mySem;
	OMUTEX 				myMutex;
	Queue 				*myEventQueue;
	int				myMessageCount;
}

/**/
+ new;

/**/
+ getInstance;

/**/
+ initialize;

/**/
- free;

/**
 * Devuelve la cantidad de mensajes que actualmente hay en la cola.
 */
- (int) getMessageCount;

/**
 * Agrega un evento a la cola de eventos.
 * Copia internamente el contenido del evento. 
 */
- (void) putJEvent: (JEvent *) anEvent;
 
/**
 * Extrae un evento de la cola de eventos y lo copia en @param anEvent.
 * @result devuelve el evento pasado por argumento.
 */
- (JEvent *) getJEvent: (JEvent *) anEvent;


@end

#endif

