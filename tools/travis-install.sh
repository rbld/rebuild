#!/usr/bin/env bash

try_with_sudo()
{
  $1 || sudo $1
}

set -e
set -x

rm -f *.gem

if [ "x${installed}" == "x1" ]; then
  gem build rbld.gemspec
  try_with_sudo "gem install ./rbld*.gem"
else
  try_with_sudo "gem uninstall rbld --all --executables"
fi

if [ "x${gem_sanity}" != "x1" ]; then
  bundle install --with="development test"
fi
