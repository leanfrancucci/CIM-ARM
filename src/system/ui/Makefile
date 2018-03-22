# includes
INCLUDES=-Ios -Iutil -Ilang -Ios/$(PLATFORM) -I../ \
-Iui -Iui/jlcd/jvscreen  -Iui/jlcd/jlcdlib -Iui/jkeyboard/$(PLATFORM) -Iinclude \
-Iutil -Idev -Iprinter -I./

# el archivo ejecutable generado
OUT_LIB=libsysui.a

include ../.config.h

ADDITIONAL_OBJS=
ADDITIONAL_OBJS=JEventQueue.o InputKeyboardManager.o

COMPONENTS=
COMPONENTS=JVirtualScreen.o JGraphicContext.o JComponent.o \
JContainer.o JWindow.o JForm.o JDialog.o JApplication.o

CONTROLS=
CONTROLS=JScrollPanel.o JLabel.o JCombo.o JList.o JProgressBar.o \
JMainMenu.o JMenuItem.o JActionMenu.o JSubMenu.o \
JButton.o JCheckBox.o JGrid.o JText.o JNumericText.o JDate.o JTime.o \
JCheckBoxList.o

LCDLIB=lcdlib.o
ifeq "$(PLATFORM)" "uclinux"
LCDLIB=lcdlib.o unicodecvtr.o
endif

ifeq "$(PLATFORM)" "arm-linux"
LCDLIB=lcdlib.o unicodecvtr.o
endif

KEYPADLIB=keypadlib.o keypadconf.o
#KEYPADLIB=keypadlib.o

# archivos a compilar
ifeq "$(CT_GUI)" "PC"
OBJECTS= $(LCDLIB)
else
OBJECTS= $(COMPONENTS) $(CONTROLS) $(ADDITIONAL_OBJS) $(LCDLIB) $(KEYPADLIB)
endif



# paths a incluir
vpath %.m ui
vpath %.c ui
vpath %.m ui/jlcd
vpath %.c ui/jlcd
vpath %.m ui/jlcd/jvscreen
vpath %.c ui/jlcd/jvscreen
vpath %.c ui/jlcd/jlcdlib

ifeq "$(CT_NCURSES_SUPPORT)" "true"
vpath %.c ui/jlcd/jlcdlib/ncurses
INCLUDES+=-I/usr/include
CT_DEFINES+= -DCT_NCURSES_SUPPORT
else
vpath %.c ui/jlcd/jlcdlib/$(PLATFORM)
endif

vpath %.c ui/jkeyboard
vpath %.c ui/jkeyboard/$(PLATFORM)

# esto incluye todas las funciones necesarias
include includes.mak
