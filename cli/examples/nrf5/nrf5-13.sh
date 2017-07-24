#!/bin/bash -ex

TOOLCHAIN_FILE_EXT=.zip
TOOLCHAIN_FILE=nRF5_SDK_13.1.0_7ca7556
TOOLCHAIN_PATH=https://developer.nordicsemi.com/nRF5_SDK/nRF5_SDK_v13.x.x/

wget -c ${TOOLCHAIN_PATH}${TOOLCHAIN_FILE}${TOOLCHAIN_FILE_EXT}

rbld create --base ubuntu:16.04 nrf5
rbld modify nrf5:initial -- "sudo apt-get update"
rbld modify nrf5:initial -- "sudo apt-get install -y make unzip gcc-arm-none-eabi" 
rbld modify nrf5:initial -- "sudo unzip ${TOOLCHAIN_FILE}${TOOLCHAIN_FILE_EXT} -d /${TOOLCHAIN_FILE}"
rbld modify nrf5:initial -- "echo -e 'GNU_INSTALL_ROOT := /usr\nGNU_VERSION := 4.9.3\nGNU_PREFIX := arm-none-eabi' | sudo tee /${TOOLCHAIN_FILE}/components/toolchain/gcc/Makefile.posix"
rbld modify nrf5:initial -- "echo -e 'export NRF5_SDK_ROOT=/nRF5_SDK_13.1.0_7ca7556' | sudo tee -a /rebuild/rebuild.rc"
rbld commit nrf5 --tag 13
rbld rm nrf5:initial

rm -f $TOOLCHAIN_FILE
