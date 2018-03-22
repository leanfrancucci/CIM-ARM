#include "EnvelopeAcceptor.h"
#include "Audit.h"
#include "SafeBoxHAL.h"
#include "CimEventDispatcher.h"
#include "MessageHandler.h"
#include "CimManager.h"
#include "POSEventAcceptor.h"

//#define LOG(args...) doLog(0,args)

@implementation EnvelopeAcceptor


/**/
- (void) initAcceptor
{
	int stackerSensorHardwareId = -1;
	int i;
	COLLECTION doors;

	myStackerSensorStatus = DoorPlungerSensorStatus_UNDEFINED;

	//Si no es Prosegur
	if (![[[CimManager getInstance] getCim] isTransferenceBoxMode]) {
		myStackerSensorStatus = StackerSensorStatus_INSTALLED;
		return;
	}

	// si es Prosegur toma el plungerid para controlar la bolsa del buzon
	doors = [[[CimManager getInstance] getCim] getDoors];

	for (i = 0; i < [doors size]; ++i) {
		if ([[doors at: i] isDeleted]) {
			stackerSensorHardwareId = [[doors at: i] getPlungerHardwareId];
			break;
		}
	}

	// Registra el sensor de stacker para recibir sus eventos
	if (stackerSensorHardwareId != -1) {
		[[CimEventDispatcher getInstance] registerDevice: stackerSensorHardwareId
			deviceType: DeviceType_STACKER_SENSOR 
			object: self];
	}
	
}

/**/
- (void) open 
{
			    //************************* logcoment
	//doLog(0,"EnvelopeAcceptor -> open\n");
}

/**/
- (void) close
{
				    //************************* logcoment
    //doLog(0,"EnvelopeAcceptor -> close\n");
}

/**/
- (StackerSensorStatus) getStackerSensorStatus
{
	//doLog(0,"EnvelopeAcceptor - StackerSensorStatus = %d\n", myStackerSensorStatus);
	return myStackerSensorStatus;
}

/**/
- (void) stackerSensorStatusChange: (DoorPlungerSensorStatus) anStatus
{
	StackerSensorStatus status = StackerSensorStatus_UNDEFINED;

	// El sensor de la bolsa se comporta de la misma manera al stacker del validador
	// La unica diferencia es que ahora tengo por un lado el estado del validador y 
	// por otro el estado de la bolsa pero lo integro como si fuera una sola cosa

	if (anStatus == DoorPlungerSensorStatus_OPEN) status = StackerSensorStatus_REMOVED;
	if (anStatus == DoorPlungerSensorStatus_CLOSE) status = StackerSensorStatus_INSTALLED;
	
	// Si estaba removido y ahora lo colocaron entonces genero una auditoria
	if (myStackerSensorStatus == StackerSensorStatus_REMOVED && anStatus == StackerSensorStatus_INSTALLED) {
		[Audit auditEventCurrentUser: Event_STACKER_OK additional: [myAcceptorSettings getAcceptorName] station: [myAcceptorSettings getAcceptorId] 
				logRemoteSystem: FALSE];
	}

	myStackerSensorStatus = status;

	// me fijo si debo informar al POS del evento.
	/*if ([[POSEventAcceptor getInstance] isTelesupRunning]) {
		if (anStatus == StackerSensorStatus_REMOVED)
			[[POSEventAcceptor getInstance] cassetteRemovedEvent: [myAcceptorSettings getAcceptorId] acceptorName: [myAcceptorSettings getAcceptorName]];

		if (anStatus == StackerSensorStatus_INSTALLED)
			[[POSEventAcceptor getInstance] cassetteInstalledEvent: [myAcceptorSettings getAcceptorId] acceptorName: [myAcceptorSettings getAcceptorName]];
	}*/

	// Si la bolsa esta removida informo un error de STACKER_OPEN
	if (status == StackerSensorStatus_REMOVED) {
		if (myObserver) [myObserver onAcceptorError: self cause: BillAcceptorStatus_STACKER_OPEN];

		[Audit auditEventCurrentUser: Event_STACKER_OUT additional: [myAcceptorSettings getAcceptorName] station: [myAcceptorSettings getAcceptorId] logRemoteSystem: FALSE];

	}

}


/**/
- (char *) getErrorDescription: (int) aCode
{

	if (aCode == BillAcceptorStatus_STACKER_OPEN) 
 		return getResourceStringDef(RESID_STACKER_OPEN,  "Stacker open");

	return NULL;
}



@end
