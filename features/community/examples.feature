@community
Feature: environment creation examples
  As a rebuild community participant
  I want to see examples for creation of rebuild environments

  @skip-on-windows
  Scenario Outline: verify example scripts
    Given non-existing environment <environment name>:initial
    And non-existing environment <environment name>:<environment tag>
    When I successfully run `./cli/examples/<script>`
    Then environment <environment name>:<environment tag> should exist
    When I run `rbld run <environment name>:<environment tag> -- exit 5`
    Then the exit status should be 5
    When I run `rbld run <environment name>:<environment tag> -- exit 0`
    Then the exit status should be 0

    Examples:
      | script                         | environment name     | environment tag |
      | qemu/qemu-fc20.sh              | qemu-fc20            | v001            |
      | qemu/qemu-fc23.sh              | qemu-fc23            | v001            |
      | bb-x15/bbx15-16-05.sh          | bb-x15               | 16-05           |
      | raspberry-pi/rpi-raspbian.sh   | rpi-raspbian         | v001            |
