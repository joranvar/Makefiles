MAKE_mono      ?= env mono
MAKE_toolsDir  ?= tools
NUNIT_testDir  ?= test

NUGET_nugetDir ?= lib/NuGet
include $(MAKE_utilsDir)/NuGet.mk

NUNIT_runner = $(call NUGET_mkNuGetContentsTarget,NUnit.ConsoleRunner,tools/nunit3-console.exe)
NUNIT_NUGET  = $(call NUGET_mkNuGetContentsTarget,NUnit,lib/net45/nunit.framework.dll)

### Functions
define NUNIT_mkTestTarget = # test_assembly
$(eval $(call NUNIT_mkTestRule,$(1)))$(NUNIT_testDir)/$(1).success
endef

### Target templates
define NUNIT_mkTestRule =
 ifndef $(NUNIT_testDir)/$(1).success_NUNIT_defined
 $(1): $(NUNIT_NUGET)
 $(NUNIT_testDir)/$(1).success: $(1) $(NUNIT_runner)
	mkdir -p $$(@D)
	$(MAKE_mono) $(NUNIT_runner) $(1) --noheader --result=$$(@:.success=.last) && touch $$@ || (rm $$@ && exit 1)
 $(NUNIT_testDir)/$(1).success_NUNIT_defined = 1
 endif
endef

### Default targets
.PHONY: cleanall
cleanall: NUNIT_clean

.PHONY: NUNIT_clean
NUNIT_clean:
	$(call MAKE_clean,$(patsubst %_NUNIT_defined,%,$(filter %.success_NUNIT_defined,$(.VARIABLES))))
	$(call MAKE_clean,$(patsubst %.success_NUNIT_defined,%.last,$(filter %.success_NUNIT_defined,$(.VARIABLES))))
