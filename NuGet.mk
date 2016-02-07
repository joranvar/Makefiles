MAKE_curl      ?= env curl
MAKE_mono      ?= env mono
MAKE_toolsDir  ?= tools
NUGET_nugetDir ?= lib/NuGet
NUGET_nuget    ?= $(MAKE_toolsDir)/nuget/NuGet.exe

include $(MAKE_utilsDir)/MakeUtils.mk

ifndef NUGET_defined

### Functions
define NUGET_mkNuGetTarget = # pkg_name[,version]
$(eval $(call NUGET_mkNuGetRule,$(1),$(2)))$(NUGET_nugetDir)/$(1)/$(1).nupkg
endef

define NUGET_mkNuGetContentsTarget = # pkg_name,contents
$(foreach contents,$(2),$(eval $(call NUGET_mkNuGetContentsRule,$(1),$(contents))))$(addprefix $(NUGET_nugetDir)/$(1)/,$(2))
endef

### Target templates
define NUGET_mkNuGetRule =
 ifndef $(NUGET_nugetDir)/$(1)/$(1).nupkg_defined
 $(NUGET_nugetDir)/$(1)/$(1).nupkg: $(NUGET_nuget)
	mkdir -p $(NUGET_nugetDir)
		$(MAKE_mono) $(NUGET_nuget) install $(1) \
		-ExcludeVersion \
		-OutputDirectory $(NUGET_nugetDir) \
		-Verbosity quiet \
		$(if $(2),-Version $(2))
 $(NUGET_nugetDir)/$(1)/$(1).nupkg_defined = 1
 endif
endef

define NUGET_mkNuGetContentsRule =
 ifndef $(NUGET_nugetDir)/$(1)/$(2)_defined
 $(NUGET_nugetDir)/$(1)/$(2): $(NUGET_nugetDir)/$(1)/$(1).nupkg
 $(eval $(call NUGET_mkNuGetRule,$(1)))
 $(NUGET_nugetDir)/$(1)/$(2)_defined = 1
 endif
endef

$(NUGET_nuget):
	mkdir -p $(@D)
	$(MAKE_curl) -SsL https://www.nuget.org/nuget.exe -o $@

### Default targets
.PHONY: cleanall
cleanall: NUGET_clean

.PHONY: cleandeep
cleandeep: NUGET_cleandeep

.PHONY: NUGET_clean
NUGET_clean:
	rm -fr $(dir $(patsubst %_defined,%,$(filter %.nupkg_defined,$(.VARIABLES))))

.PHONY: NUGET_cleandeep
NUGET_cleandeep:
	$(call MAKE_clean,$(NUGET_nuget))

NUGET_defined = 1
endif
