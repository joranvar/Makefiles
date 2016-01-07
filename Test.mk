TEST_diff    ?= env diff
TEST_testDir ?= test

include $(MAKE_utilsDir)/MakeUtils.mk

### Functions
define TEST_mkCompareTarget = # result[,expected]
$(eval $(call TEST_mkCompareRule,$(1),$(or $(2),$(TEST_testDir)/$(1).gold)))$(TEST_testDir)/$(1).success
endef

define TEST_mkGoldTarget = # compare_target
$(1:.success=.create_gold)
endef

### Target templates
define TEST_mkCompareRule =
 ifndef $(TEST_testDir)/$(1).success_defined
 $(TEST_testDir)/$(1).success: $(1) $(2)
	mkdir -p $$(@D)
	$(TEST_diff) $(1) $(2) && touch $$@

 .PHONY: $(TEST_testDir)/$(1).create_gold
 $(TEST_testDir)/$(1).create_gold: $(1)
	mkdir -p $$(@D)
	cat $(1) > $$(patsubst %.create_gold,%.gold,$$@)
 $(TEST_testDir)/$(1).success_defined = 1
 endif
endef

### Default targets
.PHONY: cleanall
cleanall: TEST_clean

.PHONY: cleandeep
cleandeep: TEST_cleandeep

.PHONY: TEST_clean
TEST_clean: TEST_cleansuccess

.PHONY: TEST_cleansuccess
TEST_cleansuccess:
	$(call MAKE_clean,$(patsubst %_defined,%,$(filter %.success_defined,$(.VARIABLES))))

# Gold should not be deleted easily, most of the time it comes from an earlier iteration
.PHONY: TEST_cleandeep
TEST_cleandeep: TEST_cleangold

.PHONY: TEST_cleangold
TEST_cleangold:
	$(call MAKE_clean,$(patsubst %.success_defined,%.gold,$(filter %.success_defined,$(.VARIABLES))))
