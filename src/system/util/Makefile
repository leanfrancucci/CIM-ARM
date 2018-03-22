# includes
INCLUDES=-Ios -Idev -Iutil -Ilang -Ios/$(PLATFORM) -I../ -I/usr/local/include/cakit

# el archivo ejecutable generado
OUT_LIB=libsysutil.a

include ../.config.h

# archivos a compilar
OBJECTS=util.o StringTokenizer.o queue.o SyncQueue.o SyncQueueReader.o \
SyncQueueWriter.o Collection.o SystemTime.o StaticSyncQueue.o Configuration.o \
File.o md5lib.o Map.o state_machine.o log.o

ifeq "$(PLATFORM)" "uclinux"
OBJECTS+= integer.o
endif

# paths a incluir
vpath %.m util
vpath %.c util

# esto incluye todas las funciones necesarias
include includes.mak
