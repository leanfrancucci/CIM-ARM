# Includes necesarios
INCLUDES=-Ios -Ilang -I../ -Iutil

# el archivo ejecutable generado
OUT_LIB=libsysos.a

include ../.config.h
 
# archivos a compilar
OBJECTS=osrt.o OMutex.o OSemaphore.o OThread.o osdep.o socketapi.o comportapi.o ctimers.o OTimer.o \
	    OSServices.o PowerFailManager.o

ifeq "$(CT_INCLUDE_PARALLEL_PRINTER)" "y"
OBJECTS+= parallelportapi.o
endif

vpath %.m os
vpath %.c os
vpath %.m os/$(PLATFORM)
vpath %.c os/$(PLATFORM)

# esto incluye todas las funciones necesarias
include includes.mak
