#include "FileReader.h"

@implementation FileReader

- initWithFile: (FILE*) aFile
{
	myFile = aFile;
	return self;
}

- initWithFileName: (char*) aFile
{
	myFile = fopen(aFile, "rb");
	if (!myFile) THROW_MSG(FILE_NOT_FOUND_EX, aFile);
	return self;
}

- (int) read: (char *)aBuf qty: (int) aQty
{
	return fread(aBuf, 1, aQty, myFile);
}

- (void) seek: (int)aQty from: (int) aFrom
{
		fseek(myFile, aQty, aFrom); 
}

- (void) close
{
	fclose(myFile);
}

@end

