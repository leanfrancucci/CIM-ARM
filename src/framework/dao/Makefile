# el archivo ejecutable generado
OUT_LIB=libdao.a

include ../.config.h
 
# archivos a compilar

ROP=ROPPersistence.o ROPAudit.o
		
SQL=SQLPersistence.o SQLAudit.o

DAO=DataSearcher.o \
		Persistence.o DataObject.o AmountSettingsDAO.o \
		BillSettingsDAO.o CommercialStateDAO.o \
		RegionalSettingsDAO.o PrintingSettingsDAO.o EventCategoryDAO.o \
		ProfileDAO.o UserDAO.o TelesupSettingsDAO.o \
		ConnectionSettingsDAO.o OperationDAO.o CommercialStateDAO.o AuditDAO.o FilteredRecordSet.o \
		RequestDAO.o DepositDAO.o CurrencyDAO.o ExtractionDAO.o TempDepositDAO.o ZCloseDAO.o \
		CimGeneralSettingsDAO.o RequestDAO.o DepositDAO.o CurrencyDAO.o \
		ExtractionDAO.o TempDepositDAO.o ZCloseDAO.o DoorDAO.o AcceptorDAO.o CimCashDAO.o \
		Makefile CashReferenceDAO.o SafeBoxRecordSet.o CashReferenceDAO.o BoxDAO.o \
		RepairOrderItemDAO.o LicenceModulesDAO.o BackupsDAO.o


OBJECTS=	$(DAO)
  
ifeq ($(CT_SQL_DB),y) 
	OBJECTS+= $(SQL)
else
	OBJECTS+= $(ROP)
endif
 
# paths
vpath %.m dao
vpath %.m dao/telesup

ifeq ($(CT_SQL_DB),y) 
  vpath %.m dao/sql
else
  vpath %.m dao/rop
endif       

# include de reglas de compilacion 
include includes.mak

# includes
INCLUDES=$(ALL_INCLUDES)
		 
