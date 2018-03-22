#include "ParallelDriver.h"
#include <stdlib.h>
#include "util.h"
#include "PrinterExcepts.h"
#include "string.h"
#include "ParallelPortWriter.h"
#include "Configuration.h"

#define PARALLEL_FORMAT_SUBDIRECTORY "standard/"

@implementation ParallelDriver

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
  int i, j;

	/* Redirijo impresion a archivo en lugar de tirarlo en la impresora */
	if (strcmp([[Configuration getDefaultInstance] getParamAsString: "REDIRECT_PRINTER_TO_FILE" default: "no"], "yes") == 0) {
		FILE *f = fopen("printer.txt", "a+");
		if (!f) return;
		fprintf(f, "%s", aText);
		fclose(f);
		return;
	}
  
  // El puerto paralelo conviene abrirlo solamente cuando se va a imprimir
  // y cerrarlo inmediatemente despues de imprimir.

  TRY
    [[myWriter getParallelPort] open];
  CATCH
    THROW(PRINTER_OUT_OF_LINE_EX);
  END_TRY
  
  
	while ( *p != '\0' ) {

		// Encuentro el proximo fin de linea
		to = strchr(p, '\n');

		// Si no existe, busco el fin de cadena
		if (to == NULL) to = strchr(p, '\0');
		else to++;

		// Escribo en la impresora
		size = to - p;

    for (i=0; i<size; ++i) {
      if ( *p == '\n') {
        for (j=0; j<(40 - (size-1)); ++j) [myWriter write: " " qty: 1];
         
        [myWriter write: "\r" qty: 1];
      }        

      [myWriter write: p qty: 1];
      p++;
    }      
    
		//[myWriter write: p qty: size];

		p = to;

		msleep(30);
	}

  msleep(300);
  
  [[myWriter getParallelPort] close];
    
  
  //[myWriter write: aText qty: strlen(aText)];
  //[myWriter write: "\n\n\n\n\n\n" qty: 6];
  
}

/**/
- (char*) getFormatSubdirectory: (char*) aFormatSubdirectory
{
  strcpy(aFormatSubdirectory, PARALLEL_FORMAT_SUBDIRECTORY);
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
	
	[self printText: text];

	free(text);
} 

@end
