#!/usr/bin/env bash

set -e
set -x

if [ "x${gem_sanity}" != "x1" ]; then
  rake spec

  echo Running local cucumber tests...
  local=1 rake citest

  echo Running remote cucumber tests for rebuild registry...
  remote=1 registry_type=rebuild rake citest

  echo Running remote cucumber tests for docker registry...
  remote=1 registry_type=docker rake citest

  echo Running remote cucumber tests for dockerhub registry...
  error=0
  remote=1 registry_type=dockerhub rake citest || error=1
  for i in {1..10}; do
    if [ "x${error}" != "x1" ]; then break; fi

    echo Running failed dockerhub tests again \(iteration \#$i\)...
    error=0

    cp tmp/last_failed_list.txt tmp/list_to_rerun.txt
    rerun=1 registry_type=dockerhub rake citest || error=1
  done

  exit $error
else
  rbld help
  rbld version
  rbld help list
  rbld list
fi
