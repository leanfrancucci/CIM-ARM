#!/bin/sh

if [ -n "$OS" ]; then

export CT_HOME=../..
export ROOTDIR=/data/uClinux-App
export PLATFORM=win32
export CT_GUI=PC
export CT_SQL_DB=y

else

export CT_HOME=../..
export ROOTDIR=/data/uClinux-App
export PLATFORM=uclinux

fi
