# Includes necesarios
INCLUDES=-Ios -Ilang -I../ -Iutil -Iexpat

# el archivo ejecutable generado
OUT_LIB=libexpat.a

include ../.config.h
 
# archivos a compilar
OBJECTS=xmlparse.o xmlrole.o xmltok.o

vpath %.m expat
vpath %.c expat

# esto incluye todas las funciones necesarias
include includes.mak

CFLAGS+= -DHAVE_EXPAT_CONFIG_H
