/**
 * osplatf.c
 **/

/*
* PLATAFORMA LINUX
*/

#include <sched.h>
#include <pthread.h>
#include <assert.h>
#include <unistd.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>
#include <linux/kernel.h>
#include <sys/times.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/resource.h>
#include <stdlib.h>
#include <string.h>
#include "log.h"
//#include <semaphore.h>

#include "osdef.h"

/* Im not sure */
#define 	EOK 		0

	
/**
 * O P E R A T I N G    S Y S T E M
 **/


/**
 *
 **/
/*
void
osInit_OSPDep(void)
{
	return;
}

void
osStart_OSPDep(void)
{
	return;
}

void
osExit_OSPDep(void)
{
}
*/

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
	int ret;

	attr = attr;
	prior = prior;
	

/*	pthread_attr_init(&_attrib);
	
	if (prior == 15 || prior == 5) {

		if (prior == 15) params.sched_priority = sched_get_priority_max(SCHED_RR);
		if (prior == 5) params.sched_priority = sched_get_priority_min(SCHED_RR);
		
		doLog(0,"Settings thread priority to %d\n", params.sched_priority);
		pthread_attr_setschedpolicy(&_attrib, SCHED_RR);
		pthread_attr_setschedparam(&_attrib, &params);
		//pthread_attr_setdetachstate(&_attrib, PTHREAD_CREATE_DETACHED);
		//pthread_attr_setscope(&_attrib, PTHREAD_SCOPE_SYSTEM);	
	}
	
	
	ret = pthread_create(th, &_attrib, ef, ei);
*/

	ret = pthread_create(th, NULL, ef, ei);
	
	assert(ret == 0);
	return ret;
}

/**
 *
 **/
void 
threadExit_OSPDep(ThreadId_t * thid)
{
	/*Se realiza un cancel del thread*/
	pthread_cancel(*thid);
	/*Se debe invocar a esta funcion para que termine la ejecucion del thread en el momento*/
	pthread_testcancel();
}


/**
 *
 **/
ThreadId_t
threadSelf_OSPDep(void)
{
	return pthread_self();
}


/**
 *  Routine compares two thread IDs. If the two IDs are different 0 is returned, otherwise a non-zero value is returned.
 **/
int 
threadEqual_OSPDep(ThreadId_t th1, ThreadId_t th2)
{
	return th1 == th2;
}

/**
 * Duerme el thread la cantidad de segundos enviada como parametro.
 **/
void
threadSleep_OSPDep(unsigned int secs)
{	
	sleep(secs);
}

/**
 * Leaves the processor 
 **/
void 
threadYield_OSPDep(void)
{
	sched_yield();
}

/**
 * Realiza un join del thread.
 **/
 void
 threadJoin_OSDep(ThreadId_t * thid)
 {
	 pthread_join(*thid, NULL);
 }

/**
 *
 **/
int 
geterrno_OSPDep(void)
{
	return errno;
}

/**
 *
 **/
void
seterrno_OSPDep(int eno)
{
	errno = eno;
}

/**/
int threadSetPriority_OSDep(int priority)
{
	//doLog(0,"thread priority before = %d\n", getpriority(PRIO_PROCESS,0));
	assert(setpriority(PRIO_PROCESS,0,priority)==0);
	//doLog(0,"thread priority after = %d, pid = %d\n", getpriority(PRIO_PROCESS,0), getpid());
	return 0;
}

/**
 * M U T E X
 **/

/**
 *
 **/

int 
mutexInit_OSPDep(MutexId_t *mutex, const MutexAttr_t *attr)
{
	int ret = pthread_mutex_init(mutex, NULL);
	return ret == EOK ? 0: ret;
}

int 
mutexDestroy_OSPDep(MutexId_t *mutex)
{
	int ret = pthread_mutex_destroy(mutex);
	return ret == EOK ? 0: ret;
}

int 
mutexLock_OSPDep(MutexId_t *mutex)
{
	int ret = pthread_mutex_lock(mutex);
	return ret == EOK ? 0: ret;
}

