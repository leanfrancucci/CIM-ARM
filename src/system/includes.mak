##########################################
# Variables de entorno necesarias
##########################################

ifndef CT_HOME
$(error Enviorement variable CT_HOME is not set, p.e: /c/Proyectos/ct)
endif

ifndef PLATFORM
$(error Enviorement variable PLATFORM is not set, should be win32, linux, uclinux)
endif

ifndef OBJC_BASE
$(error Environment variable OBJC_BASE is not set, p.e: /home/razor/Work/poc/objc-3.3.2)
endif

##########################################
# Opciones especificas de una plataforma
##########################################

CFLAGS=
SYS_INCLUDES=
OBJC_INCLUDES=-I$(OBJC_BASE)/include/objcrt -I$(OBJC_BASE)/include/objpak

#uclinux
ifeq "$(PLATFORM)" "uclinux"

	UCLINUX_BUILD_USER=1
	AR=m68k-elf-ar
	CC=m68k-elf-gcc

	export UCLINUX_BUILD_USER

	include $(ROOTDIR)/.config
	include $(ROOTDIR)/config.arch
	
	CT_DEFINES+= -D_ISOC99_SOURCE
	CT_DEFINES+=-D__UCLINUX

#	SYS_INCLUDES=-I/uclinux/lib/uClibc/include

	OBJCOPT=-noNilRcvr -noFwd -Wall -noBlocks -noFiler -noCategories -q \
			-pthreads -I/usr/local/m68k-elf/include -L/usr/local/m68k-elf/lib/
#	-I/uclinux/lib/uClibc/include -I/uclinux/lib/libm -I/usr/local/lib/gcc-lib/m68k-elf/2.95.3/include -L/usr/local/lib/gcc-lib/m68k-elf/2.95.3/ -pthreads

	CFLAGS = -m5307 -DCONFIG_COLDFIRE -O3 -Wc:-O3 -fomit-frame-pointer \
		-Dlinux -D__linux__ -Dunix -D__uClinux__ -DEMBED \
		-fno-builtin
#		-msep-data

#	CFLAGS = -m5307 -DCONFIG_COLDFIRE -Os -fomit-frame-pointer \
#		-Dlinux -D__linux__ -Dunix -D__uClinux__ -DEMBED \
#		-fno-builtin
		
endif

#win32
ifeq "$(PLATFORM)" "win32"

	CT_DEFINES+=-D__WIN32
	CC=gcc
	AR=ar
	OBJCOPT=-q -g -lpthread -noNilRcvr -Wall -noFwd
	
endif

#linux
ifeq "$(PLATFORM)" "linux"

	CT_DEFINES+=-D__LINUX
	#CC=gcc
	#AR=ar
	OBJCOPT=-q -g -lpthread -noNilRcvr -Wall -noFwd
	
endif

#arm-linux
ifeq "$(PLATFORM)" "arm-linux"

	CT_DEFINES+=-D__ARM_LINUX
	#CC=gcc
	#AR=ar
	OBJCOPT=-q -g -lpthread -noNilRcvr -Wall -noFwd -noI
	
endif

ifeq "$(CT_APP_TYPE)" "dll"
	OBJCOPT +=-dynamic -dl -postLink
endif

##########################################
# Opciones general
##########################################

# Opciones de Objective-c

	
# Define el directorio donde de las librerias
OUT_LIB_PATH=$(CT_HOME)/lib/$(PLATFORM)
 
# compilador de objective-c
OBJC=objc

# path de las bibliotecas dependientes de la plataforma
LIB_PATH=-L$(CT_HOME)/lib/$(PLATFORM)

# le concatena el path a los obj/ a los .o
OBJECTS_WITH_PATH=$(OBJECTS:%=%)

##########################################
# Reglas implicitas de compilacion
##########################################

%.d: %.c
	echo Generating dependencies for $< ...
	$(CC) -M $(OBJC_INCLUDES) $(INCLUDES) $(SYS_INCLUDES) $(CT_DEFINES) $< | sed 's/$*.o/& $@/g' > $@

%.d: %.m
	echo Generating dependencies for $< ...
	$(CC) -M $(OBJC_INCLUDES) $(INCLUDES) $(SYS_INCLUDES) $(CT_DEFINES) -D__PORTABLE_OBJC__ $< | sed 's/$*.o/& $@/g' > $@
	
%.o: %.m
	echo Compiling $< ...
	echo $(OBJC) -c -noFiler $(CFLAGS) $(OBJC_INCLUDES) $(INCLUDES) $(SYS_INCLUDES) $(CT_DEFINES) $(OBJCOPT) $< -o $@
	$(OBJC) -c -noFiler $(CFLAGS) $(OBJC_INCLUDES) $(INCLUDES) $(SYS_INCLUDES) $(CT_DEFINES) $(OBJCOPT) $< -o $@

%.o : %.c
	echo Compiling $< ...
	$(OBJC) -c $(CFLAGS) $(OBJC_INCLUDES) $(INCLUDES) $(SYS_INCLUDES) $(CT_DEFINES) $(OBJCOPT) $< -o $@

		
##########################################
# Objetivos
##########################################

LIB: $(OBJECTS)
	$(AR) r $(OUT_LIB_PATH)/$(OUT_LIB) $(OBJECTS)

# generacion de la aplicacion
TARGET: $(LIB)

include $(OBJECTS:.o=.d)

clean:
	rm -f $(OUT_LIB_PATH)/$(OUT_LIB)

