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
BASE_SCR=$(CT_HOME)/src
BASE_FW_SCR=$(CT_HOME)/src/framework
OBJC_INCLUDES=-I$(OBJC_BASE)/include/objcrt -I$(OBJC_BASE)/include/objpak

CT_DEFINES+=$(USER_DEBUG_MODULES) 

ALL_INCLUDES=\
	 -I$(BASE_SCR) \
	 -I$(BASE_SCR)/system \
	 -I$(BASE_SCR)/system/os \
	 -I$(BASE_SCR)/system/$(PLATFORM) \
	 -I$(BASE_SCR)/system/io  \
	 -I$(BASE_SCR)/system/db \
	 -I$(BASE_SCR)/system/db/rop \
	 -I$(BASE_SCR)/system/net \
	 -I$(BASE_SCR)/system/dev \
	 -I$(BASE_SCR)/system/dev/dallas \
	 -I$(BASE_SCR)/system/util \
	 -I$(BASE_SCR)/system/include \
 	 -I$(BASE_SCR)/system/lang \
	 -I$(BASE_SCR)/system/ui \
	 -I$(BASE_SCR)/system/ui/jlcd \
	 -I$(BASE_SCR)/system/ui/jlcd/jcontrols \
	 -I$(BASE_SCR)/system/ui/jlcd/jforms \
	 -I$(BASE_SCR)/system/ui/jlcd/jvscreen \
   -I$(BASE_SCR)/system/printer \
   -I$(BASE_SCR)/includes \
	 -I$(BASE_SCR)/exports \
	 -I$(BASE_FW_SCR) \
	 -I$(BASE_FW_SCR)/visor \
   -I$(BASE_FW_SCR)/sms \
   -I$(BASE_FW_SCR)/workstation \
	 -I$(BASE_FW_SCR)/table \
	 -I$(BASE_FW_SCR)/bill \
	 -I$(BASE_FW_SCR)/viewer \
	 -I$(BASE_FW_SCR)/audit  \
   -I$(BASE_FW_SCR)/xml  \
	 -I$(BASE_FW_SCR)/message \
	 -I$(BASE_FW_SCR)/system \
	 -I$(BASE_FW_SCR)/system/facade \
	 -I$(BASE_FW_SCR)/system/license \
	 -I$(BASE_FW_SCR)/reports \
	 -I$(BASE_FW_SCR)/tariff \
	 -I$(BASE_FW_SCR)/tariff/destination \
	 -I$(BASE_FW_SCR)/tariff/cabin \
	 -I$(BASE_FW_SCR)/tariff/digit \
	 -I$(BASE_FW_SCR)/tariff/initsignal \
	 -I$(BASE_FW_SCR)/tariff/appraiser \
	 -I$(BASE_FW_SCR)/tariff/call \
	 -I$(BASE_FW_SCR)/tariff/router \
	 -I$(BASE_FW_SCR)/tariff/locator \
	 -I$(BASE_FW_SCR)/tariff/searchers \
	 -I$(BASE_FW_SCR)/tariff/table \
	 -I$(BASE_FW_SCR)/tariff/promotion \
	 -I$(BASE_FW_SCR)/dao \
	 -I$(BASE_FW_SCR)/telesup \
	 -I$(BASE_FW_SCR)/dao/rop \
   -I$(BASE_FW_SCR)/dao/sql \
	 -I$(BASE_FW_SCR)/cim \
	 -I$(BASE_FW_SCR)/cim/device \
	 -I$(BASE_FW_SCR)/ui \
	 -I$(BASE_FW_SCR)/ui/remote \
	 -I$(BASE_FW_SCR)/ui/visor \
	 -I$(BASE_FW_SCR)/ui/remote \
	 -I$(BASE_FW_SCR)/ui/lcd \
	 -I$(BASE_FW_SCR)/ui/lcd/util \
	 -I$(BASE_FW_SCR)/ui/lcd/forms \
	 -I$(BASE_FW_SCR)/ui/lcd/forms/bill \
	 -I$(BASE_FW_SCR)/ui/lcd/forms/workStation \
   -I$(BASE_FW_SCR)/ui/lcd/forms/workStation/tariffTable \
   -I$(BASE_FW_SCR)/ui/lcd/forms/cabin \
	 -I$(BASE_FW_SCR)/ui/lcd/forms/general \
	 -I$(BASE_FW_SCR)/ui/lcd/forms/lines \
	 -I$(BASE_FW_SCR)/ui/lcd/forms/regionalSettings \
	 -I$(BASE_FW_SCR)/ui/lcd/forms/security \
	 -I$(BASE_FW_SCR)/ui/lcd/forms/cim \
	 -I$(BASE_FW_SCR)/ui/lcd/forms/visor \
   -I$(BASE_FW_SCR)/ui/lcd/forms/products \
	 -I$(BASE_FW_SCR)/ui/lcd/forms/supervision \
	 -I$(BASE_FW_SCR)/ui/lcd/forms/reprint \
	 -I$(BASE_FW_SCR)/ui/lcd/forms/sms \
	 -I$(BASE_FW_SCR)/bill/tax \
	 -I$(BASE_FW_SCR)/bill/numerator \
	 -I$(BASE_FW_SCR)/bill/paymode \
	 -I$(BASE_FW_SCR)/bill/round \
	 -I$(BASE_FW_SCR)/bill/cashregister \
	 -I$(BASE_FW_SCR)/settings \
	 -I$(BASE_FW_SCR)/settings/bill \
	 -I$(BASE_FW_SCR)/settings/cabin \
	 -I$(BASE_FW_SCR)/settings/commercial \
	 -I$(BASE_FW_SCR)/settings/general  \
	 -I$(BASE_FW_SCR)/settings/regional \
	 -I$(BASE_FW_SCR)/settings/visor \
	 -I$(BASE_FW_SCR)/settings \
	 -I$(BASE_FW_SCR)/settings/product \
	 -I$(BASE_FW_SCR)/settings/event \
	 -I$(BASE_FW_SCR)/settings/user \
	 -I$(BASE_FW_SCR)/settings/telesup \
	 -I$(BASE_FW_SCR)/settings/workStation \
	 -I$(BASE_FW_SCR)/workstation \
   -I$(BASE_FW_SCR)/reports \
	 -I$(BASE_FW_SCR)/telesup \
   -I$(BASE_FW_SCR)/telesup/linetelesup \
    -I$(BASE_FW_SCR)/telesup/console \
	 -I$(BASE_FW_SCR)/telesup/request \
	 -I$(BASE_FW_SCR)/telesup/request/PFire \
	 -I$(BASE_FW_SCR)/telesup/request/Pims \
	 -I$(BASE_FW_SCR)/telesup/g2 \
 	 -I$(BASE_FW_SCR)/telesup/imas \
	 -I$(BASE_FW_SCR)/telesup/telefonica \
	 -I$(BASE_FW_SCR)/telesup/telecom \
	 -I$(BASE_FW_SCR)/telesup/linetelesup \
	 -I$(BASE_FW_SCR)/telesup/filetransfer \
	 -I$(BASE_FW_SCR)/ui/visor \
	 -I$(BASE_FW_SCR)/xml \
	 -I$(BASE_FW_SCR)/test \
	 -I$(BASE_FW_SCR)/test/common

