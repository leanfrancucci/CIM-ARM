# el archivo ejecutable generado
OUT_LIB=libtelesup.a

include ../.config.h

# archivos a compilar
 
DMODEM=DModemProto.o dmodem.o ptsm.o statesst.o

TELESUP=TelesupD.o TelesupParser.o \
	RemoteProxy.o InfoFormatter.o \
	Request.o GetRequest.o SetParamRequest.o SetEntityRequest.o  \
	TelesupScheduler.o TelesupViewer.o TelesupFactory.o TelesupErrorManager.o \
	DummyTelesupViewer.o Acceptor.o GenericGetRequest.o GenericSetRequest.o SimCardValidator.o \
	TelesupTest.o TemplateParser.o DummyRemoteProxy.o FTPSupervision.o POSAcceptor.o POSEventAcceptor.o

# TelesupSecurityManager.o  AskRequest.o 

# G2
TELESUP_G2= G2TelesupD.o  G2TelesupParser.o G2RemoteProxy.o G2InfoFormatter.o G2ActivePIC.o G2TelesupErrorManager.o cl_genericpkg.o 

REQUEST=GetFileRequest.o PutFileRequest.o \
		GetDataFileRequest.o \
		GetDateTimeRequest.o \
		GetAuditsRequest.o \
		CleanDataRequest.o RestartSystemRequest.o \
		PutTextMessagesRequest.o \
		GetDepositsRequest.o PimsRequest.o GetExtractionsRequest.o GetZCloseRequest.o GetXCloseRequest.o GetUserRequest.o \
		GetLogRequest.o \
		GetSettingsDumpRequest.o \
		GetGenericFileRequest.o \
		CipherManager.o FileManager.o ConsoleAcceptor.o SystemOpRequest.o AsyncMsgThread.o ExtractionController.o
		

#TelesupJob.o StartJobRequest.o CommitJobRequest.o RollbackJobRequest.o \

# IMAS  
TELESUP_TI= TIRemoteProxy.o TITelesupD.o TIInfoFormatter.o TITelesupParser.o ImasConfigLauncher.o CipherManager.o FileManager.o ImasConfiguration.o UpdateImasConfiguration.o RetransImasConfiguration.o GeneralImasConfiguration.o StateImasConfiguration.o
 
FILE_TRANSFER=FileTransfer.o DFileTransferProtocol.o

# LINE TELESUP
OBJECTS=$(TELESUP) $(REQUEST) $(FILE_TRANSFER) $(DMODEM) $(TELESUP_G2)

# $(TELESUP_TI)

# paths
vpath %.m telesup
vpath %.m telesup/request
vpath %.m telesup/request/PFire
vpath %.m telesup/request/Pims
vpath %.m telesup/g2
vpath %.m telesup/imas
vpath %.m telesup/dmodem
vpath %.c telesup/dmodem
vpath %.m telesup/filetransfer
vpath %.c telesup/filetransfer
vpath %.m telesup/console


# include de reglas de compilacion 
include includes.mak

# includes
INCLUDES=$(ALL_INCLUDES)

