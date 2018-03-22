#include "FileWriter.h"

@implementation FileWriter

- initWithFile: (FILE*) aFile
{
	myFile = aFile;
	return self;
}

- initWithFileName: (char*) aFile
{
	myFile = fopen(aFile, "w+b");
	if (!myFile) THROW_MSG(FILE_NOT_FOUND_EX, aFile);
	return self;
}

- (int) write: (char *)aBuf qty: (int) aQty
{
	return fwrite(aBuf, 1, aQty, myFile);
}

- (void) seek: (int) aQty from: (int) aFrom
{
	fseek(myFile, aQty, aFrom);	
}

- (void) close
{
	fclose(myFile);
}

@end