CFLAGS=


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

	OBJCOPT=-noNilRcvr -noFwd -noBlocks -noFiler -Wall -noCategories -q \
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
	$(GCC) -M $(INCLUDES) $(SYS_INCLUDES) $(CT_DEFINES) $< | sed 's/$*\.o/& $@/g' > $@

%.d: %.m
	echo Generating dependencies for $< ...
	$(GCC) -M $(OBJC_INCLUDES) $(INCLUDES) $(SYS_INCLUDES) $(CT_DEFINES) -D__PORTABLE_OBJC__ $< | sed 's/$*\.o/& $@/g' > $@
	
%.o: %.m
	echo Compiling $< ...
	$(OBJC) -c -noFiler $(CFLAGS) $(OBJC_INCLUDES) $(INCLUDES) $(SYS_INCLUDES) $(CT_DEFINES) $(OBJCOPT) $< -o $@

%.o : %.c
	echo Compiling $< ...
	$(OBJC) -c -noFiler  $(CFLAGS) $(OBJC_INCLUDES) $(INCLUDES) $(SYS_INCLUDES) $(CT_DEFINES) $(OBJCOPT) $< -o $@


		
##########################################
# Objetivos
##########################################

LIB: $(OBJECTS)
	$(AR) r $(OUT_LIB_PATH)/$(OUT_LIB) $(OBJECTS)

# generacion de la aplicacion
TARGET: $(LIB)

include $(OBJECTS:.o=.d)


