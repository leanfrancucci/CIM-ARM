#ifndef __EXCEPTS_H
#define __EXCEPTS_H

#include "osrt.h"

/** Try block */
#define   TRY				{	if (setjmp(*ex_save_env()) == 0) {

/** it must be declared before exits tthe TRY block  */
#define   EXIT_TRY    				ex_remove_env();
#define   BREAK_TRY						{ex_remove_env(); break; }
#define   RETURN_TRY(a)				{ex_remove_env(); return(a); }

/** Catch block */
#define   CATCH 	   				ex_remove_env();  } else { ex_set_except_block();

/** Finally block (without explicit else)  */
#define   FINALLY	 			ex_remove_env();  } { ex_set_finally_block();

/** Catch an espcific Exception */
#define   EXCEPTION(excode)			if (ex_curr_code(excode))
#define   EXCEPTION_GROUP(excode) if (ex_get_code() - excode > 0 && ex_get_code() - excode < 1000)

/** End of a try block */
#define 	END_TRY			ex_do_rethrow(); } }

/** Throws an Exception */
#define   THROW(excode) 	ex_throw((excode), 0, 0, __FILE__, __LINE__, #excode)
#define   THROW_CODE(excode, acode) ex_throw((excode), 0, (acode), __FILE__, __LINE__, #excode)
#define   THROW_MSG(excode, msg) ex_throw_msg((excode), 0, 0, __FILE__, __LINE__, #excode, msg)
#define   THROWF(excode)	ex_throw((excode), 1, 0, __FILE__, __LINE__, #excode)
#define   THROW_FMT(excode, format, args...) ex_throw_fmt((excode), 0, 0, __FILE__, __LINE__, #excode, format, args)

/** RETHROWs the current Exception */
#define   RETHROW()		 		ex_rethrow()

#endif
