
# Configuracion particulares

CT_DEFINES+= -DCT_INCLUDE_LINE_TELESUP -DSMALL_MEMORY_TARGET

ifeq "$(CT_GUI)" "PC"
CT_DEFINES+= -DCT_GUI_PC -DPFIRE
endif

ifeq "$(CT_VERSION)" "BEM"
CT_DEFINES+= -DHAVE_VISOR_ROTATION -DDISABLE_WORK_STATION_SERVICE -DDISABLE_CASH_REGISTER
endif

ifeq "$(CT_SQL_DB)" "y"
CT_DEFINES+= -DCT_SQL_DB
export CT_SQL_DB=y
endif

ifeq "(CT_INCLUDE_POLLING)" "y"
CT_DEFINES+= -DCT_INCLUDE_POLLING
endif

ifeq "$(PLATFORM)" "win32"
CT_DEFINES+= -DCT_INCLUDE_PARALLEL_PRINTER
export CT_INCLUDE_PARALLEL_PRINTER=y
endif

ifeq "$(PLATFORM)" "linux"
export CT_NCURSES_SUPPORT=true
endif

ifeq "$(PLATFORM)" "arm-linux"
export CT_NCURSES_SUPPORT=false
export USE_KEYBOARD=false
endif


export CT_INCLUDE_LINE_TELESUP=y

