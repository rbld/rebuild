[![Gem Version](https://img.shields.io/gem/v/rbld.svg)](https://rubygems.org/gems/rbld)
[![Build Status](https://travis-ci.org/rbld/rebuild.svg?branch=master)](https://travis-ci.org/rbld/rebuild)

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

---

    Rebuild is licensed under the Apache License, Version 2.0.
    See LICENSE for the full license text.
