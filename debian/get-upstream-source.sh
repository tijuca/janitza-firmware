#!/bin/bash

# get-upstream-source.sh
# part of the *.deb packaging files for janitza-firmware
#
# Download all the *.zip files from http://www.janitza.de/files/download/firmware/
# and unpack them into $package/debian/download

DOWNLOAD="debian/download"

if [ -d debian ]; then
    if [ -d ${DOWNLOAD} ]; then
        rm -f ${DOWNLOAD}/*
    else
        mkdir -p ${DOWNLOAD}
    fi
else
    echo "Couldn't find directory 'debian', script started from the correct folder?"
fi

FILE_LIST=\
`curl --silent -L  http://janitza.de/firmware-download.html |\
tr "<>" '\n' |\
grep data-href |\
awk '{print $6;}' |\
tr '"' ' ' | cut -f 3 -d =`

cd ${DOWNLOAD}

for i in ${FILE_LIST}; do
    echo "downloading --> ${i##*/}"
    wget -nv http://janitza.de/$i
    echo
done

# generate a md5sum list from the files that are downloaded
md5sum *.zip > md5sum.list

# going thrue the list and compare with the already imported files
while read LINE; do
    # getting variables from the new file
    MD5SUM=`echo ${LINE} | awk '{print $1;}'`
    FILE=`echo ${LINE} | awk '{print $2;}'`
    if [ -f ../../${FILE} ]; then
        # reading the md5dsum from the original file
        MD5SUM_ORIG=`md5sum ../../${FILE} | awk '{print $1;}'`
        # now comparing ...
        if [ "$MD5SUM" = "$MD5SUM_ORIG" ]; then
				echo "Equal files, no further action needed (${FILE})."
        else
             echo "File ${FILE} is different to original, copy to \${TOPDIR}."
             cp -f ${FILE} ../../
        fi
    echo
    else
        # we can't find the file in the already imported files
        echo "${FILE} is new, copy to \${TOPDIR}!"
        cp ${FILE} ../../
    fi
done < md5sum.list
