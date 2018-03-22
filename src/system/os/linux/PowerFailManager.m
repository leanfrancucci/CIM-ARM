#include "PowerFailManager.h"
#include "SystemTime.h"
#include <time.h>
#include "log.h"

#define printd(args...)
//#define printd(args...) doLog(0,args)

static char *files[] = {"clock1.dat", "clock2.dat"};
static POWER_FAIL_MANAGER singleInstance = NULL;

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
	[self recover];
	timer = [OTimer new];
	[timer initTimer: PERIODIC period: 1000 object: self callback: "timerExpired"];
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
	FILE *f;

	// intento leer desde el primer archivo
	f = fopen(files[0], "rb");
	if (f) {
		fread(&time1, sizeof(time1), 1, f);
		fread(&timechk, sizeof(timechk), 1, f);
		fclose(f);
		if (time1 != timechk) time1 = 0;
	}
		
	// intento leer desde el segundo archivo
	f = fopen(files[1], "rb");
	if (f) {
		fread(&time2, sizeof(time2), 1, f);
		fread(&timechk, sizeof(timechk), 1, f);		
		fclose(f);
		if (time2 != timechk) time2 = 0;
	}	

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
	printd("PowerFailManager -> stoping timer\n");	
	[timer stop];
	remove(files[0]);
	remove(files[1]); 	
}

/**/
- (void) saveToFile: (char*) aFile
{
	FILE *f;
	datetime_t now = [SystemTime getLocalTime];
	
 	f = fopen(aFile, "w+b");
	
	if (!f) {
	//	doLog(0,"PowerFailManager cannot write on file %s\n", aFile);
		return;
	}
	
	// escribo la fecha/hora actual
	fwrite(&now, sizeof(now), 1, f);
	
	// la escribo nuevamente, esto me sirve de checksum
	fwrite(&now, sizeof(now), 1, f);
	
	fclose(f);
	
}

/**/
- (void) timerExpired 
{
	currentFile = (currentFile + 1) % 2;
	[self saveToFile: files[currentFile]];	
}

/**/
- (datetime_t) getPowerFailTime
{
	return powerFailTime;
}

@end
