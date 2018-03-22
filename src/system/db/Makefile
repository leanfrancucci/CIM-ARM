# includes
INCLUDES=-Ios -Iutil -Ilang -Idb -Iio -I../ -I./ -Iinclude

# el archivo ejecutable generado
OUT_LIB=libsysdb.a

include ../.config.h

# archivos a compilar
ROP=RecordSet.o MultiPartRecordSet.o DB.o Table.o roputil.o Transaction.o TransactionManager.o
SQL=SQLRecordSet.o SQLWrapper.o SQLResultParser.o SQLUtils.o Transaction.o
OBJECTS=AbstractRecordSet.o DBConnection.o

ifeq ($(CT_SQL_DB),y) 
	OBJECTS+= $(SQL)
else
	OBJECTS+= $(ROP)
endif

# donde se encuentran los archivos fuente
vpath %.m db

ifeq ($(CT_SQL_DB),y) 
	vpath %.m db/sql
	vpath %.c db/sql
else
	vpath %.m db/rop
	vpath %.c db/rop
endif


# esto incluye todas las funciones necesarias
include includes.mak
