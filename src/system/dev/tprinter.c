#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <fcntl.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include "tprinter.h"
#include "tprinter_ioctls.h"
#include "bitmap.h"
#include "log.h"

static char printer_node[] = "/dev/tprinter";
static int fd = -1;
static int curr_fontfmt = PRT_NORMAL;

/*
 * Open the printer driver 
 *  Return driver fd
 *  
 */
int 
tprinter_open(void)
{
	int i;

    printf("*---------***************************************ABRIENDO IMPRESORA *-****************************** \n");
    
	/* Control concurrent opening of the driver */
	if (fd != -1) {
        printf("*---------***************************************ERROR ABRIENDO IMPRESORA *-****************************** \n");
		perror("The printer driver is already opened!\n");
		return -1;
	}

	/* Open the driver */
	i = open(printer_node, O_WRONLY);	
	if (i < 0) {
        printf("*---------***************************************ERROR ABRIENDO IMPRESORA 2*-****************************** \n");
		perror("The printer driver could not be opened!\n");
		return -1;
	}
	fd = i;
    printf("*---------***************************************EXITO ABRIENDO IMPRESORA *-****************************** \n");
	return 0;
}	

/*
 * Close the printer driver 
 */
int 
tprinter_close(void)
{
	fd = -1;
	return  close(fd);
}

/*
 * Write to the printer driver 
 */
int 
tprinter_write(const char *buf, size_t count)
{
	/*char * pt;
	int i;*/
/*	int n = write(fd, "0123456789", 10);
	doLog(0,"---> %d bytes writen to printer\n", n);
	return n;*/
	/*doLog(0,"\n%s\n",buf);

	pt = buf;
	for(i=0;i<count;i++) {
		doLog(0,"[%x]", *pt);
		pt++;
	}*/
	return  write(fd, buf, count);
}
/*
 *	Get the printer format
 */
int
tprinter_get_fontfmt( void )
{
	return curr_fontfmt;
}

/*
 * Set the new printer format 
 */
int 
tprinter_set_fontfmt(int fmt)
{
	char fontfmt[3];
	
	curr_fontfmt = fmt;
	sprintf(fontfmt, "\x1B\x21%c", fmt);	
	return tprinter_write(fontfmt, 3);
}

/*
 * Add bold to printer format
 */
int 
tprinter_set_bold_on(void)
{
	int fmt = curr_fontfmt | PRT_BOLD;
	return tprinter_set_fontfmt(fmt);
}
/*
 * 
 */
int 
tprinter_set_bold_off(void)
{
	int fmt = curr_fontfmt & ~PRT_BOLD;
	return tprinter_set_fontfmt(fmt);
}

int
tprinter_get_bold_on(void)
{
	return ( curr_fontfmt & PRT_BOLD ) ? 1 : 0;
}
/*
 *
 */
int 
tprinter_set_dblheight_on(void)
{
	int fmt = curr_fontfmt | PRT_DBLHEIGHT;
	return tprinter_set_fontfmt(fmt);
}

/*
 *
 */
int 
tprinter_set_dblheight_off(void)
{
	int fmt = curr_fontfmt & ~PRT_DBLHEIGHT;
	return tprinter_set_fontfmt(fmt);
}

int
tprinter_get_dblheight_on(void)
{
	return (curr_fontfmt & PRT_DBLHEIGHT) ? 1 : 0;
}

/**/
int tprinter_queue_qty(void)
{
	return ioctl(fd, TPRINTER_QUEUEQTY, 0);
}

/**/
int tprinter_has_paper(void)
{
	return ioctl(fd, TPRINTER_NOPAPER, 0);
}

/**/
int tprinter_wait_for_paper(void)
{
//	doLog(0,"paso por ............. tprinter_wait_for_paper");
	return ioctl(fd, TPRINTER_WAITFORPAPER, 0);
}

/**/
int tprinter_try_printing(void)
{
//	doLog(0,"paso por ............. tprinter_try_printing");
	return ioctl(fd, TPRINTER_TRYPRINTING, 0);
}

/**/
int tprinter_clean_queue(void)
{
	return ioctl(fd, TPRINTER_CLEANQUEUE, 0);
}

/**/
void tprinter_start_advance_paper(void)
{
	ioctl(fd, TPRINTER_ADVANCEPAPER, 0);
}

/**/
void tprinter_stop_advance_paper(void)
{
	ioctl(fd, TPRINTER_STOPPAPER, 0);
}

/**/
/*
int tprinter_barcode(type, barCode)
{
	char prString[30];
	doLog(0,"paso por ............. tprinter_try_barcode");
	sprintf(prString, "\x1D\x68\x05%s", barCode);	
	return tprinter_write(prString, strlen(prString));	
}  
*/


/**/
int tprinter_print_logo(char* aFileName)
{
   BITMAP bmp;
   int res;
   int total;
   long l;
 
   FILE *fp = fopen( aFileName, "r" );

   if( !fp ) {
      // doLog(0,"Could not open logo\n");
       return -1;
   }

   fseek( fp, 0, SEEK_END );
   l = ftell ( fp );
   fseek( fp, 0, SEEK_SET );
   bmp.width = 384;
   bmp.height = l / ( 384 / 8 );
#ifdef __ARM_LINUX
   bmp.flags = BITMAP_INVERT;
#endif
   total = (bmp.width / 8) * bmp.height;
   bmp.image = (char *) malloc( total );
   fread( bmp.image, 1, total, fp );
   res = ioctl(fd, TPRINTER_DRAW, &bmp);

	 free(bmp.image);
	 fclose(fp);

   if( res ) {
  //     doLog(0," prn_printbmp error\n");
       return -2;
   }

   tprinter_write("\n", 1);


   return 0;
} 
