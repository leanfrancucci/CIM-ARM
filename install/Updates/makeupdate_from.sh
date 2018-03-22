#!/bin/sh

#
# Este script debe llamarse con el nombre de la version, que es el directorio donde se van a colocar
# los .tar.gz una vez generados.
#
# Ejemplo: ./makeupdate.sh "Update F0.7-DEL0.2-REL2006.08.16-RI02"
#
#

VERSION=$1
TARGET="Update a $VERSION"

echo "Creando update en la carpeta $TARGET"

rm update_to.tar.gz 2> /dev/null
rm update.tar.gz 2> /dev/null
rm update_app_to.tar.gz 2> /dev/null

rm -r temp 2> /dev/null
mkdir temp

cd $VERSION
tar -zxvvf ap.tar.gz
cd ..
cp $VERSION/rw/CT8016/tariff.exe update_app_to/rw/CT8016/
cp -R $VERSION/rw/CT8016/formatFiles update_to/copy/rw/CT8016/
cp -R $VERSION/rw/CT8016/data update_to/copy/rw/CT8016/
cp -R $VERSION/rw/CT8016/initFiles update_to/copy/rw/CT8016/

echo Eliminando archivos de configuracion de update_to/copy/rw/CT8016/data
rm update_to/copy/rw/CT8016/data/accepted_dep_value.dat 2> /dev/null
rm update_to/copy/rw/CT8016/data/acceptor_by_box.dat 2> /dev/null
rm update_to/copy/rw/CT8016/data/acceptor_by_cash.dat 2> /dev/null
rm update_to/copy/rw/CT8016/data/acceptors.dat 2> /dev/null
rm update_to/copy/rw/CT8016/data/amount_settings.dat 2> /dev/null
rm update_to/copy/rw/CT8016/data/bill_settings.dat 2> /dev/null
rm update_to/copy/rw/CT8016/data/box.dat 2> /dev/null
rm update_to/copy/rw/CT8016/data/cim_cash.dat 2> /dev/null
rm update_to/copy/rw/CT8016/data/cim_settings.dat 2> /dev/null
rm update_to/copy/rw/CT8016/data/commercial_state.dat 2> /dev/null
rm update_to/copy/rw/CT8016/data/currency_dep_value.dat 2> /dev/null
rm update_to/copy/rw/CT8016/data/denominations.dat 2> /dev/null
rm update_to/copy/rw/CT8016/data/doors_by_user.dat 2> /dev/null
rm update_to/copy/rw/CT8016/data/doors.dat 2> /dev/null
rm update_to/copy/rw/CT8016/data/dual_access.dat 2> /dev/null
rm update_to/copy/rw/CT8016/data/licence_modules.dat 2> /dev/null
rm update_to/copy/rw/CT8016/data/printing_settings.dat 2> /dev/null
rm update_to/copy/rw/CT8016/data/profiles.dat 2> /dev/null
rm update_to/copy/rw/CT8016/data/regional_settings.dat 2> /dev/null
rm update_to/copy/rw/CT8016/data/users.dat 2> /dev/null

cp -r update_to temp/
cp -r update temp/
cp -r update_app_to temp/

echo Eliminando archivos CVS
find temp/update_to | grep CVS$ | xargs rm -r 2>  /dev/null
find temp/update | grep CVS$ | xargs rm -r 2>  /dev/null
find temp/update_app_to | grep CVS$ | xargs rm -r  2> /dev/null

echo Eliminando archivos foo.txt
find temp/update_to | grep foo.txt | xargs rm 2> /dev/null
find temp/update | grep foo.txt | xargs rm  2> /dev/null
find temp/update_app_to | grep foo.txt | xargs rm  2> /dev/null
find temp/update_app_to -name *~ | xargs rm 2> /dev/null

echo Configurando permisos a los archivos
chmod 777 -R temp/update_to/*
chmod 777 -R temp/update/*
chmod 777 -R temp/update_app_to/*

cd temp/update_to
tar -cvvf update_to.tar .
mv update_to.tar ../..
cd ../..
gzip update_to.tar

cd temp/update
tar -cvvf update.tar .
mv update.tar ../..
cd ../..
gzip update.tar

cd temp/update_app_to
tar -cvvf update_app_to.tar .
mv update_app_to.tar ../..
cd ../..
gzip update_app_to.tar

rm -r "$TARGET" 2> /dev/null
mkdir "$TARGET"
mv update_to.tar.gz "$TARGET"
mv update.tar.gz "$TARGET"
mv update_app_to.tar.gz "$TARGET"
