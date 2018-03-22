#ifndef PRINTER_EXCEPTS_H
#define PRINTER_EXCEPTS_H

#include "system/lang/all.h"

#define PRINTER_EXCEPTS 		8000

#define PRINTER_MAX_RETRIES_QTY_EX	  		                (PRINTER_EXCEPTS)
#define PRINTER_DRIVER_ERROR_EX           		            (PRINTER_EXCEPTS + 1) 
#define PRINTER_OUT_OF_PAPER_EX           		            (PRINTER_EXCEPTS + 2)
#define CANNOT_REMOVE_XML_FILE_EX	  		                  (PRINTER_EXCEPTS + 3)
#define ERROR_PARSING_DOCUMENT_EX         		            (PRINTER_EXCEPTS + 4)
#define ERROR_LOADING_FORMAT_FILE_EX      		            (PRINTER_EXCEPTS + 5)
#define ERROR_LOADING_XML_FILE_EX         		            (PRINTER_EXCEPTS + 6)
#define PRINTER_NEEDS_CLOSE_Z_EX	  		                  (PRINTER_EXCEPTS + 7)
#define PRINTER_FATAL_ERROR_EX		  		                  (PRINTER_EXCEPTS + 8)
#define PRINTER_OUT_OF_LINE_EX                            (PRINTER_EXCEPTS + 9)
#define PRINTER_INTERNAL_FATAL_ERROR_EX                   (PRINTER_EXCEPTS + 10)
#define PENDING_PRINTINGS_EX                              (PRINTER_EXCEPTS + 11)

#endif
