#include <windows.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "parallelportapi.h"
#include "OSExcepts.h"

#define printd(args...)



/**/
OS_HANDLE lpt_open()
{
	 HANDLE myHandle;

/*   myHandle = CreateFile("lpt1", GENERIC_READ | GENERIC_WRITE, 0, 0, 
													OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_WRITE_THROUGH |
													FILE_FLAG_NO_BUFFERING, 0);
*/	 
	myHandle = CreateFile("lpt1", GENERIC_READ | GENERIC_WRITE, 0, 0, 
													CREATE_ALWAYS, 0, 0);
  if (!myHandle) return 0;
							
	return myHandle;
}


/**/
int lpt_read(OS_HANDLE handle, char *buffer, int qty)
{
	unsigned long nReaded;
	ReadFile( handle, buffer, qty, &nReaded, NULL);
  return(nReaded);
}

/**/
void lpt_flush(OS_HANDLE handle)
{
  FlushFileBuffers(handle);
}

/**/
int lpt_write(OS_HANDLE handle, char *buffer, int qty)
{
	unsigned long nWritten;
	WriteFile(handle, buffer, qty, &nWritten, NULL);
	return nWritten;
}


/**/
void lpt_close(OS_HANDLE handle)
{
	CloseHandle(handle);
}


