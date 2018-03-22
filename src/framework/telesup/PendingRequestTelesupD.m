#include "util.h"
#include "PendingRequestTelesupD.h"
#include "Request.h"
#include "Persistence.h"
#include "RequestDAO.h"
#include "DefaultRequestDAO.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation PendingRequestTelesupD

+ new
{
	printd("PendingRequestTelesupD - new\n");
	return [[super new] initialize];
}

- initialize
{

	return self;
}

/**/
- (void) run
{
	REQUEST request;
	COLLECTION	requestCol;

	/* Crea la coleccion de Request que se pasara al PendingRequestDAO
	  para que la llene con los Request pendientes  */
	requestCol = [OrdCltn new] ;

	/* Repite para siempre */
	while (1) {

		printd("Arranca de nuevo [presione cualquier tecla para finalizar]\n");
		/* Obtiene la lista de todos los Request pendientes */
		[[[Persistence getInstance] getDefaultRequestDAO] fillPendingRequestCol: requestCol];

		/* Recorre y procesa cada Request pendiente */
		while ( [requestCol size] ) {

			request = [requestCol firstElement];

			/* Procesa el Request */
			[self processRequest: request];

			/* Avisa que el Request se proceso con exito */
			[[[Persistence getInstance] getDefaultRequestDAO] requestProcessed: request];

			/* remueve el item */
			[requestCol removeFirst] ;

			/* Hace el clear del request */
			[request clear];
		}

		/** Duerme x segundos */
		[self sleep: PENDING_TELESUPD_SLEEPING];
	}

	[requestCol free];
};

@end
