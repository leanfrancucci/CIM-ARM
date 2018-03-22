#ifndef JCM_BILL_COMM_H
#define JCM_BILL_COMM_H

//char jcmInitComm( char portNumber );

char jcmInitComm( char portNumber, char protocol );

unsigned short calcCrc( unsigned short baseCrc, char * data, unsigned short n );
void jcmWrite( unsigned char dev, char protocol, unsigned char cmd, unsigned char * data, int dataLen );
unsigned char *jcmRead( unsigned char *dev, char protocol, int *cmdDataLen );


#endif
