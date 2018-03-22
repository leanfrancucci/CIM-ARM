#ifndef CIM_EVENT_DISPATCHER_H
#define CIM_EVENT_DISPATCHER_H

#define CIM_EVENT_DISPATCHER id

#include <Object.h>
#include "system/os/all.h"
#include "system/util/all.h"
#include "SafeBoxHAL.h"

/**
 *	Hilo que procesa eventos provenientes del SafeBox y los despacha al objeto apropiado segun 
 *	el tipo de dispositivo y tipo de evento del cual se trate.
 */
@interface CimEventDispatcher : OThread
{
	STATIC_SYNC_QUEUE mySyncQueue;
	COLLECTION myDevices;
}

/** Devuelve la unica instancia posible de esta clase */
+ getInstance;

/**
 *	Registra el dispositivo para capturar eventos.
 *	@param hardwareId identificador de hardware del dispositivo.
 *	@param deviceType tipo de dispositivo.
 *	@param object objecto al que se le notificaron los eventos del dispositivo.
 */
- (void) registerDevice: (int) aHardwareId deviceType: (DeviceType) aDeviceType object: (id) anObject;
- (void) registerDevice: (int) aHardwareId deviceType: (DeviceType) aDeviceType object: (id) anObject external: (BOOL) aExternal;

- (void) addEvent: (CimEvent*) aCimEvent;

/**
 *	Configura la cola desde donde se obtendran los eventos.
 */
- (void) setEventQueue: (STATIC_SYNC_QUEUE) aSyncQueue;

@end

#endif
