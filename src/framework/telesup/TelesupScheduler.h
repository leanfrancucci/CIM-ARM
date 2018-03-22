#ifndef TELESUP_SCHEDULER_H
#define TELESUP_SCHEDULER_H

#define TELESUP_SCHEDULER id

#include <Object.h>
#include "ctapp.h"
#include "system/os/all.h"
#include "TelesupViewer.h"
#include "TelesupSettings.h"
#include "TelesupDefs.h"
#include "OMutex.h"


/**
 *	Scheduler de supervision.
 *	Es un hilo que va chequeando cada x cantidad de tiempo si debe realizar una
 *	supervision y esta en condiciones de hacerlo, la realiza.
 *
 *	<<thread>>
 */
@interface TelesupScheduler : OThread
{
	TELESUP_VIEWER telesupViewer;
	int randMinutes;
	BOOL inTelesup;
	BOOL firstTelesup;
	BOOL myStartTelesupInBackground;
	id currentTelesup;
	CommunicationIntention myCommunicationIntention;
	//@@todo esta aca por una cuestion de prueba, en realidad habria que tener un manejador de ordenes de reparacion
	id myRepairOrder;
	char myErrorInTelesupMsg[100];
	BOOL myShutdownApp; // indica si al finalizar la supervision se debe reiniciar la applicacion
	BOOL myIsManual; // indica si la supervision es lanzada manualmente.
	BOOL myIsSchedule; // indica si la supervision es programada.
	BOOL myIsInBackground; // indica si la supervision es en background

	COLLECTION myBackgTelesupList;
	OMUTEX myMutex;
}

+ getInstance;
- (void) setTelesupViewer: (TELESUP_VIEWER) aTelesupViewer;
- (void) startTelesupById: (int) aTelesupId;
- (void) startTelesup: (TELESUP_SETTINGS) aTelesup;
- (void) startTelesup: (TELESUP_SETTINGS) aTelesup getCurrentSettings: (BOOL) aGetCurrentSettings;
- (void) startTelesup: (TELESUP_SETTINGS) aTelesup getCurrentSettings: (BOOL) aGetCurrentSettings telesupViewer: (TELESUP_VIEWER) aTelesupViewer;

- (char *) getErrorInTelesupMsg;

- (void) startTelesupById: (int) aTelesupId getCurrentSettings: (BOOL) aGetCurrentSettings;
- (BOOL) inTelesup;
- (void) startTelesupInBackground;

- (TELESUP_SETTINGS) getMainTelesup;
- (void) setCommunicationIntention: (CommunicationIntention) aCommunicationIntention;
- (CommunicationIntention) getCommunicationIntention;

- (void) setRepairOrder: (id) aRepairOrder;
- (id) getRepairOrder;

- (void) setShutdownApp: (BOOL) aValue;
- (BOOL) getShutdownApp;
- (void) shutdownApp;

- (void) isManual: (BOOL) aValue;
- (BOOL) isInBackground;

@end

#endif
