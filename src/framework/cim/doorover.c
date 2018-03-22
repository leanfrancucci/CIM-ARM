/* ========================================================================== */
/*                                                                            */
/*   Filename.c                                                               */
/*   (c) 2001 Author                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */
#include <stdlib.h>
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include "doorover.h"

/**/
static unsigned long
calcChecksum(unsigned char *buf, int cant)
{
	int i;
	unsigned long checksum;
	
	checksum = 0;
	for (i = 0; i < cant; ++i) //seria hasta cant. eventos del sector.
		checksum += buf[i];

	return checksum;
}

/* Funcion: genVerifCode
 * Entrada: fecha y hora del equipo.
 *          codigo de verificacion que se muestra por pantalla
 */
void genVerifCode( struct tm * fechaHora, unsigned char * codVerif )
{
  codVerif[0] = (unsigned char)(fechaHora->tm_mon + 1 + 75);
  codVerif[1] = (unsigned char)((fechaHora->tm_year-100) / 10)+48;
  codVerif[2] = (unsigned char)((fechaHora->tm_year-100) % 10)+48;
  codVerif[3] = (unsigned char)(fechaHora->tm_hour + 67);
  codVerif[4] = (unsigned char)(fechaHora->tm_min / 10)+48;
  codVerif[5] = (unsigned char)(fechaHora->tm_min % 10)+48;
  codVerif[6] = (unsigned char)((fechaHora->tm_mday / 10) + 65);
  codVerif[7] = (unsigned char)((fechaHora->tm_mday % 10) + 80);
  codVerif[8] = 0;
}


/* Funcion: genInternalCode
 * Entrada: mac_address del equipo, Id del punto de venta y fecha y hora del equipo.
 * Salida: codigo interno que se debe comparar con el código ingresado por el operador.
 */
unsigned long genInternalCode( char * mac, char * idPunto, struct tm * fechaHora )
{
  return (unsigned long)(fechaHora->tm_mon + 1) * 10000L + (unsigned long)(fechaHora->tm_year - 100) * 555L +
		  (unsigned long)fechaHora->tm_hour * 33L + (unsigned long)fechaHora->tm_min * 5L + (unsigned long)fechaHora->tm_mday +
		  (unsigned long)calcChecksum(mac, strlen(mac)) + (unsigned long)calcChecksum(idPunto, strlen(idPunto));
}

#ifdef __TEST_DOOR_OVERRIDE

void main()
{
  time_t fh;
  struct tm fechaHora;
  unsigned char codAux[10];
  unsigned long intCode;

  fh = time(NULL);

  localtime_r( &fh, &fechaHora );

  fechaHora.tm_hour = 19;
  fechaHora.tm_mday = 29;
  fechaHora.tm_min  = 12;
  fechaHora.tm_year = 107;
  fechaHora.tm_mon  = 5;

  //doLog(0,"Hora %s\n",asctime(&fechaHora));
  genVerifCode(&fechaHora, codAux);
 // doLog(0,"Codigo de verificacion: %s\n", codAux);

  intCode = genInternalCode("00-E0-7D-F2-BF-E2", "BANK12322222" ,&fechaHora);
 // doLog(0,"Codigo interno: %d\n", intCode);

}
#endif
