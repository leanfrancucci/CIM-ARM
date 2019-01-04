#ifndef ABSTRACT_PRINTER_DRIVER_H
#define ABSTRACT_PRINTER_DRIVER_H

#define ABSTRACT_PRINTER_DRIVER id

#define BOLD_ON							"BOLD_ON"
#define BOLD_OFF						"BOLD_OFF"
#define DBL_HEIGHT_ON				"DBL_HEIGHT_ON"
#define DBL_HEIGHT_OFF			"DBL_HEIGHT_OFF"
#define BOLD_DBL_HEIGHT_ON  "BOLD_DBL_HEIGHT_ON"
#define BOLD_DBL_HEIGHT_OFF "BOLD_DBL_HEIGHT_OFF"
#define CLEAR_FORMAT				"CLEAR_FORMAT"
#define VERDANA_FONT				"VERDANA_FONT"
#define ITALIC_FONT					"ITALIC_FONT"
#define STANDARD_FONT				"STANDARD_FONT"
#define COURIER_FONT				"COURIER_FONT"
#define VERDANA_SMALL_FONT 	"VERDANA_SMALL_FONT"	
#define VERDANA_BIG_FONT 		"VERDANA_BIG_FONT"
#define TAHOMA_FONT      		"TAHOMA_FONT"	
#define BITSTREAM_FONT 			"BITSTREAM_FONT"	
#define COMIC_FONT  				"COMIC_FONT"
#define INVERSE_ON					"INVERSE_ON"
#define INVERSE_OFF					"INVERSE_OFF"
#define COURIER_8x16_FONT		"COURIER_8x16_FONT"
#define FEED_LINE		"FEED_LINE"
#define CUT_PAPER		"CUT_PAPER"
#define CHAR_SPACE		"CHAR_SPACE"
#define LEFT_SPACE		"LEFT_SPACE"

#define BAR_CODE_ITF "BAR_CODE_ITF"


#include <Object.h>
#include "system/io/all.h"
#include "PrinterExcepts.h"

typedef enum {
  HEADER_PRINTING, 
  FOOTER_PRINTING
} HeaderFooterType;


/**
 *	
 */
@interface AbstractPrinterDriver : Object
{
}

/**
 * Inicializa en caso de ser necesario el driver.
 */ 
- (void) initDriver;

/**
 * Imprime texto comun que no representa un item fiscal
 */
- (void) printText: (char*) aText;

/**
 * Avanza el papel
 */
- (void) advancePaper;

/**
 * Avanza el papel la cantidad de lineas pasadas como parametro.
 */
- (void) advancePaper: (int) aQty;

/** 
 * Corta el papel
 */
- (void) cutPaper;  

/**
 * Limpia los buffers.
 */
- (void) clean;

/**
 * Abre el cajon de dinero.
 */
- (void) openCashDrawer;  

/**
 * Devuelve el codigo de escape del parametro aEscapeCodeTag
 */
- (char*) getEscapeCode: (char*) aEscapeCodeTag escapeCode: (char*) aEscapeCode;  

/**
 * Devuelve el subdirectorio donde se encuentran los archivos de formato
 */
- (char*) getFormatSubdirectory: (char*) aFormatSubdirectory; 

/**
 * Devuelve el ancho permitido de la impresora
 */
- (int) getPrinterWidth; 

/**
 *
 */
- (void) printLogo: (char*) aFileName;


@end

#endif
