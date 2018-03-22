/*
 * net.c
 *
 * Return the network interfaces (ie, ethernet hardware) by using system specific
 * calls.
 *
 */

#define Linux

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
#include <sys/socket.h> 
#include <sys/ioctl.h> 
#include "net.h"  

#define MAX_NUM_IFREQ 512

/*
* intf = interface name : "eth0"
* rslt = retorna la mac address
*/
 
 /*se invoca de la siguiente manera -> if_netInfo("eth0", rslt) */
int if_netInfo  (char *intf , char *rslt){
 struct ifconf Ifc; 
 struct ifreq IfcBuf[MAX_NUM_IFREQ], *pIfr; 
 int num_ifreq, i, fd; 
 struct sockaddr_in addrtmp; 
 unsigned char mac[10]={0}; 
 char tmp[20];
 char gateway[255];

 Ifc.ifc_len=sizeof(IfcBuf); 
 Ifc.ifc_buf=(char *)IfcBuf; 
 if ((fd=socket(AF_INET, SOCK_DGRAM, 0))<0) { return -1; }
  
 if (ioctl(fd, SIOCGIFCONF, &Ifc)<0) { close(fd); return -1; } 

 num_ifreq=Ifc.ifc_len/sizeof(struct ifreq); 
 for (pIfr=Ifc.ifc_req, i=0; i<num_ifreq; ++pIfr, ++i) 
  	{  
	if (strcmp(pIfr->ifr_name,intf)!=0) continue;  // filtro por interfaz solicitada
  	//MACADDRESS
  	if (ioctl(fd,SIOCGIFHWADDR, pIfr)<0) { continue; } 
  	memcpy(mac,(unsigned char *)&(pIfr->ifr_hwaddr.sa_data),sizeof(struct sockaddr)); 
	  sprintf(tmp,"%02X:%02X:%02X:%02X:%02X:%02X", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]); 

	  strcpy(rslt, tmp);
	  close(fd);
    return 0;   	
  } // for
  
 close(fd); 
 return 0; 
}
