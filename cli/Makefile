prefix=/usr/local/
bin_dir=$(prefix)bin/
lib_dir=$(prefix)lib/
config_dir=$(prefix)etc/

VERSION=0.01

Q=@

EXEC_FILES = bin/rbld

HELPERS = lib/bootstrap/re-build-entry-point     \
          lib/bootstrap/re-build-env-prepare     \
          lib/bootstrap/re-build-bootstrap-utils \
          lib/bootstrap/rebuild.rc

RUBY_MODULES = lib/rbld_log.rb      \
               lib/rbld_print.rb    \
               lib/rbld_commands.rb \
               lib/rbld_envmgr.rb   \
               lib/rbld_config.rb   \
               lib/rbld_registry.rb \

COMMANDS = lib/commands/rbld_list.rb     \
           lib/commands/rbld_status.rb   \
           lib/commands/rbld_rm.rb       \
           lib/commands/rbld_save.rb     \
           lib/commands/rbld_load.rb     \
           lib/commands/rbld_checkout.rb \
           lib/commands/rbld_run.rb      \
           lib/commands/rbld_commit.rb   \
           lib/commands/rbld_modify.rb   \
           lib/commands/rbld_create.rb   \
           lib/commands/rbld_search.rb   \
           lib/commands/rbld_publish.rb  \
           lib/commands/rbld_deploy.rb

TESTS = tests/hello/hello.c tests/hello/Makefile

CONFIG = etc/rebuild.conf

DIST_FILES = $(EXEC_FILES)      \
             $(CONFIG)          \
             $(HELPERS)         \
             $(RUBY_MODULES)    \
             $(TESTS)           \
             Makefile

install:
	$(Q)install -vd $(bin_dir)
	$(Q)install -vt $(bin_dir) $(EXEC_FILES)
	$(Q)install -vd $(config_dir)
	$(Q)install -vt $(config_dir) $(CONFIG)
	$(Q)install -vd $(lib_dir)
	$(Q)install -vt $(lib_dir) $(RUBY_MODULES)
	$(Q)install -vd $(lib_dir)bootstrap
	$(Q)install -vt $(lib_dir)bootstrap $(HELPERS)
	$(Q)install -vd $(lib_dir)commands
	$(Q)install -vt $(lib_dir)commands $(COMMANDS)

uninstall:
	$(Q)cd $(prefix) && rm -vf $(EXEC_FILES) $(CONFIG) $(COMMANDS) $(RUBY_MODULES)

dist:
	$(Q)tar --transform "s|^|rebuild-v$(VERSION)/|" \
            -vcJ -f rebuild-v$(VERSION).tar.xz      \
            $(DIST_FILES)
	$(Q)echo && echo rebuild-v$(VERSION).tar.xz created
