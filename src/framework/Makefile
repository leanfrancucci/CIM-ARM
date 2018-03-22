ifndef CT_HOME
$(error Enviorement variable CT_HOME not set, p.e: /c/Proyectos/ct)
endif

ifndef PLATFORM
$(error Enviorement variable PLATFORM not set, should be win32, linux, uclinux)
endif

APPLICATION=$(CT_HOME)/bin/tariff.exe
DLL=$(CT_HOME)/bin/ctsystem.dll
TEST_APPLICATION=$(CT_HOME)/bin/test.exe

.PHONY: rmtest exe bill main dao system ui audit xml cim settings clean test testlib message telesup help install compileandinstall

TARGET: application

telesup: 
	make -s -f telesup/Makefile
	
settings: 
	make -s -f settings/Makefile
	
bill: 
	make -s -f bill/Makefile	

main:
	make -s -f main/Makefile
	
dao:
	make -s -f dao/Makefile
	
system:
	make -s -f system/Makefile
	
ui:
	make -s -f ui/Makefile

audit:  
	make -s -f audit/Makefile

cim:  
	make -s -f cim/Makefile

reports:
	make -s -f reports/Makefile
		
message:
	make -s -f message/Makefile	

xml:
	make -s -f xml/Makefile

testlib:
	make -s -f test/Makefile

application: bill dao main system ui settings audit xml cim message telesup exe 

help:
	cd $(CT_HOME)/doc && doxygen Doxyfile
	
CT_LIBS=main system dao bill ui audit xml cim settings message telesup 

LIBS=-lsettings -lsystem -ldao -lbill -lui -laudit -lxml -lcim \
     -lsysutil -lsysnet -lsysdev -lsysio -lsysdb -lsysos -lmessage -lsysui -ltelesup -lsysprinter 

ifeq ($(CT_SQL_DB),y) 
LIBS+= fbwrapc.dll
endif

ifeq "$(PLATFORM)" "linux"
NLIBS= -lncurses
endif

ifeq "$(PLATFORM)" "arm-linux"
NLIBS= -lncurses
endif
	
		 
OBJC_LIBS=-lobjcrt -lobjpak -lcakit -lpthread
OS_LIBS=

OBJC=objc

LDFLAGS=--verbose
#LIB_PATH=-L/usr/lib/i386-linux-gnu -L$(CT_HOME)/lib/$(PLATFORM) -L$(OBJC_HOME)/lib
LIB_PATH=-L$(CT_HOME)/lib/$(PLATFORM) -L$(OBJC_HOME)/lib

########################################################
# Definiciones especificas para plataforma Linux
########################################################
ifeq "$(PLATFORM)" "arm-linux"
	
	OS_LIBS= -lm -lscew -lexpat -lssl -lcrypto -ldl
 
endif

ifeq "$(PLATFORM)" "linux"
	
	OS_LIBS=-lm -lscew -lexpat -lssl -lcrypto
 
endif

########################################################
# Definiciones especificas para plataforma Win32
########################################################
ifeq "$(PLATFORM)" "win32"

	OS_LIBS=-lwsock32 -lscew -lexpat -liberty

endif

########################################################
# Ejecutable a generar
########################################################
ifneq "$(PLATFORM)" "uclinux"

ifeq "$(CT_DEBUG_MALLOC)" "true"
	DEBUG_LIBS=-lefence
endif

exe: 
	$(CC) -Os -D_ISOC99_SOURCE $(LIB_PATH) -Wl,--start-group $(LIBS) $(DEBUG_LIBS) -lmain -g -Wl,--end-group $(OBJC_LIBS) $(OS_LIBS) $(NLIBS) -o $(APPLICATION)

endif	


ifeq "$(PLATFORM)" "uclinux"

UCLINUX_BUILD_USER=1
AR=m68k-elf-ar
CC=m68k-elf-gcc
export UCLINUX_BUILD_USER

include $(ROOTDIR)/.config
include $(ROOTDIR)/config.arch

exe:
	$(CC) -v -Os --strip-all -L$(CT_HOME)/lib/uclinux/uclibc \
	$(LDFLAGS) $(MAIN) $(INCLUDES) -Wl,--start-group \
	$(CT_HOME)/lib/uclinux/libmain.a $(CT_HOME)/lib/uclinux/libmessage.a \
	$(CT_HOME)/lib/uclinux/libsettings.a \
	$(CT_HOME)/lib/uclinux/libsystem.a \
	$(CT_HOME)/lib/uclinux/libdao.a \
	$(CT_HOME)/lib/uclinux/libbill.a \
	$(CT_HOME)/lib/uclinux/libtelesup.a \
	$(CT_HOME)/lib/uclinux/libui.a \
	$(CT_HOME)/lib/uclinux/libaudit.a \
	$(CT_HOME)/lib/uclinux/libxml.a \
	$(CT_HOME)/lib/uclinux/libcim.a \
	$(CT_HOME)/lib/uclinux/libsysutil.a \
	$(CT_HOME)/lib/uclinux/libsysnet.a \
	$(CT_HOME)/lib/uclinux/libsysdev.a \
	$(CT_HOME)/lib/uclinux/libsysio.a \
	$(CT_HOME)/lib/uclinux/libsysdb.a \
	$(CT_HOME)/lib/uclinux/libsysui.a \
	$(CT_HOME)/lib/uclinux/libsysos.a \
	$(CT_HOME)/lib/uclinux/libsysprinter.a \
	$(CT_HOME)/lib/uclinux/libexpat.a \
	$(CT_HOME)/lib/uclinux/libscew.a \
	$(CT_HOME)/lib/uclinux/libssl.a \
	$(CT_HOME)/lib/uclinux/libcrypto.a \
	-Wl,--end-group -lm  \
	$(CT_HOME)/lib/uclinux/objcrt.a \
	$(CT_HOME)/lib/uclinux/objpak.a \
	-lpthread -o $(APPLICATION) $(LDLIBS)
	flthdr -s 32768 $(APPLICATION)


#	$(CC) -Os --strip-all $(LIB_PATH) $(LDFLAGS) $(INCLUDES) obj/*.o  $(CT_HOME)/lib/uclinux/objcrt.a $(CT_HOME)/lib/uclinux/objpak.a -lpthread -o $(APPLICATION) $(LDLIBS) -lm
	
endif


########################################################
# DLL a generar
########################################################
dll: 
	$(OBJC) -dl -postlink -dynamic -L$(CT_HOME)/lib/$(PLATFORM) -L$(CT_HOME)/lib/dll -lobjcrt -lobjpak tmpobj/*.o $(OS_LIBS) -o $(DLL)

	
########################################################
# Testing automatico
########################################################

test: testlib
#	$(CC) -Os $(LIB_PATH) -Wl,--start-group $(LIBS) -ltest -Wl,--end-group $(OBJC_LIBS) $(OS_LIBS) -o $(TEST_APPLICATION)
#	cd ../../bin && ./beforetest.bat && ./test.exe

gentest:
	make gentest -f test/Makefile

rmtest:
	rm -f obj/test.o  
	rm -f $(CT_HOME)/lib/$(PLATFORM)/libtest.a 
	make test
	
########################################################
# Todo
########################################################		

all: application test
	
LIBS_WITH_PATH=$(CT_LIBS:%=$(CT_HOME)/lib/$(PLATFORM)/lib%.a)

install:
	echo Installing aplication in $(CT_INSTALL_DIR)
	cp $(CT_HOME)/bin/tariff.exe $(CT_INSTALL_DIR)

compileandinstall: application install
		
clean:
	rm -f *.o *.d
	rm -f $(LIBS_WITH_PATH)