int 
mutexTrylock_OSPDep(MutexId_t *mutex)
{
	int ret = pthread_mutex_trylock(mutex);
	return ret == EOK ? 0: ret;
}

int 
mutexUnlock_OSPDep(MutexId_t *mutex)
{
	int ret = pthread_mutex_unlock(mutex);
	return ret == EOK ? 0: ret;
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
	/* 2nd parameter: 0 is non shared semaphore */
	return sem_init(sem, 0, value);
}

/**
 *
 **/
int 
semDestroy_OSPDep(SemId_t *sem)
{
	return sem_destroy(sem);
}

/**
 *
 **/
 
int 
semPost_OSPDep(SemId_t *sem)
{
	return sem_post(sem);
}

/**
 *
 **/
int 
semWait_OSPDep(SemId_t *sem)
{
	return sem_wait(sem);
}

/**
 *
 **/ 
int 
semTimedwait_OSPDep(SemId_t *sem, unsigned long msecs)
{
	/* struct timespec abs_timeout; */
	sem = sem;
	msecs = msecs;
	
	/*
		return sem_timedwait(sem_t *restrict sem,
       					const struct timespec *abs_timeout);
	*/       				

	return -1;
}

/**
 *
 **/
int 
semTrywait_OSPDep(SemId_t *sem)
{
	return sem_trywait(sem);
}

// Definido para el kernel a 1.25 ms
static unsigned long ticksPerSecond = 1250;

// Definido para el kernel a 10 ms
//static unsigned long ticksPerSecond = 100;

/*
static int uptimefd = -1;

static int oldvalue = 0;

*/
#define UPTIME_FILE "/proc/uptime"


/*
 *	Devuelve un tickcount en milisegundos.
 *	PROBAR.
 */
unsigned long
getTicks(void)
{
	/*struct tms buf;
	long value;

	value = times(&buf);
	value = (value * 125) / 100;
	return value;
	*/
/*	
	 struct timeval tv;
	 //doLog(0,"HZ = %ld\n", CLK_TCK);
	 gettimeofday(&tv, NULL);
   return( tv.tv_sec * 1000 + tv.tv_usec / 1000 );
*/

	struct tms buf;
	unsigned long value = 0;
	 
	//if (ticksPerSecond == -1) ticksPerSecond = sysconf(_SC_CLK_TCK);
	 
	value = ((long long)times(&buf) * ticksPerSecond) / 1000;

	return value ;

	/*
	char *index;
	char buffer[50];
	float value;
	long 	result;
	
	uptimefd = open(UPTIME_FILE, O_RDONLY);
	assert(uptimefd != -1);
	//seek(uptimefd, 0, SEEK_SET);
	read(uptimefd, buffer, 49 );
	close(uptimefd);
	
	index = strchr(buffer, 32);
	if (index) *index = '\0';
	sscanf(buffer, "%f", &value);
	result = (long)(value * 1000);
	
	if (result - oldvalue >= 1000) {
		oldvalue = result;
		doLog(0,"value is %ld\n", result);
	}
	
	return result;
	*/
}

/*
 *	Duerme la cantidad de milisegundos segundos especificada en value.
 */
void	msleep(unsigned long value)
{
	struct timespec sl;
	//sl.tv_sec = 0;
	//sl.tv_nsec = value * 1000000;
	sl.tv_sec = value / 1000;
	sl.tv_nsec = (value % 1000) * 1000000;
	nanosleep(&sl, NULL);
	//usleep(value * 1000);
}

static char version[255];

/**/
char *getKernelVersion_OSDep(void)
{
	FILE *f;

	if (system("uname -r > /tmp/version.txt") == -1)
		return NULL;

	f = fopen("/tmp/version.txt", "r");
	if (!f) return NULL;

	fgets(version, 200, f);
	if (version[strlen(version)-1] == '\n') version[strlen(version)-1] = 0;

	fclose(f);

	if (strlen(version) == 0) return NULL;

	return version;
}


/**/
int makeDir_OSDep(char *path)
{
	return mkdir(path, 777);
}

