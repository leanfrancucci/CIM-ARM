#ifndef SIM_CARD_VALIDATOR_H
#define SIM_CARD_VALIDATOR_H

#define SIM_CARD_VALIDATOR id

#include <Object.h>
#include "ctapp.h"
#include "system/os/all.h"
#include "system/io/all.h"
#include "system/dev/all.h"
#include "system/util/all.h"

typedef enum {
	 SimCardStatus_READY
	,SimCardStatus_NOT_INSERTED
	,SimCardStatus_PIN_REQUIRED
	,SimCardStatus_PUK_REQUIRED
	,SimCardStatus_FAILURE
	,SimCardStatus_ERROR
	,SimCardStatus_BLOCKED
} SimCardStatus;

/**
 *
 */
@interface SimCardValidator : Object
{
	COM_PORT myComPort;
	DATA_READER myReader;
	DATA_WRITER myWriter;
	int myPortNumber;
	int myConnectionSpeed;
	BOOL myIsSimCardLocked;
	char myPin[9];
}

+ getInstance;

/**
 *  Configura el puerto COM asociado
 */
- (void) setPortNumber: (int) aValue;
- (void) setConnectionSpeed: (int) aValue;

/**/
- (BOOL) openSimCard;

/**/
- (void) close;

/**/
- (BOOL) isSimCardLocked;

/**/
- (SimCardStatus) checkSimCard: (char *) aPin;

/**/
- (BOOL) enterPuk: (char *) aPuk newPin: (char *) aNewPin;

/**/
- (BOOL) lockSimCard: (BOOL) aLock pin: (char *) aPin;

/**/
- (BOOL) changeSimCardPin: (char *) anOldPin newPin: (char *) aNewPin;

@end

#endif
