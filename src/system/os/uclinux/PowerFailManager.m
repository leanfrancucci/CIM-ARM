#include "PowerFailManager.h"
#include "SystemTime.h"
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include "log.h"

#define printd(args...)
//#define printd(args...) doLog(0,args)

// Cada cuanto escribe en la NVRAM la fecha/hora actual
#define POWER_FAIL_TIMER_MS		1000

unsigned int qtimes = 0;
int stime(time_t *t);

/**
 *	La NVRAM del RTC esta distribuida de la siguiente forma:
 *
 *	Byte 32     : MAGIC NUMBER
 *	Byte 33-36  : Clock 1.
 *	Byte 37-40  : Checksum Clock 1.
 *	Byte 41-44  : Clock 2.
 *	Byte 44-47  : Checksum Clock 2.
 *
 */

static char *RTC_DEVICE = "/dev/rtc";
static unsigned char MAGIC_CHAR = 0xCA;
static id singleInstance = NULL;
static int fd;

@implementation PowerFailManager

- (void) recover;

/**/
+ new
{
	if (!singleInstance) singleInstance = [[super new] initialize];
	return singleInstance;	
}


/**/
- initialize
{
	printd("PowerFailManager -> initiating\n");
	powerFailTime = 0;
	
	/* Open the RTC device */
	fd = open(RTC_DEVICE, O_RDWR);
	if (fd < 0) {
		//doLog(0, "Cannot open %s.\n",	RTC_DEVICE);
		return self;
	}

	[self recover];
	timer = [OTimer new];
	[timer initTimer: PERIODIC period: POWER_FAIL_TIMER_MS object: self callback: "timerExpired"];
	currentFile = 0;

	return self;
}


/**/
+ getInstance
{
	return [self new];
}

/**/
- (void) recover 
{
	datetime_t time1 = 0, time2 = 0, timechk = 1;
	unsigned char magic;
	
	/* Byte read/write operation. */
	if (lseek(fd, 32, SEEK_SET) < 0) {
		//doLog(0, "RTC driver lseek failed\n");
		return;
	}

	// Leo el numero magico
	if (read(fd, &magic, 1)<= 0) {
		//doLog(0, "RTC driver read failed\n");
		return;	
	}

	// No pudo leer el numero magico, no se puede recuperar la fecha/hora
	// Esto puede ocurrir la primera vez que se utiliza el RTC, despues
	// escribo el numero y ya no deberia suceder.
	if (magic != MAGIC_CHAR) {
		if (lseek(fd, 32, SEEK_SET) < 0) return;
		magic = MAGIC_CHAR;
		if (write(fd, &magic , 1) <= 0) return;
		return;
	}
	
	// Leo el primer clock	
	if (read(fd, &time1, 4) <= 0) {
		//doLog(0, "RTC driver read failed\n");
		return;
	}
	
	// Leo el checksum
	if (read(fd, &timechk, 4) <= 0) {
		//doLog(0, "RTC driver read failed\n");
		return;
	}
		
	if (time1 != timechk) time1 = 0;

	// Leo el segundo clock
	if (read(fd, &time2, 4) <= 0) {
		//doLog(0, "RTC driver read failed\n");
		return;
	}

	// Leo el checksum
	if (read(fd, &timechk, 4) <= 0) {
		//doLog(0, "RTC driver read failed\n");
		return;
	}
		
	if (time2 != timechk) time2 = 0;

	// me quedo con el tiempo mas grande de los dos
	powerFailTime = (time1 > time2) ? time1 : time2;
	
}

/**/
- (void) start
{
	printd("PowerFailManager -> starting timer\n");
	[timer start];	
}

