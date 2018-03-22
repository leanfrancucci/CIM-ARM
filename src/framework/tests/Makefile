TARGET: test

# archivos a compilar
APPLICATION=test.exe

OBJECTS+=
#OBJECTS+= cashCodeBillAcceptorMgr.o

include ../.config.h

# paths
vpath %.m tests/mocks
vpath %.c tests/mocks

# include de reglas de compilacion 
include includes.mak

# includes
INCLUDES=$(ALL_INCLUDES) -Itests/cut-2.3

UCLINUX_BUILD_USER=1
AR=m68k-elf-ar
CC=m68k-elf-gcc
export UCLINUX_BUILD_USER

include $(ROOTDIR)/.config
include $(ROOTDIR)/config.arch

#TEST_DEPOSIT_DAO_SRC = test/test_DepositDAO.m
#TEST_DEPOSIT_DAO_OBJ = test/test_DepositDAO.o

gentest:
	tests/cutgen tests/test_Doors.m tests/test_Deposit.m tests/test_Extraction.m tests/test_ExtractionWorkflow.m tests/test_InstaDrop.m $(TEST_DEPOSIT_DAO_SRC) > tests/mainTest.m

libtest: tests/test_Deposit.o tests/test_Doors.o tests/test_Extraction.o $(TEST_DEPOSIT_DAO_OBJ) tests/test_ExtractionWorkflow.o tests/test_InstaDrop.o tests/mainTest.o tests/mocks/GenericMock.o

test: libtest
	$(CC) -v -Os --strip-all -L$(CT_HOME)/lib/uclinux/uclibc \
	$(LDFLAGS) $(MAIN) $(INCLUDES) -Wl,--start-group \
	tests/mainTest.o \
	tests/test_Deposit.o \
	tests/test_Doors.o \
	tests/test_InstaDrop.o \
	tests/test_Extraction.o \
	$(TEST_DEPOSIT_DAO_OBJ) \
	tests/test_ExtractionWorkflow.o \
	tests/mocks/GenericMock.o \
  $(CT_HOME)/lib/uclinux/libmessage.a \
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
	-Wl,--end-group -lm  \
	$(CT_HOME)/lib/uclinux/objcrt.a \
	$(CT_HOME)/lib/uclinux/objpak.a \
	-lpthread -o $(CT_HOME)/bin/$(APPLICATION) $(LDLIBS)
	flthdr -s 32768 $(CT_HOME)/bin/$(APPLICATION)
