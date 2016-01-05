TRANSFORM_sed    ?= env sed
TRANSFORM_outDir ?= $(MAKE_objDir)

### Functions
define TRANSFORM_mkTransformedTarget = # input_name,pipe_name,pipe_cmd
$(eval $(call TRANSFORM_mkTransformedRule,$(1),$(2),$(3)))$(TRANSFORM_outDir)/$(1).$(2).transformed$(suffix $(1))
endef

define TRANSFORM_mkReplaceCmd = # from,to
sed s/"$(1)"/"$(2)"/g
endef

### Target templates
define TRANSFORM_mkTransformedRule =
 ifndef $(TRANSFORM_outDir)/$(1).$(2).transformed$(suffix $(1))_defined
 $(TRANSFORM_outDir)/$(1).$(2).transformed$(suffix $(1)): $(1)
	mkdir -p $$(@D)
	cat $$^ | $(3) > $(TRANSFORM_outDir)/$(1).$(2).transformed$(suffix $(1))
 $(TRANSFORM_outDir)/$(1).$(2).transformed$(suffix $(1))_defined = 1
 endif
endef
