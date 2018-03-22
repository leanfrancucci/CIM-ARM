/*
 *	lcddriver.h	
 */

#ifndef  __TPRINTER_IOCTLS_H__
#define  __TPRINTER_IOCTLS_H__ 

#include <linux/ioctl.h>

/* ioctl defs */
#define TPRINTER_IOC_MAGIC 'y'
#define TPRINTER_OK 0

//#define TPRINTER_WAITFORQUEUE		_IO(TPRINTER_IOC_MAGIC, 1)
/*
 * Non-blocking. Returns the number of elements in the queue, waiting to be printed.
 * When it returns zero it means that the printer is idle. However, it might never
 * reach zero if it ran out of paper !!!
 */
#define TPRINTER_QUEUEQTY			_IO(TPRINTER_IOC_MAGIC, 1)
/*
 * Non-blocking. Returns 1 if we have no paper, 0 (OK) if we do.
 */
#define TPRINTER_NOPAPER			_IO(TPRINTER_IOC_MAGIC, 2)
/*
 * Blocking. Returns as soon as the printer sensor reports there is paper again.
 * It does not mean that it will restart printing the pending lines immediately:
 * TPRINTER_TRYPRINTING must be sent before. Might be used, for example, for dialogs
 * or on-screen icons showing that there's no paper.
 */
#define TPRINTER_WAITFORPAPER		_IO(TPRINTER_IOC_MAGIC, 3)
/*
 * Non-blocking. It tries to resume printing when the paper is ready on the printer.
 * When a printer runs out of paper it stops working until this IOCTL is issued.
 */
#define TPRINTER_TRYPRINTING		_IO(TPRINTER_IOC_MAGIC, 4)
/*
 * This resets the queue, removing all pending lines. It may be issued whenever you
 * want, but you might get weird results if you send this while printing. 
 * This is useful if you want to remove pending lines after a run-out-of-paper event.
 */
#define TPRINTER_CLEANQUEUE			_IO(TPRINTER_IOC_MAGIC, 5)

/*
 * Advance paper one line
 */
#define TPRINTER_ADVANCEPAPER       _IO(TPRINTER_IOC_MAGIC, 6)

/*
 * Stop paper
 */
#define TPRINTER_STOPPAPER      _IO(TPRINTER_IOC_MAGIC, 7)

/*
 * Print bitmap
 */
#define TPRINTER_DRAW 					_IO(TPRINTER_IOC_MAGIC, 8)


#define TPRINTER_IOC_MAXNR          7


#endif

