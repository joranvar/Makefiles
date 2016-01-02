SQLSTART ?= echo "Starting SQL"
SQSH_FLAGS ?=
SQSH_OUTPUT_FLAGS ?= -mcsv
CC.sql ?= env sqsh
OUTDIR ?= bin/
TESTDIR ?= test/

$(OUTDIR)%.db: DB_NAME = $(notdir $(basename $@))
$(OUTDIR)%.db: create_%.sql
	mkdir -p $(@D)
	$(SQLSTART)
	-$(CC.sql) $(SQSH_FLAGS) -C"DROP DATABASE [$(DB_NAME)];"
	$(CC.sql) $(SQSH_FLAGS) -C"CREATE DATABASE [$(DB_NAME)];"
	$(CC.sql) $(SQSH_FLAGS) $(SQSH_OUTPUT_FLAGS) -D"[$(DB_NAME)]" $(addprefix -i,$^) -e -o$@

cat_combined_with_go = for i in $(1); do cat $$i; echo "go"; done

$(TESTDIR)%.sql.success: DB_NAME   = $(firstword $(subst /, ,$(subst $(TESTDIR),,$@)))
$(TESTDIR)%.sql.success: TEST_NAME = $(*F)
$(TESTDIR)%.sql.success: SETUP     = $(wildcard $(<D)/$(TEST_NAME)_setup*.sql)
$(TESTDIR)%.sql.success: CLEANUP   = $(wildcard $(<D)/$(TEST_NAME)_cleanup*.sql)
$(TESTDIR)%.sql.success: EXPECT    = $(<D)/$(TEST_NAME)_expect.out
$(TESTDIR)%.sql.success: %_run_test.sql
	make $(OUTDIR)$(DB_NAME).db
	@echo "Running test:" $(TEST_NAME)
	@echo "Setup from files:" $(SETUP)
	-@$(call cat_combined_with_go,$(SETUP)) | $(CC.sql) $(SQSH_FLAGS) -D"[$(DB_NAME)]" -mnone -Lsemicolon_hack=0
	@echo "Running:" $(filter-out %run_test.sql,$^) $(filter %run_test.sql,$^)
	-@$(call cat_combined_with_go,$(filter-out %run_test.sql,$^) $(filter %run_test.sql,$^)) \
		| $(CC.sql) $(SQSH_FLAGS) $(SQSH_OUTPUT_FLAGS) -D"[$(DB_NAME)]" -Lsemicolon_hack=0 \
		| diff - $(EXPECT) && touch $@
	@echo "Cleanup from files:" $(CLEANUP)
	-@$(call cat_combined_with_go,$(CLEANUP)) | $(CC.sql) $(SQSH_FLAGS) -D"[$(DB_NAME)]" -mnone -Lsemicolon_hack=0

$(TESTDIR)%_expect.out: DB_NAME   = $(firstword $(subst /, ,$(subst $(TESTDIR),,$@)))
$(TESTDIR)%_expect.out: TEST_NAME = $(*F)
$(TESTDIR)%_expect.out: SETUP     = $(wildcard $(<D)/$(TEST_NAME)_setup*.sql)
$(TESTDIR)%_expect.out: CLEANUP   = $(wildcard $(<D)/$(TEST_NAME)_cleanup*.sql)
$(TESTDIR)%_expect.out: %_run_test.sql
	make $(OUTDIR)$(DB_NAME).db
	@echo "Creating expected data for test:" $(TEST_NAME)
	@echo "Setup from files:" $(SETUP)
	-@$(call cat_combined_with_go,$(SETUP)) | $(CC.sql) $(SQSH_FLAGS) -D"[$(DB_NAME)]" -mnone -Lsemicolon_hack=0
	@echo "Running:" $(filter-out %run_test.sql,$^) $(filter %run_test.sql,$^)
	-@$(call cat_combined_with_go,$(filter-out %run_test.sql,$^) $(filter %run_test.sql,$^)) \
		| $(CC.sql) $(SQSH_FLAGS) $(SQSH_OUTPUT_FLAGS) -D"[$(DB_NAME)]" -Lsemicolon_hack=0 -o $@
	@echo "Cleanup from files:" $(CLEANUP)
	-@$(call cat_combined_with_go,$(CLEANUP)) | $(CC.sql) $(SQSH_FLAGS) -D"[$(DB_NAME)]" -mnone -Lsemicolon_hack=0