- (void) stop
{
	datetime_t t = 0;
	printd("PowerFailManager -> stoping timer\n");	
	[timer stop];
	
	/* Byte read/write operation. */
	if (lseek(fd, 33, SEEK_SET) < 0) {
		//doLog(0, "RTC driver lseek failed\n");
		return;
	}
	
	// Escribo en el RTC, borro el clock1
	if (write(fd, &t , 4) <= 0) {
		//doLog(0, "RTC driver write failed\n");
		return;
	}

	// Escribo en el RTC, borro el checksum
	if (write(fd, &t , 4) <= 0) {
		//doLog(0, "RTC driver write failed\n");
		return;
	}
	
	// Escribo en el RTC, borro el clock2
	if (write(fd, &t , 4) <= 0) {
		//doLog(0, "RTC driver write failed\n");
		return;
	}
	
	// Escribo en el RTC, borro el checksum
	if (write(fd, &t , 4) <= 0) {
		//doLog(0, "RTC driver write failed\n");
		return;
	}
	
	close(fd);
}

/**/
- (void) saveToFile
{
	datetime_t now = [SystemTime getLocalTime];
	datetime_t now2;
	
	/* Byte read/write operation. */
	if (lseek(fd, (currentFile * 8 + 33), SEEK_SET) < 0) {
		//doLog(0, "RTC driver lseek failed\n");
		return;
	}
	
	// Escribo en el RTC
	if (write(fd, &now , 4) <= 0) {
		//doLog(0, "RTC driver write failed\n");
		return;
	}

	///////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////
	/* Byte read/write operation. */
	if (lseek(fd, (currentFile * 8 + 33), SEEK_SET) < 0) {
		//doLog(0, "RTC driver lseek failed\n");
		return;
	}

		// Escribo en el RTC
	if (read(fd, &now2 , 4) <= 0) {
		//doLog(0, "RTC driver write failed\n");
		return;
	}
	
	if (now != now2) {
	//	//doLog(0, "RTC driver write failed, value not written correctly!!\n");
	}
	///////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////
	
	// Escribo el checksum
	if (write(fd, &now , 4) <= 0) {
		//doLog(0, "RTC driver write failed\n");
		return;
	}

		
}

/** @todo: esto deberia moverse a otro lugar, no es responsabilidad de esta clase
    la actualizacion de la fecha/hora del sistema a partir del RTC.
		Ni siquiera deberia ser responsabilidad de la aplicacion, pero hasta que el linux
		ande bien, se hace aca. */
		
/**/
- (void) updateSystemTime
{
	struct tm tm;
	unsigned char tbuf[7];
	time_t t;

	if (lseek(fd, 0, SEEK_SET) < 0) return;
	
	// Leo el numero magico
	if (read(fd, tbuf, 7)<= 0) return;

	tm.tm_sec = (tbuf[0] & 0xf) + 10 * ((tbuf[0] >> 4) & 0x7);
	tm.tm_min = (tbuf[1] & 0xf) + 10 * ((tbuf[1] >> 4) & 0x7);
	tm.tm_hour = (tbuf[2] & 0xf) + 10 * ((tbuf[2] >> 4) & 0x3);
	tm.tm_mday = (tbuf[3] & 0xf) + 10 * ((tbuf[3] >> 4) & 0x3);
	tm.tm_mon = (tbuf[4] & 0xf) + 10 * ((tbuf[4] >> 4) & 0x1) - 1;
	tm.tm_year = 100 + (tbuf[6] & 0xf) + 10 * ((tbuf[6] >> 4) & 0xf);

	printd("time is year=%d, mon=%d, day=%d, hour=%d, min=%d, sec = %d\n", tm.tm_year, tm.tm_mon, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec);

	t = mktime(&tm);
	stime(&t);
	
}

/**/
- (void) timerExpired 
{
	currentFile = (currentFile + 1) % 2;
	[self saveToFile];
	qtimes++;

	// Cada 10 minutos toma la fecha/hora del RTC y la actualiza
	if (qtimes >= 600) {
//		[self updateSystemTime];
		qtimes = 0;
	}
}


/**/
- (datetime_t) getPowerFailTime
{
	return powerFailTime;
}

@end
