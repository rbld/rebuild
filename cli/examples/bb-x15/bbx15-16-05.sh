#!/bin/bash -ex

TOOLCHAIN_FILE_EXT=.tar.xz
TOOLCHAIN_FILE=gcc-linaro-5.3.1-2016.05-x86_64_arm-linux-gnueabihf${TOOLCHAIN_FILE_EXT}
TOOLCHAIN_PATH=https://releases.linaro.org/components/toolchain/binaries/5.3-2016.05/arm-linux-gnueabihf/

wget -c ${TOOLCHAIN_PATH}${TOOLCHAIN_FILE}

rbld create --base ubuntu:16.04 bb-x15
rbld modify bb-x15:initial -- "sudo apt-get update && sudo apt-get install -y make xz-utils"
rbld modify bb-x15:initial -- "(cd /; sudo tar -Jxf -) < $TOOLCHAIN_FILE"
rbld modify bb-x15:initial -- "echo export CC=/`basename $TOOLCHAIN_FILE $TOOLCHAIN_FILE_EXT`/bin/arm-linux-gnueabihf- | sudo tee -a /rebuild/rebuild.rc > /dev/null"
                       
rbld commit bb-x15 --tag 16-05
rbld rm bb-x15:initial

rm -f $TOOLCHAIN_FILE

