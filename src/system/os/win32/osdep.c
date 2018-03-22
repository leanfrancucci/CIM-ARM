/**
 * osplatf.c
 **/

/*
* PLATAFORMA WINDOWS
*/

#include <WINDOWS.H>
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <windows.h>
#include <winsock.h>
#include <unistd.h>
#include "time.h"
#include "osdef.h"

/* Im not sure */
#define 	EOK 		0

/**
 * O P E R A T I N G    S Y S T E M
 **/


/** 
 * T H R E A D S 
 **/

/** 
 * Funcion que invoca a la funcion para la creacion de un thread.
 *
 **/

int 
threadCreate_OSPDep(ThreadId_t *th, const ThreadAttr_t *attr, ThreadEntryFun_t *ef, void *ei, int prior)
{	
	size_t stacksize;
	HANDLE h;
	DWORD threadId;
	attr = attr;
	prior = prior;
	
	/* Define stack size */
	if (attr && attr->stacksize > MIN_STACK_SIZE) 
		stacksize = attr->stacksize;
	else
		stacksize = MIN_STACK_SIZE;

	h = CreateThread(
			    		NULL , //lpThreadAttributes,	// pointer to thread security attributes  
			    		stacksize ,//dwStackSize,	// initial thread stack size, in bytes 
			    		(LPTHREAD_START_ROUTINE)ef, //lpStartAddress,	// pointer to thread function 
			    		ei, // lpParameter,	// argument for new thread 
			    		0, //dwCreationFlags,	// creation flags 
		    			&threadId // lpThreadId 	// pointer to returned thread identifier 
		   			);
  assert(h != NULL);
	
//  if (th) *th = h;   	
//  *th = (Thread_OSPDep_t)threadId;
  (*th).handle = h;
  (*th).threadId = threadId;

	if (5  == prior) SetThreadPriority(h, THREAD_PRIORITY_BELOW_NORMAL);
	if (10 == prior) SetThreadPriority(h, THREAD_PRIORITY_ABOVE_NORMAL);
	if (15 == prior) SetThreadPriority(h, THREAD_PRIORITY_HIGHEST	);
	
  return 0;
}

/**
 *
 **/
void 
threadExit_OSPDep(ThreadId_t * thid)
{
	ExitThread(0);
}


/**
 *
 **/
ThreadId_t
threadSelf_OSPDep(void)
{
	ThreadId_t th;

	th.handle = 0;
	th.threadId = GetCurrentThreadId();

	return th;
}


/**
 *  Routine compares two thread IDs. If the two IDs are different 0 is returned, otherwise a non-zero value is returned.
 **/
int 
threadEqual_OSPDep(ThreadId_t th1, ThreadId_t th2)
{
	return th1.threadId == th2.threadId;
}

/**
 * Duerme el thread la cantidad de segundos enviada como parametro.
 **/
void
threadSleep_OSPDep(unsigned int secs)
{	
	Sleep(secs);
}

/**
 * Libera el procesador.
 **/
void 
threadYield_OSPDep(void)
{
	Sleep(0);
}

/**
 * Realiza un join del thread.
 **/

void
threadJoin_OSDep(ThreadId_t * thid)
{
	int ret;
	ret = WaitForSingleObject((*thid).handle, INFINITE);
	assert(ret != WAIT_FAILED);
}

/**
 *
 **/
int 
geterrno_OSPDep(void)
{
	return GetLastError();
}

/**
 *
 **/
void
seterrno_OSPDep(int eno)
{
	SetLastError(eno);
}

/**/
int threadSetPriority_OSDep(int priority)
{
  int nPriority;

//	doLog(0,"Implementar el cambio de prioridades de un hilo para Win32, osdep.c\n");
/*
    THREAD_PRIORITY_TIME_CRITICAL --> no se usa
    THREAD_PRIORITY_HIGHEST       --> -20 a -11
    THREAD_PRIORITY_ABOVE_NORMAL  --> -10 a -1
    THREAD_PRIORITY_NORMAL        --> 0 a 20
    THREAD_PRIORITY_BELOW_NORMAL  --> no se usa
    THREAD_PRIORITY_LOWEST        --> no se usa
    THREAD_PRIORITY_IDLE          --> no se usa
*/
  if (priority <= -11) {
  //  doLog(0,"Seteando prioridad a THREAD_PRIORITY_HIGHEST\n");
    nPriority = THREAD_PRIORITY_HIGHEST;
  }
  else if (priority < 0) {
   // doLog(0,"Seteando prioridad a THREAD_PRIORITY_ABOVE_NORMAL\n");
    nPriority = THREAD_PRIORITY_ABOVE_NORMAL;
  }
  else {
 //   doLog(0,"Seteando prioridad a THREAD_PRIORITY_NORMAL\n");
    nPriority = THREAD_PRIORITY_NORMAL;
  }

  SetThreadPriority(
    GetCurrentThread(),
    nPriority);

	return 0;
}


/**
 * M U T E X
 **/


int 
mutexInit_OSPDep(MutexId_t *mutex, const MutexAttr_t *attr)
{
	HANDLE h = CreateMutex(
							    NULL, // pointer to security attributes 
							    FALSE,	// flag for initial ownership 
							    NULL	// pointer to mutex-object name  
						   );
	assert(h != NULL);
	
	attr = attr;
	*mutex = h;
	return 0;
}

