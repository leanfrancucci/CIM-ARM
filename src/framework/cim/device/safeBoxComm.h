#ifndef SAFE_BOX_COMM_H
#define SAFE_BOX_COMM_H

extern unsigned short framesQty;

char safeBoxCommOpen( char portNumber );
void safeBoxCommClose( void );
void safeBoxCommWrite( unsigned char dev, unsigned char cmd, unsigned char * data, int dataLen );
unsigned char * safeBoxCommRead( int timeout );
//void logFrame( unsigned char devId, unsigned char *frame, int n, char direction );
int TEST_SAFE_BOX_COM( char portNumber );

#endif
