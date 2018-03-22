#ifndef  JTIME_H__
#define  JTIME_H__

#define  JTIME  id

#include "OTimer.h"
#include "JText.h"
#include "system/os/all.h"

#define JTime_SeparatorLen					5
#define JTime_DefaultSeparator 			":"

typedef enum {
 TimeOperationMode_DATE_TIME,
 TimeOperationMode_HOUR_MIN_SECOND,
 TimeOperationMode_SECONDS_MODE  
}	TimeOperationModeType;

/**
 * Implementa una cajita de texto para ingresar fechas.
 *
 **/
@interface  JTime: JText
{
	OTIMER							mySystemModeTimer;
	BOOL								mySystemTimeMode;
	
	/* Atributo privado que se utiliza para cuando esta en mySystemTimeMode = TRUE, asi
	   imprime la hora por mas que sea cero.
		 En myDurationTimeMode = FALSE si la hora es cero no la imprime */
	int									myDurationTimeMode;

	datetime_t   				myTimeValue;		
	char								myTimeSeparator[JTime_SeparatorLen + 1];
	OMUTEX							myMutex;
	BOOL								myIsFree;
/********************/
  int myOperationMode;
  datetime_t myDateTimeValue;
  char myHours[3];
  char myMinutes[3];
  char mySeconds[3];  
  
  BOOL myShowHours;
  BOOL myShowMinutes;
  BOOL myShowSeconds;
}

/**
 * Configura el separador de horas
 * Por defecto viene configurado con ':' para hacer hh/mm/ss
 */
- (void) setTimeSeparator: (char *) aValue;
- (char *) getTimeSeparator;

/**
 * Si systemTimeMode es TRUE entonces el componente actualiza la hora del 
 * sistema automaticamente, siempre y cuando este en estado readOnly.
 */
- (void) setSystemTimeMode: (BOOL) aValue;
- (BOOL) getSystemTimeMode;

/**
 * Configura la hora del componente
 */

- (datetime_t) getDateTimeValue;

/**
 * Devuelve el tiempo en un buffer 
 */
- (char*) getTimeAsString: (char*) aBuffer;

/**
 *
 */
- (BOOL) isTimeCorrect; 

/**/
- (void) setDurationTimeMode: (BOOL) aValue;

/**
 * 0 - DATE_TIME_MODE
 * 1 - HOUR_SECOND_MODE
 * 2 - SECONDS_MODE  
 */
- (void) setOperationMode: (int) aValue;

/**/
- (void) setDateTimeValue: (datetime_t) aDateTimeValue;

/**/
- (void) setTimeValue: (unsigned long) hours minutes: (unsigned long) minutes seconds: (unsigned long) seconds;

/**/
- (void) setShowConfig: (BOOL) aShowHours showMinutes: (BOOL) aShowMinutes showSeconds: (BOOL) aShowSeconds;

- (unsigned long) getTimeValue;

- (void) getTextAsTime;

- (int) getHours;
- (int) getMinutes;
- (int) getSeconds;
 
@end

#endif

