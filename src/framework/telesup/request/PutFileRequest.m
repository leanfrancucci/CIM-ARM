#include "PutFileRequest.h"
#include "assert.h"
#include "system/util/all.h"
#include "Audit.h"

/* macro para debugging */
//#define printd(args...) doLog(0,args)
#define printd(args...)

static PUT_FILE_REQUEST mySingleInstance = nil;
static PUT_FILE_REQUEST myRestoreSingleInstance = nil;

@implementation PutFileRequest	

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
	[self setReqType: PUT_FILE_REQ];
  myPackage = [GenericPackage new];
	return self;
}

/**/
- (void) setTargetFileName: (char *) aFileName 
{ 
	stringcpy(myTargetFileName, aFileName); 
}

/**/
- (char *) getTargetFileName 
{ 
	return myTargetFileName; 
}

/**/
- (void) setSourceFileName: (char *) aFileName 
{ 
	stringcpy(mySourceFileName, aFileName);
}


/**/
- (char *) getSourceFileName 
{ 
	return mySourceFileName; 
}

/**/
- (void) clearRequest
{	
};

/**/
- (void) executeRequest
{
  FILE *file;
	char fileStr[50];
	char fileName[50];
	char buffer[100];
	STRING_TOKENIZER tokenizer;

	[myRemoteProxy sendAckMessage];

	//doLog(0,"mySourceFileName = %s\n", mySourceFileName);
//	doLog(0,"myTargetFileName = %s\n", myTargetFileName);

	[myRemoteProxy receiveFile: mySourceFileName targetFileName: myTargetFileName];	


	// analiza la categoria, si es firm update crea un archivo FileName.ini que adentro posee la lista de aceptadores a los cuales se aplica el update y el nombre del archivo de update.
	
  if ([myPackage isValidParam: "Category"]) {

		if (strcmp([myPackage getParamAsString: "Category"], "UPDATE") == 0) {
			[Audit auditEventCurrentUser: SOFTWARE_UPDATE additional: "" station: 0 logRemoteSystem: TRUE];
		}

		if (strcmp([myPackage getParamAsString: "Category"], "FIRM_UPDATE") == 0) {

			tokenizer = [StringTokenizer new];
			[tokenizer setDelimiter: "."];
			[tokenizer setTrimMode: TRIM_ALL];
	
			[tokenizer restart];
			[tokenizer setText: [myPackage getParamAsString: "FileName"]];
	
			if (![tokenizer hasMoreTokens]) THROW(INVALID_UPDATE_FILE_NAME_EX);
			[tokenizer getNextToken: fileStr];
	
			sprintf(fileName, "%s%s%s", myPath, fileStr,".ini"); 
	
			file = fopen(fileName, "w+"); // si no existe lo crea
	
			sprintf(buffer, "%s%s\n", "Acceptors=", [myPackage getParamAsString: "Devices"]);
			fwrite(buffer, strlen(buffer), 1, file);
	
			sprintf(buffer, "%s%s", "File=", [myPackage getParamAsString: "FileName"]);
			fwrite(buffer, strlen(buffer), 1, file);
			fclose(file);
			[tokenizer free];
		}
	}	

}

/**/
- (void) loadPackage: (char*) aMessage
{
  [myPackage loadPackage: aMessage];
}

/**/
- (void) setPath: (char*) aPath
{
	stringcpy(myPath, aPath);
}

@end



