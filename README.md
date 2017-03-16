[![Gem Version](https://img.shields.io/gem/v/rbld.svg)](https://rubygems.org/gems/rbld)
[![Build Status](https://travis-ci.org/rbld/rebuild.svg?branch=master)](https://travis-ci.org/rbld/rebuild)

# Usage

#### Install rebuild CLI

```bash
gem install rbld
```

#### Search for pre-created environments on Docker Hub

```bash
rbld search
```

#### Deploy environment for Raspberry Pi

```bash
rbld deploy rpi-raspbian:v001
```

#### Build code for Raspberry Pi

```bash
cd code-location
rbld run rpi-raspbian:v001 -- make -j8
```

#### Deploy environment for BeagleBoard-X15

```bash
rbld deploy bb-x15:16-05
```

#### Build code for BeagleBoard-X15

```bash
cd code-location
rbld run bb-x15:16-05 -- make -j8
```

#### Create environment for Raspberry Pi

```bash
git clone git://github.com/raspberrypi/tools.git rpi-tools

rbld create --base ubuntu:16.04 rpi-raspbian

rbld modify rpi-raspbian:initial

>> sudo apt-get update
>> sudo apt-get install -y make
>> TOOLCHAIN=gcc-linaro-arm-linux-gnueabihf-raspbian-x64
>> sudo cp -r rpi-tools/arm-bcm2708/$TOOLCHAIN /
>> echo export CC=/$TOOLCHAIN/bin/arm-linux-gnueabihf- | sudo tee -a /rebuild/rebuild.rc
>> exit

rbld commit rpi-raspbian --tag v001
```

# Project documentation

* Project WiKi at GitHub: https://github.com/rbld/rebuild/wiki
* Living Documentation at RelishApp: http://www.relishapp.com/rbld/rebuild

# Rebuild CLI gem

* Available at RubyGems: https://rubygems.org/gems/rbld

# Running tests

rebuild test suite is based on cucumber/aruba:

1. Run `bundle` to install cucumber, aruba and other dependencies
2. Run `cucumber [OPTIONS]` in the source tree root:
  * `cucumber` to run all tests using binaries from the working copy
  * `cucmber -p installed` to run tests using installed binaries
  * `cucumber -t ~@slow` to exclude slow tests

Use environment variable `registry_type` to control registry type used during tests:

  * `registry_type=rebuild cucumber ...` to use native rebuild registry (default)
  * `registry_type=docker cucumber ...` to use docker registry
  * `registry_type=dockerhub cucumber ...` to use Docker Hub (Docker Hub credentials needed)

---

    Rebuild is licensed under the Apache License, Version 2.0.
    See LICENSE for the full license text.
