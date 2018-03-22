#include "SerialDriver.h"
#include <stdlib.h>
#include "util.h"
#include "PrinterExcepts.h"
#include "string.h"
#include "PrinterSpooler.h"

#define SERIAL_FORMAT_SUBDIRECTORY "standard/"

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

/**/
- (void) advancePaper
{
	[self advancePaper: 10];
}

@end
