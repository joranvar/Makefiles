MAKE_sed            ?= env sed
MAKE_toolsDir       ?= tools
HASKELL_nixShellDir ?= nix
HASKELL_ghcFlags    ?= -threaded -Wall

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
 $(MAKE_binDir)/$(1): $(HASKELL_nixShellDir)/$(1).nix
	mkdir -p $$(@D)
	$$(call HASKELL_prepareNixShell,$(1),$$(filter %.cabalpkg,$$^))
	$$(call HASKELL_callNixShell,ghc $(HASKELL_ghcFlags) -o $$(@) --make $$(filter %.hs,$$^))
 $(HASKELL_nixShellDir)/$(1).nix: | $(MAKE_utilsDir)/default.nix
	mkdir -p $$(@D)
	cp $(MAKE_utilsDir)/default.nix $$(@)
 $(MAKE_binDir)/$(1)_HASKELL_defined = 1
 $(HASKELL_nixShellDir)/$(1).nix_defined = 1
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
	$(MAKE_sed) -e 's/#{deps}/$(notdir $(basename $(2)))/' $(HASKELL_nixShellDir)/$(1).nix > $(notdir $(1)).nix
	$(MAKE_sed) -e 's/#{name}/$(notdir $(1))/' -i $(notdir $(1)).nix
	$(MAKE_sed) -e 's/default.nix/$(notdir $(1)).nix/' $(MAKE_utilsDir)/shell.nix > ./shell.nix
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
	$(call MAKE_clean,$(patsubst %_HASKELL_defined,%,$(filter %_HASKELL_defined,$(.VARIABLES))))
