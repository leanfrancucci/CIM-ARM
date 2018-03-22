#include "GetFileRequest.h"
#include "assert.h"
#include "system/util/all.h"
#include "GetLogRequest.h"

/* macro para debugging */
//#define printd(args...) doLog(0,args)
#define printd(args...)


static GET_LOG_REQUEST mySingleInstance = nil;
static GET_LOG_REQUEST myRestoreSingleInstance = nil;
 


@implementation GetLogRequest	

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
	[self setReqType: GET_FILE_REQ];
	mySendAllLogsCompressed = FALSE;
	return self;
}

/**/
- (void) executeRequest
{
	FILE *f;
	char path[50];
	char sourcePath[50];
	char command[255];

	// evalua si debe comprimir los archivos y enviarlos
	if (mySendAllLogsCompressed) {

		unlink(BASE_VAR_PATH "/log.txt");
		unlink(BASE_VAR_PATH "/log2.txt");
		unlink(BASE_VAR_PATH "/logs.tar.gz");
		unlink(BASE_VAR_PATH "/logs.tar");

		sprintf(path, "%s%s", BASE_PATH "/bin/", "log.txt");
		//doLog(0,"path = %s\n", path);

		// si existe copia log.txt a /var
		f = fopen(path, "r");	
		if (f)  {
			fclose(f);
			sprintf(command, "cp %s %s", path, BASE_VAR_PATH "");
			//doLog(0,"Ejecutando comando %s\n", command);
			system(command);
		}

		sprintf(path, "%s%s", BASE_PATH "/bin/", "log2.txt");
		//doLog(0,"path = %s\n", path);

		// si existe copia log2.txt a /var
		f = fopen(path, "r");	
		if (f)  {
			fclose(f);
			sprintf(command, "cp %s %s", path, BASE_VAR_PATH "");
			//doLog(0,"Ejecutando comando %s\n", command);
			system(command);
		}

		// empaqueta los dos archivos
		sprintf(command, "cd " BASE_VAR_PATH " && tar -f logs.tar -c %s %s", "log.txt", "log2.txt");
		//doLog(0,"Ejecutando comando %s\n", command);
		system(command);
		
		// zippea
		sprintf(command, "cd " BASE_VAR_PATH " && gzip %s ", "logs.tar");
		//doLog(0,"Ejecutando comando %s\n", command);
		system(command);

		// envia
		[myRemoteProxy sendAckMessage];
		[myRemoteProxy sendFile: BASE_VAR_PATH "/logs.tar.gz" targetFileName: "logs.tar.gz" appendMode: FALSE];

		unlink(BASE_VAR_PATH "/log.txt");
		unlink(BASE_VAR_PATH "/log2.txt");
		unlink(BASE_PATH "/bin/log2.txt");
		unlink(BASE_VAR_PATH "/logs.tar.gz");
		unlink(BASE_VAR_PATH "/logs.tar");

	} else {

		/* controlar si el archivo existe */
		sprintf(path, "%s%s", BASE_PATH "/bin/", mySourceFileName);
		//doLog(0,"path = %s\n", path);
	
		f = fopen(path, "r");	
	
		if (f) {
		
			fclose(f);
	
			sprintf(command, "cp %s %s", path, BASE_VAR_PATH "");
			//doLog(0,"Ejecutando comando %s\n", command);
			system(command);
	
			sprintf(sourcePath, "%s%s", BASE_VAR_PATH "/", mySourceFileName);
			//doLog(0,"sourcePath = %s\n", sourcePath);

			[myRemoteProxy sendAckMessage];
			[myRemoteProxy sendFile: sourcePath targetFileName: mySourceFileName appendMode: FALSE];

		} else THROW( TSUP_FILE_NOT_FOUND_EX );
	}
}

/**/
- (void) sendAllLogsCompressed: (BOOL) aValue
{
	mySendAllLogsCompressed = aValue;
}

@end



