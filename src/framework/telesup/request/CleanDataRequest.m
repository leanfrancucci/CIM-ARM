#include "CleanDataRequest.h"
#include "ctversion.h"
#include "system/util/all.h"

//#define printd(args...) doLog(args)
#define printd(args...)


@implementation CleanDataRequest

static CLEAN_DATA_REQUEST mySingleInstance = nil;
static CLEAN_DATA_REQUEST myRestoreSingleInstance = nil;

/**/
+ getSingleVarInstance
{
	 return mySingleInstance; 
};
+ (void) setSingleVarInstance: (id) aSingleVarInstance
{
	 mySingleInstance =  aSingleVarInstance;
};

/**/
+ getRestoreVarInstance
{
	 return myRestoreSingleInstance;
};
+ (void) setRestoreVarInstance: (id) aRestoreVarInstance
{
	 myRestoreSingleInstance = aRestoreVarInstance;
};

/**/
- initialize
{
	[super initialize];
	[self setReqType: CLEAN_DATA_REQ];
	myCleanAudits = FALSE;
	myCleanTickets = FALSE;
	myCleanCashRegister = FALSE;
	return self;
}

/**/
- (void) setCleanAudits: (BOOL) aValue { myCleanAudits = aValue; }
/**/
- (void) setCleanTickets: (BOOL) aValue { myCleanTickets = aValue; }
/**/
- (void) setCleanCashRegister: (BOOL) aValue { myCleanCashRegister = aValue; }

#define SCRIPT_FILE BASE_PATH "/etc/rc2.d/S23clean_data"

/** @todo: la forma en que esta hecho esto esta muy acoplado con el sistema operativo uclinux.
		Deberia de implementarse de forma mas generica o derivar la implementacion a un facade.
		No se hace por falta de tiempo.  */
		
/**/
- (void) generateScript
{
	char path[255];
	char *databasePath;
	FILE *f;

	strcpy(path, SCRIPT_FILE);
	
	// Genero el archivo	
	f = fopen(path, "w+");
	if (!f) THROW(INVALID_PATH_EX);

	fprintf(f, "%s", "#!/bin/sh\n");
	fprintf(f, "echo Eliminando archivos...\n");
	
	databasePath = [[Configuration getDefaultInstance] getParamAsString: "DATABASE_PATH"];
	
	if (myCleanAudits) {
		fprintf(f, "echo Eliminando auditorias...\n");
		fprintf(f, "rm %s/audits*dat 2> /dev/null\n", databasePath);
	}

	if (myCleanTickets) {
		fprintf(f, "echo Eliminando tickets y llamadas..\n");
		fprintf(f, "rm %s/tickets*dat 2> /dev/null\n", databasePath);
		fprintf(f, "rm %s/calls*dat 2> /dev/null\n", databasePath);
		fprintf(f, "rm %s/items*dat 2> /dev/null\n", databasePath);
		fprintf(f, "rm %s/product_sale*dat 2> /dev/null\n", databasePath);
		fprintf(f, "rm %s/ws_accounts*dat 2> /dev/null\n", databasePath);
		fprintf(f, "rm %s/amounts_by_call*dat 2> /dev/null\n", databasePath);
		fprintf(f, "rm %s/fiscal_tickets*dat 2> /dev/null\n", databasePath);
	}

	if (myCleanCashRegister) {
		fprintf(f, "echo Eliminando tickets y llamadas..\n");
		fprintf(f, "rm %s/cash_register.dat 2> /dev/null\n", databasePath);
		fprintf(f, "rm %s/movements*dat 2> /dev/null\n", databasePath);
		fprintf(f, "rm %s/fiscal_close*dat 2> /dev/null\n", databasePath);
	}

	fprintf(f, "rm %s\n", SCRIPT_FILE);
	
	fclose(f);
	
}

/**/
- (void) executeRequest
{
	[self generateScript];
}

/**/
- (void) endRequest
{
	[super endRequest];
	
	[myRemoteProxy sendAckMessage];
}

@end
