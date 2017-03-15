#!/bin/bash -ex

git clone git://github.com/raspberrypi/tools.git rpi-tools

rbld create --base ubuntu:16.04 rpi-raspbian
rbld modify rpi-raspbian:initial -- "sudo apt-get update && sudo apt-get install -y make"
rbld modify rpi-raspbian:initial -- sudo cp -r rpi-tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64 /
rbld modify rpi-raspbian:initial -- "echo export CC=/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf- | sudo tee -a /rebuild/rebuild.rc > /dev/null"

rbld commit rpi-raspbian --tag v001
rbld rm rpi-raspbian:initial

rm -rf rpi-tools
