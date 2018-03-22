#ifndef THERMAL_DRIVER_H
#define THERMAL_DRIVER_H

#define THERMAL_DRIVER id

#include <Object.h>
#include "AbstractPrinterDriver.h"
#include "system/dev/Printer.h"

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

/**
 *	
 */
@interface ThermalDriver : AbstractPrinterDriver
{
  PRINTER printer;
}

- (void) printBarCode: (char*) aBarCode;

- (void) printLogo: (char*) aFileName;

@end

#endif
