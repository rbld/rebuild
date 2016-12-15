#!/usr/bin/env bash

set -e
set -x

if [ "x${gem_sanity}" != "x1" ]; then
  rake spec citest
else
  rbld help
  rbld help list
  rbld list
fi
