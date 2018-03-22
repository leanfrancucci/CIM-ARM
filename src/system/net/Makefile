# includes
INCLUDES=-Ios -Iutil -Iio -Ilang -Iinclude -Iinclude/openssl -I../

# el archivo ejecutable generado
OUT_LIB=libsysnet.a

include ../.config.h

# archivos a compilar
OBJECTS=ClientSocket.o ServerSocket.o SocketReader.o SocketWriter.o SSLClientSocket.o SSLServerSocket.o

# paths a incluir
vpath %.m net

# esto incluye todas las funciones necesarias
include includes.mak
