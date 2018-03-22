

  # el archivo ejecutable generado
OUT_LIB=libmain.a

include ../.config.h
 
OBJECTS=mainSystem.o LCDUserInterface.o 

ifeq "$(CT_GUI)" "PC"
OBJECTS=mainSystemPC.o sigsevhandler.o
endif

# paths
vpath %.m main
vpath %.c main

# include de reglas de compilacion 
include includes.mak

# includes
INCLUDES=$(ALL_INCLUDES)
		 
