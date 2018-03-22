/*
 * 		mytypes.h
 * 			Defines portable types
 */

#ifndef __MYTYPES__
#define __MYTYPES__

#ifdef __TINY_PROC__

typedef signed		char	MInt;
typedef unsigned	char	MUInt;

#else

typedef int					MInt;
typedef unsigned			MUInt;

#endif

#endif

