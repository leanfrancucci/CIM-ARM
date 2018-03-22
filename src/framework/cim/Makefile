
# el archivo ejecutable generado
OUT_LIB=libcim.a
 
# archivos a compilar
OBJECTS= \
	CimGeneralSettings.o \
	AcceptorSettings.o \
	CimManager.o \
	AbstractAcceptor.o \
	BillAcceptor.o \
	Door.o \
	Currency.o \
	CurrencyManager.o \
	CimState.o \
	Deposit.o \
	DepositDetail.o \
	Cim.o \
	EnvelopeAcceptor.o \
	AcceptedDepositValue.o \
	AcceptedCurrency.o \
	Denomination.o \
	CimStateDeposit.o \
	CimStateIdle.o \
	Extraction.o \
	ExtractionDetail.o \
	ExtractionManager.o \
	DepositManager.o \
	ExtractionWorkflow.o \
	CimCash.o \
	ZClose.o \
	ZCloseDetail.o \
	ZCloseManager.o \
	TimeLock.o \
	InstaDrop.o \
	InstaDropManager.o \
	DepositDetailReport.o \
	SafeBoxHAL.o \
	JcmThread.o \
	safeBoxComm.o \
	safeBoxMgr.o \
	CashReference.o \
	CashReferenceManager.o \
	UpdateFirmwareThread.o \
	CashReferenceSummary.o \
	logComm.o \
	doorover.o \
	CimEventDispatcher.o \
	CimBackup.o \
	CimEventDispatcher.o \
	Box.o \
	RepairOrder.o \
	RepairOrderItem.o \
	id0003Mapping.o \
	rdm100.o \
	RepairOrderManager.o \
	CdmCoinAcceptor.o \
	cdm3000.o \
	DallasDevThread.o \
	BagTrack.o \
	SwipeReaderThread.o \
	BoxModel.o \
	AESencript.o \
	dynamicPin.o

#	CimStateExtraction.o \
#OBJECTS+= TestCim.o

OBJECTS+= jcmBillAcceptorComm.o jcmBillAcceptorMgr.o

#OBJECTS+= cashCodeBillAcceptorMgr.o

include ../.config.h

# paths
vpath %.m cim
vpath %.c cim
vpath %.m cim/device
vpath %.c cim/device

# include de reglas de compilacion 
include includes.mak

# includes
INCLUDES=$(ALL_INCLUDES)
		 

