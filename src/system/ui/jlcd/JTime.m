#include <stdio.h>
#include <assert.h>
#include <ctype.h>
#include <limits.h>
#include <time.h>

#include "util.h"
#include "UserInterfaceExcepts.h"
#include "JTime.h"
#include "SystemTime.h"

//#define printd(args...) doLog(args)
#define printd(args...)

#define HOUR_POS		0
#define MIN_POS			3
#define SEC_POS		  6

@implementation  JTime


/**
 * Se ejecuta cuando expira el timer en modo  SystemModeTimer
 */
- (void) systemTimerExpires;

/**/
- (struct tm*) getTextAsDateTime: (struct tm*) aBrokenTime;

/**/
- (void) initComponent
{
	[super initComponent];

	myIsFree = FALSE;

	myMutex = [OMutex new];
 
	myCanFocus = TRUE;	
	myCurrentPosition = 0;
	
	mySystemTimeMode = FALSE;	
	mySystemModeTimer = [OTimer new];
	[mySystemModeTimer initTimer: PERIODIC period: 500 object: self callback: "systemTimerExpires"];	
	assert(mySystemModeTimer != NULL);

	myDurationTimeMode = FALSE;
	myIsNumericMode	= TRUE;
	
	myTimeValue = [SystemTime getLocalTime];
	stringcpy(myTimeSeparator, JTime_DefaultSeparator);	

	[self systemTimerExpires];	
  myWidth = 8;
  
  myOperationMode = TimeOperationMode_DATE_TIME;
  
  myShowHours = TRUE;
  myShowMinutes = TRUE;
  myShowSeconds = TRUE;
}

/**/
- free
{
	[myMutex lock];
	myIsFree = TRUE;
	[mySystemModeTimer stop];
	[mySystemModeTimer free];
	[myMutex unLock];
	[myMutex free];
	return [super free];
}

