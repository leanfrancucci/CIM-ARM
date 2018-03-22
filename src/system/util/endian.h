#ifndef ENDIAN_H
#define ENDIAN_H

#include "system/lang/all.h"
#include "sysconf.h"
#include <asm/byteorder.h>

#if defined(PLATFORM_IS_LITTLE_ENDIAN) && !defined(PLATFORM_IS_BIG_ENDIAN)

#define L_ENDIAN_TO_SHORT(A)  (A)
#define L_ENDIAN_TO_LONG(A)   (A)

#define B_ENDIAN_TO_SHORT(A)  ((((UInt16)(A) & 0xff00) >> 8) | (((UInt16)(A) & 0x00ff) << 8))
#define B_ENDIAN_TO_LONG(A)  ((((UInt32)(A) & 0xff000000) >> 24) | (((UInt32)(A) & 0x00ff0000) >> 8)  | (((UInt32)(A) & 0x0000ff00) << 8)  |               (((UInt32)(A) & 0x000000ff) << 24))

#define __BYTE_ORDER __LITTLE_ENDIAN 

#elif defined(PLATFORM_IS_BIG_ENDIAN) && !defined(PLATFORM_IS_LITTLE_ENDIAN)

#define L_ENDIAN_TO_SHORT(A)  ((((UInt16)(A) & 0xff00) >> 8) | (((UInt16)(A) & 0x00ff) << 8))
#define L_ENDIAN_TO_LONG(A)  ((((UInt32)(A) & 0xff000000) >> 24) | (((UInt32)(A) & 0x00ff0000) >> 8)  | (((UInt32)(A) & 0x0000ff00) << 8)  |               (((UInt32)(A) & 0x000000ff) << 24))

#define B_ENDIAN_TO_SHORT(A)	 (A)
#define B_ENDIAN_TO_LONG(A)    (A)

#else 

#error "Either PLATFORM_IS_BIG_ENDIAN or PLATFORM_IS_LITTLE_ENDIAN must be defined, but not both."

#endif

#define SHORT_TO_L_ENDIAN(A)  L_ENDIAN_TO_SHORT(A)
#define LONG_TO_L_ENDIAN(A)   L_ENDIAN_TO_LONG(A)

#define SHORT_TO_B_ENDIAN(A)  B_ENDIAN_TO_SHORT(A)
#define LONG_TO_B_ENDIAN(A)   B_ENDIAN_TO_LONG(A)

#endif
