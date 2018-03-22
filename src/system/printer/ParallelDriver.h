#ifndef PARALLEL_DRIVER_H
#define PARALLEL_DRIVER_H

#define PARALLEL_DRIVER id

#include <Object.h>
#include "AbstractPrinterDriver.h"
#include "system/dev/Printer.h"

/**
 *	
 */
@interface ParallelDriver : AbstractPrinterDriver
{
  id myReader;
  id myWriter;
}

@end

#endif
