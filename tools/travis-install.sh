#!/usr/bin/env bash

set -e
set -x

bundle install --without development
sudo make -C cli install
