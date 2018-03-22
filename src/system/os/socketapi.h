#ifndef OSSOCKET_H
#define OSSOCKET_H

#include <stdlib.h>

/**/
int sock_socket(void);

/**/
int sock_connect (int socket, int port, char *host);

/**/
int sock_accept (int socket);

/**/
int sock_bind(int socket, int port);

/**/
int sock_listen(int socket, int n);

/**/
/*ssize_t*/ size_t sock_write(int filedes, const void *buffer, size_t size);

/**/
/*ssize_t*/ size_t sock_read (int filedes, void *buffer, size_t size);

/**/
int sock_shutdown (int socket, int how);

/**/
int sock_close (int filedes);

int sock_get_remote_ip_addr(int socket, char *buffer);
int sock_get_remote_host_name(int socket, char *buffer);

int sock_set_read_timeout(int socket, int seconds);
int sock_set_write_timeout(int socket, int seconds);

#endif
