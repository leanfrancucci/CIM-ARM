# Includes necesarios
INCLUDES=-Ios -Ilang -I../ -Iutil -Iexpat -Iscew

# el archivo ejecutable generado
OUT_LIB=libscew.a

include ../.config.h
 
# archivos a compilar
OBJECTS=attribute.o element.o error.o parser.o str.o tree.o \
                    writer.o xattribute.o xerror.o xhandler.o xparser.o xprint.o

vpath %.m scew
vpath %.c scew

# esto incluye todas las funciones necesarias
include includes.mak

CFLAGS+= -DHAVE_EXPAT_CONFIG_H
