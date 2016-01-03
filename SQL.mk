SQL_startServer ?= # NOOP e.g. cd ~/git/vagrant-boxes && vagrant up # must be idempotent
SQL_sqshFlags   ?= #      e.g. -S localhost:1433 -U sa -P vagrant -G 7.0
SQL_dbDir       ?= db
SQL_sqsh	?= env sqsh

### Functions
define SQL_mkDatabaseTarget = # database_name
$(eval $(call SQL_mkDatabaseRule,$(1)))$(SQL_dbDir)/$(1).db
endef

define SQL_mkScriptSetTarget = # database_name,scriptset_name
$(eval $(call SQL_mkScriptSetRule,$(1),$(2)))$(addsuffix .out,$(addprefix $(SQL_dbDir)/$(1)/,$(2)))
endef

### Target templates
define SQL_mkDatabaseRule =
 ifndef $(SQL_dbDir)/$(1).db_defined
 $(SQL_dbDir)/$(1).db:
	mkdir -p $$(@D)
	@$(SQL_startServer)
	$(call SQL_runCommand,master,DROP DATABASE [$(1)]) || true
	$(call SQL_runCommand,master,CREATE DATABASE [$(1)])
	$(call SQL_runScripts,$(1),$$(filter %.sql,$$^)) -o$$@ || (cat $$@ && touch -dyesterday $$@ && exit 1)
 $(SQL_dbDir)/$(1).db_defined = 1
 endif
endef

define SQL_mkScriptSetRule =
 ifndef $(SQL_dbDir)/$(1)/$(2).out_defined
 $(SQL_dbDir)/$(1)/$(2).out: $(SQL_dbDir)/$(1).db
	mkdir -p $$(@D)
	@$(SQL_startServer)
	$(call SQL_runScripts,$(1),$$(filter %.sql,$$^)) -o$$@ || (cat $$@ && touch -dyesterday $$@ && exit 1)
 $(SQL_dbDir)/$(1)/$(2).out_defined = 1
 endif
endef

define SQL_runScripts =
	@echo Running $(2) on $(1)
	@for i in $(2); do cat $$$$i; echo "go"; done | $(SQL_sqsh) $(SQL_sqshFlags) -Lsemicolon_hack=0 -D"[$(1)]"
endef

define SQL_runCommand =
	@echo Running \"$(2)\" on $(1)
	@$(SQL_sqsh) $(SQL_sqshFlags) -Lsemicolon_hack=0 -C"\loop -e '$(2)'" -D"[$(1)]"
endef


### Default targets
.PHONY: cleanall
cleanall: SQL_clean

.PHONY: SQL_clean
SQL_clean: SQL_cleanoutput SQL_cleandb

.PHONY: SQL_cleanoutput
SQL_cleanoutput:
	rm -f $(patsubst %_defined,%,$(filter $(SQL_dbDir)%.out_defined,$(.VARIABLES)))

.PHONY: SQL_cleandb
SQL_cleandb:
	-$(foreach db,$(patsubst $(SQL_dbDir)/%.db_defined,%,$(filter %.db_defined,$(.VARIABLES))),$(call SQL_runCommand,master,DROP DATABASE [$(db)]))
	rm -f $(patsubst %_defined,%,$(filter $(SQL_dbDir)%.db_defined,$(.VARIABLES)))
