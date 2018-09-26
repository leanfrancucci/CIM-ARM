#include "SystemTime.h"
#include "UtilExcepts.h"
#include <time.h>
#include <stdlib.h>

/** @todo: buscar la forma de obtener la zona horaria en uClibc */

#ifdef __UCLINUX
#define TIMEZONE tzone
int stime(time_t *t);
#endif

#ifdef __LINUX
#define TIMEZONE (__timezone)
#endif

#ifdef __ARM_LINUX
//#define TIMEZONE (__timezone)
#define TIMEZONE tzone
#endif

#ifdef __WIN32
#define TIMEZONE (_timezone - _daylight*3600)
#endif

#ifdef __WIN32
/*int stime(time_t *t)
{
  setDateTime(*t);
  return 0;
}*/
#endif

static long tzone = 0;

@implementation SystemTime

/**/
+ new
{
	THROW(CLASS_METHODS_ONLY_CLASS_EX);
	return NULL;
}

/**/
+ (void) setTimeZone: (int) aTimeZone
{
	tzone = aTimeZone * -1;
}

/**/
+ (datetime_t) getLocalTime
{
	time_t now = [self getGMTTime];
	return now - TIMEZONE;
}

/**/
+ (void) setLocalTime: (datetime_t) aLocalTime
{
#ifdef __UCLINUX  
	time_t aux = aLocalTime + TIMEZONE;
	stime(&aux);
	if ( system("rtc -w") == -1) {
		//doLog(0, "Error al intentar configurar el Real Time Clock\n");
	}
#else
	time_t aux = aLocalTime;
	stime(&aux);
#endif

}

/**/
+ (void) setGMTTime: (datetime_t) aGMTTime
{
	time_t aux = aGMTTime;
	stime(&aux);
#ifdef __UCLINUX
	if ( system("rtc -w") == -1) {
		//doLog(0, "Error al intentar configurar el Real Time Clock\n");
	}
#endif

}

/**/
+ (datetime_t) getGMTTime
{
#ifdef __UCLINUX
	return time(NULL);
#else
	char *tz;

	tz = getenv("TZ");
	setenv("TZ", "", 1);
	tzset();

	return time(NULL);
#endif

}

/**/
+ (datetime_t) encodeTime: (int) aYear mon: (int) aMon day: (int) aDay
							 hour: (int) anHour min: (int) aMin sec: (int) aSec
{
	struct tm brokenTime;

	brokenTime.tm_year = aYear - 1900;
	brokenTime.tm_mon  = aMon -1;
	brokenTime.tm_mday = aDay;
	brokenTime.tm_hour = anHour;
	brokenTime.tm_min  = aMin;
	brokenTime.tm_sec  = aSec;

	return mktime(&brokenTime);
	
}

/**/
+ (struct tm*) decodeTime: (datetime_t) aDateTime brokenTime: (struct tm*) aBrokenTime
{
	gmtime_r(&aDateTime, aBrokenTime);
	return aBrokenTime;
}

/**/
+ (datetime_t) convertToLocalTime: (datetime_t) aGMTTime
{
  long result = aGMTTime - TIMEZONE;
  
  if (result < 0) return 0;
     
	return result;	
}

/**/
+ (datetime_t) convertToGMTTime: (datetime_t) aLocalTime
{
	return aLocalTime + TIMEZONE;
}

/**/
+ (int) getTimeZone
{
	return TIMEZONE;	
}

/**/
+ (void) checkCurrentTime
{
	datetime_t now = [SystemTime getLocalTime];
	struct tm brokenTime;
	
	[SystemTime decodeTime: now brokenTime: &brokenTime];

	if (brokenTime.tm_year < 105 || brokenTime.tm_year > 150)
	{
		THROW(INVALID_CURRENT_TIME_EX);
	}
	
}

@end
