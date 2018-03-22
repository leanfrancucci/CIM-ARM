#include "CimEventDispatcher.h"
#include "Audit.h"

/**/
typedef struct {
	int hardwareId;
	DeviceType deviceType;
	id  object;
} CimDevice;

@implementation CimEventDispatcher

static CIM_EVENT_DISPATCHER singleInstance = NULL; 

- (void) billAccepted: (money_t) anAmount currencyId: (int) aCurrencyId qty: (int) aQty { }
- (void) billRejected: (int) aCause qty: (int) aQty { }
- (void) billAccepting { }
- (void) communicationError: (int) aCause { }
- (void) statusChange: (int) newStatus { }
- (void) onDoorOpen {}
- (void) onDoorClose {}
- (void) onLocked {}
- (void) onUnLocked {}
- (void) onPowerStatusChange: (PowerStatus) aNewStatus { }
- (void) onBatteryStatusChange: (BatteryStatus) aNewStatus { }
- (void) onHardwareSystemStatusChange: (HardwareSystemStatus) aNewStatus { }
- (void) stackerSensorStatusChange: (int) anStatus { }

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}
 
/**/
- initialize
{
//	mySyncQueue = [[StaticSyncQueue new] initWithSize: sizeof(CimEvent) count: 100];
	mySyncQueue = NULL;
	myDevices = [Collection new];
	return self;
}

/**/
- (void) setEventQueue: (STATIC_SYNC_QUEUE) aSyncQueue
{
	mySyncQueue = aSyncQueue;
}

/**/
+ getInstance
{
  return [self new];
}

/**/
- (CimDevice *) getCimDevice: (int) aHardwareId
{
	int i;
	
	for (i = 0; i < [myDevices size]; ++i) {
		if (((CimDevice*)[myDevices at: i])->hardwareId == aHardwareId) 
			return (CimDevice *)[myDevices at: i];
	}

	return NULL;

}
/**/
- (void) registerDevice: (int) aHardwareId deviceType: (DeviceType) aDeviceType object: (id) anObject external: (BOOL) aExternal
{
	CimDevice *device;

	device = malloc(sizeof(CimDevice));

	device->hardwareId = aHardwareId;
	device->deviceType = aDeviceType;
	device->object = anObject;

	[myDevices add: device];

  // Si es un dispositivo externo no se maneja por el safebox, si es interno si
	if (!aExternal) [SafeBoxHAL addDevice: aHardwareId deviceType: aDeviceType object: anObject];

}

/**/
- (void) registerDevice: (int) aHardwareId deviceType: (DeviceType) aDeviceType object: (id) anObject
{
	[self registerDevice: aHardwareId deviceType: aDeviceType object: anObject external: FALSE];
}

/**/
- (void) addEvent: (CimEvent*) aCimEvent
{
  [mySyncQueue pushElement: aCimEvent];
}


