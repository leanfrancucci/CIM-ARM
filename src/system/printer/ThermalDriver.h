#ifndef THERMAL_DRIVER_H
#define THERMAL_DRIVER_H

#define THERMAL_DRIVER id

#include <Object.h>
#include "AbstractPrinterDriver.h"
#include "system/dev/Printer.h"


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
