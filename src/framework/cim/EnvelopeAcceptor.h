#ifndef ENVELOPE_ACCEPTOR_H
#define ENVELOPE_ACCEPTOR_H

#define ENVELOPE_ACCEPTOR id

#include "AbstractAcceptor.h"

typedef enum {
 	DoorPlungerSensorStatus_OPEN
 ,DoorPlungerSensorStatus_CLOSE
 ,DoorPlungerSensorStatus_UNDEFINED
} DoorPlungerSensorStatus;

/**
 * 
 */
@interface EnvelopeAcceptor :  AbstractAcceptor
{
	StackerSensorStatus myStackerSensorStatus;
}

/**/
- (StackerSensorStatus) getStackerSensorStatus;
- (void) stackerSensorStatusChange: (DoorPlungerSensorStatus) anStatus;



@end

#endif

