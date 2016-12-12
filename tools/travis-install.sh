#!/usr/bin/env bash

set -e
set -x

rm -f *.gem

if [ "x${installed}" == "x1" ]; then
  gem build rbld.gemspec
  gem install ./rbld*.gem
fi

if [ "x${gem_sanity}" != "x1" ]; then
  bundle install --with="development test"
fi
