#include "os.h"
#include "oslayer.h"

long  
getTicks(void)
{
   return( GetTickCount() );
}

/*
 *	Duerme la cantidad de segundos especificada en value.
 */
void	msleep(unsigned long value)
{
	sleep(value);
}
