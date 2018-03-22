#ifndef ID003MAPP_H
#define ID003MAPP_H

#include <stdio.h>

#define downloadStartCmd   		0xD0
#define downloadDataCmd			0xD1	      				
#define downloadEndCmd 			0xD2
#define downloadEndStatusCmd 	0xD3
#define downloadStatusCmd		0xD4

typedef enum {
    ID003_STACKER_FULL = 0x43, ID003_STACKER_OPEN, ID003_JAM_IN_ACCEPTOR, ID003_JAM_IN_STACKER, 
    ID003_PAUSE, ID003_CHEATED, ID003_FAILURE, ID003_COMM_ERROR
} ID003StatusError;

//COMUNES CASHCODE Y JCM
#define STACK_MOTOR_FAILURE 		0xA2 
#define MOTOR_SPEED_FAILURE 		0xA5 
#define MOTOR_FEED_FAILURE 			0xA6 
// JCM
#define CASHBOX_NOT_READY_FAILURE 	0xAB 
#define HEAD_REMOVED_FAILURE 		0xAF 
#define BOOT_ROM_FAILURE 			0xB0 
#define EXTERNAL_ROM_FAILURE		0xB1 
#define ROM_FAILURE			 		0xB2 
#define EXT_ROM_WRITING_FAILURE 	0xB3 
//CASHCODE
#define ALIGN_MOTOR_FAILURE 		0xB4 
#define CASSETTE_STATUS_FAILURE		0xB5 
#define OPTIC_CANAL_FAILURE			0xB6 
#define MAGNETIC_CANAL_FAILURE 		0xB7 
#define CAPACITANCE_CANAL_FAILURE 	0xB8 




typedef enum {
    ID003_IDLING =  0x11, ID003_ACCEPTING, ID003_ESCROW, ID003_STACKING, ID003_VEND_VALID, 
    ID003_STACKED, ID003_REJECTING, ID003_RETURNING, ID003_HOLDING, ID003_DISABLED, 
    ID003_INITIALIZING, ID003_SIG_BUSY, ID003_SIG_END, ID003_RETURNED,ID003_UPDATE_FIRM = 0x01
} ID003StatusResponse;

typedef enum {
    ID003_POWER_UP = 0x40, ID003_POWER_UP_ACCEPTOR, ID003_POWER_UP_BILL_STACKER
} ID003StatusPowerUp;

typedef enum {
    CCNET_POWER_UP =  0x10, CCNET_POWER_UP_ACCEPTOR, CCNET_POWER_UP_BILL_STACKER, CCNET_INITIALIZING, 
    CCNET_IDLING, CCNET_ACCEPTING, CCNET_NONE, CCNET_STACKING, CCNET_RETURNING, CCNET_DISABLED, CCNET_HOLDING, 
    CCNET_BUSY, CCNET_REJECTING
} CCNETStatusResponse;

typedef enum {
    CCNET_STACKER_FULL = 0x41, CCNET_STACKER_OPEN, CCNET_JAM_IN_ACCEPTOR, CCNET_JAM_IN_STACKER, 
    CCNET_CHEATED, CCNET_PAUSE, CCNET_FAILURE, CCNET_COMM_ERROR
} CCNETStatusError;
 
typedef enum {
	CCNET_ESCROW = 0x80, CCNET_STACKED, CCNET_RETURNED
} CCNETEventsCredit;

enum {
	ACK_CMD = 0, RESET_CMD, STACK_CMD, STATUS_CMD, DISABLE_CMD, 
	RETURN_CMD, CURRENCY_CMD, IDENTIF_CMD, DOWNLOADSTART_CMD, 
	DOWNLOADDATA_CMD, DOWNLOADEND_CMD, DOWNLOADENDST_CMD, DOWNLOADSTATUS_CMD, CMDQTY 
};

unsigned char getCommandCode( int protocol, unsigned char commdReq );
unsigned char mapRejectCause( int protocol, unsigned char rejectCause );
unsigned char mapStatus( int protocol, unsigned char cashCodeStatus );
int mapFailureCode( int protocol, unsigned char failureCode );
int getCurrencyIdFromJcm ( int countryCode );
int getCurrencyIdFromCashCode( char* countryStr );
int getCurrencyIdFromISOStr( char* countryStr );


#endif