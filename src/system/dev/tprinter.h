#ifndef __TPRINTER_H__
#define __TPRINTER_H__

/*
 * Macro definitions
 */
#define PRT_NORMAL			0x00
#define PRT_BOLD				0x08
#define PRT_DBLHEIGHT		0x10
#define PRT_UNDERLINE		0x80 /* not supported yet */
 

int tprinter_open(void);
int tprinter_close(void);
int tprinter_write(const char *, size_t);

int tprinter_get_fontfmt(void);
int tprinter_set_fontfmt(int);
/* Manteins previos format */
int tprinter_set_bold_on(void);
int tprinter_set_bold_off(void);
int tprinter_get_bold_on(void);
int tprinter_set_dblheight_on(void);
int tprinter_set_dblheight_off(void);
int tprinter_get_dblheight_on(void);

/**
 *	Non-blocking. Returns the number of elements in the queue, waiting to be printed.
 * 	When it returns zero it means that the printer is idle. However, it might never
 * 	reach zero if it ran out of paper !!!
 *
 */
int tprinter_queue_qty(void);

/**
 *	Non-blocking. Returns 1 if we have no paper, 0 (OK) if we do.
 */
int tprinter_has_paper(void);

/**
 * 	Blocking. Returns as soon as the printer sensor reports there is paper again.
 * 	It does not mean that it will restart printing the pending lines immediately:
 * 	TPRINTER_TRYPRINTING must be sent before. Might be used, for example, for dialogs
 * 	or on-screen icons showing that there's no paper.
 */
int tprinter_wait_for_paper(void);

/**
 * 	Non-blocking. It tries to resume printing when the paper is ready on the printer.
 * 	When a printer runs out of paper it stops working until this IOCTL is issued.
 */
int tprinter_try_printing(void);

/**
 * 	This resets the queue, removing all pending lines. It may be issued whenever you
 * 	want, but you might get weird results if you send this while printing. 
 * 	This is useful if you want to remove pending lines after a run-out-of-paper event.
 */
int tprinter_clean_queue(void);

/**
 *	
 */
void tprinter_start_advance_paper(void);

/**
 *
 */
void tprinter_stop_advance_paper(void);

int tprinter_print_logo(char* aFileName);

#endif

