TEST_diff    ?= env diff
TEST_testDir ?= test

### Functions
define TEST_mkCompareTarget = # result[,expected]
$(eval $(call TEST_mkCompareRule,$(1),$(or $(2),$(addprefix $(TEST_testDir)/,$(addsuffix .expected,$(1))))))$(TEST_testDir)/$(1).success
endef

define TEST_mkGoldTarget = # compare_target
$(1:.success=.gold)
endef

### Target templates
define TEST_mkCompareRule =
 ifndef $(TEST_testDir)/$(1).success_defined
 $(TEST_testDir)/$(1).success: $(1) $(2)
	mkdir -p $$(@D)
	$(TEST_diff) $(1) $(2) && touch $$@

 .PHONY: $(TEST_testDir)/$(1).gold
 $(TEST_testDir)/$(1).gold: $(1)
	mkdir -p $(dir $(2))
	cat $(1) > $(2)
 $(TEST_testDir)/$(1).success_defined = 1
endif
endef