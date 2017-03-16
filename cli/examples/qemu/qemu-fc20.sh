#!/bin/bash -ex

rbld create --base fedora:20 qemu-fc20
rbld modify qemu-fc20 -- sudo yum install -y make gcc gcc-c++ \
                                             zlib-devel glib2-devel \
                                             pixman pixman-devel \
                                             libfdt-devel lttng-ust-devel
rbld commit qemu-fc20 --tag v001

rbld rm qemu-fc20:initial
