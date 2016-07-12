#!/bin/bash -ex

rbld create --base fedora:23 qemu-fc23
rbld modify qemu-fc23 -- sudo dnf install -y make gcc gcc-c++ \
                                             zlib-devel glib2-devel \
                                             pixman pixman-devel \
                                             libfdt-devel lttng-ust-devel \
                                             findutils
rbld commit qemu-fc23 --tag v001

