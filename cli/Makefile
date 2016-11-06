prefix=/usr/local/
bin_dir=$(prefix)bin/
lib_dir=$(prefix)lib/
libexec_dir=$(prefix)libexec/
config_dir=$(prefix)etc/

VERSION=0.01

Q=@

EXEC_FILES = bin/rbld

COMMANDS = libexec/re-build-cmd-create    \
           libexec/re-build-cmd-publish   \
           libexec/re-build-cmd-run       \
           libexec/re-build-cmd-commit    \
           libexec/re-build-cmd-deploy    \
           libexec/re-build-cmd-modify    \
           libexec/re-build-cmd-search    \
           libexec/re-build-globals

HELPERS = libexec/re-build-entry-point     \
          libexec/re-build-env-prepare     \
          libexec/re-build-bootstrap-utils \
          libexec/rebuild.rc

RUBY_MODULES = lib/rbld_log.rb      \
               lib/rbld_print.rb    \
               lib/rbld_commands.rb \
               lib/rbld_envmgr.rb   \
               lib/rbld_list.rb     \
               lib/rbld_status.rb   \
               lib/rbld_rm.rb       \
               lib/rbld_save.rb     \
               lib/rbld_load.rb     \
               lib/rbld_checkout.rb

TESTS = tests/hello/hello.c tests/hello/Makefile

CONFIG = etc/rebuild.conf

DIST_FILES = $(EXEC_FILES)      \
             $(COMMANDS)        \
             $(CONFIG)          \
             $(HELPERS)         \
             $(RUBY_MODULES)    \
             $(TESTS)           \
             Makefile

install:
	$(Q)install -vd $(bin_dir)
	$(Q)install -vt $(bin_dir) $(EXEC_FILES)
	$(Q)install -vd $(libexec_dir)
	$(Q)install -vt $(libexec_dir) $(COMMANDS) $(HELPERS)
	$(Q)install -vd $(config_dir)
	$(Q)install -vt $(config_dir) $(CONFIG)
	$(Q)install -vd $(lib_dir)
	$(Q)install -vt $(lib_dir) $(RUBY_MODULES)

uninstall:
	$(Q)cd $(prefix) && rm -vf $(EXEC_FILES) $(COMMANDS) $(CONFIG) $(HELPERS) $(RUBY_MODULES)

dist:
	$(Q)tar --transform "s|^|rebuild-v$(VERSION)/|" \
            -vcJ -f rebuild-v$(VERSION).tar.xz      \
            $(DIST_FILES)
	$(Q)echo && echo rebuild-v$(VERSION).tar.xz created
