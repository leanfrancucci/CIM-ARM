# el archivo ejecutable generado
OUT_LIB=libsettings.a

include ../.config.h
 
# archivos a compilar
OBJECTS=AmountSettings.o BillSettings.o CommercialState.o \
PrintingSettings.o RegionalSettings.o EventManager.o \
UserManager.o Profile.o User.o TelesupervisionManager.o TelesupSettings.o ConnectionSettings.o \
Operation.o DualAccess.o CommercialStateMgr.o Module.o CommercialUtils.o \
ModuleLicenceThread.o
						     
# paths
vpath %.m settings/bill
vpath %.m settings/commercial
vpath %.m settings/event
vpath %.m settings/regional
vpath %.m settings/telesup
vpath %.m settings/user

# include de reglas de compilacion 
include includes.mak

# includes
INCLUDES=$(ALL_INCLUDES)
		 