int 
mutexDestroy_OSPDep(MutexId_t *mutex)
{
	if (CloseHandle(*mutex)) return 0; else return geterrno_OSPDep();
}

 
int 
mutexLock_OSPDep(MutexId_t *mutex)
{
	int ret;
	ret = WaitForSingleObject(*mutex, INFINITE);
	assert(ret != WAIT_FAILED);
	return 0;	
}

int 
mutexTrylock_OSPDep(MutexId_t *mutex)
{
	DWORD ret;
	
	ret = WaitForSingleObject(*mutex, 0);
	assert(ret == WAIT_OBJECT_0 || ret == WAIT_TIMEOUT);
	return 0;
	
}

int 
mutexUnlock_OSPDep(MutexId_t *mutex)
{
	if (ReleaseMutex(*mutex)) return 0; else return geterrno_OSPDep();   
}


/**
 * S E M A P H O R E S
 **/

/**
 *
 **/
int 
semInit_OSPDep(SemId_t *sem, unsigned int value)
{
	HANDLE h = CreateSemaphore(
    							NULL, // pointer to security attributes 
							    (LONG)value,	// initial count 
							    MAX_SEMAPHORE_COUNT,	// maximum count 
							    NULL 	// pointer to semaphore-object name  
							   );	
   	assert(h != NULL);   	   	
   	*sem = h;
   	return 0;   	
}

/**
 *
 **/
int 
semDestroy_OSPDep(SemId_t *sem)
{
	if (CloseHandle(*sem)) return 0; else return geterrno_OSPDep();
}

/**
 *
 **/
 
int 
semPost_OSPDep(SemId_t *sem)
{
	/*
		BOOL ReleaseSemaphore(
	    	HANDLE hSemaphore,	// handle of the semaphore object  
	    	LONG lReleaseCount,	// amount to add to current count  
		    LPLONG lpPreviousCount 	// address of previous count 
		   );
	*/
	if (ReleaseSemaphore(*sem,1, NULL)) return 0; else return geterrno_OSPDep();
}

/**
 *
 **/
int 
semWait_OSPDep(SemId_t *sem)
{
	int ret;
	/*
		DWORD WaitForSingleObject(
			    HANDLE hHandle,	// handle of object to wait for 
    			DWORD dwMilliseconds 	// time-out interval in milliseconds  
   		);
   	*/
	ret = WaitForSingleObject(*sem, INFINITE);
	assert(ret != WAIT_FAILED);
	return 0;
}

/**
 *
 **/ 
int 
semTimedwait_OSPDep(SemId_t *sem, unsigned long msecs)
{
	DWORD ret;
	
	ret = WaitForSingleObject(*sem, msecs);
	assert(ret != WAIT_FAILED);
	return 0;
}	

/**
 *
 **/
int 
semTrywait_OSPDep(SemId_t *sem)
{
	DWORD ret;
	
	ret = WaitForSingleObject(*sem, 0);
	assert(ret == WAIT_OBJECT_0 || ret == WAIT_TIMEOUT);
	return 0;	
}



long  
getTicks(void)
{
   return( GetTickCount() );
}

/*
 *	Duerme la cantidad de segundos especificada en value.
 */
void	msleep(unsigned long value)
{
	Sleep(value);
}

/** 
 * S O C K E T S
 **/

/** 
 * Inicializa los WinSockets
 */
int initSockets_OSPDep(void)
{
	WORD wVersionRequested;
	WSADATA wsaData;
	int err;
	 
//	wVersionRequested = MAKEWORD( 2, 2 );
	wVersionRequested = MAKEWORD( 1, 1 );
	 
	err = WSAStartup( wVersionRequested, &wsaData );
	if ( err != 0 )
		return -1;
	return 0;		
}

/** 
 * Libera recursos tomados por los WinSockets
 */
int cleanupSockets_OSPDep(void)
{
	WSACleanup();
	return 1;
}

/**/
char *getKernelVersion_OSDep(void)
{
	return NULL;
}

/**/
int makeDir_OSDep(char *path)
{
	return mkdir(path);
}

/**/
int secureWriteDataToFile(char *aFileName, char *data, int size)
{
  HANDLE hFile; 
  DWORD wmWritten; 

  hFile = CreateFile(aFileName,GENERIC_READ|GENERIC_WRITE, 
        FILE_SHARE_READ,NULL,OPEN_ALWAYS,FILE_FLAG_WRITE_THROUGH,NULL); 

  WriteFile(hFile,data,size,&wmWritten,NULL); 

  FlushFileBuffers(hFile);

  CloseHandle(hFile); 
  return 0;
}

/**/
int stime(time_t *dt)
{
  SYSTEMTIME systime;
  struct tm brokenTime;

  gmtime_r(dt, &brokenTime);

  systime.wYear = brokenTime.tm_year + 1900;
  systime.wMonth = brokenTime.tm_mon + 1;
  systime.wDayOfWeek = 0; 
  systime.wDay = brokenTime.tm_mday;
  systime.wHour = brokenTime.tm_hour;
  systime.wMinute = brokenTime.tm_min;
  systime.wSecond = brokenTime.tm_sec;
  systime.wMilliseconds = 0; 

  //doLog(0,"Configurando hora a %02d/%02d/%d %02d:%02d:%02d (%ld)", systime.wDay, systime.wMonth, systime.wYear, systime.wHour, systime.wMinute, systime.wSecond, *dt);

  SetSystemTime(&systime);
  return 0;
}
