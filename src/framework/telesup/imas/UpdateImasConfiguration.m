#include <unistd.h>
#include "UpdateImasConfiguration.h"
#include "FileManager.h"
#include "CipherManager.h"

#define printd(args...)

@implementation UpdateImasConfiguration

/**/
-(int) applyConfiguration:(char *) filename destination:(char*) dest
{
  CIPHER_MANAGER cipherManager;
	char *fn= (char *) malloc(100);
  char tmpFileName[255];
  int fSize;

 	printd("applyConfiguration: %s - %s\n",filename, dest);

  fSize = [[FileManager getDefaultInstance] getFilesize: filename];
 
  cipherManager = [CipherManager new];
  sprintf(tmpFileName, "%sdec", filename);
  [cipherManager decodeFile: filename destination: tmpFileName size: fSize];
  [cipherManager free];

#ifdef __WIN32	
  strcpy(fn,"update.tgz");
#else
  strcpy(fn,"update.tar.gz");
#endif

	printd("filename: %s\n",fn);

	strcat(dest,fn);
	printd("filenamedest: %s\n",dest);

  unlink(dest);
  rename(tmpFileName, dest);

	[[FileManager getDefaultInstance] deleteFile: filename];

	free(fn);

	return 0;

}

@end
