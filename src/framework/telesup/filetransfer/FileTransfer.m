#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <objpak.h>
#include "system/util/all.h"
#include "telesup/TelesupExcepts.h"
#include "FileTransfer.h"


//#define printd(args...) doLog(args)
#define printd(args...)


@implementation FileTransfer


/**/
+ new
{
	printd("FileTransfer - new\n");
	return [[super new] initialize];
};

/**/
- initialize
{
	[super initialize];
	return self;
};

/**/
- (void) clear
{
	myReader = NULL;
	myWriter = NULL;			
	
	myFileSize = 0;
	mySourceFileName[0] = '\0';
	myTargetFileName[0] = '\0';
	myDirName[0] = '\0';
	myFileDate = 0;
}

/**/
- (void) setTelesupViewer: aTelesupViewer { myTelesupViewer = aTelesupViewer; }
- (TELESUP_VIEWER) getTelesupViewer { return myTelesupViewer; }

/**/
- (void) setSourceFileName: (char *) aFileName { strncpy2(mySourceFileName, aFileName, sizeof(mySourceFileName) - 1); }
- (char *) getSourceFileName { return mySourceFileName; }

/**/
- (void) setTargetFileName: (char *) aFileName { strncpy2(myTargetFileName, aFileName, sizeof(myTargetFileName) - 1); }
- (char *) getTargetFileName { return myTargetFileName; }

/**/
- (void) setFileCompressed: (BOOL) aFileIsCompressed { myFileIsCompressed = aFileIsCompressed;}
- (BOOL) isFileCompressed { return myFileIsCompressed; }

/**/
- (void) setDirName: (const char *) aDirName { strncpy2(myDirName, aDirName, sizeof(myDirName) - 1); }

/**/
- (void) setFileSize: (unsigned long) aFileSize { 	myFileSize = aFileSize; }


/**/
- (void) setReader: (READER) aReader { 	myReader = aReader; }

/**/
- (void) setWriter: (WRITER) aWriter { 	myWriter = aWriter; }

/**/
- (void) uploadFile
{
	THROW( ABSTRACT_METHOD_EX );
};

/**/
- (void) downloadFile
{
	THROW( ABSTRACT_METHOD_EX );
};

@end
