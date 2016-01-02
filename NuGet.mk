CURL ?= env curl
MONO ?= env mono

NUGETDIR ?= lib/NuGet/
TOOLSDIR ?= tools/

NUGET ?= $(TOOLSDIR)nuget/NuGet.exe

.PHONY: all
all: install_nuget

.PHONY: clean
clean: nugetclean

.PHONY: install_tools
install_tools: install_nuget

.PHONY: realclean
realclean: clean_nuget

.PHONY: install_nuget
install_nuget: $(NUGET)

.PHONY: clean_nuget
ifndef nuget
clean_nuget:
	-$(RM) $(NUGET)

$(NUGET): | $(dir $(NUGET))
	$(CURL) -SsL https://www.nuget.org/nuget.exe -o $@

.PHONY: nugetclean
nugetclean:
	$(RM) -r $(NUGETDIR)
endif

nuget = $(addprefix $(NUGETDIR)$(1)/,$(1).nupkg $(2))

# Nuget dependency template
%.nupkg: PKGNAME = $(basename $(word 1,$(subst /, ,$(subst $(NUGETDIR),,$@))))
%.nupkg: VERSION = $(basename $(word 4,$(subst /, ,$(subst $(NUGETDIR),,$@))))
%.nupkg: | $(NUGET)
	-[ -d $(NUGETDIR)$(PKGNAME) ] || \
		$(MONO) $(NUGET) install $(PKGNAME) \
		-ExcludeVersion \
		-OutputDirectory $(NUGETDIR) \
		-Verbosity quiet \
		$(if $(VERSION),-Version $(VERSION))

# How to make a directory
%/:
	mkdir -p $@
