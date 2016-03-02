FSHARP_fsi      ?= env fsharpi
include $(MAKE_utilsDir)/FSharp.mk
include $(MAKE_utilsDir)/MakeUtils.mk

### Functions
define SLN_mkMkTarget = # mk_name
$(eval $(call SLN_mkMkRule,$(1)))$(1)
endef

### Target templates
define SLN_mkMkRule =
 ifndef $(1)_SLN_mk_defined
 $(1):
	mkdir -p $$(@D)
	$(FSHARP_fsi) $(MAKE_utilsDir)/importSln.fsx $$^ > $$@
 $(1)_SLN_mk_defined = 1
 endif
endef

### Default targets
.PHONY: cleanall
cleanall: SLN_clean

.PHONY: SLN_clean
SLN_clean:
	$(call MAKE_clean,$(patsubst %_SLN_mk_defined,%,$(filter %_SLN_mk_defined,$(.VARIABLES))))
