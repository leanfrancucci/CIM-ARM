# includes
INCLUDES=-Ios -Iutil -Ilang -I../

# el archivo ejecutable generado
OUT_LIB=libsysio.a

include ../.config.h
 
# archivos a compilar
OBJECTS=Reader.o Writer.o \
				FileReader.o FileWriter.o
#				FilterReader.o FilterWriter.o \
#				DataReader.o DataWriter.o \
# 				MemoryReader.o MemoryWriter.o
#				LogWriter.o LogReader.o ASCIIFormatterWriter.o

# paths a incluir
vpath %.m io

# esto incluye todas las funciones necesarias
include includes.mak
