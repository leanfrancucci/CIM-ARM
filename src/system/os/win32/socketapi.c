#include <stdlib.h>
#include <windows.h>
#include <winsock.h>
#include <unistd.h>
#include <assert.h>
#include "socketapi.h"


/**/
int sock_socket(void)
{	 
	//socket(namespace, int style, int protocol);
	return socket(PF_INET, SOCK_STREAM, 0);
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
	
	assert(socket >= 0);
	return connect(socket, (struct sockaddr *) &saddr_in, sizeof(struct sockaddr));
}

/**/
int sock_accept(int socket) 
{
	struct sockaddr_in remote_sa;
	int len;
	int res;
	
	memset(&remote_sa, 0, sizeof(remote_sa));
	len = sizeof(remote_sa);
	res = accept(socket, (struct sockaddr*)&remote_sa, &len);	
	return res;
}

/**/
int sock_bind(int socket, int port )
{
	struct sockaddr_in local_sa;
	
	assert(socket >= 0);
	
	memset(&local_sa, 0, sizeof(local_sa));
	local_sa.sin_family = AF_INET;
	local_sa.sin_port = htons(port);
	local_sa.sin_addr.s_addr = INADDR_ANY;
	
	return bind( socket, (struct sockaddr*)&local_sa, sizeof(local_sa));
}

/**/
int sock_listen( int socket, int n )
{
	assert(socket >= 0);
	return  listen( socket, n );
}
	
/**/
/*ssize_t*/ size_t sock_write(int socket, const void *buffer, size_t size)
{	
	return send(socket, buffer, size, 0);
}

/**/
/*ssize_t*/ size_t sock_read (int socket, void *buffer, size_t size) 
{
	return  recv(socket, buffer, size, 0); 
	
}

/**/
int sock_shutdown (int socket, int how) 
{
	return shutdown(socket, how);
}

/**/
int sock_close(int socket)
{	  
	close(socket);
	return 1;	
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
