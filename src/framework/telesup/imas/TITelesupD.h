#ifndef TI_TELESUPD_H
#define TI_TELESUPD_H

#define TI_TELESUPD id

#include <Object.h>
#include "ctapp.h"
#include "TelesupD.h"
#include "ImasConfigLauncher.h"


/*
 *	Implementa el protocolo de telesupervision con el sistema de Telecom
 */
@interface TITelesupD: TelesupD
{
	IMAS_CONFIG_LAUNCHER imasConfigLauncher;
	char *myCurrentMsg;
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

/**/
-(int) genFile:(char*) reqMsg fileName:(char *) fName fixedFilename:(char *) fFName fromDate:(datetime_t) fDate toDate:(datetime_t) tDate activefilter:(int) filtered;
@end

#endif
