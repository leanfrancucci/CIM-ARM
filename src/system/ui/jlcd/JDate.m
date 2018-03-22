#include <stdio.h>
#include <assert.h>
#include <ctype.h>
#include <limits.h>
#include <time.h>

#include "util.h"
#include "UserInterfaceExcepts.h"
#include "JDate.h"
#include "SystemTime.h"

//#define printd(args...) doLog(args)
#define printd(args...)

#define MON_POS			3
#define DAY_POS			0
#define YEAR_POS		6

#define YEAR_LEN		4

@implementation  JDate

/**
 * Se ejecuta cuando expira el timer en modo  SystemModeTimer
 */
- (void) systemTimerExpires;

/**/
- (struct tm*) getTextAsDate: (struct tm*) aBrokenTime;

/**/
- (void) initComponent
{
 [super initComponent];

	myCanFocus = TRUE;	
	myCurrentPosition = 0;
	
	mySystemTimeMode = FALSE;
	myIsNumericMode	= TRUE;
	
	mySystemModeTimer = [OTimer new];
	[mySystemModeTimer initTimer: PERIODIC period: 850 object: self callback: "systemTimerExpires"];
	assert(mySystemModeTimer != NULL);
	
	myDateFormat = JDate_UEShortFormat;
	myDateValue = [SystemTime getLocalTime];
	stringcpy(myDateSeparator, JDate_DefaultSeparator);	
	
	snprintf(myText, sizeof(myText) - 1, "%02d%s%02d%s%04d", 1, myDateSeparator, 1, myDateSeparator, 2000);
	myWidth = strlen(myText);
}

/**/
- free
{
	[mySystemModeTimer stop];
	[mySystemModeTimer free];
	return [super free];
}

/**/
- (void) setSystemTimeMode: (BOOL) aValue 
{ 
	if (aValue) {
		[mySystemModeTimer start];
		[self systemTimerExpires];
	} else
		[mySystemModeTimer stop];

	mySystemTimeMode = aValue;
}

/**/
- (BOOL) getSystemTimeMode 
{ 
	return mySystemTimeMode; 
}


  /**/
- (void) setDateSeparator: (char *) aValue { stringcpy(myDateSeparator, aValue);	}
- (char *) getDateSeparator { return myDateSeparator; }

/**/
- (void) setJDateFormat: (JDate_Format) aValue
{ 
		if (myDateFormat <= JDate_FirstInvalidFormat ||  myDateFormat >= JDate_LastInvalidFormat)
			THROW( UI_INDEX_OUT_OF_RANGE_EX );
		
		myDateFormat = aValue;		
};
- (JDate_Format) getJDateFormat { return myDateFormat; }

/**/
- (void) setDateValue: (datetime_t) aValue
{
	struct tm brokenTime;

	if (aValue < 0)
			THROW( UI_INDEX_OUT_OF_RANGE_EX );

	myDateValue = truncDateTime(aValue);
	
	localtime_r(&myDateValue, &brokenTime);

	if (myDateFormat == JDate_USAShortFormat)
		strftime(myText, sizeof(myText) - 1, "%m/%d/%Y", &brokenTime);
	else 
		strftime(myText, sizeof(myText) - 1, "%d/%m/%Y", &brokenTime);

	[self paintComponent];
}


/**/
- (datetime_t) getDateValue
{ 
	struct tm brokenTime;

	[self doValidate];
	[self getTextAsDate: &brokenTime];

	return mktime(&brokenTime);
}

/**/
- (void) systemTimerExpires
{	
	[self setDateValue: [SystemTime getLocalTime]];
}

/**/
- (void) onChangeLockComponent: (BOOL) isLocked
{
	if (!mySystemTimeMode)
		return;
	
	/*if (!isLocked) {
		[mySystemModeTimer start];	
		[self systemTimerExpires];		
	} else
		[mySystemModeTimer stop];
	*/
}

