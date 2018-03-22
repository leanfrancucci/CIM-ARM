#ifndef NET_EXCEPTS_H
#define NET_EXCEPTS_H

#include "excepts.h"

#define NET_EXCEPT 	4000

#define SOCKET_EX							(NET_EXCEPT)
#define SOCKET_INIT_EX				(NET_EXCEPT + 1)
#define SOCKET_HOST_NAME_EX		(NET_EXCEPT + 2)
#define SOCKET_CONNECT_EX			(NET_EXCEPT + 3)
#define SOCKET_TIMEOUT_EX			(NET_EXCEPT + 4)

#endif
