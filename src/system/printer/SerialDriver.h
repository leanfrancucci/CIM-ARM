#ifndef SERIAL_DRIVER_H
#define SERIAL_DRIVER_H

#define SERIAL_DRIVER id

#include <Object.h>
#include "AbstractPrinterDriver.h"
#include "system/dev/Printer.h"

/**
 *	
 */
@interface SerialDriver : AbstractPrinterDriver
{
  id myReader;
  id myWriter;
}

- (void) printLogo: (char*) aFileName;

@end

#endif
