CURL ?= env curl
MONO ?= env mono

NUGETDIR ?= lib/NuGet/
TOOLSDIR ?= tools/

NUGET = $(TOOLSDIR)nuget/NuGet.exe

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

$(NUGET): | $(dir $(NUGET))
	$(CURL) -SsL https://www.nuget.org/nuget.exe -o $@

# Nuget dependency template
%.nupkg: PKGNAME = $(basename $(firstword $(subst /, ,$@)))
%.nupkg: VERSION = $(basename $(word 2,$(subst /, ,$@)))
%.nupkg: | $(NUGET)
	[ -d $(NUGETDIR)$(PKGNAME) ] || \
		$(MONO) $(NUGET) install $(PKGNAME) \
		-ExcludeVersion \
		-OutputDirectory $(NUGETDIR) \
		-Verbosity quiet \
		$(if $(VERSION),-Version $(VERSION))

.PHONY: nugetclean
nugetclean:
	$(RM) -r $(NUGETDIR)

# How to make a directory
%/:
	mkdir -p $@