/**/
- (void) doReadOnlyMode: (BOOL) aValue
{
	if (!mySystemTimeMode) return;
	
	if (aValue)
		[mySystemModeTimer start];
	else
		[mySystemModeTimer stop];
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) isPressed
{
	int result;

	if (myReadOnly) return FALSE;

	result = FALSE;

	switch (aKey)
	{
	 
		case JComponent_TAB:										/* TAB */
		case JComponent_SHIFT_TAB:							/* SHIFT TAB */
	
			if (!myReadOnly) [self validateComponent];
			result = FALSE;
			break;
	
		case 	JText_KEY_LEFT:									/* Cursor izquierda */
		
			result = [self setLeftKeyPressed];
			break;
	
		case JText_KEY_RIGHT:									/* Cursor derecha */

			result = [self setRightKeyPressed];
			break;

		case JText_KEY_DELETE:							/* Delete */

			//result = [self setDeleteKeyPressed];
			break;

		default:
	
			result = [self setNewKeyPressed: aKey];
			break;
			
	}
	
	[self setNewCursorPosition];
					
	return result;


}

/**/
- (BOOL) setRightKeyPressed
{
	if (myCurrentPosition < strlen(myText))		{
			myCurrentPosition++;
			if (myCurrentPosition == 2 || myCurrentPosition == 5) myCurrentPosition++;
	}
	
	myIsNewPosition = TRUE;
	return TRUE;
}

/**/
- (BOOL) setLeftKeyPressed
{				
	if (myCurrentPosition > 0) {
		myCurrentPosition--;
		if (myCurrentPosition == 2 || myCurrentPosition == 5) myCurrentPosition--;
	}
	
	myIsNewPosition = TRUE;
	return TRUE;
}

/**/
- (BOOL) setNewKeyPressed: (char) aKey
{
	
	if (aKey < ' ' || (myIsNumericMode && !isdigit(aKey))) return FALSE;

	if (myCurrentPosition >= strlen(myText)) return TRUE;
	
	myText[myCurrentPosition] = aKey;
	myText[myMaxLen] = '\0';		
	
	myIsNewPosition = FALSE;
	
	/** si es modo numerico pasa directo al caracter de al lado */
	if (myIsNumericMode) [self setRightKeyPressed];
	
	[self executeOnChangeAction];
	
	return TRUE;
}

/**/
- (struct tm*) getTextAsDate: (struct tm*) aBrokenTime
{
	char aux[20];
	int year;
	int dayPos;
	int monPos;

	if (myDateFormat == JDate_USAShortFormat) {
		dayPos = 3;
		monPos = 0;
	} else {
		dayPos = 0;
		monPos = 3;
	}

	// El dia 
	strcpy(aux, &myText[dayPos]);
	aux[2] = '\0';
	aBrokenTime->tm_mday = atoi(aux);

	// El mes
	strcpy(aux, &myText[monPos]);
	aux[2] = '\0';
	aBrokenTime->tm_mon = atoi(aux) - 1;

	// El ano
	strcpy(aux, &myText[YEAR_POS]);
	aux[YEAR_LEN] = '\0';
	if (YEAR_LEN == 4) year = atoi(aux);
	if (YEAR_LEN == 2) {
		year = atoi(aux);
		if (year < 30) year = year + 2000; else year = year + 1900;
	}
	
	aBrokenTime->tm_year = year - 1900;
	
	aBrokenTime->tm_hour = 0;
	aBrokenTime->tm_min  = 0;
	aBrokenTime->tm_sec  = 0;
	
	return aBrokenTime;
	
}

/**/
- (BOOL) isDateCorrect
{
	struct tm brokenTime;
	struct tm auxBrokenTime;
	
	[self getTextAsDate: &brokenTime];
	
	if (brokenTime.tm_mon < 0 || brokenTime.tm_mon > 11) return FALSE;
	if (brokenTime.tm_mday < 1 || brokenTime.tm_mday > 31) return FALSE;
	if (brokenTime.tm_year < 1 || brokenTime.tm_year > 140) return FALSE;

	auxBrokenTime.tm_mon = brokenTime.tm_mon;
	auxBrokenTime.tm_mday = brokenTime.tm_mday;
	auxBrokenTime.tm_year = brokenTime.tm_year;
	auxBrokenTime.tm_hour = 0;
	auxBrokenTime.tm_min  = 0;
	auxBrokenTime.tm_sec  = 0;
	
	if (mktime(&auxBrokenTime) == -1) return FALSE;

	if (brokenTime.tm_mon != auxBrokenTime.tm_mon) return FALSE;
	if (brokenTime.tm_mday != auxBrokenTime.tm_mday) return FALSE;
	if (brokenTime.tm_year != auxBrokenTime.tm_year) return FALSE;
  
  return TRUE;
}

@end

