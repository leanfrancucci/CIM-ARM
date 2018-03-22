#ifndef  __CTIMER_H
#define  __CTIMER_H



/** If __TINY_PROC__ then timeout param is not present */
#ifdef __TINY_PROC__

	#define DECLARE_TIMEOUT_CTIMER_HANDLER(handler)		void handler(void)
	#define TIMEOUT_CTIMER_HANDLER(handler) 			void handler(void)
	#define SET_TIMEOUT_CTIMER_PARAM(value)				ctimers_with_no_data
	#define GET_TIMEOUT_CTIMER_PARAM(ptimer, value)		ctimers_with_no_data
	#define SET_TIMEOUT_CTIMER_DATA(ptimer, data)		ctimers_with_no_data
	
#else

	#define DECLARE_TIMEOUT_CTIMER_HANDLER(handler)		void handler(unsigned long data)
	#define TIMEOUT_CTIMER_HANDLER(handler) 			void handler(unsigned long data)
	#define GET_TIMEOUT_CTIMER_PARAM()					data
	#define SET_TIMEOUT_CTIMER_PARAM(ptimer, value)		((ptimer)->data = value)
	#define SET_TIMEOUT_CTIMER_DATA(ptimer, d)			((ptimer)->data = d)

#endif


/**
 *	All functions returns 1 if success and negative code if fail, 
 *	except another behavior is specified
 * */

enum 
{
	 ECTIMER_INVALID
	,ECTIMER_NOAVAIL
	,ECTIMER_NOINIT
};


/** LINUX OS */
#ifdef __LINUX_KERNEL__ 
	/**
	 *	The linux specific definitions. 
	 *	Use the linux kernel timers.
	 * */
	#include <linux/param.h>
	#include <linux/sched.h>
	#include <linux/timer.h>
	#include <linux/kernel.h>
	 
  	typedef  unsigned long 			CTimerExpiresType;
	typedef  struct timer_list 		CTimer;	

#else	/** __DOS__ o __LINUX__ o QY1 */

	//typedef  int 			CTimerExpiresType;
    typedef unsigned long CTimerExpiresType;
	typedef struct {

		CTimerExpiresType	expires;		/** timeout expires in msecs */		

		int periodic;
		unsigned long period;

#ifdef	__TINY_PROC__	
		void(*function)(void);
#else
		void(*function)(unsigned long);
		unsigned long		data;			/** an arbitrary value to pass to function */
#endif
		
#ifdef USEC_CTIMERS
		CTimerExpiresType	usec_expires;	/** timeout expires in micro secs */
#endif		

	} CTimer;
	
#endif


/**
 *	All functions return 1 if success or 0 if fail. 
 */ 
	
/**
 * 	init_ctimers
 *		Initialize the ctimers module with platform specific actions
 *
 */
int init_ctimers(void);

/**
 * uninit_ctimers
 *		Uninitialize the ctimers module
 *
 */

int cleanup_ctimers(void);	

/**
 * init_ctimer
 *		Initializes a ctimer.
 *		Must be called before add to the timer list.
 *
 */
int init_ctimer(CTimer *timer);

/**
 *  add_ctimer
 *		Add a timer to the active timers list 
 *
 */
int add_ctimer(CTimer *timer);

/**
 * del_ctimer
 * 		Remove a timer from the timer active list
 *
 */
int del_ctimer(CTimer *timer);

/**
 *  mod_ctimer
 *		In the expire function you could restart the timer with mod_ctimer().
 *
 */
int mod_ctimer(CTimer *timer, 
				CTimerExpiresType msec_expires, CTimerExpiresType usec_expires);	

				
	#if 0

		Use example:

		static CTimer timer;
		
		static
		TIMEOUT_CTIMER_HANDLER(to)
		{
			print("%d\n", GET_TIMEOUT_CTIMER_PARAM());
			mod_ctimer(&timer, 500, 0);
		}
		
		int main(void)
		{
			init_ctimers();
			
			init_ctimer(&timer);
			timer.function = to;
			SET_TIMEOUT_CTIMER_PARAM(&timer, 1);
			timer.expires = 500; /** half a second */ 			
			add_ctimer(&timer);
			while (1) ;
			return 1;
		}


	#endif


#endif

