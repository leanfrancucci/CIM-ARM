#include "SerialDriver.h"
#include <stdlib.h>
#include "util.h"
#include "PrinterExcepts.h"
#include "string.h"
#include "PrinterSpooler.h"

#define SERIAL_FORMAT_SUBDIRECTORY "standard/"


#define	DBL_HEIGHT_ON_CODE  		"\x1B\x40\x1D\x21\x01"
#define	FEED_LINE_CODE 			"\x1B\x64\03"
#define	CUT_PAPER_CODE 			"\x1B\x69"
#define	CHAR_SPACE_CODE 		"\x1B\x40\x1B\x20\01"

@implementation SerialDriver

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
  return self;
}

/**/
- (void) setReader: (id) aReader
{
  myReader = aReader;
}

/**/
- (void) setWriter: (id) aWriter
{
  myWriter = aWriter;
} 


/**/
- (void) printText: (char*) aText
{
	int size;
	char *to;
  char *p = aText;

	while ( *p != '\0' ) {

		// Encuentro el proximo fin de linea
		to = strchr(p, '\n');

		// Si no existe, busco el fin de cadena
		if (to == NULL) to = strchr(p, '\0');
		else to++;

		// Escribo en la impresora
		size = to - p;

		[myWriter write: p qty: size];

		p = to;

		msleep(10);
	}
	[myWriter write: CUT_PAPER_CODE qty: 2];
	
	
	msleep(1000);
}

/**/
- (char*) getFormatSubdirectory: (char*) aFormatSubdirectory
{
  char buff[50];
  
  buff[0] = '\0';
  strcpy(buff, SERIAL_FORMAT_SUBDIRECTORY);
	strcat(buff, [[PrinterSpooler getInstance] getReportPathByLanguage]);
	strcpy(aFormatSubdirectory, buff);
  return aFormatSubdirectory;
}

/**/
- (void) advancePaper: (int) aQty
{
	int i;
	char *text = malloc(aQty*2);
	
	text[0] = '\0';
	
	for (i=0; i<aQty; ++i)
			strcat(text, " \n");
	
	[myWriter write: text qty: aQty]; 
	
	free(text);
} 

- (char*) getEscapeCode: (char*) aEscapeCodeTag escapeCode: (char*) aEscapeCode
{
  char escCode[30];
  
  strcpy(escCode, "");
	printf("SERIAL PRINTER vdfds>>>>>>>>>>> escape code setted %s\n", aEscapeCodeTag);

  if ( strcmp(aEscapeCodeTag, DBL_HEIGHT_ON) == 0 )
    strcpy(escCode, DBL_HEIGHT_ON_CODE);    
 
  if ( strcmp(aEscapeCodeTag, FEED_LINE) == 0 )
    strcpy(escCode, FEED_LINE_CODE);        
  
  if ( strcmp(aEscapeCodeTag, CUT_PAPER) == 0 )
    strcpy(escCode, CUT_PAPER_CODE);          

  if ( strcmp(aEscapeCodeTag, CHAR_SPACE) == 0 ) 
    strcpy(escCode, CHAR_SPACE_CODE);

  strcpy(aEscapeCode, escCode);   

    
  return aEscapeCode;          

}

/**/
- (void) advancePaper
{
	[self advancePaper: 10];
}

- (void) printLogo: (char*) aFileName
{
    printf("PrintLogo!!! Serial Driver >>>>>>>>>>>>>>>>>\n");
//  [printer printLogo: aFileName];
} 

@end
