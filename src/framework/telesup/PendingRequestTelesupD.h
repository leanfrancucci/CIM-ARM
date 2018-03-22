#ifndef PENDINGREQTELESUPD_H
#define PENDINGREQTELESUPD_H

#define PENDING_REQUEST_TELESUPD id

#include <Object.h>
#include "ctapp.h"

#include "TelesupD.h"

#define PENDING_TELESUPD_SLEEPING		2

/*
 *	Implementa la telesupervisión de los Request pendientes 
 *  encolados por ser configurados con fecha de vigencia futura.
 */
@interface PendingRequestTelesupD: TelesupD
{

}

/*
 *	
 */
+ new;

/*
 *	
 */
- initialize;


/**/	
- (void) run;

@end

#endif
