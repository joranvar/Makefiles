FSHARP_fsc      ?= env fsharpc
FSHARP_fsi      ?= env fsharpi
FSHARP_Core.dll ?= /nix/store/9nvx5380w2md40yzr63hbyh22aafsw4j-fsharp-3.1.2.5/lib/mono/4.5/FSharp.Core.dll
FSHARP_binDir   ?= $(MAKE_binDir)

### Functions
define FSHARP_mkDllTarget = # dll_name
$(FSHARP_binDir)/$(1)
endef

define FSHARP_mkScriptTarget = # script_name
$(eval $(call FSHARP_mkScriptRule,$(1)))$(FSHARP_binDir)/$(1).out
endef

### Rules
$(FSHARP_binDir)/%.dll: %.fs
	mkdir -p $(@D)
	$(FSHARP_fsc) $(filter-out $<,$(filter %.fs,$^)) $< $(addprefix -r:,$(filter %.dll,$^)) -o $@ -a --nologo

$(FSHARP_binDir)/%.exe: %.fs
	mkdir -p $(@D)
	$(FSHARP_fsc) $(filter-out $<,$(filter %.fs,$^)) $< $(addprefix -r:,$(filter %.dll,$^)) -o $@ --nologo
	if [ '$(filter %.dll,$^)x' != 'x' ]; then cp -u $(filter %.dll,$^) $(@D); fi
	cp -u $(FSHARP_Core.dll) $(@D)

### Target templates
define FSHARP_mkScriptRule =
 ifndef $(FSHARP_binDir)/$(1).out_defined
 $(FSHARP_binDir)/$(1).out: $(1)
	mkdir -p $$(@D)
	$(FSHARP_fsi) $$^ > $$@
 $(FSHARP_binDir)/$(1).out_defined = 1
 endif
endef

### Default targets
.PHONY: cleanall
cleanall: FSHARP_clean

.PHONY: FSHARP_clean
FSHARP_clean:
	rm -fr $(FSHARP_binDir)/*.dll
	rm -fr $(FSHARP_binDir)/*.exe
	rm -fr $(patsubst %_defined,%,$(filter $(FSHARP_binDir)/%.out_defined,$(.VARIABLES)))
