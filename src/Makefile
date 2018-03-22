.PHONY: system framework all clean

export CT_HOME=../..
export ROOTDIR=/data/uClinux-App
#export PLATFORM=uclinux

TARGET: application

install:
	curl -T ../bin/tariff.exe ftp://192.168.0.4/var/tariff.exe --user root:r2V4L5c34N
	#curl -T ../bin/tariff.exe ftp://10.3.4.70/var/tariff.exe --user root:root
#	wput ../bin/tariff.exe ftp://10.3.4.30/var/tariff.exe
#	wput ../bin/config.ini ftp://10.3.4.30/var/config.ini
	echo Instalacion finalizada !
	
all:
	cd framework && ./makeall

system:
	cd system && colormake -s
	
framework: 
	cd framework && colormake -s
	
application: all

clean:
	cd system && make clean
	cd framework && make clean


