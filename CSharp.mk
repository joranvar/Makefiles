CSHARP_mcs	  ?= env mcs
CSHARP_System.dll ?= $(wildcard /nix/store/q3yf6a3ysjv0zgad9v2rb3rvllhih8l6-mono-4.0.3.20/lib/mono/4.5/Facades/*.dll)
CSHARP_binDir	  ?= $(MAKE_binDir)

include $(MAKE_utilsDir)/MakeUtils.mk

### Functions
define CSHARP_mkDllTarget = # dll_name
$(eval $(call CSHARP_mkDllRule,$(1)))$(CSHARP_binDir)/$(1)
endef

define CSHARP_mkExeTarget = # exe_name
$(eval $(call CSHARP_mkExeRule,$(1)))$(CSHARP_binDir)/$(1)
endef

### Target templates
define CSHARP_mkDllRule =
 ifndef $(CSHARP_binDir)/$(1)_CSHARP_dll_defined
 $(CSHARP_binDir)/$(1):
	mkdir -p $$(@D)
	$(CSHARP_mcs) $$(filter %.cs,$$^) $$(addprefix -r:,$$(filter %.dll,$$^)) -out:$$@ -t:library -pkg:dotnet
	if [ '$$(filter %.dll,$$^)x' != 'x' ]; then cp -u $$(filter %.dll,$$^) $$(@D); fi
 $(CSHARP_binDir)/$(1)_CSHARP_dll_defined = 1
 endif
endef

define CSHARP_mkExeRule =
 ifndef $(CSHARP_binDir)/$(1)_CSHARP_exe_defined
 $(CSHARP_binDir)/$(1):
	mkdir -p $$(@D)
	$(CSHARP_mcs) $$(filter %.cs,$$^) $$(addprefix -r:,$$(filter %.dll,$$^)) -out:$$@ -pkg:dotnet
	if [ '$$(filter %.dll,$$^)x' != 'x' ]; then cp -u $$(filter %.dll,$$^) $$(@D); fi
	cp -u $(CSHARP_System.dll) $$(@D)
 $(CSHARP_binDir)/$(1)_CSHARP_exe_defined = 1
 endif
endef

### Default targets
.PHONY: cleanall
cleanall: CSHARP_clean

.PHONY: CSHARP_clean
CSHARP_clean:
	$(call MAKE_clean,$(patsubst %_CSHARP_exe_defined,%,$(filter $(CSHARP_binDir)/%_CSHARP_exe_defined,$(.VARIABLES))))
	$(call MAKE_clean,$(patsubst %_CSHARP_dll_defined,%,$(filter $(CSHARP_binDir)/%_CSHARP_dll_defined,$(.VARIABLES))))
