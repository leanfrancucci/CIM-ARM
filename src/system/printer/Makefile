# includes
INCLUDES=-Iprinter -Idev -Iio -Ios -Iutil -Iio -Ilang -Iinclude -I../ -I./

# el archivo ejecutable generado
OUT_LIB=libsysprinter.a

include ../.config.h
 
# archivos a compilar
OBJECTS= AbstractPrinterDriver.o ThermalDriver.o \
	 DocParsing.o NonFiscalDocParsing.o FormatParser.o PrinterInterface.o PrinterSpooler.o \
   DummyDocParsing.o SerialDriver.o

#SerialDriver.o

ifeq "$(CT_INCLUDE_PARALLEL_PRINTER)" "y"
OBJECTS+=ParallelDriver.o
endif

# paths a incluir
vpath %.m printer

# esto incluye todas las funciones necesarias
include includes.mak
