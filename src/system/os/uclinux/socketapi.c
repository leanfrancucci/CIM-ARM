#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <sys/time.h>
#include <stdio.h>
#include "socketapi.h"

#include "log.h"


/**/
int sock_socket(void)
{	 
	//socket(namespace, int style, int protocol);
	return socket(AF_INET, SOCK_STREAM, 0);
}

/**/
int sock_connect (int socket, int port, char *host)
{
	struct hostent *host_e;
	struct sockaddr_in saddr_in;
		
	host_e = gethostbyname(host);
	if (host_e == NULL) return -1;	
				 
	saddr_in.sin_family	= AF_INET;
	saddr_in.sin_addr		= *((struct in_addr *) *host_e->h_addr_list);
	saddr_in.sin_port		= htons((short) port);

	return connect(socket, (struct sockaddr *) &saddr_in, sizeof(struct sockaddr));
}

/**/
int sock_accept (int socket) 
{
	struct sockaddr_in remote_sa;
	int len;
	
	memset(&remote_sa, 0, sizeof(remote_sa));
	len = sizeof(remote_sa);
	return accept(socket, (struct sockaddr*)&remote_sa, &len);
}

/**/
int sock_bind(int socket, int port )
{
	struct sockaddr_in local_sa;
	int result;
	
	memset(&local_sa, 0, sizeof(local_sa));
	local_sa.sin_family = AF_INET;
	local_sa.sin_port = htons(port);
	local_sa.sin_addr.s_addr = INADDR_ANY;
	
	result = bind( socket, (struct sockaddr*)&local_sa, sizeof(local_sa));	
	return result;
}

/**/
int sock_listen( int socket, int n )
{
	return  listen( socket, n );
}
	
/**/
/*ssize_t*/ size_t sock_write(int filedes, const void *buffer, size_t size)
{
//	return write(filedes, buffer, size);
	/** REEMPLAZADO PARA QUE NO RECIBA UN SIGPIPE */
	return send(filedes, buffer, size, MSG_NOSIGNAL);
}

/**/
/*ssize_t*/ size_t sock_read (int filedes, void *buffer, size_t size) 
{
	return read (filedes, buffer, size); 
}

/**/
int sock_shutdown (int socket, int how) 
{
	return shutdown(socket, how);
}

/**/
int sock_close (int filedes)
{	  
	close(filedes);
	return 0;
}

/**/
int sock_get_remote_ip_addr(int socket, char *buffer)
{
	int len;
	struct sockaddr_in sin;

	strcpy(buffer, "");

	len = sizeof(sin);
	if (getpeername(socket, (struct sockaddr *) &sin, &len) < 0) return 0;
	strcpy(buffer, inet_ntoa(sin.sin_addr));
	return 1;
}

/**/
int sock_get_remote_host_name(int socket, char *buffer)
{
	return 0;
}

/**/
int sock_set_read_timeout(int socket, int seconds)
{
	struct timeval  timeo;

	timeo.tv_sec  = seconds;
	timeo.tv_usec = 0;

	if (setsockopt(socket, SOL_SOCKET, SO_RCVTIMEO, &timeo, sizeof(timeo)) < 0)
	;//	doLog(0, "setsockopt SO_RCVTIMEO");
	return 1;
}

/**/
int sock_set_write_timeout(int socket, int seconds)
{
	struct timeval  timeo;

	timeo.tv_sec  = seconds;
	timeo.tv_usec = 0;

	if (setsockopt(socket, SOL_SOCKET, SO_SNDTIMEO, &timeo, sizeof(timeo)) < 0)
		;//doLog(0, "setsockopt SO_RCVTIMEO");
	return 1;
}
