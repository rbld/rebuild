#!/usr/bin/env bash

try_with_sudo()
{
  $1 || sudo $1
}

retry_last_set()
{
  for i in {1..10}; do
    if [ "x${error}" != "x1" ]; then break; fi

    echo Running failed $1 tests again \(iteration \#$i\)...
    error=0

    cp tmp/last_failed_list.txt tmp/list_to_rerun.txt
    rerun=1 registry_type=dockerhub rake citest || error=1
  done
}

set -e
set -x

plugin=rbld-plugin-hello
plugin_version=0.0.7

try_with_sudo "gem uninstall $plugin --all"

if [ "x${gem_sanity}" != "x1" ]; then
  rake license
  rake spec

  if [ "x${unit_test}" == "x1" ]; then
    exit 0
  fi

  echo Running plugin infrastructure tests...
  cp -v Gemfile Gemfile.backup
  echo "gem '$plugin', '$plugin_version'" >> Gemfile
  bundle install
  plugins=1 rake citest
  mv -v Gemfile.backup Gemfile

  echo Running local cucumber tests...
  if [ "x${slow}" != "x1" -a "x${community}" != "x1" ]; then
    local=1 rake citest
  else
    error=0
    local=1 rake citest || error=1
    retry_last_set slow
  fi

  echo Running remote cucumber tests for rebuild registry...
  remote=1 registry_type=rebuild rake citest

  echo Running remote cucumber tests for docker registry...
  remote=1 registry_type=docker rake citest
  error=0

  if [ "$TRAVIS_PULL_REQUEST" = "false" -o  "$TRAVIS_PULL_REQUEST" = "" ]; then

    echo Running remote cucumber tests for dockerhub registry...
    remote=1 registry_type=dockerhub rake citest || error=1
    retry_last_set DockerHub

  else

    echo WARNING: Skipping dockerhub registry tests for pull requests...

  fi

  exit $error
else
  rbld help
  rbld version
  rbld help list

  #Do basic plugins tests

  try_with_sudo "gem install $plugin --version $plugin_version"

  if test -z "`rbld help | grep 'Hello from Rebuild CLI plugin'`"; then
    exit 1
  fi

  try_with_sudo "gem uninstall $plugin --version $plugin_version"

  if test -n "`rbld help | grep 'Hello from Rebuild CLI plugin'`"; then
    exit 1
  fi

fi
