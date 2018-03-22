# includes
INCLUDES=-Ios -Iutil -Iio -Ilang -I../ -Idev -Iinclude -Idev/dallas

# el archivo ejecutable generado
OUT_LIB=libsysdev.a

include ../.config.h
 
# archivos a compilar
#owtrnu.o owsesu.o ownetu.o owllu.o linuxlnk.o ds2480ut.o \
#owerr.o \
#owcache.o \
#mbnvcrc.o \
#swt1C.o \
#swt3A.o \
#owfile.o \
#swt29.o \
#mbappreg.o \
#mbscrex.o \
#swt1f.o \
#atod26.o \
#mbnv.o \
#shadebit.o \
#thermo21.o \
#mbeprom.o \
#ioutil.o \
#temp10.o \
#ibsha33o.o \
#mbscree.o \
#mbshaee.o \
#mbscrcrc.o \
#shadbtvm.o \
#ps02.o \
#crcutil.o \
#pw77.o \
#swt05.o \
#mbsha.o \
#weather.o \
#time04.o \
#rawmem.o \
#cnt1d.o \
#sha33.o \
#screenio.o \
#findtype.o \
#mbscr.o \
#owprgm.o \
#atod20.o \
#mbee.o \
#mbscrx77.o \
#shaib.o \
#owpgrw.o \
#humutil.o \
#mbee77.o \
#swt12.o \
#sha18.o \
#mbeewp.o

OBJECTS=ComPort.o ComPortReader.o ComPortWriter.o Printer.o Modem.o Buzzer.o BarcodeScanner.o\
crcutil.o \
ds2480ut.o \
linuxlnk.o \
owerr.o \
owtrnu.o owsesu.o ownetu.o owllu.o 

ifeq "$(CT_INCLUDE_PARALLEL_PRINTER)" "y"
OBJECTS+=ParallelPortReader.o ParallelPortWriter.o ParallelPort.o
endif

ifeq "$(PLATFORM)" "uclinux"
OBJECTS+=tprinter.o
endif

ifeq "$(PLATFORM)" "arm-linux"
OBJECTS+=tprinter.o
endif


# paths a incluir
vpath %.m dev
vpath %.c dev
vpath %.c dev/dallas
vpath %.m dev/dallas


# esto incluye todas las funciones necesarias
include includes.mak
