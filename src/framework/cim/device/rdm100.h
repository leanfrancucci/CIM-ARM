#ifndef RDM100_H
#define RDM100_H

static unsigned char enqCmd[4]= { 0x10, 0x05, 0x41, 0x30 };
static unsigned char ackCmd[2]= { 0x10, 0x06 };
static unsigned char nakCmd[2]= { 0x10, 0x15 };
static unsigned char eotCmd[2]= { 0x10, 0x04 };
static unsigned char etxCmd[2]= { 0x10, 0x03 };
static unsigned char rcvdFrameEnc[4]= { 0x10, 0x02, 0x30, 0x41 };
static unsigned char sntFrameEnc[4]= { 0x10, 0x02, 0x41, 0x30 };

int rdmInit( char portNumber );
unsigned char * rdmReadFrame( int aHandle, unsigned char hardwareId, int timeout );
void rdmWriteFrame(int aHandle, unsigned char hardwareId,unsigned char *data, int dataLen);
void rdmWriteCtrlSignal( int aHandle, unsigned char hardwareId,unsigned char * data, int dataLen );
unsigned char * rdmReadCtrlSignal( int aHandle, unsigned char hardwareId, int timeout );


#endif
