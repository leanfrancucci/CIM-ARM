#include "ModuleLicenceThread.h"
#include "system/util/all.h"
#include "MessageHandler.h"
#include <unistd.h>
#include "CommercialStateMgr.h"

#define CONTROL_CHECK_TIME_M						300000		// 5 minutos

//#define printd(args...) doLog(0,args)
#define printd(args...)


/**/
@implementation ModuleLicenceThread

static MODULE_LICENCE_THREAD singleInstance = NULL; 

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
	return self;
}

/**/
+ getInstance
{
  return [self new];
}

/**/
- (void) run 
{
	
//	doLog(0,"Iniciando hilo de control de tiempo transcurrido de modulos...\n");

	while (TRUE) {

//  TRY

		msleep(CONTROL_CHECK_TIME_M);
		//[[CommercialStateMgr getInstance] updateModulesTimeElapsed: CONTROL_CHECK_TIME / 1000];

//	CATCH

		//	doLog(0,"Excepcion en el hilo de control de tiempo transcurrido en el uso de modulos...\n");
			//ex_printfmt();

//	END_TRY

	}

}



@end
