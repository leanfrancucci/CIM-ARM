#ifndef __LOG_COMM__
#define __LOG_COMM__

// LOG TYPES: 
enum	{
	NO_LOG = 0, FILE_LOG, SCREEN_LOG, FULL_LOG, VALS_LOG
};

void logFrame( unsigned char devId, unsigned char *frame, int n, char direction );
void logStr( char *str );
void openConfigFile ( void );
int getLogType( void );


#endif

