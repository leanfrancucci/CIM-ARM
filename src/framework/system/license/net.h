/*
 * macAddressSys.h
 *
 * Return the MAC (ie, ethernet hardware) address by using system specific
 * calls.
 *
 * compile with: gcc -c -D "OS" mac_addr_sys.c
 * with "OS" is one of Linux, AIX, HPUX 
 */

#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <linux/if.h>

int if_netInfo  (char *intf , char *rslt);
