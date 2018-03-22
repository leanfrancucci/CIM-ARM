#ifndef  JDATE_H__
#define  JDATE_H__

#define  JDATE  id

#include "OTimer.h"
#include "JText.h"

#define JDate_SeparatorLen					5
#define JDate_DefaultSeparator 			"/"


typedef enum {

	 JDate_FirstInvalidFormat		= 0
	
	,JDate_UEShortFormat			 			/* dd/mm/yy */
	,JDate_USAShortFormat						/* mm/dd/yy */
	,JDate_UELongFormat							/* dd/mm/yyyy */
	,JDate_USALongFormat						/* mm/dd/yyyy */
	
	,JDate_LastInvalidFormat
	
	
} JDate_Format;

/**
 * Implementa una cajita de texto para ingresar fechas.
 *
 **/
@interface  JDate: JText
{
	OTIMER							mySystemModeTimer;
	BOOL								mySystemTimeMode;
	
	JDate_Format				myDateFormat;
	datetime_t   				myDateValue;	
	char								myDateSeparator[JDate_SeparatorLen + 1];
}

/**
 * Configura el separador de fechas
 * Por defecto viene configurado con '/' para hacer xx/mm/aa
 */
- (void) setDateSeparator: (char *) aValue;
- (char *) getDateSeparator;

/**
 * Configura el formato de fecha.
 */
- (void) setJDateFormat: (JDate_Format) aValue;
- (JDate_Format) getJDateFormat;

/**
 * Si systemTimeMode es TRUE entonces el componente actualiza la hora del 
 * sistema automaticamente, siempre y cuando este en estado readOnly.
 */
- (void) setSystemTimeMode: (BOOL) aValue;
- (BOOL) getSystemTimeMode;

/**
 * Configura la fecha del componente
 */
- (void) setDateValue: (datetime_t) aValue;
- (datetime_t) getDateValue;

/**
 *
 */
- (BOOL) isDateCorrect; 

@end

#endif

