#ifndef PARALLEL_PORT_API_H
#define PARALLEL_PORT_API_H

#include "osrt.h"

/**
 *
 */
OS_HANDLE lpt_open();

/**
 *
 */
int lpt_read(OS_HANDLE handle, char *buffer, int qty);

/**
 *
 */
int lpt_write(OS_HANDLE handle, char *buffer, int qty);

/**
 *
 */
void lpt_close(OS_HANDLE handle);


#endif

