#include "ThermalDriver.h"
#include <stdlib.h>
#include "util.h"
#include "PrinterExcepts.h"
#include "string.h"
#include "PrinterSpooler.h"

#define LOG(args...) logCategory("LOG_PRINTER", FALSE, args)

#define THERMAL_FORMAT_SUBDIRECTORY "thermal/"

/* Codigos de escape de la impresora termina */		
#define	BOLD_ON_CODE  			"\x1D\x66\x04"
#define	BOLD_OFF_CODE 			"\x1D\x66\x01"
#define	DBL_HEIGHT_ON_CODE 	"\x1B\x21\x10"
#define	DBL_HEIGHT_OFF_CODE	"\x1B\x21\x01"
#define BOLD_DBL_HEIGHT_CODE "\x1B\x21\x18"
#define	CLEAR_FORMAT_CODE		"\x1B\x21\x01"
#define BAR_CODE_ITF_CODE "\x1D\x6B\x05"
#define ITALIC_FONT_CODE "\x1D\x66\x09"
#define STANDARD_FONT_CODE "\x1D\x66\01"	
#define COURIER_FONT_CODE "\x1D\x66\03"	
#define VERDANA_SMALL_FONT_CODE "\x1D\x66\x07"	
#define VERDANA_BIG_FONT_CODE 	"\x1D\x66\x08"
#define TAHOMA_FONT_CODE 	"\x1D\x66\x09"	
#define BITSTREAM_FONT_CODE 	"\x1D\x66\xB"	
#define COMIC_FONT_CODE 	"\x1D\x66\xC"	
#define INVERSE_ON_CODE   "\x1C" "\x01" "1"
#define INVERSE_OFF_CODE  "\x1C" "\x01" "0"
#define COURIER_8x16_FONT_CODE "\x1D\x66\02"

char *strdup(const char *s);

@implementation ThermalDriver

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
    printf("ThermalDriver initialize\n");
  printer = [Printer getInstance];
  return self;
}

/**/
- (void) printText: (char*) aText
{
  int result;

	result = [printer print: aText];
  
  if ( result != 0 ) 
   THROW(PRINTER_OUT_OF_PAPER_EX);
  
	LOG("%s",aText);


}

/**/
- (void) clean
{
	[printer cleanQueue];
}

/**/
- (char*) getEscapeCode: (char*) aEscapeCodeTag escapeCode: (char*) aEscapeCode
{
  char escCode[30];
  
  strcpy(escCode, "");
#ifndef __LINUX

 	if ( strcmp(aEscapeCodeTag, BOLD_ON) == 0 ) 
    strcpy(escCode, BOLD_ON_CODE);

  if ( strcmp(aEscapeCodeTag, BOLD_OFF) == 0 )
    strcpy(escCode, BOLD_OFF_CODE);
    
  if ( strcmp(aEscapeCodeTag, DBL_HEIGHT_ON) == 0 )
    strcpy(escCode, DBL_HEIGHT_ON_CODE);    
 
  if ( strcmp(aEscapeCodeTag, DBL_HEIGHT_OFF) == 0 )
    strcpy(escCode, DBL_HEIGHT_OFF_CODE);        
  
  if ( strcmp(aEscapeCodeTag, CLEAR_FORMAT) == 0 )
    strcpy(escCode, CLEAR_FORMAT_CODE);          

  if ( strcmp(aEscapeCodeTag, BAR_CODE_ITF) == 0 ) 
    strcpy(escCode, BAR_CODE_ITF_CODE);
  if ( strcmp(aEscapeCodeTag, ITALIC_FONT) == 0 ) 
    strcpy(escCode, ITALIC_FONT_CODE);

  if ( strcmp(aEscapeCodeTag, STANDARD_FONT) == 0 ) 
    strcpy(escCode, STANDARD_FONT_CODE);

  if ( strcmp(aEscapeCodeTag, COURIER_FONT) == 0 ) 
    strcpy(escCode, COURIER_FONT_CODE);

  if ( strcmp(aEscapeCodeTag, VERDANA_SMALL_FONT) == 0 ) 
    strcpy(escCode, VERDANA_SMALL_FONT_CODE);

  if ( strcmp(aEscapeCodeTag, VERDANA_BIG_FONT) == 0 ) 
    strcpy(escCode, VERDANA_BIG_FONT_CODE);

  if ( strcmp(aEscapeCodeTag, TAHOMA_FONT) == 0 ) 
    strcpy(escCode, TAHOMA_FONT_CODE);

  if ( strcmp(aEscapeCodeTag, BITSTREAM_FONT) == 0 ) 
    strcpy(escCode, BITSTREAM_FONT_CODE);

  if ( strcmp(aEscapeCodeTag, COMIC_FONT) == 0 ) 
    strcpy(escCode, COMIC_FONT_CODE);

  if ( strcmp(aEscapeCodeTag, INVERSE_ON) == 0 ) 
    strcpy(escCode, INVERSE_ON_CODE);

  if ( strcmp(aEscapeCodeTag, INVERSE_OFF) == 0 ) 
    strcpy(escCode, INVERSE_OFF_CODE);
    
  if ( strcmp(aEscapeCodeTag, COURIER_8x16_FONT) == 0 ) 
    strcpy(escCode, COURIER_8x16_FONT_CODE);    

#endif

  strcpy(aEscapeCode, escCode);   
  return aEscapeCode;          
}

/**/
- (void) advancePaper: (int) aQty
{
	int result = 0;
	int i;
	char *text = malloc(aQty*2 + 1);
	
	text[0] = '\0';
	
	for (i=0; i<aQty; ++i)
			strcat(text, " \n");
	
    
	result = [printer print: text];
	
	free(text);
	
	if ( result != 0 )
		THROW(PRINTER_OUT_OF_PAPER_EX);

} 

/**/
- (void) advancePaper
{
	[self advancePaper: 10];
}

/**/
- (char*) getFormatSubdirectory: (char*) aFormatSubdirectory
{
  char buff[50];
  
  buff[0] = '\0';
  strcpy(buff, THERMAL_FORMAT_SUBDIRECTORY);
  strcat(buff, [[PrinterSpooler getInstance] getReportPathByLanguage]);
  strcpy(aFormatSubdirectory, buff);
  return aFormatSubdirectory;
}

/**/
- (void) printBarCode: (char*) aBarCode
{
	[printer print: aBarCode];
}

/**/
- (void) printLogo: (char*) aFileName
{
#ifdef __LINUX
	[printer print: "** LOGO **\n"]; 
#else
  [printer printLogo: aFileName];
#endif
} 

@end
