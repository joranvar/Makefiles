TRANSFORM_sed    ?= env sed
TRANSFORM_outDir ?= $(MAKE_objDir)

### Functions
define TRANSFORM_mkTransformedTarget = # input_name,pipe_name,pipe_cmd
$(eval $(call TRANSFORM_mkTransformedRule,$(1),$(2),$(3)))$(TRANSFORM_outDir)/$(1).$(2).transformed$(suffix $(1))
endef

define TRANSFORM_mkReplaceCmd = # from,to
sed s$$$$'\001'"$(1)"$$$$'\001'"$(2)"$$$$'\001'g
endef

### Target templates
define TRANSFORM_mkTransformedRule =
 ifndef $(TRANSFORM_outDir)/$(1).$(2).transformed$(suffix $(1))_TRANSFORM_defined
 $(TRANSFORM_outDir)/$(1).$(2).transformed$(suffix $(1)): $(1)
	mkdir -p $$(@D)
	cat $$^ | $(3) > $(TRANSFORM_outDir)/$(1).$(2).transformed$(suffix $(1))
 $(TRANSFORM_outDir)/$(1).$(2).transformed$(suffix $(1))_TRANSFORM_defined = 1
 endif
endef

### Default targets
.PHONY: cleanall
cleanall: TRANSFORM_clean

.PHONY: TRANSFORM_clean
TRANSFORM_clean:
	rm -fr $(patsubst %_TRANSFORM_defined,%,$(filter $(TRANSFORM_outDir)/%_TRANSFORM_defined,$(.VARIABLES)))
