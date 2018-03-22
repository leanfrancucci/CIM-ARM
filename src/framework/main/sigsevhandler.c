#include <signal.h>
//#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>

/**/
void sigsevHandler(int signum) 
{
  void *array[20];
  size_t size;
  char **strings;
  size_t i;

 // doLog(0,"ABORT DEL FRMW8016, signal=%d\n", signum);fflush(stdout);
  DisConnectDatabase();
  fflush(stdout);

  exit(1);
}

/**/
void sigtermHandler(int signum)
{
  exit(1);
}


/**/
void registerSigsevHandler(void) 
{
  signal(SIGSEGV, sigsevHandler);
  signal(SIGABRT, sigsevHandler);
  signal(SIGBREAK, sigsevHandler);
  signal(SIGTERM, sigtermHandler);
  signal(SIGILL, sigsevHandler);
}