/**/
- (void) run
{
	CimEvent cimEvent;
	CimDevice *cimDevice;
	char additional[20];
    int sensorType;
    unsigned long ticks = getTicks();
    
	threadSetPriority(-18);

	//[SafeBoxHAL setEventQueue: mySyncQueue];

    
	assert(mySyncQueue);

    

    
    
	while (TRUE) {
	
		TRY

                
			[mySyncQueue popBuffer: &cimEvent];
            
			cimDevice = [self getCimDevice: cimEvent.hardwareId];

			if (cimDevice == NULL) {
                    ;
    //************************* logcoment
//				doLog(0,"CimEventDispatcher -> no existe ningun dispositivo %d mapeado\n", cimEvent.hardwareId);
			}
	
			// Eventos del plunger
			else if (cimDevice->deviceType == DeviceType_PLUNGER) {
	
				// si el tipo de sensor en la puerta esta configurado como plunger o ambos envia
				// el evento sino lo ignora.
				if (([cimDevice->object getSensorType] == SensorType_PLUNGER) ||
				   ([cimDevice->object getSensorType] == SensorType_PLUNGER_EXT) ||
					 ([cimDevice->object getSensorType] == SensorType_BOTH)) {

					if (cimEvent.status == 0) {
						[cimDevice->object onDoorOpen];
						[cimDevice->object setDoorState: DoorState_OPEN];
					}
					else 
						if (cimEvent.status == 1) {
							[cimDevice->object onDoorClose];
							[cimDevice->object setDoorState: DoorState_CLOSE];
							if (([cimDevice->object getSensorType] == SensorType_PLUNGER) ||
								([cimDevice->object getSensorType] == SensorType_PLUNGER_EXT))
								[cimDevice->object onLocked];							
						}
				}

			}
		
			// Eventos del validador
			else if (cimDevice->deviceType == DeviceType_VALIDATOR) {
	     
				if (cimEvent.event == CimEvent_BILL_ACCEPTING) {
					[cimDevice->object billAccepting];
				} else if (cimEvent.event == CimEvent_BILL_ACCEPTED) {
					[cimDevice->object billAccepted: cimEvent.amount currencyId: cimEvent.currencyId qty: cimEvent.qty];
				}	else if (cimEvent.event == CimEvent_BILL_REJECTED) {
					[cimDevice->object billRejected: cimEvent.status qty: cimEvent.qty];
				} else if (cimEvent.event == CimEvent_ACCEPTOR_ERROR) {
					[cimDevice->object communicationError: cimEvent.status];
				} else if (cimEvent.event == CimEvent_STATUS_CHANGE) {
					[cimDevice->object statusChange: cimEvent.status];
				}
            
			}

			// Eventos del locker 
			else if (cimDevice->deviceType == DeviceType_LOCKER) {
                
                printf("deviceType = DeviceType_LOCKER\n");

				// si esta configurado el tipo de sensor como locker utiliza los cambios
				// para la apertura y cierre de puerta.
				if ([cimDevice->object getSensorType] == SensorType_LOCKER) {
					if (cimEvent.status == 0) {
						[cimDevice->object onDoorClose];
						[cimDevice->object onLocked];
						[cimDevice->object setLockState: LockState_LOCK];
					}
					else if (cimEvent.status == 1) {
						[cimDevice->object onDoorOpen];
						[cimDevice->object setLockState: LockState_UNLOCK];
					}
				}

				// si esta configurado el tipo de sensor como ambos utiliza los cambios
				// normalmente
				if ([cimDevice->object getSensorType] == SensorType_BOTH) {
					if (cimEvent.status == 0) {
						[cimDevice->object onLocked];
						[cimDevice->object setLockState: LockState_LOCK];
					}
					else if (cimEvent.status == 1) {
						[cimDevice->object onUnLocked];
						[cimDevice->object setLockState: LockState_UNLOCK];
					}
				}

			}
	
			// Power Status
			else if (cimDevice->deviceType == DeviceType_POWER) {
				[cimDevice->object onPowerStatusChange: cimEvent.status];
			}
		
			// Battery
			else if (cimDevice->deviceType == DeviceType_BATTERY) {
				[cimDevice->object onBatteryStatusChange: cimEvent.status];
			}
		
			// Hardware system
			else if (cimDevice->deviceType == DeviceType_HARDWARE_SYSTEM) {
				[cimDevice->object onHardwareSystemStatusChange: cimEvent.status];
			}

			// Stacker Sensor
			else if (cimDevice->deviceType == DeviceType_STACKER_SENSOR) {
				[cimDevice->object stackerSensorStatusChange: cimEvent.status];
			}

			// Stacker Sensor
			else if (cimDevice->deviceType == DeviceType_LOCKER_ERROR_STATUS) {
				[cimDevice->object lockerErrorStatusChange: cimEvent.hardwareId newStatus: cimEvent.status];
			}

		CATCH

			printf("Se ha encontrado un error en hilo de procesamiento de eventos...se continuara con las operaciones\n");
            printf("\n>>>> Tiempo transcurrido = %ld\n", getTicks() - ticks);
			ex_printfmt();
			
			//sprintf(additional, "%d", ex_get_code());
			//[Audit auditEventCurrentUser: Event_NOT_RECOGNIZED_EXCEPTION 
			//	additional: additional station: cimEvent.hardwareId logRemoteSystem: FALSE];
			
		END_TRY

	}

}


@end
