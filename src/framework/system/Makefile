# el archivo ejecutable generado
OUT_LIB=libsystem.a

include ../.config.h
 
# archivos a compilar
OBJECTS=CtSystem.o TelesupFacade.o RegionalSettingsFacade.o \
CommercialStateFacade.o \
RegionalSettingsFacade.o \
TelesupFacade.o TransferInfoFacade.o

# paths
vpath %.c system
vpath %.m system
vpath %.m system/facade
vpath %.m system/license
vpath %.c system/license

# include de reglas de compilacion 
include includes.mak

# includes
INCLUDES=$(ALL_INCLUDES)
