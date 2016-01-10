MAKE_sed            ?= env sed
MAKE_toolsDir       ?= tools
HASKELL_nixShellDir ?= nix

include $(MAKE_utilsDir)/MakeUtils.mk

### Functions
define HASKELL_mkTarget = # project_name
$(eval $(call HASKELL_mkHaskellRule,$(1)))$(MAKE_binDir)/$(1)
endef

define HASKELL_mkCabalDep = # package_name
$(eval $(call HASKELL_mkCabalDepRule,$(1)))$(HASKELL_nixShellDir)/$(1).cabalpkg
endef

### Target templates
define HASKELL_mkHaskellRule =
 ifndef $(MAKE_binDir)/$(1)_HASKELL_defined
 $(MAKE_binDir)/$(1): $(HASKELL_nixShellDir)/default.nix
	mkdir -p $$(@D)
	$$(call HASKELL_prepareNixShell,$(1),$$(filter %.cabalpkg,$$^))
	$$(call HASKELL_callNixShell,ghc -Wall -o $$(@) --make $$(filter %.hs,$$^))
 $(HASKELL_nixShellDir)/default.nix:
 $(MAKE_binDir)/$(1)_HASKELL_defined = 1
 endif
endef

define HASKELL_mkCabalDepRule =
 ifndef $(HASKELL_nixShellDir)/$(1).cabalpkg_defined
 .PHONY: $(HASKELL_nixShellDir)/$(1).cabalpkg
 $(HASKELL_nixShellDir)/$(1).cabalpkg: ;
 $(HASKELL_nixShellDir)/$(1).cabalpkg_defined = 1
 endif
endef

define HASKELL_prepareNixShell =
	$(MAKE_sed) -e 's/#{deps}/$(notdir $(basename $(2)))/' $(HASKELL_nixShellDir)/default.nix > default.nix
	$(MAKE_sed) -e 's/#{name}/$(notdir $(1))/' -i default.nix
	cp $(MAKE_utilsDir)/shell.nix .
endef

define HASKELL_callNixShell =
	nix-shell --command '$(1)'
endef

### Default targets
.PHONY: cleanall
cleanall: HASKELL_clean

.PHONY: cleandeep
cleandeep: HASKELL_cleandeep

.PHONY: HASKELL_clean
HASKELL_clean:
	$(call MAKE_clean,$(patsubst %_HASEKLL_defined,%,$(filter %_HASKELL_defined,$(.VARIABLES))))

.PHONY: HASKELL_cleandeep
HASKELL_cleandeep:
	rm -fr shell.nix default.nix
