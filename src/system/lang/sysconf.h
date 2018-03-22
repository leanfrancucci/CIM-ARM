#ifndef SYSCONF_H
#define SYSCONF_H

/** 
 * Definiciones para Linux
 */
#ifdef __LINUX

#define PLATFORM_IS_LITTLE_ENDIAN

#endif

/** 
 * Definiciones para uCLinux
 */
#ifdef __UCLINUX

#define PLATFORM_IS_BIG_ENDIAN

#endif

#ifdef __ARM_LINUX

#define PLATFORM_IS_LITTLE_ENDIAN

#endif

/** 
 * Definiciones para Win32
 */
#ifdef __WIN32

#define PLATFORM_IS_LITTLE_ENDIAN

#endif

#endif
