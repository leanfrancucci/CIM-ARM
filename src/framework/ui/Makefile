# el archivo ejecutable generado
OUT_LIB=libui.a

include ../.config.h

# archivos a compilar


UI_UTIL=JCustomForm.o JListForm.o JEditForm.o JMessageDialog.o JCustomStatusBar.o \
JProgressBarForm.o \
JUserLoginForm.o JSplashForm.o JTelesupViewerForm.o LCDTelesupViewer.o JExceptionForm.o \
JSystem.o JInfoViewerForm.o JWorkOrderForm.o JSplashBackupForm.o

VIEWERS=

OBJECTS=$(UI_UTIL) $(VIEWERS) \
JDateTimeForm.o JMainMenuForm.o JSimpleSelectionForm.o \
JHeaderEditForm.o JFooterEditForm.o JPrintingEditForm.o \
JAmountEditForm.o JGeneralEditForm.o JRegionalSettingsEditForm.o \
JProfilesListForm.o JUsersListForm.o JUserEditForm.o JDateTimeForm.o JTelesupervisionsListForm.o \
JTelesupervisionEditForm.o JSystemInfoForm.o JTelesupTypesListForm.o JManualTelesupListForm.o \
JUserChangePinEditForm.o JSystemConfigForm.o JAutomaticDepositForm.o \
JNeedMoreTimeForm.o JVerifyBillForm.o JDoorStateForm.o UICimUtils.o \
JManualDepositListForm.o JSimpleCurrencyForm.o JSimpleTextForm.o JSimpleTimerForm.o JInstaDropSettingsForm.o JInstaDropForm.o \
JDoorDelaysForm.o JAuditReportDateEditForm.o JCashReferenceEditForm.o JCashReferenceListForm.o \
Option.o AlarmThread.o JCimCashListForm.o JCimCashEditForm.o \
JCashAcceptorsListForm.o AlarmThread.o JUpdateFirmwareForm.o JSimpleTimerLockForm.o \
JDoorOverrideForm.o JSelectRangeEditForm.o JProfilesEditForm.o \
JProfilesSelectOperationsEditForm.o JDoorsByUserListForm.o \
JDoorsByUserEditForm.o JDualAccessListForm.o JDualAccessEditForm.o JActivateDeactivateUserEditForm.o \
JIncomingTelTimerForm.o JExtendedDropDetailForm.o JRepairOrderForm.o JRepairOrderReport.o \
JCommercialStateChangeForm.o JForceAdminPasswForm.o JCommercialStCodeForm.o \
JSecondaryUserLoginForm.o JCimGeneralSettingsEditForm.o JSimpleDateForm.o JCimBackupSettingsEditForm.o \
JDeviceSelectionEditForm.o JReadDallasKeyForm.o JNumbersEntryForm.o JCimDeviceLoginSettingsEditForm.o JBoxModelChangeEditForm.o JDoorsListForm.o JDoorsEditForm.o \
RemoteConsole.o

ifeq "$(CT_GUI)" "PC"
OBJECTS=$(VIEWERS) 
endif


# paths
vpath %.m ui
vpath %.m ui/lcd
vpath %.m ui/lcd/util
vpath %.m ui/lcd/forms/bill	
vpath %.m ui/lcd/forms/cim	
vpath %.m ui/lcd/forms/general
vpath %.m ui/lcd/forms/regionalSettings
vpath %.m ui/lcd/forms/reprint
vpath %.m ui/lcd/forms/security
vpath %.m ui/lcd/forms/supervision
vpath %.m ui/remote

# include de reglas de compilacion 
include includes.mak

# includes
INCLUDES=$(ALL_INCLUDES)
		 

