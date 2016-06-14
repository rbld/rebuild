prefix=/usr/local/
bin_dir=$(prefix)bin/
libexec_dir=$(prefix)libexec/
config_dir=$(prefix)etc/

VERSION=0.01

Q=@

EXEC_FILES = bin/rbld

COMMANDS = libexec/re-build-cmd-checkout  \
           libexec/re-build-cmd-create    \
           libexec/re-build-cmd-list      \
           libexec/re-build-cmd-publish   \
           libexec/re-build-cmd-run       \
           libexec/re-build-cmd-status    \
           libexec/re-build-cmd-commit    \
           libexec/re-build-cmd-deploy    \
           libexec/re-build-cmd-modify    \
           libexec/re-build-cmd-rm        \
           libexec/re-build-cmd-search    \
           libexec/re-build-globals

HELPERS = libexec/re-build-entry-point \
          libexec/re-build-dep-install \
          libexec/rebuild.rc

TESTS = tests/hello/hello.c tests/hello/Makefile

CONFIG = etc/rebuild.conf

DIST_FILES = $(EXEC_FILES)      \
             $(COMMANDS)        \
             $(CONFIG)          \
             $(HELPERS)         \
             $(TESTS)           \
             Makefile

install:
	$(Q)install -vd $(bin_dir)
	$(Q)install -vt $(bin_dir) $(EXEC_FILES)
	$(Q)install -vd $(libexec_dir)
	$(Q)install -vt $(libexec_dir) $(COMMANDS) $(HELPERS)
	$(Q)install -vd $(config_dir)
	$(Q)install -vt $(config_dir) $(CONFIG)

uninstall:
	$(Q)cd $(prefix) && rm -vf $(EXEC_FILES) $(COMMANDS) $(CONFIG) $(HELPERS)

dist:
	$(Q)tar --transform "s|^|rebuild-v$(VERSION)/|" \
            -vcJ -f rebuild-v$(VERSION).tar.xz      \
            $(DIST_FILES)
	$(Q)echo && echo rebuild-v$(VERSION).tar.xz created