/**/
- (void) setSystemTimeMode: (BOOL) aValue 
{
	if (aValue) {
		myDurationTimeMode = TRUE;
		[mySystemModeTimer start];
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
- (void) setTimeSeparator: (char *) aValue { stringcpy(myTimeSeparator, aValue);	}
- (char *) getTimeSeparator { return myTimeSeparator; }


/**/
- (datetime_t) getDateTimeValue 
{ 
	struct tm brokenTime;

	[self doValidate];
	[self getTextAsDateTime: &brokenTime];

	return mktime(&brokenTime);	
}

/**/
- (unsigned long) getTimeValue
{
  int h, m, s;
  
  [self getTextAsTime];
  
  s = atoi(mySeconds);
  m = atoi(myMinutes) * 60;
  h = atoi(myHours) * 3600;
  
  return s + m + h;
}

/**/
- (char*) getTimeAsString: (char*) aBuffer
{
  struct tm brokenTime;  
  
  if ( myOperationMode == TimeOperationMode_DATE_TIME ) {
  
    localtime_r(&myTimeValue, &brokenTime);
    
    if (myTimeValue / 60 > 59 || myDurationTimeMode) 
            strftime (aBuffer, 9 , "%H:%M:%S", &brokenTime );
    else
            strftime (aBuffer, 9 , "%M:%S   ", &brokenTime );
  } else {
  
    if ( myShowHours ) 
     strcat(myText, myHours);
   
    if ( myShowMinutes ) {
    
      if ( myShowHours )
        strcat(myText, myTimeSeparator);
    
      strcat (myText, myMinutes);            
    }    
  
    if ( myShowSeconds ) {
  
      if ( myShowMinutes) 
        strcat(myText, myTimeSeparator);
    
      strcat(myText, mySeconds);            
    }
  }

  return aBuffer;
}

/**/
- (void) systemTimerExpires
{
	[myMutex lock];
	if (!myIsFree) [self setDateTimeValue: [SystemTime getLocalTime]];
	[myMutex unLock];
}

/**/
- (void) onChangeLockComponent: (BOOL) isLocked
{
	if (!mySystemTimeMode)
		return;
	
	//if (!isLocked) {
/*	if (isLocked) {
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

	if (myCurrentPosition < strlen(myText) - 1)		{
			myCurrentPosition++;
			if ((myCurrentPosition == MIN_POS-1 || myCurrentPosition == SEC_POS-1)) 
        myCurrentPosition++;
	}
	
	myIsNewPosition = TRUE;
	return TRUE;
}

/**/
- (BOOL) setLeftKeyPressed
{				
	if (myCurrentPosition > 0) {
		myCurrentPosition--;
		if (myCurrentPosition == MIN_POS-1 || myCurrentPosition == SEC_POS-1) myCurrentPosition--;
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

- (void) getTextAsTime
{
  int pos = 0;
  
  if ( myShowHours ) {
	 strcpy(myHours, &myText[pos]);
	 myHours[2] = '\0';
   pos+=3;
  }   

  if ( myShowMinutes ) {
	 strcpy(myMinutes, &myText[pos]);
	 myMinutes[2] = '\0';
   pos+=3;
  }   

  if ( myShowSeconds ) {
	 strcpy(mySeconds, &myText[pos]);
	 mySeconds[2] = '\0';
  }   
  
}

/**/
- (struct tm*) getTextAsDateTime: (struct tm*) aBrokenTime
{
	char aux[20];
  
	// La hora
	strcpy(aux, &myText[HOUR_POS]);
	aux[2] = '\0';
	aBrokenTime->tm_hour = atoi(aux);

	// Los minutos
	strcpy(aux, &myText[MIN_POS]);
	aux[2] = '\0';
	aBrokenTime->tm_min = atoi(aux);

	// Los segundos
	strcpy(aux, &myText[SEC_POS]);
	aux[2] = '\0';
	aBrokenTime->tm_sec = atoi(aux);
	
	aBrokenTime->tm_year = 70;
	aBrokenTime->tm_mon  = 0;
	aBrokenTime->tm_mday = 1;
	
	return aBrokenTime;
	
}

/**/
- (BOOL) isTimeCorrect
{
	struct tm brokenTime;
	struct tm auxBrokenTime;
	
  if ( myOperationMode == TimeOperationMode_DATE_TIME ) {
  
    [self getTextAsDateTime: &brokenTime];
    
    auxBrokenTime.tm_mon  = 0;
    auxBrokenTime.tm_mday = 1;
    auxBrokenTime.tm_year = 70;
    auxBrokenTime.tm_hour = brokenTime.tm_hour;
    auxBrokenTime.tm_min  = brokenTime.tm_min;
    auxBrokenTime.tm_sec  = brokenTime.tm_sec;
    
    if (mktime(&auxBrokenTime) == -1) return FALSE;
  
    if (brokenTime.tm_hour != auxBrokenTime.tm_hour) return FALSE;
    if (brokenTime.tm_min != auxBrokenTime.tm_min) return FALSE;
    if (brokenTime.tm_sec != auxBrokenTime.tm_sec) return FALSE;
    
    return TRUE;
  }
  
  
  // Para considerarse correcta la duracion, la cantidad de minutos y de segundos debe ser menor a 60.
  if ( ([self getMinutes] < 60) && ([self getSeconds] < 60) ) return TRUE;
  
  return FALSE;
}

/**/
- (void) setDurationTimeMode: (BOOL) aValue
{
  myDurationTimeMode = aValue;
}

/**/
- (void) setOperationMode: (int) aValue
{
  myOperationMode = aValue;
}

/**/
- (void) setDateTimeValue: (datetime_t) aDateTimeValue
{
	struct tm brokenTime;
	
  
  if (aDateTimeValue < 0)
	 THROW( UI_INDEX_OUT_OF_RANGE_EX );
			
	myDateTimeValue = aDateTimeValue;

	localtime_r(&myDateTimeValue, &brokenTime);

	if (myDateTimeValue / 60 > 59 || myDurationTimeMode) 
		strftime (myText, sizeof(myText) - 1, "%H:%M:%S", &brokenTime );
	else
		strftime (myText, sizeof(myText) - 1, "%M:%S   ", &brokenTime );

	[self paintComponent];  
}

/**/
- (void) setTimeValue: (unsigned long) hours minutes: (unsigned long) minutes seconds: (unsigned long) seconds
{
  unsigned long aux;
  
  stringcpy(myText, "");
  
  if ( myOperationMode == TimeOperationMode_HOUR_MIN_SECOND ) {
    sprintf(myHours, "%02ld", hours);
    sprintf(myMinutes, "%02ld", minutes);
    sprintf(mySeconds, "%02ld", seconds);
  } 
  
  if ( myOperationMode == TimeOperationMode_SECONDS_MODE ) {
    aux = seconds - ((seconds / 60) / 60) * 3600;
    sprintf(myHours, "%02ld", (seconds / 60) / 60);
    sprintf(myMinutes, "%02ld", aux / 60);
    sprintf(mySeconds, "%02ld", aux % 60);   
    
  }
  
  [self getTimeAsString: myText];

  [self paintComponent];  
}

/**/
- (void) setShowConfig: (BOOL) aShowHours showMinutes: (BOOL) aShowMinutes showSeconds: (BOOL) aShowSeconds
{

  myShowHours = aShowHours;
  myShowMinutes = aShowMinutes;
  myShowSeconds = aShowSeconds;
  
}

/**/
- (int) getHours
{
  [self getTextAsTime];
  return atoi(myHours);
}

/**/
- (int) getMinutes
{
  [self getTextAsTime];
  return atoi(myMinutes);
}

/**/
- (int) getSeconds
{
  [self getTextAsTime];
  return atoi(mySeconds);
}



@end

